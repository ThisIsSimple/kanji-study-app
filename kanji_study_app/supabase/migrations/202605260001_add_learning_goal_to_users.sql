alter table public.users
  add column if not exists daily_goal integer,
  add column if not exists target_jlpt_level integer;

alter table public.users
  add constraint users_daily_goal_range
  check (daily_goal is null or (daily_goal >= 1 and daily_goal <= 100));

alter table public.users
  add constraint users_target_jlpt_level_range
  check (
    target_jlpt_level is null
    or (target_jlpt_level >= 1 and target_jlpt_level <= 5)
  );
