-- KANJI-6: split Korean display meanings from English source glosses.
-- Generated at: 2026-05-27T23:46:33+09:00 (Asia/Seoul)
-- Run in Supabase SQL editor or via `supabase db push` after review.

alter table public.words
  add column if not exists meanings_ko jsonb not null default '[]'::jsonb,
  add column if not exists meanings_en jsonb not null default '[]'::jsonb;

alter table public.kanji
  add column if not exists meanings_ko text[] not null default '{}',
  add column if not exists meanings_en text[] not null default '{}';
