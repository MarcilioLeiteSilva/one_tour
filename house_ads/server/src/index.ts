import express, { Request, Response } from 'express';
import cors from 'cors';
import { config } from './config.js';
import { checkDbHealth } from './db.js';
import { runMigrations } from './migrate.js';
import { startRankingsJob } from './rankings.js';
import { adsRouter } from './routes/ads.js';
import { trackRouter } from './routes/track.js';
import { telemetryRouter } from './routes/telemetry.js';
import { rankingsRouter } from './routes/places.js';
import { adminRouter } from './routes/admin.js';
import { packsRouter } from './routes/packs.js';

const app = express();

// Atrás do proxy do Easypanel: usa o IP real do cliente (rate limit).
app.set('trust proxy', 1);

// Apps móveis não enviam Origin; navegadores só são aceitos se estiverem na lista.
app.use(
  cors({
    origin: (origin, cb) => {
      if (!origin || config.allowedOrigins.includes(origin)) cb(null, true);
      else cb(null, false);
    },
    allowedHeaders: ['Content-Type', 'Authorization'],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  }),
);
app.use(express.json({ limit: '256kb' }));

// Health Check
app.get('/health', async (_req: Request, res: Response) => {
  const dbOk = await checkDbHealth();
  res.status(dbOk ? 200 : 503).json({
    status: dbOk ? 'ok' : 'degraded',
    service: 'one-tour-api',
    version: '2.0.0',
    dbConnected: dbOk,
    timestamp: new Date().toISOString(),
  });
});

// Público (app mobile)
app.use('/api/v1/ads/track', trackRouter);
app.use('/api/v1/ads', adsRouter);
app.use('/api/v1/telemetry', telemetryRouter);
app.use('/api/v1/places', rankingsRouter);
app.use('/api/v1/packs', packsRouter);

// Protegido (admin web, token do PocketBase)
app.use('/api/v1/admin', adminRouter);

async function main() {
  if (!config.db.url && !config.db.password) {
    console.warn('⚠️  PGPASSWORD não definida: a conexão com o PostgreSQL provavelmente falhará.');
  }

  app.listen(config.port, () => {
    console.log(`🚀 One Tour API na porta ${config.port} [${config.nodeEnv}]`);
  });

  // Migrações e job rodam em segundo plano com nova tentativa, para a API subir
  // mesmo se o Postgres ainda estiver inicializando.
  const bootstrap = async (attempt = 1): Promise<void> => {
    try {
      await runMigrations();
      startRankingsJob(config.rankingsIntervalMin);
    } catch (err) {
      console.error(`❌ Bootstrap do banco falhou (tentativa ${attempt}): ${(err as Error).message}`);
      if (attempt < 10) setTimeout(() => void bootstrap(attempt + 1), 10_000);
    }
  };
  void bootstrap();
}

void main();
