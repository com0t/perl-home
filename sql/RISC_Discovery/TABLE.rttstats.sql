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
-- Table structure for table `rttstats`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `rttstats` (
  `rttindex` int(10) unsigned DEFAULT NULL,
  `numofrtt` int(10) unsigned DEFAULT NULL,
  `rttsum` int(10) unsigned DEFAULT NULL,
  `rttmin` int(10) unsigned DEFAULT NULL,
  `rttmax` int(10) unsigned DEFAULT NULL,
  `loss_sd` int(10) unsigned DEFAULT NULL,
  `loss_ds` int(10) unsigned DEFAULT NULL,
  `oos` int(10) unsigned DEFAULT NULL,
  `mia` int(10) unsigned DEFAULT NULL,
  `late` int(10) unsigned DEFAULT NULL,
  `opersense` varchar(45) DEFAULT NULL,
  `delay_sd_avg` int(10) unsigned DEFAULT NULL,
  `delay_sd_max` int(10) unsigned DEFAULT NULL,
  `delay_ds_avg` int(10) unsigned DEFAULT NULL,
  `delay_ds_max` int(10) unsigned DEFAULT NULL,
  `mos` int(10) unsigned DEFAULT NULL,
  `icpif` int(10) unsigned DEFAULT NULL,
  `jitter_all_avg` int(10) unsigned DEFAULT NULL,
  `jitter_sd_avg` int(10) unsigned DEFAULT NULL,
  `jitter_sd_max` int(10) unsigned DEFAULT NULL,
  `jitter_ds_avg` int(10) unsigned DEFAULT NULL,
  `jitter_ds_max` int(10) unsigned DEFAULT NULL,
  `loss_ratio` int(10) unsigned DEFAULT NULL,
  `total_pkts` int(10) unsigned DEFAULT NULL,
  `ntpstatus` varchar(45) DEFAULT NULL,
  `scantime` bigint(40) DEFAULT NULL,
  KEY `Index_1` (`scantime`),
  KEY `Index_2` (`rttindex`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
