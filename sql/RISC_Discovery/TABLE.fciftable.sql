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
-- Table structure for table `fciftable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fciftable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_fcIfWwn` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminMode` varchar(255) DEFAULT NULL,
  `fc_fcIfOperMode` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminSpeed` varchar(255) DEFAULT NULL,
  `fc_fcIfBeaconMode` varchar(255) DEFAULT NULL,
  `fc_fcIfPortChannelIfIndex` varchar(255) DEFAULT NULL,
  `fc_fcIfOperStatusCause` varchar(255) DEFAULT NULL,
  `fc_fcIfOperStatusCauseDescr` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminTrunkMode` varchar(255) DEFAULT NULL,
  `fc_fcIfOperTrunkMode` varchar(255) DEFAULT NULL,
  `fc_fcIfAllowedVsanList2k` varchar(255) DEFAULT NULL,
  `fc_fcIfAllowedVsanList4k` varchar(255) DEFAULT NULL,
  `fc_fcIfActiveVsanList2k` varchar(255) DEFAULT NULL,
  `fc_fcIfActiveVsanList4k` varchar(255) DEFAULT NULL,
  `fc_fcIfBbCreditModel` varchar(255) DEFAULT NULL,
  `fc_fcIfHoldTime` varchar(255) DEFAULT NULL,
  `fc_fcIfTransmitterType` varchar(255) DEFAULT NULL,
  `fc_fcIfConnectorType` varchar(255) DEFAULT NULL,
  `fc_fcIfSerialNo` varchar(255) DEFAULT NULL,
  `fc_fcIfRevision` varchar(255) DEFAULT NULL,
  `fc_fcIfVendor` varchar(255) DEFAULT NULL,
  `fc_fcIfSFPSerialIDData` varchar(255) DEFAULT NULL,
  `fc_fcIfPartNumber` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminRxBbCredit` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminRxBbCreditModeISL` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminRxBbCreditModeFx` varchar(255) DEFAULT NULL,
  `fc_fcIfOperRxBbCredit` varchar(255) DEFAULT NULL,
  `fc_fcIfRxDataFieldSize` varchar(255) DEFAULT NULL,
  `fc_fcIfActiveVsanUpList2k` varchar(255) DEFAULT NULL,
  `fc_fcIfActiveVsanUpList4k` varchar(255) DEFAULT NULL,
  `fc_fcIfPortRateMode` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminRxPerfBuffer` varchar(255) DEFAULT NULL,
  `fc_fcIfOperRxPerfBuffer` varchar(255) DEFAULT NULL,
  `fc_fcIfBbScn` varchar(255) DEFAULT NULL,
  `fc_fcIfPortInitStatus` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminRxBbCreditExtended` varchar(255) DEFAULT NULL,
  `fc_fcIfFcTunnelIfIndex` varchar(255) DEFAULT NULL,
  `fc_fcIfServiceState` varchar(255) DEFAULT NULL,
  `fc_fcIfAdminBbScnMode` varchar(255) DEFAULT NULL,
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
