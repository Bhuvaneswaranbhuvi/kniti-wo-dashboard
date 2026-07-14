# Knit-I Work Order — Supabase Setup

No server to run, no hosting bill, nothing that can go down because a home PC
lost power. Everything lives in Supabase (free) and a static dashboard page
you can host anywhere free (GitHub Pages, or just open it locally).

- **Storage**: Supabase's free Postgres (500MB) — same SQL database engine you
  already know, just managed for you
- **Photos**: Supabase Storage (1GB free) — real files with real URLs, not
  base64 stuffed into JSON, at full original quality
- **Login & roles**: real accounts (Supabase Auth) with three roles — **admin**,
  **engineer**, **service coordinator**. Anyone can sign up; an admin promotes
  people to the right role from the dashboard's Admin tab
- **Dashboard**: `public/index.html` — a single static file, no server needed.
  Three tabs: **Submitted Orders**, **Assignments (Scheduling)**, **Admin**
  (admin-only)
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

## 3. Add login & roles

1. **New Query** again → paste in the entire contents of `auth-and-roles.sql`
   → **Run**.
2. This adds real accounts with three roles (admin, engineer, coordinator),
   and locks orders/assignments down to signed-in users only.
3. **Recommended for an internal tool**: Supabase requires email confirmation
   by default before a new account can sign in. Turn this off so accounts work
   immediately: **Authentication → Providers → Email** → toggle off
   **Confirm email**. (Leave it on instead if you'd rather each person click a
   confirmation link the first time.)

## 4. Lock down editing and assignment creation

**New Query** once more → paste in the entire contents of `permissions-v2.sql`
→ **Run**. This adds:
- Once an order is submitted, only admins can edit or delete it — engineers
  can no longer change a record after a customer has signed off
- Only admins and service coordinators can create or cancel assignments
  (schedule work). Engineers can still see their own assigned work and mark it
  complete when they submit — that's not affected.

## 5. Get your credentials

Go to **Project Settings → API**. You need two things:
- **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
- **anon / public key** — a long string starting with `eyJ...`

(There's also a `service_role` key on that page — **never use that one** in
`work_order.html` or the dashboard. It bypasses all the access rules the SQL
scripts just set up. The `anon` key is the one designed to be used directly
from apps and browsers.)

## 6. Create the first admin (important — do this before anyone else signs up)

Every new signup defaults to "engineer." Since nobody starts out as admin,
someone has to be promoted manually the very first time, or there'd be no way
to ever reach the Admin tab.

1. Open `work_order.html` (or the dashboard) → **Create an Account** → sign up
   with your own email and password.
2. In Supabase → **SQL Editor** → **New Query**, run:
   ```sql
   update profiles set role = 'admin' where email = 'your-email@counton.ai';
   ```
   (use the email you just signed up with)
3. Sign out and back in (or just reload) — you're now an admin, and the Admin
   tab in the dashboard will show every user with a role dropdown. From here
   on, promoting anyone else to admin or coordinator is just a dropdown + Save
   — no more SQL needed.

## 7. Everyone else signs up

Each of your 8 engineers, the coordinator, and any test accounts:
1. Open `work_order.html` → **Create an Account** → name, email, password.
2. They land as "engineer" by default.
3. You (the admin) go to the dashboard's **Admin** tab and change their role
   to **Service Coordinator** or leave as **Engineer** as appropriate. Role
   changes now require you to re-enter your own password to confirm it's
   really you before it takes effect.

A "test account" is nothing special — just sign up with any spare email (e.g.
`test@counton.ai`) and set whatever role you want to test with from the Admin
tab.

## 8. Configure `work_order.html` and the dashboard

**Option A — one-time setup per device (what happens by default):**
Each person opens the file → enters the Supabase URL + anon key once → signs
in. Remembered on that device from then on.

**Option B — nobody has to type anything in (recommended):**
Near the top of both `work_order.html` and `public/index.html` there's a
clearly marked block:
```js
const DEFAULT_SUPABASE_URL = '';
const DEFAULT_SUPABASE_KEY = '';
```
Fill these in once with your real values, then redistribute the file to the
team (re-share `work_order.html`, re-push the dashboard to GitHub). Everyone
who opens the updated file skips the connection step entirely and goes
straight to Sign In / Create Account.

**If the URL or key ever changes**: update those two lines and redistribute
again. There's no way for this to update live on everyone's device without a
redistribution step — the app needs to know where to even ask for updates
before it can ask anywhere, so this one requires you to push the change out.

To host the dashboard so it's reachable without sending the file around:
1. Push this folder to a GitHub repo (public is fine — the anon key is meant
   to be seen in client code; see the note in `supabase-setup.sql`. Real
   protection comes from the RLS policies and login, not from hiding this key).
2. Repo → **Settings → Pages** → Source: deploy from the `main` branch, folder
   `/public` (or move `index.html` to the repo root, either works).
