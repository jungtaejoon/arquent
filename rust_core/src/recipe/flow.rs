use serde::{Deserialize, Serialize};

/// A single action in execution order.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ActionNode {
    pub id: String,
    pub action_type: String,
    pub params: serde_json::Value,
}

/// Condition expression tree.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "op", content = "args")]
pub enum Expression {
    Literal(bool),
    Eq { left: String, right: String },
    Exists { key: String },
    Not(Box<Expression>),
    And(Vec<Expression>),
    Or(Vec<Expression>),
}

/// Trigger declaration.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct TriggerNode {
    pub trigger_type: String,
    pub params: serde_json::Value,
}

/// Full recipe flow model.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RecipeFlow {
    pub trigger: TriggerNode,
    pub condition: Option<Expression>,
    pub actions: Vec<ActionNode>,
}
