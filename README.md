# kniti-wo-backend

## Deploy
1. Copy every file in this folder into your repo root (`~/Music/kniti-wo-backend`), replacing the old ones.
2. `git add . && git commit -m "Add mill-updates page" && git push`
3. GitHub Pages serves from `/` root — no folder changes needed.

## Database — run these in Supabase SQL Editor, in this exact order
1. `supabase-setup.sql` — base tables (orders, assignments) + photos bucket *(skip if already run)*
2. `auth-and-roles.sql` — login + roles *(skip if already run)*
3. `permissions-v2.sql` — locking + assignment permissions *(skip if already run)*
4. `mill-updates-schema.sql` — **new**: mills, machines, mill_updates tables

If steps 1–3 were already run on this Supabase project earlier, just run step 4.

## Files
- `index.html` — office dashboard (Submitted Orders, Schedule, Assignments, Admin, and the new 🏭 Mills tab)
- `work_order.html` — field engineer PWA
- `mill-updates.html` — mill-wise page: to-dos, pain points, engineer suggestions, customer requirements, visit logs, work-order summary, machines, Excel import/export
- `*.sql` — run once each, in order above

Supabase URL and anon key are already baked into all three HTML files (project: `ipvgfjkyykhozomwwrfj`) — no per-device setup needed, just sign in.
