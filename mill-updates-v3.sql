-- Knit-I — Mill Updates v3
-- Run AFTER mill-updates-v2.sql. Safe to run more than once.
--
-- Adds multi-contact support to mills: each mill can now have any number
-- of contact persons (name, designation, phone) instead of a single
-- contact_name / contact_phone pair. Old columns are left in place
-- (unused by the UI going forward) so nothing breaks if referenced elsewhere.

alter table mills add column if not exists contacts jsonb not null default '[]'::jsonb;

-- One-time backfill: turn any existing single contact_name/contact_phone
-- into the first entry of the new contacts array, only where contacts is
-- still empty and a legacy value exists.
update mills
set contacts = jsonb_build_array(jsonb_build_object(
  'name', coalesce(contact_name,''), 'designation', '', 'phone', coalesce(contact_phone,'')
))
where (contacts is null or contacts = '[]'::jsonb)
  and (contact_name is not null or contact_phone is not null);
