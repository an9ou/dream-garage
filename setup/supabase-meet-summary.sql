-- Dream Garage: a "meet_summary" view for the Supabase Table Editor
-- One row per meet with its name, host and RSVP counts. Always up to date; it stores nothing itself.
-- Run in Supabase: SQL Editor → New query → paste → Run. Safe to run again.

create or replace view public.meet_summary
with (security_invoker = true)            -- respects the same security rules as the tables
as
select
  e.id,
  e.title                                                         as meet,
  e.host_name                                                     as host,
  e.date,
  to_char(e.time, 'HH24:MI')                                      as time,
  e.venue,
  count(r.*) filter (where r.status = 'Attending')                as attending,
  count(r.*) filter (where r.status = 'Maybe')                    as maybe,
  count(r.*) filter (where r.status = 'Cannot Attend')            as cannot_attend,
  e.capacity,
  greatest(e.capacity - count(r.*) filter (where r.status = 'Attending'), 0) as spots_left,
  coalesce(string_agg(r.display_name, ', ' order by r.display_name)
           filter (where r.status = 'Attending'), '')             as who_is_attending
from public.events e
left join public.rsvps r on r.event_id = e.id
group by e.id
order by e.date, e.time;

-- For you in the dashboard only; the website doesn't use it
revoke all on public.meet_summary from anon, authenticated;
