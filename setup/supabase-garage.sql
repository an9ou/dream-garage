-- Dream Garage: each person's garage (saved cars), stored in their account
-- Run once in Supabase: SQL Editor → New query → paste this whole file → Run. Safe to run again.
--
-- Who can do what (enforced by the database):
--   • Only you can see, add to, reorder or clear your own garage
--   • Logged-out visitors and other users can't see anyone's garage

-- 1. Table: one row per saved car per person ----------------------------------------------------------
create table if not exists public.garage_cars (
  user_id  uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  car_id   integer     not null check (car_id between 1 and 10000),
  car_name text        not null default '' check (char_length(car_name) <= 80),  -- for reading in the dashboard
  position integer     not null default 0,                                        -- your drag-and-drop order
  added_at timestamptz not null default now(),
  primary key (user_id, car_id)                                                   -- each car once per person
);

-- 2. Row Level Security: everyone only ever touches their own rows -------------------------------------
alter table public.garage_cars enable row level security;

drop policy if exists "Users see their own garage" on public.garage_cars;
create policy "Users see their own garage" on public.garage_cars
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "Users add to their own garage" on public.garage_cars;
create policy "Users add to their own garage" on public.garage_cars
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "Users reorder their own garage" on public.garage_cars;
create policy "Users reorder their own garage" on public.garage_cars
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "Users remove from their own garage" on public.garage_cars;
create policy "Users remove from their own garage" on public.garage_cars
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 3. Access: logged-out visitors get nothing; logged-in users get their own rows (via the rules above) ------
revoke all on public.garage_cars from anon;
grant select, insert, update, delete on public.garage_cars to authenticated;

-- 4. A readable view for you in the dashboard (Table Editor → garage_summary) ---------------------------
create or replace view public.garage_summary
with (security_invoker = true)
as
select
  u.email,
  count(g.*)                                                  as cars_saved,
  string_agg(g.car_name, ', ' order by g.position, g.added_at) as garage_in_order,
  max(g.added_at)                                             as last_added
from public.garage_cars g
join auth.users u on u.id = g.user_id
group by u.email
order by cars_saved desc, u.email;

revoke all on public.garage_summary from anon, authenticated;   -- dashboard only
