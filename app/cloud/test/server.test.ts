import crypto from 'node:crypto';
import { rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

import nacl from 'tweetnacl';
import { afterEach, beforeEach, describe, expect, test } from 'vitest';

import { buildServer } from '../src/server.js';
import { resetStoreForTests } from '../src/store.js';

let dbPath = '';

beforeEach(() => {
  dbPath = path.join(tmpdir(), `arquent-cloud-${Date.now()}-${Math.random().toString(36).slice(2)}.json`);
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

describe('cloud api', () => {
  test('rejects publish with invalid signature', async () => {
    const app = buildServer();
    const response = await app.inject({
      method: 'POST',
      url: '/marketplace/publish',
      payload: {
        id: 'pkg1',
        manifest: 'm',
        flow: 'f',
        signature: 'invalid',
        publicKey: 'invalid',
      },
    });

    expect(response.statusCode).toBe(400);
    await app.close();
  });

  test('accepts publish with valid signature', async () => {
    const app = buildServer();

    const keyPair = nacl.sign.keyPair();
    const manifest = 'manifest-content';
    const flow = 'flow-content';
    const digestHex = crypto.createHash('sha256').update(manifest + flow).digest('hex');
    const signature = nacl.sign.detached(Buffer.from(digestHex, 'utf8'), keyPair.secretKey);

    const response = await app.inject({
      method: 'POST',
      url: '/marketplace/publish',
      payload: {
        id: 'pkg-valid',
        manifest,
        flow,
        signature: Buffer.from(signature).toString('base64'),
        publicKey: Buffer.from(keyPair.publicKey).toString('base64'),
      },
    });

    expect(response.statusCode).toBe(200);
    await app.close();
  });

  test('webhook endpoint rate-limits excessive requests', async () => {
    const app = buildServer();

    let tooManyRequestsSeen = false;
    for (let index = 0; index < 15; index += 1) {
      const response = await app.inject({
        method: 'POST',
        url: '/webhook/test-hook',
        payload: { sequence: index },
      });
      if (response.statusCode === 429) {
        tooManyRequestsSeen = true;
        break;
      }
    }

    expect(tooManyRequestsSeen).toBe(true);
    await app.close();
  });

  test('accepts publish-local and exposes package in recipe list', async () => {
    const app = buildServer();

    const publishResponse = await app.inject({
      method: 'POST',
      url: '/marketplace/publish-local',
      payload: {
        id: 'local-shared-recipe',
        manifest: '{"id":"local-shared-recipe","name":"Local Shared Recipe","description":"Local publish metadata","usage":["Step one","Step two"],"tags":["local","guide"],"publisher":{"display_name":"Local Builder"}}',
        flow: '{"trigger":{"trigger_type":"trigger.manual"},"actions":[]}',
      },
    });
    expect(publishResponse.statusCode).toBe(200);

    const listResponse = await app.inject({
      method: 'GET',
      url: '/marketplace/recipes',
    });
    expect(listResponse.statusCode).toBe(200);
    const recipe = listResponse
      .json()
      .recipes.find((item: { id: string }) => item.id === 'local-shared-recipe');
    expect(recipe).toBeDefined();
    expect(recipe.name).toBe('Local Shared Recipe');
    expect(recipe.description).toBe('Local publish metadata');
    expect(recipe.usage).toEqual(['Step one', 'Step two']);

    await app.close();
  });
});
