import { Router, Request, Response } from 'express';
import { PoolClient } from 'pg';
import { withTransaction } from '../db.js';
import { asyncHandler, isDeviceId, isPlaceId, isSlug, isUf, rateLimit } from '../middleware.js';

export const telemetryRouter = Router();

const AD_POSITIONS = new Set(['home_card', 'attraction_banner', 'interstitial']);
const MAX_BATCH = 100;

type TelemetryEvent = Record<string, any>;

/** Valida e grava um evento. Retorna null se válido ou a mensagem de erro. */
export async function applyEvent(
  client: PoolClient,
  deviceId: string,
  defaultUf: string | undefined,
  ev: TelemetryEvent,
): Promise<string | null> {
  const uf = (ev.uf || defaultUf || '').toString();
  const citySlug = ev.city_slug == null || ev.city_slug === '' ? '' : String(ev.city_slug);
  if (!isUf(uf)) return 'invalid uf';
  if (citySlug && !isSlug(citySlug)) return 'invalid city_slug';
  const UF = uf.toUpperCase();

  switch (ev.kind) {
    case 'like':
    case 'unlike': {
      if (!isPlaceId(ev.place_id)) return 'invalid place_id';
      if (ev.kind === 'like') {
        await client.query(
          `INSERT INTO place_likes (place_id, device_id, uf, city_slug)
           VALUES ($1, $2, $3, $4) ON CONFLICT (place_id, device_id) DO NOTHING`,
          [ev.place_id, deviceId, UF, citySlug],
        );
      } else {
        await client.query('DELETE FROM place_likes WHERE place_id = $1 AND device_id = $2', [
          ev.place_id,
          deviceId,
        ]);
      }
      return null;
    }
    case 'review': {
      if (!isPlaceId(ev.place_id)) return 'invalid place_id';
      const stars = Number(ev.stars);
      if (!Number.isInteger(stars) || stars < 1 || stars > 5) return 'invalid stars';
      await client.query(
        `INSERT INTO place_reviews (place_id, device_id, uf, city_slug, stars)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (place_id, device_id)
         DO UPDATE SET stars = EXCLUDED.stars, updated_at = NOW()`,
        [ev.place_id, deviceId, UF, citySlug, stars],
      );
      return null;
    }
    case 'ad_impression':
    case 'ad_click': {
      if (typeof ev.ad_id !== 'string' || !ev.ad_id || ev.ad_id.length > 64) return 'invalid ad_id';
      if (!AD_POSITIONS.has(ev.position)) return 'invalid position';
      const table = ev.kind === 'ad_click' ? 'ad_clicks' : 'ad_impressions';
      await client.query(
        `INSERT INTO ${table} (ad_id, uf, city_slug, position, device_id) VALUES ($1, $2, $3, $4, $5)`,
        [ev.ad_id, UF, citySlug || null, ev.position, deviceId],
      );
      return null;
    }
    default:
      return 'unknown kind';
  }
}

async function registerDevice(client: PoolClient, deviceId: string, body: Request['body']): Promise<void> {
  await client.query(
    `INSERT INTO devices (device_id, platform, app_uf, app_version)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (device_id) DO UPDATE SET
       last_seen = NOW(),
       platform = COALESCE(EXCLUDED.platform, devices.platform),
       app_uf = COALESCE(EXCLUDED.app_uf, devices.app_uf),
       app_version = COALESCE(EXCLUDED.app_version, devices.app_version)`,
    [
      deviceId,
      typeof body.platform === 'string' ? body.platform.slice(0, 16) : null,
      isUf(body.app_uf) ? String(body.app_uf).toUpperCase() : null,
      typeof body.app_version === 'string' ? body.app_version.slice(0, 32) : null,
    ],
  );
}

/**
 * POST /api/v1/telemetry/batch
 * Descarrega a fila offline do app. Os eventos são aplicados na ordem enviada
 * (importa para like/unlike) e a operação é idempotente.
 * Body: { device_id, uf, platform?, app_version?, events: [{ kind, ... }] }
 */
telemetryRouter.post(
  '/batch',
  rateLimit(30),
  asyncHandler(async (req: Request, res: Response) => {
    const { device_id, uf, events } = req.body || {};
    if (!isDeviceId(device_id)) {
      res.status(400).json({ error: 'invalid device_id' });
      return;
    }
    if (!Array.isArray(events) || events.length === 0 || events.length > MAX_BATCH) {
      res.status(400).json({ error: `events must be an array with 1-${MAX_BATCH} items` });
      return;
    }

    const results = await withTransaction(async (client) => {
      await registerDevice(client, device_id, req.body);
      const out: { index: number; ok: boolean; error?: string }[] = [];
      for (let i = 0; i < events.length; i++) {
        const error = await applyEvent(client, device_id, uf, events[i] || {});
        out.push(error ? { index: i, ok: false, error } : { index: i, ok: true });
      }
      return out;
    });

    // Itens inválidos não devem ser reenviados; o app descarta toda a resposta processada.
    res.json({ success: true, accepted: results.filter((r) => r.ok).length, results });
  }),
);

// Atalhos para envio unitário (quando o app está online no momento da ação).
function single(kind: 'vote' | 'review') {
  return asyncHandler(async (req: Request, res: Response) => {
    const body = req.body || {};
    if (!isDeviceId(body.device_id)) {
      res.status(400).json({ error: 'invalid device_id' });
      return;
    }
    const ev: TelemetryEvent =
      kind === 'vote' ? { ...body, kind: body.type === 'unlike' ? 'unlike' : 'like' } : { ...body, kind: 'review' };

    const error = await withTransaction(async (client) => {
      await registerDevice(client, body.device_id, body);
      return applyEvent(client, body.device_id, body.uf, ev);
    });
    if (error) {
      res.status(400).json({ error });
      return;
    }
    res.json({ success: true });
  });
}

telemetryRouter.post('/vote', rateLimit(120), single('vote'));
telemetryRouter.post('/review', rateLimit(120), single('review'));
