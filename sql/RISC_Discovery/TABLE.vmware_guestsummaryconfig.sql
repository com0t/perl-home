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
-- Table structure for table `vmware_guestsummaryconfig`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_guestsummaryconfig` (
  `deviceid` bigint(20) unsigned DEFAULT NULL,
  `annotation` varchar(255) DEFAULT NULL,
  `cpureservation` int(10) unsigned DEFAULT NULL,
  `guestfullname` varchar(255) DEFAULT NULL,
  `guestid` varchar(255) DEFAULT NULL,
  `memoryreservation` int(10) unsigned DEFAULT NULL,
  `memorysizemb` int(10) unsigned DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `numcpu` int(10) unsigned DEFAULT NULL,
  `numethernetcards` int(10) unsigned DEFAULT NULL,
  `numvirtualdisks` int(10) unsigned DEFAULT NULL,
  `uuid` varchar(45) DEFAULT NULL,
  `vmpathname` varchar(255) DEFAULT NULL,
  `ipaddress` varchar(45) DEFAULT NULL,
  `toolsstatus` varchar(45) DEFAULT NULL,
  `overallstatus` varchar(45) DEFAULT NULL,
  `boottime` datetime DEFAULT NULL,
  `maxcpuusage` int(10) unsigned DEFAULT NULL,
  `maxmemoryusage` int(10) unsigned DEFAULT NULL,
  `memoryoverhead` bigint(40) DEFAULT NULL,
  `nummksconnections` int(10) unsigned DEFAULT NULL,
  `powerstate` varchar(45) DEFAULT NULL,
  `suspendinterval` int(10) unsigned DEFAULT NULL,
  `suspendtime` datetime DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
  `esxhost` varchar(255) DEFAULT NULL,
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
