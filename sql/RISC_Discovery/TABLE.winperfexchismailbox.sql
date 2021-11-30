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
-- Table structure for table `winperfexchismailbox`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchismailbox` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `activeclientlogons` int(10) unsigned DEFAULT NULL,
  `averagedeliverytime` int(10) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `clientlogons` int(10) unsigned DEFAULT NULL,
  `deliveryblockedlowdatabasespace` bigint(40) unsigned DEFAULT NULL,
  `deliveryblockedlowlogdiskspace` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `eventhistorydeletes` int(10) unsigned DEFAULT NULL,
  `eventhistorydeletespersec` bigint(40) unsigned DEFAULT NULL,
  `eventhistoryeventcachehitspercent` bigint(40) unsigned DEFAULT NULL,
  `eventhistoryeventscount` int(10) unsigned DEFAULT NULL,
  `eventhistoryeventswithemptycontainerclass` int(10) unsigned DEFAULT NULL,
  `eventhistoryeventswithemptymessageclass` int(10) unsigned DEFAULT NULL,
  `eventhistoryeventswithtruncatedcontainerclass` bigint(40) unsigned DEFAULT NULL,
  `eventhistoryeventswithtruncatedmessageclass` int(10) unsigned DEFAULT NULL,
  `eventhistoryreads` bigint(40) unsigned DEFAULT NULL,
  `eventhistoryreadspersec` bigint(40) unsigned DEFAULT NULL,
  `eventhistoryuncommittedtransactionscount` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywatermarkscount` int(10) unsigned DEFAULT NULL,
  `eventhistorywatermarksdeletes` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywatermarksdeletespersec` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywatermarksreads` int(10) unsigned DEFAULT NULL,
  `eventhistorywatermarksreadspersec` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywatermarkswrites` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywatermarkswritespersec` bigint(40) unsigned DEFAULT NULL,
  `eventhistorywrites` int(10) unsigned DEFAULT NULL,
  `eventhistorywritespersec` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchfirstbatch` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchlessone` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchonetoten` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchqueries` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchslowfirstbatch` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchtenmore` bigint(40) unsigned DEFAULT NULL,
  `exchangesearchzeroresultsqueries` bigint(40) unsigned DEFAULT NULL,
  `folderopenspersec` bigint(40) unsigned DEFAULT NULL,
  `lastquerytime` int(10) unsigned DEFAULT NULL,
  `localdeliveries` int(10) unsigned DEFAULT NULL,
  `localdeliveryrate` bigint(40) unsigned DEFAULT NULL,
  `logonoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `mailboxlogonentrycachehitrate` bigint(40) unsigned DEFAULT NULL,
  `mailboxlogonentrycachehitratepercent` bigint(40) unsigned DEFAULT NULL,
  `mailboxlogonentrycachemissrate` bigint(40) unsigned DEFAULT NULL,
  `mailboxlogonentrycachemissratepercent` bigint(40) unsigned DEFAULT NULL,
  `mailboxlogonentrycachesize` int(10) unsigned DEFAULT NULL,
  `mailboxmetadatacachehitrate` bigint(40) unsigned DEFAULT NULL,
  `mailboxmetadatacachehitratepercent` bigint(40) unsigned DEFAULT NULL,
  `mailboxmetadatacachemissrate` bigint(40) unsigned DEFAULT NULL,
  `mailboxmetadatacachemissratepercent` bigint(40) unsigned DEFAULT NULL,
  `mailboxmetadatacachesize` int(10) unsigned DEFAULT NULL,
  `mailboxreplicationreadconnections` bigint(40) unsigned DEFAULT NULL,
  `mailboxreplicationwriteconnections` bigint(40) unsigned DEFAULT NULL,
  `messageopenspersec` bigint(40) unsigned DEFAULT NULL,
  `messagerecipientsdelivered` int(10) unsigned DEFAULT NULL,
  `messagerecipientsdeliveredpersec` bigint(40) unsigned DEFAULT NULL,
  `messagesdelivered` int(10) unsigned DEFAULT NULL,
  `messagesdeliveredpersec` bigint(40) unsigned DEFAULT NULL,
  `messagesqueuedforsubmission` bigint(40) unsigned DEFAULT NULL,
  `messagessent` int(10) unsigned DEFAULT NULL,
  `messagessentpersec` bigint(40) unsigned DEFAULT NULL,
  `messagessubmitted` int(10) unsigned DEFAULT NULL,
  `messagessubmittedpersec` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `peakclientlogons` int(10) unsigned DEFAULT NULL,
  `quarantinedmailboxcount` bigint(40) unsigned DEFAULT NULL,
  `replidcount` bigint(40) unsigned DEFAULT NULL,
  `restrictedviewcachehitrate` bigint(40) unsigned DEFAULT NULL,
  `restrictedviewcachemissrate` bigint(40) unsigned DEFAULT NULL,
  `rpcaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `searchtaskrate` bigint(40) unsigned DEFAULT NULL,
  `slowfindrowrate` bigint(40) unsigned DEFAULT NULL,
  `storeonlyqueries` int(10) unsigned DEFAULT NULL,
  `storeonlyquerytenmore` bigint(40) unsigned DEFAULT NULL,
  `storeonlyqueryuptoten` int(10) unsigned DEFAULT NULL,
  `totalcountofrecoverableitems` bigint(40) unsigned DEFAULT NULL,
  `totalqueries` int(10) unsigned DEFAULT NULL,
  `totalsizeofrecoverableitems` bigint(40) unsigned DEFAULT NULL,
  `virusscanbackgroundmessagesscanned` bigint(40) unsigned DEFAULT NULL,
  `virusscanbackgroundmessagesskipped` bigint(40) unsigned DEFAULT NULL,
  `virusscanbackgroundmessagesuptodate` bigint(40) unsigned DEFAULT NULL,
  `virusscanbackgroundscanningthreads` bigint(40) unsigned DEFAULT NULL,
  `virusscanexternalresultsaccepted` bigint(40) unsigned DEFAULT NULL,
  `virusscanexternalresultsnotaccepted` bigint(40) unsigned DEFAULT NULL,
  `virusscanexternalresultsnotpresent` bigint(40) unsigned DEFAULT NULL,
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
