import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { Pool } from 'pg';
const packages = new Map();
let loaded = false;
let loadedPath = '';
let pgPool = null;
let pgReady = false;
function usePostgres() {
    return Boolean(process.env.DATABASE_URL?.trim());
}
async function ensurePostgresReady() {
    if (!usePostgres()) {
        return;
    }
    if (!pgPool) {
        pgPool = new Pool({ connectionString: process.env.DATABASE_URL });
    }
    if (pgReady) {
        return;
    }
    await pgPool.query(`
    CREATE TABLE IF NOT EXISTS marketplace_packages (
      id TEXT PRIMARY KEY,
      manifest TEXT NOT NULL,
      flow TEXT NOT NULL,
      signature TEXT NOT NULL,
      public_key TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  `);
    pgReady = true;
}
function resolveDbPath() {
    const configured = process.env.MARKETPLACE_DB_PATH?.trim();
    if (configured && configured.length > 0) {
        return configured;
    }
    return path.resolve(process.cwd(), '.data/marketplace.json');
}
function ensureLoaded() {
    const dbPath = resolveDbPath();
    if (loaded && loadedPath == dbPath) {
        return;
    }
    packages.clear();
    loaded = true;
    loadedPath = dbPath;
    if (!existsSync(dbPath)) {
        return;
    }
    try {
        const raw = readFileSync(dbPath, 'utf8');
        const parsed = JSON.parse(raw);
        for (const pkg of parsed) {
            if (!pkg?.id) {
                continue;
            }
            packages.set(pkg.id, pkg);
        }
    }
    catch {
        packages.clear();
    }
}
function persist() {
    ensureLoaded();
    const dir = path.dirname(loadedPath);
    mkdirSync(dir, { recursive: true });
    const payload = JSON.stringify(Array.from(packages.values()), null, 2);
    writeFileSync(loadedPath, payload, 'utf8');
}
export async function putPackage(pkg) {
    if (usePostgres()) {
        await ensurePostgresReady();
        await pgPool.query(`
        INSERT INTO marketplace_packages (id, manifest, flow, signature, public_key, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (id)
        DO UPDATE SET
          manifest = EXCLUDED.manifest,
          flow = EXCLUDED.flow,
          signature = EXCLUDED.signature,
          public_key = EXCLUDED.public_key,
          created_at = EXCLUDED.created_at
      `, [pkg.id, pkg.manifest, pkg.flow, pkg.signature, pkg.publicKey, pkg.createdAt]);
        return;
    }
    ensureLoaded();
    packages.set(pkg.id, pkg);
    persist();
}
export async function getPackage(id) {
    if (usePostgres()) {
        await ensurePostgresReady();
        const result = await pgPool.query(`
        SELECT id, manifest, flow, signature, public_key, created_at
        FROM marketplace_packages
        WHERE id = $1
      `, [id]);
        const row = result.rows[0];
        if (!row) {
            return undefined;
        }
        return {
            id: row.id,
            manifest: row.manifest,
            flow: row.flow,
            signature: row.signature,
            publicKey: row.public_key,
            createdAt: row.created_at,
        };
    }
    ensureLoaded();
    return packages.get(id);
}
export async function listPackages() {
    if (usePostgres()) {
        await ensurePostgresReady();
        const result = await pgPool.query(`
        SELECT id, manifest, flow, signature, public_key, created_at
        FROM marketplace_packages
        ORDER BY created_at DESC
      `);
        return result.rows.map((row) => ({
            id: row.id,
            manifest: row.manifest,
            flow: row.flow,
            signature: row.signature,
            publicKey: row.public_key,
            createdAt: row.created_at,
        }));
    }
    ensureLoaded();
    return Array.from(packages.values());
}
export async function resetStoreForTests() {
    packages.clear();
    loaded = false;
    loadedPath = '';
    pgReady = false;
    if (pgPool) {
        await pgPool.end();
    }
    pgPool = null;
}
