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
-- Table structure for table `winperfexchavailservice`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchavailservice` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `availabilityrequestssec` bigint(40) unsigned DEFAULT NULL,
  `averagenumberofmailboxesprocessedperrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetomapexternalcallertointernalidentity` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessacrossforestfreebusyrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessacrosssitefreebusyrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessafederatedfreebusyrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessafreebusyrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessameetingsuggestionsrequest` bigint(40) unsigned DEFAULT NULL,
  `averagetimetoprocessanintrasitefreebusyrequest` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `clientreportedfailuresautodiscoverfailures` bigint(40) unsigned DEFAULT NULL,
  `clientreportedfailuresconnectionfailures` bigint(40) unsigned DEFAULT NULL,
  `clientreportedfailurespartialorotherfailures` bigint(40) unsigned DEFAULT NULL,
  `clientreportedfailurestimeoutfailures` bigint(40) unsigned DEFAULT NULL,
  `clientreportedfailurestotal` bigint(40) unsigned DEFAULT NULL,
  `crossforestcalendarfailuressec` bigint(40) unsigned DEFAULT NULL,
  `crossforestcalendarqueriessec` bigint(40) unsigned DEFAULT NULL,
  `crosssitecalendarfailuressec` bigint(40) unsigned DEFAULT NULL,
  `crosssitecalendarqueriessec` bigint(40) unsigned DEFAULT NULL,
  `currentrequests` bigint(40) unsigned DEFAULT NULL,
  `description` text,
  `federatedfreebusycalendarqueriessec` bigint(40) unsigned DEFAULT NULL,
  `federatedfreebusyfailuressec` bigint(40) unsigned DEFAULT NULL,
  `foreignconnectorqueriessec` bigint(40) unsigned DEFAULT NULL,
  `foreignconnectorrequestfailurerate` bigint(40) unsigned DEFAULT NULL,
  `intrasitecalendarfailuressec` bigint(40) unsigned DEFAULT NULL,
  `intrasitecalendarqueriessec` bigint(40) unsigned DEFAULT NULL,
  `intrasiteproxyfreebusycalendarqueriessec` bigint(40) unsigned DEFAULT NULL,
  `intrasiteproxyfreebusyfailuressec` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `publicfolderqueriessec` bigint(40) unsigned DEFAULT NULL,
  `publicfolderrequestfailuressec` bigint(40) unsigned DEFAULT NULL,
  `successfulclientreportedrequestslessthan10seconds` bigint(40) unsigned DEFAULT NULL,
  `successfulclientreportedrequestslessthan20seconds` bigint(40) unsigned DEFAULT NULL,
  `successfulclientreportedrequestslessthan5seconds` bigint(40) unsigned DEFAULT NULL,
  `successfulclientreportedrequestsover20seconds` bigint(40) unsigned DEFAULT NULL,
  `successfulclientreportedrequeststotal` bigint(40) unsigned DEFAULT NULL,
  `suggestionsrequestssec` bigint(40) unsigned DEFAULT NULL,
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
