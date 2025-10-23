#!/usr/bin/env python3
"""
'き' 인덱스 데이터를 CSV 파일로 저장하는 스크립트
"""

import json
import csv
import os

def save_ki_to_csv():
    # crawl_progress.json 읽기
    with open('crawl_progress.json', 'r') as f:
        data = json.load(f)

    if 'き' not in data.get('data', {}):
        print('き data not found in crawl_progress.json')
        return False

    ki_data = data['data']['き']
    songs = ki_data.get('songs', [])

    if not songs:
        print('No songs found for き')
        return False

    # indexes 폴더가 없으면 생성
    os.makedirs('song_lists/indexes', exist_ok=True)

    # CSV 파일로 저장
    csv_path = 'song_lists/indexes/き.csv'
    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        # 필드명 정의
        fieldnames = ['title', 'url', 'artist', 'songwriter', 'composer', 'preview']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        # 헤더 작성
        writer.writeheader()

        # 데이터 작성
        for song in songs:
            writer.writerow({
                'title': song.get('title', ''),
                'url': song.get('url', ''),
                'artist': song.get('artist', ''),
                'songwriter': song.get('songwriter', ''),
                'composer': song.get('composer', ''),
                'preview': song.get('preview', '')
            })

    print(f'Successfully saved {len(songs):,} songs to {csv_path}')
    return True

if __name__ == '__main__':
    save_ki_to_csv()