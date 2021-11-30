-- gensrv_package_path_map
--
-- Join table mapping each file path to a package containing htat path.
-- Unique on package_id/path_id

CREATE TABLE IF NOT EXISTS gensrv_package_path_map (
	package_path_id	BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	package_id	BIGINT(40) UNSIGNED NOT NULL,
	path_id		BIGINT(40) UNSIGNED NOT NULL,
	PRIMARY KEY	(package_path_id),
	UNIQUE KEY	(package_id, path_id),
	FOREIGN KEY	(package_id)
		REFERENCES gensrv_package (package_id)
		ON DELETE CASCADE,
	FOREIGN KEY	(path_id)
		REFERENCES gensrv_install_path (path_id)
		ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
