# 익명 사용자에서 SNS 계정으로의 데이터 마이그레이션 가이드

## 현재 문제점

Supabase는 익명 사용자를 SNS 계정으로 직접 변환하는 기능을 제공하지 않습니다. 
Google/Apple/Kakao로 로그인하면 새로운 계정이 생성되고, 기존 익명 사용자의 데이터가 유지되지 않습니다.

## 해결 방법

### 방법 1: 서버 측 데이터 마이그레이션 (권장)

1. **Supabase Edge Function 생성**
   - 익명 사용자의 데이터를 새 SNS 계정으로 이동하는 함수
   - 학습 기록, 퀴즈 결과 등 모든 데이터 이관

2. **클라이언트 구현**
   ```dart
   // SNS 로그인 후
   if (previousAnonymousId != null) {
     await supabase.functions.invoke('migrate-anonymous-data', body: {
       'from_user_id': previousAnonymousId,
       'to_user_id': currentUser.id,
     });
   }
   ```

### 방법 2: 클라이언트 측 데이터 마이그레이션

1. **로그인 전 데이터 백업**
   ```dart
   // 익명 사용자의 데이터를 로컬에 저장
   final studyRecords = await getStudyRecords();
   final quizResults = await getQuizResults();
   ```

2. **SNS 로그인 후 데이터 복원**
   ```dart
   // 새 계정으로 데이터 재생성
   await createStudyRecords(studyRecords);
   await createQuizResults(quizResults);
   ```

### 방법 3: 계정 연결 방식 (부분적 해결)

1. **익명 사용자 메타데이터에 SNS 정보 저장**
   ```dart
   // SNS 로그인 정보를 익명 계정에 연결
   await supabase.auth.updateUser(UserAttributes(
     data: {
       'linked_google_email': googleUser.email,
       'linked_at': DateTime.now().toIso8601String(),
     }
   ));
   ```

2. **다음 로그인 시 데이터 확인**
   - SNS 계정으로 로그인 시 이전 익명 계정 데이터 확인
   - 필요시 데이터 마이그레이션 실행

## 현재 코드의 한계

현재 구현:
```dart
// If was anonymous, update the new user's metadata to indicate previous anonymous ID
if (isAnonymous && anonymousUserId != null) {
  await _client.auth.updateUser(
    UserAttributes(
      data: {
        'previous_anonymous_id': anonymousUserId,
        'linked_from_anonymous': true,
      },
    ),
  );
}
```

이 코드는:
- ✅ 새 SNS 계정에 이전 익명 사용자 ID를 기록
- ❌ 실제 데이터는 이관되지 않음
- ❌ 익명 계정은 그대로 남아있음

## 권장 구현 방안

### 1단계: Edge Function 생성 (Supabase Dashboard)

```sql
-- Edge Function: migrate_anonymous_data
CREATE OR REPLACE FUNCTION migrate_anonymous_data(
  from_user_id UUID,
  to_user_id UUID
) RETURNS void AS $$
BEGIN
  -- study_records 이관
  UPDATE study_records 
  SET user_id = to_user_id 
  WHERE user_id = from_user_id;
  
  -- quiz_attempts 이관
  UPDATE quiz_attempts 
  SET user_id = to_user_id 
  WHERE user_id = from_user_id;
  
  -- 기타 테이블도 동일하게 처리
  
  -- 익명 사용자 프로필 삭제 (선택사항)
  DELETE FROM profiles 
  WHERE id = from_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2단계: 클라이언트 코드 수정

```dart
Future<bool> signInWithGoogle() async {
  // 1. 익명 사용자 데이터 백업
  final anonymousUserId = currentUser?.id;
  final isAnonymous = currentUser?.isAnonymous ?? false;
  
  // 2. Google 로그인
  await _client.auth.signInWithIdToken(...);
  
  // 3. 데이터 마이그레이션
  if (isAnonymous && anonymousUserId != null) {
    await migrateAnonymousData(
      fromUserId: anonymousUserId,
      toUserId: currentUser!.id,
    );
  }
  
  return true;
}

Future<void> migrateAnonymousData({
  required String fromUserId,
  required String toUserId,
}) async {
  try {
    await _client.functions.invoke(
      'migrate-anonymous-data',
      body: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
      },
    );
    debugPrint('Successfully migrated data from anonymous user');
  } catch (e) {
    debugPrint('Failed to migrate anonymous data: $e');
  }
}
```

## 구현 우선순위

1. **즉시 필요**: 현재 메타데이터 저장 방식 유지 (완료)
2. **단기**: Edge Function을 통한 서버 측 데이터 마이그레이션
3. **장기**: 사용자 경험 개선 (마이그레이션 진행 표시 등)

## 테스트 시나리오

1. 익명 사용자로 학습 기록 생성
2. SNS 로그인
3. 이전 학습 기록이 새 계정에 표시되는지 확인
4. 익명 계정이 정리되었는지 확인