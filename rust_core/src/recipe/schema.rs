use crate::recipe::flow::ActionNode;
use crate::types::errors::{RuntimeError, RuntimeResult};

/// Validates action parameter structure and known fields.
pub fn validate_action_schema(action: &ActionNode) -> RuntimeResult<()> {
    match action.action_type.as_str() {
        "http.request" => {
            let obj = action
                .params
                .as_object()
                .ok_or_else(|| RuntimeError::SchemaValidation("http.request expects object params".to_string()))?;
            if !obj.contains_key("url") {
                return Err(RuntimeError::SchemaValidation("http.request missing url".to_string()));
            }
            Ok(())
        }
        "file.read" | "file.write" | "file.move" | "file.rename" => {
            let obj = action
                .params
                .as_object()
                .ok_or_else(|| RuntimeError::SchemaValidation("file action expects object params".to_string()))?;
            if !obj.contains_key("uri") {
                return Err(RuntimeError::SchemaValidation("file action missing uri".to_string()));
            }
            Ok(())
        }
        "camera.capture" | "microphone.record" | "webcam.capture" | "health.read" => Ok(()),
        _ => Ok(()),
    }
}
