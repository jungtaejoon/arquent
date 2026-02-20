use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::engine::policy::TriggerClass;
use crate::types::errors::RuntimeError;

pub struct HealthConnector;

impl Connector for HealthConnector {
    fn name(&self) -> &str {
        "health"
    }

    fn supports(&self) -> Vec<String> {
        vec!["health.read".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.metadata.trigger_class != TriggerClass::UserInitiated {
            return Err(RuntimeError::UserInitiationRequired);
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({
                "date": "2026-02-19",
                "sleep_hours": 6.2,
                "steps": 8450
            }),
        })
    }
}
