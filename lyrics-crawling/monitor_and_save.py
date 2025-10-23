#!/usr/bin/env python3
"""
Monitor crawling progress and automatically save to CSV when complete
"""

import json
import pandas as pd
import os
import time
from datetime import datetime


def check_and_save_if_complete(index_char, threshold=0.95):
    """
    Check if crawling is complete and save to CSV if it is

    Args:
        index_char: The hiragana character to check
        threshold: Completion threshold (default 95%)
    """

    if not os.path.exists('crawl_progress.json'):
        return False

    with open('crawl_progress.json', 'r') as f:
        data = json.load(f)

    if index_char not in data.get('data', {}):
        return False

    index_data = data['data'][index_char]
    songs = index_data.get('songs', [])
    expected = index_data.get('expected_count', 0)

    if expected == 0 or len(songs) == 0:
        return False

    percent = len(songs) / expected

    # Check if already saved
    csv_path = f'song_lists/indexes/{index_char}.csv'
    if os.path.exists(csv_path):
        print(f"   {index_char}: Already saved to {csv_path}")
        return True

    # Save if complete enough
    if percent >= threshold:
        # Convert to DataFrame
        df = pd.DataFrame(songs)
        df['index'] = index_char

        # Reorder columns
        columns = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
        for col in columns:
            if col not in df.columns:
                df[col] = None
        df = df[columns]

        # Save to CSV
        os.makedirs('song_lists/indexes', exist_ok=True)
        df.to_csv(csv_path, index=False, encoding='utf-8')

        print(f"   ✅ {index_char}: Saved {len(df):,} songs to {csv_path} ({percent*100:.1f}%)")
        return True
    else:
        print(f"   🔄 {index_char}: {len(songs):,}/{expected:,} ({percent*100:.1f}%) - Still crawling...")
        return False


def main():
    print(f"\n{'='*60}")
    print(f"Monitoring crawlers - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}\n")

    indices_to_monitor = ['き', 'く']
    completed = set()

    while len(completed) < len(indices_to_monitor):
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Checking status...")

        for index_char in indices_to_monitor:
            if index_char not in completed:
                if check_and_save_if_complete(index_char):
                    completed.add(index_char)

        if len(completed) < len(indices_to_monitor):
            remaining = [i for i in indices_to_monitor if i not in completed]
            print(f"\n   Remaining: {', '.join(remaining)}")
            print(f"   Waiting 2 minutes before next check...")
            time.sleep(120)  # Wait 2 minutes

    print(f"\n✨ All indices have been saved to CSV!")
    print(f"   Completed: {', '.join(sorted(completed))}")


if __name__ == '__main__':
    main()