import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const alertsRouter = Router();

const alertSchema = z.object({
  alertType: z.enum(['flood', 'heatwave', 'drought', 'air_quality', 'wildfire']),
  title: z.string().min(1),
  message: z.string().min(1),
  severity: z.enum(['low', 'medium', 'high', 'critical']).default('medium'),
  locationLabel: z.string().max(160).optional().nullable(),
  latitude: z.number().optional().nullable(),
  longitude: z.number().optional().nullable(),
});

alertsRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const query = supabaseAdmin
      .from('climate_alerts')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);

    const { data, error } = req.authUser?.id
      ? await query.or(`user_id.eq.${req.authUser.id},is_public.eq.true`)
      : await query.eq('is_public', true);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

alertsRouter.post(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = alertSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('climate_alerts')
      .insert({
        user_id: req.authUser?.id,
        alert_type: payload.alertType,
        title: payload.title,
        message: payload.message,
        severity: payload.severity,
        location_label: payload.locationLabel ?? null,
        latitude: payload.latitude ?? null,
        longitude: payload.longitude ?? null,
      })
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json({ data });
  })
);