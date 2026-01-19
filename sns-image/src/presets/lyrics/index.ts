import type { ReactNode } from "react";
import type { LyricsInput } from "../../types/lyrics";
import { LyricsCover } from "./cover";
import { LyricsIntro } from "./intro";
import { LyricsObjective } from "./objective";
import { LyricsMain } from "./main";
import { LyricsSummary } from "./summary";
import { LyricsQuiz } from "./quiz";
import { LyricsOutro } from "./outro";

export interface PageDefinition {
  element: ReactNode;
  filename: string;
}

/**
 * 가사 해석 프리셋의 모든 페이지를 생성
 */
export function generateLyricsPages(input: LyricsInput): PageDefinition[] {
  const pages: PageDefinition[] = [];

  // 1. 커버 페이지
  pages.push({
    element: LyricsCover({ data: input.cover }),
    filename: "01_cover.png",
  });

  // 2. 인트로 페이지 (가사 & 해석)
  pages.push({
    element: LyricsIntro({ data: input.intro }),
    filename: "02_intro.png",
  });

  // 3. 학습 목표 페이지
  pages.push({
    element: LyricsObjective({ data: input.objective }),
    filename: "03_objective.png",
  });

  // 4. 메인 페이지들 (문법 해설)
  input.main.forEach((mainItem, index) => {
    pages.push({
      element: LyricsMain({ data: mainItem, index }),
      filename: `04_main_${String(index + 1).padStart(2, "0")}.png`,
    });
  });

  // 5. 요약 페이지
  pages.push({
    element: LyricsSummary({ data: input.summary }),
    filename: "05_summary.png",
  });

  // 6. 퀴즈 페이지
  pages.push({
    element: LyricsQuiz({ data: input.quiz }),
    filename: "06_quiz.png",
  });

  // 7. 아웃트로 페이지
  pages.push({
    element: LyricsOutro({ data: input.outro }),
    filename: "07_outro.png",
  });

  return pages;
}

// Export individual components for testing
export { LyricsCover } from "./cover";
export { LyricsIntro } from "./intro";
export { LyricsObjective } from "./objective";
export { LyricsMain } from "./main";
export { LyricsSummary } from "./summary";
export { LyricsQuiz } from "./quiz";
export { LyricsOutro } from "./outro";
