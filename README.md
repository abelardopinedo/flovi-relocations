# Flovi Relocations

Two connected apps built for the Flovi AI Build Challenge: a **Vue dispatcher web app** for creating and managing relocation requests, and a **Flutter driver app** for browsing and booking them. Both share a single Supabase backend (auth, database, realtime).

## Live URLs

- Dispatcher app: https://dispatcher-tau.vercel.app/
- Driver app: https://driver-sigma-three.vercel.app/

## Tech stack

- Vue 3 + Vite + TypeScript + Tailwind CSS — dispatcher web app
- Flutter web — driver app
- Supabase — auth, database, realtime sync
- Vercel — hosting for both apps

## Dispatcher app

**What was built:**
- Google OAuth login
- Create, list, and edit relocation requests
- Realtime sync — changes reflect across sessions/tabs without a manual refresh

**How to run locally:**

```bash
cd dispatcher
npm install
```

Copy `.env.example` to `.env` and fill in your Supabase project's values (Supabase Dashboard → Project Settings → API):

```
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

```bash
npm run dev
```

## Database setup

- Schema lives in [`misc/supabase.sql`](misc/supabase.sql) — run it in the Supabase SQL Editor for a fresh project.
- After running it, enable **Realtime** on the `relocation_requests` table (Database → Replication) so both apps stay in sync.

## Driver app

**What was built:**
- Google OAuth login
- Browse available (open) gigs
- One-tap booking with confirmation dialog
- View booked gigs ("My Gigs")
- Realtime sync — new gigs, bookings, and cross-tab changes reflect without a manual refresh

**How to run locally:**

```bash
cd driver
flutter pub get
```

Copy `env/env.example.json` to `env/env.json` and fill in your Supabase project's values (Supabase Dashboard → Project Settings → API):

```json
{
  "SUPABASE_URL": "",
  "SUPABASE_ANON_KEY": ""
}
```

```bash
flutter build web --dart-define-from-file=env/env.json
```
