-- dataset_log
-- Log of all collection attempts per collection-target, including whether
-- that attempt was successful.

CREATE TABLE IF NOT EXISTS dataset_type (
	dataset_id	INT UNSIGNED NOT NULL,
	name		VARCHAR(191) NOT NULL,
	descr		VARCHAR(255) NOT NULL,
	PRIMARY KEY	(dataset_id),
	UNIQUE KEY	(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dataset_log (
	id		BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	dataset_id	INT UNSIGNED NOT NULL,
	success		TINYINT UNSIGNED NOT NULL DEFAULT 0,
	tstamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY	(id),
	FOREIGN KEY	(dataset_id)
		REFERENCES dataset_type (dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE OR REPLACE VIEW dataset_log_view
AS
	SELECT	id,
		collection_id,
		dataset_type.name AS dataset_name,
		success,
		tstamp
	FROM dataset_log
	INNER JOIN dataset_type USING (dataset_id)
;

INSERT IGNORE INTO dataset_type
	(dataset_id, name, descr)
VALUES
	(1, 'inventory', 'The inventory upload type'),
	(2, 'netperf', 'The netperf upload type'),
	(3, 'winperf', 'The winperf upload type'),
	(4, 'ccmperf', 'The ccmperf upload type'),
	(5, 'vmwareperf', 'The vmwareperf upload type'),
	(6, 'gensrvperf', 'The gensrvperf upload type'),
	(7, 'trafwatch', 'The trafwatch upload type'),
	(8, 'logs', 'The logs upload type'),
	(9, 'dbperf', 'The dbperf upload type'),
	(10, 'dbtableperf', 'The dbtableperf upload type'),
	(11, 'aws_perf', 'The aws_perf upload type'),
	(12, 'serviceconfig', 'The serviceconfig upload type'),
	(13, 'installedsoftware', 'The installedsoftware upload type')
;
