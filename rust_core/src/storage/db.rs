use rusqlite::Connection;

use crate::storage::migrations::MIGRATIONS;
use crate::types::errors::{RuntimeError, RuntimeResult};

/// Opens SQLite and ensures required tables exist.
pub fn initialize_database(path: &str) -> RuntimeResult<Connection> {
    let conn = Connection::open(path).map_err(|err| RuntimeError::Storage(err.to_string()))?;
    for statement in MIGRATIONS {
        conn.execute(statement, [])
            .map_err(|err| RuntimeError::Storage(err.to_string()))?;
    }
    Ok(conn)
}
