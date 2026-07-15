import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';
import { supabaseAdmin } from '../lib/supabase.js';

export const profilesRouter = Router();

const profileSchema = z.object({
  displayName: z.string().min(1).max(120).optional(),
  avatarUrl: z.string().url().optional().nullable(),
  bio: z.string().max(280).optional().nullable(),
  location: z.string().max(120).optional().nullable(),
  organization: z.string().max(120).optional().nullable(),
  interests: z.array(z.string().min(1).max(50)).max(20).optional(),
});

profilesRouter.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = req.authUser?.id;

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (data) {
      res.json({ data });
      return;
    }

    const fallbackProfile = {
      id: userId,
      email: req.authUser?.email ?? null,
      display_name: req.authUser?.user_metadata?.display_name ?? req.authUser?.email ?? 'GreenRes User',
      avatar_url: req.authUser?.user_metadata?.avatar_url ?? null,
      bio: null,
      location: null,
      organization: null,
      interests: [],
    };

    const { data: createdProfile, error: createError } = await supabaseAdmin
      .from('profiles')
      .insert(fallbackProfile)
      .select('*')
      .single();

    if (createError) {
      throw createError;
    }

    res.status(201).json({ data: createdProfile });
  })
);

profilesRouter.patch(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = req.authUser?.id;
    const payload = profileSchema.parse(req.body);

    const { data: existing } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .upsert(
        {
          id: userId,
          display_name: payload.displayName ?? existing?.display_name ?? req.authUser?.email ?? 'GreenRes User',
          avatar_url: payload.avatarUrl !== undefined ? payload.avatarUrl : existing?.avatar_url ?? null,
          bio: payload.bio !== undefined ? payload.bio : existing?.bio ?? null,
          location: payload.location !== undefined ? payload.location : existing?.location ?? null,
          organization: payload.organization !== undefined ? payload.organization : existing?.organization ?? null,
          interests: payload.interests ?? existing?.interests ?? [],
          email: req.authUser?.email ?? existing?.email ?? null,
        },
        { onConflict: 'id' }
      )
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    res.json({ data });
  })
);