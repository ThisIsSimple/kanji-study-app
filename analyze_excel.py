#!/usr/bin/env python3
"""
Excel 파일 구조 분석 스크립트
한자 데이터의 열 구조와 샘플 데이터를 확인합니다.
"""

import pandas as pd
import sys

def analyze_excel_structure(file_path):
    """Excel 파일의 구조를 분석합니다."""
    try:
        # Excel 파일 읽기
        df = pd.read_excel(file_path)
        
        print("=== Excel 파일 분석 결과 ===")
        print(f"\n총 행 수: {len(df)}")
        print(f"총 열 수: {len(df.columns)}")
        
        print("\n열 이름:")
        for i, col in enumerate(df.columns):
            print(f"  {i}: {col}")
        
        print("\n첫 5행 데이터:")
        print(df.head())
        
        print("\n각 열의 데이터 타입:")
        print(df.dtypes)
        
        print("\n각 열의 null 값 개수:")
        print(df.isnull().sum())
        
        # 첫 번째 행의 상세 데이터
        if len(df) > 0:
            print("\n첫 번째 행 상세 데이터:")
            for col in df.columns:
                print(f"  {col}: {df.iloc[0][col]}")
        
    except Exception as e:
        print(f"오류 발생: {e}")
        sys.exit(1)

if __name__ == "__main__":
    excel_file = "/Users/cordelia273/Downloads/한자(2136자).xlsx"
    analyze_excel_structure(excel_file)