-- Add a client-generated id for idempotent flashcard session sync retries.
-- Run in Supabase SQL editor or via `supabase db push` before releasing the app update.

ALTER TABLE public.flashcard_sessions
  ADD COLUMN IF NOT EXISTS session_client_id text;

UPDATE public.flashcard_sessions
SET session_client_id = 'legacy-' || id::text
WHERE session_client_id IS NULL OR session_client_id = '';

ALTER TABLE public.flashcard_sessions
  ALTER COLUMN session_client_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS flashcard_sessions_user_client_unique
  ON public.flashcard_sessions (user_id, session_client_id);
