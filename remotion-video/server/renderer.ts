import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import * as path from 'path';
import { QuizQuestion } from '../src/types/quiz';
import { generateTempFilePath, generateTempThumbnailPath, ensureTempDirectory, cleanupFile } from './utils/fileManager';

const BUNDLE_PATH = path.join(process.cwd(), 'build');
const COMPOSITION_ID = 'QuizVideo';
const FPS = 30;
const WIDTH = 1080;
const HEIGHT = 1920;
const TOTAL_DURATION = 23; // 초 단위

/**
 * 퀴즈 문제 데이터를 받아 영상을 렌더링합니다.
 * @param question 퀴즈 문제 데이터
 * @returns 렌더링된 영상 파일 경로
 */
export async function renderQuizVideo(question: QuizQuestion): Promise<string> {
  // 임시 디렉토리 생성
  await ensureTempDirectory();
  
  // 고유한 임시 파일 경로 생성
  const outputPath = generateTempFilePath();
  
  try {
    // Composition 선택
    const composition = await selectComposition({
      serveUrl: BUNDLE_PATH,
      id: COMPOSITION_ID,
      inputProps: {
        question,
      },
    });

    // 영상 렌더링
    await renderMedia({
      composition,
      serveUrl: BUNDLE_PATH,
      codec: 'h264',
      outputLocation: outputPath,
      inputProps: {
        question,
      },
      onProgress: ({ progress }) => {
        // 진행률 로깅 (선택사항)
        if (Math.floor(progress * 100) % 10 === 0) {
          console.log(`Rendering progress: ${Math.floor(progress * 100)}%`);
        }
      },
    });

    console.log(`Video rendered successfully: ${outputPath}`);
    return outputPath;
  } catch (error) {
    // 렌더링 실패 시 생성된 파일 정리 시도
    await cleanupFile(outputPath);
    throw error;
  }
}

/**
 * 렌더링 타임아웃을 설정하여 영상을 렌더링합니다.
 * @param question 퀴즈 문제 데이터
 * @param timeoutMs 타임아웃 시간 (밀리초). 기본값: 60000ms (60초)
 * @returns 렌더링된 영상 파일 경로
 */
export async function renderQuizVideoWithTimeout(
  question: QuizQuestion,
  timeoutMs: number = 60000
): Promise<string> {
  return new Promise(async (resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error(`Rendering timeout after ${timeoutMs}ms`));
    }, timeoutMs);

    try {
      const outputPath = await renderQuizVideo(question);
      clearTimeout(timeoutId);
      resolve(outputPath);
    } catch (error) {
      clearTimeout(timeoutId);
      reject(error);
    }
  });
}

/**
 * 퀴즈 문제 데이터를 받아 썸네일 이미지를 렌더링합니다.
 * 첫 번째 프레임(인트로 화면)을 PNG 형식으로 렌더링합니다.
 * @param question 퀴즈 문제 데이터
 * @returns 렌더링된 썸네일 파일 경로
 */
export async function renderQuizThumbnail(question: QuizQuestion): Promise<string> {
  // 임시 디렉토리 생성
  await ensureTempDirectory();
  
  // 고유한 임시 파일 경로 생성
  const outputPath = generateTempThumbnailPath();
  
  try {
    // Composition 선택
    const composition = await selectComposition({
      serveUrl: BUNDLE_PATH,
      id: COMPOSITION_ID,
      inputProps: {
        question,
      },
    });

    // 첫 번째 프레임(프레임 0)을 PNG 형식으로 렌더링
    await renderStill({
      composition,
      serveUrl: BUNDLE_PATH,
      output: outputPath,
      frame: 0,
      imageFormat: 'png',
      inputProps: {
        question,
      },
    });

    console.log(`Thumbnail rendered successfully: ${outputPath}`);
    return outputPath;
  } catch (error) {
    // 렌더링 실패 시 생성된 파일 정리 시도
    await cleanupFile(outputPath);
    throw error;
  }
}

/**
 * 렌더링 타임아웃을 설정하여 썸네일을 렌더링합니다.
 * @param question 퀴즈 문제 데이터
 * @param timeoutMs 타임아웃 시간 (밀리초). 기본값: 30000ms (30초)
 * @returns 렌더링된 썸네일 파일 경로
 */
export async function renderQuizThumbnailWithTimeout(
  question: QuizQuestion,
  timeoutMs: number = 30000
): Promise<string> {
  return new Promise(async (resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error(`Thumbnail rendering timeout after ${timeoutMs}ms`));
    }, timeoutMs);

    try {
      const outputPath = await renderQuizThumbnail(question);
      clearTimeout(timeoutId);
      resolve(outputPath);
    } catch (error) {
      clearTimeout(timeoutId);
      reject(error);
    }
  });
}

