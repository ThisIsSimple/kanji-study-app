#!/usr/bin/env python3
"""
Parse Excel file containing kanji data and convert to JSON format
"""

import pandas as pd
import json
import re
import os

def parse_korean_meaning(meaning_text):
    """
    Parse Korean meaning text to extract kun (훈독) and on (음독) readings
    
    Examples:
    - "노래 가" → kun: ["노래"], on: ["가"]
    - "당나라/ 당황할 당" → kun: ["당나라", "당황할"], on: ["당"]
    - "대 대/ 태풍 태" → kun: ["대", "태풍"], on: ["대", "태"]
    - "거북 귀/ 터질 균" → kun: ["거북", "터질"], on: ["귀", "균"]
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
    """
    Parse Japanese reading text and return as list
    Split by 、 (Japanese comma)
    """
    if pd.isna(reading_text):
        return []
    
    reading_text = str(reading_text).strip()
    if not reading_text:
        return []
    
    # Split by Japanese comma
    readings = [r.strip() for r in reading_text.split('、') if r.strip()]
    return readings

def convert_excel_to_json(excel_path, output_path):
    """
    Convert Excel file to JSON format with proper parsing
    """
    print(f"Reading Excel file: {excel_path}")
    df = pd.read_excel(excel_path)
    
    print(f"Total rows: {len(df)}")
    print(f"Columns: {list(df.columns)}")
    
    kanji_list = []
    missing_data = {
        'no_korean_on': 0,
        'no_korean_kun': 0,
        'no_japanese_on': 0,
        'no_japanese_kun': 0
    }
    
    for idx, row in df.iterrows():
        # Parse Korean meanings
        korean_kun, korean_on = parse_korean_meaning(row['뜻'])
        
        # Parse Japanese readings
        japanese_kun = parse_japanese_readings(row['훈독'])
        japanese_on = parse_japanese_readings(row['음독'])
        
        # Count missing data
        if not korean_on:
            missing_data['no_korean_on'] += 1
        if not korean_kun:
            missing_data['no_korean_kun'] += 1
        if not japanese_on:
            missing_data['no_japanese_on'] += 1
        if not japanese_kun:
            missing_data['no_japanese_kun'] += 1
        
        kanji_data = {
            'id': int(row['번호']),
            'character': row['한자'],
            'meanings': korean_kun,  # Use Korean kun readings as meanings
            'korean_on_readings': korean_on,
            'korean_kun_readings': korean_kun,
            'readings': {
                'on': japanese_on,
                'kun': japanese_kun
            },
            'grade': 0,  # Will be updated later
            'jlpt': 0,   # Will be updated later
            'strokeCount': 0,
            'frequency': int(row['번호']),  # Use number as frequency for now
            'examples': []
        }
        
        kanji_list.append(kanji_data)
        
        # Print progress
        if (idx + 1) % 100 == 0:
            print(f"Processed {idx + 1} kanji...")
    
    # Create final JSON structure
    json_data = {
        'kanji': kanji_list
    }
    
    # Save to file
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, ensure_ascii=False, indent=2)
    
    print(f"\nConversion complete!")
    print(f"Total kanji: {len(kanji_list)}")
    print(f"\nMissing data statistics:")
    print(f"  No Korean on readings: {missing_data['no_korean_on']}")
    print(f"  No Korean kun readings: {missing_data['no_korean_kun']}")
    print(f"  No Japanese on readings: {missing_data['no_japanese_on']}")
    print(f"  No Japanese kun readings: {missing_data['no_japanese_kun']}")
    
    # Show some examples
    print("\nFirst 5 entries:")
    for i in range(min(5, len(kanji_list))):
        k = kanji_list[i]
        print(f"\n[{k['id']}] {k['character']}:")
        print(f"  Korean kun: {k['korean_kun_readings']}")
        print(f"  Korean on: {k['korean_on_readings']}")
        print(f"  Japanese kun: {k['readings']['kun']}")
        print(f"  Japanese on: {k['readings']['on']}")

def verify_json_file(json_path):
    """
    Verify the generated JSON file
    """
    print(f"\nVerifying JSON file: {json_path}")
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    kanji_list = data['kanji']
    print(f"Total kanji in JSON: {len(kanji_list)}")
    
    # Check for empty fields
    empty_fields = {
        'character': 0,
        'korean_on': 0,
        'korean_kun': 0,
        'japanese_on': 0,
        'japanese_kun': 0
    }
    
    for k in kanji_list:
        if not k['character']:
            empty_fields['character'] += 1
        if not k.get('korean_on_readings'):
            empty_fields['korean_on'] += 1
        if not k.get('korean_kun_readings'):
            empty_fields['korean_kun'] += 1
        if not k['readings'].get('on'):
            empty_fields['japanese_on'] += 1
        if not k['readings'].get('kun'):
            empty_fields['japanese_kun'] += 1
    
    print("\nEmpty fields count:")
    for field, count in empty_fields.items():
        percentage = (count / len(kanji_list)) * 100
        print(f"  {field}: {count} ({percentage:.1f}%)")
    
    return len(kanji_list) == 2136

if __name__ == "__main__":
    # File paths
    excel_path = "/Users/cordelia273/Projects/kanji/한자(2136자).xlsx"
    output_path = "/Users/cordelia273/Projects/kanji/kanji_study_app/assets/data/kanji_data_from_excel.json"
    
    # Convert Excel to JSON
    convert_excel_to_json(excel_path, output_path)
    
    # Verify the result
    is_valid = verify_json_file(output_path)
    
    if is_valid:
        print("\n✅ JSON file is valid with 2136 kanji entries!")
    else:
        print("\n❌ JSON file validation failed!")