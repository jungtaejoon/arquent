use crate::engine::policy::{PolicySettings, SensitiveRuntimeContext, TriggerClass};
use crate::engine::risk::RiskLevel;
use crate::recipe::flow::ActionNode;
use crate::recipe::manifest::Manifest;
use crate::types::errors::{RuntimeError, RuntimeResult};

fn action_is_sensitive(action_type: &str) -> bool {
    matches!(
        action_type,
        "camera.capture" | "microphone.record" | "webcam.capture" | "health.read"
    )
}

fn action_requires_user_initiation(action_type: &str) -> bool {
    matches!(
        action_type,
        "camera.capture" | "microphone.record" | "webcam.capture" | "health.read"
    )
}

fn action_requires_visible_capture_ui(action_type: &str) -> bool {
    matches!(
        action_type,
        "camera.capture" | "microphone.record" | "webcam.capture"
    )
}

fn manifest_declares_action_permission(manifest: &Manifest, action_type: &str) -> bool {
    match action_type {
        "camera.capture" => manifest.permissions.camera_capture.is_some(),
        "microphone.record" => manifest.permissions.microphone_record.is_some(),
        "webcam.capture" => manifest.permissions.webcam_capture.is_some(),
        "health.read" => manifest.permissions.health_read.is_some(),
        "health.export" => manifest.permissions.health_export,
        "notification.send" => manifest.permissions.notification_send,
        "clipboard.read" => manifest.permissions.clipboard_read,
        "clipboard.write" => manifest.permissions.clipboard_write,
        "http.request" => manifest.permissions.network_request.is_some(),
        "file.read" | "file.write" | "file.move" | "file.rename" => {
            manifest.permissions.file_access.is_some()
        }
        _ => true,
    }
}

/// Validates manifest/flow risk consistency.
pub fn validate_manifest_risk(manifest: &Manifest, actions: &[ActionNode]) -> RuntimeResult<()> {
    let flow_has_sensitive = actions.iter().any(|action| action_is_sensitive(&action.action_type));
    let permission_has_sensitive = manifest.permissions.uses_sensitive();

    if flow_has_sensitive || permission_has_sensitive {
        if manifest.risk_level != RiskLevel::Sensitive {
            return Err(RuntimeError::PermissionDenied {
                reason: "sensitive capabilities require Sensitive risk level".to_string(),
                code: "RISK_LEVEL_MISMATCH".to_string(),
            });
        }
        if !manifest.user_initiated_required {
            return Err(RuntimeError::PermissionDenied {
                reason: "sensitive capabilities require user_initiated_required".to_string(),
                code: "USER_INITIATED_DECLARATION_REQUIRED".to_string(),
            });
        }
    }
    Ok(())
}

/// Enforces runtime invocation constraints for each action.
pub fn enforce_action_permission(
    manifest: &Manifest,
    action_type: &str,
    trigger_class: &TriggerClass,
    runtime_context: &SensitiveRuntimeContext,
    policy_settings: &PolicySettings,
    health_external_transmission_enabled: bool,
) -> RuntimeResult<()> {
    if !manifest_declares_action_permission(manifest, action_type) {
        return Err(RuntimeError::PermissionDenied {
            reason: format!("manifest missing declared permission for action {}", action_type),
            code: "ACTION_PERMISSION_NOT_DECLARED".to_string(),
        });
    }

    if action_requires_user_initiation(action_type) {
        let must_be_user_initiated = action_type != "health.read" || policy_settings.health_read_requires_user_initiated;
        if must_be_user_initiated && *trigger_class != TriggerClass::UserInitiated {
            return Err(RuntimeError::UserInitiationRequired);
        }
        if !runtime_context.ui_session_active && !runtime_context.confirmation_token_exists {
            return Err(RuntimeError::UserInitiationRequired);
        }
    }

    if action_requires_visible_capture_ui(action_type) && policy_settings.require_visible_capture_ui {
        if !runtime_context.visible_capture_ui {
            return Err(RuntimeError::PermissionDenied {
                reason: "visible capture UI is required for sensitive capture".to_string(),
                code: "VISIBLE_CAPTURE_UI_REQUIRED".to_string(),
            });
        }
    }

    if action_requires_visible_capture_ui(action_type)
        && policy_settings.block_background_capture
        && runtime_context.is_background_execution
    {
        return Err(RuntimeError::PermissionDenied {
            reason: "background capture is blocked by policy".to_string(),
            code: "BACKGROUND_CAPTURE_BLOCKED".to_string(),
        });
    }

    if action_type == "health.export" {
        if !manifest.permissions.health_export {
            return Err(RuntimeError::PermissionDenied {
                reason: "manifest missing health.export permission".to_string(),
                code: "HEALTH_EXPORT_DECLARATION_REQUIRED".to_string(),
            });
        }
        if !health_external_transmission_enabled {
            return Err(RuntimeError::PermissionDenied {
                reason: "user has not enabled health external transmission".to_string(),
                code: "HEALTH_EXPORT_USER_TOGGLE_REQUIRED".to_string(),
            });
        }
        if !policy_settings.allow_health_export {
            return Err(RuntimeError::PermissionDenied {
                reason: "enterprise policy blocks health export".to_string(),
                code: "HEALTH_EXPORT_POLICY_BLOCKED".to_string(),
            });
        }
    }

    Ok(())
}
