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
-- Table structure for table `citrixmetaframepresentationserver`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `citrixmetaframepresentationserver` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `ApplicationEnumerationsPersec` bigint(40) DEFAULT NULL,
  `ApplicationResolutionsFailedPersec` bigint(40) DEFAULT NULL,
  `ApplicationResolutionsPersec` bigint(40) DEFAULT NULL,
  `ApplicationResolutionTimems` bigint(40) DEFAULT NULL,
  `Caption` varchar(255) DEFAULT NULL,
  `DataStorebytesread` bigint(40) DEFAULT NULL,
  `DataStorebytesreadPersec` bigint(40) DEFAULT NULL,
  `DataStorebyteswrittenPersec` bigint(40) DEFAULT NULL,
  `DataStoreConnectionFailure` bigint(40) DEFAULT NULL,
  `DataStorereads` bigint(40) DEFAULT NULL,
  `DataStorereadsPersec` bigint(40) DEFAULT NULL,
  `DataStorewritesPersec` bigint(40) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `DynamicStorebytesreadPersec` bigint(40) DEFAULT NULL,
  `DynamicStorebyteswrittenPersec` bigint(40) DEFAULT NULL,
  `DynamicStoreGatewayUpdateBytesSent` bigint(40) DEFAULT NULL,
  `DynamicStoreGatewayUpdateCount` bigint(40) DEFAULT NULL,
  `DynamicStoreQueryCount` bigint(40) DEFAULT NULL,
  `DynamicStoreQueryRequestBytesReceived` bigint(40) DEFAULT NULL,
  `DynamicStoreQueryResponseBytesSent` bigint(40) DEFAULT NULL,
  `DynamicStorereadsPersec` bigint(40) DEFAULT NULL,
  `DynamicStoreUpdateBytesReceived` bigint(40) DEFAULT NULL,
  `DynamicStoreUpdatePacketsReceived` bigint(40) DEFAULT NULL,
  `DynamicStoreUpdateResponseBytesSent` bigint(40) DEFAULT NULL,
  `DynamicStorewritesPersec` bigint(40) DEFAULT NULL,
  `FilteredApplicationEnumerationsPersec` bigint(40) DEFAULT NULL,
  `Frequency_Object` bigint(40) DEFAULT NULL,
  `Frequency_PerfTime` bigint(40) DEFAULT NULL,
  `Frequency_Sys100NS` bigint(40) DEFAULT NULL,
  `LocalHostCachebytesreadPersec` bigint(40) DEFAULT NULL,
  `LocalHostCachebyteswrittenPersec` bigint(40) DEFAULT NULL,
  `LocalHostCachereadsPersec` bigint(40) DEFAULT NULL,
  `LocalHostCachewritesPersec` bigint(40) DEFAULT NULL,
  `MaximumnumberofXMLthreads` bigint(40) DEFAULT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `NumberofbusyXMLthreads` bigint(40) DEFAULT NULL,
  `NumberofXMLthreads` bigint(40) DEFAULT NULL,
  `ResolutionWorkItemQueueExecutingCount` bigint(40) DEFAULT NULL,
  `ResolutionWorkItemQueueReadyCount` bigint(40) DEFAULT NULL,
  `Timestamp_Object` bigint(40) DEFAULT NULL,
  `Timestamp_PerfTime` bigint(40) DEFAULT NULL,
  `Timestamp_Sys100NS` bigint(40) DEFAULT NULL,
  `WorkItemQueueExecutingCount` bigint(40) DEFAULT NULL,
  `WorkItemQueuePendingCount` bigint(40) DEFAULT NULL,
  `WorkItemQueueReadyCount` bigint(40) DEFAULT NULL,
  `ZoneElections` bigint(40) DEFAULT NULL,
  `ZoneElectionsWon` bigint(40) DEFAULT NULL,
  KEY `Index_1` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
