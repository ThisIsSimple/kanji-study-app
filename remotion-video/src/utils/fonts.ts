// 폰트 유틸리티
export const loadFont = (fontName: string, weight: 'regular' | 'bold' = 'regular'): string => {
  const fontFile = weight === 'bold' ? 'SpoqaHanSansNeo-Bold.ttf' : 'SpoqaHanSansNeo-Regular.ttf';
  return `/fonts/${fontFile}`;
};

export const FONT_FAMILY = 'SpoqaHanSansNeo';

