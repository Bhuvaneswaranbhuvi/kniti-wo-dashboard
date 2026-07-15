-- Knit-I — Mill-wise Updates module
--
-- Run AFTER your existing supabase-setup.sql + auth-and-roles.sql +
-- permissions-v2.sql (SQL Editor → New Query → paste this whole file → Run).
--
-- Adds three tables that back the new mill-updates.html page:
--   mills          — master list of mills/factories
--   machines       — machines at each mill (machine-wise records)
--   mill_updates   — the actual entries: to-dos, pain points, engineer
--                    suggestions, customer requirements, visit logs —
--                    all tagged to a mill and optionally to one machine
--
-- Work-order summary (completed/pending/assigned counts) is NOT a new table —
-- it's computed in the page itself from your existing `orders` and
-- `assignments` tables, matched to a mill by name (or by the aliases list
-- below, for when a mill is typed differently on different work orders).

create table if not exists mills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  area text,               -- e.g. Tirupur, Erode, Coimbatore
  address text,
  contact_name text,
  contact_phone text,
  -- other spellings/short forms this mill appears under in orders.customer,
  -- so the work-order summary can still find them (e.g. "Jay Jay", "JJ Mills")
  aliases text[] not null default '{}',
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists machines (
  id uuid primary key default gen_random_uuid(),
  mill_id uuid not null references mills(id) on delete cascade,
  machine_no text not null,       -- e.g. "KM-04" or asset tag
  machine_type text,              -- e.g. Single Jersey, Rib, Interlock
  brand text,
  model text,
  serial_no text,
  gauge text,
  diameter text,
  install_date date,
  notes text,
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  unique (mill_id, machine_no)
);

create table if not exists mill_updates (
  id uuid primary key default gen_random_uuid(),
  mill_id uuid not null references mills(id) on delete cascade,
  machine_id uuid references machines(id) on delete set null,  -- null = mill-wide, not machine-specific
  category text not null check (category in ('todo','pain_point','suggestion','requirement','visit_log')),
  title text,
  description text,
  status text not null default 'open' check (status in ('open','in_progress','done')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  images jsonb not null default '[]'::jsonb,   -- array of public photo URLs (same 'photos' bucket)
  visit_date date,          -- relevant for visit_log entries, optional elsewhere
  created_by uuid references profiles(id),
  created_by_name text,     -- denormalized so the list doesn't need a join
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists mill_updates_mill_idx on mill_updates(mill_id);
create index if not exists mill_updates_machine_idx on mill_updates(machine_id);
create index if not exists mill_updates_category_idx on mill_updates(category);
create index if not exists machines_mill_idx on machines(mill_id);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists mill_updates_set_updated_at on mill_updates;
create trigger mill_updates_set_updated_at
  before update on mill_updates
  for each row execute procedure public.set_updated_at();

alter table mills enable row level security;
alter table machines enable row level security;
alter table mill_updates enable row level security;

-- Same posture as the rest of the app: any logged-in user (engineer,
-- coordinator, admin) can read and add. Editing/deleting is tighter —
-- an engineer can fix their own entry, only admins can touch others' or
-- delete outright (mirrors permissions-v2.sql's pattern for orders).

create policy "mills_select_all" on mills for select to authenticated using (true);
create policy "mills_insert_any" on mills for insert to authenticated with check (true);
create policy "mills_update_admin_or_coordinator" on mills for update to authenticated
  using (public.is_admin() or public.is_coordinator());
create policy "mills_delete_admin_only" on mills for delete to authenticated using (public.is_admin());

create policy "machines_select_all" on machines for select to authenticated using (true);
create policy "machines_insert_any" on machines for insert to authenticated with check (true);
create policy "machines_update_admin_or_coordinator" on machines for update to authenticated
  using (public.is_admin() or public.is_coordinator());
create policy "machines_delete_admin_only" on machines for delete to authenticated using (public.is_admin());

create policy "mill_updates_select_all" on mill_updates for select to authenticated using (true);
create policy "mill_updates_insert_any" on mill_updates for insert to authenticated with check (true);
create policy "mill_updates_update_own_or_admin" on mill_updates for update to authenticated
  using (created_by = auth.uid() or public.is_admin() or public.is_coordinator());
create policy "mill_updates_delete_own_or_admin" on mill_updates for delete to authenticated
  using (created_by = auth.uid() or public.is_admin());

-- Photos for this module reuse the existing public 'photos' bucket and its
-- existing policies (public read, authenticated upload) — nothing new needed
-- there, as long as supabase-setup.sql has already been run.
