#!/usr/bin/env python3
"""
Migrate kanji data from JSON to Supabase database
"""

import json
import os
from supabase import create_client, Client
from typing import List, Dict, Any
import sys

# Supabase configuration
SUPABASE_URL = "https://kasxghygpyiyxsjzhomn.supabase.co"
SUPABASE_KEY = "sb_publishable_0d_TYnZ1PBpAkuJW5sgmuA_Kfu6EtYr"  # This should be service role key for admin operations

def load_json_data(file_path: str) -> List[Dict[str, Any]]:
    """Load kanji data from JSON file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        # JSON 구조가 {"kanji": [...]} 형태인 경우 처리
        if isinstance(data, dict) and 'kanji' in data:
            return data['kanji']
        return data

def prepare_kanji_data(kanji: Dict[str, Any]) -> Dict[str, Any]:
    """Prepare kanji data for database insertion"""
    # Extract readings
    readings = kanji.get('readings', {})
    on_readings = readings.get('on', [])
    kun_readings = readings.get('kun', [])
    
    return {
        'character': kanji['character'],
        'meanings': kanji['meanings'],
        'on_readings': on_readings,
        'kun_readings': kun_readings,
        'grade': kanji['grade'],
        'jlpt': kanji['jlpt'],
        'stroke_count': kanji['strokeCount'],
        'frequency': kanji['frequency']
    }

def prepare_example_data(kanji_character: str, examples: List[Any]) -> List[Dict[str, Any]]:
    """Prepare example data for database insertion"""
    prepared_examples = []
    
    for example in examples:
        if isinstance(example, str):
            # Legacy format - just a string
            prepared_examples.append({
                'kanji_character': kanji_character,
                'japanese': example,
                'hiragana': '',
                'korean': '',
                'explanation': None,
                'source': 'legacy'
            })
        elif isinstance(example, dict):
            # New format with full data
            prepared_examples.append({
                'kanji_character': kanji_character,
                'japanese': example.get('japanese', ''),
                'hiragana': example.get('hiragana', ''),
                'korean': example.get('korean', ''),
                'explanation': example.get('explanation'),
                'source': example.get('source', 'manual')
            })
    
    return prepared_examples

def migrate_data(supabase: Client, json_file_path: str):
    """Migrate all data to Supabase"""
    # Load JSON data
    print(f"Loading data from {json_file_path}...")
    kanji_list = load_json_data(json_file_path)
    print(f"Loaded {len(kanji_list)} kanji")
    
    # Migrate kanji data
    print("\nMigrating kanji data...")
    kanji_batch = []
    examples_batch = []
    
    for i, kanji in enumerate(kanji_list):
        # Prepare kanji data
        kanji_data = prepare_kanji_data(kanji)
        kanji_batch.append(kanji_data)
        
        # Prepare examples
        if 'examples' in kanji and kanji['examples']:
            examples = prepare_example_data(kanji['character'], kanji['examples'])
            examples_batch.extend(examples)
        
        # Insert in batches of 100
        if len(kanji_batch) >= 100 or i == len(kanji_list) - 1:
            try:
                # Insert kanji
                result = supabase.table('kanji').upsert(kanji_batch).execute()
                print(f"  Inserted {len(kanji_batch)} kanji (total: {i+1}/{len(kanji_list)})")
                kanji_batch = []
            except Exception as e:
                print(f"  Error inserting kanji batch: {e}")
                # Try inserting one by one to identify problematic records
                for single_kanji in kanji_batch:
                    try:
                        supabase.table('kanji').upsert(single_kanji).execute()
                    except Exception as single_error:
                        print(f"    Failed to insert kanji {single_kanji['character']}: {single_error}")
                kanji_batch = []
    
    # Insert examples
    print(f"\nMigrating {len(examples_batch)} examples...")
    for i in range(0, len(examples_batch), 100):
        batch = examples_batch[i:i+100]
        try:
            result = supabase.table('kanji_examples').insert(batch).execute()
            print(f"  Inserted examples batch {i//100 + 1}/{(len(examples_batch)-1)//100 + 1}")
        except Exception as e:
            print(f"  Error inserting examples batch: {e}")

def main():
    """Main migration function"""
    # Create Supabase client
    print("Connecting to Supabase...")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # JSON file path
    json_file = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'assets', 'data', 'kanji_data.json'
    )
    
    if not os.path.exists(json_file):
        print(f"Error: JSON file not found at {json_file}")
        sys.exit(1)
    
    # Run migration
    try:
        migrate_data(supabase, json_file)
        print("\nMigration completed successfully!")
    except Exception as e:
        print(f"\nMigration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()