import crypto from 'node:crypto';

import nacl from 'tweetnacl';
import { describe, expect, test } from 'vitest';

import { buildServer } from '../src/server.js';

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
        manifest: '{"id":"local-shared-recipe"}',
        flow: '{"trigger":{"trigger_type":"trigger.manual"},"actions":[]}',
      },
    });
    expect(publishResponse.statusCode).toBe(200);

    const listResponse = await app.inject({
      method: 'GET',
      url: '/marketplace/recipes',
    });
    expect(listResponse.statusCode).toBe(200);
    expect(listResponse.json().recipes.some((item: { id: string }) => item.id === 'local-shared-recipe')).toBe(true);

    await app.close();
  });
});
