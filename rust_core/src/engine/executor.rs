use std::collections::HashMap;

use chrono::Utc;

use crate::engine::evaluator::evaluate_expression;
use crate::engine::logging::{detect_sensitive_usage, ExecutionLog};
use crate::engine::permission::{enforce_action_permission, validate_manifest_risk};
use crate::engine::policy::{PolicySettings, SensitiveRuntimeContext};
use crate::engine::sandbox::{validate_action_budget, SandboxLimits};
use crate::ffi::take_runtime_proof;
use crate::recipe::model::RecipeModel;
use crate::recipe::schema::validate_action_schema;
use crate::types::context::ExecutionContext;
use crate::types::datavalue::DataValue;
use crate::types::errors::RuntimeResult;

/// Result from executing a recipe run.
#[derive(Debug, Clone)]
pub struct ExecutionResult {
    pub output: HashMap<String, DataValue>,
    pub log: ExecutionLog,
}

/// Engine execution entry point.
pub fn execute_recipe(
    recipe: &RecipeModel,
    context: &ExecutionContext,
    runtime_context: &SensitiveRuntimeContext,
    policy_settings: &PolicySettings,
    health_external_transmission_enabled: bool,
) -> RuntimeResult<ExecutionResult> {
    validate_manifest_risk(&recipe.manifest, &recipe.flow.actions)?;
    validate_action_budget(recipe.flow.actions.len(), &SandboxLimits::default())?;

    if let Some(condition) = &recipe.flow.condition {
        let mut scope = context.input.clone();
        for (key, value) in &context.state {
            scope.insert(key.clone(), value.clone());
        }
        if !evaluate_expression(condition, &scope) {
            let log = ExecutionLog {
                recipe_id: context.metadata.recipe_id.clone(),
                run_id: context.metadata.run_id.clone(),
                status: "skipped".to_string(),
                sensitive_used: false,
                reason_code: Some("CONDITION_FALSE".to_string()),
                timestamp: Utc::now().to_rfc3339(),
            };
            return Ok(ExecutionResult {
                output: HashMap::new(),
                log,
            });
        }
    }

    for action in &recipe.flow.actions {
        validate_action_schema(action)?;
        enforce_action_permission(
            &recipe.manifest,
            &action.action_type,
            &context.metadata.trigger_class,
            runtime_context,
            policy_settings,
            health_external_transmission_enabled,
        )?;
    }

    let actions: Vec<String> = recipe
        .flow
        .actions
        .iter()
        .map(|action| action.action_type.clone())
        .collect();

    let log = ExecutionLog {
        recipe_id: context.metadata.recipe_id.clone(),
        run_id: context.metadata.run_id.clone(),
        status: "success".to_string(),
        sensitive_used: detect_sensitive_usage(&actions),
        reason_code: None,
        timestamp: Utc::now().to_rfc3339(),
    };

    Ok(ExecutionResult {
        output: HashMap::new(),
        log,
    })
}

/// Convenience entry point that consumes a previously submitted host proof.
pub fn execute_recipe_with_stored_proof(
    recipe: &RecipeModel,
    context: &ExecutionContext,
    policy_settings: &PolicySettings,
    health_external_transmission_enabled: bool,
) -> RuntimeResult<ExecutionResult> {
    let stored = take_runtime_proof(&context.metadata.recipe_id);
    let runtime_context = stored
        .map(|proof| proof.runtime_context)
        .unwrap_or_default();

    execute_recipe(
        recipe,
        context,
        &runtime_context,
        policy_settings,
        health_external_transmission_enabled,
    )
}
