use serde::{Deserialize, Serialize};

use crate::types::errors::{RuntimeError, RuntimeResult};

/// Trigger classes used to enforce user-initiated capture policies.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TriggerClass {
    UserInitiated,
    Passive,
}

impl TriggerClass {
    pub fn from_wire(value: &str) -> RuntimeResult<Self> {
        match value {
            "userInitiated" | "user_initiated" | "UserInitiated" => Ok(Self::UserInitiated),
            "passive" | "Passive" => Ok(Self::Passive),
            _ => Err(RuntimeError::SchemaValidation(format!(
                "invalid trigger_class: {}",
                value
            ))),
        }
    }
}

/// Runtime proof values provided by host UI/session to authorize sensitive execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct SensitiveRuntimeContext {
    pub ui_session_active: bool,
    pub confirmation_token_exists: bool,
    pub visible_capture_ui: bool,
    pub is_background_execution: bool,
}

impl Default for SensitiveRuntimeContext {
    fn default() -> Self {
        Self {
            ui_session_active: false,
            confirmation_token_exists: false,
            visible_capture_ui: false,
            is_background_execution: false,
        }
    }
}

/// Serialized token proof submitted by host UI before sensitive execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct SensitiveTokenPayload {
    pub id: String,
    pub issued_at: String,
    pub visible_capture_ui: bool,
}

/// Serialized bridge payload from Flutter MethodChannel.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct SensitiveRuntimeProofPayload {
    pub recipe_id: String,
    pub trigger_class: String,
    pub token: SensitiveTokenPayload,
}

/// Parses and validates a runtime proof payload, then maps it to policy context.
pub fn parse_runtime_proof_payload(
    payload_json: &str,
) -> RuntimeResult<(String, TriggerClass, SensitiveRuntimeContext)> {
    let payload: SensitiveRuntimeProofPayload = serde_json::from_str(payload_json)
        .map_err(|err| RuntimeError::SchemaValidation(err.to_string()))?;

    if payload.recipe_id.trim().is_empty() {
        return Err(RuntimeError::SchemaValidation(
            "recipe_id is required".to_string(),
        ));
    }
    if payload.token.id.trim().is_empty() {
        return Err(RuntimeError::SchemaValidation(
            "token.id is required".to_string(),
        ));
    }

    let trigger_class = TriggerClass::from_wire(&payload.trigger_class)?;
    let runtime_context = SensitiveRuntimeContext {
        ui_session_active: true,
        confirmation_token_exists: true,
        visible_capture_ui: payload.token.visible_capture_ui,
        is_background_execution: false,
    };

    Ok((payload.recipe_id, trigger_class, runtime_context))
}

/// Runtime policy toggles for enterprise and sensitive data export.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct PolicySettings {
    pub allow_health_export: bool,
    pub require_visible_capture_ui: bool,
    pub block_background_capture: bool,
    pub health_read_requires_user_initiated: bool,
}

impl Default for PolicySettings {
    fn default() -> Self {
        Self {
            allow_health_export: false,
            require_visible_capture_ui: true,
            block_background_capture: true,
            health_read_requires_user_initiated: true,
        }
    }
}
