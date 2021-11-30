--
-- perf_device_connection_state_log
--
-- Contains a record of each change in the state of performance collection
-- connection attempts a given collection device.

CREATE TABLE IF NOT EXISTS perf_device_connection_state_log (
	id		BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	tstamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	state		TINYINT UNSIGNED NOT NULL,
	PRIMARY KEY	(id)
) ENGINE=InnoDB;

--
-- perf_device_connection_state
--
-- Contains a record for each collection device for which performance collection
-- was attempted, and the boolean state describing whether the connection
-- attempt succeeded or failed.

CREATE TABLE IF NOT EXISTS perf_device_connection_state (
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	state		TINYINT UNSIGNED NOT NULL,
	PRIMARY KEY	(collection_id)
) ENGINE=InnoDB;

DELIMITER //

-- perf_device_connection_state_insert
-- Trigger that creates a log entry when a new entry is created in the state table.

DROP TRIGGER IF EXISTS perf_device_connection_state_insert//

CREATE TRIGGER perf_device_connection_state_insert
AFTER INSERT ON perf_device_connection_state
FOR EACH ROW
BEGIN
	INSERT INTO perf_device_connection_state_log
		(collection_id, state)
	VALUES
		(NEW.collection_id, NEW.state)
	;
END//

-- perf_device_connection_state_update
-- Trigger that creates a log entry when a state record is modified.

DROP TRIGGER IF EXISTS perf_device_connection_state_update//

CREATE TRIGGER perf_device_connection_state_update
AFTER UPDATE ON perf_device_connection_state
FOR EACH ROW
BEGIN
	INSERT INTO perf_device_connection_state_log
		(collection_id, state)
	VALUES
		(NEW.collection_id, NEW.state)
	;
END//

DELIMITER ;

