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
-- Table structure for table `winperfphysdisk`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfphysdisk` (
  `deviceid` bigint(40) DEFAULT NULL,
  `diskname` varchar(40) DEFAULT NULL,
  `percentfreespace` int(10) DEFAULT NULL,
  `freemb` bigint(40) DEFAULT NULL,
  `currentdiskqueuelength` bigint(40) DEFAULT NULL,
  `avgdiskbytesperread` bigint(20) DEFAULT NULL,
  `avgdiskbytesperreadbase` bigint(20) DEFAULT NULL,
  `avgdiskbytespertransfer` bigint(20) DEFAULT NULL,
  `avgdiskbytespertransferbase` bigint(20) DEFAULT NULL,
  `avgdiskbytesperwrite` bigint(20) DEFAULT NULL,
  `avgdiskbytesperwritebase` bigint(20) DEFAULT NULL,
  `avgdiskqueuelength` bigint(20) DEFAULT NULL,
  `avgdiskreadqueuelength` bigint(20) DEFAULT NULL,
  `avgdiskwritequeuelength` bigint(20) DEFAULT NULL,
  `avgdisksecperread` bigint(20) DEFAULT NULL,
  `avgdisksecpertransfer` bigint(20) DEFAULT NULL,
  `avgdisksecperwrite` bigint(20) DEFAULT NULL,
  `diskbytespersec` bigint(20) DEFAULT NULL,
  `diskreadbytespersec` bigint(20) DEFAULT NULL,
  `diskreadspersec` bigint(20) DEFAULT NULL,
  `disktransferspersec` bigint(20) DEFAULT NULL,
  `diskwritebytespersec` bigint(20) DEFAULT NULL,
  `diskwritespersec` bigint(20) DEFAULT NULL,
  `frequencyobject` bigint(20) DEFAULT NULL,
  `frequencyperftime` bigint(20) DEFAULT NULL,
  `frequencysys100ns` bigint(20) DEFAULT NULL,
  `percentdiskreadtime` bigint(20) DEFAULT NULL,
  `percentdiskreadtimebase` bigint(20) DEFAULT NULL,
  `percentdisktime` bigint(20) DEFAULT NULL,
  `percentdisktimebase` bigint(20) DEFAULT NULL,
  `percentdiskwritetime` bigint(20) DEFAULT NULL,
  `percentdiskwritetimebase` bigint(20) DEFAULT NULL,
  `percentidletime` bigint(20) DEFAULT NULL,
  `percentidletimebase` bigint(20) DEFAULT NULL,
  `splitiopersec` bigint(20) DEFAULT NULL,
  `timestampobject` bigint(20) DEFAULT NULL,
  `timestampperftime` bigint(20) DEFAULT NULL,
  `timestampsys100ns` bigint(20) DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `cooked_avgdiskbytesperread` bigint(20) DEFAULT NULL,
  `cooked_avgdiskbytespertransfer` bigint(20) DEFAULT NULL,
  `cooked_avgdiskbytesperwrite` bigint(20) DEFAULT NULL,
  `cooked_avgdiskqueuelength` bigint(20) DEFAULT NULL,
  `cooked_avgdiskreadqueuelength` bigint(20) DEFAULT NULL,
  `cooked_avgdiskwritequeuelength` bigint(20) DEFAULT NULL,
  `cooked_disksecperread` bigint(20) DEFAULT NULL,
  `cooked_disksecperwrite` bigint(20) DEFAULT NULL,
  `cooked_disksecpertransfer` bigint(20) DEFAULT NULL,
  `cooked_diskbytespersec` bigint(20) DEFAULT NULL,
  `cooked_diskreadbytespersec` bigint(20) DEFAULT NULL,
  `cooked_diskwritebytespersec` bigint(20) DEFAULT NULL,
  `cooked_disktransferspersec` bigint(20) DEFAULT NULL,
  `cooked_diskwritespersec` bigint(20) DEFAULT NULL,
  `cooked_diskreadspersec` bigint(20) DEFAULT NULL,
  `cooked_percentdisktime` int(11) DEFAULT NULL,
  `cooked_percentdiskreadtime` int(11) DEFAULT NULL,
  `cooked_percentdiskwritetime` int(11) DEFAULT NULL,
  `cooked_percentidletime` int(11) DEFAULT NULL,
  KEY `Index_1` (`deviceid`),
  KEY `Index_2` (`scantime`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
