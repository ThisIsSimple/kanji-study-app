-- Home Dashboard Enhancement Tables
-- Created for enhanced home screen with gamification, achievements, and social features

-- ============================================
-- 1. Achievements System Tables
-- ============================================

-- Achievements table: Defines all available achievements/badges
CREATE TABLE IF NOT EXISTS achievements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  required_count INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('kanji_count', 'streak', 'mastery_rate', 'weekly_count')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements table: Tracks user progress and unlocked achievements
CREATE TABLE IF NOT EXISTS user_achievements (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress INTEGER DEFAULT 0,
  UNIQUE(user_id, achievement_id)
);

-- ============================================
-- 2. User Goals and Settings
-- ============================================

-- Daily goals table: User-specific daily study targets
CREATE TABLE IF NOT EXISTS daily_goals (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  daily_target INTEGER DEFAULT 10 CHECK (daily_target > 0 AND daily_target <= 100),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. User Profile Extensions
-- ============================================

-- Add profile visibility settings to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS profile_public BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_on_leaderboard BOOLEAN DEFAULT true;

-- ============================================
-- 4. Leaderboard Materialized View
-- ============================================

-- Weekly leaderboard view for performance optimization
-- This aggregates study data for ranking users
DROP MATERIALIZED VIEW IF EXISTS leaderboard_weekly;

CREATE MATERIALIZED VIEW leaderboard_weekly AS
SELECT
  u.id as user_id,
  COALESCE(u.username, 'User' || SUBSTRING(u.id::text FROM 1 FOR 8)) as username,
  -- Total kanji studied (all time)
  COUNT(DISTINCT CASE WHEN sr.type = 'kanji' THEN sr.target_id END) as total_kanji,
  -- Total kanji mastered (all time)
  COUNT(DISTINCT CASE WHEN sr.type = 'kanji' AND sr.status = 'mastered' THEN sr.target_id END) as mastered_kanji,
  -- Kanji studied in the last 7 days
  COUNT(DISTINCT CASE
    WHEN sr.type = 'kanji' AND sr.created_at > NOW() - INTERVAL '7 days'
    THEN sr.target_id
  END) as weekly_kanji,
  -- Rank based on weekly kanji count
  ROW_NUMBER() OVER (
    ORDER BY COUNT(DISTINCT CASE
      WHEN sr.type = 'kanji' AND sr.created_at > NOW() - INTERVAL '7 days'
      THEN sr.target_id
    END) DESC
  ) as rank
FROM users u
LEFT JOIN study_records sr ON u.id = sr.user_id
WHERE u.show_on_leaderboard = true
GROUP BY u.id, u.username;

-- Create index on the materialized view for faster queries
CREATE INDEX IF NOT EXISTS idx_leaderboard_weekly_rank ON leaderboard_weekly(rank);
CREATE INDEX IF NOT EXISTS idx_leaderboard_weekly_user_id ON leaderboard_weekly(user_id);

-- ============================================
-- 5. Helper Functions
-- ============================================

-- Function to refresh the leaderboard view
CREATE OR REPLACE FUNCTION refresh_leaderboard()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW leaderboard_weekly;
END;
$$;

-- Function to check and update user achievements
CREATE OR REPLACE FUNCTION check_user_achievements(p_user_id UUID)
RETURNS TABLE(achievement_id TEXT, newly_unlocked BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE
  v_kanji_count INTEGER;
  v_mastered_count INTEGER;
  v_streak INTEGER;
  v_weekly_count INTEGER;
  v_mastery_rate NUMERIC;
BEGIN
  -- Calculate user statistics
  SELECT
    COUNT(DISTINCT CASE WHEN type = 'kanji' THEN target_id END),
    COUNT(DISTINCT CASE WHEN type = 'kanji' AND status = 'mastered' THEN target_id END),
    COUNT(DISTINCT CASE WHEN type = 'kanji' AND created_at > NOW() - INTERVAL '7 days' THEN target_id END)
  INTO v_kanji_count, v_mastered_count, v_weekly_count
  FROM study_records
  WHERE user_id = p_user_id;

  -- Calculate mastery rate
  IF v_kanji_count > 0 THEN
    v_mastery_rate := (v_mastered_count::NUMERIC / v_kanji_count::NUMERIC) * 100;
  ELSE
    v_mastery_rate := 0;
  END IF;

  -- Check kanji_count achievements
  RETURN QUERY
  SELECT
    a.id as achievement_id,
    NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    ) as newly_unlocked
  FROM achievements a
  WHERE a.type = 'kanji_count' AND a.required_count <= v_mastered_count
    AND NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    );

  -- Check weekly_count achievements
  RETURN QUERY
  SELECT
    a.id as achievement_id,
    NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    ) as newly_unlocked
  FROM achievements a
  WHERE a.type = 'weekly_count' AND a.required_count <= v_weekly_count
    AND NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    );

  -- Check mastery_rate achievements
  RETURN QUERY
  SELECT
    a.id as achievement_id,
    NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    ) as newly_unlocked
  FROM achievements a
  WHERE a.type = 'mastery_rate' AND a.required_count <= v_mastery_rate
    AND NOT EXISTS(
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id
    );
