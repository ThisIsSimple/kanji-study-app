import express, { Request, Response } from 'express';
import * as fs from 'fs';
import { QuizQuestion } from '../src/types/quiz';
import { renderQuizVideoWithTimeout, renderQuizThumbnailWithTimeout } from './renderer';
import { cleanupFile, cleanupOldFiles } from './utils/fileManager';

const app = express();
const PORT = process.env.PORT || 8080;

// JSON 파싱 미들웨어
app.use(express.json({ limit: '10mb' }));

// 헬스 체크 엔드포인트
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 영상 렌더링 엔드포인트
app.post('/render', async (req: Request, res: Response) => {
  let outputPath: string | null = null;

  try {
    // 요청 본문에서 퀴즈 데이터 추출
    const question: QuizQuestion = req.body;

    // 데이터 검증
    if (!question || !question.question || !question.options || !question.correct_answer) {
      return res.status(400).json({
        error: 'Invalid request body',
        message: 'Missing required fields: question, options, correct_answer',
      });
    }

    // options가 4개인지 확인
    if (!Array.isArray(question.options) || question.options.length !== 4) {
      return res.status(400).json({
        error: 'Invalid request body',
        message: 'options must be an array with exactly 4 elements',
      });
    }

    console.log(`Rendering video for question: ${question.question}`);

    // 영상 렌더링 (타임아웃: 60초)
    outputPath = await renderQuizVideoWithTimeout(question, 60000);

    // 파일 존재 확인
    if (!fs.existsSync(outputPath)) {
      throw new Error('Rendered file does not exist');
    }

    // 파일 크기 확인 (로깅용)
    const stats = await fs.promises.stat(outputPath);
    console.log(`Video file size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

    // 파일 스트리밍으로 응답
    res.setHeader('Content-Type', 'video/mp4');
    res.setHeader('Content-Disposition', `attachment; filename="quiz-video-${question.id || Date.now()}.mp4"`);
    res.setHeader('Content-Length', stats.size.toString());

    const stream = fs.createReadStream(outputPath);

    // 스트림 이벤트 핸들링
    stream.on('error', (error) => {
      console.error('Stream error:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Failed to stream video' });
      }
      // 스트림 에러 시에도 파일 정리
      cleanupFile(outputPath!).catch(() => {});
    });

    stream.on('end', () => {
      console.log('Video stream completed');
      // 스트림 완료 후 파일 정리
      cleanupFile(outputPath!).catch(() => {});
    });

    // 스트림을 응답으로 파이프
    stream.pipe(res);

    // 응답 종료 시 파일 정리 (안전장치)
    res.on('close', () => {
      if (outputPath) {
        cleanupFile(outputPath).catch(() => {});
      }
    });
  } catch (error: any) {
    console.error('Rendering error:', error);

    // 에러 발생 시 파일 정리
    if (outputPath) {
      await cleanupFile(outputPath).catch(() => {});
    }

    // 응답이 아직 전송되지 않았다면 에러 응답
    if (!res.headersSent) {
      const statusCode = error.message?.includes('timeout') ? 504 : 500;
      res.status(statusCode).json({
        error: 'Rendering failed',
        message: error.message || 'Unknown error occurred',
      });
    }
  }
});

// 썸네일 생성 엔드포인트
app.post('/thumbnail', async (req: Request, res: Response) => {
  let outputPath: string | null = null;

  try {
    // 요청 본문에서 퀴즈 데이터 추출
    const question: QuizQuestion = req.body;

    // 데이터 검증
    if (!question || !question.question || !question.options || !question.correct_answer) {
      return res.status(400).json({
        error: 'Invalid request body',
        message: 'Missing required fields: question, options, correct_answer',
      });
    }

    // options가 4개인지 확인
    if (!Array.isArray(question.options) || question.options.length !== 4) {
      return res.status(400).json({
        error: 'Invalid request body',
        message: 'options must be an array with exactly 4 elements',
      });
    }

    console.log(`Rendering thumbnail for question: ${question.question}`);

    // 썸네일 렌더링 (타임아웃: 30초)
    outputPath = await renderQuizThumbnailWithTimeout(question, 30000);

    // 파일 존재 확인
    if (!fs.existsSync(outputPath)) {
      throw new Error('Rendered thumbnail file does not exist');
    }

    // 파일 크기 확인 (로깅용)
    const stats = await fs.promises.stat(outputPath);
    console.log(`Thumbnail file size: ${(stats.size / 1024).toFixed(2)} KB`);

    // 파일 스트리밍으로 응답
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Disposition', `attachment; filename="quiz-thumbnail-${question.id || Date.now()}.png"`);
    res.setHeader('Content-Length', stats.size.toString());

    const stream = fs.createReadStream(outputPath);

    // 스트림 이벤트 핸들링
    stream.on('error', (error) => {
      console.error('Stream error:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Failed to stream thumbnail' });
      }
      // 스트림 에러 시에도 파일 정리
      cleanupFile(outputPath!).catch(() => {});
    });

    stream.on('end', () => {
      console.log('Thumbnail stream completed');
      // 스트림 완료 후 파일 정리
      cleanupFile(outputPath!).catch(() => {});
    });

    // 스트림을 응답으로 파이프
    stream.pipe(res);

    // 응답 종료 시 파일 정리 (안전장치)
    res.on('close', () => {
      if (outputPath) {
        cleanupFile(outputPath).catch(() => {});
      }
    });
  } catch (error: any) {
    console.error('Thumbnail rendering error:', error);

    // 에러 발생 시 파일 정리
    if (outputPath) {
      await cleanupFile(outputPath).catch(() => {});
    }

    // 응답이 아직 전송되지 않았다면 에러 응답
    if (!res.headersSent) {
      const statusCode = error.message?.includes('timeout') ? 504 : 500;
      res.status(statusCode).json({
        error: 'Thumbnail rendering failed',
        message: error.message || 'Unknown error occurred',
      });
    }
  }
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Render endpoint: POST http://localhost:${PORT}/render`);
  console.log(`Thumbnail endpoint: POST http://localhost:${PORT}/thumbnail`);

  // 로컬 개발 환경에서만 오래된 파일 정리 (선택사항)
  if (process.env.NODE_ENV !== 'production') {
    // 서버 시작 시 오래된 파일 정리
    cleanupOldFiles().catch(() => {});
    
    // 10분마다 오래된 파일 정리
    setInterval(() => {
      cleanupOldFiles().catch(() => {});
    }, 10 * 60 * 1000);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

