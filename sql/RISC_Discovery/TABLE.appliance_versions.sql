CREATE TABLE IF NOT EXISTS appliance_versions (
	`dist`          VARCHAR(255) NOT NULL UNIQUE,
	`version`       INT NOT NULL DEFAULT 0,
	`notes`         VARCHAR(1024) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
