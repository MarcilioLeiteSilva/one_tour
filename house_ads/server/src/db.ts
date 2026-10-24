import { Pool, PoolClient, QueryResult } from 'pg';
import { config } from './config.js';

export const pool = new Pool(
  config.db.url
    ? { connectionString: config.db.url, max: 10, idleTimeoutMillis: 30000, connectionTimeoutMillis: 5000 }
    : {
        host: config.db.host,
        port: config.db.port,
        database: config.db.database,
        user: config.db.user,
        password: config.db.password,
        ssl: config.db.ssl ? { rejectUnauthorized: false } : undefined,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      },
);

pool.on('error', (err) => {
  console.error('PostgreSQL unexpected pool error:', err.message);
});

/** Executa uma consulta. Erros são propagados (nada é mascarado). */
export async function query(text: string, params?: any[]): Promise<QueryResult<any>> {
  return pool.query(text, params);
}

/** Executa um bloco dentro de uma transação. */
export async function withTransaction<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw err;
  } finally {
    client.release();
  }
}

export async function checkDbHealth(): Promise<boolean> {
  try {
    const res = await pool.query('SELECT 1');
    return res.rowCount === 1;
  } catch {
    return false;
  }
}
