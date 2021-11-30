CREATE TABLE IF NOT EXISTS `windowsiisregistry` (
  `id` bigint(40) unsigned NOT NULL AUTO_INCREMENT,
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned NOT NULL,
  `dataset_log_id` bigint(40) unsigned NOT NULL,
  `MajorVersion` smallint(5) unsigned NOT NULL,
  `MinorVersion` smallint(5) unsigned NULL,
  `VersionString` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `SetupString` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `ProductString` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `IISProgramGroup` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `PathWWWRoot` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `InstallPath` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `deviceid_idx` (`deviceid`),
  KEY `version_idx` (`MajorVersion`,`MinorVersion`),
  KEY `scantime_idx` (`scantime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
