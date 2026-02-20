use serde::{Deserialize, Serialize};

/// Portable file reference that never exposes raw host paths.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FileRef {
    pub uri: String,
    pub name: String,
    pub mime: String,
    pub size_bytes: u64,
    pub sha256: String,
}

/// Supported media kinds for connector output.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum MediaKind {
    Photo,
    Audio,
    Video,
}

/// Structured media pointer payload.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MediaRef {
    pub kind: MediaKind,
    pub file: FileRef,
    pub duration_ms: Option<u64>,
    pub width: Option<u32>,
    pub height: Option<u32>,
}

/// Typed data contract exchanged across runtime and connectors.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "value")]
pub enum DataValue {
    Text(String),
    Url(String),
    FileRef(FileRef),
    MediaRef(MediaRef),
    Json(serde_json::Value),
    Number(f64),
    Boolean(bool),
    DateTime(String),
    List(Vec<DataValue>),
    Null,
}
