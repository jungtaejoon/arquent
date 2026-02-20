use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::engine::policy::TriggerClass;
use crate::types::datavalue::DataValue;

/// Device metadata attached to each execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct DeviceMeta {
    pub platform: String,
    pub os_version: String,
    pub app_version: String,
}

/// Execution metadata used by policy and connector layers.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ExecutionMetadata {
    pub recipe_id: String,
    pub run_id: String,
    pub trigger: String,
    pub trigger_class: TriggerClass,
    pub started_at: String,
    pub device: DeviceMeta,
}

/// Runtime context for expression and action execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ExecutionContext {
    pub input: HashMap<String, DataValue>,
    pub state: HashMap<String, DataValue>,
    pub metadata: ExecutionMetadata,
}
