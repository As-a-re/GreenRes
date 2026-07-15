import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const jobsRouter = Router();

jobsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('job_listings_view')
      .select('*')
      .order('match_score', { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);