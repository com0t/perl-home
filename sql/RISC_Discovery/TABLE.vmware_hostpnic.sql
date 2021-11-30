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
-- Table structure for table `vmware_hostpnic`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_hostpnic` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `device` varchar(255) DEFAULT NULL,
  `duplex` varchar(10) DEFAULT NULL,
  `speedmb` int(11) DEFAULT NULL,
  `dhcp` varchar(10) DEFAULT NULL,
  `ipaddress` varchar(25) DEFAULT NULL,
  `subnetmask` varchar(25) DEFAULT NULL,
  `ipv6autoconfigenabled` varchar(10) DEFAULT NULL,
  `ipv6dhcpenabled` varchar(10) DEFAULT NULL,
  `pci` varchar(20) DEFAULT NULL,
  `resourcepoolschedulerallowed` int(11) DEFAULT NULL,
  `vmdirectpathgen2supported` int(11) DEFAULT NULL,
  `pnickey` varchar(255) DEFAULT NULL,
  `autonegotiatesupported` int(11) DEFAULT NULL,
  `wakeonlansupported` int(11) DEFAULT NULL,
  `mac` varchar(255) DEFAULT NULL,
  `driver` varchar(255) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
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
