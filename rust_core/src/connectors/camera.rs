use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::engine::policy::TriggerClass;
use crate::types::errors::RuntimeError;

pub struct CameraConnector;

impl Connector for CameraConnector {
    fn name(&self) -> &str {
        "camera"
    }

    fn supports(&self) -> Vec<String> {
        vec!["camera.capture".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.metadata.trigger_class != TriggerClass::UserInitiated {
            return Err(RuntimeError::UserInitiationRequired);
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({"kind": "photo", "uri": "sandbox://captures/photo.jpg"}),
        })
    }
}
