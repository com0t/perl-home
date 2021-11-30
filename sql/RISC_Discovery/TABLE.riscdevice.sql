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
-- Table structure for table `riscdevice`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `riscdevice` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `sysdescription` varchar(256) DEFAULT NULL,
  `ipaddress` varchar(16) DEFAULT NULL,
  `macaddr` varchar(45) NOT NULL,
  `snmpstring` varchar(45) DEFAULT NULL,
  `layer2` int(10) unsigned DEFAULT NULL,
  `layer3` int(10) unsigned DEFAULT NULL,
  `layer1` int(10) unsigned DEFAULT NULL,
  `layer4` int(10) unsigned DEFAULT NULL,
  `layer5` int(10) unsigned DEFAULT NULL,
  `layer6` int(10) unsigned DEFAULT NULL,
  `layer7` int(10) unsigned DEFAULT NULL,
  `wmi` int(5) unsigned DEFAULT '0',
  PRIMARY KEY (`macaddr`) USING BTREE,
  KEY `Index_2` (`deviceid`)
) ENGINE=MyISAM AUTO_INCREMENT=133 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
