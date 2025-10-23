#!/usr/bin/env python3
"""
Extract specific index data from crawl_progress.json and save to CSV
"""

import json
import pandas as pd
import os
import sys
from datetime import datetime


def extract_index_to_csv(index_char):
    """
    Extract data for a specific index from crawl_progress.json and save to CSV

    Args:
        index_char: The hiragana character to extract (e.g., 'き', 'く')
    """

    # Load crawl_progress.json
    if not os.path.exists('crawl_progress.json'):
        print(f"❌ crawl_progress.json not found")
        return False

    with open('crawl_progress.json', 'r') as f:
        data = json.load(f)

    # Check if index exists
    if index_char not in data.get('data', {}):
        print(f"❌ No data found for index '{index_char}'")
        return False

    # Extract data for this index
    index_data = data['data'][index_char]
    songs = index_data.get('songs', [])

    if not songs:
        print(f"❌ No songs found for index '{index_char}'")
        return False

    # Convert to DataFrame
    df = pd.DataFrame(songs)

    # Add index column
    df['index'] = index_char

    # Reorder columns
    columns = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
    for col in columns:
        if col not in df.columns:
            df[col] = None
    df = df[columns]

    # Save to CSV
    output_dir = 'song_lists/indexes'
    os.makedirs(output_dir, exist_ok=True)

    csv_path = os.path.join(output_dir, f'{index_char}.csv')
    df.to_csv(csv_path, index=False, encoding='utf-8')

    print(f"✅ Saved {len(df):,} songs to {csv_path}")
    print(f"   Expected: {index_data.get('expected_count', 0):,}")
    print(f"   Actual: {len(df):,}")

    percent = (len(df) / index_data.get('expected_count', 1) * 100) if index_data.get('expected_count', 0) > 0 else 0
    print(f"   Coverage: {percent:.1f}%")

    return True


def check_index_status(index_char):
    """Check the current status of an index in crawl_progress.json"""

    if not os.path.exists('crawl_progress.json'):
        return None

    with open('crawl_progress.json', 'r') as f:
        data = json.load(f)

    if index_char not in data.get('data', {}):
        return None

    index_data = data['data'][index_char]
    songs = len(index_data.get('songs', []))
    expected = index_data.get('expected_count', 0)

    return {
        'songs': songs,
        'expected': expected,
        'percent': (songs / expected * 100) if expected > 0 else 0
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_to_csv.py <index_char> [index_char2 ...]")
        print("Example: python extract_to_csv.py き く")
        sys.exit(1)

    indices = sys.argv[1:]

    print(f"\n{'='*60}")
    print(f"Extracting indices to CSV - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}\n")

    for index_char in indices:
        print(f"\nProcessing '{index_char}'...")

        # Check status first
        status = check_index_status(index_char)
        if status:
            print(f"   Current: {status['songs']:,}/{status['expected']:,} ({status['percent']:.1f}%)")

            if status['percent'] < 90:
                print(f"   ⚠️  Warning: Only {status['percent']:.1f}% complete")
                response = input("   Continue anyway? (y/n): ")
                if response.lower() != 'y':
                    print(f"   Skipping '{index_char}'")
                    continue

        # Extract to CSV
        extract_index_to_csv(index_char)

    print(f"\n✨ Extraction complete!")


if __name__ == '__main__':
    main()