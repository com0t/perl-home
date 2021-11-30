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
-- Table structure for table `t11fcsplatformtable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `t11fcsplatformtable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_t11FcsPlatformIndex` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformName` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformType` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformNodeNameListIndex` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformMgmtAddrListIndex` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformVendorId` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformProductId` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformProductRevLevel` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformDescription` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformLabel` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformLocation` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformSystemID` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformSysMgmtAddr` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformClusterId` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformClusterMgmtAddr` varchar(255) DEFAULT NULL,
  `fc_t11FcsPlatformFC4Types` varchar(255) DEFAULT NULL,
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
