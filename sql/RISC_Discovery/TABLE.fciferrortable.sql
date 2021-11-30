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
-- Table structure for table `fciferrortable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fciferrortable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_fcIfLinkFailures` varchar(255) DEFAULT NULL,
  `fc_fcIfSyncLosses` varchar(255) DEFAULT NULL,
  `fc_fcIfSigLosses` varchar(255) DEFAULT NULL,
  `fc_fcIfPrimSeqProtoErrors` varchar(255) DEFAULT NULL,
  `fc_fcIfInvalidTxWords` varchar(255) DEFAULT NULL,
  `fc_fcIfInvalidCrcs` varchar(255) DEFAULT NULL,
  `fc_fcIfDelimiterErrors` varchar(255) DEFAULT NULL,
  `fc_fcIfAddressIdErrors` varchar(255) DEFAULT NULL,
  `fc_fcIfLinkResetIns` varchar(255) DEFAULT NULL,
  `fc_fcIfLinkResetOuts` varchar(255) DEFAULT NULL,
  `fc_fcIfOlsIns` varchar(255) DEFAULT NULL,
  `fc_fcIfOlsOuts` varchar(255) DEFAULT NULL,
  `fc_fcIfRuntFramesIn` varchar(255) DEFAULT NULL,
  `fc_fcIfJabberFramesIn` varchar(255) DEFAULT NULL,
  `fc_fcIfTxWaitCount` varchar(255) DEFAULT NULL,
  `fc_fcIfFramesTooLong` varchar(255) DEFAULT NULL,
  `fc_fcIfFramesTooShort` varchar(255) DEFAULT NULL,
  `fc_fcIfLRRIn` varchar(255) DEFAULT NULL,
  `fc_fcIfLRROut` varchar(255) DEFAULT NULL,
  `fc_fcIfNOSIn` varchar(255) DEFAULT NULL,
  `fc_fcIfNOSOut` varchar(255) DEFAULT NULL,
  `fc_fcIfFragFrames` varchar(255) DEFAULT NULL,
  `fc_fcIfEOFaFrames` varchar(255) DEFAULT NULL,
  `fc_fcIfUnknownClassFrames` varchar(255) DEFAULT NULL,
  `fc_fcIf8b10bDisparityErrors` varchar(255) DEFAULT NULL,
  `fc_fcIfFramesDiscard` varchar(255) DEFAULT NULL,
  `fc_fcIfELPFailures` varchar(255) DEFAULT NULL,
  `fc_fcIfBBCreditTransistionFromZero` varchar(255) DEFAULT NULL,
  `fc_fcIfEISLFramesDiscard` varchar(255) DEFAULT NULL,
  `fc_fcIfFramingErrorFrames` varchar(255) DEFAULT NULL,
  `fc_fcIfLipF8In` varchar(255) DEFAULT NULL,
  `fc_fcIfLipF8Out` varchar(255) DEFAULT NULL,
  `fc_fcIfNonLipF8In` varchar(255) DEFAULT NULL,
  `fc_fcIfNonLipF8Out` varchar(255) DEFAULT NULL,
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
