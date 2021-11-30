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
-- Table structure for table `winperfprocess`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfprocess` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `creatingprocessid` int(10) unsigned DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `elapsedtime` bigint(40) unsigned DEFAULT NULL,
  `frequencyobject` bigint(40) unsigned DEFAULT NULL,
  `frequencyperftime` bigint(40) unsigned DEFAULT NULL,
  `frequencysys100ns` bigint(40) unsigned DEFAULT NULL,
  `handlecount` int(10) unsigned DEFAULT NULL,
  `idprocess` int(10) unsigned DEFAULT NULL,
  `iodatabytespersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iodatabytespersec` bigint(40) unsigned DEFAULT NULL,
  `iodataoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iodataoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `iootherbytespersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iootherbytespersec` bigint(40) unsigned DEFAULT NULL,
  `iootheroperationspersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iootheroperationspersec` bigint(40) unsigned DEFAULT NULL,
  `ioreadbytespersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_ioreadbytespersec` bigint(40) unsigned DEFAULT NULL,
  `ioreadoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_ioreadoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `iowritebytespersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iowritebytespersec` bigint(40) unsigned DEFAULT NULL,
  `iowriteoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `cooked_iowriteoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `pagefaultspersec` int(10) unsigned DEFAULT NULL,
  `cooked_pagefaultspersec` int(10) unsigned DEFAULT NULL,
  `pagefilebytes` bigint(40) unsigned DEFAULT NULL,
  `pagefilebytespeak` bigint(40) unsigned DEFAULT NULL,
  `percentprivilegedtime` bigint(40) unsigned DEFAULT NULL,
  `cooked_percentprivilegedtime` bigint(40) unsigned DEFAULT NULL,
  `percentprocessortime` bigint(40) unsigned DEFAULT NULL,
  `cooked_percentprocessortime` bigint(40) unsigned DEFAULT NULL,
  `percentusertime` bigint(40) unsigned DEFAULT NULL,
  `cooked_percentusertime` bigint(40) unsigned DEFAULT NULL,
  `poolnonpagedbytes` int(10) unsigned DEFAULT NULL,
  `poolpagedbytes` int(10) unsigned DEFAULT NULL,
  `prioritybase` int(10) unsigned DEFAULT NULL,
  `privatebytes` bigint(40) unsigned DEFAULT NULL,
  `threadcount` int(10) unsigned DEFAULT NULL,
  `timestampobject` bigint(40) unsigned DEFAULT NULL,
  `timestampperftime` bigint(40) unsigned DEFAULT NULL,
  `timestampsys100ns` bigint(40) unsigned DEFAULT NULL,
  `virtualbytes` bigint(40) unsigned DEFAULT NULL,
  `virtualbytespeak` bigint(40) unsigned DEFAULT NULL,
  `workingset` bigint(40) unsigned DEFAULT NULL,
  `workingsetpeak` bigint(40) unsigned DEFAULT NULL,
  `commandline` varchar(255) DEFAULT NULL,
  `execpath` longtext,
  KEY `Index_1` (`scantime`),
  KEY `Index_2` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
