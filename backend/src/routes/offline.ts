import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const offlineRouter = Router();

offlineRouter.get(
  '/guides',
  requireAuth,
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('offline_guides')
      .select('*')
      .order('priority', { ascending: true });
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);