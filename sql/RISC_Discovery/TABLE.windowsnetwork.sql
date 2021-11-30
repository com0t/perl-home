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
-- Table structure for table `windowsnetwork`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `windowsnetwork` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `adaptertype` varchar(40) DEFAULT NULL,
  `description` varchar(256) DEFAULT NULL,
  `intindex` varchar(10) DEFAULT NULL,
  `macaddr` varchar(32) DEFAULT NULL,
  `manufacturer` varchar(256) DEFAULT NULL,
  `name` varchar(256) DEFAULT NULL,
  `netconnectionid` varchar(256) DEFAULT NULL,
  `defaulttos` int(11) DEFAULT NULL,
  `dhcpenabled` varchar(40) DEFAULT NULL,
  `dhcpleaseobtained` datetime DEFAULT NULL,
  `dhcpleaseexpires` datetime DEFAULT NULL,
  `dhcpserver` varchar(50) DEFAULT NULL,
  `dnsdomain` varchar(255) DEFAULT NULL,
  `dnshostname` varchar(255) DEFAULT NULL,
  `ipenabled` varchar(40) DEFAULT NULL,
  `ipxenabled` varchar(40) DEFAULT NULL,
  `ipaddress` varchar(1024) DEFAULT NULL,
  `subnetmask` varchar(1024) DEFAULT NULL,
  `ipxaddress` varchar(255) DEFAULT NULL,
  `ipxnet` varchar(255) DEFAULT NULL,
  `ipxvirtualnet` varchar(255) DEFAULT NULL,
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