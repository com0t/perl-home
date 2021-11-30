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
-- Table structure for table `callhistory`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `callhistory` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `callindex` int(11) DEFAULT NULL,
  `callstarttime` varchar(50) DEFAULT NULL,
  `callingnumber` varchar(40) DEFAULT NULL,
  `callednumber` varchar(40) DEFAULT NULL,
  `interfacenumber` int(11) DEFAULT NULL,
  `destinationaddress` varchar(40) DEFAULT NULL,
  `destinationhostname` varchar(255) DEFAULT NULL,
  `disconnectcause` varchar(40) DEFAULT NULL,
  `connecttime` varchar(50) DEFAULT NULL,
  `disconnecttime` varchar(50) DEFAULT NULL,
  `dialreason` varchar(40) DEFAULT NULL,
  `connecttimeofday` varchar(40) DEFAULT NULL,
  `disconnecttimeofday` varchar(40) DEFAULT NULL,
  `transmitpackets` bigint(40) DEFAULT NULL,
  `transmitbytes` bigint(40) DEFAULT NULL,
  `receivepackets` bigint(40) DEFAULT NULL,
  `receivebytes` bigint(40) DEFAULT NULL,
  `recordedunits` int(11) DEFAULT NULL,
  `currency` varchar(20) DEFAULT NULL,
  `currencyamount` int(11) DEFAULT NULL,
  `multiplier` varchar(20) DEFAULT NULL,
  `uniqueid` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`uniqueid`) USING BTREE,
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

-- Dump completed on 2018-06-07 18:11:21
