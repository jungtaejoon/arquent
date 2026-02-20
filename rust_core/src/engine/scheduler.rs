/// Scheduler trigger debounce/backpressure defaults.
#[derive(Debug, Clone)]
pub struct SchedulerPolicy {
    pub debounce_ms: u64,
    pub max_pending_runs: usize,
}

impl Default for SchedulerPolicy {
    fn default() -> Self {
        Self {
            debounce_ms: 500,
            max_pending_runs: 10,
        }
    }
}
