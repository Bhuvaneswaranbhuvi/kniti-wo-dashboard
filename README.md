# Knit-I Work Order System — deployment

## Files (all go in the repo root, served by GitHub Pages)
- `index.html` — office dashboard (login here first)
- `work_order.html` — engineer PWA
- `mill-updates.html` — mill-wise updates (machines, pain points, requirements, to-dos, visit logs)
- `production.html` — production & dispatch (plans, BOM, shortages, courier tracking)

Supabase URL + anon key are baked in; localStorage settings override them if present.

## SQL — run in Supabase SQL Editor, in this order
1. `supabase-setup.sql` — orders/assignments + photos bucket *(already applied — "policy already exists" errors mean skip)*
2. `auth-and-roles.sql` — profiles + roles *(already applied — skip if it errors)*
3. `permissions-v2.sql` *(already applied — skip if it errors)*
4. `mill-updates-schema.sql` — mills, machines, mill_updates
5. `mill-updates-v2.sql` — Knit-I machine config columns + production_dispatch table
6. `mill-updates-v3.sql` — multi-contact support on mills (contacts jsonb)
7. `mill-updates-v4.sql` — To-Do comments thread, progress %, bottleneck flag
8. `schedule-v5.sql` — scheduling upgrade: start/end dates, order numbers (IN/SE/PM/RN-YYMM-###), tickets, production link
9. `machines-dedupe-v6.sql` — removes duplicate machines (same Tailscale IP) and blocks future duplicates  ← **run this now**

## Deploy
Copy all files to the repo root, commit, push. GitHub Pages serves from root.

## Importing your existing data
On the Mills page click **Download Import Template** → fill the two sheets ("Mills & Machines" with all Knit-I fields, "Updates" for pain points/requirements/etc.) → **Import from Excel**. Any other Excel also works via column-mapping (basic fields only).
