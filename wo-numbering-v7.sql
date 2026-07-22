-- Knit-I — Atomic Work Order numbering (v7)
-- Run AFTER machines-dedupe-v6.sql. Safe to run more than once.
--
-- Replaces the old client-side "find the max existing number and add 1"
-- approach (which could return the same number twice if two people
-- scheduled at nearly the same time, or if the lookup query silently
-- failed and defaulted to 0) with a single atomic database counter.
-- Postgres serializes the upsert below, so two simultaneous calls can
-- never receive the same sequence number.

create table if not exists wo_counters (
  type_month text primary key,   -- e.g. 'IN-2607'
  seq int not null default 0
);
alter table wo_counters enable row level security;
drop policy if exists "wo_counters_all_authenticated" on wo_counters;
create policy "wo_counters_all_authenticated" on wo_counters for all to authenticated using (true) with check (true);

create or replace function public.next_wo_number(p_type text)
returns text
language plpgsql
security definer
as $$
declare
  v_prefix text;
  v_key text;
  v_seq int;
begin
  v_prefix := case p_type
    when 'installation' then 'IN'
    when 'service' then 'SE'
    when 'pm' then 'PM'
    when 'rnd' then 'RN'
    else 'SE'
  end;
  v_key := v_prefix || '-' || to_char(now(), 'YYMM');

  insert into wo_counters(type_month, seq) values (v_key, 1)
  on conflict (type_month) do update set seq = wo_counters.seq + 1
  returning seq into v_seq;

  return v_key || '-' || lpad(v_seq::text, 3, '0');
end;
$$;

grant execute on function public.next_wo_number(text) to authenticated;

-- One-time: seed the counter from the highest number already in use this
-- month, so numbering continues from where the old (buggy) system left off
-- instead of restarting at 001 and potentially re-issuing a used number.
insert into wo_counters(type_month, seq)
select
  substring(wo_number from '^([A-Z]+-\d{4})-\d+$') as type_month,
  max((regexp_match(wo_number, '-(\d+)$'))[1]::int) as seq
from (
  select wo_number from assignments where wo_number ~ '^[A-Z]+-\d{4}-\d+$'
  union all
  select wo_number from orders where wo_number ~ '^[A-Z]+-\d{4}-\d+$'
) all_numbers
group by 1
on conflict (type_month) do update set seq = greatest(wo_counters.seq, excluded.seq);
