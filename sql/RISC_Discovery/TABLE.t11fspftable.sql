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
-- Table structure for table `t11fspftable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `t11fspftable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_t11FspfFabricIndex` varchar(255) DEFAULT NULL,
  `fc_t11FspfMinLsArrival` varchar(255) DEFAULT NULL,
  `fc_t11FspfMinLsInterval` varchar(255) DEFAULT NULL,
  `fc_t11FspfLsRefreshTime` varchar(255) DEFAULT NULL,
  `fc_t11FspfMaxAge` varchar(255) DEFAULT NULL,
  `fc_t11FspfMaxAgeDiscards` varchar(255) DEFAULT NULL,
  `fc_t11FspfPathComputations` varchar(255) DEFAULT NULL,
  `fc_t11FspfChecksumErrors` varchar(255) DEFAULT NULL,
  `fc_t11FspfLsrs` varchar(255) DEFAULT NULL,
  `fc_t11FspfCreateTime` varchar(255) DEFAULT NULL,
  `fc_t11FspfAdminStatus` varchar(255) DEFAULT NULL,
  `fc_t11FspfOperStatus` varchar(255) DEFAULT NULL,
  `fc_t11FspfNbrStateChangNotifyEnable` varchar(255) DEFAULT NULL,
  `fc_t11FspfSetToDefault` varchar(255) DEFAULT NULL,
  `fc_t11FspfStorageType` varchar(255) DEFAULT NULL,
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

-- Dump completed on 2018-06-07 18:11:22
