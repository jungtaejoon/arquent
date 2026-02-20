import nacl from 'tweetnacl';
function toBytesBase64(value) {
    try {
        return Buffer.from(value, 'base64');
    }
    catch {
        return null;
    }
}
export function verifyPackageSignature(params) {
    const signature = toBytesBase64(params.signatureBase64);
    const publicKey = toBytesBase64(params.publicKeyBase64);
    if (!signature || !publicKey) {
        return false;
    }
    if (signature.length != 64 || publicKey.length != 32) {
        return false;
    }
    const message = Buffer.from(params.digestHex, 'utf8');
    try {
        return nacl.sign.detached.verify(message, signature, publicKey);
    }
    catch {
        return false;
    }
}
