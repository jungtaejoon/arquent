use thiserror::Error;

/// Typed runtime errors for deterministic policy enforcement.
#[derive(Debug, Error)]
pub enum RuntimeError {
    #[error("permission denied: {reason}")]
    PermissionDenied { reason: String, code: String },
    #[error("user initiation required")]
    UserInitiationRequired,
    #[error("sandbox violation: {0}")]
    SandboxViolation(String),
    #[error("schema validation failed: {0}")]
    SchemaValidation(String),
    #[error("signature invalid")]
    SignatureInvalid,
    #[error("connector error: {0}")]
    Connector(String),
    #[error("storage error: {0}")]
    Storage(String),
    #[error("serialization error: {0}")]
    Serialization(String),
}

pub type RuntimeResult<T> = Result<T, RuntimeError>;
