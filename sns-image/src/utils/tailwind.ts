import type { CSSProperties } from "react";

/**
 * Tailwind CSS 유틸리티 클래스를 인라인 스타일로 변환
 * Satori는 Tailwind 클래스를 직접 지원하지 않으므로 인라인 스타일로 변환해야 함
 *
 * 참고: 이 구현은 자주 사용되는 Tailwind 클래스만 지원합니다.
 * 완전한 Tailwind 지원이 필요하면 tw-to-css 라이브러리 사용을 권장합니다.
 */

// 색상 팔레트
const colors: Record<string, string> = {
  // 기본 색상
  transparent: "transparent",
  black: "#000000",
  white: "#ffffff",

  // Gray
  "gray-50": "#f9fafb",
  "gray-100": "#f3f4f6",
  "gray-200": "#e5e7eb",
  "gray-300": "#d1d5db",
  "gray-400": "#9ca3af",
  "gray-500": "#6b7280",
  "gray-600": "#4b5563",
  "gray-700": "#374151",
  "gray-800": "#1f2937",
  "gray-900": "#111827",

  // Red
  "red-500": "#ef4444",
  "red-600": "#dc2626",

  // Orange
  "orange-500": "#f97316",

  // Yellow
  "yellow-400": "#facc15",
  "yellow-500": "#eab308",

  // Green
  "green-500": "#22c55e",
  "green-600": "#16a34a",

  // Blue
  "blue-500": "#3b82f6",
  "blue-600": "#2563eb",

  // Purple
  "purple-500": "#a855f7",
  "purple-600": "#9333ea",

  // Pink
  "pink-500": "#ec4899",

  // 커스텀 테마 색상 (한자)
  "kanji-primary": "#1a1a2e",
  "kanji-secondary": "#16213e",
  "kanji-accent": "#e94560",
  "kanji-light": "#f5f5f5",
  "kanji-gold": "#ffd700",

  // 커스텀 테마 색상 (가사)
  "lyrics-primary": "#2d1b4e",
  "lyrics-secondary": "#462066",
  "lyrics-accent": "#ff6b9d",
  "lyrics-light": "#fef6ff",
  "lyrics-highlight": "#00d4ff",
};

// 스페이싱 값
const spacing: Record<string, string> = {
  "0": "0px",
  "0.5": "2px",
  "1": "4px",
  "1.5": "6px",
  "2": "8px",
  "2.5": "10px",
  "3": "12px",
  "3.5": "14px",
  "4": "16px",
  "5": "20px",
  "6": "24px",
  "7": "28px",
  "8": "32px",
  "9": "36px",
  "10": "40px",
  "11": "44px",
  "12": "48px",
  "14": "56px",
  "16": "64px",
  "20": "80px",
  "24": "96px",
  "28": "112px",
  "32": "128px",
  "36": "144px",
  "40": "160px",
  "44": "176px",
  "48": "192px",
  "52": "208px",
  "56": "224px",
  "60": "240px",
  "64": "256px",
  "72": "288px",
  "80": "320px",
  "96": "384px",
  auto: "auto",
  full: "100%",
};

// 폰트 사이즈
const fontSize: Record<string, [string, string]> = {
  xs: ["12px", "16px"],
  sm: ["14px", "20px"],
  base: ["16px", "24px"],
  lg: ["18px", "28px"],
  xl: ["20px", "28px"],
  "2xl": ["24px", "32px"],
  "3xl": ["30px", "36px"],
  "4xl": ["36px", "40px"],
  "5xl": ["48px", "1"],
  "6xl": ["60px", "1"],
  "7xl": ["72px", "1"],
  "8xl": ["96px", "1"],
  "9xl": ["128px", "1"],
};

// 폰트 굵기
const fontWeight: Record<string, string> = {
  thin: "100",
  extralight: "200",
  light: "300",
  normal: "400",
  medium: "500",
  semibold: "600",
  bold: "700",
  extrabold: "800",
  black: "900",
};

// Border radius
const borderRadius: Record<string, string> = {
  none: "0px",
  sm: "2px",
  DEFAULT: "4px",
  md: "6px",
  lg: "8px",
  xl: "12px",
  "2xl": "16px",
  "3xl": "24px",
  full: "9999px",
};

/**
 * Tailwind 클래스 문자열을 CSSProperties 객체로 변환
 */
