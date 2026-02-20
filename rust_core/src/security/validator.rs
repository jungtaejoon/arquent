use crate::engine::risk::RiskLevel;
use crate::recipe::manifest::Manifest;
use crate::types::errors::{RuntimeError, RuntimeResult};

/// Marketplace validation for publish workflow.
pub fn validate_publish_policy(manifest: &Manifest, public_marketplace: bool) -> RuntimeResult<()> {
    if manifest.signature.is_none() {
        return Err(RuntimeError::SignatureInvalid);
    }

    if public_marketplace && manifest.risk_level == RiskLevel::Sensitive {
        let verified = manifest
            .publisher
            .as_ref()
            .map(|publisher| publisher.verified)
            .unwrap_or(false);
        if !verified {
            return Err(RuntimeError::PermissionDenied {
                reason: "sensitive recipes require verified publisher".to_string(),
                code: "VERIFIED_PUBLISHER_REQUIRED".to_string(),
            });
        }
        if !manifest.user_initiated_required {
            return Err(RuntimeError::PermissionDenied {
                reason: "sensitive recipes must set user_initiated_required".to_string(),
                code: "USER_INITIATED_DECLARATION_REQUIRED".to_string(),
            });
        }
    }

    Ok(())
}
