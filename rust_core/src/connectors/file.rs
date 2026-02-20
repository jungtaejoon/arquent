use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::engine::sandbox::enforce_file_sandbox;
use crate::types::errors::RuntimeError;

pub struct FileConnector;

impl Connector for FileConnector {
    fn name(&self) -> &str {
        "file"
    }

    fn supports(&self) -> Vec<String> {
        vec![
            "file.read".to_string(),
            "file.write".to_string(),
            "file.move".to_string(),
            "file.rename".to_string(),
        ]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        let uri = req
            .params
            .get("uri")
            .and_then(serde_json::Value::as_str)
            .ok_or_else(|| RuntimeError::SchemaValidation("file action missing uri".to_string()))?;
        enforce_file_sandbox(uri, &req.permission_snapshot)?;
        Ok(ConnectorResponse {
            output: serde_json::json!({"ok": true}),
        })
    }
}
