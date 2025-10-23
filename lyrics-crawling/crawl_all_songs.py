#!/usr/bin/env python3
"""
J-Lyric 전체 노래 목록 크롤링 스크립트
"""

import argparse
import sys
import os
from jlyric_list_crawler import JLyricListCrawler


def main():
    parser = argparse.ArgumentParser(
        description='J-Lyric 사이트에서 노래 목록을 크롤링합니다.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
예제:
  # 전체 목록 크롤링
  python crawl_all_songs.py

  # 특정 문자만 크롤링
  python crawl_all_songs.py --index あ

  # 이전 진행 상황부터 재개
  python crawl_all_songs.py --resume

  # 느리게 크롤링 (서버 부하 감소)
  python crawl_all_songs.py --delay 3
        '''
    )

    parser.add_argument('--index', '-i', type=str,
                        help='특정 문자만 크롤링 (예: あ, い, A, 1)')
    parser.add_argument('--resume', '-r', action='store_true',
                        help='이전 진행 상황부터 재개')
    parser.add_argument('--delay', '-d', type=float, default=1.0,
                        help='요청 간 대기 시간 (초, 기본값: 1.0)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='자세한 출력 표시')

    args = parser.parse_args()

    # 크롤러 인스턴스 생성
    crawler = JLyricListCrawler(delay=args.delay)

    if args.verbose:
        print("J-Lyric 노래 목록 크롤러")
        print(f"대기 시간: {args.delay}초")
        print(f"재개 모드: {'예' if args.resume else '아니오'}")
        if args.index:
            print(f"대상 문자: {args.index}")
        print("=" * 50)

    try:
        # 크롤링 시작
        crawler.crawl_all_indexes(
            specific_index=args.index,
            resume=args.resume
        )

        print("\n크롤링이 성공적으로 완료되었습니다!")

    except KeyboardInterrupt:
        print("\n\n크롤링이 중단되었습니다.")
        print("진행 상황이 crawl_progress.json에 저장되었습니다.")
        print("--resume 옵션으로 재개할 수 있습니다.")
        sys.exit(0)

    except Exception as e:
        print(f"\n오류 발생: {e}", file=sys.stderr)
        print("진행 상황이 저장되었습니다. --resume 옵션으로 재개할 수 있습니다.")
        sys.exit(1)


if __name__ == '__main__':
    main()