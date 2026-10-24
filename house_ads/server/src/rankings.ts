import { withTransaction } from './db.js';

/**
 * Recalcula likes, médias e score comunitário por lugar, e depois os rankings.
 *
 * Score (escala 0–5) = média_bayesiana * 0.40 + curtidas_normalizadas * 0.30 + peso_editorial * 0.30
 *  - média_bayesiana: suaviza lugares com poucos votos (prior 4.0 com peso de 5 votos)
 *  - curtidas_normalizadas: curtidas / maior_contagem_do_estado * 5
 */
export async function recalculateRankings(): Promise<{ places: number }> {
  return withTransaction(async (client) => {
    await client.query(`
      WITH ids AS (
        SELECT place_id, uf, city_slug FROM place_stats
        UNION
        SELECT place_id, uf, city_slug FROM place_likes
        UNION
        SELECT place_id, uf, city_slug FROM place_reviews WHERE NOT hidden
      ),
      base AS (
        SELECT place_id, MIN(uf) AS uf, MIN(city_slug) AS city_slug FROM ids GROUP BY place_id
      ),
      l AS (SELECT place_id, COUNT(*) AS c FROM place_likes GROUP BY place_id),
      r AS (
        SELECT place_id, AVG(stars) AS avg, COUNT(*) AS c
        FROM place_reviews WHERE NOT hidden GROUP BY place_id
      )
      INSERT INTO place_stats (place_id, uf, city_slug, likes_count, rating_avg, rating_count, updated_at)
      SELECT b.place_id, b.uf, b.city_slug,
             COALESCE(l.c, 0), COALESCE(ROUND(r.avg, 2), 0), COALESCE(r.c, 0), NOW()
      FROM base b
      LEFT JOIN l ON l.place_id = b.place_id
      LEFT JOIN r ON r.place_id = b.place_id
      ON CONFLICT (place_id) DO UPDATE SET
        likes_count  = EXCLUDED.likes_count,
        rating_avg   = EXCLUDED.rating_avg,
        rating_count = EXCLUDED.rating_count,
        updated_at   = NOW()
    `);

    await client.query(`
      UPDATE place_stats s SET score = ROUND(
        ((s.rating_count * s.rating_avg + 5 * 4.0) / (s.rating_count + 5)) * 0.40
        + COALESCE(s.likes_count::numeric / NULLIF(m.max_likes, 0), 0) * 5 * 0.30
        + s.editorial_weight * 0.30, 3)
      FROM (SELECT uf, MAX(likes_count) AS max_likes FROM place_stats GROUP BY uf) m
      WHERE m.uf = s.uf
    `);

    await client.query(`
      UPDATE place_stats s SET rank_state = x.rs, rank_city = x.rc
      FROM (
        SELECT place_id,
               RANK() OVER (PARTITION BY uf ORDER BY score DESC, likes_count DESC) AS rs,
               RANK() OVER (PARTITION BY uf, city_slug ORDER BY score DESC, likes_count DESC) AS rc
        FROM place_stats
      ) x
      WHERE x.place_id = s.place_id
    `);

    const count = await client.query('SELECT COUNT(*)::int AS n FROM place_stats');
    return { places: count.rows[0].n };
  });
}

export function startRankingsJob(intervalMin: number): void {
  const run = () =>
    recalculateRankings()
      .then((r) => console.log(`🏆 Rankings recalculados (${r.places} lugares).`))
      .catch((e) => console.error('❌ Falha ao recalcular rankings:', e.message));

  run();
  setInterval(run, Math.max(1, intervalMin) * 60_000).unref();
}

