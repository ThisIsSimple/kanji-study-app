// 레이아웃 상수
export const WIDTH = 1080;
export const HEIGHT = 1920;

// Safe Zone 규격 (유동적 적용 - 상하단 우선, 좌우는 유동적)
export const SAFE_ZONE_TOP = 250;
export const SAFE_ZONE_BOTTOM = 420;
export const SAFE_ZONE_LEFT = 40; // 좌우 여백 완화
export const SAFE_ZONE_RIGHT = 120; // 우측 중앙-하단만 피하면 됨
export const SAFE_ZONE_WIDTH = WIDTH - SAFE_ZONE_LEFT - SAFE_ZONE_RIGHT; // 920px
export const SAFE_ZONE_HEIGHT = HEIGHT - SAFE_ZONE_TOP - SAFE_ZONE_BOTTOM; // 1250px