export function tw(classString: string): CSSProperties {
  const classes = classString.split(/\s+/).filter(Boolean);
  const styles: CSSProperties = {};

  for (const cls of classes) {
    // Display
    if (cls === "flex") styles.display = "flex";
    if (cls === "hidden") styles.display = "none";
    if (cls === "block") styles.display = "block";
    if (cls === "inline") styles.display = "inline";
    if (cls === "inline-flex") styles.display = "inline-flex";

    // Flex direction
    if (cls === "flex-row") styles.flexDirection = "row";
    if (cls === "flex-col") styles.flexDirection = "column";
    if (cls === "flex-row-reverse") styles.flexDirection = "row-reverse";
    if (cls === "flex-col-reverse") styles.flexDirection = "column-reverse";

    // Flex wrap
    if (cls === "flex-wrap") styles.flexWrap = "wrap";
    if (cls === "flex-nowrap") styles.flexWrap = "nowrap";

    // Flex grow/shrink
    if (cls === "flex-1") styles.flex = "1 1 0%";
    if (cls === "flex-auto") styles.flex = "1 1 auto";
    if (cls === "flex-initial") styles.flex = "0 1 auto";
    if (cls === "flex-none") styles.flex = "none";
    if (cls === "grow") styles.flexGrow = 1;
    if (cls === "grow-0") styles.flexGrow = 0;
    if (cls === "shrink") styles.flexShrink = 1;
    if (cls === "shrink-0") styles.flexShrink = 0;

    // Justify content
    if (cls === "justify-start") styles.justifyContent = "flex-start";
    if (cls === "justify-end") styles.justifyContent = "flex-end";
    if (cls === "justify-center") styles.justifyContent = "center";
    if (cls === "justify-between") styles.justifyContent = "space-between";
    if (cls === "justify-around") styles.justifyContent = "space-around";
    if (cls === "justify-evenly") styles.justifyContent = "space-evenly";

    // Align items
    if (cls === "items-start") styles.alignItems = "flex-start";
    if (cls === "items-end") styles.alignItems = "flex-end";
    if (cls === "items-center") styles.alignItems = "center";
    if (cls === "items-baseline") styles.alignItems = "baseline";
    if (cls === "items-stretch") styles.alignItems = "stretch";

    // Align self
    if (cls === "self-start") styles.alignSelf = "flex-start";
    if (cls === "self-end") styles.alignSelf = "flex-end";
    if (cls === "self-center") styles.alignSelf = "center";

    // Gap
    const gapMatch = cls.match(/^gap-(\d+(?:\.\d+)?|auto|full)$/);
    if (gapMatch && spacing[gapMatch[1]]) {
      styles.gap = spacing[gapMatch[1]];
    }
    const gapXMatch = cls.match(/^gap-x-(\d+(?:\.\d+)?|auto|full)$/);
    if (gapXMatch && spacing[gapXMatch[1]]) {
      styles.columnGap = spacing[gapXMatch[1]];
    }
    const gapYMatch = cls.match(/^gap-y-(\d+(?:\.\d+)?|auto|full)$/);
    if (gapYMatch && spacing[gapYMatch[1]]) {
      styles.rowGap = spacing[gapYMatch[1]];
    }

    // Padding
    const pMatch = cls.match(/^p-(\d+(?:\.\d+)?|auto|full)$/);
    if (pMatch && spacing[pMatch[1]]) styles.padding = spacing[pMatch[1]];
    const pxMatch = cls.match(/^px-(\d+(?:\.\d+)?|auto|full)$/);
    if (pxMatch && spacing[pxMatch[1]]) {
      styles.paddingLeft = spacing[pxMatch[1]];
      styles.paddingRight = spacing[pxMatch[1]];
    }
    const pyMatch = cls.match(/^py-(\d+(?:\.\d+)?|auto|full)$/);
    if (pyMatch && spacing[pyMatch[1]]) {
      styles.paddingTop = spacing[pyMatch[1]];
      styles.paddingBottom = spacing[pyMatch[1]];
    }
    const ptMatch = cls.match(/^pt-(\d+(?:\.\d+)?|auto|full)$/);
    if (ptMatch && spacing[ptMatch[1]]) styles.paddingTop = spacing[ptMatch[1]];
    const pbMatch = cls.match(/^pb-(\d+(?:\.\d+)?|auto|full)$/);
    if (pbMatch && spacing[pbMatch[1]]) styles.paddingBottom = spacing[pbMatch[1]];
    const plMatch = cls.match(/^pl-(\d+(?:\.\d+)?|auto|full)$/);
    if (plMatch && spacing[plMatch[1]]) styles.paddingLeft = spacing[plMatch[1]];
    const prMatch = cls.match(/^pr-(\d+(?:\.\d+)?|auto|full)$/);
    if (prMatch && spacing[prMatch[1]]) styles.paddingRight = spacing[prMatch[1]];

    // Margin
    const mMatch = cls.match(/^m-(\d+(?:\.\d+)?|auto|full)$/);
    if (mMatch && spacing[mMatch[1]]) styles.margin = spacing[mMatch[1]];
    const mxMatch = cls.match(/^mx-(\d+(?:\.\d+)?|auto|full)$/);
    if (mxMatch && spacing[mxMatch[1]]) {
      styles.marginLeft = spacing[mxMatch[1]];
      styles.marginRight = spacing[mxMatch[1]];
    }
    const myMatch = cls.match(/^my-(\d+(?:\.\d+)?|auto|full)$/);
    if (myMatch && spacing[myMatch[1]]) {
      styles.marginTop = spacing[myMatch[1]];
      styles.marginBottom = spacing[myMatch[1]];
    }
    const mtMatch = cls.match(/^mt-(\d+(?:\.\d+)?|auto|full)$/);
    if (mtMatch && spacing[mtMatch[1]]) styles.marginTop = spacing[mtMatch[1]];
    const mbMatch = cls.match(/^mb-(\d+(?:\.\d+)?|auto|full)$/);
    if (mbMatch && spacing[mbMatch[1]]) styles.marginBottom = spacing[mbMatch[1]];
    const mlMatch = cls.match(/^ml-(\d+(?:\.\d+)?|auto|full)$/);
    if (mlMatch && spacing[mlMatch[1]]) styles.marginLeft = spacing[mlMatch[1]];
    const mrMatch = cls.match(/^mr-(\d+(?:\.\d+)?|auto|full)$/);
    if (mrMatch && spacing[mrMatch[1]]) styles.marginRight = spacing[mrMatch[1]];

    // Width & Height
    const wMatch = cls.match(/^w-(\d+(?:\.\d+)?|auto|full)$/);
    if (wMatch && spacing[wMatch[1]]) styles.width = spacing[wMatch[1]];
    if (cls === "w-screen") styles.width = "100vw";
    const hMatch = cls.match(/^h-(\d+(?:\.\d+)?|auto|full)$/);
    if (hMatch && spacing[hMatch[1]]) styles.height = spacing[hMatch[1]];
    if (cls === "h-screen") styles.height = "100vh";

    // Font size
    const textSizeMatch = cls.match(/^text-(xs|sm|base|lg|xl|[2-9]xl)$/);
    if (textSizeMatch && fontSize[textSizeMatch[1]]) {
      const [size, lineHeight] = fontSize[textSizeMatch[1]];
      styles.fontSize = size;
      styles.lineHeight = lineHeight;
    }

    // Font weight
    const fontWeightMatch = cls.match(
      /^font-(thin|extralight|light|normal|medium|semibold|bold|extrabold|black)$/
    );
    if (fontWeightMatch && fontWeight[fontWeightMatch[1]]) {
      styles.fontWeight = fontWeight[fontWeightMatch[1]];
    }

    // Text color
    const textColorMatch = cls.match(/^text-(.+)$/);
    if (textColorMatch && colors[textColorMatch[1]]) {
      styles.color = colors[textColorMatch[1]];
    }

    // Background color
    const bgMatch = cls.match(/^bg-(.+)$/);
    if (bgMatch && colors[bgMatch[1]]) {
      styles.backgroundColor = colors[bgMatch[1]];
    }

    // Border radius
    if (cls === "rounded") styles.borderRadius = borderRadius.DEFAULT;
    const roundedMatch = cls.match(/^rounded-(none|sm|md|lg|xl|2xl|3xl|full)$/);
    if (roundedMatch && borderRadius[roundedMatch[1]]) {
      styles.borderRadius = borderRadius[roundedMatch[1]];
    }

    // Border
    if (cls === "border") styles.borderWidth = "1px";
    const borderMatch = cls.match(/^border-(\d+)$/);
    if (borderMatch) styles.borderWidth = `${borderMatch[1]}px`;
    const borderColorMatch = cls.match(/^border-(.+)$/);
    if (borderColorMatch && colors[borderColorMatch[1]]) {
      styles.borderColor = colors[borderColorMatch[1]];
    }

    // Text align
    if (cls === "text-left") styles.textAlign = "left";
    if (cls === "text-center") styles.textAlign = "center";
    if (cls === "text-right") styles.textAlign = "right";
    if (cls === "text-justify") styles.textAlign = "justify";

    // Position
    if (cls === "relative") styles.position = "relative";
    if (cls === "absolute") styles.position = "absolute";
    if (cls === "fixed") styles.position = "fixed";

    // Inset
    if (cls === "inset-0") {
      styles.top = "0";
      styles.right = "0";
      styles.bottom = "0";
      styles.left = "0";
    }
    const topMatch = cls.match(/^top-(\d+(?:\.\d+)?|auto|full)$/);
    if (topMatch && spacing[topMatch[1]]) styles.top = spacing[topMatch[1]];
    const bottomMatch = cls.match(/^bottom-(\d+(?:\.\d+)?|auto|full)$/);
    if (bottomMatch && spacing[bottomMatch[1]]) styles.bottom = spacing[bottomMatch[1]];
    const leftMatch = cls.match(/^left-(\d+(?:\.\d+)?|auto|full)$/);
    if (leftMatch && spacing[leftMatch[1]]) styles.left = spacing[leftMatch[1]];
    const rightMatch = cls.match(/^right-(\d+(?:\.\d+)?|auto|full)$/);
    if (rightMatch && spacing[rightMatch[1]]) styles.right = spacing[rightMatch[1]];

    // Overflow
    if (cls === "overflow-hidden") styles.overflow = "hidden";
    if (cls === "overflow-auto") styles.overflow = "auto";
    if (cls === "overflow-scroll") styles.overflow = "scroll";
    if (cls === "overflow-visible") styles.overflow = "visible";

    // Shadow (simplified)
    if (cls === "shadow") styles.boxShadow = "0 1px 3px rgba(0,0,0,0.1)";
    if (cls === "shadow-md") styles.boxShadow = "0 4px 6px rgba(0,0,0,0.1)";
    if (cls === "shadow-lg") styles.boxShadow = "0 10px 15px rgba(0,0,0,0.1)";
    if (cls === "shadow-xl") styles.boxShadow = "0 20px 25px rgba(0,0,0,0.1)";
    if (cls === "shadow-2xl") styles.boxShadow = "0 25px 50px rgba(0,0,0,0.25)";
    if (cls === "shadow-none") styles.boxShadow = "none";

    // Opacity
    const opacityMatch = cls.match(/^opacity-(\d+)$/);
    if (opacityMatch) {
      styles.opacity = parseInt(opacityMatch[1]) / 100;
    }

    // Line height
    if (cls === "leading-none") styles.lineHeight = "1";
    if (cls === "leading-tight") styles.lineHeight = "1.25";
    if (cls === "leading-snug") styles.lineHeight = "1.375";
    if (cls === "leading-normal") styles.lineHeight = "1.5";
    if (cls === "leading-relaxed") styles.lineHeight = "1.625";
    if (cls === "leading-loose") styles.lineHeight = "2";

    // Letter spacing
    if (cls === "tracking-tighter") styles.letterSpacing = "-0.05em";
    if (cls === "tracking-tight") styles.letterSpacing = "-0.025em";
    if (cls === "tracking-normal") styles.letterSpacing = "0em";
    if (cls === "tracking-wide") styles.letterSpacing = "0.025em";
    if (cls === "tracking-wider") styles.letterSpacing = "0.05em";
    if (cls === "tracking-widest") styles.letterSpacing = "0.1em";

    // Word break
    if (cls === "break-words") styles.wordBreak = "break-word";
    if (cls === "break-all") styles.wordBreak = "break-all";

    // White space
    if (cls === "whitespace-normal") styles.whiteSpace = "normal";
    if (cls === "whitespace-nowrap") styles.whiteSpace = "nowrap";
    if (cls === "whitespace-pre") styles.whiteSpace = "pre";
    if (cls === "whitespace-pre-line") styles.whiteSpace = "pre-line";
    if (cls === "whitespace-pre-wrap") styles.whiteSpace = "pre-wrap";

    // Z-index
    const zMatch = cls.match(/^z-(\d+)$/);
    if (zMatch) styles.zIndex = parseInt(zMatch[1]);
  }

  return styles;
}

/**
 * 여러 스타일 객체를 병합
 */
export function mergeStyles(...styles: (CSSProperties | undefined)[]): CSSProperties {
  return Object.assign({}, ...styles.filter(Boolean));
}

/**
 * 기본 컨테이너 스타일 (인스타그램 4:5 비율)
 */
export const containerStyle: CSSProperties = {
  width: "1080px",
  height: "1350px",
  display: "flex",
  flexDirection: "column",
  fontFamily: "SUITE, SpoqaHanSansNeo, sans-serif",
};
