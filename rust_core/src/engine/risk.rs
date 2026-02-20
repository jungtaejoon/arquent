use serde::{Deserialize, Serialize};

/// Runtime risk classes used by policy and marketplace validation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum RiskLevel {
    Standard,
    Sensitive,
    Restricted,
}
