CREATE TABLE IF NOT EXISTS `ip_exclusion_list` (
  `exclusion_id` bigint NOT NULL AUTO_INCREMENT,
  `ip` varchar(255) DEFAULT NULL,
  `user` varchar(255) DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`exclusion_id`),
  UNIQUE KEY `ip` (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
