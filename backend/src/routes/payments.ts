import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const paymentsRouter = Router();

const paymentSchema = z.object({
  provider: z.enum(['paystack', 'flutterwave', 'stripe', 'mtn_momo', 'airtel_money']),
  amount: z.number().positive(),
  purpose: z.enum(['marketplace', 'rewards', 'donation', 'grant']),
});

paymentsRouter.post(
  '/intents',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = paymentSchema.parse(req.body);
    const { data, error } = await supabaseAdmin
      .from('payment_intents')
      .insert({
        user_id: req.authUser?.id,
        provider: payload.provider,
        amount: payload.amount,
        purpose: payload.purpose,
        status: 'pending',
      })
      .select('*')
      .single();
    if (error) throw error;
    res.status(201).json({ data });
  })
);