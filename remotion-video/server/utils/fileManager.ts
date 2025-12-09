import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

const TEMP_DIR_CLOUD = '/tmp/remotion-renders';
const TEMP_DIR_LOCAL = path.join(process.cwd(), 'tmp', 'remotion-renders');

/**
 * 임시 디렉토리 경로를 반환합니다.
 * Cloud Run 환경에서는 /tmp를, 로컬에서는 ./tmp를 사용합니다.
 */
export function getTempDirectory(): string {
  // Cloud Run 환경 감지: /tmp 디렉토리가 쓰기 가능한지 확인
  if (process.env.NODE_ENV === 'production' || fs.existsSync('/tmp')) {
    return TEMP_DIR_CLOUD;
  }
  return TEMP_DIR_LOCAL;
}

/**
 * 임시 디렉토리를 생성합니다 (존재하지 않는 경우).
 */
export async function ensureTempDirectory(): Promise<string> {
  const tempDir = getTempDirectory();
  await fs.promises.mkdir(tempDir, { recursive: true });
  return tempDir;
}

/**
 * 고유한 임시 파일 경로를 생성합니다.
 * 형식: quiz-{timestamp}-{randomId}.mp4
 */
export function generateTempFilePath(): string {
  const timestamp = Date.now();
  const randomId = crypto.randomBytes(8).toString('hex');
  const filename = `quiz-${timestamp}-${randomId}.mp4`;
  const tempDir = getTempDirectory();
  return path.join(tempDir, filename);
}

/**
 * 고유한 임시 썸네일 파일 경로를 생성합니다.
 * 형식: quiz-thumbnail-{timestamp}-{randomId}.png
 */
export function generateTempThumbnailPath(): string {
  const timestamp = Date.now();
  const randomId = crypto.randomBytes(8).toString('hex');
  const filename = `quiz-thumbnail-${timestamp}-${randomId}.png`;
  const tempDir = getTempDirectory();
  return path.join(tempDir, filename);
}

/**
 * 파일을 정리합니다 (삭제).
 * 삭제 실패 시에도 에러를 throw하지 않고 로그만 기록합니다.
 */
export async function cleanupFile(filePath: string): Promise<void> {
  try {
    // 파일 존재 여부 확인
    await fs.promises.access(filePath);
    // 파일 삭제
    await fs.promises.unlink(filePath);
    console.log(`Cleaned up: ${filePath}`);
  } catch (error: any) {
    // 파일이 존재하지 않거나 삭제 실패 시 로그만 기록
    if (error.code === 'ENOENT') {
      // 파일이 없는 것은 정상 (이미 삭제되었거나 생성되지 않음)
      return;
    }
    // 삭제 실패는 로그만 기록, 프로세스 중단하지 않음
    console.error(`Failed to cleanup ${filePath}:`, error);
  }
}

/**
 * 오래된 파일을 정리합니다 (로컬 개발 환경용).
 * @param maxAgeMs 최대 보관 시간 (밀리초). 기본값: 1시간
 */
export async function cleanupOldFiles(maxAgeMs: number = 60 * 60 * 1000): Promise<void> {
  try {
    const tempDir = getTempDirectory();
    
    // 디렉토리 존재 여부 확인
    try {
      await fs.promises.access(tempDir);
    } catch {
      // 디렉토리가 없으면 정리할 파일이 없으므로 조용히 반환
      return;
    }
    
    const files = await fs.promises.readdir(tempDir);
    const now = Date.now();
    let cleanedCount = 0;

    for (const file of files) {
      const filePath = path.join(tempDir, file);
      try {
        const stats = await fs.promises.stat(filePath);
        const age = now - stats.mtimeMs;

        if (age > maxAgeMs) {
          await fs.promises.unlink(filePath);
          cleanedCount++;
          console.log(`Cleaned up old file: ${filePath} (age: ${Math.round(age / 1000)}s)`);
        }
      } catch (error) {
        // 개별 파일 처리 실패는 무시
        console.error(`Failed to process ${filePath}:`, error);
      }
    }

    if (cleanedCount > 0) {
      console.log(`Cleaned up ${cleanedCount} old file(s)`);
    }
  } catch (error) {
    // 디렉토리 읽기 실패는 로그만 기록
    console.error('Failed to cleanup old files:', error);
  }
}

