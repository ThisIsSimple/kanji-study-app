#!/usr/bin/env python3
"""
Update kanji data in Supabase with Korean readings
"""

import json
import os
from supabase import create_client, Client
import sys

# Supabase configuration
SUPABASE_URL = "https://kasxghygpyiyxsjzhomn.supabase.co"
SUPABASE_KEY = "sb_publishable_0d_TYnZ1PBpAkuJW5sgmuA_Kfu6EtYr"

def update_kanji_data(supabase: Client, json_file_path: str):
    """Update kanji data with Korean readings"""
    
    # Load processed JSON data
    print(f"Loading data from {json_file_path}...")
    with open(json_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    kanji_list = data['kanji']
    print(f"Loaded {len(kanji_list)} kanji")
    
    # Clear existing data first
    print("\nClearing existing kanji data...")
    try:
        supabase.table('kanji').delete().neq('id', 0).execute()
        print("Cleared existing data")
    except Exception as e:
        print(f"Error clearing data: {e}")
    
    # Insert updated data
    print("\nInserting updated kanji data...")
    batch_size = 100
    total_inserted = 0
    
    for i in range(0, len(kanji_list), batch_size):
        batch = kanji_list[i:i+batch_size]
        
        # Prepare batch data
        batch_data = []
        for kanji in batch:
            # Handle duplicate kanji by using original_id
            kanji_data = {
                'character': kanji['character'],
                'meanings': kanji['meanings'],
                'on_readings': kanji['readings']['on'],
                'kun_readings': kanji['readings']['kun'],
                'korean_on_readings': kanji.get('korean_on_readings', []),
                'korean_kun_readings': kanji.get('korean_kun_readings', []),
                'grade': kanji['grade'],
                'jlpt': kanji['jlpt'],
                'stroke_count': kanji['strokeCount'],
                'frequency': kanji['frequency'],
                'original_id': kanji['id']
            }
            batch_data.append(kanji_data)
        
        try:
            result = supabase.table('kanji').insert(batch_data).execute()
            total_inserted += len(batch)
            print(f"  Inserted batch {i//batch_size + 1}/{(len(kanji_list)-1)//batch_size + 1} (total: {total_inserted})")
        except Exception as e:
            print(f"  Error inserting batch: {e}")
            # Try inserting one by one
            for single_kanji in batch_data:
                try:
                    supabase.table('kanji').insert(single_kanji).execute()
                    total_inserted += 1
                except Exception as single_error:
                    print(f"    Failed to insert {single_kanji['character']}: {single_error}")
    
    print(f"\nUpdate complete! Inserted {total_inserted} kanji")
    
    # Verify the update
    print("\nVerifying update...")
    try:
        # Check total count
        count_result = supabase.table('kanji').select('id', count='exact').execute()
        print(f"Total kanji in database: {count_result.count}")
        
        # Check some examples with Korean readings
        examples = supabase.table('kanji').select('character', 'korean_on_readings', 'korean_kun_readings').in_('character', ['歌', '家', '加', '席', '船']).execute()
        print("\nExamples with Korean readings:")
        for ex in examples.data:
            print(f"  {ex['character']}: on={ex['korean_on_readings']}, kun={ex['korean_kun_readings']}")
    except Exception as e:
        print(f"Error verifying: {e}")

def main():
    """Main update function"""
    # Create Supabase client
    print("Connecting to Supabase...")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # JSON file path
    json_file = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'assets', 'data', 'kanji_data_processed.json'
    )
    
    if not os.path.exists(json_file):
        print(f"Error: Processed JSON file not found at {json_file}")
        sys.exit(1)
    
    # Run update
    try:
        update_kanji_data(supabase, json_file)
        print("\nUpdate completed successfully!")
    except Exception as e:
        print(f"\nUpdate failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()