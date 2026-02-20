/// SQLite schema migration statements.
pub const MIGRATIONS: &[&str] = &[
    "CREATE TABLE IF NOT EXISTS recipes (id TEXT PRIMARY KEY, manifest TEXT NOT NULL, flow TEXT NOT NULL, enabled INTEGER NOT NULL, scope TEXT NOT NULL)",
    "CREATE TABLE IF NOT EXISTS permissions_grants (recipe_id TEXT PRIMARY KEY, grants_json TEXT NOT NULL)",
    "CREATE TABLE IF NOT EXISTS execution_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, recipe_id TEXT NOT NULL, run_id TEXT NOT NULL, log_json TEXT NOT NULL, created_at TEXT NOT NULL)",
    "CREATE TABLE IF NOT EXISTS state_kv (recipe_id TEXT NOT NULL, key TEXT NOT NULL, value_json TEXT NOT NULL, PRIMARY KEY(recipe_id, key))",
    "CREATE TABLE IF NOT EXISTS trigger_bindings (recipe_id TEXT NOT NULL, trigger_type TEXT NOT NULL, binding_json TEXT NOT NULL)",
    "CREATE TABLE IF NOT EXISTS policy_settings (id INTEGER PRIMARY KEY CHECK (id = 1), settings_json TEXT NOT NULL)",
];
