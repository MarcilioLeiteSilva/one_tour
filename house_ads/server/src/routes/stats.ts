import { Router, Request, Response } from 'express';
import { query } from '../db.js';

export const statsRouter = Router();

statsRouter.get('/performance', async (_req: Request, res: Response) => {
  const sql = `
    SELECT 
      ad_id,
      uf,
      position,
      impressions_count,
      clicks_count,
      ctr_percentage
    FROM view_ad_performance
    ORDER BY impressions_count DESC;
  `;

  try {
    const result = await query(sql);
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      rows: result.rows,
    });
  } catch (err: any) {
    res.status(500).json({ error: 'Failed to query ad performance', details: err.message });
  }
});
