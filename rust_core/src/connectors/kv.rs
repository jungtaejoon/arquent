use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct KvConnector;

impl Connector for KvConnector {
    fn name(&self) -> &str {
        "kv"
    }

    fn supports(&self) -> Vec<String> {
        vec!["state.get".to_string(), "state.set".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        match req.action_type.as_str() {
            "state.get" => Ok(ConnectorResponse {
                output: serde_json::json!({"value": null}),
            }),
            "state.set" => Ok(ConnectorResponse {
                output: serde_json::json!({"ok": true}),
            }),
            _ => Err(RuntimeError::Connector("unsupported state action".to_string())),
        }
    }
}
