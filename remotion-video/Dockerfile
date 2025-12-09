# Node.js 베이스 이미지 사용
FROM node:20-slim

# 작업 디렉토리 설정
WORKDIR /app

# Remotion 렌더링에 필요한 시스템 의존성 설치
# Chrome/Chromium 및 기타 필수 라이브러리
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# Chrome 실행 경로 설정
ENV CHROME_BIN=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# package.json과 package-lock.json 복사 (의존성 캐싱 최적화)
COPY package*.json ./

# 의존성 설치 (빌드를 위해 devDependencies도 필요)
RUN npm ci

# 나머지 파일 복사
COPY . .

# Remotion 번들 빌드
RUN npm run build

# Chrome Headless Shell 미리 다운로드 (빌드 시 포함하여 첫 요청 지연 방지)
RUN npx remotion browser ensure

# 서버 빌드 (TypeScript 컴파일)
RUN npx tsc --project tsconfig.server.json

# 포트 노출
EXPOSE 8080

# 환경 변수 설정
ENV PORT=8080
ENV NODE_ENV=production

# 서버 실행
CMD ["node", "dist/server/index.js"]

