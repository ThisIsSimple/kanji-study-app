import {staticFile} from 'remotion';

let fontsLoaded = false;
let fontsLoading: Promise<void> | null = null;

export const loadFonts = async (): Promise<void> => {
  if (fontsLoaded) {
    return;
  }
  
  if (fontsLoading) {
    return fontsLoading;
  }

  fontsLoading = (async () => {
    try {
      // Regular 폰트
      const regularFont = new FontFace(
        'SpoqaHanSansNeo',
        `url(${staticFile('fonts/SpoqaHanSansNeo-Regular.ttf')})`,
        {weight: '400'}
      );
      
      // Bold 폰트
      const boldFont = new FontFace(
        'SpoqaHanSansNeo',
        `url(${staticFile('fonts/SpoqaHanSansNeo-Bold.ttf')})`,
        {weight: '700'}
      );

      await Promise.all([regularFont.load(), boldFont.load()]);
      
      // 폰트를 document에 추가
      if (typeof document !== 'undefined') {
        document.fonts.add(regularFont);
        document.fonts.add(boldFont);
      }
      
      fontsLoaded = true;
    } catch (err) {
      console.warn('폰트 로드 실패:', err);
      fontsLoaded = false;
    }
  })();

  return fontsLoading;
};

// 모듈 로드 시 즉시 폰트 로드 시작
if (typeof window !== 'undefined') {
  loadFonts();
}

