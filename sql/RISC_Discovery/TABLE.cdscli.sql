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
-- Table structure for table `cdscli`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `cdscli` (
  `deviceid` bigint(40) DEFAULT NULL,
  `showversion` longtext,
  `showdiag` longtext,
  `showinventory` longtext,
  `showmodule` longtext,
  `showhardware` longtext,
  `showidprom` longtext,
  `showrun` longtext,
  `showconfig` longtext,
  `showmlsqos` longtext,
  `showmlsqosint` longtext,
  `showmlsqosintstats` longtext,
  `showpolicyint` longtext,
  `showlog` longtext,
  `showinterface` longtext,
  `showcallactivevoicebrief` longtext,
  `showmlsqosmaps` longtext,
  `showasicdrops` longtext,
  `showWaasStatus` longtext,
  `showLicense` longtext,
  `showLicenseAll` longtext,
  `showLicenseDetail` longtext,
  `showLicenseFeature` longtext,
  `showLicenseFile` longtext,
  `showLicenseFeatureMapping` longtext,
  `showLicenseRightUsage` longtext,
  `showLicenseRightDetail` longtext,
  `showLicenseRightSummary` longtext,
  `showLicenseUsage_LAN_ENTERPRISE_SERVICES_PKG` longtext,
  `showLicenseUsage_NETWORK_SERVICES_PKG` longtext,
  `showLicenseUsage_LAN_ENTERPRISE_ADVANCED_PKG` longtext,
  `showLicenseUsage_LAN_TRANSPORT_SERVICES_PKG` longtext,
  `showLicenseUsage_ENHANCED_LAYER_PKG` longtext,
  `showLicenseUsage_MPLS_PKG` longtext,
  `showLicenseUsage_FCOE_F2` longtext,
  `showLicenseUsage_STORAGE_ENT` longtext,
  `showLicenseUsage_SCALABLE_SERVICES_PKG` longtext,
  `showLicenseUsage_NEXUS1000V_LAN_SERVICES_PKG` longtext,
  `log` longtext,
  `scantime` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:21
