use base64::{engine::general_purpose::STANDARD, Engine as _};
use ed25519_dalek::{Signature, Verifier, VerifyingKey};

use crate::security::hashing::sha256_hex;
use crate::types::errors::{RuntimeError, RuntimeResult};

/// Computes package digest sha256(manifest + flow + assets_manifest_hash).
pub fn package_digest_hex(manifest: &[u8], flow: &[u8], assets_manifest_hash: &str) -> String {
    let mut payload = Vec::new();
    payload.extend_from_slice(manifest);
    payload.extend_from_slice(flow);
    payload.extend_from_slice(assets_manifest_hash.as_bytes());
    sha256_hex(&payload)
}

/// Canonicalizes manifest bytes for signing by forcing `signature = null`.
pub fn canonicalize_manifest_for_digest(manifest: &[u8]) -> RuntimeResult<Vec<u8>> {
    let mut manifest_json: serde_json::Value = serde_json::from_slice(manifest)
        .map_err(|err| RuntimeError::Serialization(err.to_string()))?;

    let manifest_obj = manifest_json
        .as_object_mut()
        .ok_or_else(|| RuntimeError::Serialization("manifest must be a JSON object".to_string()))?;
    manifest_obj.insert("signature".to_string(), serde_json::Value::Null);

    serde_json::to_vec(&manifest_json)
        .map_err(|err| RuntimeError::Serialization(err.to_string()))
}

/// Computes package digest using normalized manifest where `signature` is null.
pub fn package_digest_hex_normalized(
    manifest: &[u8],
    flow: &[u8],
    assets_manifest_hash: &str,
) -> RuntimeResult<String> {
    let canonical_manifest = canonicalize_manifest_for_digest(manifest)?;
    Ok(package_digest_hex(
        canonical_manifest.as_slice(),
        flow,
        assets_manifest_hash,
    ))
}

/// Verifies Ed25519 signature against digest bytes.
pub fn verify_ed25519_signature(
    public_key_b64: &str,
    signature_b64: &str,
    digest_hex: &str,
) -> RuntimeResult<()> {
    let public_key_bytes = STANDARD
        .decode(public_key_b64)
        .map_err(|_| RuntimeError::SignatureInvalid)?;
    let signature_bytes = STANDARD
        .decode(signature_b64)
        .map_err(|_| RuntimeError::SignatureInvalid)?;

    let verifying_key = VerifyingKey::from_bytes(
        public_key_bytes
            .as_slice()
            .try_into()
            .map_err(|_| RuntimeError::SignatureInvalid)?,
    )
    .map_err(|_| RuntimeError::SignatureInvalid)?;
    let signature = Signature::from_slice(signature_bytes.as_slice()).map_err(|_| RuntimeError::SignatureInvalid)?;

    verifying_key
        .verify(digest_hex.as_bytes(), &signature)
        .map_err(|_| RuntimeError::SignatureInvalid)
}

/// Verifies a package signature against normalized package digest.
pub fn verify_recipe_package_signature(
    public_key_b64: &str,
    signature_b64: &str,
    manifest: &[u8],
    flow: &[u8],
    assets_manifest_hash: &str,
) -> RuntimeResult<()> {
    let digest_hex = package_digest_hex_normalized(manifest, flow, assets_manifest_hash)?;
    verify_ed25519_signature(public_key_b64, signature_b64, &digest_hex)
}
