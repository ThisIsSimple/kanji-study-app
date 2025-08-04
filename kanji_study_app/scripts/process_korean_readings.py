#!/usr/bin/env python3
"""
Process kanji data to extract Korean on/kun readings
"""

import json
import re
from typing import List, Dict, Any, Tuple
from korean_readings_map import KOREAN_ON_READINGS

def extract_korean_readings(meaning_text: str) -> Tuple[List[str], List[str]]:
    """
    Extract Korean on readings (음독) and kun readings (훈독) from meaning text
    
    Examples:
    - "노래 가" → kun: ["노래"], on: ["가"]
    - "그림 화/그을 획" → kun: ["그림", "그을"], on: ["화", "획"]
    - "각출/마땅 해" → kun: ["각출", "마땅"], on: ["해"]
    """
    korean_on = []
    korean_kun = []
    
    # Handle multiple meanings separated by /
    meanings = meaning_text.split('/')
    
    for meaning in meanings:
        meaning = meaning.strip()
        
        # Extract the last syllable(s) as on reading
        # Pattern: word + space + 1-2 syllable on reading
        match = re.match(r'^(.+?)\s+([가-힣]{1,2})$', meaning)
        
        if match:
            kun_part = match.group(1).strip()
            on_part = match.group(2).strip()
            
            if kun_part:
                korean_kun.append(kun_part)
            if on_part:
                korean_on.append(on_part)
        else:
            # If no pattern match, treat the whole as kun reading
            if meaning:
                korean_kun.append(meaning)
    
    return korean_on, korean_kun

def fix_japanese_readings(kanji_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Fix incorrectly classified Japanese on/kun readings
    
    Common patterns:
    - Single kana syllables (か, け, etc.) are usually ON readings
    - Longer readings with okurigana are usually KUN readings
    """
    character = kanji_data['character']
    current_on = kanji_data['readings']['on']
    current_kun = kanji_data['readings']['kun']
    
    new_on = []
    new_kun = []
    
    # Process current ON readings
    for reading in current_on:
        # If it contains a dot (okurigana marker) or is longer, it's likely KUN
        if '.' in reading or (len(reading) > 3 and any(c in 'るむうくすつぬふ' for c in reading[-1:])):
            new_kun.append(reading)
        else:
            new_on.append(reading)
    
    # Process current KUN readings
    for reading in current_kun:
        # If it's a single syllable in katakana style, it's likely ON
        if len(reading) <= 2 and not any(c in 'るむうくすつぬふ' for c in reading):
            new_on.append(reading)
        else:
            new_kun.append(reading)
    
    kanji_data['readings']['on'] = new_on
    kanji_data['readings']['kun'] = new_kun
    
    return kanji_data

def process_kanji_data(input_file: str, output_file: str):
    """Process kanji data to add Korean readings"""
    
    # Load JSON data
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    kanji_list = data['kanji']
    processed_count = 0
    missing_on_readings = []
    
    for kanji in kanji_list:
        character = kanji['character']
        
        # Get Korean on readings from mapping
        korean_on = KOREAN_ON_READINGS.get(character, [])
        
        # Korean kun readings are the meanings
        korean_kun = []
        for meaning in kanji['meanings']:
            # Handle slash-separated meanings
            if '/' in meaning:
                parts = [part.strip() for part in meaning.split('/')]
                korean_kun.extend(parts)
            else:
                korean_kun.append(meaning)
        
        # Remove duplicates while preserving order
        kanji['korean_on_readings'] = korean_on
        kanji['korean_kun_readings'] = list(dict.fromkeys(korean_kun))
        
        # Fix Japanese readings classification
        kanji = fix_japanese_readings(kanji)
        
        # Track missing on readings
        if not korean_on and character not in missing_on_readings:
            missing_on_readings.append(character)
        
        processed_count += 1
        
        # Show progress
        if processed_count % 100 == 0:
            print(f"Processed {processed_count} kanji...")
    
    # Save processed data
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\nProcessing complete! Processed {processed_count} kanji.")
    print(f"Missing Korean on readings for {len(missing_on_readings)} kanji")
    
    # Show some examples
    print("\nExamples of processed data:")
    for i in [0, 1, 100, 500]:
        if i < len(kanji_list):
            k = kanji_list[i]
            print(f"\n{k['character']}:")
            print(f"  meanings: {k['meanings']}")
            print(f"  korean_on: {k['korean_on_readings']}")
            print(f"  korean_kun: {k['korean_kun_readings']}")
            print(f"  japanese_on: {k['readings']['on']}")
            print(f"  japanese_kun: {k['readings']['kun']}")

if __name__ == "__main__":
    import os
    
    # File paths
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_file = os.path.join(base_dir, 'assets', 'data', 'kanji_data.json')
    output_file = os.path.join(base_dir, 'assets', 'data', 'kanji_data_processed.json')
    
    process_kanji_data(input_file, output_file)