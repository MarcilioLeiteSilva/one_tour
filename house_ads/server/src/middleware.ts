import { Request, Response, NextFunction } from 'express';
import { config } from './config.js';

// ---------------------------------------------------------------------------
// Rate limit simples em memória (janela fixa) por IP
// ---------------------------------------------------------------------------
export function rateLimit(maxPerMinute: number) {
  const hits = new Map<string, { count: number; resetAt: number }>();

  setInterval(() => {
    const now = Date.now();
    for (const [key, v] of hits) if (v.resetAt <= now) hits.delete(key);
  }, 60_000).unref();

  return (req: Request, res: Response, next: NextFunction): void => {
    const key = req.ip || 'unknown';
    const now = Date.now();
    const entry = hits.get(key);
    if (!entry || entry.resetAt <= now) {
      hits.set(key, { count: 1, resetAt: now + 60_000 });
      next();
      return;
    }
    entry.count += 1;
    if (entry.count > maxPerMinute) {
      res.setHeader('Retry-After', Math.ceil((entry.resetAt - now) / 1000).toString());
      res.status(429).json({ error: 'Too many requests' });
      return;
    }
    next();
  };
}

// ---------------------------------------------------------------------------
// Autenticação do admin: valida o token emitido pelo PocketBase (v0.22: admins)
// ---------------------------------------------------------------------------
const tokenCache = new Map<string, { email: string; expiresAt: number }>();
const CACHE_TTL_MS = 60_000;

export async function requireAdmin(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : header;
  if (!token) {
    res.status(401).json({ error: 'Missing token' });
    return;
  }

  const cached = tokenCache.get(token);
  if (cached && cached.expiresAt > Date.now()) {
    (req as any).adminEmail = cached.email;
    next();
    return;
  }

  try {
    // Tenta primeiro no PocketBase v0.23+ (_superusers)
    let pbRes = await fetch(`${config.pocketbaseUrl}/api/collections/_superusers/auth-refresh`, {
      method: 'POST',
      headers: { Authorization: token },
      signal: AbortSignal.timeout(5000),
    });

    // Fallback para PocketBase v0.22 (admins) caso retorne 404
    if (pbRes.status === 404) {
      pbRes = await fetch(`${config.pocketbaseUrl}/api/admins/auth-refresh`, {
        method: 'POST',
        headers: { Authorization: token },
        signal: AbortSignal.timeout(5000),
      });
    }

    if (!pbRes.ok) {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }
    const body: any = await pbRes.json();
    const email: string = body?.record?.email || body?.admin?.email || 'admin';
    tokenCache.set(token, { email, expiresAt: Date.now() + CACHE_TTL_MS });
    (req as any).adminEmail = email;
    next();
  } catch {
    res.status(503).json({ error: 'Auth provider unavailable' });
  }
}

// ---------------------------------------------------------------------------
// Validação de entrada
// ---------------------------------------------------------------------------
const DEVICE_RE = /^[A-Za-z0-9_-]{8,128}$/;
const SLUG_RE = /^[a-z0-9_-]{1,64}$/;
const ID_RE = /^[A-Za-z0-9_.:-]{1,64}$/;

export const isDeviceId = (v: unknown): v is string => typeof v === 'string' && DEVICE_RE.test(v);
export const isSlug = (v: unknown): v is string => typeof v === 'string' && SLUG_RE.test(v);
export const isPlaceId = (v: unknown): v is string => typeof v === 'string' && ID_RE.test(v);
export const isUf = (v: unknown): v is string => typeof v === 'string' && /^[A-Za-z]{2}$/.test(v);

/** Envolve handlers async para que erros virem respostas 5xx em vez de derrubar a requisição. */
export function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    fn(req, res).catch((err) => {
      console.error(`❌ ${req.method} ${req.originalUrl}:`, err?.message || err);
      if (!res.headersSent) res.status(503).json({ error: 'Service temporarily unavailable' });
      else next(err);
    });
  };
}
