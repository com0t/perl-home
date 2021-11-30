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
-- Table structure for table `fcmportstatstable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fcmportstatstable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_fcmPortBBCreditZeros` varchar(255) DEFAULT NULL,
  `fc_fcmPortFullInputBuffers` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2Discards` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxFbsyFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxPbsyFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxFrjtFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2RxPrjtFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxFbsyFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxPbsyFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxFrjtFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass2TxPrjtFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass3RxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass3RxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass3TxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass3TxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClass3Discards` varchar(255) DEFAULT NULL,
  `fc_fcmPortClassFRxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClassFRxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClassFTxFrames` varchar(255) DEFAULT NULL,
  `fc_fcmPortClassFTxOctets` varchar(255) DEFAULT NULL,
  `fc_fcmPortClassFDiscards` varchar(255) DEFAULT NULL,
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