3. GitHub gives you a URL like `https://<you>.github.io/<repo>/` — that's your
   permanent dashboard link.

`index.html` is fully self-contained — it doesn't need `work_order.html` to
be present or co-located to work. Deploy just the `public/` folder for the
dashboard; keep `work_order.html` wherever's convenient for distributing to
engineers' phones separately.

## 9. Creating orders directly from the dashboard

The dashboard's **+ New Order** tab contains the exact same wizard as
`work_order.html` — Job Details, photos, machines, signatures, everything —
but it's built directly into `index.html` itself now, not loaded from a
separate file. There's no iframe, no external page reference; it's genuinely
one page, same as every other tab (Submitted Orders, Schedule, Assignments,
Admin).

`work_order.html` still exists as its own standalone file at the root of this
folder — that's what stays on engineers' phones for field use, unchanged.
The dashboard's copy is a separate, independent copy of the same tool for
anyone who'd rather work from a browser/desktop. If you ever update one, the
other won't automatically follow — they're two copies of the same code, not
one shared source, so keep that in mind if the wizard itself needs changes
down the line.

Logging into the dashboard also logs you into its embedded "+ New Order" tab
automatically (same shared session, same storage keys) — no double login.

## 10. Scheduling work for engineers ahead of time

Only **admins and service coordinators** see the Assignments tab — engineers
don't, and can't create assignments even by calling the API directly (locked
down at the database level, not just hidden in the UI).

From the dashboard's **Assignments** tab: fill in the engineer's name (must
match exactly what they signed up with / what shows as their profile name),
customer, location, date, and notes → **Schedule Order**.

The engineer opens `work_order.html` → **📋 My Assigned Orders** → sees
everything scheduled for them → taps one → Job Details is pre-filled → they
complete the rest on-site. Submitting flips the assignment to "Completed"
automatically.

## 11. Downloading completed orders — anytime, from the dashboard

Open any order in **Submitted Orders**, and you'll see three buttons:
**⬇️ Download PDF**, **⬇️ Download HTML**, and **🖨️ Print** — no need to be the
engineer who filled it out, and no need to catch it right when it's submitted.
Any admin, coordinator, or engineer with dashboard access can pull a full
report for any order, whenever it's needed.

## 12. Engineer Performance & Parts Analytics (Admin tab)

Below the user list in the **Admin** tab, two more sections build themselves
automatically from submitted orders — no extra setup needed:

- **Engineer Performance**: orders completed, average CSAT rating, number of
  distinct mills attended, machines installed, and distinct machine
  models/types experienced — one row per engineer.
- **Parts Failure Analytics**: every part recorded in a service order's Parts
  Used section, ranked by how often it's been replaced (a practical proxy for
  "which parts fail most"), with which engineers and machines were involved —
  plus a breakdown of total parts used per engineer.

Both read directly from the same `orders` table, so they're always current —
nothing to refresh or recalculate manually.

## 13. Auto-filling service calls from installation records

When an engineer starts a **Service / Repair** order and enters the customer
name, a **"🔍 Look up installation record"** button appears. It searches past
**Installation Orders** for that customer, lists the machines found, and — if
they pick one — pulls in its specs (brand, model, serial, cabinet info, gauge,
diameter) as a reference card. No more retyping specs that were already
recorded when the machine went in; the details also flow into the final
report and PDF.

## Notes & limitations (so there are no surprises)

- **"Parts failure" is a proxy, not a tracked field.** There's no explicit
  "this part failed" checkbox — the analytics assume a part appearing in a
  service order's Parts Used section means it was replaced (usually true, but
  worth knowing it's inferred, not a separate data point).
- **Password re-confirmation for role changes** re-authenticates the currently
  logged-in admin (checks their password against Supabase directly) before
  applying any role change — it doesn't require the *other* person's password,
  just the admin's, to guard against someone else using an unlocked session.
- **Nobody can create accounts on someone else's behalf from the app** — not
  even admins. That would require Supabase's `service_role` key in client
  code, which must never happen (it bypasses every rule above). Self-signup +
  admin-promotes-role is the secure way to do this without a backend server.
- **Engineer name matching is a simple text match.** Keep spelling consistent
  between your profile name and what's typed when scheduling, or an assignment
  won't show up for the right person.
- **Free tier limits**: 500MB database, 1GB file storage, project pauses after
  ~1 week with zero API activity (one click to resume — daily use means this
  basically never triggers). Supabase's paid plan (~$25/month) lifts all of
  these if you outgrow them.
- **Photo uploads are the one part I couldn't test locally** — Supabase
  Storage's upload API isn't part of the open-source tools available in my
  environment (unlike the database and login logic, which I verified against
  a real Postgres + PostgREST instance with actual signed JWTs). Test
  submitting one order with a photo early and flag it if the upload step needs
  adjusting.
- **Backups**: Supabase's paid tier includes automatic daily backups; the free
  tier doesn't. Worth checking their current backup policy before this becomes
  your only copy of real business data.
