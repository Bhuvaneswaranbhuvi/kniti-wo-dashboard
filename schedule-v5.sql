-- Knit-I — Scheduling upgrade (v5)
-- Run AFTER mill-updates-v4.sql. Safe to run more than once.
--
-- Upgrades `assignments` for proper scheduling:
--   start_date / end_date  — visit window (scheduled_date kept for backward compat = start_date)
--   wo_number              — auto order number issued at scheduling time:
--                            IN-2607-003 (installation), SE-2607-003 (service/repair),
--                            PM-2607-001 (preventive maintenance), RN-2607-001 (R&D)
--   ticket_no              — support ticket reference that converts into this work order
--   production_id          — link to production_dispatch (installation orders fetch machine details from it)
--   details                — jsonb: contacts shown to engineer, what-to-carry, machine info, eng comments

alter table assignments add column if not exists start_date date;
alter table assignments add column if not exists end_date date;
alter table assignments add column if not exists wo_number text;
alter table assignments add column if not exists ticket_no text;
alter table assignments add column if not exists production_id uuid references production_dispatch(id) on delete set null;
alter table assignments add column if not exists details jsonb not null default '{}'::jsonb;

create index if not exists assignments_wo_number_idx on assignments(wo_number);
create index if not exists assignments_start_date_idx on assignments(start_date);

-- Backfill start_date from legacy scheduled_date where possible
update assignments set start_date = scheduled_date::date
where start_date is null and scheduled_date is not null and scheduled_date ~ '^\d{4}-\d{2}-\d{2}';
