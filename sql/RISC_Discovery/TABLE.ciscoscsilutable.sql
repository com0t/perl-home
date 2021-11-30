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
-- Table structure for table `ciscoscsilutable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `ciscoscsilutable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_ciscoScsiLuIndex` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuDefaultLun` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuWwnName` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuVendorId` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuProductId` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuRevisionId` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuPeripheralType` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuStatus` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuState` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuInCommands` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuReadMegaBytes` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuWrittenMegaBytes` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuInResets` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuOutQueueFullStatus` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuHSInCommands` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuIdIndex` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuIdCodeSet` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuIdAssociation` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuIdType` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiLuIdValue` varchar(255) DEFAULT NULL,
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

-- Dump completed on 2018-06-07 18:11:21
