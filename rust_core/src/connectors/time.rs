use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::types::errors::RuntimeError;

pub struct TimeConnector;

impl Connector for TimeConnector {
    fn name(&self) -> &str {
        "time"
    }

    fn supports(&self) -> Vec<String> {
        vec!["trigger.schedule".to_string()]
    }

    fn execute(&self, _req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        Err(RuntimeError::Connector(
            "time connector trigger execution is orchestrator-owned".to_string(),
        ))
    }
}
