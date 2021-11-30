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
-- Table structure for table `vmware_compute_resource_summary`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_compute_resource_summary` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `dc` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `iscluster` int(11) DEFAULT NULL,
  `effectivecpu` int(11) DEFAULT NULL,
  `effectivememory` bigint(40) DEFAULT NULL,
  `numcpucores` int(11) DEFAULT NULL,
  `numcputhreads` int(11) DEFAULT NULL,
  `numeffectivehosts` int(11) DEFAULT NULL,
  `numhosts` int(11) DEFAULT NULL,
  `overallstatus` varchar(255) DEFAULT NULL,
  `totalcpu` int(11) DEFAULT NULL,
  `totalmemory` bigint(40) DEFAULT NULL,
  `defaulthardwareversionkey` varchar(255) DEFAULT NULL,
  `spbmenabled` int(11) DEFAULT NULL,
  `vmswapplacement` varchar(255) DEFAULT NULL,
  `resourcepool` varchar(255) DEFAULT NULL,
  `dasConfig_admissionControlEnabled` int(11) DEFAULT NULL,
  `dasConfig_defaultVmSettings_isolationResponse` varchar(255) DEFAULT NULL,
  `dasConfig_defaultVmSettings_restartPriority` varchar(255) DEFAULT NULL,
  `dasConfig_enabled` int(11) DEFAULT NULL,
  `dasConfig_failoverLevel` int(11) DEFAULT NULL,
  `dasConfig_option` text,
  `drsConfig_defaultVmBehavior` varchar(255) DEFAULT NULL,
  `drsConfig_enabled` int(11) DEFAULT NULL,
  `drsConfig_option` text,
  `drsConfig_vmotionRate` int(11) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
