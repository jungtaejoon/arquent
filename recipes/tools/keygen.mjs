#!/usr/bin/env node
import { generateKeyPairSync } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

function parseArgs(argv) {
  const args = {};
  for (let index = 2; index < argv.length; index += 1) {
    const item = argv[index];
    if (!item.startsWith('--')) {
      continue;
    }
    const [key, value] = item.slice(2).split('=');
    args[key] = value ?? 'true';
  }
  return args;
}

const args = parseArgs(process.argv);
const privateKeyPath = resolve(args.privateKey ?? 'recipes/keys/ed25519_private.pem');
const publicKeyPath = resolve(args.publicKey ?? 'recipes/keys/ed25519_public.pem');

const { publicKey, privateKey } = generateKeyPairSync('ed25519');

mkdirSync(dirname(privateKeyPath), { recursive: true });
mkdirSync(dirname(publicKeyPath), { recursive: true });

writeFileSync(
  privateKeyPath,
  privateKey.export({ format: 'pem', type: 'pkcs8' }),
  { encoding: 'utf8', mode: 0o600 }
);
writeFileSync(publicKeyPath, publicKey.export({ format: 'pem', type: 'spki' }), {
  encoding: 'utf8',
});

console.log(`private key: ${privateKeyPath}`);
console.log(`public key:  ${publicKeyPath}`);
