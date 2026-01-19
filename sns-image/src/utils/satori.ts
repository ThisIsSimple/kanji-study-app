import satori from "satori";
import sharp from "sharp";
import { mkdir, writeFile } from "fs/promises";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import type { ReactNode } from "react";
import { loadFonts } from "./fonts";
import { IMAGE_WIDTH, IMAGE_HEIGHT } from "../types";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, "../../output");

/**
 * JSX 요소를 PNG 이미지로 렌더링
 */
export async function renderToImage(
  element: ReactNode,
  filename: string,
  outputDir: string
): Promise<string> {
  const fonts = loadFonts();

  // SVG로 렌더링
  const svg = await satori(element, {
    width: IMAGE_WIDTH,
    height: IMAGE_HEIGHT,
    fonts: fonts.map((f) => ({
      name: f.name,
      data: f.data,
      weight: f.weight,
      style: f.style,
    })),
  });

  // 출력 디렉토리 생성
  const fullOutputDir = join(OUTPUT_DIR, outputDir);
  await mkdir(fullOutputDir, { recursive: true });

  // SVG를 PNG로 변환
  const pngBuffer = await sharp(Buffer.from(svg)).png({ quality: 90 }).toBuffer();

  // 파일 저장
  const outputPath = join(fullOutputDir, filename);
  await writeFile(outputPath, pngBuffer);

  return outputPath;
}

/**
 * 여러 페이지를 한 번에 렌더링
 */
export async function renderPages(
  pages: Array<{ element: ReactNode; filename: string }>,
  outputDir: string
): Promise<string[]> {
  const results: string[] = [];

  for (const page of pages) {
    const path = await renderToImage(page.element, page.filename, outputDir);
    results.push(path);
    console.log(`Rendered: ${path}`);
  }

  return results;
}

/**
 * 고유한 출력 디렉토리 이름 생성
 */
export function generateOutputDirName(prefix: string): string {
  const timestamp = Date.now();
  return `${prefix}_${timestamp}`;
}

/**
 * 출력 디렉토리 경로 반환
 */
export function getOutputDir(): string {
  return OUTPUT_DIR;
}
