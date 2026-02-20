use crate::connectors::{Connector, ConnectorRequest, ConnectorResponse};
use crate::engine::policy::TriggerClass;
use crate::types::errors::RuntimeError;

pub struct MicrophoneConnector;

impl Connector for MicrophoneConnector {
    fn name(&self) -> &str {
        "microphone"
    }

    fn supports(&self) -> Vec<String> {
        vec!["microphone.record".to_string()]
    }

    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, RuntimeError> {
        if req.metadata.trigger_class != TriggerClass::UserInitiated {
            return Err(RuntimeError::UserInitiationRequired);
        }
        Ok(ConnectorResponse {
            output: serde_json::json!({"kind": "audio", "uri": "sandbox://captures/audio.m4a"}),
        })
    }
}
