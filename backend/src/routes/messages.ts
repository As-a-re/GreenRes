import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const messagesRouter = Router();

const messageSchema = z.object({
  threadId: z.string().uuid(),
  body: z.string().min(1),
});

const threadStartSchema = z.object({
  listingId: z.string().uuid(),
  sellerId: z.string().uuid(),
});

messagesRouter.post(
  '/threads',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = threadStartSchema.parse(req.body);
    const buyerId = req.authUser?.id;

    if (buyerId === payload.sellerId) {
      return res.status(400).json({
        error: 'INVALID_THREAD',
        message: 'You cannot start a thread with yourself.',
      });
    }

    const { data: existing, error: findError } = await supabaseAdmin
      .from('marketplace_threads')
      .select('*')
      .eq('listing_id', payload.listingId)
      .eq('participant_a', buyerId)
      .eq('participant_b', payload.sellerId)
      .maybeSingle();

    if (findError) throw findError;
    if (existing) {
      res.json({ data: existing });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('marketplace_threads')
      .insert({
        listing_id: payload.listingId,
        participant_a: buyerId,
        participant_b: payload.sellerId,
      })
      .select('*')
      .single();

    if (error) throw error;
    res.status(201).json({ data });
  })
);

messagesRouter.get(
  '/threads',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = req.authUser?.id;
    const { data, error } = await supabaseAdmin
      .from('message_threads_view')
      .select('*')
      .or(`participant_a.eq.${userId},participant_b.eq.${userId}`)
      .order('updated_at', { ascending: false })
      .limit(50);

    if (error) throw error;

    const threads = (data ?? []).map((thread: Record<string, unknown>) => {
      const isA = thread.participant_a === userId;
      return {
        ...thread,
        other_user_name: isA ? thread.participant_b_name : thread.participant_a_name,
        other_user_id: isA ? thread.participant_b : thread.participant_a,
      };
    });

    res.json({ data: threads });
  })
);

messagesRouter.get(
  '/threads/:threadId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { data, error } = await supabaseAdmin
      .from('marketplace_messages')
      .select('*')
      .eq('thread_id', req.params.threadId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    res.json({ data: data ?? [] });
  })
);

messagesRouter.post(
  '/threads/send',
  requireAuth,
  asyncHandler(async (req, res) => {
    const payload = messageSchema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('marketplace_messages')
      .insert({
        thread_id: payload.threadId,
        sender_id: req.authUser?.id,
        body: payload.body,
      })
      .select('*')
      .single();

    if (error) throw error;
    res.status(201).json({ data });
  })
);