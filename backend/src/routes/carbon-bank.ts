import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const carbonBankRouter = Router();

carbonBankRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('carbon_projects_view')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);