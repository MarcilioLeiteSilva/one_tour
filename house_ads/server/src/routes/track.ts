import { Router, Request, Response } from 'express';
import { query } from '../db.js';

export const trackRouter = Router();

// Track Impression
trackRouter.post('/impression', async (req: Request, res: Response) => {
  const { ad_id, uf, city_slug, position, device_id } = req.body;

  if (!ad_id || !uf || !position) {
    res.status(400).json({ error: 'Missing required parameters: ad_id, uf, position' });
    return;
  }

  const sql = `
    INSERT INTO ad_impressions (ad_id, uf, city_slug, position, device_id)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, created_at;
  `;

  try {
    const result = await query(sql, [ad_id, uf.toUpperCase(), city_slug || null, position, device_id || null]);
    res.json({
      success: true,
      event: 'impression_recorded',
      id: result.rows[0]?.id || 'local_uuid',
    });
  } catch (err: any) {
    res.status(500).json({ error: 'Failed to record impression', details: err.message });
  }
});

// Track Click
trackRouter.post('/click', async (req: Request, res: Response) => {
  const { ad_id, uf, city_slug, position, device_id } = req.body;

  if (!ad_id || !uf || !position) {
    res.status(400).json({ error: 'Missing required parameters: ad_id, uf, position' });
    return;
  }

  const sql = `
    INSERT INTO ad_clicks (ad_id, uf, city_slug, position, device_id)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, created_at;
  `;

  try {
    const result = await query(sql, [ad_id, uf.toUpperCase(), city_slug || null, position, device_id || null]);
    res.json({
      success: true,
      event: 'click_recorded',
      id: result.rows[0]?.id || 'local_uuid',
    });
  } catch (err: any) {
    res.status(500).json({ error: 'Failed to record click', details: err.message });
  }
});
