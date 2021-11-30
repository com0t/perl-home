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
-- Table structure for table `winperfredirector`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfredirector` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(10) DEFAULT NULL,
  `bytesreceivedpersec` bigint(40) DEFAULT NULL,
  `bytestotalpersec` bigint(40) DEFAULT NULL,
  `bytestransmittedpersec` bigint(40) DEFAULT NULL,
  `caption` varchar(40) DEFAULT NULL,
  `connectscore` int(10) DEFAULT NULL,
  `connectslanmanager20` int(10) DEFAULT NULL,
  `connectslanmanager21` int(10) DEFAULT NULL,
  `connectswindowsnt` int(10) DEFAULT NULL,
  `currentcommands` int(10) DEFAULT NULL,
  `description` varchar(40) DEFAULT NULL,
  `filedataoperationspersec` int(10) DEFAULT NULL,
  `filereadoperationspersec` int(10) DEFAULT NULL,
  `filewriteoperationspersec` int(10) DEFAULT NULL,
  `networkerrorspersec` int(10) DEFAULT NULL,
  `packetspersec` int(10) DEFAULT NULL,
  `packetsreceivedpersec` int(10) DEFAULT NULL,
  `packetstransmittedpersec` int(10) DEFAULT NULL,
  `readbytescachepersec` bigint(40) DEFAULT NULL,
  `readbytesnetworkpersec` bigint(40) DEFAULT NULL,
  `readbytesnonpagingpersec` bigint(40) DEFAULT NULL,
  `readbytespagingpersec` bigint(40) DEFAULT NULL,
  `readoperationsrandompersec` int(10) DEFAULT NULL,
  `readpacketspersec` int(10) DEFAULT NULL,
  `readpacketssmallpersec` int(10) DEFAULT NULL,
  `readsdeniedpersec` int(10) DEFAULT NULL,
  `readslargepersec` int(10) DEFAULT NULL,
  `serverdisconnects` int(10) DEFAULT NULL,
  `serverreconnects` int(10) DEFAULT NULL,
  `serversessions` int(10) DEFAULT NULL,
  `serversessionshung` int(10) DEFAULT NULL,
  `writebytescachepersec` bigint(40) DEFAULT NULL,
  `writebytesnetworkpersec` bigint(40) DEFAULT NULL,
  `writebytesnonpagingpersec` bigint(40) DEFAULT NULL,
  `writebytespagingpersec` bigint(40) DEFAULT NULL,
  `writeoperationsrandompersec` int(10) DEFAULT NULL,
  `writepacketspersec` int(10) DEFAULT NULL,
  `writepacketssmallpersec` int(10) DEFAULT NULL,
  `writesdeniedpersec` int(10) DEFAULT NULL,
  `writeslargepersec` int(10) DEFAULT NULL,
  KEY `Index_1` (`deviceid`),
  KEY `Index_2` (`scantime`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
