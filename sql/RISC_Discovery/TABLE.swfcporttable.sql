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
-- Table structure for table `swfcporttable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `swfcporttable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_swFCPortIndex` varchar(255) DEFAULT NULL,
  `fc_swFCPortType` varchar(255) DEFAULT NULL,
  `fc_swFCPortPhyState` varchar(255) DEFAULT NULL,
  `fc_swFCPortOpStatus` varchar(255) DEFAULT NULL,
  `fc_swFCPortAdmStatus` varchar(255) DEFAULT NULL,
  `fc_swFCPortLinkState` varchar(255) DEFAULT NULL,
  `fc_swFCPortTxType` varchar(255) DEFAULT NULL,
  `fc_swFCPortTxWords` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxWords` varchar(255) DEFAULT NULL,
  `fc_swFCPortTxFrames` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxFrames` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxC2Frames` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxC3Frames` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxLCs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxMcasts` varchar(255) DEFAULT NULL,
  `fc_swFCPortTooManyRdys` varchar(255) DEFAULT NULL,
  `fc_swFCPortNoTxCredits` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxEncInFrs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxCrcs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxTruncs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxTooLongs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxBadEofs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxEncOutFrs` varchar(255) DEFAULT NULL,
  `fc_swFCPortRxBadOs` varchar(255) DEFAULT NULL,
  `fc_swFCPortC3Discards` varchar(255) DEFAULT NULL,
  `fc_swFCPortMcastTimedOuts` varchar(255) DEFAULT NULL,
  `fc_swFCPortTxMcasts` varchar(255) DEFAULT NULL,
  `fc_swFCPortLipIns` varchar(255) DEFAULT NULL,
  `fc_swFCPortLipOuts` varchar(255) DEFAULT NULL,
  `fc_swFCPortLipLastAlpa` varchar(255) DEFAULT NULL,
  `fc_swFCPortWwn` varchar(255) DEFAULT NULL,
  `fc_swFCPortSpeed` varchar(255) DEFAULT NULL,
  `fc_swFCPortName` varchar(255) DEFAULT NULL,
  `fc_swFCPortSpecifier` varchar(255) DEFAULT NULL,
  `fc_swFCPortFlag` varchar(255) DEFAULT NULL,
  `fc_swFCPortBrcdType` varchar(255) DEFAULT NULL,
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
