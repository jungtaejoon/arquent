import { createHash, createPrivateKey, createPublicKey, sign, verify } from 'node:crypto';
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

export function parseArgs(argv) {
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

function sha256Hex(buffer) {
  return createHash('sha256').update(buffer).digest('hex');
}

function walkFiles(dirPath, out = []) {
  const items = readdirSync(dirPath);
  for (const item of items) {
    const fullPath = join(dirPath, item);
    const info = statSync(fullPath);
    if (info.isDirectory()) {
      walkFiles(fullPath, out);
    } else {
      out.push(fullPath);
    }
  }
  return out;
}

function assetsManifestHash(packageDir) {
  const assetsDir = join(packageDir, 'assets');
  try {
    const info = statSync(assetsDir);
    if (!info.isDirectory()) {
      return sha256Hex(Buffer.from('[]'));
    }
  } catch {
    return sha256Hex(Buffer.from('[]'));
  }

  const files = walkFiles(assetsDir)
    .map((path) => {
      const rel = relative(packageDir, path).replaceAll('\\', '/');
      const hash = sha256Hex(readFileSync(path));
      return { path: rel, sha256: hash };
    })
    .sort((a, b) => a.path.localeCompare(b.path));

  return sha256Hex(Buffer.from(JSON.stringify(files), 'utf8'));
}

export function packageDigestHex(packageDir) {
  const manifestPath = join(packageDir, 'manifest.json');
  const manifestJson = JSON.parse(readFileSync(manifestPath, 'utf8'));
  if (typeof manifestJson === 'object' && manifestJson !== null) {
    manifestJson.signature = null;
  }
  const manifestBytes = Buffer.from(JSON.stringify(manifestJson), 'utf8');
  const flowBytes = readFileSync(join(packageDir, 'flow.json'));
  const assetsHash = assetsManifestHash(packageDir);
  const payload = Buffer.concat([
    manifestBytes,
    flowBytes,
    Buffer.from(assetsHash, 'utf8'),
  ]);
  return sha256Hex(payload);
}

export function signDigestHex(privateKeyPemPath, digestHex) {
  const key = createPrivateKey(readFileSync(privateKeyPemPath, 'utf8'));
  const signature = sign(null, Buffer.from(digestHex, 'utf8'), key);
  return signature.toString('base64');
}

export function verifyDigestHex(publicKeyPemPath, digestHex, signatureBase64) {
  const key = createPublicKey(readFileSync(publicKeyPemPath, 'utf8'));
  const signature = Buffer.from(signatureBase64, 'base64');
  return verify(null, Buffer.from(digestHex, 'utf8'), key, signature);
}

export function listRecipePackageDirs(baseDir) {
  const root = resolve(baseDir);
  return readdirSync(root)
    .map((item) => join(root, item))
    .filter((dirPath) => {
      try {
        return statSync(dirPath).isDirectory() && dirPath.endsWith('.recipepkg');
      } catch {
        return false;
      }
    })
    .sort((a, b) => a.localeCompare(b));
}

export function writeSignatureFile(packageDir, signatureBase64) {
  writeFileSync(join(packageDir, 'signature.sig'), signatureBase64, 'utf8');
}

export function updateManifestSignature(packageDir, signatureBase64) {
  const manifestPath = join(packageDir, 'manifest.json');
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  manifest.signature = signatureBase64;
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
}
