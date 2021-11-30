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
-- Table structure for table `fc_t11famtable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fc_t11famtable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_t11FamFabricIndex` varchar(255) DEFAULT NULL,
  `fc_t11FamConfigDomainId` varchar(255) DEFAULT NULL,
  `fc_t11FamConfigDomainIdType` varchar(255) DEFAULT NULL,
  `fc_t11FamAutoReconfigure` varchar(255) DEFAULT NULL,
  `fc_t11FamContiguousAllocation` varchar(255) DEFAULT NULL,
  `fc_t11FamPriority` varchar(255) DEFAULT NULL,
  `fc_t11FamPrincipalSwitchWwn` varchar(255) DEFAULT NULL,
  `fc_t11FamLocalSwitchWwn` varchar(255) DEFAULT NULL,
  `fc_t11FamAssignedAreaIdList` varchar(255) DEFAULT NULL,
  `fc_t11FamGrantedFcIds` varchar(255) DEFAULT NULL,
  `fc_t11FamRecoveredFcIds` varchar(255) DEFAULT NULL,
  `fc_t11FamFreeFcIds` varchar(255) DEFAULT NULL,
  `fc_t11FamAssignedFcIds` varchar(255) DEFAULT NULL,
  `fc_t11FamAvailableFcIds` varchar(255) DEFAULT NULL,
  `fc_t11FamRunningPriority` varchar(255) DEFAULT NULL,
  `fc_t11FamPrincSwRunningPriority` varchar(255) DEFAULT NULL,
  `fc_t11FamState` varchar(255) DEFAULT NULL,
  `fc_t11FamLocalPrincipalSwitchSlctns` varchar(255) DEFAULT NULL,
  `fc_t11FamPrincipalSwitchSelections` varchar(255) DEFAULT NULL,
  `fc_t11FamBuildFabrics` varchar(255) DEFAULT NULL,
  `fc_t11FamFabricReconfigures` varchar(255) DEFAULT NULL,
  `fc_t11FamDomainId` varchar(255) DEFAULT NULL,
  `fc_t11FamSticky` varchar(255) DEFAULT NULL,
  `fc_t11FamRestart` varchar(255) DEFAULT NULL,
  `fc_t11FamRcFabricNotifyEnable` varchar(255) DEFAULT NULL,
  `fc_t11FamEnable` varchar(255) DEFAULT NULL,
  `fc_t11FamFabricName` varchar(255) DEFAULT NULL,
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
