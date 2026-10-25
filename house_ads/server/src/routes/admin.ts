import { Router, Request, Response } from 'express';
import { query } from '../db.js';
import { recalculateRankings } from '../rankings.js';
import { asyncHandler, isPlaceId, isSlug, isUf, requireAdmin } from '../middleware.js';
import { sendFcmPush } from '../services/fcm.js';

export const adminRouter = Router();
adminRouter.use(requireAdmin);

/** GET /api/v1/admin/overview — números principais do dashboard. */
adminRouter.get(
  '/overview',
  asyncHandler(async (_req: Request, res: Response) => {
    const result = await query(`
      SELECT
        (SELECT COUNT(*) FROM devices)::int                                              AS devices_total,
        (SELECT COUNT(*) FROM devices WHERE last_seen > NOW() - INTERVAL '7 days')::int  AS devices_active_7d,
        (SELECT COUNT(*) FROM place_likes)::int                                          AS likes_total,
        (SELECT COUNT(*) FROM place_reviews WHERE NOT hidden)::int                       AS reviews_total,
        (SELECT COUNT(*) FROM ad_impressions WHERE created_at > NOW() - INTERVAL '30 days')::int AS impressions_30d,
        (SELECT COUNT(*) FROM ad_clicks WHERE created_at > NOW() - INTERVAL '30 days')::int      AS clicks_30d
    `);
    res.json({ success: true, data: result.rows[0] });
  }),
);

/** GET /api/v1/admin/ads/performance[?days=30] — impressões, cliques e CTR por anúncio. */
adminRouter.get(
  '/ads/performance',
  asyncHandler(async (req: Request, res: Response) => {
    const days = Math.min(Math.max(parseInt((req.query.days as string) || '30', 10) || 30, 1), 365);
    const result = await query(
      `SELECT i.ad_id, i.uf, i.position, i.impressions,
              COALESCE(c.clicks, 0)::int AS clicks,
              ROUND(COALESCE(c.clicks, 0)::numeric / NULLIF(i.impressions, 0) * 100, 2)::float AS ctr
       FROM (SELECT ad_id, uf, position, COUNT(*)::int AS impressions
             FROM ad_impressions WHERE created_at > NOW() - make_interval(days => $1)
             GROUP BY ad_id, uf, position) i
       LEFT JOIN (SELECT ad_id, uf, position, COUNT(*)::int AS clicks
                  FROM ad_clicks WHERE created_at > NOW() - make_interval(days => $1)
                  GROUP BY ad_id, uf, position) c
         ON c.ad_id = i.ad_id AND c.uf = i.uf AND c.position = i.position
       ORDER BY i.impressions DESC`,
      [days],
    );
    res.json({ success: true, days, rows: result.rows });
  }),
);

/** PUT /api/v1/admin/places/:id/editorial — define o peso editorial (0–5) de um lugar. */
adminRouter.put(
  '/places/:id/editorial',
  asyncHandler(async (req: Request, res: Response) => {
    const id = req.params.id;
    const { uf, city_slug, editorial_weight } = req.body || {};
    const weight = Number(editorial_weight);
    if (!isPlaceId(id) || !isUf(uf) || !isSlug(city_slug) || !(weight >= 0 && weight <= 5)) {
      res.status(400).json({ error: 'invalid place id, uf, city_slug or editorial_weight (0-5)' });
      return;
    }
    await query(
      `INSERT INTO place_stats (place_id, uf, city_slug, editorial_weight)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (place_id) DO UPDATE SET editorial_weight = EXCLUDED.editorial_weight`,
      [id, String(uf).toUpperCase(), city_slug, weight],
    );
    const r = await recalculateRankings();
    res.json({ success: true, recalculated: r.places });
  }),
);

/** POST /api/v1/admin/rankings/recalculate — força o recálculo imediato. */
adminRouter.post(
  '/rankings/recalculate',
  asyncHandler(async (_req: Request, res: Response) => {
    const r = await recalculateRankings();
    res.json({ success: true, places: r.places });
  }),
);

/** GET /api/v1/admin/reviews?uf=PE&place_id=... — lista avaliações para moderação. */
adminRouter.get(
  '/reviews',
  asyncHandler(async (req: Request, res: Response) => {
    const uf = (req.query.uf as string) || 'PE';
    const placeId = req.query.place_id as string | undefined;
    const limit = Math.min(Math.max(parseInt((req.query.limit as string) || '50', 10) || 50, 1), 200);
    if (!isUf(uf) || (placeId && !isPlaceId(placeId))) {
      res.status(400).json({ error: 'invalid uf or place_id' });
      return;
    }
    const result = await query(
      `SELECT place_id, device_id, city_slug, stars, hidden, created_at, updated_at
       FROM place_reviews
       WHERE uf = $1 AND ($2::text IS NULL OR place_id = $2)
       ORDER BY updated_at DESC LIMIT $3`,
      [uf.toUpperCase(), placeId || null, limit],
    );
    res.json({ success: true, rows: result.rows });
  }),
);

/** PATCH /api/v1/admin/reviews/hide — oculta/reexibe uma avaliação (suspeita de fraude). */
adminRouter.patch(
  '/reviews/hide',
  asyncHandler(async (req: Request, res: Response) => {
    const { place_id, device_id, hidden } = req.body || {};
    if (!isPlaceId(place_id) || typeof device_id !== 'string' || typeof hidden !== 'boolean') {
      res.status(400).json({ error: 'place_id, device_id and hidden (boolean) are required' });
      return;
    }
    await query('UPDATE place_reviews SET hidden = $3 WHERE place_id = $1 AND device_id = $2', [
      place_id,
      device_id,
      hidden,
    ]);
    const r = await recalculateRankings();
    res.json({ success: true, recalculated: r.places });
  }),
);

/** POST /api/v1/admin/notifications/send — dispara notificação push via FCM. */
adminRouter.post(
  '/notifications/send',
  asyncHandler(async (req: Request, res: Response) => {
    const { topic, device_token, title, body, image_url, action_type, action_value } = req.body || {};
    if ((!topic && !device_token) || !title || !body) {
      res.status(400).json({ error: 'topic (or device_token), title and body are required' });
      return;
    }

    const result = await sendFcmPush({
      topic: topic ? String(topic) : undefined,
      deviceToken: device_token ? String(device_token) : undefined,
      title: String(title),
      body: String(body),
      imageUrl: image_url ? String(image_url) : undefined,
      actionType: action_type ? String(action_type) : undefined,
      actionValue: action_value ? String(action_value) : undefined,
    });

    res.json({
      success: true,
      message_id: result.messageId,
      target: result.target,
      broadcast_at: result.broadcastAt,
      is_real_dispatch: result.isRealDispatch,
    });
  }),
);
