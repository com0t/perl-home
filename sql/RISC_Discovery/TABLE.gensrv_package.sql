-- gensrv_package
--
-- Contains distinct installed software packages.
-- Unique on name and version, but uniqueness is enforced by application logic
-- rather than schema for reasons of key length.

CREATE TABLE IF NOT EXISTS gensrv_package (
	package_id	BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	name		VARCHAR(255) NOT NULL,
	version		VARCHAR(255) NOT NULL,
	summary		TEXT NOT NULL,
	PRIMARY KEY	(package_id),
	INDEX		`idx_name_version` (name, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
