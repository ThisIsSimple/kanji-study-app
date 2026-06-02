-- Backfill-compatible idempotency fixes for offline sync retries.
-- This is a corrective migration for the already-applied flashcard session client id migration.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.flashcard_sessions
  ALTER COLUMN session_client_id
  SET DEFAULT ('server-' || gen_random_uuid()::text);

ALTER TABLE public.study_records
  ADD COLUMN IF NOT EXISTS record_client_id text;

CREATE UNIQUE INDEX IF NOT EXISTS study_records_user_client_unique
  ON public.study_records (user_id, record_client_id);
