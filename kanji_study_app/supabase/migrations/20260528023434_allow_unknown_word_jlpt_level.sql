-- KANJI-6: allow JLPT level 0 for words with no official JLPT mapping.
-- Generated at: 2026-05-28T02:34:34+09:00 (Asia/Seoul)
-- Run in Supabase SQL editor or via `supabase db push` before importing JMdict-only words.

alter table public.words
  drop constraint if exists words_jlpt_level_check;

alter table public.words
  add constraint words_jlpt_level_check
  check (jlpt_level between 0 and 5);
