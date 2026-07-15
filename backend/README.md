# GreenRes Backend

Express + TypeScript + Supabase backend for the GreenRes Ecosystem.

## Setup

```bash
npm install
cp .env.example .env
# Fill in SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY
# from your Supabase project's Settings -> API page, then:
npm run dev
```

Run `supabase/schema.sql` against your Supabase project (SQL Editor, or
`supabase db push` / `psql` if you use the CLI) before starting the server —
the API will fail fast on startup if the required env vars are missing, and
routes will error at request time if the tables/views in that file don't exist yet.

## Known gaps

Everything below returns real data from Supabase — there is no mock/demo
data left anywhere in the app — but a few features are intentionally
incomplete rather than faked:

- **No photo/file upload pipeline.** Verification evidence and marketplace
  images are plain URL fields; there's no Supabase Storage upload route or
  camera capture wired into the Flutter app yet.
- **No admin/reviewer role system.** `/admin/summary` reports real counts,
  but there's no `is_admin` flag, no auth gate on who can view it, and no
  moderation actions (approve/reject/ban) — anyone signed in can currently
  hit it.
- **Verification auto-approval is a simple rule, not AI.** Submissions with
  both a photo URL and coordinates are auto-approved against a fixed,
  documented per-action-type credit table (see `ACTION_POLICY` in
  `src/routes/verification.ts`). Anything else is left `pending` with no
  reviewer queue to actually act on it yet.
- **No live map SDK.** FloodWatch and the Carbon Map show real alert/impact
  data in list/stat form; the map surface itself is a static placeholder
  pending a Mapbox/Google Maps integration.
- **No hyperlocal weather integration.** AgriShield shows real
  agriculture-relevant alerts instead of a fabricated forecast, but there's
  no weather API wired in yet.
- **Marketplace reports and community flags aren't modeled.** There's no
  table for either, so the admin dashboard doesn't claim to show them.
- **True offline caching isn't implemented.** The offline guides screen
  fetches real guide content from the API; it doesn't yet cache it for
  access with zero connectivity.

## Scripts

- `npm run dev` - start the API in watch mode
- `npm run build` - compile to `dist/`
- `npm run start` - run the compiled server
- `npm run typecheck` - run the TypeScript compiler without emitting files

## API surface

- `GET /health` - service health check
- `GET /api/v1/auth/me` - return the current Supabase user
- `GET /api/v1/profiles/me` - fetch the current user profile
- `PATCH /api/v1/profiles/me` - update the current user profile
- `GET /api/v1/actions` - sample climate actions query
- `POST /api/v1/actions` - create a climate action record
- `GET /api/v1/alerts` - get public and user alerts
- `POST /api/v1/alerts` - create a climate alert report
- `GET /api/v1/admin/summary` - admin analytics summary (users, actions, alerts, grants, pending verifications, high-severity alerts, active challenges)
- `GET /api/v1/ar/projections` - GreenLens AR projections (live counts/severity by alert type)
- `GET /api/v1/carbon-bank` - community carbon projects
- `GET /api/v1/challenges` - climate hero challenges list, with participant counts
- `POST /api/v1/challenges` - create a challenge
- `POST /api/v1/challenges/:challengeId/join` - join a challenge
- `GET /api/v1/clubs` - climate clubs list
- `POST /api/v1/clubs` - create a climate club
- `POST /api/v1/clubs/:clubId/join` - join a club
- `GET /api/v1/coach/weekly` - weekly AI coach summary (real per-user rollup of the last 7 days)
- `GET /api/v1/community/feed` - community feed
- `POST /api/v1/community/feed` - create a community post
- `GET /api/v1/grants` - micro-grants list
- `POST /api/v1/grants` - submit a micro-grant project
- `POST /api/v1/grants/:grantId/vote` - vote for a micro-grant project (one vote per user)
- `GET /api/v1/jobs` - climate jobs list
- `GET /api/v1/learning/courses` - list learning courses
- `GET /api/v1/learning/progress` - fetch progress for the current user
- `POST /api/v1/learning/progress` - update progress for the current user
- `GET /api/v1/offline/guides` - offline emergency guides
- `GET /api/v1/messages/threads` - marketplace message threads
- `POST /api/v1/messages/threads` - start (or fetch existing) thread with a seller for a listing
- `GET /api/v1/messages/threads/:threadId` - thread messages
- `POST /api/v1/messages/threads/send` - send a marketplace message
- `POST /api/v1/payments/intents` - create a payment intent record
- `GET /api/v1/rewards/wallet` - fetch the current user wallet
- `GET /api/v1/rewards/redemptions` - list reward redemptions
- `POST /api/v1/rewards/redemptions` - redeem GreenRes credits
- `GET /api/v1/verification` - verification submissions
- `POST /api/v1/verification/submit` - submit evidence for verification
- `GET /api/v1/trees` - tree registry
- `POST /api/v1/trees` - register a tree
- `GET /api/v1/impact` - fetch global impact summary data
- `GET /api/v1/marketplace/listings` - active marketplace listings, with seller display name
- `GET /api/v1/marketplace/listings/:listingId` - single listing detail

## Supabase

This backend is wired to Supabase through a service client in `src/lib/supabase.ts`.
The baseline schema lives in `supabase/schema.sql` and covers profiles, climate actions,
marketplace listings, learning, rewards, alerts, community, clubs, jobs, trees, grants,
payments, verification submissions, marketplace messaging, offline guides, and impact reports with row-level security policies.

Authenticated routes expect a Supabase access token in `Authorization: Bearer <token>`.