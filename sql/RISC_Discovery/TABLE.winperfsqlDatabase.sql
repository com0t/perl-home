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
-- Table structure for table `winperfsqlDatabase`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfsqlDatabase` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `instancename` text,
  `activetransactions` bigint(40) unsigned DEFAULT NULL,
  `backupperrestorethroughputpersec` bigint(40) unsigned DEFAULT NULL,
  `bulkcopyrowspersec` bigint(40) unsigned DEFAULT NULL,
  `bulkcopythroughputpersec` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `committableentries` bigint(40) unsigned DEFAULT NULL,
  `datafilessizekb` int(10) unsigned DEFAULT NULL,
  `dbcclogicalscanbytespersec` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `logbytesflushedpersec` int(10) unsigned DEFAULT NULL,
  `logcachehitratio` bigint(40) unsigned DEFAULT NULL,
  `logcachereadspersec` bigint(40) unsigned DEFAULT NULL,
  `logfilessizekb` int(10) unsigned DEFAULT NULL,
  `logfilesusedsizekb` int(10) unsigned DEFAULT NULL,
  `logflushespersec` int(10) unsigned DEFAULT NULL,
  `logflushwaitspersec` int(10) unsigned DEFAULT NULL,
  `logflushwaittime` int(10) unsigned DEFAULT NULL,
  `logflushwritetimems` int(10) unsigned DEFAULT NULL,
  `loggrowths` bigint(40) unsigned DEFAULT NULL,
  `logpoolcachemissespersec` int(10) unsigned DEFAULT NULL,
  `logpooldiskreadspersec` int(10) unsigned DEFAULT NULL,
  `logpoolrequestspersec` int(10) unsigned DEFAULT NULL,
  `logshrinks` bigint(40) unsigned DEFAULT NULL,
  `logtruncations` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `percentlogused` int(10) unsigned DEFAULT NULL,
  `replpendingxacts` bigint(40) unsigned DEFAULT NULL,
  `repltransrate` bigint(40) unsigned DEFAULT NULL,
  `shrinkdatamovementbytespersec` bigint(40) unsigned DEFAULT NULL,
  `trackedtransactionspersec` bigint(40) unsigned DEFAULT NULL,
  `transactionspersec` int(10) unsigned DEFAULT NULL,
  `writetransactionspersec` int(10) unsigned DEFAULT NULL,
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
