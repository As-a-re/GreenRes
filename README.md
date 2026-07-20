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
before your first build. After that, add these permissions and AR
requirements:

**`android/app/src/main/AndroidManifest.xml`** — inside `<manifest>`, before `<application>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera.ar" android:required="false" />
```
Inside `<application>`, add (required for ARCore/GreenLens AR):
```xml
<meta-data android:name="com.google.ar.core" android:value="optional" />
```
Use `android:value="required"` instead if you want to restrict installs to
AR-capable devices only; `optional` lets the app install everywhere and
GreenLens AR shows the in-app "AR isn't available" fallback screen on
devices without ARCore. Also bump `minSdkVersion` to at least 24 in
`android/app/build.gradle` (ARCore's minimum).

**`ios/Runner/Info.plist`** — inside the outer `<dict>`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>GreenRes uses your microphone for voice commands so blind and low-vision users can navigate the app by speaking.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>GreenRes converts your speech to text to understand voice commands.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>GreenRes uses your location to show live weather and nearby climate alerts for exactly where you are.</string>
<key>NSCameraUsageDescription</key>
<string>GreenRes uses your camera for GreenLens AR, to project climate risk data onto real-world surfaces.</string>
```
Also set the iOS deployment target to 13.0+ in `ios/Podfile` (ARKit + the
AR plugin's minimum).

**GreenLens AR only works on a physical device** — ARCore/ARKit don't run
in the iOS Simulator or most Android emulators. Test it on real hardware.

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
- Four Postgres views (`weekly_coach_summary_view`, `ar_projections_view`,
  `message_threads_view`, `carbon_projects_view`) failed to apply with
  `cannot change name of view column` — `CREATE OR REPLACE VIEW` can't
  rename or reorder columns. Fixed with explicit `DROP VIEW ... CASCADE`
  before each in `schema.sql`, plus a standalone
  `backend/supabase/patch_view_column_rename.sql` for anyone who already
  has a partially-applied database.

**Wired the remaining screens to real data**, removing every hardcoded
name, number, and demo string in the process — Carbon Bank, Carbon Map,
Climate Coach, Climate SOS, Checkout, GreenLens AR, Hero Challenges,
Messaging (+ a new inbox screen), Verification, AgriShield, Admin
Dashboard, Offline Guides, and the leftover static bits of Home Dashboard,
Tree Guardian, Wallet, Impact Passport, and Learning Academy.

**Removed `lib/models/mock_models.dart` entirely** — it was dead code, no
longer imported anywhere.

**Added this pass:**
- **Voice assistant** (`lib/services/voice_assistant_service.dart`) — speaks
  a welcome/orientation message when the app opens, and takes real spoken
  voice commands ("home", "market", "wallet", "weather", "carbon",
  "settings", "explore", "log out", "emergency", "help", "read screen") to
  navigate the entire app hands-free, for blind/low-vision users. Added
  `Semantics` labels to the bottom nav and SOS button for screen-reader
  support too.
- **Twi (Akan) localization** (`lib/localization/localization_service.dart`)
  — real infrastructure with genuine Twi translations for navigation and
  voice assistant content, opt-in via Settings. See Known Gaps in
  `backend/README.md` for the honest caveats on translation review and
  device TTS voice availability.
- **Local Climate Center** (`local_climate_screen.dart`) — real GPS
  location, live hyperlocal weather (Open-Meteo), real nearby climate
  alerts within 50km, and an AI Climate Coach briefing (Claude-generated if
  you set `ANTHROPIC_API_KEY`, rules-based otherwise) — all from real data,
  reachable from Home and the Explore hub.
- **Carbon Footprint Tracker** (`carbon_tracker_screen.dart`) — transparent,
  factor-based CO₂ estimates from manually logged expenses, with the full
  emission-factor table exposed via the API.

**Added this pass — GreenLens AR and native-quality Twi:**

- **GreenLens AR is now real ARCore/ARKit AR**, not a fake camera-less
  gradient. Rewritten on `ar_flutter_plugin` with genuine horizontal-plane
  detection: tap a real detected surface and a 3D marker (color-coded by
  live alert severity from `/ar/projections`) gets anchored there in
  world space via `ARAnchorManager`. Three marker assets
  (`assets/ar/marker_{low,moderate,high}.gltf`) were hand-generated as
  valid glTF 2.0 files (checked in this pass — buffer lengths, byte
  alignment, and JSON structure all validated).

  **Important caveat:** this code was written against `ar_flutter_plugin`'s
  documented API without the ability to compile or run it — Flutter AR
  needs a native Android/iOS toolchain and a physical ARCore/ARKit device,
  neither of which exist in the environment this was built in. The four
  spots most likely to need a small fix on your first build are marked
  `// VERIFY` in `lib/screens/greenlens_ar_screen.dart` with exactly what
  to check. This is a materially different confidence level than the rest
  of this codebase, where full structural verification was possible.
  GreenLens AR also only works on physical devices, not simulators/most
  emulators.

- **Twi now routes through a real Twi-specific TTS model** (GhanaNLP's
  Khaya AI, `translation.ghananlp.org`) via a new backend proxy
  (`POST /voice/twi-tts`), instead of the device's generic TTS engine
  guessing at pronunciation. This is the honest path to "sounds like a
  native speaker" — no major TTS provider (Google, Amazon, Azure,
  ElevenLabs) supports Twi/Akan at all, so a Ghana-specific model is
  actually the only credible option, not a corner cut. Requires signing up
  at translation.ghananlp.org and setting `KHAYA_API_KEY` in the backend's
  `.env` — without it, `/voice/twi-tts` returns 503 and the app
  transparently falls back to device TTS (which will likely mispronounce
  Twi, as before). The exact request shape was reconstructed from public
  docs since Khaya AI's full interactive reference needs a signed-in
  session to view — verify against your account dashboard if the first
  call 404s or 401s (see the comment in `backend/src/routes/voice.ts`).

See `backend/README.md` → **Known gaps** for what's honestly still
incomplete (file uploads, a real map SDK, an admin role system,
bank/OCR integration, full-app translation, native-speaker review of the
Twi text itself) rather than faked.
