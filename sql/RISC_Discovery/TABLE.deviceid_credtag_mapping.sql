-- deviceid_credtag_mapping

CREATE TABLE IF NOT EXISTS deviceid_credtag_mapping (
  id int NOT NULL AUTO_INCREMENT,
  deviceid bigint DEFAULT NULL,
  credtag varchar(45) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
