#!/usr/bin/env python3
"""
J-Lyric 크롤러 실행 스크립트
"""

import argparse
import sys
from jlyric_crawler import JLyricCrawler


def main():
    parser = argparse.ArgumentParser(description='J-Lyric 사이트에서 노래 정보를 크롤링합니다.')
    parser.add_argument('--url', '-u', type=str, required=True,
                        help='크롤링할 J-Lyric 페이지 URL')
    parser.add_argument('--output', '-o', type=str, default='data',
                        help='출력 디렉토리 (기본값: data)')
    parser.add_argument('--format', '-f', type=str, choices=['json', 'txt', 'both'],
                        default='both', help='저장 형식 (기본값: both)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='자세한 출력 표시')

    args = parser.parse_args()

    # 크롤러 인스턴스 생성
    crawler = JLyricCrawler()

    if args.verbose:
        print(f"크롤링 시작: {args.url}")
        print(f"출력 디렉토리: {args.output}")
        print(f"저장 형식: {args.format}")
        print("=" * 50)

    # 크롤링 및 저장
    result = crawler.crawl_and_save(args.url, args.output, args.format)

    if result:
        print("\n크롤링 완료!")
        print(f"제목: {result['title']}")
        print(f"가수: {result['artist']}")
        print(f"작사: {result['songwriter']}")
        print(f"작곡: {result['composer']}")

        if args.verbose and result['lyrics']:
            print("\n가사 미리보기 (처음 100자):")
            preview = result['lyrics'][:100] + "..." if len(result['lyrics']) > 100 else result['lyrics']
            print(preview)
    else:
        print("크롤링 실패!", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()