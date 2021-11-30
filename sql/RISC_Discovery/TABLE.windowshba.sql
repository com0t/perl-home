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
-- Table structure for table `windowshba`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `windowshba` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
  `adapterid` varchar(255) DEFAULT NULL,
  `hbastatus` varchar(255) DEFAULT NULL,
  `nodewwn` varchar(255) DEFAULT NULL,
  `vendorspecificid` varchar(255) DEFAULT NULL,
  `numberofport` int(11) DEFAULT NULL,
  `manufacturer` varchar(255) DEFAULT NULL,
  `serialnumber` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `modeldescription` varchar(255) DEFAULT NULL,
  `nodesymbolicname` varchar(255) DEFAULT NULL,
  `hardwareversion` varchar(40) DEFAULT NULL,
  `driverversion` varchar(40) DEFAULT NULL,
  `optionromversion` varchar(40) DEFAULT NULL,
  `firmwareversion` varchar(40) DEFAULT NULL,
  `drivername` varchar(255) DEFAULT NULL,
  `mfgdomain` varchar(255) DEFAULT NULL,
  `instancename` varchar(255) DEFAULT NULL,
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
