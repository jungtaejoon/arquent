import { rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, expect, test } from 'vitest';
import { listPackages, putPackage, resetStoreForTests } from '../src/store.js';
describe('marketplace store persistence', () => {
    let dbPath = '';
    beforeEach(() => {
        dbPath = path.join(tmpdir(), `arquent-store-${Date.now()}-${Math.random().toString(36).slice(2)}.json`);
        process.env.MARKETPLACE_DB_PATH = dbPath;
        delete process.env.DATABASE_URL;
    });
    afterEach(async () => {
        await resetStoreForTests();
        if (dbPath) {
            rmSync(dbPath, { force: true });
        }
        delete process.env.MARKETPLACE_DB_PATH;
    });
    test('persists packages to disk and reloads after reset', async () => {
        await putPackage({
            id: 'persisted-recipe',
            manifest: '{"id":"persisted-recipe"}',
            flow: '{"trigger":{"trigger_type":"trigger.manual"},"actions":[]}',
            signature: 'sig',
            publicKey: 'pub',
            createdAt: new Date().toISOString(),
        });
        expect((await listPackages()).some((pkg) => pkg.id === 'persisted-recipe')).toBe(true);
        await resetStoreForTests();
        const loaded = await listPackages();
        expect(loaded.some((pkg) => pkg.id === 'persisted-recipe')).toBe(true);
    });
});
