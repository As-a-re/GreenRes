import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const learningRouter = Router();

const progressSchema = z.object({
  courseId: z.string().uuid(),
  progressPercent: z.number().min(0).max(100),
  completed: z.boolean().default(false),
  quizScore: z.number().min(0).max(100).optional().nullable(),
});

learningRouter.get(
  '/courses',
  asyncHandler(async (_req, res) => {
    const { data, error } = await supabaseAdmin
      .from('learning_courses')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

learningRouter.get(
  '/progress',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('learning_progress')
      .select('*')
      .eq('user_id', req.authUser?.id)
      .order('updated_at', { ascending: false })
      .limit(100);

    if (error) {
      throw error;
    }

    res.json({ data: data ?? [] });
  })
);

learningRouter.post(
  '/progress',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = progressSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('learning_progress')
      .upsert(
        {
          user_id: req.authUser?.id,
          course_id: payload.courseId,
          progress_percent: payload.progressPercent,
          completed: payload.completed,
          quiz_score: payload.quizScore ?? null,
        },
        { onConflict: 'user_id,course_id' }
      )
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json({ data });
  })
);