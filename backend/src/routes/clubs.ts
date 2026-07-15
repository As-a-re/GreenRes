import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const clubsRouter = Router();

const clubSchema = z.object({
  name: z.string().min(1),
  category: z.enum(['school', 'university', 'community']).default('community'),
  description: z.string().min(1).optional().nullable(),
});

clubsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('climate_clubs_view')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

clubsRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = clubSchema.parse(req.body);
    const { data, error } = await supabaseAdmin
      .from('climate_clubs')
      .insert({
        owner_id: req.authUser?.id,
        name: payload.name,
        category: payload.category,
        description: payload.description ?? null,
      })
      .select('*')
      .single();
    if (error) throw error;
    res.status(201).json({ data });
  })
);

clubsRouter.post(
  '/:clubId/join',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { error } = await supabaseAdmin
      .from('climate_club_members')
      .upsert(
        { club_id: req.params.clubId, user_id: req.authUser?.id },
        { onConflict: 'club_id,user_id' }
      );

    if (error) throw error;
    res.status(200).json({ data: { joined: true } });
  })
);