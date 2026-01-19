// 한자 학습 시나리오 타입 정의

export interface KanjiCover {
  word: string;
  yomigana: string;
  meaning: string;
}

export interface KanjiIntroItem {
  kanji: string;
  korean: string;
}

export interface KanjiIntro {
  kanji: KanjiIntroItem[];
  meaning: string;
}

export interface KanjiMainItem {
  equation: string;
  explanation: string;
}

export interface KanjiExample {
  word: string;
  equation: string;
  level: string;
}

export interface KanjiAdditionalItem {
  kanji: string;
  examples: KanjiExample[];
}

export interface KanjiOutro {
  [key: string]: unknown;
}

export interface KanjiInput {
  cover: KanjiCover;
  intro: KanjiIntro;
  main: KanjiMainItem[];
  additional: KanjiAdditionalItem[];
  outro: KanjiOutro;
}

// 각 페이지별 컴포넌트 props
export interface KanjiCoverProps {
  data: KanjiCover;
}

export interface KanjiIntroProps {
  data: KanjiIntro;
}

export interface KanjiMainProps {
  data: KanjiMainItem;
  index: number;
}

export interface KanjiAdditionalProps {
  data: KanjiAdditionalItem;
  index: number;
}

export interface KanjiOutroProps {
  data: KanjiOutro;
}
