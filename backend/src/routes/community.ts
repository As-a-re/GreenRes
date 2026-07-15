import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const communityRouter = Router();

const postSchema = z.object({
  action: z.string().min(1),
  mediaUrl: z.string().url().optional().nullable(),
  visibility: z.enum(['public', 'club', 'private']).default('public'),
});

communityRouter.get(
  '/feed',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('community_posts_view')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

communityRouter.post(
  '/feed',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = postSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('community_posts')
      .insert({
        user_id: req.authUser?.id,
        action: payload.action,
        media_url: payload.mediaUrl ?? null,
        visibility: payload.visibility,
      })
      .select('*')
      .single();

    if (error) throw error;
    res.status(201).json({ data });
  })
);