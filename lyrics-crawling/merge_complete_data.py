#!/usr/bin/env python3
"""
모든 데이터를 합치는 스크립트 - 백업 파일과 현재 crawl_progress.json 데이터 결합
"""

import pandas as pd
import json
import os
from datetime import datetime

def merge_complete_data():
    """백업 파일과 현재 데이터를 합치기"""

    print(f"\n{'='*50}")
    print(f"Complete Data Merging - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*50}\n")

    # 1. 백업 파일에서 이전 데이터 읽기
    backup_csv = 'song_lists/backup_before_ka.csv'
    all_data = []

    if os.path.exists(backup_csv):
        df_backup = pd.read_csv(backup_csv)
        print(f"✅ Loaded {len(df_backup):,} songs from backup")
        print(f"   Indices: {', '.join(df_backup['index'].unique())}")
        all_data.append(df_backup)

    # 2. crawl_progress.json에서 새로운 데이터 읽기
    if os.path.exists('crawl_progress.json'):
        with open('crawl_progress.json', 'r') as f:
            progress_data = json.load(f)

        if 'data' in progress_data:
            for char, char_data in progress_data['data'].items():
                if char == 'か':  # 'か' 데이터만 추가 (다른 데이터는 백업에 있음)
                    songs = char_data.get('songs', [])
                    if songs:
                        df_new = pd.DataFrame(songs)
                        df_new['index'] = char
                        all_data.append(df_new)
                        print(f"✅ Added {len(df_new):,} songs for index '{char}'")

    # 3. 모든 데이터 결합
    if all_data:
        final_df = pd.concat(all_data, ignore_index=True)

        # 열 순서 정리
        columns = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
        for col in columns:
            if col not in final_df.columns:
                final_df[col] = None
        final_df = final_df[columns]

        # 저장
        csv_path = 'song_lists/all_songs_complete.csv'
        final_df.to_csv(csv_path, index=False, encoding='utf-8')
        print(f"\n💾 Saved complete data to: {csv_path}")

        # 통계
        print(f"\n📈 Final Statistics:")
        print(f"  - Total songs: {len(final_df):,}")
        print(f"  - Unique artists: {final_df['artist'].nunique():,}")
        print(f"  - Data by index:")
        for idx in sorted(final_df['index'].unique()):
            count = len(final_df[final_df['index'] == idx])
            print(f"    {idx}: {count:,} songs")

        return final_df
    else:
        print("No data found to merge")
        return None


if __name__ == '__main__':
    merge_complete_data()