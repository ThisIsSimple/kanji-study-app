// 타이밍 상수 (초 단위)
export const INTRO_DURATION = 2; // 0-2초: 인트로
export const QUESTION_DURATION = 5; // 2-7초: 문제 (5초 카운트다운)
export const ANSWER_DURATION = 5; // 7-12초: 정답
export const ACCOUNT_DURATION = 0; // 비활성화 (코드 유지)
export const TOTAL_DURATION = INTRO_DURATION + QUESTION_DURATION + ANSWER_DURATION + ACCOUNT_DURATION; // 12초

// FPS (1초에 한 번씩 업데이트되는 영상이므로 낮춤)
export const FPS = 5;

