import { Router } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

export const adminRouter = Router();

adminRouter.get(
  '/summary',
  asyncHandler(async (_req, res) => {
    const [profiles, actions, alerts, grants, pendingVerifications, highSeverityAlerts, challenges] =
      await Promise.all([
        supabaseAdmin.from('profiles').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('climate_actions').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('climate_alerts').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('micro_grants').select('id', { count: 'exact', head: true }),
        supabaseAdmin
          .from('verification_submissions')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'pending'),
        supabaseAdmin
          .from('climate_alerts')
          .select('id', { count: 'exact', head: true })
          .in('severity', ['high', 'critical'])
          .eq('resolved', false),
        supabaseAdmin.from('climate_challenges').select('id', { count: 'exact', head: true }),
      ]);

    res.json({
      data: {
        totalUsers: profiles.count ?? 0,
        totalActions: actions.count ?? 0,
        totalAlerts: alerts.count ?? 0,
        totalGrants: grants.count ?? 0,
        pendingVerifications: pendingVerifications.count ?? 0,
        highSeverityAlerts: highSeverityAlerts.count ?? 0,
        activeChallenges: challenges.count ?? 0,
      },
    });
  })
);