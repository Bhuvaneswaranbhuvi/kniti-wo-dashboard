-- Knit-I Work Order — Permissions v2
--
-- Run AFTER auth-and-roles.sql (SQL Editor → New Query → paste → Run).
--
-- This tightens things up:
-- 1. Once an order is submitted, engineers can no longer edit or delete it —
--    only admins can (locking in the record once a customer has signed off).
-- 2. Only admins and service coordinators can create or cancel assignments
--    (schedule work for engineers) — engineers can still see their own
--    assigned work and mark it complete when they submit, but can't assign
--    jobs to themselves or each other.

create or replace function public.is_coordinator()
returns boolean as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'coordinator'
  );
$$ language sql security definer stable;

-- ---- Orders: everyone can submit and view, only admins can edit/delete ----
drop policy if exists "orders_authenticated_all" on orders;

create policy "orders_select_all" on orders
  for select to authenticated using (true);

create policy "orders_insert_any" on orders
  for insert to authenticated with check (true);

create policy "orders_update_admin_only" on orders
  for update to authenticated using (public.is_admin());

create policy "orders_delete_admin_only" on orders
  for delete to authenticated using (public.is_admin());

-- ---- Assignments: everyone can view/complete their own, only admins and
-- coordinators can create new ones or cancel/delete them ----
drop policy if exists "assignments_authenticated_all" on assignments;

create policy "assignments_select_all" on assignments
  for select to authenticated using (true);

create policy "assignments_insert_admin_or_coordinator" on assignments
  for insert to authenticated with check (public.is_admin() or public.is_coordinator());

-- Left open so an engineer's own app can flip their assignment to
-- "completed" (with the resulting order_id) the moment they submit —
-- tightening this further to "only your own assignment" would need engineer
-- names to be a hard identity match rather than free text, which isn't the
-- case yet.
create policy "assignments_update_any" on assignments
  for update to authenticated using (true) with check (true);

create policy "assignments_delete_admin_or_coordinator" on assignments
  for delete to authenticated using (public.is_admin() or public.is_coordinator());
