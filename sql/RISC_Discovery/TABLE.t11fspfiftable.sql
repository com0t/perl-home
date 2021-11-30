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
-- Table structure for table `t11fspfiftable`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `t11fspfiftable` (
  `deviceid` bigint(40) NOT NULL,
  `scantime` int(10) NOT NULL,
  `fc_t11FspfIfIndex` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfHelloInterval` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfDeadInterval` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfRetransmitInterval` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfInLsuPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfInLsaPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfOutLsuPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfOutLsaPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfOutHelloPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfInHelloPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfRetransmittedLsuPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfInErrorPkts` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfNbrState` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfNbrDomainId` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfNbrPortIndex` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfAdminStatus` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfCreateTime` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfSetToDefault` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfLinkCostFactor` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfStorageType` varchar(255) DEFAULT NULL,
  `fc_t11FspfIfRowStatus` varchar(255) DEFAULT NULL,
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
