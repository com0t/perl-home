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
-- Table structure for table `netflowtoprn50`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `netflowtoprn50` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(10) DEFAULT NULL,
  `flowid` varchar(255) DEFAULT NULL,
  `flowindex` varchar(255) DEFAULT NULL,
  `srcaddrtype` varchar(255) DEFAULT NULL,
  `srcaddr` varchar(255) DEFAULT NULL,
  `srcaddrmask` varchar(255) DEFAULT NULL,
  `destaddrtype` varchar(255) DEFAULT NULL,
  `destaddr` varchar(255) DEFAULT NULL,
  `srcport` int(10) DEFAULT NULL,
  `destport` int(10) DEFAULT NULL,
  `srcmac` varchar(40) DEFAULT NULL,
  `destmac` varchar(40) DEFAULT NULL,
  `firstswitched` decimal(17,5) DEFAULT NULL,
  `lastswitched` decimal(17,5) DEFAULT NULL,
  `stos` int(10) DEFAULT NULL,
  `dtos` int(10) DEFAULT NULL,
  `protocol` varchar(15) DEFAULT NULL,
  `tcpflag` varchar(255) DEFAULT NULL,
  `samplerid` varchar(255) DEFAULT NULL,
  `flags` varchar(255) DEFAULT NULL,
  `bytes` bigint(40) DEFAULT NULL,
  `packets` int(10) DEFAULT NULL,
  `spkts` int(10) DEFAULT NULL,
  `dpkts` int(10) DEFAULT NULL,
  `sbytes` bigint(40) DEFAULT NULL,
  `dbytes` bigint(40) DEFAULT NULL,
  `protocolname` varchar(255) DEFAULT NULL,
  `tcprtt` decimal(9,6) DEFAULT NULL,
  `losspercent` decimal(8,5) DEFAULT NULL,
  `sloss` int(10) DEFAULT NULL,
  `dloss` int(10) DEFAULT NULL,
  `sjitt` int(10) DEFAULT NULL,
  `djitt` int(10) DEFAULT NULL,
  `reason` varchar(10) DEFAULT NULL,
  `srcloc` int(10) DEFAULT NULL,
  `destloc` int(10) DEFAULT NULL,
  `conversation` varchar(45) DEFAULT NULL,
  `suser` varchar(255) DEFAULT NULL,
  `duser` varchar(255) DEFAULT NULL,
  KEY `Index_1` (`flowid`),
  KEY `Index_2` (`deviceid`),
  KEY `Index_3` (`scantime`),
  KEY `Index_4` (`srcaddr`),
  KEY `Index_5` (`destaddr`),
  KEY `Index_6` (`firstswitched`),
  KEY `Index_7` (`lastswitched`),
  KEY `Index_8` (`samplerid`),
  KEY `Index_9` (`protocolname`),
  KEY `Index_10` (`srcloc`),
  KEY `Index_11` (`destloc`),
  KEY `Index_12` (`conversation`),
  KEY `Index_13` (`protocol`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
