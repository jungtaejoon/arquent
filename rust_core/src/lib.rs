//! Core runtime for local-first productivity automation.

pub mod connectors;
pub mod engine;
pub mod ffi;
pub mod recipe;
pub mod security;
pub mod storage;
pub mod types;

#[cfg(test)]
mod tests;
