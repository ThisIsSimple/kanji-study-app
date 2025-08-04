-- ==========================================
-- 1. kanji 테이블 - 한자 마스터 데이터
-- ==========================================
CREATE TABLE IF NOT EXISTS kanji (
  id BIGSERIAL PRIMARY KEY,
  character TEXT UNIQUE NOT NULL,
  meanings TEXT[] NOT NULL,
  on_readings TEXT[],
  kun_readings TEXT[],
  grade INTEGER CHECK (grade >= 1 AND grade <= 7),
  jlpt INTEGER CHECK (jlpt >= 1 AND jlpt <= 5),
  stroke_count INTEGER,
  frequency INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_kanji_character ON kanji(character);
CREATE INDEX idx_kanji_grade ON kanji(grade);
CREATE INDEX idx_kanji_jlpt ON kanji(jlpt);
CREATE INDEX idx_kanji_frequency ON kanji(frequency);

-- ==========================================
-- 2. kanji_examples 테이블 - 예문 (확장)
-- ==========================================
CREATE TABLE IF NOT EXISTS kanji_examples (
  id BIGSERIAL PRIMARY KEY,
  kanji_character TEXT NOT NULL REFERENCES kanji(character) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  japanese TEXT NOT NULL,
  hiragana TEXT NOT NULL,
  korean TEXT NOT NULL,
  explanation TEXT, -- 새로운 필드: 해설
  source TEXT DEFAULT 'manual' CHECK (source IN ('gemini', 'manual', 'user')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_kanji_examples_character ON kanji_examples(kanji_character);
CREATE INDEX idx_kanji_examples_user_id ON kanji_examples(user_id);
CREATE INDEX idx_kanji_examples_source ON kanji_examples(source);

-- ==========================================
-- 3. quiz_sets 테이블 - 시험 세트
-- ==========================================
CREATE TABLE IF NOT EXISTS quiz_sets (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
  category TEXT,
  kanji_ids INTEGER[], -- 포함된 한자 ID 배열
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_quiz_sets_created_by ON quiz_sets(created_by);
CREATE INDEX idx_quiz_sets_is_public ON quiz_sets(is_public);
CREATE INDEX idx_quiz_sets_category ON quiz_sets(category);

-- ==========================================
-- 4. quiz_questions 테이블 - 시험 문제
-- ==========================================
CREATE TABLE IF NOT EXISTS quiz_questions (
  id BIGSERIAL PRIMARY KEY,
  quiz_set_id BIGINT NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
  question_type TEXT NOT NULL CHECK (question_type IN ('meaning', 'reading', 'kanji', 'sentence')),
  question_text TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options JSONB NOT NULL, -- 선택지 배열
  explanation TEXT,
  points INTEGER DEFAULT 1,
  order_index INTEGER NOT NULL
);

-- 인덱스 생성
CREATE INDEX idx_quiz_questions_quiz_set_id ON quiz_questions(quiz_set_id);
CREATE INDEX idx_quiz_questions_type ON quiz_questions(question_type);

-- ==========================================
-- 5. quiz_attempts 테이블 - 시험 응시 기록
-- ==========================================
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quiz_set_id BIGINT NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  score INTEGER,
  total_points INTEGER,
  time_taken_seconds INTEGER
);

-- 인덱스 생성
CREATE INDEX idx_quiz_attempts_user_id ON quiz_attempts(user_id);
CREATE INDEX idx_quiz_attempts_quiz_set_id ON quiz_attempts(quiz_set_id);
CREATE INDEX idx_quiz_attempts_started_at ON quiz_attempts(started_at);

-- ==========================================
-- 6. quiz_answers 테이블 - 개별 문제 답변
-- ==========================================
CREATE TABLE IF NOT EXISTS quiz_answers (
  id BIGSERIAL PRIMARY KEY,
  attempt_id BIGINT NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
  user_answer TEXT,
  is_correct BOOLEAN NOT NULL,
  time_taken_seconds INTEGER,
  answered_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_quiz_answers_attempt_id ON quiz_answers(attempt_id);
CREATE INDEX idx_quiz_answers_question_id ON quiz_answers(question_id);

-- ==========================================
-- 7. user_progress 테이블 (이미 존재할 수 있음)
-- ==========================================
CREATE TABLE IF NOT EXISTS user_progress (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kanji_character TEXT NOT NULL REFERENCES kanji(character) ON DELETE CASCADE,
  last_studied TIMESTAMPTZ NOT NULL,
  study_count INTEGER DEFAULT 0,
  mastered BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, kanji_character)
);

-- 인덱스 생성
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_kanji_character ON user_progress(kanji_character);

-- ==========================================
-- 8. study_sessions 테이블 (이미 존재할 수 있음)
-- ==========================================
CREATE TABLE IF NOT EXISTS study_sessions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  kanji_studied INTEGER DEFAULT 0,
  kanji_mastered INTEGER DEFAULT 0,
  duration_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_start_time ON study_sessions(start_time);

-- ==========================================
-- 9. audio_files 테이블 - 향후 음성 기능용
-- ==========================================
CREATE TABLE IF NOT EXISTS audio_files (
  id BIGSERIAL PRIMARY KEY,
  kanji_character TEXT REFERENCES kanji(character) ON DELETE CASCADE,
  example_id BIGINT REFERENCES kanji_examples(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('kanji_reading', 'example_sentence')),
  language TEXT NOT NULL CHECK (language IN ('ja', 'ko')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (
    (kanji_character IS NOT NULL AND example_id IS NULL) OR 
    (kanji_character IS NULL AND example_id IS NOT NULL)
  )
);

-- 인덱스 생성
CREATE INDEX idx_audio_files_kanji_character ON audio_files(kanji_character);
CREATE INDEX idx_audio_files_example_id ON audio_files(example_id);

-- ==========================================
-- 업데이트 트리거 함수
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
CREATE TRIGGER update_kanji_updated_at BEFORE UPDATE
  ON kanji FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quiz_sets_updated_at BEFORE UPDATE
  ON quiz_sets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE
  ON user_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();