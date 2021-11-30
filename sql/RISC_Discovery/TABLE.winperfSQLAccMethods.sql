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
-- Table structure for table `winperfSQLAccMethods`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfSQLAccMethods` (
  `deviceid` bigint(40) unsigned NOT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `instancename` text,
  `aucleanupbatchespersec` bigint(40) unsigned DEFAULT NULL,
  `aucleanupspersec` bigint(40) unsigned DEFAULT NULL,
  `byreferencelobcreatecount` bigint(40) unsigned DEFAULT NULL,
  `byreferencelobusecount` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `countlobreadahead` bigint(40) unsigned DEFAULT NULL,
  `countpullinrow` bigint(40) unsigned DEFAULT NULL,
  `countpushoffrow` bigint(40) unsigned DEFAULT NULL,
  `deferreddroppedaus` bigint(40) unsigned DEFAULT NULL,
  `deferreddroppedrowsets` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `droppedrowsetcleanupspersec` bigint(40) unsigned DEFAULT NULL,
  `droppedrowsetsskippedpersec` bigint(40) unsigned DEFAULT NULL,
  `extentdeallocationspersec` bigint(40) unsigned DEFAULT NULL,
  `extentsallocatedpersec` bigint(40) unsigned DEFAULT NULL,
  `failedaucleanupbatchespersec` bigint(40) unsigned DEFAULT NULL,
  `failedleafpagecookie` bigint(40) unsigned DEFAULT NULL,
  `failedtreepagecookie` bigint(40) unsigned DEFAULT NULL,
  `forwardedrecordspersec` bigint(40) unsigned DEFAULT NULL,
  `freespacepagefetchespersec` bigint(40) unsigned DEFAULT NULL,
  `freespacescanspersec` bigint(40) unsigned DEFAULT NULL,
  `fullscanspersec` int(10) unsigned DEFAULT NULL,
  `indexsearchespersec` int(10) unsigned DEFAULT NULL,
  `insysxactwaitspersec` bigint(40) unsigned DEFAULT NULL,
  `lobhandlecreatecount` bigint(40) unsigned DEFAULT NULL,
  `lobhandledestroycount` bigint(40) unsigned DEFAULT NULL,
  `lobssprovidercreatecount` bigint(40) unsigned DEFAULT NULL,
  `lobssproviderdestroycount` bigint(40) unsigned DEFAULT NULL,
  `lobssprovidertruncationcount` bigint(40) unsigned DEFAULT NULL,
  `mixedpageallocationspersec` int(10) unsigned DEFAULT NULL,
  `name` text,
  `pagecompressionattemptspersec` bigint(40) unsigned DEFAULT NULL,
  `pagedeallocationspersec` bigint(40) unsigned DEFAULT NULL,
  `pagesallocatedpersec` int(10) unsigned DEFAULT NULL,
  `pagescompressedpersec` bigint(40) unsigned DEFAULT NULL,
  `pagesplitspersec` int(10) unsigned DEFAULT NULL,
  `probescanspersec` int(10) unsigned DEFAULT NULL,
  `rangescanspersec` int(10) unsigned DEFAULT NULL,
  `scanpointrevalidationspersec` bigint(40) unsigned DEFAULT NULL,
  `skippedghostedrecordspersec` bigint(40) unsigned DEFAULT NULL,
  `tablelockescalationspersec` bigint(40) unsigned DEFAULT NULL,
  `usedleafpagecookie` bigint(40) unsigned DEFAULT NULL,
  `usedtreepagecookie` bigint(40) unsigned DEFAULT NULL,
  `workfilescreatedpersec` bigint(40) unsigned DEFAULT NULL,
  `worktablescreatedpersec` int(10) unsigned DEFAULT NULL,
  `worktablesfromcacheratio` bigint(40) unsigned DEFAULT NULL,
  `batchrequestspersec` bigint(40) unsigned DEFAULT NULL,
  `percentforwardedrecordspersec_to_batchrequestspersec` int(10) unsigned DEFAULT NULL,
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
