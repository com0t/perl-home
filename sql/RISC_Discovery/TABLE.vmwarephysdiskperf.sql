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
-- Table structure for table `vmwarephysdiskperf`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmwarephysdiskperf` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
  `instance` varchar(255) DEFAULT NULL,
  `minsample` datetime DEFAULT NULL,
  `maxsample` datetime DEFAULT NULL,
  `diskdevicelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskdevicelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskdevicelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskdevicereadlatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskdevicereadlatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskdevicereadlatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskdevicewritelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskdevicewritelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskdevicewritelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskkernellatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskkernellatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskkernellatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskkernelreadlatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskkernelreadlatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskkernelreadlatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskkernelwritelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskkernelwritelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskkernelwritelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskqueuelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskqueuelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskqueuelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskqueuereadlatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskqueuereadlatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskqueuereadlatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskqueuewritelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `diskqueuewritelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `diskqueuewritelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskreadkilobytespersecondaveragemin` float(7,2) DEFAULT NULL,
  `diskreadkilobytespersecondaveragemax` float(7,2) DEFAULT NULL,
  `diskreadkilobytespersecondaverageavg` float(7,2) DEFAULT NULL,
  `disktotallatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `disktotallatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `disktotallatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `disktotalreadlatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `disktotalreadlatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `disktotalreadlatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `disktotalwritelatencymillisecondaveragemin` float(7,2) DEFAULT NULL,
  `disktotalwritelatencymillisecondaveragemax` float(7,2) DEFAULT NULL,
  `disktotalwritelatencymillisecondaverageavg` float(7,2) DEFAULT NULL,
  `diskwritekilobytespersecondaveragemin` float(7,2) DEFAULT NULL,
  `diskwritekilobytespersecondaveragemax` float(7,2) DEFAULT NULL,
  `diskwritekilobytespersecondaverageavg` float(7,2) DEFAULT NULL,
  `esxhost` varchar(255) DEFAULT NULL,
  KEY `Index_2` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:23
