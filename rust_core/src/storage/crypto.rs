use sha2::{Digest, Sha256};

/// Hashes encrypted payload envelope input.
pub fn hash_blob(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}
