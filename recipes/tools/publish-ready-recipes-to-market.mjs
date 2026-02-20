#!/usr/bin/env node
import { createHash, generateKeyPairSync, sign } from 'node:crypto';
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

function listRecipeDirs(baseDir) {
  return readdirSync(baseDir)
    .filter((name) => name.endsWith('.recipepkg'))
    .map((name) => join(baseDir, name))
    .sort();
}

function toRawPublicKeyBase64(publicKey) {
  const der = publicKey.export({ format: 'der', type: 'spki' });
  return Buffer.from(der).subarray(-32).toString('base64');
}

async function publishOne(baseUrl, packageDir) {
  const manifestPath = join(packageDir, 'manifest.json');
  const flowPath = join(packageDir, 'flow.json');

  const manifestObj = JSON.parse(readFileSync(manifestPath, 'utf8'));
  manifestObj.signature = null;
  const manifest = JSON.stringify(manifestObj);
  const flow = JSON.stringify(JSON.parse(readFileSync(flowPath, 'utf8')));

  const digestHex = createHash('sha256').update(manifest + flow).digest('hex');
  const { publicKey, privateKey } = generateKeyPairSync('ed25519');
  const signature = sign(null, Buffer.from(digestHex, 'utf8'), privateKey).toString('base64');
  const publicKeyBase64 = toRawPublicKeyBase64(publicKey);

  const response = await fetch(`${baseUrl}/marketplace/publish`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      id: manifestObj.id,
      manifest,
      flow,
      signature,
      publicKey: publicKeyBase64,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`publish failed (${manifestObj.id}): ${text}`);
  }

  return manifestObj.id;
}

async function main() {
  const baseDir = resolve(process.argv[2] ?? 'recipes/ready-v0.3');
  const baseUrl = process.argv[3] ?? 'http://localhost:4000';
  const recipeDirs = listRecipeDirs(baseDir);

  if (recipeDirs.length === 0) {
    throw new Error(`no recipe packages in ${baseDir}`);
  }

  const published = [];
  for (const recipeDir of recipeDirs) {
    const recipeId = await publishOne(baseUrl, recipeDir);
    published.push(recipeId);
    console.log(`published: ${recipeId}`);
  }

  const listRes = await fetch(`${baseUrl}/marketplace/recipes`);
  const listJson = await listRes.json();
  console.log(`total marketplace recipes: ${listJson.recipes.length}`);
  console.log(`published now: ${published.length}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
