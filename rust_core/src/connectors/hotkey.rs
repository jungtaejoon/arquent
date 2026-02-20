use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct HotkeyConnector;

impl Connector for HotkeyConnector {
    fn name(&self) -> &str {
        "hotkey"
    }

    fn supports(&self) -> Vec<String> {
        vec!["trigger.hotkey".to_string()]
    }

    fn execute(&self, _req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        Err(RuntimeError::Connector(
            "hotkey trigger execution is orchestrator-owned".to_string(),
        ))
    }
}
