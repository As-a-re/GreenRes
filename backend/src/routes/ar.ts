import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const arRouter = Router();

arRouter.get(
  '/projections',
  requireAuth,
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin.from('ar_projections_view').select('*');
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);