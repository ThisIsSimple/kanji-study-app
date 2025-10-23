import requests
from bs4 import BeautifulSoup
import json
import os
from typing import Dict, Optional
import re


class JLyricCrawler:
    """J-Lyric 사이트에서 노래 정보를 크롤링하는 클래스"""

    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)

    def fetch_song_data(self, url: str) -> Optional[Dict]:
        """
        주어진 URL에서 노래 정보를 크롤링합니다.

        Args:
            url: J-Lyric 노래 페이지 URL

        Returns:
            노래 정보를 담은 딕셔너리 또는 None
        """
        try:
            response = self.session.get(url)
            response.encoding = 'utf-8'
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'lxml')

            # 노래 제목 추출
            title_element = soup.select_one('.cap h2')
            title = title_element.text.strip() if title_element else None
            # "「」" 제거
            if title:
                title = re.sub(r'[「」]', '', title)
                title = title.replace('歌詞', '').strip()

            # 가수 이름 추출
            artist_element = soup.select_one('.lbdy .sml a')
            artist = artist_element.text.strip() if artist_element else None

            # 작사/작곡 정보 추출
            info_elements = soup.select('.lbdy .sml')
            songwriter = None
            composer = None

            for elem in info_elements:
                text = elem.text.strip()
                if '作詞' in text:
                    # "作詞：" 이후의 텍스트 추출
                    songwriter_match = re.search(r'作詞[：:](.+?)(?:　|$)', text)
                    if songwriter_match:
                        songwriter = songwriter_match.group(1).strip()

                    # "作曲：" 이후의 텍스트 추출
                    composer_match = re.search(r'作曲[：:](.+?)(?:　|$)', text)
                    if composer_match:
                        composer = composer_match.group(1).strip()

            # 가사 추출 (줄바꿈 보존)
            lyric_element = soup.select_one('#Lyric')
            lyrics = None

            if lyric_element:
                # br 태그를 줄바꿈으로 변환
                for br in lyric_element.find_all('br'):
                    br.replace_with('\n')

                lyrics = lyric_element.get_text().strip()

                # 연속된 줄바꿈을 정리
                lyrics = re.sub(r'\n{3,}', '\n\n', lyrics)

            # 결과 딕셔너리 생성
            result = {
                'url': url,
                'title': title,
                'artist': artist,
                'songwriter': songwriter,
                'composer': composer,
                'lyrics': lyrics
            }

            return result

        except requests.RequestException as e:
            print(f"Error fetching URL {url}: {e}")
            return None
        except Exception as e:
            print(f"Error parsing data: {e}")
            return None

    def save_to_json(self, data: Dict, filepath: str):
        """
        데이터를 JSON 파일로 저장합니다.

        Args:
            data: 저장할 데이터
            filepath: 저장할 파일 경로
        """
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"Data saved to {filepath}")

    def save_to_txt(self, data: Dict, filepath: str):
        """
        가사를 텍스트 파일로 저장합니다.

        Args:
            data: 노래 데이터
            filepath: 저장할 파일 경로
        """
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(f"제목: {data.get('title', 'Unknown')}\n")
            f.write(f"가수: {data.get('artist', 'Unknown')}\n")
            f.write(f"작사: {data.get('songwriter', 'Unknown')}\n")
            f.write(f"작곡: {data.get('composer', 'Unknown')}\n")
            f.write("=" * 50 + "\n\n")
            f.write(data.get('lyrics', ''))

        print(f"Lyrics saved to {filepath}")

    def crawl_and_save(self, url: str, output_dir: str = 'data', format: str = 'json'):
        """
        URL에서 데이터를 크롤링하고 저장합니다.

        Args:
            url: J-Lyric 노래 페이지 URL
            output_dir: 출력 디렉토리
            format: 저장 형식 ('json', 'txt', 'both')
        """
        # 데이터 크롤링
        data = self.fetch_song_data(url)

        if not data:
            print("Failed to fetch data")
            return None

        # 파일명 생성 (가수_제목)
        filename_base = f"{data['artist']}_{data['title']}" if data['artist'] and data['title'] else "unknown"
        # 파일명에 사용할 수 없는 문자 제거
        filename_base = re.sub(r'[<>:"/\\|?*]', '_', filename_base)

        # 지정된 형식으로 저장
        if format in ['json', 'both']:
            json_path = os.path.join(output_dir, f"{filename_base}.json")
            self.save_to_json(data, json_path)

        if format in ['txt', 'both']:
            txt_path = os.path.join(output_dir, f"{filename_base}.txt")
            self.save_to_txt(data, txt_path)

        return data