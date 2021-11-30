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
-- Table structure for table `winperfexchisclient`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchisclient` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `activeclientconnections` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `clientconnections` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `directoryaccesscacheentriesaddedpersec` bigint(40) unsigned DEFAULT NULL,
  `directoryaccesscacheentriesexpiredpersec` bigint(40) unsigned DEFAULT NULL,
  `directoryaccesscachehitspercent` bigint(40) unsigned DEFAULT NULL,
  `directoryaccessldapreadspersec` bigint(40) unsigned DEFAULT NULL,
  `directoryaccessldapsearchespersec` bigint(40) unsigned DEFAULT NULL,
  `jetlogrecordbytespersec` bigint(40) unsigned DEFAULT NULL,
  `jetlogrecordspersec` bigint(40) unsigned DEFAULT NULL,
  `jetpagesmodifiedpersec` bigint(40) unsigned DEFAULT NULL,
  `jetpagesprereadpersec` bigint(40) unsigned DEFAULT NULL,
  `jetpagesreadpersec` bigint(40) unsigned DEFAULT NULL,
  `jetpagesreferencedpersec` int(10) unsigned DEFAULT NULL,
  `jetpagesremodifiedpersec` bigint(40) unsigned DEFAULT NULL,
  `messagecreatepersec` bigint(40) unsigned DEFAULT NULL,
  `messagedeletepersec` bigint(40) unsigned DEFAULT NULL,
  `messagemodifypersec` bigint(40) unsigned DEFAULT NULL,
  `messagemovepersec` bigint(40) unsigned DEFAULT NULL,
  `minimsgcreatedforviewspersec` bigint(40) unsigned DEFAULT NULL,
  `minimsgmsgtableseekspersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsdeletedpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsdeletesdeferredpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsinsertedpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsinsertsdeferredpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablecreatepersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablenullrefreshpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablerefreshdvurecordsscanned` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablerefreshpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablerefreshupdatesapplied` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `rpcaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `rpcbytesreceivedpersec` int(10) unsigned DEFAULT NULL,
  `rpcbytessentpersec` int(10) unsigned DEFAULT NULL,
  `rpcoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpacketspersec` int(10) unsigned DEFAULT NULL,
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
