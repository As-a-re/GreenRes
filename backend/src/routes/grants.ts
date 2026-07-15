import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const grantsRouter = Router();

const grantSchema = z.object({
  title: z.string().min(1),
  goalAmount: z.number().positive(),
  description: z.string().min(1),
});

grantsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('micro_grants_view')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

grantsRouter.post(
  '/:grantId/vote',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { error } = await supabaseAdmin
      .from('micro_grant_votes')
      .upsert(
        { grant_id: req.params.grantId, user_id: req.authUser?.id },
        { onConflict: 'grant_id,user_id' }
      );
    if (error) throw error;
    res.status(200).json({ data: { voted: true } });
  })
);

grantsRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = grantSchema.parse(req.body);
    const { data, error } = await supabaseAdmin
      .from('micro_grants')
      .insert({
        owner_id: req.authUser?.id,
        title: payload.title,
        goal_amount: payload.goalAmount,
        description: payload.description,
      })
      .select('*')
      .single();
    if (error) throw error;
    res.status(201).json({ data });
  })
);