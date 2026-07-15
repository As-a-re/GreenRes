# GreenRes Ecosystem

A Flutter mobile app + Express/Supabase backend for Africa's climate action,
resilience, learning, employment, and circular-economy super app.

This is a two-part project:

- **`/` (this Flutter app)** — the mobile frontend, talking to the backend
  over HTTP via `lib/services/backend_api.dart`.
- **`/backend`** — an Express + TypeScript API backed by Supabase
  (Postgres + Auth), documented in `backend/README.md`.

## Running it

**1. Stand up the backend first** (the app can't do anything useful without it):

```bash
cd backend
npm install
cp .env.example .env
# fill in SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
```

Then run `backend/supabase/schema.sql` against your Supabase project (SQL
Editor, or `psql`/`supabase db push` if you use the CLI) — this creates
every table, view, and RLS policy the API depends on.

```bash
npm run dev
```

**2. Run the Flutter app:**

```bash
flutter pub get
flutter run --dart-define=GREENRES_API_BASE_URL=http://localhost:4000/api/v1
```

If you're on a physical device or emulator, `localhost` won't reach your
computer — use your machine's LAN IP, or `10.0.2.2` for the Android
emulator, instead. If the app can't reach the backend at launch, it shows a
**Setup screen** with the exact URL it's configured for and next steps,
instead of failing silently.

android/ and ios/ platform folders aren't included in this package (to keep
it small) — run `flutter create .` in this folder once to regenerate them
before your first build.

## What changed in this pass

This project came in with a real backend and about 16 of its 34 screens
already wired to it — but the wiring had several bugs, and the other ~18
screens were still on the placeholder/mockup data from an earlier design
pass. This pass:

**Fixed real bugs:**
- Sessions were never persisted — every restart logged you out. Now backed
  by `shared_preferences`.
- Settings' logout button called an uninitialized Supabase client directly
  and would have crashed; it now clears the session the same way the rest
  of the app does.
- `hero_challenges_screen.dart` had a leftover syntax error (dangling
  brackets) that would have failed to compile.
- Several screens read field names that don't exist on the real API
  response (e.g. marketplace `seller`/`price` instead of
  `seller_display_name`/`price`+`currency`; grants' `raised`/`goal`
  instead of `raised_amount`/`goal_amount`) — these always silently showed
  `0`/fallback values.
- `message_threads_view` filtered on a column that doesn't exist and
  always resolved the wrong "other user" — fixed both the view and the
  query.
- `PATCH /profiles/me` overwrote every field with `null` on every partial
  update, silently wiping data — now merges with the existing row.
- The verification → rewards pipeline was completely disconnected:
  submitting evidence created a row but never verified an action or
  awarded credits, and wallets were never created so first-time
  redemptions always failed. Both are now wired end-to-end (see
  `backend/README.md` → Known gaps for the honest limits of that
  wiring).

**Wired the remaining screens to real data**, removing every hardcoded
name, number, and demo string in the process — Carbon Bank, Carbon Map,
Climate Coach, Climate SOS, Checkout, GreenLens AR, Hero Challenges,
Messaging (+ a new inbox screen), Verification, AgriShield, Admin
Dashboard, Offline Guides, and the leftover static bits of Home Dashboard,
Tree Guardian, Wallet, Impact Passport, and Learning Academy.

**Removed `lib/models/mock_models.dart` entirely** — it was dead code, no
longer imported anywhere.

See `backend/README.md` → **Known gaps** for what's honestly still
incomplete (file uploads, a real map SDK, an admin role system, hyperlocal
weather) rather than faked.
