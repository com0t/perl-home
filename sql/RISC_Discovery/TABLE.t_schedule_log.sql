-- t_schedule_log
-- scheduled discovery run log

CREATE TABLE IF NOT EXISTS t_schedule_log (
	schedule_log_id INTEGER NOT NULL AUTO_INCREMENT,
	schedule_id     INTEGER,
	error_msg       VARCHAR(250),
	start_time      DATETIME,
	end_run         DATETIME,
	PRIMARY KEY (schedule_log_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
