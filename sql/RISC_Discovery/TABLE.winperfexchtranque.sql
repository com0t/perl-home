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
-- Table structure for table `winperfexchtranque`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchtranque` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `activemailboxdeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `activenonsmtpdeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `activeremotedeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `aggregatedeliveryqueuelengthallqueues` bigint(40) unsigned DEFAULT NULL,
  `aggregateshadowqueuelength` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `categorizerjobavailability` int(10) unsigned DEFAULT NULL,
  `description` text,
  `itemscompleteddeliverypersecond` int(10) unsigned DEFAULT NULL,
  `itemscompleteddeliverytotal` int(10) unsigned DEFAULT NULL,
  `itemsdeletedbyadmintotal` bigint(40) unsigned DEFAULT NULL,
  `itemsqueuedfordeliveryexpiredtotal` bigint(40) unsigned DEFAULT NULL,
  `itemsqueuedfordeliverypersecond` int(10) unsigned DEFAULT NULL,
  `itemsqueuedfordeliverytotal` int(10) unsigned DEFAULT NULL,
  `itemsresubmittedtotal` bigint(40) unsigned DEFAULT NULL,
  `largestdeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `messagescompleteddeliverypersecond` int(10) unsigned DEFAULT NULL,
  `messagescompleteddeliverytotal` int(10) unsigned DEFAULT NULL,
  `messagescompletingcategorization` int(10) unsigned DEFAULT NULL,
  `messagesdeferredduringcategorization` bigint(40) unsigned DEFAULT NULL,
  `messagesqueuedfordelivery` bigint(40) unsigned DEFAULT NULL,
  `messagesqueuedfordeliverypersecond` int(10) unsigned DEFAULT NULL,
  `messagesqueuedfordeliverytotal` int(10) unsigned DEFAULT NULL,
  `messagessubmittedpersecond` int(10) unsigned DEFAULT NULL,
  `messagessubmittedtotal` int(10) unsigned DEFAULT NULL,
  `name` text,
  `poisonqueuelength` bigint(40) unsigned DEFAULT NULL,
  `retrymailboxdeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `retrynonsmtpdeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `retryremotedeliveryqueuelength` bigint(40) unsigned DEFAULT NULL,
  `shadowqueueautodiscardstotal` bigint(40) unsigned DEFAULT NULL,
  `submissionqueueitemsexpiredtotal` bigint(40) unsigned DEFAULT NULL,
  `submissionqueuelength` bigint(40) unsigned DEFAULT NULL,
  `unreachablequeuelength` bigint(40) unsigned DEFAULT NULL,
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
