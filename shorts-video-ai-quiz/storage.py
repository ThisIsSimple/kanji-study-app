"""
Storage - 로컬/GCS 저장소 추상화
디버깅용 영상 저장 기능 제공
"""

import os
from abc import ABC, abstractmethod
from pathlib import Path
from datetime import datetime

# GCS 사용 여부에 따라 조건부 import
try:
    from google.cloud import storage as gcs_storage
    GCS_AVAILABLE = True
except ImportError:
    GCS_AVAILABLE = False


class StorageBackend(ABC):
    """저장소 추상 클래스"""
    
    @abstractmethod
    def save(self, data: bytes, filename: str) -> str:
        """
        데이터 저장
        
        Args:
            data: 저장할 바이트 데이터
            filename: 파일명
        
        Returns:
            str: 저장된 파일의 URL 또는 경로
        """
        pass
    
    @abstractmethod
    def exists(self, filename: str) -> bool:
        """파일 존재 여부 확인"""
        pass


class LocalStorage(StorageBackend):
    """로컬 파일시스템 저장소"""
    
    def __init__(self, base_dir: str = "./output"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
    
    def save(self, data: bytes, filename: str) -> str:
        """로컬에 파일 저장"""
        file_path = self.base_dir / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(file_path, "wb") as f:
            f.write(data)
        
        return str(file_path.absolute())
    
    def exists(self, filename: str) -> bool:
        """파일 존재 여부 확인"""
        file_path = self.base_dir / filename
        return file_path.exists()
    
    def get_path(self, filename: str) -> str:
        """파일 경로 반환"""
        return str((self.base_dir / filename).absolute())


class GCSStorage(StorageBackend):
    """Google Cloud Storage 저장소"""
    
    def __init__(self, bucket_name: str, prefix: str = "videos"):
        if not GCS_AVAILABLE:
            raise RuntimeError(
                "google-cloud-storage 패키지가 설치되지 않았습니다. "
                "pip install google-cloud-storage 를 실행해주세요."
            )
        
        self.bucket_name = bucket_name
        self.prefix = prefix
        self.client = gcs_storage.Client()
        self.bucket = self.client.bucket(bucket_name)
    
    def save(self, data: bytes, filename: str) -> str:
        """GCS에 파일 저장"""
        blob_name = f"{self.prefix}/{filename}"
        blob = self.bucket.blob(blob_name)
        
        blob.upload_from_string(data, content_type="video/mp4")
        
        # Public URL 반환 (또는 signed URL 사용 가능)
        return f"gs://{self.bucket_name}/{blob_name}"
    
    def exists(self, filename: str) -> bool:
        """파일 존재 여부 확인"""
        blob_name = f"{self.prefix}/{filename}"
        blob = self.bucket.blob(blob_name)
        return blob.exists()
    
    def get_public_url(self, filename: str) -> str:
        """Public URL 반환"""
        blob_name = f"{self.prefix}/{filename}"
        return f"https://storage.googleapis.com/{self.bucket_name}/{blob_name}"


class StorageManager:
    """
    저장소 관리자
    환경 변수에 따라 로컬 또는 GCS 저장소 사용
    """
    
    def __init__(self):
        self.debug_save_enabled = os.getenv("DEBUG_SAVE_VIDEO", "false").lower() == "true"
        self.storage_type = os.getenv("STORAGE_TYPE", "local").lower()
        
        self._storage: StorageBackend | None = None
        
        if self.debug_save_enabled:
            self._init_storage()
    
    def _init_storage(self):
        """저장소 초기화"""
        if self.storage_type == "gcs":
            bucket_name = os.getenv("GCS_BUCKET")
            if not bucket_name:
                raise ValueError("GCS_BUCKET 환경 변수가 설정되지 않았습니다.")
            self._storage = GCSStorage(bucket_name)
        else:
            output_dir = os.getenv("OUTPUT_DIR", "./output")
            self._storage = LocalStorage(output_dir)
    
    @property
    def storage(self) -> StorageBackend | None:
        """저장소 인스턴스 반환"""
        return self._storage
    
    def save_video(self, video_bytes: bytes, question_id: int) -> str | None:
        """
        영상 저장 (디버그 모드일 때만)
        
        Args:
            video_bytes: 영상 바이트 데이터
            question_id: 문제 ID
        
        Returns:
            str | None: 저장된 파일 경로/URL (디버그 모드 아니면 None)
        """
        if not self.debug_save_enabled or self._storage is None:
            return None
        
        # 타임스탬프 포함 파일명
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"quiz_{question_id}_{timestamp}.mp4"
        
        saved_path = self._storage.save(video_bytes, filename)
        return saved_path
    
    def is_debug_enabled(self) -> bool:
        """디버그 저장 활성화 여부"""
        return self.debug_save_enabled
    
    def get_storage_info(self) -> dict:
        """저장소 정보 반환"""
        return {
            "debug_save_enabled": self.debug_save_enabled,
            "storage_type": self.storage_type,
            "gcs_bucket": os.getenv("GCS_BUCKET") if self.storage_type == "gcs" else None,
            "output_dir": os.getenv("OUTPUT_DIR", "./output") if self.storage_type == "local" else None,
        }


# 싱글톤 인스턴스
_storage_manager: StorageManager | None = None


def get_storage_manager() -> StorageManager:
    """StorageManager 싱글톤 인스턴스 반환"""
    global _storage_manager
    if _storage_manager is None:
        _storage_manager = StorageManager()
    return _storage_manager


# 테스트용
if __name__ == "__main__":
    # 환경 변수 설정 테스트
    os.environ["DEBUG_SAVE_VIDEO"] = "true"
    os.environ["STORAGE_TYPE"] = "local"
    os.environ["OUTPUT_DIR"] = "./test_output"
    
    manager = StorageManager()
    print(f"📁 저장소 정보: {manager.get_storage_info()}")
    
    # 테스트 데이터 저장
    test_data = b"test video data"
    saved_path = manager.save_video(test_data, question_id=123)
    print(f"✅ 저장됨: {saved_path}")
