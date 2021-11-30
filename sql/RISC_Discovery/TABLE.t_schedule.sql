-- t_schedule
-- scheduled discovery schedule table

CREATE TABLE IF NOT EXISTS t_schedule (
	schedule_id     INTEGER NOT NULL AUTO_INCREMENT,
	is_running      INTEGER DEFAULT 0,
	run_time        DATETIME,
	last_run        DATETIME,
	end_date        DATETIME,
	recurrence      INTEGER DEFAULT 0,
	date_modified   DATETIME,
	date_created    DATETIME,
	PRIMARY KEY (schedule_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
