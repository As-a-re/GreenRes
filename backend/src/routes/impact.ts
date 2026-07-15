import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

export const impactRouter = Router();

impactRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('impact_summary_view')
      .select('*')
      .limit(1)
      .maybeSingle();

    if (error) {
      throw error;
    }

    res.json({
      data: data ?? {
        impact_score: 0,
        carbon_saved_kg: 0,
        community_score: 0,
        trees_planted: 0,
        recycling_actions: 0,
        verified_actions: 0,
      },
    });
  })
);