use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::engine::policy::TriggerClass;
use crate::types::errors::RuntimeError;

pub struct WebcamConnector;

impl Connector for WebcamConnector {
    fn name(&self) -> &str {
        "webcam"
    }

    fn supports(&self) -> Vec<String> {
        vec!["webcam.capture".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.metadata.trigger_class != TriggerClass::UserInitiated {
            return Err(RuntimeError::UserInitiationRequired);
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({"kind": "photo", "uri": "sandbox://captures/webcam.jpg"}),
        })
    }
}
