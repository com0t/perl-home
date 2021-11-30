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
-- Table structure for table `ciscoscsiflowstatstable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `ciscoscsiflowstatstable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_ciscoScsiFlowLunId` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdIos` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdFailedIos` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdTimeouts` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdBlocks` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdMaxBlocks` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdMinTime` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdMaxTime` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdsActive` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrIos` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrFailedIos` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrTimeouts` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrBlocks` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrMaxBlocks` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrMinTime` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrMaxTime` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowWrsActive` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowTestUnitRdys` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRepLuns` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowInquirys` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRdCapacitys` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowModeSenses` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowReqSenses` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRxFc2Frames` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowTxFc2Frames` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowRxFc2Octets` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowTxFc2Octets` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowBusyStatuses` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowStatusResvConfs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowTskSetFulStatuses` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowAcaActiveStatuses` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyNotRdyErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyMedErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyHwErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyIllReqErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyUnitAttErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyDatProtErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyBlankErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyCpAbrtErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyAbrtCmdErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyVolFlowErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowSenseKeyMiscmpErrs` varchar(255) DEFAULT NULL,
  `fc_ciscoScsiFlowAbts` varchar(255) DEFAULT NULL,
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
