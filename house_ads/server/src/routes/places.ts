import { Router, Request, Response } from 'express';
import { query } from '../db.js';
import { asyncHandler, isSlug, isUf } from '../middleware.js';

export const rankingsRouter = Router();

/**
 * GET /api/v1/places/stats?uf=PE[&city=recife]
 * Estatísticas consolidadas (média, curtidas, score, posição) para o app atualizar
 * os valores locais sempre que houver conexão.
 */
rankingsRouter.get(
  '/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const uf = (req.query.uf as string) || 'PE';
    const city = req.query.city as string | undefined;
    if (!isUf(uf) || (city && !isSlug(city))) {
      res.status(400).json({ error: 'invalid uf or city' });
      return;
    }
    const result = await query(
      `SELECT place_id, city_slug, likes_count, rating_avg::float AS rating_avg, rating_count,
              score::float AS score, rank_state, rank_city, updated_at
       FROM place_stats
       WHERE uf = $1 AND ($2::text IS NULL OR city_slug = $2)
       ORDER BY score DESC`,
      [uf.toUpperCase(), city || null],
    );
    res.setHeader('Cache-Control', 'public, max-age=60');
    res.json({ success: true, uf: uf.toUpperCase(), count: result.rows.length, data: result.rows });
  }),
);

/**
 * GET /api/v1/places/ranking?uf=PE[&city=recife][&limit=10]
 */
rankingsRouter.get(
  '/ranking',
  asyncHandler(async (req: Request, res: Response) => {
    const uf = (req.query.uf as string) || 'PE';
    const city = req.query.city as string | undefined;
    const limit = Math.min(Math.max(parseInt((req.query.limit as string) || '10', 10) || 10, 1), 100);
    if (!isUf(uf) || (city && !isSlug(city))) {
      res.status(400).json({ error: 'invalid uf or city' });
      return;
    }
    const result = await query(
      `SELECT place_id, city_slug, likes_count, rating_avg::float AS rating_avg, rating_count,
              score::float AS score, rank_state, rank_city
       FROM place_stats
       WHERE uf = $1 AND ($2::text IS NULL OR city_slug = $2) AND (likes_count > 0 OR rating_count > 0)
       ORDER BY score DESC, likes_count DESC
       LIMIT $3`,
      [uf.toUpperCase(), city || null, limit],
    );
    res.setHeader('Cache-Control', 'public, max-age=60');
    res.json({ success: true, count: result.rows.length, data: result.rows });
  }),
);
