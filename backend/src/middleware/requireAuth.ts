import type { NextFunction, Request, Response } from 'express';
import { supabasePublic } from '../lib/supabase.js';

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authorizationHeader = req.headers.authorization;

  if (!authorizationHeader?.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Missing bearer token',
    });
  }

  const accessToken = authorizationHeader.slice(7).trim();

  if (!accessToken) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Missing bearer token',
    });
  }

  const { data, error } = await supabasePublic.auth.getUser(accessToken);

  if (error || !data.user) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Invalid or expired session',
    });
  }

  req.authUser = data.user;
  req.accessToken = accessToken;
  return next();
}