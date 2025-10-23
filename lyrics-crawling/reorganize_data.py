#!/usr/bin/env python3
"""
모든 인덱스별 CSV 파일을 하나의 최종 파일로 병합하는 스크립트
"""

import pandas as pd
import os
from datetime import datetime
import glob

def reorganize_data():
    """indexes 디렉토리의 모든 CSV 파일을 병합"""

    print(f"\n{'='*60}")
    print(f"Data Reorganization - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}\n")

    # indexes 디렉토리의 모든 CSV 파일 찾기
    index_dir = 'song_lists/indexes'
    csv_files = glob.glob(os.path.join(index_dir, '*.csv'))

    if not csv_files:
        print(f"❌ No CSV files found in {index_dir}")
        return None

    # 모든 CSV 파일 읽어서 병합
    all_dataframes = []
    total_songs = 0

    # 정렬된 순서로 파일 처리
    csv_files.sort()

    for csv_file in csv_files:
        filename = os.path.basename(csv_file)
        index_char = filename.replace('.csv', '')

        try:
            df = pd.read_csv(csv_file, encoding='utf-8')

            # index 열이 없거나 비어있으면 파일명에서 추출한 문자로 설정
            if 'index' not in df.columns or df['index'].isna().all():
                df['index'] = index_char

            all_dataframes.append(df)
            count = len(df)
            total_songs += count
            print(f"✅ Loaded {index_char}: {count:,} songs")

        except Exception as e:
            print(f"❌ Error loading {filename}: {e}")
            continue

    if not all_dataframes:
        print("❌ No data could be loaded")
        return None

    # 모든 데이터프레임 병합
    print(f"\n📊 Merging all data...")
    final_df = pd.concat(all_dataframes, ignore_index=True)

    # 열 순서 정리
    columns = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
    for col in columns:
        if col not in final_df.columns:
            final_df[col] = None
    final_df = final_df[columns]

    # 중복 제거 (URL 기준)
    before_dedup = len(final_df)
    final_df = final_df.drop_duplicates(subset=['url'], keep='first')
    after_dedup = len(final_df)

    if before_dedup != after_dedup:
        print(f"⚠️  Removed {before_dedup - after_dedup} duplicate entries")

    # 최종 파일 저장
    output_path = 'song_lists/all_songs.csv'
    final_df.to_csv(output_path, index=False, encoding='utf-8')
    print(f"\n💾 Saved final data to: {output_path}")

    # 통계 정보 출력
    print(f"\n{'='*60}")
    print(f"📈 Final Statistics:")
    print(f"{'='*60}")
    print(f"  Total songs: {len(final_df):,}")
    print(f"  Unique artists: {final_df['artist'].nunique():,}")
    print(f"\n  Data distribution by index:")

    # 인덱스별 분포를 히라가나 순서로 정렬
    index_order = ['あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ',
                   'さ', 'し', 'す', 'せ', 'そ', 'た', 'ち', 'つ', 'て', 'と',
                   'な', 'に', 'ぬ', 'ね', 'の', 'は', 'ひ', 'ふ', 'へ', 'ほ',
                   'ま', 'み', 'む', 'め', 'も', 'や', 'ゆ', 'よ',
                   'ら', 'り', 'る', 'れ', 'ろ', 'わ', 'を', 'ん']

    index_counts = final_df['index'].value_counts()

    # 존재하는 인덱스만 순서대로 출력
    for idx in index_order:
        if idx in index_counts.index:
            count = index_counts[idx]
            print(f"    {idx}: {count:,} songs")

    # 히라가나가 아닌 다른 인덱스가 있으면 추가로 출력
    other_indices = [idx for idx in index_counts.index if idx not in index_order]
    if other_indices:
        print(f"\n  Other indices:")
        for idx in sorted(other_indices):
            count = index_counts[idx]
            print(f"    {idx}: {count:,} songs")

    print(f"\n✨ Data reorganization completed successfully!")
    return final_df


if __name__ == '__main__':
    reorganize_data()