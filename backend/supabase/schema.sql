create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique,
  display_name text not null,
  avatar_url text,
  bio text,
  location text,
  organization text,
  interests text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.climate_actions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  action_type text not null,
  title text not null,
  evidence_url text,
  metadata jsonb not null default '{}'::jsonb,
  impact_score numeric(10, 2) not null default 0,
  carbon_saved_kg numeric(10, 2) not null default 0,
  community_score numeric(10, 2) not null default 0,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  category text not null,
  price numeric(12, 2) not null default 0,
  currency text not null default 'USD',
  media_urls text[] not null default '{}'::text[],
  is_verified boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.impact_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  period_start date not null,
  period_end date not null,
  trees_planted integer not null default 0,
  waste_collected_kg numeric(10, 2) not null default 0,
  carbon_saved_kg numeric(10, 2) not null default 0,
  volunteer_hours numeric(10, 2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.learning_courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  summary text,
  category text not null,
  duration_minutes integer not null default 0,
  xp_reward integer not null default 0,
  certificate_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learning_progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  course_id uuid not null references public.learning_courses (id) on delete cascade,
  progress_percent numeric(5, 2) not null default 0,
  completed boolean not null default false,
  quiz_score numeric(5, 2),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, course_id)
);

create table if not exists public.reward_wallets (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  credits_balance integer not null default 0,
  lifetime_credits integer not null default 0,
  tier_name text not null default 'starter',
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  reward_type text not null,
  credits_spent integer not null,
  metadata jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.climate_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  alert_type text not null,
  title text not null,
  message text not null,
  severity text not null default 'medium',
  location_label text,
  latitude double precision,
  longitude double precision,
  is_public boolean not null default false,
  resolved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  action text not null,
  media_url text,
  visibility text not null default 'public',
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now()
);

create or replace view public.community_posts_view as
select p.*, pr.display_name, pr.avatar_url
from public.community_posts p
join public.profiles pr on pr.id = p.user_id;

