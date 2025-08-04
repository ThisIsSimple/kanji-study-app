-- ==========================================
-- Row Level Security (RLS) 정책 설정
-- ==========================================

-- 1. kanji 테이블 - 모든 사용자가 읽기 가능
ALTER TABLE kanji ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read kanji" ON kanji
  FOR SELECT USING (true);

-- 2. kanji_examples 테이블
ALTER TABLE kanji_examples ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기 가능
CREATE POLICY "Anyone can read kanji_examples" ON kanji_examples
  FOR SELECT USING (true);

-- 로그인한 사용자는 자신의 예문 생성 가능
CREATE POLICY "Users can create their own examples" ON kanji_examples
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신이 만든 예문만 수정/삭제 가능
CREATE POLICY "Users can update their own examples" ON kanji_examples
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own examples" ON kanji_examples
  FOR DELETE USING (auth.uid() = user_id);

-- 3. quiz_sets 테이블
ALTER TABLE quiz_sets ENABLE ROW LEVEL SECURITY;

-- 공개된 퀴즈는 모두가 볼 수 있고, 비공개는 작성자만
CREATE POLICY "Public quiz sets are readable by all" ON quiz_sets
  FOR SELECT USING (is_public = true OR auth.uid() = created_by);

-- 로그인한 사용자는 퀴즈 세트 생성 가능
CREATE POLICY "Authenticated users can create quiz sets" ON quiz_sets
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- 작성자만 수정/삭제 가능
CREATE POLICY "Users can update their own quiz sets" ON quiz_sets
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete their own quiz sets" ON quiz_sets
  FOR DELETE USING (auth.uid() = created_by);

-- 4. quiz_questions 테이블
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;

-- 퀴즈 세트를 볼 수 있는 사용자는 문제도 볼 수 있음
CREATE POLICY "Readable if quiz set is readable" ON quiz_questions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_sets 
      WHERE quiz_sets.id = quiz_questions.quiz_set_id 
      AND (quiz_sets.is_public = true OR quiz_sets.created_by = auth.uid())
    )
  );

-- 퀴즈 세트 작성자만 문제 생성/수정/삭제 가능
CREATE POLICY "Quiz set owner can manage questions" ON quiz_questions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM quiz_sets 
      WHERE quiz_sets.id = quiz_questions.quiz_set_id 
      AND quiz_sets.created_by = auth.uid()
    )
  );

-- 5. quiz_attempts 테이블
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 시도 기록만 볼 수 있음
CREATE POLICY "Users can see their own attempts" ON quiz_attempts
  FOR SELECT USING (auth.uid() = user_id);

-- 사용자는 자신의 시도 기록만 생성 가능
CREATE POLICY "Users can create their own attempts" ON quiz_attempts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 시도 기록만 수정 가능
CREATE POLICY "Users can update their own attempts" ON quiz_attempts
  FOR UPDATE USING (auth.uid() = user_id);

-- 6. quiz_answers 테이블
ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 답변만 볼 수 있음
CREATE POLICY "Users can see their own answers" ON quiz_answers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_attempts 
      WHERE quiz_attempts.id = quiz_answers.attempt_id 
      AND quiz_attempts.user_id = auth.uid()
    )
  );

-- 사용자는 자신의 시도에 대한 답변만 생성 가능
CREATE POLICY "Users can create answers for their attempts" ON quiz_answers
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM quiz_attempts 
      WHERE quiz_attempts.id = quiz_answers.attempt_id 
      AND quiz_attempts.user_id = auth.uid()
    )
  );

-- 7. user_progress 테이블
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 진도만 볼 수 있음
CREATE POLICY "Users can see their own progress" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

-- 사용자는 자신의 진도만 생성/수정 가능
CREATE POLICY "Users can manage their own progress" ON user_progress
  FOR ALL USING (auth.uid() = user_id);

-- 8. study_sessions 테이블
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 학습 세션만 볼 수 있음
CREATE POLICY "Users can see their own sessions" ON study_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- 사용자는 자신의 학습 세션만 생성 가능
CREATE POLICY "Users can create their own sessions" ON study_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 9. audio_files 테이블
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 오디오 파일을 들을 수 있음
CREATE POLICY "Anyone can access audio files" ON audio_files
  FOR SELECT USING (true);