END;
$$;

-- ============================================
-- 6. Performance Indexes
-- ============================================

-- Indexes for user_achievements
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);

-- Indexes for study_records (if not already exist)
CREATE INDEX IF NOT EXISTS idx_study_records_created_at ON study_records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_study_records_user_type ON study_records(user_id, type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_study_records_user_status ON study_records(user_id, status);

-- ============================================
-- 7. Initial Achievement Data
-- ============================================

-- Insert default achievements
INSERT INTO achievements (id, title, description, icon, required_count, type) VALUES
  -- Kanji count achievements
  ('kanji_10', '첫 걸음', '10개 한자 마스터', '🎯', 10, 'kanji_count'),
  ('kanji_50', '열정적인 학습자', '50개 한자 마스터', '🏆', 50, 'kanji_count'),
  ('kanji_100', '한자 마스터', '100개 한자 마스터', '👑', 100, 'kanji_count'),
  ('kanji_200', '한자 전문가', '200개 한자 마스터', '💎', 200, 'kanji_count'),
  ('kanji_500', '한자 챔피언', '500개 한자 마스터', '⭐', 500, 'kanji_count'),
  ('kanji_1000', '한자 마에스트로', '1000개 한자 마스터', '🌟', 1000, 'kanji_count'),
  ('kanji_2000', '한자 그랜드마스터', '2000개 한자 마스터', '👹', 2000, 'kanji_count'),

  -- Streak achievements
  ('streak_3', '시작이 반', '3일 연속 학습', '🔥', 3, 'streak'),
  ('streak_7', '일주일 연속', '7일 연속 학습', '🔥🔥', 7, 'streak'),
  ('streak_14', '2주 연속', '14일 연속 학습', '🔥🔥🔥', 14, 'streak'),
  ('streak_30', '한 달 연속', '30일 연속 학습', '🔥🔥🔥🔥', 30, 'streak'),
  ('streak_100', '100일 챌린지', '100일 연속 학습', '🔥🔥🔥🔥🔥', 100, 'streak'),

  -- Weekly count achievements
  ('weekly_20', '주간 학습자', '일주일에 20개 학습', '⚡', 20, 'weekly_count'),
  ('weekly_50', '주간 챔피언', '일주일에 50개 학습', '⚡⚡', 50, 'weekly_count'),
  ('weekly_100', '주간 마스터', '일주일에 100개 학습', '⚡⚡⚡', 100, 'weekly_count'),

  -- Mastery rate achievements
  ('mastery_70', '정확한 학습자', '성공률 70% 달성', '✨', 70, 'mastery_rate'),
  ('mastery_80', '완벽주의자', '성공률 80% 달성', '✨✨', 80, 'mastery_rate'),
  ('mastery_90', '완벽 마스터', '성공률 90% 달성', '✨✨✨', 90, 'mastery_rate')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 8. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on new tables
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_goals ENABLE ROW LEVEL SECURITY;

-- user_achievements policies
CREATE POLICY "Users can view all achievements"
  ON user_achievements FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own achievements"
  ON user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own achievements"
  ON user_achievements FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- daily_goals policies
CREATE POLICY "Users can view their own goals"
  ON daily_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals"
  ON daily_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals"
  ON daily_goals FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- achievements table (read-only for all users)
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view achievements"
  ON achievements FOR SELECT
  USING (true);

-- ============================================
-- 9. Triggers for Auto-updating
-- ============================================

-- Trigger to update daily_goals updated_at
CREATE OR REPLACE FUNCTION update_daily_goals_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_daily_goals_timestamp
  BEFORE UPDATE ON daily_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_goals_timestamp();

-- ============================================
-- Migration Complete
-- ============================================

-- Refresh the leaderboard view
SELECT refresh_leaderboard();

COMMENT ON TABLE achievements IS 'Defines all available achievements/badges in the app';
COMMENT ON TABLE user_achievements IS 'Tracks user progress and unlocked achievements';
COMMENT ON TABLE daily_goals IS 'User-specific daily study targets';
COMMENT ON MATERIALIZED VIEW leaderboard_weekly IS 'Weekly leaderboard rankings for performance';
