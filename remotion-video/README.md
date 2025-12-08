# Remotion Quiz Video Generator

React 기반 영상 생성 프로젝트입니다. Remotion을 사용하여 일본어 퀴즈 영상을 생성합니다.

## 설치

```bash
npm install
```

## 개발

Remotion Studio를 실행하여 실시간 미리보기를 확인합니다:

```bash
npm run dev
```

## 빌드

영상을 렌더링합니다:

```bash
npm run build
```

## 프로젝트 구조

```
remotion-video/
├── src/
│   ├── components/      # 프레임 컴포넌트
│   ├── constants/       # 상수 정의
│   ├── types/           # TypeScript 타입
│   ├── utils/           # 유틸리티 함수
│   ├── Video.tsx        # 메인 영상 컴포넌트
│   ├── Root.tsx         # Remotion 루트
│   └── index.tsx        # 진입점
├── public/
│   ├── fonts/           # 폰트 파일
│   └── sounds/          # 오디오 파일
└── package.json
```

## 주요 기능

- 인트로 화면 (3초)
- 문제 화면 (10초, 카운트다운)
- 정답 화면 (5초)
- 계정 정보 화면 (5초)
- 배경음악 및 효과음
- Safe Zone 레이아웃 적용

## 사용법

`src/Root.tsx`에서 테스트 퀴즈 데이터를 수정하거나, API를 통해 동적으로 퀴즈 데이터를 전달할 수 있습니다.

