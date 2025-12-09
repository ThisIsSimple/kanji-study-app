# Remotion Video API Cloud Run 배포 가이드

이 문서는 Remotion Video API 서버를 Google Cloud Run에 배포하는 방법을 설명합니다.

## 목차

1. [사전 준비](#사전-준비)
2. [배포 명령어](#배포-명령어)
3. [배포 옵션 설명](#배포-옵션-설명)
4. [배포 후 확인](#배포-후-확인)
5. [테스트](#테스트)
6. [추가 설정](#추가-설정)
7. [트러블슈팅](#트러블슈팅)

---

## 사전 준비

### 1. Google Cloud CLI 설치 및 인증

```bash
# gcloud CLI 설치 확인
gcloud --version

# Google Cloud 계정 로그인
gcloud auth login

# 프로젝트 설정
gcloud config set project YOUR_PROJECT_ID

# Cloud Run 및 Cloud Build API 활성화
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 2. 필요한 파일 확인

배포 전에 다음 파일들이 프로젝트 루트에 있는지 확인하세요:

- ✅ `Dockerfile` - 컨테이너 빌드 설정
- ✅ `.dockerignore` - 빌드 최적화
- ✅ `package.json` - 의존성 정의
- ✅ `tsconfig.server.json` - 서버 TypeScript 설정
- ✅ `server/` - 서버 소스 코드
- ✅ `src/` - Remotion 컴포넌트 소스 코드

---

## 배포 명령어

프로젝트 루트 디렉토리(`remotion-video/`)에서 다음 명령어를 실행하세요:

```bash
gcloud run deploy remotion-video-api \
  --source . \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 60 \
  --max-instances 10 \
  --min-instances 0 \
  --allow-unauthenticated
```

### 첫 배포 시 확인 사항

첫 배포 시 다음 질문들이 나타날 수 있습니다:

1. **서비스 이름**: `remotion-video-api` (Enter로 확인)
2. **리전**: `asia-northeast3` (Enter로 확인)
3. **인증되지 않은 호출 허용**: `y` (Enter로 확인)

---

## 배포 옵션 설명

| 옵션 | 값 | 설명 |
|------|-----|------|
| `--source .` | 현재 디렉토리 | 소스 코드 위치 (Dockerfile 자동 감지) |
| `--platform managed` | managed | Cloud Run 관리형 플랫폼 사용 |
| `--region` | asia-northeast3 | 배포 리전 (서울) |
| `--memory` | 2Gi | 컨테이너 메모리 할당량 |
| `--cpu` | 2 | CPU 코어 수 |
| `--timeout` | 60 | 요청 타임아웃 (초) |
| `--max-instances` | 10 | 최대 동시 인스턴스 수 |
| `--min-instances` | 0 | 최소 인스턴스 수 (0 = 콜드 스타트 허용) |
| `--allow-unauthenticated` | - | 인증 없이 접근 허용 |

### 리전 선택

다른 리전을 사용하려면:

- **서울**: `asia-northeast3` (권장)
- **도쿄**: `asia-northeast1`
- **대만**: `asia-east1`
- **미국 동부**: `us-east1`
- **유럽**: `europe-west1`

### 리소스 권장 사항

| 사용량 | 메모리 | CPU | 비고 |
|--------|--------|-----|------|
| 낮음 | 2Gi | 2 | 기본 설정 |
| 중간 | 4Gi | 4 | 동시 요청 증가 시 |
| 높음 | 8Gi | 8 | 대용량 처리 시 |

---

## 배포 후 확인

### 1. 배포 성공 메시지

배포가 완료되면 다음과 같은 메시지가 표시됩니다:

```
Service [remotion-video-api] revision [remotion-video-api-xxxxx] has been deployed and is serving 100 percent of traffic.
Service URL: https://remotion-video-api-xxxxx-uc.a.run.app
```

### 2. 서비스 URL 확인

서비스 URL은 다음 명령어로도 확인할 수 있습니다:

```bash
gcloud run services describe remotion-video-api \
  --region asia-northeast3 \
  --format 'value(status.url)'
```

### 3. 헬스 체크

배포된 서비스가 정상 작동하는지 확인:

```bash
# 서비스 URL을 YOUR_SERVICE_URL로 교체
curl https://YOUR_SERVICE_URL/health
```

**예상 응답:**
```json
{
  "status": "ok",
  "timestamp": "2024-12-06T10:30:00.000Z"
}
```

---

## 테스트

### 1. cURL로 테스트

```bash
curl -X POST https://YOUR_SERVICE_URL/render \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "question": "勉強",
    "options": ["운동", "독서", "공부", "여행"],
    "correct_answer": "공부",
    "explanation": "(べんきょう)\n勉(힘쓸 면) + 強(강할 강) = 공부하다",
    "jlpt_level": 3,
    "quiz_type": "jp_to_kr"
  }' \
  --output test-video.mp4
```

### 2. JavaScript/TypeScript로 테스트

```typescript
async function testRender() {
  const response = await fetch('https://YOUR_SERVICE_URL/render', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      id: 1,
      question: '勉強',
      options: ['운동', '독서', '공부', '여행'],
      correct_answer: '공부',
      explanation: '(べんきょう)\n勉(힘쓸 면) + 強(강할 강) = 공부하다',
      jlpt_level: 3,
      quiz_type: 'jp_to_kr',
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Rendering failed: ${error.message}`);
  }

  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  console.log('Video URL:', url);
}

testRender();
```

### 3. Python으로 테스트

```python
import requests

def test_render():
    url = "https://YOUR_SERVICE_URL/render"
    data = {
        "id": 1,
        "question": "勉強",
        "options": ["운동", "독서", "공부", "여행"],
        "correct_answer": "공부",
        "explanation": "(べんきょう)\n勉(힘쓸 면) + 強(강할 강) = 공부하다",
        "jlpt_level": 3,
        "quiz_type": "jp_to_kr"
    }
    
    response = requests.post(url, json=data, stream=True)
    
    if response.status_code != 200:
        error = response.json()
        raise Exception(f"Rendering failed: {error['message']}")
    
    with open("test-video.mp4", "wb") as f:
        f.write(response.content)
    
    print("Video saved as test-video.mp4")

test_render()
```

---

## 추가 설정

### 1. 환경 변수 설정

```bash
gcloud run services update remotion-video-api \
  --set-env-vars NODE_ENV=production \
  --region asia-northeast3
```

### 2. 리소스 조정

메모리나 CPU를 조정하려면:

```bash
# 메모리 4GB, CPU 4개로 증가
gcloud run services update remotion-video-api \
  --memory 4Gi \
  --cpu 4 \
  --region asia-northeast3
```

### 3. 타임아웃 조정

더 긴 렌더링 시간이 필요한 경우:

```bash
# 타임아웃 120초로 증가
gcloud run services update remotion-video-api \
  --timeout 120 \
  --region asia-northeast3
```

### 4. 최소 인스턴스 설정 (콜드 스타트 방지)

항상 최소 1개의 인스턴스를 유지하려면:

```bash
gcloud run services update remotion-video-api \
  --min-instances 1 \
  --region asia-northeast3
```

**주의**: 최소 인스턴스를 설정하면 비용이 발생합니다.

### 5. 로그 확인

#### 실시간 로그

```bash
gcloud run services logs read remotion-video-api \
  --region asia-northeast3 \
  --follow
```

#### 최근 로그 확인

```bash
gcloud run services logs read remotion-video-api \
  --region asia-northeast3 \
  --limit 50
```

### 6. 서비스 정보 확인

```bash
gcloud run services describe remotion-video-api \
  --region asia-northeast3
```

### 7. 서비스 삭제

서비스를 삭제하려면:

```bash
gcloud run services delete remotion-video-api \
  --region asia-northeast3
```

---

## 트러블슈팅

### 1. 빌드 실패

#### 문제: Docker 빌드 중 오류 발생

**해결 방법:**

1. 로컬에서 Docker 이미지 빌드 테스트:

```bash
docker build -t remotion-video-test .
docker run -p 8080:8080 remotion-video-test
```

2. 빌드 로그 확인:

```bash
gcloud builds list --limit=5
gcloud builds log BUILD_ID
```

3. Dockerfile 확인:
   - Node.js 버전이 올바른지 확인
   - 필요한 시스템 패키지가 모두 설치되는지 확인

### 2. 메모리 부족 에러

#### 문제: 렌더링 중 메모리 부족으로 인한 크래시

**해결 방법:**

메모리를 증가시킵니다:

```bash
gcloud run services update remotion-video-api \
  --memory 4Gi \
  --region asia-northeast3
```

### 3. 타임아웃 에러

#### 문제: 60초 내에 렌더링이 완료되지 않음

**해결 방법:**

타임아웃을 증가시킵니다:

```bash
gcloud run services update remotion-video-api \
  --timeout 120 \
  --region asia-northeast3
```

**참고**: Cloud Run의 최대 타임아웃은 3600초(60분)입니다.

### 4. 콜드 스타트 지연

#### 문제: 첫 요청이 매우 느림

**해결 방법:**

1. 최소 인스턴스 설정 (비용 발생):

```bash
gcloud run services update remotion-video-api \
  --min-instances 1 \
  --region asia-northeast3
```

2. 또는 주기적으로 헬스 체크 요청을 보내 인스턴스를 유지

### 5. 포트 에러

#### 문제: 포트 8080이 이미 사용 중

**해결 방법:**

Dockerfile에서 `EXPOSE 8080`이 설정되어 있고, 서버가 `process.env.PORT`를 사용하므로 문제가 없어야 합니다. 

확인:

```bash
# 서버가 올바른 포트를 사용하는지 확인
gcloud run services describe remotion-video-api \
  --region asia-northeast3 \
  --format 'value(spec.template.spec.containers[0].ports)'
```

### 6. 의존성 설치 실패

#### 문제: npm install 중 오류

**해결 방법:**

1. `package-lock.json`이 있는지 확인
2. Dockerfile에서 `npm ci` 대신 `npm install` 사용 시도 (권장하지 않음)
3. 네트워크 문제인 경우, 빌드 시간을 늘리거나 재시도

### 7. Remotion 번들 빌드 실패

#### 문제: `npm run build` 실패

**해결 방법:**

1. 로컬에서 빌드 테스트:

```bash
npm run build
```

2. 빌드 로그에서 구체적인 오류 확인
3. `remotion.config.ts` 설정 확인

### 8. 서비스 접근 불가

#### 문제: 403 Forbidden 또는 인증 오류

**해결 방법:**

인증 없이 접근을 허용했는지 확인:

```bash
gcloud run services add-iam-policy-binding remotion-video-api \
  --region asia-northeast3 \
  --member "allUsers" \
  --role "roles/run.invoker"
```

---

## 비용 최적화

### 1. 리소스 최적화

- 실제 사용량에 맞게 메모리/CPU 조정
- 불필요한 최소 인스턴스 제거 (`--min-instances 0`)

### 2. 요청 최적화

- 동시 요청 수 제한 (`--max-instances`)
- 타임아웃을 적절히 설정하여 불필요한 리소스 사용 방지

### 3. 비용 모니터링

```bash
# Cloud Console에서 비용 확인
# https://console.cloud.google.com/billing
```

---

## 보안 고려사항

### 1. 인증 설정

프로덕션 환경에서는 인증을 활성화하는 것을 권장합니다:

```bash
# 인증 없이 접근 허용 제거
gcloud run services remove-iam-policy-binding remotion-video-api \
  --region asia-northeast3 \
  --member "allUsers" \
  --role "roles/run.invoker"
```

### 2. API 키 사용

서비스 간 통신 시 서비스 계정 사용:

```bash
# 서비스 계정 생성 및 권한 부여
gcloud iam service-accounts create remotion-video-sa
gcloud run services add-iam-policy-binding remotion-video-api \
  --region asia-northeast3 \
  --member "serviceAccount:remotion-video-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/run.invoker"
```

---

## 업데이트 및 재배포

### 1. 코드 변경 후 재배포

코드를 수정한 후 동일한 명령어로 재배포:

```bash
gcloud run deploy remotion-video-api \
  --source . \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 60
```

### 2. 특정 리비전으로 롤백

```bash
# 리비전 목록 확인
gcloud run revisions list --service remotion-video-api --region asia-northeast3

# 특정 리비전으로 트래픽 이동
gcloud run services update-traffic remotion-video-api \
  --to-revisions REVISION_NAME=100 \
  --region asia-northeast3
```

---

## 참고 자료

- [Cloud Run 공식 문서](https://cloud.google.com/run/docs)
- [Remotion 공식 문서](https://www.remotion.dev/docs)
- [API 문서](./API_DOCUMENTATION.md)
- [Gemini 프롬프트 가이드](./GEMINI_PROMPTS.md)

---

## 지원

문제가 발생하면 다음을 확인하세요:

1. 로그 확인: `gcloud run services logs read`
2. 서비스 상태 확인: `gcloud run services describe`
3. 빌드 로그 확인: `gcloud builds list`

