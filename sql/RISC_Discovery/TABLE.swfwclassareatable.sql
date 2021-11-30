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
-- Table structure for table `swfwclassareatable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `swfwclassareatable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_swFwClassAreaIndex` varchar(255) DEFAULT NULL,
  `fc_swFwWriteThVals` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultUnit` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultTimebase` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultLow` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultHigh` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultBufSize` varchar(255) DEFAULT NULL,
  `fc_swFwCustUnit` varchar(255) DEFAULT NULL,
  `fc_swFwCustTimebase` varchar(255) DEFAULT NULL,
  `fc_swFwCustLow` varchar(255) DEFAULT NULL,
  `fc_swFwCustHigh` varchar(255) DEFAULT NULL,
  `fc_swFwCustBufSize` varchar(255) DEFAULT NULL,
  `fc_swFwThLevel` varchar(255) DEFAULT NULL,
  `fc_swFwWriteActVals` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultChangedActs` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultExceededActs` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultBelowActs` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultAboveActs` varchar(255) DEFAULT NULL,
  `fc_swFwDefaultInBetweenActs` varchar(255) DEFAULT NULL,
  `fc_swFwCustChangedActs` varchar(255) DEFAULT NULL,
  `fc_swFwCustExceededActs` varchar(255) DEFAULT NULL,
  `fc_swFwCustBelowActs` varchar(255) DEFAULT NULL,
  `fc_swFwCustAboveActs` varchar(255) DEFAULT NULL,
  `fc_swFwCustInBetweenActs` varchar(255) DEFAULT NULL,
  `fc_swFwValidActs` varchar(255) DEFAULT NULL,
  `fc_swFwActLevel` varchar(255) DEFAULT NULL,
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
