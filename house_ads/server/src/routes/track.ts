import { Router, Request, Response } from 'express';
import { withTransaction } from '../db.js';
import { applyEvent } from './telemetry.js';
import { asyncHandler, isDeviceId, rateLimit } from '../middleware.js';

export const trackRouter = Router();

function track(kind: 'ad_impression' | 'ad_click') {
  return asyncHandler(async (req: Request, res: Response) => {
    const { ad_id, uf, city_slug, position, device_id } = req.body || {};
    if (!ad_id || !uf || !position) {
      res.status(400).json({ error: 'Missing required parameters: ad_id, uf, position' });
      return;
    }
    if (!isDeviceId(device_id)) {
      res.status(400).json({ error: 'invalid device_id' });
      return;
    }
    const error = await withTransaction((client) =>
      applyEvent(client, device_id, uf, { kind, ad_id, uf, city_slug, position }),
    );
    if (error) {
      res.status(400).json({ error });
      return;
    }
    res.json({ success: true, event: kind === 'ad_click' ? 'click_recorded' : 'impression_recorded' });
  });
}

trackRouter.post('/impression', rateLimit(300), track('ad_impression'));
trackRouter.post('/click', rateLimit(120), track('ad_click'));
