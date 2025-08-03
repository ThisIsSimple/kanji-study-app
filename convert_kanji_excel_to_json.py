#!/usr/bin/env python3
"""
한자 Excel 파일을 JSON으로 변환하는 스크립트
Excel 파일에서 한자 데이터를 읽어 Flutter 앱에서 사용할 수 있는 JSON 형태로 변환합니다.
"""

import pandas as pd
import json
import re
from datetime import datetime

def parse_meaning(meaning_text):
    """
    뜻 필드를 파싱합니다.
    예: "노래 가" -> ["노래"]
    """
    if pd.isna(meaning_text):
        return []
    
    # 마지막 한글 발음 제거 (예: "노래 가" -> "노래")
    parts = str(meaning_text).strip().split()
    if len(parts) > 1 and len(parts[-1]) == 1:  # 마지막이 한 글자면 발음으로 간주
        meanings = parts[:-1]
    else:
        meanings = parts
    
    return meanings

def parse_readings(reading_text):
    """
    읽기를 파싱합니다.
    예: "か、け" -> ["か", "け"]
    """
    if pd.isna(reading_text) or reading_text == '':
        return []
    
    # 쉼표, 중점(・), 공백으로 분리
    readings = re.split('[、・ ]', str(reading_text).strip())
    # 빈 문자열 제거
    readings = [r.strip() for r in readings if r.strip()]
    
    return readings

def estimate_grade(index):
    """
    인덱스를 기반으로 대략적인 학년을 추정합니다.
    실제 학년 데이터가 없으므로 빈도를 기반으로 추정
    """
    if index < 80:
        return 1
    elif index < 240:
        return 2
    elif index < 440:
        return 3
    elif index < 640:
        return 4
    elif index < 825:
        return 5
    elif index < 1006:
        return 6
    else:
        return 7  # 중학교 이상

def estimate_jlpt(index):
    """
    인덱스를 기반으로 JLPT 레벨을 추정합니다.
    """
    if index < 100:
        return 5  # N5 (가장 쉬움)
    elif index < 300:
        return 4  # N4
    elif index < 600:
        return 3  # N3
    elif index < 1200:
        return 2  # N2
    else:
        return 1  # N1 (가장 어려움)

def convert_excel_to_json(excel_path, json_path):
    """Excel 파일을 JSON으로 변환합니다."""
    
    print("Excel 파일 읽기 중...")
    df = pd.read_excel(excel_path)
    
    kanji_list = []
    
    print("데이터 변환 중...")
    for index, row in df.iterrows():
        kanji_data = {
            "id": int(row['번호']),
            "character": str(row['한자']).strip(),
            "meanings": parse_meaning(row['뜻']),
            "readings": {
                "on": parse_readings(row['음독']),  # 음독
                "kun": parse_readings(row['훈독'])  # 훈독
            },
            "grade": estimate_grade(index),
            "jlpt": estimate_jlpt(index),
            "strokeCount": 0,  # Excel에 획수 정보가 없음
            "frequency": index + 1,  # 순서를 빈도로 사용
            "examples": []  # 예시는 나중에 추가
        }
        
        kanji_list.append(kanji_data)
    
    # 전체 데이터 구조
    data = {
        "kanji": kanji_list,
        "metadata": {
            "totalCount": len(kanji_list),
            "lastUpdated": datetime.now().strftime("%Y-%m-%d"),
            "source": "한자(2136자).xlsx"
        }
    }
    
    # JSON 파일로 저장
    print(f"JSON 파일 저장 중: {json_path}")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"변환 완료! 총 {len(kanji_list)}개의 한자가 변환되었습니다.")
    
    # 통계 출력
    print("\n=== 변환 통계 ===")
    print(f"총 한자 수: {len(kanji_list)}")
    
    # 학년별 통계
    grade_counts = {}
    for kanji in kanji_list:
        grade = kanji['grade']
        grade_counts[grade] = grade_counts.get(grade, 0) + 1
    
    print("\n학년별 한자 수:")
    for grade in sorted(grade_counts.keys()):
        print(f"  {grade}학년: {grade_counts[grade]}개")
    
    # JLPT 레벨별 통계
    jlpt_counts = {}
    for kanji in kanji_list:
        jlpt = kanji['jlpt']
        jlpt_counts[jlpt] = jlpt_counts.get(jlpt, 0) + 1
    
    print("\nJLPT 레벨별 한자 수:")
    for level in sorted(jlpt_counts.keys()):
        print(f"  N{level}: {jlpt_counts[level]}개")

if __name__ == "__main__":
    excel_file = "/Users/cordelia273/Downloads/한자(2136자).xlsx"
    json_file = "/Users/cordelia273/Projects/kanji/kanji_study_app/kanji_data.json"
    
    convert_excel_to_json(excel_file, json_file)