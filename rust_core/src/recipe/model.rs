use serde::{Deserialize, Serialize};

use crate::recipe::flow::RecipeFlow;
use crate::recipe::manifest::Manifest;

/// Installed recipe package model.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RecipeModel {
    pub manifest: Manifest,
    pub flow: RecipeFlow,
}
