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
-- Table structure for table `winperfSQLStatis`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfSQLStatis` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `instancename` text,
  `autoparamattemptspersec` bigint(40) unsigned DEFAULT NULL,
  `batchrequestspersec` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `description` text,
  `failedautoparamspersec` bigint(40) unsigned DEFAULT NULL,
  `forcedparameterizationspersec` bigint(40) unsigned DEFAULT NULL,
  `guidedplanexecutionspersec` bigint(40) unsigned DEFAULT NULL,
  `misguidedplanexecutionspersec` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `safeautoparamspersec` bigint(40) unsigned DEFAULT NULL,
  `sqlattentionrate` bigint(40) unsigned DEFAULT NULL,
  `sqlcompilationspersec` bigint(40) unsigned DEFAULT NULL,
  `sqlrecompilationspersec` bigint(40) unsigned DEFAULT NULL,
  `unsafeautoparamspersec` bigint(40) unsigned DEFAULT NULL,
  `sqlcompilationspersec_to_batchrequestspersec` int(10) unsigned DEFAULT NULL,
  `sqlrecompilationspersec_to_sqlcompilationspersec` int(10) unsigned DEFAULT NULL,
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
