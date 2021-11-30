CREATE TABLE IF NOT EXISTS `windowsdnscache` (
  `id` bigint(40) unsigned NOT NULL AUTO_INCREMENT,
  `deviceid` bigint(40) unsigned NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `ip` varchar(45) NOT NULL,
  `type` varchar(8) NOT NULL,
  `scantime` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `deviceid_idx` (`deviceid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
