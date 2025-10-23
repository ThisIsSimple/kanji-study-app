#!/usr/bin/env python3
"""
모든 크롤링된 데이터를 하나의 파일로 합치는 스크립트
"""

import pandas as pd
import json
import os
from datetime import datetime

def merge_all_data():
    """모든 인덱스의 데이터를 합치기"""

    # 파일 패턴
    index_files = {
        'あ': 'song_lists/아.csv',
        'い': 'song_lists/이.csv',
        'う': 'song_lists/우.csv',
        'え': 'song_lists/에.csv',
        'お': 'song_lists/오.csv',
    }

    # crawl_progress.json도 확인
    progress_data = {}
    if os.path.exists('crawl_progress.json'):
        with open('crawl_progress.json', 'r') as f:
            progress_data = json.load(f)

    # 데이터 수집
    all_data = {}
    total_songs = 0

    print(f"\n{'='*50}")
    print(f"Data Merging - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*50}\n")

    # CSV 파일에서 데이터 읽기
    for idx, csv_path in index_files.items():
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            all_data[idx] = {
                'character': idx,
                'actual_count': len(df),
                'songs': df.to_dict('records')
            }
            total_songs += len(df)
            print(f"✅ {idx}: {len(df):,} songs from {csv_path}")

    # crawl_progress.json에서 추가 데이터 확인
    if 'data' in progress_data:
        for char, char_data in progress_data['data'].items():
            if char not in all_data or len(char_data.get('songs', [])) > all_data[char]['actual_count']:
                all_data[char] = char_data
                total_songs = sum(len(data.get('songs', [])) for data in all_data.values())
                print(f"📊 {char}: {len(char_data.get('songs', [])):,} songs from crawl_progress.json")

    # 최종 CSV 생성
    if all_data:
        all_songs_list = []
        for char, char_data in all_data.items():
            for song in char_data.get('songs', []):
                song['index'] = char
                all_songs_list.append(song)

        # DataFrame 생성
        final_df = pd.DataFrame(all_songs_list)

        # 열 순서 정리
        columns = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
        for col in columns:
            if col not in final_df.columns:
                final_df[col] = None
        final_df = final_df[columns]

        # 저장
        csv_path = 'song_lists/all_songs_final.csv'
        json_path = 'song_lists/all_songs_final.json'

        final_df.to_csv(csv_path, index=False, encoding='utf-8')
        print(f"\n💾 Saved CSV: {csv_path}")

        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(all_data, f, ensure_ascii=False, indent=2)
        print(f"💾 Saved JSON: {json_path}")

        # 통계
        print(f"\n📈 Statistics:")
        print(f"  - Total songs: {len(final_df):,}")
        print(f"  - Unique artists: {final_df['artist'].nunique():,}")
        print(f"  - Indices collected: {', '.join(sorted(all_data.keys()))}")

        return final_df
    else:
        print("No data found to merge")
        return None


if __name__ == '__main__':
    merge_all_data()