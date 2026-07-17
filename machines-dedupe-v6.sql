-- Knit-I — Machines dedupe + Tailscale IP uniqueness (v6)
-- Run AFTER schedule-v5.sql. Safe to run more than once.
--
-- 1. Removes duplicate machines that share the same Tailscale IP:
--    keeps the OLDEST record per IP, repoints any mill_updates entries
--    from the duplicates to the kept machine, then deletes the duplicates.
-- 2. Adds a unique index so the same Tailscale IP can never be saved twice.

-- ---- 1. Dedupe ----------------------------------------------------------
with ranked as (
  select id, tailscale_ip,
         first_value(id) over (partition by lower(trim(tailscale_ip)) order by created_at asc, id asc) as keep_id
  from machines
  where tailscale_ip is not null and trim(tailscale_ip) <> ''
),
dups as (
  select id, keep_id from ranked where id <> keep_id
)
update mill_updates mu
set machine_id = d.keep_id
from dups d
where mu.machine_id = d.id;

with ranked as (
  select id, tailscale_ip,
         first_value(id) over (partition by lower(trim(tailscale_ip)) order by created_at asc, id asc) as keep_id
  from machines
  where tailscale_ip is not null and trim(tailscale_ip) <> ''
)
delete from machines m
using ranked r
where m.id = r.id and r.id <> r.keep_id;

-- ---- 2. Enforce uniqueness going forward --------------------------------
-- Normalised (case/space-insensitive) unique index, ignoring empty values.
create unique index if not exists machines_tailscale_ip_uniq
  on machines (lower(trim(tailscale_ip)))
  where tailscale_ip is not null and trim(tailscale_ip) <> '';
