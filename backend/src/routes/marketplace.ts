import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

export const marketplaceRouter = Router();

marketplaceRouter.get(
  '/listings',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('marketplace_listings_view')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

marketplaceRouter.get(
  '/listings/:listingId',
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('marketplace_listings_view')
      .select('*')
      .eq('id', req.params.listingId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (!data) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Listing not found' });
    }

    res.json({ data });
  })
);