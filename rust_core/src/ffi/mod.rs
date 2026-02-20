use std::collections::HashMap;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::sync::{Mutex, OnceLock};

use chrono::Utc;

use crate::engine::policy::{
    parse_runtime_proof_payload, SensitiveRuntimeContext, TriggerClass,
};

pub const ARQUENT_OK: i32 = 0;
pub const ARQUENT_ERR_NULL_PTR: i32 = 1;
pub const ARQUENT_ERR_INVALID_UTF8: i32 = 2;
pub const ARQUENT_ERR_VALIDATION: i32 = 3;

#[derive(Debug, Clone)]
pub struct RuntimeProofRecord {
    pub recipe_id: String,
    pub trigger_class: TriggerClass,
    pub runtime_context: SensitiveRuntimeContext,
    pub recorded_at: String,
}

static PROOF_STORE: OnceLock<Mutex<HashMap<String, RuntimeProofRecord>>> = OnceLock::new();
static LAST_ERROR: OnceLock<Mutex<String>> = OnceLock::new();

fn proof_store() -> &'static Mutex<HashMap<String, RuntimeProofRecord>> {
    PROOF_STORE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn last_error_store() -> &'static Mutex<String> {
    LAST_ERROR.get_or_init(|| Mutex::new(String::new()))
}

fn set_last_error(message: impl Into<String>) {
    if let Ok(mut error) = last_error_store().lock() {
        *error = message.into();
    }
}

pub fn submit_sensitive_runtime_proof_json(payload_json: &str) -> Result<(), String> {
    let (recipe_id, trigger_class, runtime_context) =
        parse_runtime_proof_payload(payload_json).map_err(|err| err.to_string())?;

    let record = RuntimeProofRecord {
        recipe_id: recipe_id.clone(),
        trigger_class,
        runtime_context,
        recorded_at: Utc::now().to_rfc3339(),
    };

    let mut guard = proof_store().lock().map_err(|_| "proof store lock poisoned".to_string())?;
    guard.insert(recipe_id, record);
    Ok(())
}

pub fn take_runtime_proof(recipe_id: &str) -> Option<RuntimeProofRecord> {
    let mut guard = proof_store().lock().ok()?;
    guard.remove(recipe_id)
}

pub fn last_error_message() -> Option<String> {
    let guard = last_error_store().lock().ok()?;
    if guard.is_empty() {
        None
    } else {
        Some(guard.clone())
    }
}

#[no_mangle]
pub unsafe extern "C" fn arquent_submit_sensitive_runtime_proof(payload_json: *const c_char) -> i32 {
    if payload_json.is_null() {
        set_last_error("payload pointer is null");
        return ARQUENT_ERR_NULL_PTR;
    }

    let c_str = CStr::from_ptr(payload_json);
    let payload = match c_str.to_str() {
        Ok(value) => value,
        Err(err) => {
            set_last_error(err.to_string());
            return ARQUENT_ERR_INVALID_UTF8;
        }
    };

    match submit_sensitive_runtime_proof_json(payload) {
        Ok(()) => {
            set_last_error(String::new());
            ARQUENT_OK
        }
        Err(err) => {
            set_last_error(err);
            ARQUENT_ERR_VALIDATION
        }
    }
}
