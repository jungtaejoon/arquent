pub mod camera;
pub mod clipboard;
pub mod file;
pub mod health;
pub mod hotkey;
pub mod http;
pub mod kv;
pub mod manual;
pub mod microphone;
pub mod notification;
pub mod time;
pub mod webcam;

use serde::{Deserialize, Serialize};

use crate::recipe::manifest::PermissionSet;
use crate::types::context::ExecutionMetadata;
use crate::types::errors::RuntimeError;

/// Connector invocation payload.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectorRequest {
    pub action_type: String,
    pub params: serde_json::Value,
    pub metadata: ExecutionMetadata,
    pub permission_snapshot: PermissionSet,
}

/// Connector response payload.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectorResponse {
    pub output: serde_json::Value,
}

pub type ConnectorError = RuntimeError;

/// Platform connector contract.
pub trait Connector {
    fn name(&self) -> &str;
    fn supports(&self) -> Vec<String>;
    fn execute(&self, req: ConnectorRequest) -> Result<ConnectorResponse, ConnectorError>;
}
