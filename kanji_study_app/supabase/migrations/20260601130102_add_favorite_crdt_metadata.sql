-- Add CRDT metadata for deterministic favorite sync across offline devices.
-- Run in Supabase SQL editor or via `supabase db push` before releasing the app update.

ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS is_favorite boolean,
  ADD COLUMN IF NOT EXISTS operation_timestamp timestamptz,
  ADD COLUMN IF NOT EXISTS operation_id text,
  ADD COLUMN IF NOT EXISTS device_id text;

UPDATE public.favorites
SET
  is_favorite = COALESCE(is_favorite, true),
  operation_timestamp = COALESCE(operation_timestamp, created_at, now()),
  operation_id = COALESCE(operation_id, 'legacy-' || id::text),
  device_id = COALESCE(NULLIF(device_id, ''), 'legacy');

WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, type, target_id
      ORDER BY operation_timestamp DESC, operation_id DESC, id DESC
    ) AS row_number
  FROM public.favorites
)
DELETE FROM public.favorites AS favorites
USING ranked
WHERE favorites.id = ranked.id
  AND ranked.row_number > 1;

ALTER TABLE public.favorites
  ALTER COLUMN is_favorite SET DEFAULT true,
  ALTER COLUMN is_favorite SET NOT NULL,
  ALTER COLUMN operation_timestamp SET NOT NULL,
  ALTER COLUMN operation_id SET NOT NULL,
  ALTER COLUMN device_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS favorites_user_type_target_unique
  ON public.favorites (user_id, type, target_id);
