#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

import {
  listRecipePackageDirs,
  packageDigestHex,
  parseArgs,
  verifyDigestHex,
} from './_common.mjs';

const args = parseArgs(process.argv);
const baseDir = resolve(args.dir ?? 'recipes/ready-v0.3');
const publicKeyPath = resolve(args.publicKey ?? 'recipes/keys/ed25519_public.pem');

const packages = listRecipePackageDirs(baseDir);
if (packages.length === 0) {
  console.error(`no .recipepkg directories found in ${baseDir}`);
  process.exit(1);
}

let failed = 0;
for (const packageDir of packages) {
  const digestHex = packageDigestHex(packageDir);
  const signaturePath = join(packageDir, 'signature.sig');
  let signatureBase64 = '';
  try {
    signatureBase64 = readFileSync(signaturePath, 'utf8').trim();
  } catch {
    console.error(`missing signature: ${packageDir}`);
    failed += 1;
    continue;
  }

  const ok = verifyDigestHex(publicKeyPath, digestHex, signatureBase64);
  if (ok) {
    console.log(`verified: ${packageDir}`);
  } else {
    console.error(`invalid signature: ${packageDir}`);
    failed += 1;
  }
}

if (failed > 0) {
  process.exit(1);
}
