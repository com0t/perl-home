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
-- Table structure for table `vmware_guestperformance`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_guestperformance` (
  `deviceid` bigint(20) unsigned DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
  `samples` int(10) unsigned DEFAULT NULL,
  `minsample` datetime DEFAULT NULL,
  `maxsample` datetime DEFAULT NULL,
  `avgmemorygranted` bigint(20) unsigned DEFAULT NULL,
  `minmemorygranted` bigint(20) unsigned DEFAULT NULL,
  `maxmemorygranted` bigint(20) unsigned DEFAULT NULL,
  `avgcpuutil` int(10) unsigned DEFAULT NULL,
  `mincpuutil` int(10) unsigned DEFAULT NULL,
  `maxcpuutil` int(10) unsigned DEFAULT NULL,
  `avgcpumhz` int(10) unsigned DEFAULT NULL,
  `mincpumhz` int(10) unsigned DEFAULT NULL,
  `maxcpumhz` int(10) unsigned DEFAULT NULL,
  `avgdiskkbytespersec` int(10) unsigned DEFAULT NULL,
  `mindiskkbytespersec` int(10) unsigned DEFAULT NULL,
  `maxdiskkbytespersec` int(10) unsigned DEFAULT NULL,
  `avgkbytememactive` int(10) unsigned DEFAULT NULL,
  `minkbytememactive` int(10) unsigned DEFAULT NULL,
  `maxkbytememactive` int(10) unsigned DEFAULT NULL,
  `avgmemutil` int(10) unsigned DEFAULT NULL,
  `minmemutil` int(10) unsigned DEFAULT NULL,
  `maxmemutil` int(10) unsigned DEFAULT NULL,
  `avgnetkbyte` int(10) unsigned DEFAULT NULL,
  `minnetkbyte` int(10) unsigned DEFAULT NULL,
  `maxnetkbyte` int(10) unsigned DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
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
