use crate::recipe::flow::Expression;
use crate::types::datavalue::DataValue;

/// Evaluates expression DSL against key-value scope.
pub fn evaluate_expression(expr: &Expression, scope: &std::collections::HashMap<String, DataValue>) -> bool {
    match expr {
        Expression::Literal(v) => *v,
        Expression::Eq { left, right } => {
            let left_value = scope.get(left);
            let right_value = scope.get(right);
            left_value == right_value
        }
        Expression::Exists { key } => scope.contains_key(key),
        Expression::Not(inner) => !evaluate_expression(inner, scope),
        Expression::And(values) => values.iter().all(|item| evaluate_expression(item, scope)),
        Expression::Or(values) => values.iter().any(|item| evaluate_expression(item, scope)),
    }
}
