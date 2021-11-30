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
-- Table structure for table `perfsummary`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `perfsummary` (
  `deviceid` bigint(40) NOT NULL,
  `attempt` int(11) unsigned DEFAULT '0',
  `success` int(11) unsigned DEFAULT '0',
  `cpu` int(11) unsigned DEFAULT '0',
  `mem` int(11) unsigned DEFAULT '0',
  `diskutil` int(11) unsigned DEFAULT '0',
  `diskio` int(11) unsigned DEFAULT '0',
  `traffic` int(11) unsigned DEFAULT '0',
  `processes` int(11) unsigned DEFAULT '0',
  `netstat` int(11) unsigned DEFAULT '0',
  `rfc4022` tinyint(4) DEFAULT '0',
  `flow` int(11) unsigned DEFAULT '0',
  `polls` int(11) unsigned DEFAULT '0',
  `failed` int(11) unsigned DEFAULT '0',
  `error` varchar(255) DEFAULT NULL,
  INDEX `deviceid` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
