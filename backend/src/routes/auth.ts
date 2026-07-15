import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/requireAuth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { supabasePublic } from '../lib/supabase.js';

export const authRouter = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  full_name: z.string().optional(),
});

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Please provide a valid email and password.',
      });
    }

    const { email, password } = parsed.data;
    const { data, error } = await supabasePublic.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.session?.access_token || !data.user) {
      return res.status(401).json({
        error: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password.',
      });
    }

    return res.json({
      data: {
        access_token: data.session.access_token,
        user: data.user,
      },
    });
  })
);

authRouter.post(
  '/signup',
  asyncHandler(async (req, res) => {
    const parsed = signupSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Please provide a valid email and password.',
      });
    }

    const { email, password, full_name } = parsed.data;
    const { data, error } = await supabasePublic.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: full_name ?? email,
        },
      },
    });

    if (error) {
      return res.status(400).json({
        error: 'SIGNUP_FAILED',
        message: error.message,
      });
    }

    return res.status(data.session ? 200 : 201).json({
      data: {
        access_token: data.session?.access_token ?? null,
        user: data.user,
        message: data.session
          ? null
          : 'Account created. Please confirm your email if required.',
      },
    });
  })
);

authRouter.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    res.json({
      data: {
        id: req.authUser?.id,
        email: req.authUser?.email,
        phone: req.authUser?.phone,
        appMetadata: req.authUser?.app_metadata ?? {},
        userMetadata: req.authUser?.user_metadata ?? {},
      },
    });
  })
);