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
-- Table structure for table `db_inventory`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `db_inventory` (
  `dboid` bigint(40) NOT NULL DEFAULT '0',
  `credid` int(10) DEFAULT NULL,
  `hostdevice` varchar(255) DEFAULT NULL,
  `can_acc` tinyint(1) DEFAULT NULL,
  `dbtype` varchar(20) DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `hostip` varchar(255) DEFAULT NULL,
  `hostport` varchar(255) DEFAULT NULL,
  `oraclesid` varchar(255) DEFAULT NULL,
  `initialdbs` bigint(40) DEFAULT NULL,
  `initialconns` bigint(40) DEFAULT NULL,
  `extracol1` varchar(255) DEFAULT NULL,
  `extracol2` varchar(255) DEFAULT NULL,
  `extracol3` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`dboid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
