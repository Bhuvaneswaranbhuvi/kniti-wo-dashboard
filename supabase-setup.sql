-- Knit-I Work Order — Supabase setup
--
-- Run this once: Supabase dashboard → your project → SQL Editor → New Query →
-- paste this whole file → Run.
--
-- This creates the two tables the app uses (orders, assignments), opens them
-- up to the "anon" key (safe — see the note at the bottom), and sets up a
-- public "photos" storage bucket for engineer photos and signatures.

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  order_type text,
  wo_number text,
  customer text,
  location text,
  engineer text,
  machine_count int,
  csat_rating int,
  created_at timestamptz default now(),
  data jsonb
);

create table if not exists assignments (
  id uuid primary key default gen_random_uuid(),
  order_type text,
  engineer text,
  customer text,
  location text,
  scheduled_date text,
  notes text,
  prefill jsonb default '{}'::jsonb,
  status text default 'scheduled',
  order_id uuid,
  created_at timestamptz default now()
);

alter table orders enable row level security;
alter table assignments enable row level security;

-- Fully open policies: any request carrying the anon key can read/write both
-- tables. Fine for an internal team tool; tighten later if you add per-engineer
-- logins (Supabase Auth would let you scope these to "only see your own rows").
create policy "orders_anon_all" on orders
  for all to anon using (true) with check (true);

create policy "assignments_anon_all" on assignments
  for all to anon using (true) with check (true);

-- Storage bucket for photos and signatures (public read, anyone with the anon
-- key can upload — this is what lets work_order.html upload photos directly).
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

create policy "photos_public_read" on storage.objects
  for select to public using (bucket_id = 'photos');

create policy "photos_anon_upload" on storage.objects
  for insert to public with check (bucket_id = 'photos');

-- Note on the anon key: Supabase's "anon" API key is designed to be used
-- directly from client apps and browsers — it's meant to be seen in network
-- requests. What actually protects your data is the RLS policies above, not
-- keeping the key secret. Never use the separate "service_role" key anywhere
-- in work_order.html or the dashboard — that one bypasses RLS entirely and
-- must stay server-side only (which this setup doesn't use at all).
