#!/usr/bin/env python3
"""
Cross-validation script to verify data accuracy between Excel source and Supabase database
"""

import pandas as pd
import json
import os
import sys
from supabase import create_client, Client
from typing import List, Dict, Any, Tuple

def load_supabase_config():
    """Load Supabase configuration from environment"""
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_key:
        print("Error: Could not find Supabase configuration")
        print("Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
        sys.exit(1)
    
    return supabase_url, supabase_key

def parse_korean_meaning(meaning_text):
    """
    Parse Korean meaning text to extract kun (훈독) and on (음독) readings
    Same logic as in parse_excel_to_json.py
    """
    if pd.isna(meaning_text):
        return [], []
    
    meaning_text = str(meaning_text).strip()
    korean_kun = []
    korean_on = []
    
    # Split by / to handle multiple meanings
    parts = meaning_text.split('/')
    
    for part in parts:
        part = part.strip()
        if not part:
            continue
            
        # Try to find the last word (usually the on reading)
        words = part.split()
        
        if len(words) >= 2:
            # Last word is usually the on reading (음독)
            # Everything before is kun reading (훈독)
            on_reading = words[-1]
            kun_reading = ' '.join(words[:-1])
            
            # Check if the last word looks like an on reading (usually 1-2 characters)
            if len(on_reading) <= 2 and on_reading and not on_reading.endswith('다'):
                korean_on.append(on_reading)
                if kun_reading:
                    korean_kun.append(kun_reading)
            else:
                # If last word doesn't look like on reading, treat whole as kun
                korean_kun.append(part)
        else:
            # Single word - could be either on or kun
            if len(part) <= 2:
                korean_on.append(part)
            else:
                korean_kun.append(part)
    
    # Remove duplicates while preserving order
    korean_kun = list(dict.fromkeys(korean_kun))
    korean_on = list(dict.fromkeys(korean_on))
    
    return korean_kun, korean_on

def parse_japanese_readings(reading_text):
    """Parse Japanese reading text and return as list"""
    if pd.isna(reading_text):
        return []
    
    reading_text = str(reading_text).strip()
    if not reading_text:
        return []
    
    # Split by Japanese comma
    readings = [r.strip() for r in reading_text.split('、') if r.strip()]
    return readings

def load_excel_data(excel_path: str) -> List[Dict[str, Any]]:
    """Load and parse data from Excel file"""
    print(f"Loading Excel data from: {excel_path}")
    df = pd.read_excel(excel_path)
    
    excel_data = []
    for idx, row in df.iterrows():
        # Parse Korean meanings
        korean_kun, korean_on = parse_korean_meaning(row['뜻'])
        
        # Parse Japanese readings
        japanese_kun = parse_japanese_readings(row['훈독'])
        japanese_on = parse_japanese_readings(row['음독'])
        
        kanji_data = {
            'id': int(row['번호']),
            'character': row['한자'],
            'meanings': korean_kun,
            'korean_on_readings': korean_on,
            'korean_kun_readings': korean_kun,
            'on_readings': japanese_on,
            'kun_readings': japanese_kun,
            'grade': 0,
            'jlpt': 0,
            'stroke_count': 0,
            'frequency': int(row['번호'])
        }
        excel_data.append(kanji_data)
    
    print(f"Loaded {len(excel_data)} records from Excel")
    return excel_data

def load_supabase_data() -> List[Dict[str, Any]]:
    """Load data from Supabase kanji table"""
    print("Loading data from Supabase...")
    
    # Load Supabase configuration
    supabase_url, supabase_key = load_supabase_config()
    supabase: Client = create_client(supabase_url, supabase_key)
    
    try:
        response = supabase.table('kanji').select('*').order('id').execute()
        supabase_data = response.data
        
        print(f"Loaded {len(supabase_data)} records from Supabase")
        return supabase_data
        
    except Exception as e:
        print(f"Error loading data from Supabase: {e}")
        sys.exit(1)

def compare_lists(list1: List[str], list2: List[str], field_name: str) -> Tuple[bool, str]:
    """Compare two lists and return match status and details"""
    if not list1 and not list2:
        return True, "Both empty"
    
    if set(list1) == set(list2):
        return True, f"Match: {list1}"
    else:
        return False, f"Mismatch - Excel: {list1}, DB: {list2}"

def validate_record(excel_record: Dict[str, Any], db_record: Dict[str, Any]) -> Dict[str, Any]:
    """Validate a single record between Excel and DB"""
    validation_result = {
        'id': excel_record['id'],
        'character': excel_record['character'],
        'is_valid': True,
        'errors': []
    }
    
    # Check character
    if excel_record['character'] != db_record['character']:
        validation_result['is_valid'] = False
        validation_result['errors'].append(f"Character mismatch: Excel='{excel_record['character']}', DB='{db_record['character']}'")
    
    # Check Korean kun readings (meanings)
    kun_match, kun_details = compare_lists(
        excel_record['korean_kun_readings'], 
        db_record['korean_kun_readings'], 
        'korean_kun_readings'
    )
    if not kun_match:
        validation_result['is_valid'] = False
        validation_result['errors'].append(f"Korean kun readings: {kun_details}")
    
    # Check Korean on readings
    on_match, on_details = compare_lists(
        excel_record['korean_on_readings'], 
        db_record['korean_on_readings'], 
        'korean_on_readings'
    )
    if not on_match:
        validation_result['is_valid'] = False
        validation_result['errors'].append(f"Korean on readings: {on_details}")
    
    # Check Japanese kun readings
    j_kun_match, j_kun_details = compare_lists(
        excel_record['kun_readings'], 
        db_record['kun_readings'], 
        'kun_readings'
    )
    if not j_kun_match:
        validation_result['is_valid'] = False
        validation_result['errors'].append(f"Japanese kun readings: {j_kun_details}")
    
    # Check Japanese on readings
    j_on_match, j_on_details = compare_lists(
        excel_record['on_readings'], 
        db_record['on_readings'], 
        'on_readings'
    )
    if not j_on_match:
        validation_result['is_valid'] = False
        validation_result['errors'].append(f"Japanese on readings: {j_on_details}")
    
    return validation_result

def cross_validate_data(excel_path: str):
    """Main cross-validation function"""
    print("=" * 80)
    print("📊 Starting Cross-Validation of Kanji Data")
    print("=" * 80)
    
    # Load data from both sources
    excel_data = load_excel_data(excel_path)
    supabase_data = load_supabase_data()
    
    # Check record count
    if len(excel_data) != len(supabase_data):
        print(f"⚠️ Record count mismatch: Excel={len(excel_data)}, Supabase={len(supabase_data)}")
        return False
    
    print(f"✅ Record count matches: {len(excel_data)} records")
    print()
    
    # Create dictionaries for easier lookup
    excel_dict = {record['id']: record for record in excel_data}
    supabase_dict = {record['id']: record for record in supabase_data}
    
    # Validation results
    validation_results = []
    errors_found = 0
    
    print("🔍 Starting record-by-record validation...")
    print()
    
    # Validate each record
    for record_id in sorted(excel_dict.keys()):
        if record_id not in supabase_dict:
            print(f"❌ Record ID {record_id} exists in Excel but not in Supabase")
            errors_found += 1
            continue
        
        validation_result = validate_record(excel_dict[record_id], supabase_dict[record_id])
        validation_results.append(validation_result)
        
        if not validation_result['is_valid']:
            errors_found += 1
            print(f"❌ Validation failed for ID {record_id} ({validation_result['character']}):")
            for error in validation_result['errors']:
                print(f"   {error}")
            print()
        elif record_id <= 10:  # Show first 10 successful validations
            print(f"✅ ID {record_id} ({validation_result['character']}): Valid")
    
    # Check for records in Supabase but not in Excel
    for record_id in supabase_dict.keys():
        if record_id not in excel_dict:
            print(f"❌ Record ID {record_id} exists in Supabase but not in Excel")
            errors_found += 1
    
    # Summary
    print("=" * 80)
    print("📈 VALIDATION SUMMARY")
    print("=" * 80)
    
    total_records = len(validation_results)
    valid_records = sum(1 for result in validation_results if result['is_valid'])
    accuracy = (valid_records / total_records) * 100 if total_records > 0 else 0
    
    print(f"Total records validated: {total_records}")
    print(f"Valid records: {valid_records}")
    print(f"Invalid records: {errors_found}")
    print(f"Accuracy: {accuracy:.2f}%")
    
    if errors_found == 0:
        print("\n🎉 ALL DATA VALIDATION PASSED! 🎉")
        print("Excel and Supabase data are perfectly synchronized.")
        return True
    else:
        print(f"\n⚠️ Found {errors_found} validation errors.")
        print("Please review the errors above and fix the data inconsistencies.")
        return False

if __name__ == "__main__":
    excel_path = "/Users/cordelia273/Projects/kanji/한자(2136자).xlsx"
    
    if not os.path.exists(excel_path):
        print(f"Error: Excel file not found at {excel_path}")
        sys.exit(1)
    
    success = cross_validate_data(excel_path)
    
    if success:
        print("\n✅ Cross-validation completed successfully!")
    else:
        print("\n❌ Cross-validation found data inconsistencies.")