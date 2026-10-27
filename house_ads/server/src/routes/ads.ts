import { Router, Request, Response } from 'express';
import { query } from '../db.js';
import { getMatchingAds } from '../campaigns.js';

export const adsRouter = Router();

adsRouter.get('/', async (req: Request, res: Response) => {
  const uf = ((req.query.uf as string) || 'PE').toUpperCase();
  const city = (req.query.cidade as string) || (req.query.city as string);
  const position = (req.query.posicao as string) || (req.query.position as string);
  const limit = Math.min(Math.max(parseInt((req.query.limit as string) || '5', 10), 1), 20);

  try {
    let sql = `
      SELECT id, type, title, subtitle, tag, image_url, action_label, target_url,
             target_uf, target_cities, position, priority, active
      FROM house_ad_campaigns
      WHERE active = true
        AND (target_uf = $1 OR target_uf = 'ALL')
        AND (start_date IS NULL OR start_date <= NOW())
        AND (end_date IS NULL OR end_date >= NOW())
    `;
    const params: any[] = [uf];

    if (position) {
      params.push(position);
      sql += ` AND position = $${params.length}`;
    }

    sql += ' ORDER BY priority DESC, created_at DESC';

    const dbResult = await query(sql, params);

    let candidateAds = dbResult.rows;

    // Filtro de cidade se especificado
    if (city && candidateAds.length > 0) {
      const normalizedCity = city.toLowerCase().trim();
      candidateAds = candidateAds.filter((ad: any) => {
        if (!ad.target_cities || ad.target_cities.length === 0) return true; // Veiculação estadual
        return ad.target_cities.some((c: string) =>
          normalizedCity.includes(c.toLowerCase()) || c.toLowerCase().includes(normalizedCity),
        );
      });
    }

    if (candidateAds.length > 0) {
      const mapped = candidateAds.slice(0, limit).map((r: any) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        subtitle: r.subtitle,
        tag: r.tag,
        imageUrl: r.image_url,
        actionLabel: r.action_label,
        targetUrl: r.target_url,
        targetUf: r.target_uf,
        targetCities: r.target_cities || [],
        position: r.position,
        priority: r.priority,
        active: r.active,
      }));

      res.json({
        success: true,
        source: 'database',
        uf,
        city: city || null,
        position: position || null,
        count: mapped.length,
        data: mapped,
      });
      return;
    }
  } catch (err: any) {
    console.warn('⚠️ [AdsRouter] Falha ao consultar campanhas no PostgreSQL, usando fallback em memória:', err.message);
  }

  // Fallback estático caso a tabela ainda não esteja populada ou em caso de erro
  const fallbackAds = getMatchingAds({
    uf,
    city,
    position,
    limit,
  });

  res.json({
    success: true,
    source: 'memory_fallback',
    uf,
    city: city || null,
    position: position || null,
    count: fallbackAds.length,
    data: fallbackAds,
  });
});
