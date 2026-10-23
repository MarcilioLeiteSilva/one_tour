import { Router, Request, Response } from 'express';
import { getMatchingAds } from '../campaigns.js';

export const adsRouter = Router();

adsRouter.get('/', (req: Request, res: Response) => {
  const uf = (req.query.uf as string) || 'PE';
  const city = (req.query.cidade as string) || (req.query.city as string);
  const position = (req.query.posicao as string) || (req.query.position as string);
  const limit = parseInt((req.query.limit as string) || '5', 10);

  const ads = getMatchingAds({
    uf,
    city,
    position,
    limit,
  });

  res.json({
    success: true,
    uf: uf.toUpperCase(),
    city: city || null,
    position: position || null,
    count: ads.length,
    data: ads,
  });
});
