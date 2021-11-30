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
-- Table structure for table `windowsphysicaldisk`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `windowsphysicaldisk` (
  `deviceid` bigint(40) DEFAULT NULL,
  `bytespersector` bigint(40) DEFAULT NULL,
  `caption` varchar(200) DEFAULT NULL,
  `compressionmethod` varchar(100) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `diskdeviceid` varchar(255) DEFAULT NULL,
  `dindex` int(11) DEFAULT NULL,
  `interfacetype` varchar(255) DEFAULT NULL,
  `mediatype` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `partitions` int(11) DEFAULT NULL,
  `scsibus` int(11) DEFAULT NULL,
  `scsilogicalunit` int(11) DEFAULT NULL,
  `scsiport` int(11) DEFAULT NULL,
  `scsitargetid` int(11) DEFAULT NULL,
  `sectorspertrack` bigint(40) DEFAULT NULL,
  `size` bigint(40) DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `totalcylinders` bigint(20) DEFAULT NULL,
  `totalheads` bigint(20) DEFAULT NULL,
  `totalsectors` bigint(20) DEFAULT NULL,
  `totaltracks` bigint(20) DEFAULT NULL,
  `trackspercylinder` bigint(20) DEFAULT NULL,
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
