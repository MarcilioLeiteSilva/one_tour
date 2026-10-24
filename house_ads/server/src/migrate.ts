import fs from 'node:fs';
import path from 'node:path';
import { pool } from './db.js';

// dist/migrate.js -> ../migrations
const MIGRATIONS_DIR = path.resolve(__dirname, '..', 'migrations');
const LOCK_ID = 727001; // advisory lock: impede migrações concorrentes

/** Aplica, em ordem, as migrações .sql ainda não registradas. */
export async function runMigrations(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_ID]);
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name        TEXT PRIMARY KEY,
        applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    const applied = new Set<string>(
      (await client.query('SELECT name FROM schema_migrations')).rows.map((r) => r.name),
    );

    const files = fs
      .readdirSync(MIGRATIONS_DIR)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      if (applied.has(file)) continue;
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
      console.log(`🗄️  Aplicando migração ${file}...`);
      try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
        await client.query('COMMIT');
        console.log(`✅ Migração ${file} aplicada.`);
      } catch (err) {
        await client.query('ROLLBACK').catch(() => undefined);
        throw new Error(`Falha na migração ${file}: ${(err as Error).message}`);
      }
    }
  } finally {
    await client.query('SELECT pg_advisory_unlock($1)', [LOCK_ID]).catch(() => undefined);
    client.release();
  }
}
