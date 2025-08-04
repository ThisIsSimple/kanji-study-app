#!/usr/bin/env python3
"""
Insert parsed Excel JSON data into Supabase database
"""

import json
import os
import sys
from supabase import create_client, Client

def load_supabase_config():
    """Load Supabase configuration from environment or config file"""
    # Try to get from environment first
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_key:
        # Try to read from config file
        config_path = '/Users/cordelia273/Projects/kanji/kanji_study_app/lib/config/supabase_config.dart'
        try:
            with open(config_path, 'r') as f:
                content = f.read()
                # Extract URL and key from Dart file
                import re
                url_match = re.search(r"supabaseUrl = '([^']+)'", content)
                key_match = re.search(r"supabaseAnonKey = '([^']+)'", content)
                
                if url_match and key_match:
                    supabase_url = url_match.group(1)
                    supabase_key = key_match.group(1)
        except Exception as e:
            print(f"Error reading config file: {e}")
    
    if not supabase_url or not supabase_key:
        print("Error: Could not find Supabase configuration")
        print("Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
        sys.exit(1)
    
    return supabase_url, supabase_key

def insert_kanji_data(json_path):
    """Insert kanji data from JSON file into Supabase"""
    
    # Load Supabase configuration
    supabase_url, supabase_key = load_supabase_config()
    supabase: Client = create_client(supabase_url, supabase_key)
    
    # Load JSON data
    print(f"Loading JSON data from: {json_path}")
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    kanji_list = data['kanji']
    print(f"Total kanji to insert: {len(kanji_list)}")
    
    # Prepare data for Supabase insertion
    insert_data = []
    
    for kanji in kanji_list:
        row = {
            'id': kanji['id'],
            'character': kanji['character'],
            'meanings': kanji['meanings'],
            'on_readings': kanji['readings']['on'],
            'kun_readings': kanji['readings']['kun'],
            'korean_on_readings': kanji['korean_on_readings'],
            'korean_kun_readings': kanji['korean_kun_readings'],
            'grade': kanji['grade'],
            'jlpt': kanji['jlpt'],
            'stroke_count': kanji.get('strokeCount', 0),
            'frequency': kanji['frequency']
        }
        insert_data.append(row)
    
    # Insert data in batches
    batch_size = 100
    total_inserted = 0
    
    try:
        for i in range(0, len(insert_data), batch_size):
            batch = insert_data[i:i + batch_size]
            
            print(f"Inserting batch {i//batch_size + 1}: rows {i+1} to {min(i+batch_size, len(insert_data))}")
            
            response = supabase.table('kanji').insert(batch).execute()
            
            if response.data:
                total_inserted += len(response.data)
                print(f"  ✅ Successfully inserted {len(response.data)} rows")
            else:
                print(f"  ❌ Batch insertion failed")
                
    except Exception as e:
        print(f"Error during insertion: {e}")
        return False
    
    print(f"\n🎉 Insertion complete! Total rows inserted: {total_inserted}")
    
    # Verify insertion
    try:
        count_response = supabase.table('kanji').select('id', count='exact').execute()
        actual_count = count_response.count
        print(f"✅ Verification: {actual_count} rows in database")
        
        if actual_count == len(kanji_list):
            print("✅ All data successfully inserted!")
            return True
        else:
            print(f"⚠️ Expected {len(kanji_list)} rows, but found {actual_count}")
            return False
            
    except Exception as e:
        print(f"Error during verification: {e}")
        return False

if __name__ == "__main__":
    json_path = "/Users/cordelia273/Projects/kanji/kanji_study_app/assets/data/kanji_data_from_excel.json"
    
    if not os.path.exists(json_path):
        print(f"Error: JSON file not found at {json_path}")
        sys.exit(1)
    
    success = insert_kanji_data(json_path)
    
    if success:
        print("\n🎉 Mission accomplished! All kanji data has been successfully migrated to Supabase.")
    else:
        print("\n❌ Migration completed with some issues. Please check the logs above.")