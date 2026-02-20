use std::collections::HashMap;

use crate::types::datavalue::DataValue;

/// In-memory state map scoped by recipe.
#[derive(Debug, Default, Clone)]
pub struct StateStore {
    values: HashMap<String, DataValue>,
}

impl StateStore {
    pub fn get(&self, key: &str) -> Option<&DataValue> {
        self.values.get(key)
    }

    pub fn set(&mut self, key: impl Into<String>, value: DataValue) {
        self.values.insert(key.into(), value);
    }
}
