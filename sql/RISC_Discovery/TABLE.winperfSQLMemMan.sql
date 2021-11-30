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
-- Table structure for table `winperfSQLMemMan`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfSQLMemMan` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `instancename` text,
  `caption` varchar(255) DEFAULT NULL,
  `connectionmemorykb` int(10) unsigned DEFAULT NULL,
  `databasecachememorykb` int(10) unsigned DEFAULT NULL,
  `description` text,
  `externalbenefitofmemory` bigint(40) unsigned DEFAULT NULL,
  `freememorykb` int(10) unsigned DEFAULT NULL,
  `grantedworkspacememorykb` bigint(40) unsigned DEFAULT NULL,
  `lockblocks` bigint(40) unsigned DEFAULT NULL,
  `lockblocksallocated` bigint(40) unsigned DEFAULT NULL,
  `lockmemorykb` int(10) unsigned DEFAULT NULL,
  `lockownerblocks` bigint(40) unsigned DEFAULT NULL,
  `lockownerblocksallocated` bigint(40) unsigned DEFAULT NULL,
  `logpoolmemorykb` int(10) unsigned DEFAULT NULL,
  `maximumworkspacememorykb` bigint(40) unsigned DEFAULT NULL,
  `memorygrantsoutstanding` bigint(40) unsigned DEFAULT NULL,
  `memorygrantspending` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `optimizermemorykb` int(10) unsigned DEFAULT NULL,
  `reservedservermemorykb` bigint(40) unsigned DEFAULT NULL,
  `sqlcachememorykb` int(10) unsigned DEFAULT NULL,
  `stolenservermemorykb` bigint(40) unsigned DEFAULT NULL,
  `targetservermemorykb` bigint(40) unsigned DEFAULT NULL,
  `totalservermemorykb` bigint(40) unsigned DEFAULT NULL,
  KEY `Index_1` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
