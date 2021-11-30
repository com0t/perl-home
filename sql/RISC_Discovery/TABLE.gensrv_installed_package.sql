-- gensrv_installed_package
--
-- Mapping of packages to collection sources that have those packages installed,
-- with a timestamp of when the package was seen as installed.

CREATE TABLE IF NOT EXISTS gensrv_installed_package (
	installed_id	BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	package_id	BIGINT(40) UNSIGNED NOT NULL,
	dataset_log_id	BIGINT(40) UNSIGNED NOT NULL,
	tstamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY	(installed_id),
	KEY `package_id` (`package_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;
