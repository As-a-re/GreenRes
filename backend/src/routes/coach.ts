import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const coachRouter = Router();

coachRouter.get(
  '/weekly',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('weekly_coach_summary_view')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .maybeSingle();
    if (error) throw error;
    res.json({
      data:
        data ?? {
          user_id: req.authUser?.id,
          carbon_saved_7d: 0,
          actions_7d: 0,
          recommended_goal: 3,
          next_challenge: 'No active challenge right now',
        },
    });
  })
);