-- MySQL dump 10.13  Distrib 5.6.39, for FreeBSD11.1 (amd64)
--
-- Host: db.internal.grond.us    Database: RISC_Discovery
-- ------------------------------------------------------
-- Server version	5.6.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `t11zsservertable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `t11zsservertable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_t11ZsServerFabricIndex` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerCapabilityObject` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerDatabaseStorageType` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerDistribute` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerCommit` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerResult` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerReasonCode` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerReasonCodeExp` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerReasonVendorCode` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerLastChange` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerHardZoning` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerReadFromDatabase` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerOperationMode` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerChangeModeResult` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerDefaultZoneSetting` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerMergeControlSetting` varchar(255) DEFAULT NULL,
  `fc_t11ZsServerDefZoneBroadcast` varchar(255) DEFAULT NULL,
  `snmpindex` varchar(255) DEFAULT NULL,
  KEY `Index_1` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
