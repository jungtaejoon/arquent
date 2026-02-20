#!/usr/bin/env node
import { resolve } from 'node:path';

import {
  listRecipePackageDirs,
  packageDigestHex,
  parseArgs,
  signDigestHex,
  updateManifestSignature,
  writeSignatureFile,
} from './_common.mjs';

const args = parseArgs(process.argv);
const baseDir = resolve(args.dir ?? 'recipes/ready-v0.3');
const privateKeyPath = resolve(args.privateKey ?? 'recipes/keys/ed25519_private.pem');
const updateManifest = (args.updateManifest ?? 'true') === 'true';

const packages = listRecipePackageDirs(baseDir);
if (packages.length === 0) {
  console.error(`no .recipepkg directories found in ${baseDir}`);
  process.exit(1);
}

for (const packageDir of packages) {
  const digestHex = packageDigestHex(packageDir);
  const signatureBase64 = signDigestHex(privateKeyPath, digestHex);
  writeSignatureFile(packageDir, signatureBase64);
  if (updateManifest) {
    updateManifestSignature(packageDir, signatureBase64);
  }
  console.log(`signed: ${packageDir}`);
}
