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
-- Table structure for table `vmwareperf_sys`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmwareperf_sys` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `entity` varchar(25) DEFAULT NULL,
  `entityname` varchar(40) DEFAULT NULL,
  `instance` varchar(255) DEFAULT NULL,
  `value` bigint(40) DEFAULT NULL,
  `counterid` int(11) DEFAULT NULL,
  `countername` varchar(25) DEFAULT NULL,
  `groupinfo` varchar(25) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `allvalues` varchar(255) DEFAULT NULL,
  `starttime` int(11) DEFAULT NULL,
  `endtime` int(11) DEFAULT NULL,
  `rmin` int(11) DEFAULT NULL,
  `rmax` int(11) DEFAULT NULL,
  `ravg` float DEFAULT NULL,
  `rsum` int(11) DEFAULT NULL,
  `rstddev` float DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23