-- gensrv_install_path
--
-- Contains each distinct file path reported by installed packages.
-- Unique on path, but uniqueness is enforced by application logic rather
-- than schema for reasons of key length.

CREATE TABLE IF NOT EXISTS gensrv_install_path (
	path_id		BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	path		TEXT NOT NULL,
	PRIMARY KEY	(path_id),
	INDEX           `idx_path` (path(1024))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
