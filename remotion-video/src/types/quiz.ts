// 퀴즈 타입 정의
export type QuizType = 'jp_to_kr' | 'kr_to_jp' | 'kanji_reading' | 'fill_blank';

export interface QuizQuestion {
  id: number;
  question: string;
  options: [string, string, string, string]; // 4개의 선택지
  correct_answer: string;
  explanation: string;
  jlpt_level: number | null; // 1-5
  quiz_type: QuizType;
}

export const getQuizTypeDisplay = (type: QuizType): string => {
  const displayNames: Record<QuizType, string> = {
    jp_to_kr: '단어의 뜻',
    kr_to_jp: '뜻의 단어',
    kanji_reading: '한자읽기',
    fill_blank: '빈칸채우기',
  };
  return displayNames[type] || '퀴즈';
};

export const getQuestionPrompt = (type: QuizType): string => {
  const prompts: Record<QuizType, string> = {
    jp_to_kr: '다음 단어의 뜻을 고르시요.',
    kr_to_jp: '다음을 뜻하는 단어를 고르시오.',
    kanji_reading: '다음 한자의 읽기는?',
    fill_blank: '빈칸에 들어갈 단어는?',
  };
  return prompts[type] || '정답을 고르세요';
};

