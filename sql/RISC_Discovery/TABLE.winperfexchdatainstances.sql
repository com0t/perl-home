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
-- Table structure for table `winperfexchdatainstances`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchdatainstances` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `databasecachemissespersec` bigint(40) unsigned DEFAULT NULL,
  `databasecachepercenthit` bigint(40) unsigned DEFAULT NULL,
  `databasecacherequestspersec` bigint(40) unsigned DEFAULT NULL,
  `databasecachesizemb` int(10) unsigned DEFAULT NULL,
  `databasemaintenanceduration` bigint(40) unsigned DEFAULT NULL,
  `databasemaintenancepagesbadchecksums` bigint(40) unsigned DEFAULT NULL,
  `defragmentationtasks` bigint(40) unsigned DEFAULT NULL,
  `defragmentationtaskspending` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `iodatabasereadsattachedaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasereadsattachedpersec` bigint(40) unsigned DEFAULT NULL,
  `iodatabasereadsaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasereadspersec` bigint(40) unsigned DEFAULT NULL,
  `iodatabasereadsrecoveryaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasereadsrecoverypersec` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritesattachedaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritesattachedpersec` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritesaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritespersec` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritesrecoveryaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iodatabasewritesrecoverypersec` bigint(40) unsigned DEFAULT NULL,
  `iologreadsaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iologreadspersec` bigint(40) unsigned DEFAULT NULL,
  `iologwritesaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `iologwritespersec` bigint(40) unsigned DEFAULT NULL,
  `logbytesgeneratedpersec` bigint(40) unsigned DEFAULT NULL,
  `logbyteswritepersec` bigint(40) unsigned DEFAULT NULL,
  `logcheckpointdepthasapercentoftarget` int(10) unsigned DEFAULT NULL,
  `logfilecurrentgeneration` bigint(40) unsigned DEFAULT NULL,
  `logfilesgenerated` int(10) unsigned DEFAULT NULL,
  `logfilesgeneratedprematurely` int(10) unsigned DEFAULT NULL,
  `loggenerationcheckpointdepth` int(10) unsigned DEFAULT NULL,
  `loggenerationcheckpointdepthmax` int(10) unsigned DEFAULT NULL,
  `loggenerationcheckpointdepthtarget` int(10) unsigned DEFAULT NULL,
  `loggenerationlossresiliencydepth` int(10) unsigned DEFAULT NULL,
  `logrecordstallspersec` bigint(40) unsigned DEFAULT NULL,
  `logthreadswaiting` bigint(40) unsigned DEFAULT NULL,
  `logwritespersec` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `pagesconverted` bigint(40) unsigned DEFAULT NULL,
  `pagesconvertedpersec` bigint(40) unsigned DEFAULT NULL,
  `recordsconverted` bigint(40) unsigned DEFAULT NULL,
  `recordsconvertedpersec` bigint(40) unsigned DEFAULT NULL,
  `sessionsinuse` int(10) unsigned DEFAULT NULL,
  `sessionspercentused` int(10) unsigned DEFAULT NULL,
  `streamingbackuppagesreadpersec` bigint(40) unsigned DEFAULT NULL,
  `tableopencachehitspersec` bigint(40) unsigned DEFAULT NULL,
  `tableopencachemissespersec` bigint(40) unsigned DEFAULT NULL,
  `tableopencachepercenthit` bigint(40) unsigned DEFAULT NULL,
  `tableopenspersec` bigint(40) unsigned DEFAULT NULL,
  `versionbucketsallocated` int(10) unsigned DEFAULT NULL,
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
