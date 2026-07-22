-- Knit-I — Issues Faced by Engineer (v8)
-- Run AFTER wo-numbering-v7.sql. Safe to run more than once.
--
-- Adds a new mill_updates category "issue" (Mechanical / Electrical /
-- Customer Miscommunication / Accommodation / Transport) with its own
-- issue_type column, alongside the existing todo/pain_point/suggestion/
-- requirement/visit_log categories.

alter table mill_updates drop constraint if exists mill_updates_category_check;
alter table mill_updates add constraint mill_updates_category_check
  check (category in ('todo','pain_point','suggestion','requirement','visit_log','issue'));

alter table mill_updates add column if not exists issue_type text
  check (issue_type is null or issue_type in ('mechanical','electrical','customer_miscommunication','accommodation','transport'));
