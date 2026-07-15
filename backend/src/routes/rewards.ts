import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const rewardsRouter = Router();

const redemptionSchema = z.object({
  rewardType: z.enum(['airtime', 'data', 'transport_voucher', 'marketplace_product', 'donation']),
  credits: z.number().int().positive(),
  metadata: z.record(z.string(), z.any()).default({}),
});

rewardsRouter.get(
  '/wallet',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('reward_wallets')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .maybeSingle();

    if (error) {
      throw error;
    }

    res.json({
      data:
        data ??
        {
          user_id: req.authUser?.id,
          credits_balance: 0,
          lifetime_credits: 0,
          tier_name: 'starter',
        },
    });
  })
);

rewardsRouter.get(
  '/redemptions',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('reward_redemptions')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

rewardsRouter.post(
  '/redemptions',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = redemptionSchema.parse(req.body);

    const { data: wallet } = await supabaseAdmin
      .from('reward_wallets')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .maybeSingle();

    if (!wallet || wallet.credits_balance < payload.credits) {
      return res.status(400).json({
        error: 'INSUFFICIENT_CREDITS',
        message: 'Not enough credits available for redemption',
      });
    }

    const { data, error } = await supabaseAdmin
      .from('reward_redemptions')
      .insert({
        user_id: req.authUser?.id,
        reward_type: payload.rewardType,
        credits_spent: payload.credits,
        metadata: payload.metadata,
        status: 'pending',
      })
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    await supabaseAdmin
      .from('reward_wallets')
      .update({ credits_balance: wallet.credits_balance - payload.credits })
      .eq('user_id', req.authUser?.id);

    res.status(201).json({ data });
  })
);