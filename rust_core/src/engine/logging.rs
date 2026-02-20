use serde::{Deserialize, Serialize};

/// Execution log record with sensitive usage marker.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ExecutionLog {
    pub recipe_id: String,
    pub run_id: String,
    pub status: String,
    pub sensitive_used: bool,
    pub reason_code: Option<String>,
    pub timestamp: String,
}

/// Indicates whether any action consumed Sensitive permission.
pub fn detect_sensitive_usage(action_types: &[String]) -> bool {
    action_types.iter().any(|action| {
        matches!(
            action.as_str(),
            "camera.capture" | "microphone.record" | "webcam.capture" | "health.read" | "health.export"
        )
    })
}
