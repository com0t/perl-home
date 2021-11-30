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
-- Table structure for table `winperfexchstoreint`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchstoreint` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `connectioncacheactiveconnections` bigint(40) unsigned DEFAULT NULL,
  `connectioncacheidleconnections` int(10) unsigned DEFAULT NULL,
  `connectioncachenumcaches` int(10) unsigned DEFAULT NULL,
  `connectioncacheoutoflimitcreations` bigint(40) unsigned DEFAULT NULL,
  `connectioncachetotalcapacity` int(10) unsigned DEFAULT NULL,
  `description` text,
  `exrpcconnectioncreationevents` int(10) unsigned DEFAULT NULL,
  `exrpcconnectiondisposalevents` int(10) unsigned DEFAULT NULL,
  `exrpcconnectionoutstanding` int(10) unsigned DEFAULT NULL,
  `name` text,
  `roprequestscomplete` bigint(40) unsigned DEFAULT NULL,
  `roprequestsoutstanding` bigint(40) unsigned DEFAULT NULL,
  `roprequestssent` bigint(40) unsigned DEFAULT NULL,
  `rpcbytesreceived` bigint(40) unsigned DEFAULT NULL,
  `rpcbytesreceivedaverage` bigint(40) unsigned DEFAULT NULL,
  `rpcbytessent` bigint(40) unsigned DEFAULT NULL,
  `rpcbytessentaverage` bigint(40) unsigned DEFAULT NULL,
  `rpclatencyaveragemsec` bigint(40) unsigned DEFAULT NULL,
  `rpclatencytotalmsec` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolactivethreadsratio` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolasyncnotificationsreceivedpersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolaveragelatency` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolparkedasyncnotificationcalls` int(10) unsigned DEFAULT NULL,
  `rpcpoolpools` int(10) unsigned DEFAULT NULL,
  `rpcpoolrpccontexthandles` int(10) unsigned DEFAULT NULL,
  `rpcpoolsessionnotificationsreceivedpersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolsessions` int(10) unsigned DEFAULT NULL,
  `rpcrequestsfailed` int(10) unsigned DEFAULT NULL,
  `rpcrequestsfailedpercent` bigint(40) unsigned DEFAULT NULL,
  `rpcrequestsfailedwithexception` int(10) unsigned DEFAULT NULL,
  `rpcrequestsoutstanding` bigint(40) unsigned DEFAULT NULL,
  `rpcrequestssent` bigint(40) unsigned DEFAULT NULL,
  `rpcrequestssentpersec` bigint(40) unsigned DEFAULT NULL,
  `rpcrequestssucceeded` bigint(40) unsigned DEFAULT NULL,
  `rpcslowrequests` int(10) unsigned DEFAULT NULL,
  `rpcslowrequestslatencyaveragemsec` bigint(40) unsigned DEFAULT NULL,
  `rpcslowrequestslatencytotalmsec` bigint(40) unsigned DEFAULT NULL,
  `rpcslowrequestspercent` bigint(40) unsigned DEFAULT NULL,
  `unkfolders` int(10) unsigned DEFAULT NULL,
  `unklogons` int(10) unsigned DEFAULT NULL,
  `unkmessages` int(10) unsigned DEFAULT NULL,
  `unkobjectstotal` int(10) unsigned DEFAULT NULL,
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
