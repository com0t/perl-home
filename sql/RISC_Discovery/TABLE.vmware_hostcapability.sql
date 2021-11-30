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
-- Table structure for table `vmware_hostcapability`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `vmware_hostcapability` (
  `deviceid` bigint(20) unsigned DEFAULT NULL,
  `backgroundsnapshotssupported` varchar(10) DEFAULT NULL,
  `clonefromsnampshotsupported` varchar(10) DEFAULT NULL,
  `cpumemoryresourceconfigurationsupported` varchar(10) DEFAULT NULL,
  `datastoreprincipalsupported` varchar(10) DEFAULT NULL,
  `deltadiskbackingssupported` varchar(10) DEFAULT NULL,
  `ftsupported` varchar(10) DEFAULT NULL,
  `highguestmemsupported` varchar(10) DEFAULT NULL,
  `ipmisupported` varchar(10) DEFAULT NULL,
  `iscsisupported` varchar(10) DEFAULT NULL,
  `localswapdatastoresupported` varchar(10) DEFAULT NULL,
  `loginbysslthumbprintsupported` varchar(10) DEFAULT NULL,
  `maintenancemodesupported` varchar(10) DEFAULT NULL,
  `maxsupportedvcpus` int(10) unsigned DEFAULT NULL,
  `maxrunningvms` int(10) unsigned DEFAULT NULL,
  `maxsupportedvms` int(10) unsigned DEFAULT NULL,
  `nfssupported` varchar(10) DEFAULT NULL,
  `nicteamingsupported` varchar(10) DEFAULT NULL,
  `pervmnetworktrafficshapingsupported` varchar(10) DEFAULT NULL,
  `pervmswapfiles` varchar(10) DEFAULT NULL,
  `preassignedpciunitnumberssupported` varchar(10) DEFAULT NULL,
  `rebootsupported` varchar(10) DEFAULT NULL,
  `recordreplaysupported` varchar(10) DEFAULT NULL,
  `recursiveresourcepoolssupported` varchar(10) DEFAULT NULL,
  `replayunsuportedreason` varchar(255) DEFAULT NULL,
  `restrictedsnampshotrelocatesupported` varchar(10) DEFAULT NULL,
  `sansupported` varchar(10) DEFAULT NULL,
  `screenshotsupported` varchar(10) DEFAULT NULL,
  `shutdownsupported` varchar(10) DEFAULT NULL,
  `standbysupported` varchar(10) DEFAULT NULL,
  `storagevmotionsupported` varchar(10) DEFAULT NULL,
  `suspendedrelocatesupported` varchar(10) DEFAULT NULL,
  `tpmsupported` varchar(10) DEFAULT NULL,
  `unsharedswapvmotionsupported` varchar(10) DEFAULT NULL,
  `virtualexecusagesupported` varchar(10) DEFAULT NULL,
  `vlantaggingsupported` varchar(10) DEFAULT NULL,
  `vmotionsupported` varchar(10) DEFAULT NULL,
  `vmotionwithstoragevmotionsupported` varchar(10) DEFAULT NULL,
  `esxhost` varchar(50) DEFAULT NULL,
  `scantime` int(10) unsigned DEFAULT NULL,
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
