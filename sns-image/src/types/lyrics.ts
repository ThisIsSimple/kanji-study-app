// 가사 해석 시나리오 타입 정의

export interface LyricsCover {
  artist: string;
  korean_title: string;
  title: string;
}

export interface LyricsIntro {
  lyrics: string;
  meaning: string;
}

export interface LyricsObjective {
  title: string;
  subtitle: string;
}

export interface LyricsMainItem {
  number: number;
  sentence: string;
  content: string;
  explanation: string;
}

export interface LyricsSummary {
  content: string;
}

export interface LyricsQuizQuestion {
  content: string;
}

export interface LyricsQuiz {
  sentence: string;
  questions: LyricsQuizQuestion[];
}

export interface LyricsOutro {
  [key: string]: unknown;
}

export interface LyricsInput {
  cover: LyricsCover;
  intro: LyricsIntro;
  objective: LyricsObjective;
  main: LyricsMainItem[];
  summary: LyricsSummary;
  quiz: LyricsQuiz;
  outro: LyricsOutro;
}

// 각 페이지별 컴포넌트 props
export interface LyricsCoverProps {
  data: LyricsCover;
}

export interface LyricsIntroProps {
  data: LyricsIntro;
}

export interface LyricsObjectiveProps {
  data: LyricsObjective;
}

export interface LyricsMainProps {
  data: LyricsMainItem;
  index: number;
}

export interface LyricsSummaryProps {
  data: LyricsSummary;
}

export interface LyricsQuizProps {
  data: LyricsQuiz;
}

export interface LyricsOutroProps {
  data: LyricsOutro;
}
