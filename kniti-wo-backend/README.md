# Knit-I Work Order — Supabase Setup

No server to run, no hosting bill, nothing that can go down because a home PC
lost power. Everything lives in Supabase (free) and a static dashboard page
you can host anywhere free (GitHub Pages, or just open it locally).

- **Storage**: Supabase's free Postgres (500MB) — same SQL database engine you
  already know, just managed for you
- **Photos**: Supabase Storage (1GB free) — real files with real URLs, not
  base64 stuffed into JSON, at full original quality
- **Dashboard**: `public/index.html` — a single static file, no server needed.
  Two tabs: **Submitted Orders** and **Assignments (Scheduling)**
- **`work_order.html`**: talks to Supabase directly — no backend code in the
  middle to maintain at all
- **Survives dropped connections**: if an engineer's phone can't reach Supabase
  when they hit Submit, the app queues the order on the device and retries
  automatically once back online

## 1. Create your Supabase project

1. Go to [supabase.com](https://supabase.com) → sign up (free) → **New Project**.
2. Pick a name, set a database password (save it somewhere — you likely won't
   need it day-to-day, but keep it safe), pick a region close to India (e.g.
   Singapore), and create the project. Takes about 2 minutes to provision.

## 2. Set up the database

1. In your project, open **SQL Editor** → **New Query**.
2. Paste in the entire contents of `supabase-setup.sql` (included in this
   folder) and click **Run**.
3. That's it — this creates both tables, opens them up for the app to use, and
   sets up a public storage bucket for photos and signatures.

## 3. Get your credentials

Go to **Project Settings → API**. You need two things:
- **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
- **anon / public key** — a long string starting with `eyJ...`

(There's also a `service_role` key on that page — **never use that one** in
`work_order.html` or the dashboard. It bypasses all the access rules the SQL
script just set up. The `anon` key is the one designed to be used directly
from apps and browsers.)

## 4. Configure `work_order.html`

Open it (as an artifact or the downloaded file) → **⚙️ Settings** on the very
first screen → paste in the Project URL and anon key → enter your name → Save.
Each engineer does this once on their own phone.

## 5. Configure and host the dashboard

Open `public/index.html` (double-click it, or host it anywhere) → click
**⚙️ Connection** in the top right → paste the same Project URL and anon key →
Save & Connect.

To make it reachable by others without sending the file around:
1. Push this folder to a GitHub repo (public is fine — the anon key is meant
   to be seen in client code; see the note in `supabase-setup.sql`).
2. Repo → **Settings → Pages** → Source: deploy from the `main` branch, folder
   `/public` (or move `index.html` to the repo root, either works).
3. GitHub gives you a URL like `https://<you>.github.io/<repo>/` — that's your
   permanent dashboard link.

## 6. Scheduling work for engineers ahead of time

From the dashboard's **Assignments** tab: fill in the engineer's name (must
match exactly what they entered in their own Settings), customer, location,
date, and notes → **Schedule Order**.

The engineer opens `work_order.html` → **📋 My Assigned Orders** (only appears
once they've saved their Supabase credentials in Settings) → sees everything
scheduled for them → taps one → Job Details is pre-filled → they complete the
rest on-site. Submitting flips the assignment to "Completed" automatically.

## Notes & limitations (so there are no surprises)

- **No login/auth yet.** Anyone with the Project URL + anon key can read or
  write orders and assignments (that's what the permissive RLS policies in the
  setup script do). Fine for an internal team where everyone already has
  legitimate access to this data. Supabase Auth is the natural next step if
  you want per-engineer accounts and row-level restrictions later.
- **Engineer name matching is a simple text match.** Keep spelling consistent
  between what's typed in Settings and what's typed when scheduling, or an
  assignment won't show up for the right person.
- **Free tier limits**: 500MB database, 1GB file storage, project pauses after
  ~1 week with zero API activity (one click in the dashboard to resume — daily
  use means this basically never triggers). If you outgrow the free tier,
  Supabase's paid plan starts around $25/month and lifts all of these caps.
- **Photo uploads are the one part I couldn't test locally** — Supabase
  Storage's upload API isn't part of the open-source tools I could run in this
  environment (unlike the database queries, which I verified against a real
  Postgres + PostgREST instance). Test submitting one order with a photo early
  and let me know if the upload step needs adjusting.
- **Backups**: Supabase's paid tier includes automatic daily backups; the free
  tier doesn't. Worth checking their current backup policy before this becomes
  your only copy of real business data.
