import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const FONTS_DIR = join(__dirname, "../../fonts");

export interface FontConfig {
  name: string;
  data: Buffer;
  weight: 400 | 500 | 600 | 700 | 800;
  style: "normal" | "italic";
}

// 폰트 캐시
let fontsCache: FontConfig[] | null = null;

/**
 * 폰트 파일을 로드하여 Satori에서 사용할 수 있는 형태로 반환
 */
export function loadFonts(): FontConfig[] {
  if (fontsCache) {
    return fontsCache;
  }

  const fonts: FontConfig[] = [];

  try {
    // SUITE 폰트 로드
    const suiteWeights: Array<{ file: string; weight: 400 | 500 | 600 | 700 | 800 }> = [
      { file: "SUITE-Regular.ttf", weight: 400 },
      { file: "SUITE-Medium.ttf", weight: 500 },
      { file: "SUITE-SemiBold.ttf", weight: 600 },
      { file: "SUITE-Bold.ttf", weight: 700 },
      { file: "SUITE-ExtraBold.ttf", weight: 800 },
    ];

    for (const { file, weight } of suiteWeights) {
      try {
        const data = readFileSync(join(FONTS_DIR, file));
        fonts.push({
          name: "SUITE",
          data,
          weight,
          style: "normal",
        });
      } catch {
        console.warn(`Font file not found: ${file}`);
      }
    }

    // SpoqaHanSansNeo 폰트 로드
    const spoqaWeights: Array<{ file: string; weight: 400 | 700 }> = [
      { file: "SpoqaHanSansNeo-Regular.ttf", weight: 400 },
      { file: "SpoqaHanSansNeo-Bold.ttf", weight: 700 },
    ];

    for (const { file, weight } of spoqaWeights) {
      try {
        const data = readFileSync(join(FONTS_DIR, file));
        fonts.push({
          name: "SpoqaHanSansNeo",
          data,
          weight,
          style: "normal",
        });
      } catch {
        console.warn(`Font file not found: ${file}`);
      }
    }
  } catch (error) {
    console.error("Error loading fonts:", error);
  }

  if (fonts.length === 0) {
    throw new Error("No fonts loaded. Please ensure font files are in the fonts/ directory.");
  }

  fontsCache = fonts;
  console.log(`Loaded ${fonts.length} font files`);
  return fonts;
}

/**
 * 폰트 캐시 초기화 (테스트용)
 */
export function clearFontsCache(): void {
  fontsCache = null;
}
