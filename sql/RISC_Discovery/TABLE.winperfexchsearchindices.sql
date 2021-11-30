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
-- Table structure for table `winperfexchsearchindices`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchsearchindices` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `ageofthelastnotificationindexed` int(10) unsigned DEFAULT NULL,
  `ageofthelastnotificationprocessed` int(10) unsigned DEFAULT NULL,
  `averagedocumentindexingtime` bigint(40) unsigned DEFAULT NULL,
  `averagelatencyofrpcsduringcrawling` bigint(40) unsigned DEFAULT NULL,
  `averagelatencyofrpcstogetnotifications` bigint(40) unsigned DEFAULT NULL,
  `averagelatencyofrpcsusedtoobtaincontent` bigint(40) unsigned DEFAULT NULL,
  `averagesizeofindexedattachments` bigint(40) unsigned DEFAULT NULL,
  `averagesizeofindexedattachmentsforprotectedmessages` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `description` text,
  `documentindexingrate` bigint(40) unsigned DEFAULT NULL,
  `fullcrawlmodestatus` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `numberofcontentconversionsdone` int(10) unsigned DEFAULT NULL,
  `numberofcreatenotifications` int(10) unsigned DEFAULT NULL,
  `numberofcreatenotificationspersec` bigint(40) unsigned DEFAULT NULL,
  `numberofdeletenotifications` bigint(40) unsigned DEFAULT NULL,
  `numberofdeletenotificationspersec` bigint(40) unsigned DEFAULT NULL,
  `numberofdocumentssuccessfullyindexed` int(10) unsigned DEFAULT NULL,
  `numberofdocumentsthatfailedduringindexing` bigint(40) unsigned DEFAULT NULL,
  `numberoffailedmailboxes` bigint(40) unsigned DEFAULT NULL,
  `numberoffailedretries` bigint(40) unsigned DEFAULT NULL,
  `numberofhtmlmessagebodies` int(10) unsigned DEFAULT NULL,
  `numberofindexedattachments` bigint(40) unsigned DEFAULT NULL,
  `numberofindexedattachmentsforprotectedmessages` bigint(40) unsigned DEFAULT NULL,
  `numberofindexedrecipients` int(10) unsigned DEFAULT NULL,
  `numberofintransitmailboxesbeingindexedonthisdestinationdatabase` bigint(40) unsigned DEFAULT NULL,
  `numberofitemsinanotificationqueue` bigint(40) unsigned DEFAULT NULL,
  `numberofmailboxeslefttocrawl` bigint(40) unsigned DEFAULT NULL,
  `numberofmovenotifications` bigint(40) unsigned DEFAULT NULL,
  `numberofmovenotificationspersec` bigint(40) unsigned DEFAULT NULL,
  `numberofoutstandingbatches` bigint(40) unsigned DEFAULT NULL,
  `numberofoutstandingdocuments` bigint(40) unsigned DEFAULT NULL,
  `numberofplaintextmessagebodies` bigint(40) unsigned DEFAULT NULL,
  `numberofretries` bigint(40) unsigned DEFAULT NULL,
  `numberofretriesfornewfilter` bigint(40) unsigned DEFAULT NULL,
  `numberofrmsprotectedmessages` bigint(40) unsigned DEFAULT NULL,
  `numberofrtfmessagebodies` bigint(40) unsigned DEFAULT NULL,
  `numberofsuccessfulretries` bigint(40) unsigned DEFAULT NULL,
  `numberofupdatenotifications` bigint(40) unsigned DEFAULT NULL,
  `numberofupdatenotificationspersec` bigint(40) unsigned DEFAULT NULL,
  `percentageofnotificationsoptimized` bigint(40) unsigned DEFAULT NULL,
  `recentaveragelatencyofrpcsusedtoobtaincontent` bigint(40) unsigned DEFAULT NULL,
  `searchableifmounted` int(10) unsigned DEFAULT NULL,
  `throttlingdelayvalue` bigint(40) unsigned DEFAULT NULL,
  `timesincelastnotificationwasindexed` bigint(40) unsigned DEFAULT NULL,
  `totaltimetakenforindexingprotectedmessages` bigint(40) unsigned DEFAULT NULL,
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
