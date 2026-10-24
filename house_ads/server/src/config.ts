import dotenv from 'dotenv';
dotenv.config();

const nodeEnv = process.env.NODE_ENV || 'development';

function list(value: string | undefined): string[] {
  return (value || '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
}

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv,
  isProduction: nodeEnv === 'production',

  // PostgreSQL: variáveis separadas evitam problemas de escape de caracteres
  // especiais (@, $, etc.) na senha. DATABASE_URL, se definida, tem prioridade.
  db: {
    url: process.env.DATABASE_URL || '',
    host: process.env.PGHOST || 'localhost',
    port: parseInt(process.env.PGPORT || '5432', 10),
    database: process.env.PGDATABASE || 'onetour',
    user: process.env.PGUSER || '',
    password: process.env.PGPASSWORD || '',
    ssl: process.env.PGSSL === 'true',
  },

  pocketbaseUrl: process.env.POCKETBASE_URL || 'https://onetour-backend-onetour.gtalg3.easypanel.host',

  // Origens autorizadas a chamar a API pelo navegador (admin web app).
  allowedOrigins: [
    ...list(process.env.ADMIN_ORIGIN),
    ...(nodeEnv === 'production' ? [] : ['http://localhost:5173', 'http://localhost:3000']),
  ],

  rankingsIntervalMin: parseInt(process.env.RANKINGS_INTERVAL_MIN || '10', 10),
};
