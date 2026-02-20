use serde::{Deserialize, Serialize};

use crate::engine::risk::RiskLevel;

/// Marketplace publisher metadata.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct PublisherMeta {
    pub id: String,
    pub display_name: String,
    pub verified: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct NetworkPermission {
    pub domains: Vec<String>,
    pub max_calls: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FileAccessPermission {
    pub roots: Vec<String>,
    pub ops: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct CameraPermission {
    pub mode: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MicrophonePermission {
    pub max_seconds: u32,
    pub user_initiated_only: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct HealthReadPermission {
    pub types: Vec<String>,
    pub aggregation: String,
}

/// Declarative recipe permission contract.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
pub struct PermissionSet {
    pub notification_send: bool,
    pub network_request: Option<NetworkPermission>,
    pub file_access: Option<FileAccessPermission>,
    pub clipboard_read: bool,
    pub clipboard_write: bool,
    pub hotkey_register: bool,
    pub camera_capture: Option<CameraPermission>,
    pub microphone_record: Option<MicrophonePermission>,
    pub webcam_capture: Option<CameraPermission>,
    pub health_read: Option<HealthReadPermission>,
    pub health_export: bool,
}

impl PermissionSet {
    pub fn uses_sensitive(&self) -> bool {
        self.camera_capture.is_some()
            || self.microphone_record.is_some()
            || self.webcam_capture.is_some()
            || self.health_read.is_some()
    }
}

/// Recipe manifest metadata with risk and policy declarations.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Manifest {
    pub id: String,
    pub name: String,
    pub version: String,
    pub min_runtime_version: String,
    pub required_connectors: Vec<String>,
    pub permissions: PermissionSet,
    pub risk_level: RiskLevel,
    pub user_initiated_required: bool,
    pub signature: Option<String>,
    pub publisher: Option<PublisherMeta>,
}
