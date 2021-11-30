-- service configuration
-- configuration files and data relating to services running on collection source

CREATE TABLE IF NOT EXISTS service_configuration (
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	tstamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	service		VARCHAR(255) NOT NULL,
	content_type	VARCHAR(255) NOT NULL,
	content_source	VARCHAR(255) NOT NULL,
	content		LONGTEXT NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
