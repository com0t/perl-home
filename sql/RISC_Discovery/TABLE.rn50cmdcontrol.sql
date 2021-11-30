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
-- Table structure for table `rn50cmdcontrol`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `rn50cmdcontrol` (
  `commandid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rn50id` varchar(200) NOT NULL,
  `execfile` varchar(200) NOT NULL,
  `commandtype` varchar(100) NOT NULL,
  `arg1` varchar(200) NOT NULL,
  `arg2` varchar(200) NOT NULL,
  `arg3` varchar(200) NOT NULL,
  `arg4` varchar(200) NOT NULL,
  `arg5` varchar(200) NOT NULL,
  `arg6` varchar(200) NOT NULL,
  `arg7` varchar(200) NOT NULL,
  `arg8` varchar(200) NOT NULL,
  `arg9` varchar(200) NOT NULL,
  `arg10` varchar(200) NOT NULL,
  `status` int(10) unsigned NOT NULL,
  `orig` int(10) unsigned NOT NULL,
  `pause` int(10) unsigned NOT NULL,
  `active` int(10) unsigned NOT NULL,
  `scheduletime` int(10) unsigned NOT NULL,
  `pickuptime` int(10) unsigned NOT NULL,
  `completedtime` int(10) unsigned NOT NULL,
  `returncode` text NOT NULL,
  PRIMARY KEY (`commandid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
