-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tables
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  location TEXT,
  organization TEXT,
  interests TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  title TEXT NOT NULL,
  evidence_url TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  impact_score NUMERIC(10, 2) NOT NULL DEFAULT 0,
  carbon_saved_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
  community_score NUMERIC(10, 2) NOT NULL DEFAULT 0,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  media_urls TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.impact_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  trees_planted INTEGER NOT NULL DEFAULT 0,
  waste_collected_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
  carbon_saved_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
  volunteer_hours NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.learning_courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  summary TEXT,
  category TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 0,
  xp_reward INTEGER NOT NULL DEFAULT 0,
  certificate_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.learning_progress (
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES public.learning_courses (id) ON DELETE CASCADE,
  progress_percent NUMERIC(5, 2) NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  quiz_score NUMERIC(5, 2),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, course_id)
);

CREATE TABLE IF NOT EXISTS public.reward_wallets (
  user_id UUID PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  credits_balance INTEGER NOT NULL DEFAULT 0,
  lifetime_credits INTEGER NOT NULL DEFAULT 0,
  tier_name TEXT NOT NULL DEFAULT 'starter',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.reward_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reward_type TEXT NOT NULL,
  credits_spent INTEGER NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'medium',
  location_label TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  media_url TEXT,
  visibility TEXT NOT NULL DEFAULT 'public',
  likes_count INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_clubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_club_members (
  club_id UUID NOT NULL REFERENCES public.climate_clubs (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (club_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.job_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  organization TEXT NOT NULL,
  job_type TEXT NOT NULL,
  location TEXT NOT NULL,
  match_score NUMERIC(4, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.tree_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  species TEXT NOT NULL,
  tree_id TEXT NOT NULL UNIQUE,
  planted_at TIMESTAMPTZ,
  location_label TEXT,
  health NUMERIC(4, 2) NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.micro_grants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  goal_amount NUMERIC(12, 2) NOT NULL,
  raised_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  votes INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payment_intents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  purpose TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.offline_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.verification_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  title TEXT NOT NULL,
  evidence_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  confidence NUMERIC(5, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.marketplace_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.marketplace_listings (id) ON DELETE CASCADE,
  participant_a UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  participant_b UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.marketplace_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.marketplace_threads (id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  reward_credits INTEGER NOT NULL DEFAULT 0,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.climate_challenge_participants (
  challenge_id UUID NOT NULL REFERENCES public.climate_challenges (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (challenge_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.micro_grant_votes (
  grant_id UUID NOT NULL REFERENCES public.micro_grants (id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (grant_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.impact_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tree_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.climate_challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_grant_votes ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Profiles are self-managed" ON public.profiles;
CREATE POLICY "Profiles are self-managed" ON public.profiles FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Actions are self-managed" ON public.climate_actions;
CREATE POLICY "Actions are self-managed" ON public.climate_actions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Listings are public read" ON public.marketplace_listings;
CREATE POLICY "Listings are public read" ON public.marketplace_listings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Listings are seller managed" ON public.marketplace_listings;
CREATE POLICY "Listings are seller managed" ON public.marketplace_listings FOR ALL USING (auth.uid() = seller_id) WITH CHECK (auth.uid() = seller_id);

DROP POLICY IF EXISTS "Reports are self-managed" ON public.impact_reports;
CREATE POLICY "Reports are self-managed" ON public.impact_reports FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Courses are public read" ON public.learning_courses;
CREATE POLICY "Courses are public read" ON public.learning_courses FOR SELECT USING (true);

DROP POLICY IF EXISTS "Progress is self-managed" ON public.learning_progress;
CREATE POLICY "Progress is self-managed" ON public.learning_progress FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Wallet is self-managed" ON public.reward_wallets;
CREATE POLICY "Wallet is self-managed" ON public.reward_wallets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Redemptions are self-managed" ON public.reward_redemptions;
CREATE POLICY "Redemptions are self-managed" ON public.reward_redemptions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Alerts are self-managed or public" ON public.climate_alerts;
CREATE POLICY "Alerts are self-managed or public" ON public.climate_alerts FOR SELECT USING (auth.uid() = user_id OR is_public = true);

DROP POLICY IF EXISTS "Alerts are self-managed write" ON public.climate_alerts;
CREATE POLICY "Alerts are self-managed write" ON public.climate_alerts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Posts are visible" ON public.community_posts;
CREATE POLICY "Posts are visible" ON public.community_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Posts are self-managed" ON public.community_posts;
CREATE POLICY "Posts are self-managed" ON public.community_posts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Clubs are visible" ON public.climate_clubs;
CREATE POLICY "Clubs are visible" ON public.climate_clubs FOR SELECT USING (true);

DROP POLICY IF EXISTS "Clubs are owner managed" ON public.climate_clubs;
CREATE POLICY "Clubs are owner managed" ON public.climate_clubs FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Members are self-managed" ON public.climate_club_members;
CREATE POLICY "Members are self-managed" ON public.climate_club_members FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Jobs are public" ON public.job_listings;
CREATE POLICY "Jobs are public" ON public.job_listings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Trees are self-managed" ON public.tree_registry;
CREATE POLICY "Trees are self-managed" ON public.tree_registry FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Grants are visible" ON public.micro_grants;
CREATE POLICY "Grants are visible" ON public.micro_grants FOR SELECT USING (true);

DROP POLICY IF EXISTS "Grants are owner managed" ON public.micro_grants;
CREATE POLICY "Grants are owner managed" ON public.micro_grants FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Payment intents are self-managed" ON public.payment_intents;
CREATE POLICY "Payment intents are self-managed" ON public.payment_intents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Offline guides are public" ON public.offline_guides;
CREATE POLICY "Offline guides are public" ON public.offline_guides FOR SELECT USING (true);

DROP POLICY IF EXISTS "Verification submissions are self-managed" ON public.verification_submissions;
CREATE POLICY "Verification submissions are self-managed" ON public.verification_submissions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Threads are self-managed" ON public.marketplace_threads;
CREATE POLICY "Threads are self-managed" ON public.marketplace_threads FOR ALL USING (auth.uid() = participant_a OR auth.uid() = participant_b) WITH CHECK (auth.uid() = participant_a OR auth.uid() = participant_b);

DROP POLICY IF EXISTS "Messages are self-managed" ON public.marketplace_messages;
CREATE POLICY "Messages are self-managed" ON public.marketplace_messages FOR ALL USING (
  auth.uid() IN (
    SELECT participant_a FROM public.marketplace_threads WHERE id = thread_id
    UNION
    SELECT participant_b FROM public.marketplace_threads WHERE id = thread_id
  )
) WITH CHECK (
  auth.uid() IN (
    SELECT participant_a FROM public.marketplace_threads WHERE id = thread_id
    UNION
    SELECT participant_b FROM public.marketplace_threads WHERE id = thread_id
  )
);

DROP POLICY IF EXISTS "Challenges are visible" ON public.climate_challenges;
CREATE POLICY "Challenges are visible" ON public.climate_challenges FOR SELECT USING (true);

DROP POLICY IF EXISTS "Challenges are owner managed" ON public.climate_challenges;
CREATE POLICY "Challenges are owner managed" ON public.climate_challenges FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Challenge participation is self-managed" ON public.climate_challenge_participants;
CREATE POLICY "Challenge participation is self-managed" ON public.climate_challenge_participants FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Grant votes are visible" ON public.micro_grant_votes;
CREATE POLICY "Grant votes are visible" ON public.micro_grant_votes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Grant votes are self-managed" ON public.micro_grant_votes;
CREATE POLICY "Grant votes are self-managed" ON public.micro_grant_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Views (drop and recreate to avoid column name conflicts)
DROP VIEW IF EXISTS public.community_posts_view;
CREATE OR REPLACE VIEW public.community_posts_view AS
SELECT p.*, pr.display_name, pr.avatar_url
FROM public.community_posts p
JOIN public.profiles pr ON pr.id = p.user_id;

DROP VIEW IF EXISTS public.job_listings_view;
CREATE OR REPLACE VIEW public.job_listings_view AS
SELECT * FROM public.job_listings;

DROP VIEW IF EXISTS public.carbon_projects_view;
CREATE OR REPLACE VIEW public.carbon_projects_view AS
SELECT
  mg.id,
  mg.title,
  mg.description,
  mg.goal_amount,
  mg.raised_amount,
  mg.created_at,
  COALESCE(COUNT(v.user_id), 0)::INT AS votes
FROM public.micro_grants mg
LEFT JOIN public.micro_grant_votes v ON v.grant_id = mg.id
GROUP BY mg.id;

DROP VIEW IF EXISTS public.impact_summary_view;
CREATE OR REPLACE VIEW public.impact_summary_view AS
SELECT
  COALESCE(SUM(impact_score), 0) AS impact_score,
  COALESCE(SUM(carbon_saved_kg), 0) AS carbon_saved_kg,
  COALESCE(SUM(community_score), 0) AS community_score,
  COALESCE(COUNT(*) FILTER (WHERE action_type = 'tree_planting'), 0) AS trees_planted,
  COALESCE(COUNT(*) FILTER (WHERE action_type = 'recycling'), 0) AS recycling_actions,
  COALESCE(COUNT(*) FILTER (WHERE verified), 0) AS verified_actions
FROM public.climate_actions;

DROP VIEW IF EXISTS public.weekly_coach_summary_view;
CREATE OR REPLACE VIEW public.weekly_coach_summary_view AS
SELECT
  p.id AS user_id,
  COALESCE(SUM(a.carbon_saved_kg) FILTER (
    WHERE a.created_at > NOW() - INTERVAL '7 days'), 0) AS carbon_saved_7d,
  COALESCE(COUNT(a.id) FILTER (
    WHERE a.created_at > NOW() - INTERVAL '7 days'), 0)::INT AS actions_7d,
  CASE
    WHEN COALESCE(COUNT(a.id) FILTER (
      WHERE a.created_at > NOW() - INTERVAL '7 days'), 0) >= 5 THEN 5
    ELSE 3
  END AS recommended_goal,
  COALESCE(
    (SELECT title FROM public.climate_challenges c
     WHERE c.ends_at > NOW()
     ORDER BY c.starts_at DESC
     LIMIT 1),
    'No active challenge right now'
  ) AS next_challenge
FROM public.profiles p
LEFT JOIN public.climate_actions a ON a.user_id = p.id
GROUP BY p.id;

DROP VIEW IF EXISTS public.ar_projections_view;
CREATE OR REPLACE VIEW public.ar_projections_view AS
SELECT
  alert_type AS mode,
  COUNT(*)::INT AS active_alerts,
  ROUND(AVG(CASE severity
    WHEN 'critical' THEN 1.0
    WHEN 'high' THEN 0.75
    WHEN 'medium' THEN 0.5
    ELSE 0.25
  END)::NUMERIC, 2) AS level
FROM public.climate_alerts
WHERE resolved = FALSE
GROUP BY alert_type;

DROP VIEW IF EXISTS public.climate_clubs_view;
CREATE OR REPLACE VIEW public.climate_clubs_view AS
SELECT
  c.id,
  c.owner_id,
  c.name,
  c.category,
  c.description,
  c.created_at,
  COALESCE(COUNT(m.user_id), 0)::INT AS members_count
FROM public.climate_clubs c
LEFT JOIN public.climate_club_members m ON m.club_id = c.id
GROUP BY c.id;

DROP VIEW IF EXISTS public.message_threads_view;
CREATE OR REPLACE VIEW public.message_threads_view AS
SELECT
  mt.id,
  mt.listing_id,
  mt.participant_a,
  mt.participant_b,
  mt.updated_at,
  mt.created_at,
  pa.display_name AS participant_a_name,
  pb.display_name AS participant_b_name,
  l.title AS listing_title
FROM public.marketplace_threads mt
JOIN public.profiles pa ON pa.id = mt.participant_a
JOIN public.profiles pb ON pb.id = mt.participant_b
LEFT JOIN public.marketplace_listings l ON l.id = mt.listing_id;

DROP VIEW IF EXISTS public.marketplace_listings_view;
CREATE OR REPLACE VIEW public.marketplace_listings_view AS
SELECT l.*, pr.display_name AS seller_display_name
FROM public.marketplace_listings l
JOIN public.profiles pr ON pr.id = l.seller_id;

DROP VIEW IF EXISTS public.climate_challenges_view;
CREATE OR REPLACE VIEW public.climate_challenges_view AS
SELECT
  c.id,
  c.owner_id,
  c.title,
  c.description,
  c.reward_credits,
  c.starts_at,
  c.ends_at,
  c.created_at,
  COALESCE(COUNT(p.user_id), 0)::INT AS participant_count,
  GREATEST(0, CEIL(EXTRACT(EPOCH FROM (c.ends_at - NOW())) / 86400))::INT AS days_left
FROM public.climate_challenges c
LEFT JOIN public.climate_challenge_participants p ON p.challenge_id = c.id
GROUP BY c.id;

DROP VIEW IF EXISTS public.micro_grants_view;
CREATE OR REPLACE VIEW public.micro_grants_view AS
SELECT
  g.id,
  g.owner_id,
  g.title,
  g.description,
  g.goal_amount,
  g.raised_amount,
  g.created_at,
  COALESCE(COUNT(v.user_id), 0)::INT AS votes
FROM public.micro_grants g
LEFT JOIN public.micro_grant_votes v ON v.grant_id = g.id
GROUP BY g.id;