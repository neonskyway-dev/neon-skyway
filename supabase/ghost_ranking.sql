-- =====================================================================
-- NEON SKYWAY オンライン・ゴーストランキング
-- Supabase の「SQL Editor」にこのファイルを丸ごと貼り付けて Run してください（1回だけ）。
--
-- 安全のしくみ
--  * テーブルは RLS を有効にしたうえでポリシーを1つも作らない → 公開用キー(anon)からは直接読み書きできない
--  * 公開用キーから使えるのは下の4つの関数だけ（中で入力をチェックする）
--      ns_ghost_top    コース別の上位100件
--      ns_ghost_rank   自分の順位
--      ns_ghost_get    ゴーストの走行データを1件ダウンロード
--      ns_ghost_submit 記録の登録（自己ベストのときだけ上書き）
--  * プレイヤーは端末ごとのランダムな合言葉(token)で区別し、DB には SHA-256 のハッシュだけを保存
--  * 走行データの長さとタイムの整合・最高速・ゴール到達をサーバー側で検査し、連投も制限する
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.ns_ghosts (
  id          bigint generated always as identity primary key,
  course      smallint    not null check (course between 0 and 63),
  course_ver  text        not null check (char_length(course_ver) between 3 and 48),
  player_hash text        not null check (char_length(player_hash) = 64),
  name        text        not null check (char_length(name) between 1 and 10),
  car         text        not null check (char_length(car) between 1 and 12),
  time_ms     integer     not null check (time_ms between 15000 and 1800000),
  ghost       jsonb       not null check (jsonb_typeof(ghost) = 'array'),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (course, course_ver, player_hash)
);
create index if not exists ns_ghosts_rank_idx on public.ns_ghosts (course, course_ver, time_ms, updated_at);
create index if not exists ns_ghosts_recent_idx on public.ns_ghosts (updated_at);

alter table public.ns_ghosts enable row level security;
revoke all on table public.ns_ghosts from anon, authenticated;