create table if not exists public.climate_clubs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  category text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.climate_club_members (
  club_id uuid not null references public.climate_clubs (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

create table if not exists public.job_listings (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  organization text not null,
  job_type text not null,
  location text not null,
  match_score numeric(4, 2) not null default 0,
  created_at timestamptz not null default now()
);

create or replace view public.job_listings_view as
select * from public.job_listings;

create table if not exists public.tree_registry (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  species text not null,
  tree_id text not null unique,
  planted_at timestamptz,
  location_label text,
  health numeric(4, 2) not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.micro_grants (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text not null,
  goal_amount numeric(12, 2) not null,
  raised_amount numeric(12, 2) not null default 0,
  votes integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  provider text not null,
  amount numeric(12, 2) not null,
  purpose text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists public.offline_guides (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  priority integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.verification_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  action_type text not null,
  title text not null,
  evidence_url text,
  latitude double precision,
  longitude double precision,
  confidence numeric(5, 2) not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists public.marketplace_threads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings (id) on delete cascade,
  participant_a uuid not null references public.profiles (id) on delete cascade,
  participant_b uuid not null references public.profiles (id) on delete cascade,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.marketplace_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.marketplace_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create or replace view public.message_threads_view as
select
  mt.id,
  mt.listing_id,
  mt.participant_a,
  mt.participant_b,
  mt.updated_at,
  mt.created_at,
  p.display_name as other_user_name
from public.marketplace_threads mt
join public.profiles p on p.id = mt.participant_b;

create or replace view public.carbon_projects_view as
select mg.id, mg.title, mg.description, mg.goal_amount, mg.raised_amount, mg.votes, mg.created_at
from public.micro_grants mg;

create or replace view public.weekly_coach_summary_view as
select
  p.id as user_id,
  'You prevented impact this week'::text as impact_text,
  3::int as recommended_goal,
  'Plastic-Free Week'::text as next_challenge
from public.profiles p;

create or replace view public.ar_projections_view as
select 'Flood levels'::text as mode, 0.62::numeric as level;

create or replace view public.impact_summary_view as
select
  coalesce(sum(impact_score), 0) as impact_score,
  coalesce(sum(carbon_saved_kg), 0) as carbon_saved_kg,
  coalesce(sum(community_score), 0) as community_score,
  coalesce(count(*) filter (where action_type = 'tree_planting'), 0) as trees_planted,
  coalesce(count(*) filter (where action_type = 'recycling'), 0) as recycling_actions,
  coalesce(count(*) filter (where verified), 0) as verified_actions
from public.climate_actions;

alter table public.profiles enable row level security;
alter table public.climate_actions enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.impact_reports enable row level security;
alter table public.learning_courses enable row level security;
alter table public.learning_progress enable row level security;
alter table public.reward_wallets enable row level security;
alter table public.reward_redemptions enable row level security;
alter table public.climate_alerts enable row level security;
alter table public.community_posts enable row level security;
alter table public.climate_clubs enable row level security;
alter table public.climate_club_members enable row level security;
alter table public.job_listings enable row level security;
alter table public.tree_registry enable row level security;
alter table public.micro_grants enable row level security;
alter table public.payment_intents enable row level security;
alter table public.offline_guides enable row level security;
alter table public.verification_submissions enable row level security;
alter table public.marketplace_threads enable row level security;
alter table public.marketplace_messages enable row level security;

drop policy if exists "Profiles are self-managed" on public.profiles;
create policy "Profiles are self-managed"
  on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Actions are self-managed" on public.climate_actions;
create policy "Actions are self-managed"
  on public.climate_actions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Listings are public read" on public.marketplace_listings;
create policy "Listings are public read"
  on public.marketplace_listings
  for select
  using (true);

drop policy if exists "Listings are seller managed" on public.marketplace_listings;
create policy "Listings are seller managed"
  on public.marketplace_listings
  for all
  using (auth.uid() = seller_id)
  with check (auth.uid() = seller_id);

drop policy if exists "Reports are self-managed" on public.impact_reports;
create policy "Reports are self-managed"
  on public.impact_reports
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Courses are public read" on public.learning_courses;
create policy "Courses are public read"
  on public.learning_courses
  for select
  using (true);

drop policy if exists "Progress is self-managed" on public.learning_progress;
create policy "Progress is self-managed"
  on public.learning_progress
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Wallet is self-managed" on public.reward_wallets;
create policy "Wallet is self-managed"
  on public.reward_wallets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Redemptions are self-managed" on public.reward_redemptions;
create policy "Redemptions are self-managed"
  on public.reward_redemptions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Alerts are self-managed or public" on public.climate_alerts;
create policy "Alerts are self-managed or public"
  on public.climate_alerts
  for select
  using (auth.uid() = user_id or is_public = true);

drop policy if exists "Alerts are self-managed write" on public.climate_alerts;
create policy "Alerts are self-managed write"
  on public.climate_alerts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Posts are visible" on public.community_posts;
create policy "Posts are visible"
  on public.community_posts
  for select
  using (true);

drop policy if exists "Posts are self-managed" on public.community_posts;
create policy "Posts are self-managed"
  on public.community_posts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Clubs are visible" on public.climate_clubs;
create policy "Clubs are visible"
  on public.climate_clubs
  for select
  using (true);

drop policy if exists "Clubs are owner managed" on public.climate_clubs;
create policy "Clubs are owner managed"
  on public.climate_clubs
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "Members are self-managed" on public.climate_club_members;
create policy "Members are self-managed"
  on public.climate_club_members
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Jobs are public" on public.job_listings;
create policy "Jobs are public"
  on public.job_listings
  for select
  using (true);

drop policy if exists "Trees are self-managed" on public.tree_registry;
create policy "Trees are self-managed"
  on public.tree_registry
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Grants are visible" on public.micro_grants;
create policy "Grants are visible"
  on public.micro_grants
  for select
  using (true);

drop policy if exists "Grants are owner managed" on public.micro_grants;
create policy "Grants are owner managed"
  on public.micro_grants
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "Payment intents are self-managed" on public.payment_intents;
create policy "Payment intents are self-managed"
  on public.payment_intents
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Offline guides are public" on public.offline_guides;
create policy "Offline guides are public"
  on public.offline_guides
  for select
  using (true);

drop policy if exists "Verification submissions are self-managed" on public.verification_submissions;
create policy "Verification submissions are self-managed"
  on public.verification_submissions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Threads are self-managed" on public.marketplace_threads;
create policy "Threads are self-managed"
  on public.marketplace_threads
  for all
  using (auth.uid() = participant_a or auth.uid() = participant_b)
  with check (auth.uid() = participant_a or auth.uid() = participant_b);

drop policy if exists "Messages are self-managed" on public.marketplace_messages;
create policy "Messages are self-managed"
  on public.marketplace_messages
  for all
  using (
    auth.uid() in (
      select participant_a from public.marketplace_threads where id = thread_id
      union
      select participant_b from public.marketplace_threads where id = thread_id
    )
  )
  with check (
    auth.uid() in (
      select participant_a from public.marketplace_threads where id = thread_id
      union
      select participant_b from public.marketplace_threads where id = thread_id
    )
  );
-- ---------------------------------------------------------------------------
-- Extensions added for Hero Challenges, marketplace seller display names,
-- and turning the previously-stubbed coach/AR views into real computed data.
-- ---------------------------------------------------------------------------

create table if not exists public.climate_challenges (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles (id) on delete set null,
  title text not null,
  description text,
  reward_credits integer not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.climate_challenge_participants (
  challenge_id uuid not null references public.climate_challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

create or replace view public.climate_challenges_view as
select
  c.id,
  c.owner_id,
  c.title,
  c.description,
  c.reward_credits,
  c.starts_at,
  c.ends_at,
  c.created_at,
  coalesce(count(p.user_id), 0)::int as participant_count,
  greatest(0, ceil(extract(epoch from (c.ends_at - now())) / 86400))::int as days_left
from public.climate_challenges c
left join public.climate_challenge_participants p on p.challenge_id = c.id
group by c.id;

alter table public.climate_challenges enable row level security;
alter table public.climate_challenge_participants enable row level security;

drop policy if exists "Challenges are visible" on public.climate_challenges;
create policy "Challenges are visible"
  on public.climate_challenges
  for select
  using (true);

drop policy if exists "Challenges are owner managed" on public.climate_challenges;
create policy "Challenges are owner managed"
  on public.climate_challenges
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "Challenge participation is self-managed" on public.climate_challenge_participants;
create policy "Challenge participation is self-managed"
  on public.climate_challenge_participants
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Marketplace listings joined with seller display name, so the client never
-- has to fetch profiles separately just to show who's selling something.
create or replace view public.marketplace_listings_view as
select l.*, pr.display_name as seller_display_name
from public.marketplace_listings l
join public.profiles pr on pr.id = l.seller_id;

-- Replaces the earlier stub (a single hardcoded row) with a real per-user
-- rollup of the last 7 days of activity.
create or replace view public.weekly_coach_summary_view as
select
  p.id as user_id,
  coalesce(sum(a.carbon_saved_kg) filter (
    where a.created_at > now() - interval '7 days'), 0) as carbon_saved_7d,
  coalesce(count(a.id) filter (
    where a.created_at > now() - interval '7 days'), 0)::int as actions_7d,
  case
    when coalesce(count(a.id) filter (
      where a.created_at > now() - interval '7 days'), 0) >= 5 then 5
    else 3
  end as recommended_goal,
  coalesce(
    (select title from public.climate_challenges c
     where c.ends_at > now()
     order by c.starts_at desc
     limit 1),
    'No active challenge right now'
  ) as next_challenge
from public.profiles p
left join public.climate_actions a on a.user_id = p.id
group by p.id;

-- Replaces the earlier stub (a single hardcoded row) with real counts
-- derived from currently-unresolved alerts, grouped by type.
create or replace view public.ar_projections_view as
select
  alert_type as mode,
  count(*)::int as active_alerts,
  round(avg(case severity
    when 'critical' then 1.0
    when 'high' then 0.75
    when 'medium' then 0.5
    else 0.25
  end)::numeric, 2) as level
from public.climate_alerts
where resolved = false
group by alert_type;

-- Climate clubs joined with a real member count, so the client isn't
-- guessing at membership numbers.
create or replace view public.climate_clubs_view as
select
  c.id,
  c.owner_id,
  c.name,
  c.category,
  c.description,
  c.created_at,
  coalesce(count(m.user_id), 0)::int as members_count
from public.climate_clubs c
left join public.climate_club_members m on m.club_id = c.id
group by c.id;

-- Fixes message_threads_view: the original version only ever joined
-- participant_b's profile (wrong "other user" when the viewer *is*
-- participant_b) and had no column the API could filter on for
-- "threads I'm part of". This version returns both participant names and
-- ids so the API can resolve the correct "other user" per viewer.
create or replace view public.message_threads_view as
select
  mt.id,
  mt.listing_id,
  mt.participant_a,
  mt.participant_b,
  mt.updated_at,
  mt.created_at,
  pa.display_name as participant_a_name,
  pb.display_name as participant_b_name,
  l.title as listing_title
from public.marketplace_threads mt
join public.profiles pa on pa.id = mt.participant_a
join public.profiles pb on pb.id = mt.participant_b
left join public.marketplace_listings l on l.id = mt.listing_id;

-- One-vote-per-user tracking for micro-grant projects, plus a view that
-- exposes a real vote count (the earlier "votes" column on micro_grants
-- was a manually-incremented integer with no per-user tracking; this
-- replaces the writable column with a derived count so nobody can vote
-- twice).
create table if not exists public.micro_grant_votes (
  grant_id uuid not null references public.micro_grants (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (grant_id, user_id)
);

alter table public.micro_grant_votes enable row level security;

drop policy if exists "Grant votes are visible" on public.micro_grant_votes;
create policy "Grant votes are visible"
  on public.micro_grant_votes
  for select
  using (true);

drop policy if exists "Grant votes are self-managed" on public.micro_grant_votes;
create policy "Grant votes are self-managed"
  on public.micro_grant_votes
  for insert
  with check (auth.uid() = user_id);

create or replace view public.micro_grants_view as
select
  g.id,
  g.owner_id,
  g.title,
  g.description,
  g.goal_amount,
  g.raised_amount,
  g.created_at,
  coalesce(count(v.user_id), 0)::int as votes
from public.micro_grants g
left join public.micro_grant_votes v on v.grant_id = g.id
group by g.id;

-- carbon_projects_view previously read mg.votes directly, but that column
-- was never incremented anywhere. Point it at the same real, per-user vote
-- count that micro_grants_view now uses.
create or replace view public.carbon_projects_view as
select
  mg.id,
  mg.title,
  mg.description,
  mg.goal_amount,
  mg.raised_amount,
  mg.created_at,
  coalesce(count(v.user_id), 0)::int as votes
from public.micro_grants mg
left join public.micro_grant_votes v on v.grant_id = mg.id
group by mg.id;
