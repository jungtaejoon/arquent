use url::Url;

use crate::recipe::manifest::PermissionSet;
use crate::types::errors::{RuntimeError, RuntimeResult};

/// Resource constraints for a single run.
#[derive(Debug, Clone)]
pub struct SandboxLimits {
    pub max_actions_per_run: usize,
    pub max_run_duration_ms: u64,
    pub max_action_cpu_ms: u64,
}

impl Default for SandboxLimits {
    fn default() -> Self {
        Self {
            max_actions_per_run: 20,
            max_run_duration_ms: 2_000,
            max_action_cpu_ms: 200,
        }
    }
}

/// Verifies declared action count and global budgets.
pub fn validate_action_budget(action_count: usize, limits: &SandboxLimits) -> RuntimeResult<()> {
    if action_count > limits.max_actions_per_run {
        return Err(RuntimeError::SandboxViolation(format!(
            "action count {} exceeds {}",
            action_count, limits.max_actions_per_run
        )));
    }
    Ok(())
}

/// Ensures sandbox URI is under allowed roots and blocks traversal patterns.
pub fn enforce_file_sandbox(uri: &str, permission_set: &PermissionSet) -> RuntimeResult<()> {
    if !uri.starts_with("sandbox://") {
        return Err(RuntimeError::SandboxViolation(
            "only sandbox:// URIs are allowed".to_string(),
        ));
    }

    if uri.contains("..") {
        return Err(RuntimeError::SandboxViolation(
            "path traversal is not allowed".to_string(),
        ));
    }

    let roots = permission_set
        .file_access
        .as_ref()
        .map(|f| f.roots.as_slice())
        .ok_or_else(|| RuntimeError::PermissionDenied {
            reason: "file.access permission is missing".to_string(),
            code: "FILE_PERMISSION_REQUIRED".to_string(),
        })?;

    let allowed = roots.iter().any(|root| uri.starts_with(root));
    if !allowed {
        return Err(RuntimeError::SandboxViolation(
            "uri is outside allowed roots".to_string(),
        ));
    }
    Ok(())
}

/// Validates network URL against allowlist and declared call caps.
pub fn enforce_network_allowlist(url: &str, call_index: u32, permission_set: &PermissionSet) -> RuntimeResult<()> {
    let network = permission_set
        .network_request
        .as_ref()
        .ok_or_else(|| RuntimeError::PermissionDenied {
            reason: "network.request permission is missing".to_string(),
            code: "NETWORK_PERMISSION_REQUIRED".to_string(),
        })?;

    if call_index >= network.max_calls {
        return Err(RuntimeError::SandboxViolation(
            "network max_calls exceeded".to_string(),
        ));
    }

    let parsed = Url::parse(url).map_err(|err| RuntimeError::SandboxViolation(err.to_string()))?;
    let host = parsed
        .host_str()
        .ok_or_else(|| RuntimeError::SandboxViolation("missing host".to_string()))?;
    let allowed = network.domains.iter().any(|domain| domain == host);
    if !allowed {
        return Err(RuntimeError::SandboxViolation(
            "domain not in allowlist".to_string(),
        ));
    }
    Ok(())
}
