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
-- Table structure for table `vmware_virtualswitchconfig`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_virtualswitchconfig` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `nicteam_failcheckbeacon` varchar(10) DEFAULT NULL,
  `nicteam_failcheckduplex` varchar(10) DEFAULT NULL,
  `nicteam_failcheckerrorpercent` varchar(10) DEFAULT NULL,
  `nicteam_failcheckspeed` varchar(40) DEFAULT NULL,
  `nicteam_failfullduplex` varchar(10) DEFAULT NULL,
  `nicteam_failpercentage` varchar(10) DEFAULT NULL,
  `nicteam_failspeed` varchar(10) DEFAULT NULL,
  `notifyswitches` varchar(10) DEFAULT NULL,
  `policy` varchar(40) DEFAULT NULL,
  `reversepolicy` varchar(10) DEFAULT NULL,
  `rollingorder` varchar(10) DEFAULT NULL,
  `csumoffload` varchar(10) DEFAULT NULL,
  `tcpsegmentation` varchar(10) DEFAULT NULL,
  `zerocopyxmit` varchar(10) DEFAULT NULL,
  `allowpromiscuous` varchar(10) DEFAULT NULL,
  `forgedtransmits` varchar(10) DEFAULT NULL,
  `macchanges` varchar(10) DEFAULT NULL,
  `averagebandwidth` bigint(40) DEFAULT NULL,
  `burstsize` bigint(40) DEFAULT NULL,
  `enabled` varchar(10) DEFAULT NULL,
  `peakbandwidth` bigint(40) DEFAULT NULL,
  `mtu` int(11) DEFAULT NULL,
  `numports` int(11) DEFAULT NULL,
  `numportsavailable` int(11) DEFAULT NULL,
  `changeoperation` varchar(40) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `vswitchkey` varchar(255) DEFAULT NULL,
  `vswitchtype` varchar(255) DEFAULT NULL,
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
