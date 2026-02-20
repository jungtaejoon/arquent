use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct HttpConnector;

impl Connector for HttpConnector {
    fn name(&self) -> &str {
        "http"
    }

    fn supports(&self) -> Vec<String> {
        vec!["http.request".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.action_type != "http.request" {
            return Err(RuntimeError::Connector("unsupported http action".to_string()));
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({"status": 501, "body": "stub"}),
        })
    }
}
