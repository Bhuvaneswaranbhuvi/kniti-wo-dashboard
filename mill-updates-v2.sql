-- Knit-I — Mill Updates v2
-- Run AFTER mill-updates-schema.sql. Safe to run more than once.
--
-- Adds:
--   1. Knit-I machine configuration columns on `machines`
--      (cabinet serial, version, internet component, processing unit,
--       storage, display, wiper, cameras with lights + cable, IPs)
--   2. `production_dispatch` — production plans, dispatch/courier tracking,
--      BOM with shipped/shortage per line, mechanical diagram images

-- 1. Machine config -------------------------------------------------------
alter table machines add column if not exists cabinet_serial text;
alter table machines add column if not exists kniti_version text;      -- V11 / V10 / Supernova Single / Supernova Double / Super2Nova / Super3Nova / Intel
alter table machines add column if not exists internet_component text; -- UGREEN Ethernet Adapter / Bestor Ethernet Adapter / UGREEN Hub + Ethernet Adapter
alter table machines add column if not exists processing_unit text;    -- RPi 5 / ASUS Prime H510M-E R2 / ASUS Strix B760I
alter table machines add column if not exists storage_type text;       -- SD Card / SSD NVMe
alter table machines add column if not exists storage_capacity text;   -- 128GB..2TB
alter table machines add column if not exists display_type text;       -- 12V Monitor / 12V Tab / 230V Tab
alter table machines add column if not exists display_size text;       -- 3" / 5" / 7" / 10"
alter table machines add column if not exists wiper_installed boolean;
alter table machines add column if not exists num_cameras int;
-- one object per camera: [{"cam":1,"lights":"...","cable":"5m Shielded"}, ...]
alter table machines add column if not exists cameras jsonb not null default '[]'::jsonb;
alter table machines add column if not exists tailscale_ip text;
alter table machines add column if not exists internet_ip text;

-- 2. Production & Dispatch ------------------------------------------------
create table if not exists production_dispatch (
  id uuid primary key default gen_random_uuid(),
  mill_id uuid not null references mills(id) on delete cascade,
  title text not null,                -- e.g. "Knit-I install batch — 4 machines"
  status text not null default 'planned'
    check (status in ('planned','in_production','ready','dispatched','delivered')),
  planned_date date,
  dispatch_date date,
  courier_name text,
  tracking_no text,
  tracking_url text,
  -- BOM / shipment lines: [{"item":"RPi 5","qty":2,"unit":"nos","status":"shipped|shortage|pending","note":""}]
  bom jsonb not null default '[]'::jsonb,
  images jsonb not null default '[]'::jsonb,   -- mechanical diagrams, packing photos
  notes text,
  created_by uuid references profiles(id),
  created_by_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists production_dispatch_mill_idx on production_dispatch(mill_id);
create index if not exists production_dispatch_status_idx on production_dispatch(status);

drop trigger if exists production_dispatch_set_updated_at on production_dispatch;
create trigger production_dispatch_set_updated_at
  before update on production_dispatch
  for each row execute procedure public.set_updated_at();

alter table production_dispatch enable row level security;

drop policy if exists "prod_select_all" on production_dispatch;
create policy "prod_select_all" on production_dispatch for select to authenticated using (true);
drop policy if exists "prod_insert_any" on production_dispatch;
create policy "prod_insert_any" on production_dispatch for insert to authenticated with check (true);
drop policy if exists "prod_update_own_or_admin" on production_dispatch;
create policy "prod_update_own_or_admin" on production_dispatch for update to authenticated
  using (created_by = auth.uid() or public.is_admin() or public.is_coordinator());
drop policy if exists "prod_delete_admin_only" on production_dispatch;
create policy "prod_delete_admin_only" on production_dispatch for delete to authenticated
  using (created_by = auth.uid() or public.is_admin());
