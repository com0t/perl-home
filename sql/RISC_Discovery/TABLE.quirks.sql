--
-- quirks
-- data store for collection source idiosyncrasies
--

CREATE TABLE IF NOT EXISTS quirks (
	collection_id	BIGINT(40) UNSIGNED NOT NULL,
	payload		TEXT NOT NULL,
	ctime		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	mtime		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (collection_id)
);
