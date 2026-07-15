import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const verificationRouter = Router();

const verificationSchema = z.object({
  actionType: z.string().min(1),
  title: z.string().min(1),
  evidenceUrl: z.string().url().optional().nullable(),
  latitude: z.number().optional().nullable(),
  longitude: z.number().optional().nullable(),
});

// Documented crediting policy: this is a fixed, transparent lookup table,
// not a machine-learning model. Submissions with both a photo and a
// location get auto-approved at a baseline confidence; anything else is
// left pending for manual follow-up (there's no reviewer role/queue wired
// up yet — see backend/README.md "Known gaps").
const ACTION_POLICY: Record<string, { carbonKg: number; credits: number }> = {
  tree_planting: { carbonKg: 5.0, credits: 20 },
  recycling: { carbonKg: 2.0, credits: 10 },
  composting: { carbonKg: 1.5, credits: 8 },
  cycling: { carbonKg: 1.0, credits: 6 },
  transport: { carbonKg: 1.0, credits: 6 },
  cleanup: { carbonKg: 3.0, credits: 15 },
  water_conservation: { carbonKg: 1.0, credits: 6 },
  energy_saving: { carbonKg: 2.5, credits: 12 },
};
const DEFAULT_POLICY = { carbonKg: 1.0, credits: 5 };

function tierForLifetimeCredits(lifetime: number): string {
  if (lifetime >= 2000) return 'champion';
  if (lifetime >= 500) return 'guardian';
  if (lifetime >= 100) return 'contributor';
  return 'starter';
}

verificationRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('verification_submissions')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

verificationRouter.post(
  '/submit',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = verificationSchema.parse(req.body);
    const userId = req.authUser?.id as string;

    const hasEvidence = Boolean(payload.evidenceUrl);
    const hasLocation = payload.latitude != null && payload.longitude != null;
    const autoApprove = hasEvidence && hasLocation;
    const confidence = autoApprove ? 0.75 : 0.35;
    const status = autoApprove ? 'approved' : 'pending';

    const { data: submission, error } = await supabaseAdmin
      .from('verification_submissions')
      .insert({
        user_id: userId,
        action_type: payload.actionType,
        title: payload.title,
        evidence_url: payload.evidenceUrl ?? null,
        latitude: payload.latitude ?? null,
        longitude: payload.longitude ?? null,
        confidence,
        status,
      })
      .select('*')
      .single();

    if (error) throw error;

    let action = null;
    if (autoApprove) {
      const policy = ACTION_POLICY[payload.actionType] ?? DEFAULT_POLICY;

      const { data: createdAction, error: actionError } = await supabaseAdmin
        .from('climate_actions')
        .insert({
          user_id: userId,
          action_type: payload.actionType,
          title: payload.title,
          evidence_url: payload.evidenceUrl ?? null,
          metadata: { verification_submission_id: submission.id },
          impact_score: policy.carbonKg * 10,
          carbon_saved_kg: policy.carbonKg,
          community_score: 1,
          verified: true,
        })
        .select('*')
        .single();

      if (actionError) throw actionError;
      action = createdAction;

      const { data: wallet } = await supabaseAdmin
        .from('reward_wallets')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      const newLifetime = (wallet?.lifetime_credits ?? 0) + policy.credits;

      await supabaseAdmin.from('reward_wallets').upsert(
        {
          user_id: userId,
          credits_balance: (wallet?.credits_balance ?? 0) + policy.credits,
          lifetime_credits: newLifetime,
          tier_name: tierForLifetimeCredits(newLifetime),
        },
        { onConflict: 'user_id' }
      );
    }

    res.status(201).json({ data: { submission, action, creditsAwarded: autoApprove ? (ACTION_POLICY[payload.actionType] ?? DEFAULT_POLICY).credits : 0 } });
  })
);
