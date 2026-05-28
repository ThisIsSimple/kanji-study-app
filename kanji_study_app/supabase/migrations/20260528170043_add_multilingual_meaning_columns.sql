-- KANJI-11: Japanese word meanings and multilingual kanji compatibility columns.
-- Generated at: 2026-05-28T17:00:43+09:00 (Asia/Seoul)
-- Run in Supabase SQL editor or via `supabase db push` after review.

alter table public.words
  add column if not exists meanings_jp jsonb not null default '[]'::jsonb;

alter table public.kanji
  add column if not exists jp_on_readings text[] not null default '{}',
  add column if not exists jp_kun_readings text[] not null default '{}',
  add column if not exists kr_on_readings text[] not null default '{}',
  add column if not exists kr_kun_readings text[] not null default '{}',
  add column if not exists kr_meanings text[] not null default '{}',
  add column if not exists jp_meanings text[] not null default '{}',
  add column if not exists en_meanings text[] not null default '{}',
  add column if not exists kr_commentary text,
  add column if not exists jp_commentary text,
  add column if not exists en_commentary text;

update public.kanji
set
  jp_on_readings = case
    when coalesce(cardinality(jp_on_readings), 0) = 0 then coalesce(on_readings, '{}')
    else jp_on_readings
  end,
  jp_kun_readings = case
    when coalesce(cardinality(jp_kun_readings), 0) = 0 then coalesce(kun_readings, '{}')
    else jp_kun_readings
  end,
  kr_on_readings = case
    when coalesce(cardinality(kr_on_readings), 0) = 0 then coalesce(korean_on_readings, '{}')
    else kr_on_readings
  end,
  kr_kun_readings = case
    when coalesce(cardinality(kr_kun_readings), 0) = 0 then coalesce(korean_kun_readings, '{}')
    else kr_kun_readings
  end,
  kr_meanings = case
    when coalesce(cardinality(kr_meanings), 0) = 0 then case
      when coalesce(cardinality(meanings_ko), 0) > 0 then meanings_ko
      else coalesce(meanings, '{}')
    end
    else kr_meanings
  end,
  en_meanings = case
    when coalesce(cardinality(en_meanings), 0) = 0 then coalesce(meanings_en, '{}')
    else en_meanings
  end,
  kr_commentary = coalesce(kr_commentary, commentary);
