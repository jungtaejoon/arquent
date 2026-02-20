use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct NotificationConnector;

impl Connector for NotificationConnector {
    fn name(&self) -> &str {
        "notification"
    }

    fn supports(&self) -> Vec<String> {
        vec!["notification.send".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.action_type != "notification.send" {
            return Err(RuntimeError::Connector("unsupported notification action".to_string()));
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({"ok": true}),
        })
    }
}
