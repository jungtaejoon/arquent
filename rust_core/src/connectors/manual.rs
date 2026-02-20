use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct ManualConnector;

impl Connector for ManualConnector {
    fn name(&self) -> &str {
        "manual"
    }

    fn supports(&self) -> Vec<String> {
        vec!["trigger.manual".to_string()]
    }

    fn execute(&self, _req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        Err(RuntimeError::Connector(
            "manual trigger execution is orchestrator-owned".to_string(),
        ))
    }
}
