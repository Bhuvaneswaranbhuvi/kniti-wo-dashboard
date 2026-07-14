-- Knit-I Work Order — Add login & roles
--
-- Run this AFTER supabase-setup.sql (SQL Editor → New Query → paste → Run).
-- This adds real login (Supabase Auth) with three roles — admin, engineer,
-- coordinator — and locks orders/assignments down to logged-in users only.
--
-- How roles work here, and why: anyone can sign themselves up on the login
-- screen (safe — uses the public anon key). New accounts default to
-- "engineer". An admin then promotes people to "coordinator" or "admin" from
-- the dashboard's Admin tab. Nobody (not even an admin) creates accounts on
-- someone else's behalf from the app — that would require exposing Supabase's
-- service_role key in client code, which must never happen.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'engineer' check (role in ('admin','engineer','coordinator')),
  created_at timestamptz default now()
);

alter table profiles enable row level security;
grant usage on schema public to authenticated;
grant select, update on profiles to authenticated;

-- Helper function: checks if the calling user is an admin. Must be
-- SECURITY DEFINER so this check bypasses RLS on profiles itself — otherwise
-- the admin policies below would recurse into themselves infinitely (a
-- real, easy-to-hit bug with self-referencing RLS policies).
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

-- Everyone can see their own profile (needed so the app can show your name/role)
create policy "profiles_self_select" on profiles
  for select to authenticated using (auth.uid() = id);

-- Admins can see every profile (needed for the Admin tab's user list)
create policy "profiles_admin_select" on profiles
  for select to authenticated using (public.is_admin());

-- Only admins can change anyone's role (including their own)
create policy "profiles_admin_update" on profiles
  for update to authenticated using (public.is_admin());

-- Auto-create a profile row (role: engineer) the moment someone signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'name', new.email), 'engineer');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Replace the old "anyone with the anon key" policies from supabase-setup.sql
-- with "must be logged in" — orders and assignments now require a session.
drop policy if exists "orders_anon_all" on orders;
drop policy if exists "assignments_anon_all" on assignments;

create policy "orders_authenticated_all" on orders
  for all to authenticated using (true) with check (true);

create policy "assignments_authenticated_all" on assignments
  for all to authenticated using (true) with check (true);

-- Photos stay public-read (so images display in the dashboard/report) but
-- only logged-in users can upload.
drop policy if exists "photos_anon_upload" on storage.objects;
create policy "photos_authenticated_upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'photos');
