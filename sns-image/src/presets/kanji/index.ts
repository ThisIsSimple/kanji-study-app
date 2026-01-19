import type { ReactNode } from "react";
import type { KanjiInput } from "../../types/kanji";
import { KanjiCover } from "./cover";
import { KanjiIntro } from "./intro";
import { KanjiMain } from "./main";
import { KanjiAdditional } from "./additional";
import { KanjiOutro } from "./outro";

export interface PageDefinition {
  element: ReactNode;
  filename: string;
}

/**
 * 한자 학습 프리셋의 모든 페이지를 생성
 */
export function generateKanjiPages(input: KanjiInput): PageDefinition[] {
  const pages: PageDefinition[] = [];

  // 1. 커버 페이지
  pages.push({
    element: KanjiCover({ data: input.cover }),
    filename: "01_cover.png",
  });

  // 2. 인트로 페이지 (한자 구성)
  pages.push({
    element: KanjiIntro({ data: input.intro }),
    filename: "02_intro.png",
  });

  // 3. 메인 페이지들 (등식 + 설명)
  input.main.forEach((mainItem, index) => {
    pages.push({
      element: KanjiMain({ data: mainItem, index }),
      filename: `03_main_${String(index + 1).padStart(2, "0")}.png`,
    });
  });

  // 4. 추가 정보 페이지들 (관련 단어)
  input.additional.forEach((additionalItem, index) => {
    pages.push({
      element: KanjiAdditional({ data: additionalItem, index }),
      filename: `04_additional_${String(index + 1).padStart(2, "0")}.png`,
    });
  });

  // 5. 아웃트로 페이지
  pages.push({
    element: KanjiOutro({ data: input.outro }),
    filename: "05_outro.png",
  });

  return pages;
}

// Export individual components for testing
export { KanjiCover } from "./cover";
export { KanjiIntro } from "./intro";
export { KanjiMain } from "./main";
export { KanjiAdditional } from "./additional";
export { KanjiOutro } from "./outro";
