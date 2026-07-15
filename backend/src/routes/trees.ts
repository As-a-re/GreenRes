import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const treeRouter = Router();

const treeSchema = z.object({
  species: z.string().min(1),
  treeId: z.string().min(1),
  plantedAt: z.string().datetime().optional().nullable(),
  locationLabel: z.string().optional().nullable(),
  health: z.number().min(0).max(1).default(1),
});

treeRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('tree_registry')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .order('created_at', { ascending: false })
      .limit(100);
    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

treeRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = treeSchema.parse(req.body);
    const { data, error } = await supabaseAdmin
      .from('tree_registry')
      .insert({
        user_id: req.authUser?.id,
        species: payload.species,
        tree_id: payload.treeId,
        planted_at: payload.plantedAt ?? null,
        location_label: payload.locationLabel ?? null,
        health: payload.health,
      })
      .select('*')
      .single();
    if (error) throw error;
    res.status(201).json({ data });
  })
);