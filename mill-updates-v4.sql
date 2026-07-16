-- Knit-I — Mill Updates v4
-- Run AFTER mill-updates-v3.sql. Safe to run more than once.
--
-- Adds to mill_updates:
--   comments   — jsonb array of {by, by_name, at, text} for a running thread on any entry
--   progress   — 0-100 percent complete (used on To-Dos)
--   flagged    — bottleneck / dependency flag
--   flag_note  — free text describing what's blocking it

alter table mill_updates add column if not exists comments jsonb not null default '[]'::jsonb;
alter table mill_updates add column if not exists progress int not null default 0 check (progress >= 0 and progress <= 100);
alter table mill_updates add column if not exists flagged boolean not null default false;
alter table mill_updates add column if not exists flag_note text;
