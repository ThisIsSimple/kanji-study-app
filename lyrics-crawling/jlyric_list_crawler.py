import requests
from bs4 import BeautifulSoup
import json
import os
import time
import re
import csv
from typing import Dict, List, Optional, Tuple
from urllib.parse import urljoin


class JLyricListCrawler:
    """J-Lyric 사이트에서 노래 목록을 크롤링하는 클래스"""

    BASE_URL = "https://j-lyric.net"

    def __init__(self, delay: float = 1.0):
        """
        Args:
            delay: 요청 간 대기 시간 (초)
        """
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.delay = delay
        self.progress_file = 'crawl_progress.json'

    def make_full_url(self, relative_url: str) -> str:
        """
        상대 URL을 전체 URL로 변환합니다.

        Args:
            relative_url: 상대 경로 URL

        Returns:
            전체 URL
        """
        if relative_url.startswith('http'):
            return relative_url
        return urljoin(self.BASE_URL, relative_url)

    def get_index_links(self) -> List[Dict]:
        """
        히라가나 인덱스 페이지에서 모든 문자별 링크를 추출합니다.

        Returns:
            문자별 링크 정보 리스트
        """
        index_url = f"{self.BASE_URL}/lyric/i1p1.html"

        try:
            response = self.session.get(index_url)
            response.encoding = 'utf-8'
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'lxml')
            index_table = soup.select_one('#idx table')

            if not index_table:
                print("Index table not found")
                return []

            links = []

            # 테이블의 모든 링크 추출
            for link_element in index_table.select('a'):
                href = link_element.get('href')
                if href:
                    title = link_element.get('title', '')
                    character = link_element.text.strip()

                    # 곡 수 추출 (예: "「あ」で始まる歌詞18,347曲")
                    song_count_match = re.search(r'([0-9,]+)曲', title)
                    song_count = song_count_match.group(1).replace(',', '') if song_count_match else '0'

                    links.append({
                        'character': character,
                        'url': self.make_full_url(href),
                        'song_count': int(song_count)
                    })

            print(f"Found {len(links)} index links")
            return links

        except Exception as e:
            print(f"Error getting index links: {e}")
            return []

    def crawl_song_page(self, url: str) -> Tuple[List[Dict], Optional[str]]:
        """
        단일 페이지에서 노래 목록을 크롤링합니다.

        Args:
            url: 페이지 URL

        Returns:
            (노래 목록, 다음 페이지 URL)
        """
        try:
            response = self.session.get(url)
            response.encoding = 'utf-8'
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'lxml')
            songs = []

            # 노래 목록 추출
            song_divs = soup.select('div.bdy')

            for div in song_divs:
                # 제목과 링크
                title_elem = div.select_one('p.ttl a')
                if not title_elem:
                    continue

                title = title_elem.text.strip()
                song_url = self.make_full_url(title_elem.get('href', ''))

                # 가수 정보
                artist_elem = div.select_one('p.sml a')
                artist = artist_elem.text.strip() if artist_elem else None

                # 작사/작곡 정보
                info_text = div.select('p.sml')[1].text if len(div.select('p.sml')) > 1 else ''

                songwriter = None
                composer = None

                if '作詞' in info_text:
                    songwriter_match = re.search(r'作詞[：:]([^　\s]+)', info_text)
                    if songwriter_match:
                        songwriter = songwriter_match.group(1).strip()

                if '作曲' in info_text:
                    composer_match = re.search(r'作曲[：:]([^　\s]+)', info_text)
                    if composer_match:
                        composer = composer_match.group(1).strip()

                # 가사 미리보기
                preview_elem = div.select('p.sml')[-1] if div.select('p.sml') else None
                preview = None

                if preview_elem and '歌詞' in preview_elem.text:
                    preview_text = preview_elem.text.strip()
                    preview = preview_text.replace('歌詞：', '').strip()

                songs.append({
                    'title': title,
                    'url': song_url,
                    'artist': artist,
                    'songwriter': songwriter,
                    'composer': composer,
                    'preview': preview
                })

            # 다음 페이지 링크 찾기
            next_page_url = None
            pager = soup.select_one('#pager')

            if pager:
                # 현재 선택된 페이지 찾기
                current = pager.select_one('a.sel')
                if current:
                    # 다음 링크 찾기 (현재 페이지 다음 링크)
                    all_links = pager.select('a')
                    for i, link in enumerate(all_links):
                        if 'sel' in link.get('class', []) and i + 1 < len(all_links):
                            next_link = all_links[i + 1]
                            if 'sel' not in next_link.get('class', []):
                                next_page_url = self.make_full_url(next_link.get('href', ''))
                            break

            return songs, next_page_url

        except Exception as e:
            print(f"Error crawling page {url}: {e}")
            return [], None

    def crawl_all_pages(self, start_url: str, character: str, existing_songs: List[Dict] = None) -> List[Dict]:
        """
        특정 문자의 모든 페이지를 크롤링합니다.

        Args:
            start_url: 시작 URL
            character: 문자 (あ, い, 등)
            existing_songs: 기존에 수집된 노래 목록

        Returns:
            모든 노래 목록
        """
        all_songs = existing_songs if existing_songs else []

        # 이미 수집된 곡 수를 기준으로 시작 페이지 계산 (한 페이지에 50곡)
        start_page = (len(all_songs) // 50) + 1

        # 시작 URL 수정
        if start_page > 1:
            # URL에서 페이지 번호 변경
            import re
            current_url = re.sub(r'i(\d+)p\d+\.html', rf'i\1p{start_page}.html', start_url)
            print(f"Resuming from page {start_page}: {current_url}")
        else:
            current_url = start_url

        page_num = start_page

        while current_url:
            print(f"Crawling {character} page {page_num}: {current_url}")

            try:
                songs, next_url = self.crawl_song_page(current_url)

                if songs:
                    all_songs.extend(songs)
                    print(f"  Found {len(songs)} songs (total: {len(all_songs)})")

                    # 진행 상황 중간 저장 (매 5페이지마다)
                    if page_num % 5 == 0:
                        temp_progress = self.load_progress()
                        if character not in temp_progress.get('data', {}):
                            temp_progress['data'] = temp_progress.get('data', {})
                        temp_progress['data'][character] = {
                            'character': character,
                            'expected_count': temp_progress['data'].get(character, {}).get('expected_count', 0),
                            'actual_count': len(all_songs),
                            'songs': all_songs,
                            'last_page': page_num
                        }
                        self.save_progress(temp_progress)
                        print(f"  Progress saved at page {page_num}")

                current_url = next_url
                page_num += 1

                # 서버 부하 방지를 위한 대기
                if current_url:
                    time.sleep(self.delay)

            except Exception as e:
                print(f"Error on page {page_num}: {e}")
                # 에러 발생시에도 현재까지 수집된 데이터 저장
                return all_songs

        return all_songs

    def save_progress(self, data: Dict):
        """
        진행 상황을 저장합니다.

        Args:
            data: 저장할 데이터
        """
        with open(self.progress_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def load_progress(self) -> Dict:
        """
        저장된 진행 상황을 로드합니다.

        Returns:
            저장된 데이터
        """
        if os.path.exists(self.progress_file):
            with open(self.progress_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}

    def crawl_all_indexes(self, specific_index: str = None, resume: bool = False):
        """
        모든 인덱스 또는 특정 인덱스의 노래를 크롤링합니다.

        Args:
            specific_index: 특정 문자만 크롤링 (예: 'あ')
            resume: 이전 진행 상황부터 재개
        """
        # 진행 상황 로드
        progress = self.load_progress() if resume else {}
        completed_indexes = progress.get('completed', [])
        all_data = progress.get('data', {})

        # 인덱스 링크 가져오기
        index_links = self.get_index_links()

        if not index_links:
            print("Failed to get index links")
            return

        # 특정 인덱스만 필터링
        if specific_index:
            index_links = [link for link in index_links if link['character'] == specific_index]

        total_songs_collected = sum(len(data.get('songs', [])) for data in all_data.values())

        for link in index_links:
            character = link['character']

            # 이미 완료된 인덱스는 건너뛰기
            if character in completed_indexes:
                print(f"Skipping already completed index: {character}")
                continue

            print(f"\n{'='*50}")
            print(f"Starting to crawl index: {character} ({link['song_count']} songs expected)")
            print(f"{'='*50}")

            # 기존 데이터가 있는지 확인
            existing_songs = all_data.get(character, {}).get('songs', [])
            if existing_songs:
                print(f"Found existing {len(existing_songs)} songs for {character}")

            # 해당 문자의 모든 노래 크롤링
            songs = self.crawl_all_pages(link['url'], character, existing_songs)

            # 데이터 저장
            all_data[character] = {
                'character': character,
                'expected_count': link['song_count'],
                'actual_count': len(songs),
                'songs': songs
            }

            completed_indexes.append(character)
            total_songs_collected += len(songs)

            # 진행 상황 저장
            self.save_progress({
                'completed': completed_indexes,
                'data': all_data,
                'total_songs': total_songs_collected
            })

            print(f"Completed {character}: {len(songs)} songs")
            print(f"Total songs collected so far: {total_songs_collected}")

            # 인덱스 간 대기
            time.sleep(self.delay * 2)

        # 최종 결과 저장
        self.save_final_results(all_data)

    def save_final_results(self, data: Dict):
        """
        최종 결과를 다양한 형식으로 저장합니다.

        Args:
            data: 전체 데이터
        """
        # JSON 저장
        output_dir = 'song_lists'
        os.makedirs(output_dir, exist_ok=True)

        # 전체 데이터 JSON
        with open(os.path.join(output_dir, 'all_songs.json'), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        # CSV 저장 (분석용)
        csv_path = os.path.join(output_dir, 'all_songs.csv')
        with open(csv_path, 'w', encoding='utf-8', newline='') as csvfile:
            fieldnames = ['index', 'title', 'artist', 'songwriter', 'composer', 'url', 'preview']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for character, char_data in data.items():
                for song in char_data.get('songs', []):
                    writer.writerow({
                        'index': character,
                        'title': song.get('title'),
                        'artist': song.get('artist'),
                        'songwriter': song.get('songwriter'),
                        'composer': song.get('composer'),
                        'url': song.get('url'),
                        'preview': song.get('preview', '')[:100]  # 미리보기는 100자까지만
                    })

        # 통계 출력
        total_songs = sum(char_data.get('actual_count', 0) for char_data in data.values())
        print(f"\n{'='*50}")
        print(f"Crawling completed!")
        print(f"Total indexes: {len(data)}")
        print(f"Total songs: {total_songs}")
        print(f"Data saved to: {output_dir}/")
        print(f"{'='*50}")