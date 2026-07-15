import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const actionsRouter = Router();

const actionSchema = z.object({
  type: z.string().min(1),
  title: z.string().min(1),
  evidenceUrl: z.string().url().optional(),
  metadata: z.record(z.string(), z.any()).default({}),
});

actionsRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (_req, res) => {
    const userId = _req.authUser?.id;

    const { data, error } = await supabaseAdmin
      .from('climate_actions')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

actionsRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = actionSchema.parse(req.body);
    const userId = req.authUser?.id;

    const { data, error } = await supabaseAdmin
      .from('climate_actions')
      .insert({
        user_id: userId,
        action_type: payload.type,
        title: payload.title,
        evidence_url: payload.evidenceUrl ?? null,
        metadata: payload.metadata,
      })
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json({ data });
  })
);