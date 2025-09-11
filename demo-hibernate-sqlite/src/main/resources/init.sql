-- Enforce foreign key constraints
-- PRAGMA foreign_keys = ON;

-- Safer rollback behavior (avoid corruption if app crashes mid-transaction)
-- PRAGMA journal_mode = WAL;

-- PRAGMA locking_mode = NORMAL;
-- PRAGMA locking_mode = EXCLUSIVE;

-- Reduce disk writes while still being safe
-- PRAGMA synchronous = NORMAL;

-- Use temp files in memory instead of disk (optional)
-- PRAGMA temp_store = MEMORY;

-- Optional: make comparisons case-sensitive by default
-- PRAGMA case_sensitive_like = ON;

-- PRAGMA cache_size = -8192;
-- PRAGMA mmap_size = 268435456;
-- PRAGMA journal_size_limit = 67108864;
-- PRAGMA wal_autocheckpoint = 1000;
-- PRAGMA cache_spill = OFF;
-- PRAGMA optimize;