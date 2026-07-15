import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const challengesRouter = Router();

const challengeSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1).optional().nullable(),
  rewardCredits: z.number().int().min(0).default(0),
  endsAt: z.string().datetime(),
});

challengesRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('climate_challenges_view')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

challengesRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = challengeSchema.parse(req.body);
    const { data, error } = await supabaseAdmin
      .from('climate_challenges')
      .insert({
        owner_id: req.authUser?.id,
        title: payload.title,
        description: payload.description ?? null,
        reward_credits: payload.rewardCredits,
        ends_at: payload.endsAt,
      })
      .select('*')
      .single();
    if (error) throw error;
    res.status(201).json({ data });
  })
);

challengesRouter.post(
  '/:challengeId/join',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { error } = await supabaseAdmin
      .from('climate_challenge_participants')
      .upsert(
        { challenge_id: req.params.challengeId, user_id: req.authUser?.id },
        { onConflict: 'challenge_id,user_id' }
      );
    if (error) throw error;
    res.status(200).json({ data: { joined: true } });
  })
);
