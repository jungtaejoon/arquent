#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use base64::{engine::general_purpose::STANDARD, Engine as _};
    use chrono::Utc;
    use ed25519_dalek::{Signer, SigningKey};
    use rand::RngCore;
    use rand::rngs::OsRng;

    use crate::engine::evaluator::evaluate_expression;
    use crate::engine::executor::execute_recipe_with_stored_proof;
    use crate::engine::logging::detect_sensitive_usage;
    use crate::engine::permission::enforce_action_permission;
    use crate::engine::policy::{
        parse_runtime_proof_payload, PolicySettings, SensitiveRuntimeContext, TriggerClass,
    };
    use crate::engine::risk::RiskLevel;
    use crate::engine::sandbox::{enforce_file_sandbox, enforce_network_allowlist};
    use crate::recipe::flow::{ActionNode, Expression, RecipeFlow, TriggerNode};
    use crate::recipe::manifest::{
        FileAccessPermission, Manifest, NetworkPermission, PermissionSet,
    };
    use crate::recipe::model::RecipeModel;
    use crate::security::signature::{
        package_digest_hex, package_digest_hex_normalized, verify_ed25519_signature,
        verify_recipe_package_signature,
    };
    use crate::types::context::{DeviceMeta, ExecutionContext, ExecutionMetadata};
    use crate::types::datavalue::DataValue;
    use crate::{
        ffi::{last_error_message, submit_sensitive_runtime_proof_json, take_runtime_proof},
    };

    fn sample_manifest() -> Manifest {
        Manifest {
            id: "r1".to_string(),
            name: "sample".to_string(),
            version: "1.0.0".to_string(),
            min_runtime_version: "0.3.0".to_string(),
            required_connectors: vec!["camera".to_string()],
            permissions: PermissionSet {
                camera_capture: Some(crate::recipe::manifest::CameraPermission {
                    mode: "user_initiated_only".to_string(),
                }),
                ..PermissionSet::default()
            },
            risk_level: RiskLevel::Sensitive,
            user_initiated_required: true,
            signature: Some("sig".to_string()),
            publisher: None,
        }
    }

    #[test]
    fn sensitive_action_from_passive_trigger_fails() {
        let manifest = sample_manifest();
        let result = enforce_action_permission(
            &manifest,
            "camera.capture",
            &TriggerClass::Passive,
            &SensitiveRuntimeContext::default(),
            &PolicySettings::default(),
            false,
        );
        assert!(result.is_err());
    }

    #[test]
    fn sensitive_capture_requires_visible_ui() {
        let manifest = sample_manifest();
        let runtime_context = SensitiveRuntimeContext {
            ui_session_active: true,
            confirmation_token_exists: false,
            visible_capture_ui: false,
            is_background_execution: false,
        };
        let result = enforce_action_permission(
            &manifest,
            "camera.capture",
            &TriggerClass::UserInitiated,
            &runtime_context,
            &PolicySettings::default(),
            false,
        );
        assert!(result.is_err());
    }

    #[test]
    fn sensitive_capture_blocks_background_execution() {
        let manifest = sample_manifest();
        let runtime_context = SensitiveRuntimeContext {
            ui_session_active: true,
            confirmation_token_exists: true,
            visible_capture_ui: true,
            is_background_execution: true,
        };
        let result = enforce_action_permission(
            &manifest,
            "webcam.capture",
            &TriggerClass::UserInitiated,
            &runtime_context,
            &PolicySettings::default(),
            false,
        );
        assert!(result.is_err());
    }

    #[test]
    fn file_sandbox_disallows_out_of_root() {
        let permission_set = PermissionSet {
            file_access: Some(FileAccessPermission {
                roots: vec!["sandbox://docs".to_string()],
                ops: vec!["read".to_string()],
            }),
            ..PermissionSet::default()
        };
        let result = enforce_file_sandbox("sandbox://desktop/secret.txt", &permission_set);
        assert!(result.is_err());
    }

    #[test]
    fn network_allowlist_disallows_unknown_domain() {
        let permission_set = PermissionSet {
            network_request: Some(NetworkPermission {
                domains: vec!["api.example.com".to_string()],
                max_calls: 3,
            }),
            ..PermissionSet::default()
        };
        let result = enforce_network_allowlist("https://evil.example.net/path", 0, &permission_set);
        assert!(result.is_err());
    }

    #[test]
    fn signature_validation_round_trip() {
        let mut rng = OsRng;
        let mut secret_key_bytes = [0u8; 32];
        rng.fill_bytes(&mut secret_key_bytes);
        let signing_key = SigningKey::from_bytes(&secret_key_bytes);
        let verifying_key = signing_key.verifying_key();
        let public_key_b64 = STANDARD.encode(verifying_key.as_bytes());

        let digest_hex = package_digest_hex(b"manifest", b"flow", "assets_hash");
        let signature = signing_key.sign(digest_hex.as_bytes());
        let signature_b64 = STANDARD.encode(signature.to_bytes());

        let result = verify_ed25519_signature(&public_key_b64, &signature_b64, &digest_hex);
        assert!(result.is_ok());
    }

    #[test]
    fn normalized_manifest_signature_verification_succeeds() {
        let mut rng = OsRng;
        let mut secret_key_bytes = [0u8; 32];
        rng.fill_bytes(&mut secret_key_bytes);
        let signing_key = SigningKey::from_bytes(&secret_key_bytes);
        let verifying_key = signing_key.verifying_key();
        let public_key_b64 = STANDARD.encode(verifying_key.as_bytes());

        let manifest = serde_json::json!({
            "id": "pkg-1",
            "name": "Pkg",
            "signature": "old-signature",
            "risk_level": "Standard"
        });
        let flow = serde_json::json!({
            "trigger": {"trigger_type": "trigger.manual", "params": {}},
            "condition": null,
            "actions": []
        });

        let manifest_bytes = serde_json::to_vec_pretty(&manifest).unwrap_or_default();
        let flow_bytes = serde_json::to_vec_pretty(&flow).unwrap_or_default();

        let digest_hex = package_digest_hex_normalized(
            manifest_bytes.as_slice(),
            flow_bytes.as_slice(),
            "assets_hash",
        );
        assert!(digest_hex.is_ok());
        let digest_hex = digest_hex.unwrap_or_default();

        let signature = signing_key.sign(digest_hex.as_bytes());
        let signature_b64 = STANDARD.encode(signature.to_bytes());

        let verify_result = verify_recipe_package_signature(
            &public_key_b64,
            &signature_b64,
            manifest_bytes.as_slice(),
            flow_bytes.as_slice(),
            "assets_hash",
        );
        assert!(verify_result.is_ok());
    }

    #[test]
    fn normalized_manifest_signature_verification_rejects_tamper() {
        let mut rng = OsRng;
        let mut secret_key_bytes = [0u8; 32];
        rng.fill_bytes(&mut secret_key_bytes);
        let signing_key = SigningKey::from_bytes(&secret_key_bytes);
        let verifying_key = signing_key.verifying_key();
        let public_key_b64 = STANDARD.encode(verifying_key.as_bytes());

        let manifest = serde_json::json!({
            "id": "pkg-2",
            "name": "Pkg",
            "signature": null,
            "risk_level": "Standard"
        });
        let flow_original = serde_json::json!({
            "trigger": {"trigger_type": "trigger.manual", "params": {}},
            "condition": null,
            "actions": []
        });
        let flow_tampered = serde_json::json!({
            "trigger": {"trigger_type": "trigger.manual", "params": {}},
            "condition": null,
            "actions": [{"id": "a1", "action_type": "notification.send", "params": {}}]
        });

        let manifest_bytes = serde_json::to_vec_pretty(&manifest).unwrap_or_default();
        let flow_original_bytes = serde_json::to_vec_pretty(&flow_original).unwrap_or_default();
        let flow_tampered_bytes = serde_json::to_vec_pretty(&flow_tampered).unwrap_or_default();

        let digest_hex = package_digest_hex_normalized(
            manifest_bytes.as_slice(),
            flow_original_bytes.as_slice(),
            "assets_hash",
        );
        assert!(digest_hex.is_ok());
        let digest_hex = digest_hex.unwrap_or_default();

        let signature = signing_key.sign(digest_hex.as_bytes());
        let signature_b64 = STANDARD.encode(signature.to_bytes());

        let verify_result = verify_recipe_package_signature(
            &public_key_b64,
            &signature_b64,
            manifest_bytes.as_slice(),
            flow_tampered_bytes.as_slice(),
            "assets_hash",
        );
        assert!(verify_result.is_err());
    }

    #[test]
    fn logging_sensitive_marker_present() {
        let used = detect_sensitive_usage(&[
            "notification.send".to_string(),
            "camera.capture".to_string(),
        ]);
        assert!(used);
    }

    #[test]
    fn expression_evaluation_correctness() {
        let mut scope = HashMap::new();
        scope.insert("a".to_string(), DataValue::Text("x".to_string()));
        scope.insert("b".to_string(), DataValue::Text("x".to_string()));

        let expr = Expression::And(vec![
            Expression::Eq {
                left: "a".to_string(),
                right: "b".to_string(),
            },
            Expression::Exists {
                key: "a".to_string(),
            },
        ]);

        assert!(evaluate_expression(&expr, &scope));
    }

    #[test]
    fn executor_logs_sensitive_use_for_camera_flow() {
        let manifest = sample_manifest();
        let flow = RecipeFlow {
            trigger: TriggerNode {
                trigger_type: "trigger.manual".to_string(),
                params: serde_json::json!({}),
            },
            condition: None,
            actions: vec![ActionNode {
                id: "a1".to_string(),
                action_type: "camera.capture".to_string(),
                params: serde_json::json!({}),
            }],
        };
        let model = RecipeModel { manifest, flow };

        let context = ExecutionContext {
            input: HashMap::new(),
            state: HashMap::new(),
            metadata: ExecutionMetadata {
                recipe_id: "r1".to_string(),
                run_id: "run_1".to_string(),
                trigger: "manual".to_string(),
                trigger_class: TriggerClass::UserInitiated,
                started_at: Utc::now().to_rfc3339(),
                device: DeviceMeta {
                    platform: "desktop".to_string(),
                    os_version: "1".to_string(),
                    app_version: "0.3.0".to_string(),
                },
            },
        };

        let runtime_context = SensitiveRuntimeContext {
            ui_session_active: true,
            confirmation_token_exists: false,
            visible_capture_ui: true,
            is_background_execution: false,
        };
        let result = crate::engine::executor::execute_recipe(
            &model,
            &context,
            &runtime_context,
            &PolicySettings::default(),
            false,
        );
        assert!(result.is_ok());
        if let Ok(value) = result {
            assert!(value.log.sensitive_used);
        }
    }

    #[test]
    fn runtime_proof_payload_maps_to_sensitive_context() {
        let payload = serde_json::json!({
            "recipe_id": "demo-sensitive-recipe",
            "trigger_class": "userInitiated",
            "token": {
                "id": "tok_1",
                "issued_at": "2026-02-20T10:00:00Z",
                "visible_capture_ui": true
            }
        })
        .to_string();

        let result = parse_runtime_proof_payload(&payload);
        assert!(result.is_ok());

        if let Ok((recipe_id, trigger_class, runtime_context)) = result {
            assert_eq!(recipe_id, "demo-sensitive-recipe");
            assert_eq!(trigger_class, TriggerClass::UserInitiated);
            assert!(runtime_context.confirmation_token_exists);
            assert!(runtime_context.visible_capture_ui);
        }
    }

    #[test]
    fn runtime_proof_payload_rejects_invalid_trigger() {
        let payload = serde_json::json!({
            "recipe_id": "demo-sensitive-recipe",
            "trigger_class": "unknown",
            "token": {
                "id": "tok_1",
                "issued_at": "2026-02-20T10:00:00Z",
                "visible_capture_ui": true
            }
        })
        .to_string();

        let result = parse_runtime_proof_payload(&payload);
        assert!(result.is_err());
    }

    #[test]
    fn ffi_proof_submission_stores_and_consumes_record() {
        let payload = serde_json::json!({
            "recipe_id": "recipe-proof-1",
            "trigger_class": "userInitiated",
            "token": {
                "id": "tok_2",
                "issued_at": "2026-02-20T10:00:00Z",
                "visible_capture_ui": true
            }
        })
        .to_string();

        let submit = submit_sensitive_runtime_proof_json(&payload);
        assert!(submit.is_ok());

        let stored = take_runtime_proof("recipe-proof-1");
        assert!(stored.is_some());

        let consumed = take_runtime_proof("recipe-proof-1");
        assert!(consumed.is_none());
    }

    #[test]
    fn execute_with_stored_proof_allows_sensitive_run() {
        let manifest = sample_manifest();
        let flow = RecipeFlow {
            trigger: TriggerNode {
                trigger_type: "trigger.manual".to_string(),
                params: serde_json::json!({}),
            },
            condition: None,
            actions: vec![ActionNode {
                id: "a1".to_string(),
                action_type: "camera.capture".to_string(),
                params: serde_json::json!({}),
            }],
        };
        let model = RecipeModel { manifest, flow };

        let context = ExecutionContext {
            input: HashMap::new(),
            state: HashMap::new(),
            metadata: ExecutionMetadata {
                recipe_id: "recipe-proof-2".to_string(),
                run_id: "run_ffi_1".to_string(),
                trigger: "manual".to_string(),
                trigger_class: TriggerClass::UserInitiated,
                started_at: Utc::now().to_rfc3339(),
                device: DeviceMeta {
                    platform: "desktop".to_string(),
                    os_version: "1".to_string(),
                    app_version: "0.3.0".to_string(),
                },
            },
        };

        let payload = serde_json::json!({
            "recipe_id": "recipe-proof-2",
            "trigger_class": "userInitiated",
            "token": {
                "id": "tok_3",
                "issued_at": "2026-02-20T10:00:00Z",
                "visible_capture_ui": true
            }
        })
        .to_string();
        let submit = submit_sensitive_runtime_proof_json(&payload);
        assert!(submit.is_ok());

        let result = execute_recipe_with_stored_proof(
            &model,
            &context,
            &PolicySettings::default(),
            false,
        );
        assert!(result.is_ok());
    }

    #[test]
    fn ffi_submission_invalid_payload_sets_error() {
        let payload = "{}";
        let submit = submit_sensitive_runtime_proof_json(payload);
        assert!(submit.is_err());
        let _ = last_error_message();
    }
}
