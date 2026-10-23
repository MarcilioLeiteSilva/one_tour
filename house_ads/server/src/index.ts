import express, { Request, Response } from 'express';
import cors from 'cors';
import { config } from './config.js';
import { checkDbHealth } from './db.js';
import { adsRouter } from './routes/ads.js';
import { trackRouter } from './routes/track.js';
import { statsRouter } from './routes/stats.js';

const app = express();

app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', async (_req: Request, res: Response) => {
  const dbOk = await checkDbHealth();
  res.json({
    status: 'ok',
    service: 'one-tour-house-ads',
    version: '1.0.0',
    dbConnected: dbOk,
    timestamp: new Date().toISOString(),
  });
});

// House Ads Endpoints
app.use('/api/v1/ads', adsRouter);
app.use('/api/v1/ads/track', trackRouter);
app.use('/api/v1/ads/stats', statsRouter);

app.listen(config.port, () => {
  console.log(`🚀 One Tour House Ads Ad Server running on port ${config.port} [${config.nodeEnv}]`);
  console.log(`📡 Endpoints:`);
  console.log(`   - GET  /api/v1/ads?uf=PE&cidade=recife&posicao=home_card`);
  console.log(`   - POST /api/v1/ads/track/impression`);
  console.log(`   - POST /api/v1/ads/track/click`);
  console.log(`   - GET  /api/v1/ads/stats/performance`);
});
