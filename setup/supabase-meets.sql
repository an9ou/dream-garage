-- Dream Garage: shared car meets
-- Run once in Supabase: SQL Editor → New query → paste this whole file → Run.
-- It's safe to run again (for example after an update); it won't delete any meets.
--
-- Who can do what (enforced by the database, so no one can get around it from the website):
--   • Anyone, even logged out: see meets, and how many people are going
--   • Logged-in users: host a meet, RSVP for themselves, and see who is going
--   • Hosts only: edit or cancel their own meets
--   • The database also blocks meets dated in the past and RSVPs beyond a meet's capacity

-- 1. Tables ---------------------------------------------------------------------------------------
create table if not exists public.events (
  id          bigint generated always as identity primary key,
  title       text        not null check (char_length(title) between 1 and 80),
  host_name   text        not null check (char_length(host_name) between 1 and 40),
  date        date        not null,
  time        time        not null,
  capacity    integer     not null default 30 check (capacity between 1 and 500),
  venue       text        not null check (char_length(venue) between 1 and 80),
  description text        not null default '' check (char_length(description) <= 1000),
  created_by  uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);
create index if not exists events_date_idx on public.events (date);

create table if not exists public.rsvps (
  event_id     bigint      not null references public.events (id) on delete cascade,
  user_id      uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  display_name text        not null check (char_length(display_name) between 1 and 40),
  status       text        not null check (status in ('Attending', 'Maybe', 'Cannot Attend')),
  updated_at   timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- 2. Row Level Security: every request is checked against these rules --------------------------------
alter table public.events enable row level security;
alter table public.rsvps  enable row level security;

drop policy if exists "Anyone can see meets" on public.events;
create policy "Anyone can see meets" on public.events
  for select to anon, authenticated using (true);

drop policy if exists "Logged-in users can host meets" on public.events;
create policy "Logged-in users can host meets" on public.events
  for insert to authenticated with check ((select auth.uid()) = created_by);

drop policy if exists "Hosts can edit their own meets" on public.events;
create policy "Hosts can edit their own meets" on public.events
  for update to authenticated using ((select auth.uid()) = created_by) with check ((select auth.uid()) = created_by);

drop policy if exists "Hosts can cancel their own meets" on public.events;
create policy "Hosts can cancel their own meets" on public.events
  for delete to authenticated using ((select auth.uid()) = created_by);

drop policy if exists "Anyone can count RSVPs" on public.rsvps;
create policy "Anyone can count RSVPs" on public.rsvps
  for select to anon using (true);          -- logged-out visitors only get the columns granted below (no names)

drop policy if exists "Logged-in users can see RSVPs" on public.rsvps;
create policy "Logged-in users can see RSVPs" on public.rsvps
  for select to authenticated using (true);

drop policy if exists "Users RSVP for themselves" on public.rsvps;
create policy "Users RSVP for themselves" on public.rsvps
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "Users change their own RSVP" on public.rsvps;
create policy "Users change their own RSVP" on public.rsvps
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "Users remove their own RSVP" on public.rsvps;
create policy "Users remove their own RSVP" on public.rsvps
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 3. Table access for the website's two roles (anon = logged out, authenticated = logged in) -------------
grant usage on schema public to anon, authenticated;
grant select on public.events to anon, authenticated;
grant insert, update, delete on public.events to authenticated;
revoke all on public.rsvps from anon;
grant select (event_id, status) on public.rsvps to anon;   -- logged-out visitors can count RSVPs, but can't see names
grant select, insert, update, delete on public.rsvps to authenticated;

-- 4. Rules the database enforces ------------------------------------------------------------------
create or replace function public.dg_check_event() returns trigger
language plpgsql set search_path = '' as $$
begin
  -- one day of slack for time zones (the database clock is UTC, Hong Kong is UTC+8)
  if tg_op = 'INSERT' and new.date < current_date - 1 then
    raise exception 'Pick a date from today onwards' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' then           -- a meet can't be handed to someone else
    new.created_by := old.created_by;
    new.created_at := old.created_at;
  end if;
  return new;
end $$;
drop trigger if exists dg_check_event on public.events;
create trigger dg_check_event before insert or update on public.events
  for each row execute function public.dg_check_event();

create or replace function public.dg_check_rsvp() returns trigger
language plpgsql set search_path = '' as $$
declare
  cap   integer;
  going integer;
begin
  new.updated_at := now();
  if new.status = 'Attending' then
    select e.capacity into cap from public.events e where e.id = new.event_id;
    select count(*) into going from public.rsvps r
      where r.event_id = new.event_id and r.status = 'Attending' and r.user_id <> new.user_id;
    if going >= cap then
      raise exception 'This meet is full' using errcode = 'P0001';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists dg_check_rsvp on public.rsvps;
create trigger dg_check_rsvp before insert or update on public.rsvps
  for each row execute function public.dg_check_rsvp();

-- 5. Live updates: new meets and RSVPs appear on everyone's screen without refreshing ----------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'events') then
      alter publication supabase_realtime add table public.events;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'rsvps') then
      alter publication supabase_realtime add table public.rsvps;
    end if;
  end if;
end $$;
