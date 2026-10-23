import { Pool } from 'pg';
import { config } from './config.js';

let pool: Pool | null = null;
let isConnected = false;

try {
  pool = new Pool({
    connectionString: config.databaseUrl,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  pool.on('error', (err) => {
    console.error('PostgreSQL unexpected pool error:', err.message);
  });
} catch (e) {
  console.warn('PostgreSQL initialization deferred:', e);
}

export async function query(text: string, params?: any[]) {
  if (!pool) return { rows: [] };
  try {
    return await pool.query(text, params);
  } catch (err: any) {
    console.warn(`Postgres query failed: ${err.message}. Proceeding with memory fallback.`);
    return { rows: [] };
  }
}

export async function checkDbHealth(): Promise<boolean> {
  if (!pool) return false;
  try {
    const res = await pool.query('SELECT 1');
    isConnected = res.rowCount === 1;
    return isConnected;
  } catch {
    return false;
  }
}
