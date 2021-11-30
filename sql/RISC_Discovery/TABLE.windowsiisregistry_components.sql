CREATE TABLE IF NOT EXISTS `windowsiisregistry_components` (
  `id` bigint(40) unsigned NOT NULL AUTO_INCREMENT,
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned NOT NULL,
  `dataset_log_id` bigint(40) unsigned NOT NULL,
  `value` varchar(128) COLLATE utf8mb4_bin NOT NULL,
  `data` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `deviceid_idx` (`deviceid`),
  KEY `scantime_idx` (`scantime`),
  KEY `value_idx` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