-- 上位100件（ゴースト本体は含めない）
create or replace function public.ns_ghost_top(p_course int, p_ver text)
returns table (id bigint, name text, car text, time_ms int, updated_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select g.id, g.name, g.car, g.time_ms, g.updated_at
  from public.ns_ghosts g
  where g.course = p_course and g.course_ver = p_ver
  order by g.time_ms asc, g.updated_at asc
  limit 100;
$$;

-- 自分の順位（登録がなければ0行）
create or replace function public.ns_ghost_rank(p_course int, p_ver text, p_token text)
returns table (rank bigint, time_ms int, total bigint)
language sql stable security definer set search_path = public, extensions
as $$
  with me as (
    select g.time_ms, g.updated_at from public.ns_ghosts g
    where g.course = p_course and g.course_ver = p_ver
      and g.player_hash = encode(extensions.digest(coalesce(p_token, ''), 'sha256'), 'hex')
  )
  select
    (select count(*) from public.ns_ghosts o where o.course = p_course and o.course_ver = p_ver
       and (o.time_ms < me.time_ms or (o.time_ms = me.time_ms and o.updated_at < me.updated_at))) + 1,
    me.time_ms,
    (select count(*) from public.ns_ghosts o where o.course = p_course and o.course_ver = p_ver)
  from me;
$$;

-- ゴースト1件
create or replace function public.ns_ghost_get(p_id bigint)
returns table (name text, car text, time_ms int, ghost jsonb)
language sql stable security definer set search_path = public
as $$
  select g.name, g.car, g.time_ms, g.ghost from public.ns_ghosts g where g.id = p_id;
$$;

-- 登録: 自己ベストのときだけ保存。戻り値は今の順位と、更新したかどうか
create or replace function public.ns_ghost_submit(p_course int, p_ver text, p_token text, p_name text, p_car text, p_time_ms int, p_ghost jsonb)
returns table (rank bigint, improved boolean)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  h text; old_t int; n int; i int; prev_s numeric; cur_s numeric; goal int; nm text; skips int := 0;
begin
  if p_token is null or char_length(p_token) < 32 or char_length(p_token) > 128 then raise exception 'bad token'; end if;
  if p_course is null or p_course < 0 or p_course > 63 then raise exception 'bad course'; end if;
  if p_ver is null or p_ver !~ '^[A-Z0-9 \-]{2,40}:[0-9]{3,6}$' then raise exception 'bad version'; end if;
  if p_time_ms is null or p_time_ms < 15000 or p_time_ms > 1800000 then raise exception 'bad time'; end if;
  if p_car is null or p_car !~ '^[A-Z]{2,12}$' then raise exception 'bad car'; end if;
  if p_ghost is null or jsonb_typeof(p_ghost) <> 'array' or octet_length(p_ghost::text) > 150000 then raise exception 'bad ghost'; end if;

  -- 走行データ: [s, x, h, s, x, h, ...] を 0.1 秒ごと。長さがタイムと合っているか・速すぎないか・ゴールまで届いているか
  n := jsonb_array_length(p_ghost);
  if n % 3 <> 0 or abs(n / 3 - p_time_ms / 100) > 25 then raise exception 'ghost length mismatch'; end if;
  goal := split_part(p_ver, ':', 2)::int;
  prev_s := null;
  for i in 0 .. n / 3 - 1 loop
    if jsonb_typeof(p_ghost -> (i * 3)) <> 'number' or jsonb_typeof(p_ghost -> (i * 3 + 1)) <> 'number' or jsonb_typeof(p_ghost -> (i * 3 + 2)) <> 'number' then raise exception 'bad sample'; end if;
    cur_s := (p_ghost ->> (i * 3))::numeric;
    if prev_s is not null and cur_s - prev_s > 18 then   -- 0.1秒で18m = 秒速180m（ゲーム内の最高速 約150m/秒より上）
      skips := skips + 1;   -- 谷に落ちたときの復帰（前方へワープ）だけは数回まで許す
      if skips > 4 or cur_s - prev_s > 400 then raise exception 'impossible speed'; end if;
    end if;
    if prev_s is not null and cur_s < prev_s - 400 then raise exception 'impossible move'; end if;
    prev_s := cur_s;
  end loop;
  if prev_s is null or prev_s < goal - 60 then raise exception 'did not finish'; end if;
  if goal::numeric / (p_time_ms / 1000.0) > 115 then raise exception 'too fast average'; end if;   -- 平均で秒速115m以上はありえない

  -- 名前: 記号を落として10文字まで
  nm := left(regexp_replace(coalesce(p_name, ''), '[^[:alnum:] _\-ぁ-んァ-ヶー一-龯]', '', 'g'), 10);
  if nm = '' then nm := 'PLAYER'; end if;

  h := encode(extensions.digest(p_token, 'sha256'), 'hex');
  -- 連投制限: 同じ人は10秒に1回 / 全体で1分に300回まで
  if exists (select 1 from public.ns_ghosts g where g.player_hash = h and g.updated_at > now() - interval '10 seconds') then raise exception 'too fast'; end if;
  if (select count(*) from public.ns_ghosts g where g.updated_at > now() - interval '1 minute') > 300 then raise exception 'busy'; end if;

  select g.time_ms into old_t from public.ns_ghosts g where g.course = p_course and g.course_ver = p_ver and g.player_hash = h;
  if old_t is null then
    insert into public.ns_ghosts (course, course_ver, player_hash, name, car, time_ms, ghost) values (p_course, p_ver, h, nm, p_car, p_time_ms, p_ghost);
  elsif p_time_ms < old_t then
    update public.ns_ghosts g set name = nm, car = p_car, time_ms = p_time_ms, ghost = p_ghost, updated_at = now()
      where g.course = p_course and g.course_ver = p_ver and g.player_hash = h;
  else
    update public.ns_ghosts g set name = nm where g.course = p_course and g.course_ver = p_ver and g.player_hash = h;
  end if;

  return query
    select r.rank, (old_t is null or p_time_ms < old_t) from public.ns_ghost_rank(p_course, p_ver, p_token) r;
end;
$$;

revoke all on function public.ns_ghost_top(int, text) from public;
revoke all on function public.ns_ghost_rank(int, text, text) from public;
revoke all on function public.ns_ghost_get(bigint) from public;
revoke all on function public.ns_ghost_submit(int, text, text, text, text, int, jsonb) from public;
grant execute on function public.ns_ghost_top(int, text) to anon, authenticated;
grant execute on function public.ns_ghost_rank(int, text, text) to anon, authenticated;
grant execute on function public.ns_ghost_get(bigint) to anon, authenticated;
grant execute on function public.ns_ghost_submit(int, text, text, text, text, int, jsonb) to anon, authenticated;
