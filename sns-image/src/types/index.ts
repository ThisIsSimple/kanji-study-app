// 공통 타입 정의
export const IMAGE_WIDTH = 1080;
export const IMAGE_HEIGHT = 1350;

// 지원하는 프리셋 타입
export type PresetType = "kanji" | "lyrics";

// 생성 요청 타입
export interface GenerateRequest {
  type: PresetType;
  data: KanjiInput | LyricsInput;
}

// 생성 응답 타입
export interface GenerateResponse {
  success: boolean;
  outputDir: string;
  images: string[];
}

// 에러 응답 타입
export interface ErrorResponse {
  success: false;
  error: string;
  message: string;
}

// 한자 학습 프리셋 입력 타입
export interface KanjiInput {
  cover: {
    word: string;
    yomigana: string;
    meaning: string;
  };
  intro: {
    kanji: Array<{
      kanji: string;
      korean: string;
    }>;
    meaning: string;
  };
  main: Array<{
    equation: string;
    explanation: string;
  }>;
  additional: Array<{
    kanji: string;
    examples: Array<{
      word: string;
      equation: string;
      level: string;
    }>;
  }>;
  outro: Record<string, unknown>;
}

// 가사 해석 프리셋 입력 타입
export interface LyricsInput {
  cover: {
    artist: string;
    korean_title: string;
    title: string;
  };
  intro: {
    lyrics: string;
    meaning: string;
  };
  objective: {
    title: string;
    subtitle: string;
  };
  main: Array<{
    number: number;
    sentence: string;
    content: string;
    explanation: string;
  }>;
  summary: {
    content: string;
  };
  quiz: {
    sentence: string;
    questions: Array<{
      content: string;
    }>;
  };
  outro: Record<string, unknown>;
}

// Re-export types from sub-modules
export * from "./kanji";
export * from "./lyrics";
