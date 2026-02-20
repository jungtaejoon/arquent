use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct ClipboardConnector;

impl Connector for ClipboardConnector {
    fn name(&self) -> &str {
        "clipboard"
    }

    fn supports(&self) -> Vec<String> {
        vec!["clipboard.read".to_string(), "clipboard.write".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        match req.action_type.as_str() {
            "clipboard.read" => Ok(ConnectorResponse {
                output: serde_json::json!({"text": ""}),
            }),
            "clipboard.write" => Ok(ConnectorResponse {
                output: serde_json::json!({"ok": true}),
            }),
            _ => Err(RuntimeError::Connector("unsupported clipboard action".to_string())),
        }
    }
}
