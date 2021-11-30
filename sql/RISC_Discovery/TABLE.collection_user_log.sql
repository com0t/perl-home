-- collection_user_log
-- log of collection events intended for user display


-- collection_user_log_context
-- Dimension table defining each specific message context.
-- The context is the general class of data collection activity the process
-- generating the entry belongs to.
CREATE TABLE IF NOT EXISTS collection_user_log_context (
	context	TINYINT UNSIGNED NOT NULL PRIMARY KEY,
	name	VARCHAR(255) NOT NULL,
	descr	VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO collection_user_log_context
	(context, name, descr)
VALUES
	(1, 'discovery', 'Discovery processes'),
	(2, 'inventory', 'Inventory processes'),
	(3, 'performance', 'Performance collection processes'),
	(4, 'testing', 'User or developer testing processes')
;

-- collection_user_log_level
-- Dimension table defining each specific message level.
-- The level is the severity of the message, corresponding to the common
-- severity levels of loggers.
CREATE TABLE IF NOT EXISTS collection_user_log_level (
	level	TINYINT UNSIGNED NOT NULL PRIMARY KEY,
	name	VARCHAR(255) NOT NULL,
	descr	VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO collection_user_log_level
	(level, name, descr)
VALUES
	(1, 'critical', 'Internal fault or fatal error'),
	(2, 'error', 'External fault or fatal error'),
	(3, 'warn', 'Non-fatal error'),
	(4, 'info', 'Non-error noteworthy condition or event'),
	(5, 'debug', 'Internal non-error condition')
;


-- collection_user_log_category
-- Dimension table defining the broad categories messages relate to.
CREATE TABLE IF NOT EXISTS collection_user_log_category (
	category	TINYINT UNSIGNED NOT NULL PRIMARY KEY,
	name		VARCHAR(255) NOT NULL,
	descr		VARCHAR(255) NOT NULL
);

INSERT IGNORE INTO collection_user_log_category
	(category, name, descr)
VALUES
	(0, 'unclassified',      'Log a support ticket with our team and supply the error details.'),
	(1, 'not-eligible',      'Review firewall configuration and access controls, confirm services are running.'),
	(2, 'not-accessible',    'Review firewall configuration and access controls.'),
	(3, 'bad-credential',    'Review and test/validate credentials on the RN150 appliance.'),
	(4, 'bad-configuration', 'Review the documentation and confirm the system configuration meets the requirements.'),
	(5, 'no-credential',     'Add credentials in the RN150 appliance.'),
	(6, 'appliance-config',  'Log a support ticket with our team and supply the error details.'),
	(7, 'query-failure',     'Review the documentation and confirm the system configuration meets the requirement.'),
	(8, 'runtime-error',     'Log a support ticket with our team and supply the error details.')
;

-- collection_user_log
-- Log of user-facing collection activity messages.
CREATE TABLE IF NOT EXISTS collection_user_log (
	id		BIGINT(40) UNSIGNED NOT NULL AUTO_INCREMENT,
	tstamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	context		TINYINT UNSIGNED NOT NULL,
	level		TINYINT UNSIGNED NOT NULL,
	category	TINYINT UNSIGNED NOT NULL,
	source		VARCHAR(255) NOT NULL,
	collection_id	BIGINT(40) UNSIGNED DEFAULT NULL,
	content		TEXT NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (context)
		REFERENCES collection_user_log_context (context),
	FOREIGN KEY (level)
		REFERENCES collection_user_log_level (level),
	FOREIGN KEY (category)
		REFERENCES collection_user_log_category (category)
) ENGINE=InnoDB;

-- collection_user_log_view
-- View for human inspection of the user log data.
CREATE OR REPLACE VIEW collection_user_log_view
AS
	SELECT	id,
		tstamp,
		ctx.name AS context,
		lvl.name AS level,
		ctg.name AS category,
		source,
		collection_id,
		content
	FROM collection_user_log
	INNER JOIN collection_user_log_context ctx USING (context)
	INNER JOIN collection_user_log_level lvl USING (level)
	INNER JOIN collection_user_log_category ctg USING (category)
	ORDER BY id
;
