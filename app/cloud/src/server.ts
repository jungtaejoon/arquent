import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import crypto from 'node:crypto';
import { z } from 'zod';

import { verifyPackageSignature } from './signature.js';
import { getPackage, listPackages, putPackage } from './store.js';

function summarizePackage(pkg: {
  id: string;
  manifest: string;
  createdAt: string;
}): {
  id: string;
  name: string;
  description: string;
  usage: string[];
  tags: string[];
  publisher: string;
  createdAt: string;
} {
  let manifest: Record<string, unknown> = {};
  try {
    manifest = JSON.parse(pkg.manifest) as Record<string, unknown>;
  } catch {
    manifest = {};
  }

  const name = typeof manifest.name === 'string' && manifest.name.trim().length > 0
    ? manifest.name.trim()
    : pkg.id;
  const description = typeof manifest.description === 'string'
    ? manifest.description.trim()
    : '';
  const usage = Array.isArray(manifest.usage)
    ? manifest.usage.map((item) => String(item)).filter((item) => item.trim().length > 0)
    : [];
  const tags = Array.isArray(manifest.tags)
    ? manifest.tags
        .map((item) => String(item).trim().toLowerCase())
        .filter((item) => item.length > 0)
    : [];

  let publisher = 'Verified Publisher';
  if (manifest.publisher && typeof manifest.publisher === 'object') {
    const pub = manifest.publisher as Record<string, unknown>;
    if (typeof pub.display_name === 'string' && pub.display_name.trim().length > 0) {
      publisher = pub.display_name.trim();
    }
  }

  return {
    id: pkg.id,
    name,
    description,
    usage,
    tags,
    publisher,
    createdAt: pkg.createdAt,
  };
}

export function buildServer() {
  const app = Fastify({ logger: false });
  const corsOrigin = process.env.CORS_ORIGIN ?? true;
  const webhookBuckets = new Map<string, { windowStart: number; count: number }>();

  app.register(cors, {
    origin: corsOrigin,
    methods: ['GET', 'POST', 'OPTIONS'],
  });

  app.register(rateLimit, {
    max: 60,
    timeWindow: '1 minute',
  });

  const loginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(8),
  });

  app.post('/auth/login', async (request, reply) => {
    const parsed = loginSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: 'invalid_credentials_payload' });
    }
    return reply.send({ token: 'stub-token', user: { email: parsed.data.email } });
  });

  app.get('/healthz', async () => {
    return { ok: true, service: 'arquent-cloud' };
  });

  app.get('/marketplace/recipes', async () => {
    const packages = await listPackages();
    return {
      recipes: packages.map(summarizePackage),
    };
  });

  const publishSchema = z.object({
    id: z.string().min(1),
    manifest: z.string().min(1),
    flow: z.string().min(1),
    signature: z.string().min(1),
    publicKey: z.string().min(1),
  });

  app.post('/marketplace/publish', async (request, reply) => {
    const parsed = publishSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: 'invalid_publish_payload' });
    }

    const digestHex = crypto
      .createHash('sha256')
      .update(parsed.data.manifest + parsed.data.flow)
      .digest('hex');

    const valid = verifyPackageSignature({
      digestHex,
      signatureBase64: parsed.data.signature,
      publicKeyBase64: parsed.data.publicKey,
    });

    if (!valid) {
      return reply.code(400).send({ error: 'invalid_signature' });
    }

    await putPackage({
      id: parsed.data.id,
      manifest: parsed.data.manifest,
      flow: parsed.data.flow,
      signature: parsed.data.signature,
      publicKey: parsed.data.publicKey,
      createdAt: new Date().toISOString(),
    });

    return reply.send({ ok: true });
  });

  app.post('/marketplace/publish-demo', async (_request, reply) => {
    const id = 'community-focus-ping';
    const manifest = JSON.stringify({
      id,
      name: 'Community Focus Ping',
      version: '0.3.0',
      min_runtime_version: '0.3.0',
      required_connectors: ['manual', 'notification'],
      permissions: {
        notification_send: true,
        network_request: null,
        file_access: null,
        clipboard_read: false,
        clipboard_write: false,
        hotkey_register: false,
        camera_capture: null,
        microphone_record: null,
        webcam_capture: null,
        health_read: null,
        health_export: false,
      },
      risk_level: 'Standard',
      user_initiated_required: false,
      signature: null,
      publisher: { id: 'demo', display_name: 'Demo Publisher', verified: true },
      description: 'Send a quick focus reset notification from marketplace demo recipe.',
      usage: [
        'Open Marketplace and install this recipe.',
        'Run from Dashboard.',
        'Check Execution Logs for completion.',
      ],
      tags: ['demo', 'focus', 'notification'],
    });
    const flow = JSON.stringify({
      trigger: { trigger_type: 'trigger.manual', params: {} },
      condition: null,
      actions: [
        {
          id: 'a1',
          action_type: 'notification.send',
          params: { title: 'Focus Check', body: 'Take a 5-minute focus reset.' },
        },
      ],
    });

    const digestHex = crypto.createHash('sha256').update(manifest + flow).digest('hex');
    const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
    const signature = crypto.sign(null, Buffer.from(digestHex, 'utf8'), privateKey);

    const publicDer = publicKey.export({ format: 'der', type: 'spki' });
    const publicKeyBase64 = Buffer.from(publicDer).subarray(-32).toString('base64');
    const signatureBase64 = signature.toString('base64');

    const valid = verifyPackageSignature({
      digestHex,
      signatureBase64,
      publicKeyBase64,
    });
    if (!valid) {
      return reply.code(500).send({ error: 'demo_signature_generation_failed' });
    }

    await putPackage({
      id,
      manifest,
      flow,
      signature: signatureBase64,
      publicKey: publicKeyBase64,
      createdAt: new Date().toISOString(),
    });

    return reply.send({ ok: true, id });
  });

  const publishLocalSchema = z.object({
    id: z.string().min(1),
    manifest: z.string().min(1),
    flow: z.string().min(1),
  });

  app.post('/marketplace/publish-local', async (request, reply) => {
    const parsed = publishLocalSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: 'invalid_publish_local_payload' });
    }

    const digestHex = crypto
      .createHash('sha256')
      .update(parsed.data.manifest + parsed.data.flow)
      .digest('hex');

    const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
    const signature = crypto.sign(null, Buffer.from(digestHex, 'utf8'), privateKey);

    const publicDer = publicKey.export({ format: 'der', type: 'spki' });
    const publicKeyBase64 = Buffer.from(publicDer).subarray(-32).toString('base64');
    const signatureBase64 = signature.toString('base64');

    await putPackage({
      id: parsed.data.id,
      manifest: parsed.data.manifest,
      flow: parsed.data.flow,
      signature: signatureBase64,
      publicKey: publicKeyBase64,
      createdAt: new Date().toISOString(),
    });

    return reply.send({ ok: true, id: parsed.data.id });
  });

  app.get('/marketplace/package/:id', async (request, reply) => {
    const params = request.params as { id: string };
    const pkg = await getPackage(params.id);
    if (!pkg) {
      return reply.code(404).send({ error: 'not_found' });
    }
    return reply.send(pkg);
  });

  app.post(
    '/webhook/:id',
    {
      config: {
        rateLimit: {
          max: 10,
          timeWindow: '1 minute',
        },
      },
    },
    async (request, reply) => {
      const params = request.params as { id: string };

      const now = Date.now();
      const bucket = webhookBuckets.get(params.id);
      if (!bucket || now - bucket.windowStart > 60_000) {
        webhookBuckets.set(params.id, { windowStart: now, count: 1 });
      } else {
        bucket.count += 1;
        if (bucket.count > 10) {
          return reply.code(429).send({ error: 'rate_limit_exceeded' });
        }
      }

      return reply.send({ accepted: true, relayTarget: params.id, payload: request.body });
    }
  );

  app.post('/sync/push', async (request, reply) => {
    return reply.send({ ok: true, accepted: request.body });
  });

  app.get('/sync/pull', async () => {
    const packages = await listPackages();
    return { recipes: packages.map((pkg) => pkg.id) };
  });

  return app;
}

if (process.env.NODE_ENV !== 'test') {
  const app = buildServer();
  const port = Number.parseInt(process.env.PORT ?? '4000', 10);
  const host = process.env.HOST ?? '0.0.0.0';
  app
    .listen({ host, port })
    .catch((err) => {
      app.log.error(err);
      process.exit(1);
    });
}
