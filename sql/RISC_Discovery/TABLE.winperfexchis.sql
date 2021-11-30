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
-- Table structure for table `winperfexchis`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `winperfexchis` (
  `deviceid` bigint(40) unsigned DEFAULT NULL,
  `scantime` bigint(40) unsigned DEFAULT NULL,
  `activeanonymoususercount` bigint(40) unsigned DEFAULT NULL,
  `activeconnectioncount` int(10) unsigned DEFAULT NULL,
  `activeusercount` bigint(40) unsigned DEFAULT NULL,
  `adminrpcrequests` bigint(40) unsigned DEFAULT NULL,
  `adminrpcrequestspeak` int(10) unsigned DEFAULT NULL,
  `anonymoususercount` bigint(40) unsigned DEFAULT NULL,
  `appointmentinstancecreationrate` bigint(40) unsigned DEFAULT NULL,
  `appointmentinstancedeletionrate` bigint(40) unsigned DEFAULT NULL,
  `appointmentinstancescreated` bigint(40) unsigned DEFAULT NULL,
  `appointmentinstancesdeleted` bigint(40) unsigned DEFAULT NULL,
  `asyncnotificationscachesize` bigint(40) unsigned DEFAULT NULL,
  `asyncnotificationsgeneratedpersec` bigint(40) unsigned DEFAULT NULL,
  `asyncrpcrequests` bigint(40) unsigned DEFAULT NULL,
  `asyncrpcrequestspeak` bigint(40) unsigned DEFAULT NULL,
  `backgroundexpansionqueuelength` bigint(40) unsigned DEFAULT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `ciqpthreads` bigint(40) unsigned DEFAULT NULL,
  `clientbackgroundrpcsfailed` bigint(40) unsigned DEFAULT NULL,
  `clientbackgroundrpcsfailedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientbackgroundrpcssucceeded` bigint(40) unsigned DEFAULT NULL,
  `clientbackgroundrpcssucceededpersec` bigint(40) unsigned DEFAULT NULL,
  `clientforegroundrpcsfailed` bigint(40) unsigned DEFAULT NULL,
  `clientforegroundrpcsfailedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientforegroundrpcssucceeded` bigint(40) unsigned DEFAULT NULL,
  `clientforegroundrpcssucceededpersec` bigint(40) unsigned DEFAULT NULL,
  `clientlatency10secrpcs` bigint(40) unsigned DEFAULT NULL,
  `clientlatency2secrpcs` bigint(40) unsigned DEFAULT NULL,
  `clientlatency5secrpcs` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsattempted` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsattemptedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailed` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedaccessdenied` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedaccessdeniedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedallothererrors` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedallothererrorspersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedcallcancelled` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedcallcancelledpersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedcallfailed` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedcallfailedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedpersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedservertoobusy` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedservertoobusypersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedserverunavailable` bigint(40) unsigned DEFAULT NULL,
  `clientrpcsfailedserverunavailablepersec` bigint(40) unsigned DEFAULT NULL,
  `clientrpcssucceeded` bigint(40) unsigned DEFAULT NULL,
  `clientrpcssucceededpersec` bigint(40) unsigned DEFAULT NULL,
  `clienttotalreportedlatency` bigint(40) unsigned DEFAULT NULL,
  `connectioncount` int(10) unsigned DEFAULT NULL,
  `description` text,
  `dlmembershipcacheentriescount` bigint(40) unsigned DEFAULT NULL,
  `dlmembershipcachehits` bigint(40) unsigned DEFAULT NULL,
  `dlmembershipcachemisses` bigint(40) unsigned DEFAULT NULL,
  `dlmembershipcachesize` bigint(40) unsigned DEFAULT NULL,
  `exchmemcurrentbytesallocated` bigint(40) unsigned DEFAULT NULL,
  `exchmemcurrentnumberofvirtualallocations` int(10) unsigned DEFAULT NULL,
  `exchmemcurrentvirtualbytesallocated` bigint(40) unsigned DEFAULT NULL,
  `exchmemmaximumbytesallocated` bigint(40) unsigned DEFAULT NULL,
  `exchmemmaximumvirtualbytesallocated` bigint(40) unsigned DEFAULT NULL,
  `exchmemnumberofadditionalheaps` bigint(40) unsigned DEFAULT NULL,
  `exchmemnumberofheaps` int(10) unsigned DEFAULT NULL,
  `exchmemnumberofheapswithmemoryerrors` bigint(40) unsigned DEFAULT NULL,
  `exchmemnumberofmemoryerrors` bigint(40) unsigned DEFAULT NULL,
  `exchmemtotalnumberofvirtualallocations` bigint(40) unsigned DEFAULT NULL,
  `fbpublishcount` bigint(40) unsigned DEFAULT NULL,
  `fbpublishrate` bigint(40) unsigned DEFAULT NULL,
  `maximumanonymoususers` bigint(40) unsigned DEFAULT NULL,
  `maximumconnections` int(10) unsigned DEFAULT NULL,
  `maximumusers` bigint(40) unsigned DEFAULT NULL,
  `messagecreatepersec` bigint(40) unsigned DEFAULT NULL,
  `messagedeletepersec` bigint(40) unsigned DEFAULT NULL,
  `messagemodifypersec` bigint(40) unsigned DEFAULT NULL,
  `messagemovepersec` bigint(40) unsigned DEFAULT NULL,
  `messagesprereadascendingpersec` bigint(40) unsigned DEFAULT NULL,
  `messagesprereaddescendingpersec` bigint(40) unsigned DEFAULT NULL,
  `messagesprereadskippedpersec` bigint(40) unsigned DEFAULT NULL,
  `minimsgcreatedforviewspersec` bigint(40) unsigned DEFAULT NULL,
  `minimsgmsgtableseekspersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsdeletedpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsdeletesdeferredpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsinsertedpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewrecordsinsertsdeferredpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablecreatepersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtabledeletepersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablenullrefreshpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablerefreshdvurecordsscanned` int(10) unsigned DEFAULT NULL,
  `msgviewtablerefreshpersec` bigint(40) unsigned DEFAULT NULL,
  `msgviewtablerefreshupdatesapplied` bigint(40) unsigned DEFAULT NULL,
  `name` text,
  `oabdifferentialdownloadattempts` bigint(40) unsigned DEFAULT NULL,
  `oabdifferentialdownloadbytes` bigint(40) unsigned DEFAULT NULL,
  `oabdifferentialdownloadbytespersec` bigint(40) unsigned DEFAULT NULL,
  `oabfulldownloadattempts` bigint(40) unsigned DEFAULT NULL,
  `oabfulldownloadattemptsblocked` bigint(40) unsigned DEFAULT NULL,
  `oabfulldownloadbytes` bigint(40) unsigned DEFAULT NULL,
  `oabfulldownloadbytespersec` bigint(40) unsigned DEFAULT NULL,
  `peakasyncnotificationscachesize` int(10) unsigned DEFAULT NULL,
  `peakpushnotificationscachesize` bigint(40) unsigned DEFAULT NULL,
  `percentconnections` bigint(40) unsigned DEFAULT NULL,
  `percentrpcthreads` bigint(40) unsigned DEFAULT NULL,
  `pushnotificationscachesize` bigint(40) unsigned DEFAULT NULL,
  `pushnotificationsgeneratedpersec` bigint(40) unsigned DEFAULT NULL,
  `pushnotificationsskippedpersec` bigint(40) unsigned DEFAULT NULL,
  `readbytesrpcclientspersec` bigint(40) unsigned DEFAULT NULL,
  `recurringappointmentdeletionrate` bigint(40) unsigned DEFAULT NULL,
  `recurringappointmentmodificationrate` bigint(40) unsigned DEFAULT NULL,
  `recurringappointmentscreated` int(10) unsigned DEFAULT NULL,
  `recurringappointmentsdeleted` int(10) unsigned DEFAULT NULL,
  `recurringappointmentsmodified` int(10) unsigned DEFAULT NULL,
  `recurringapppointmentcreationrate` bigint(40) unsigned DEFAULT NULL,
  `recurringmasterappointmentsexpanded` bigint(40) unsigned DEFAULT NULL,
  `recurringmasterexpansionrate` bigint(40) unsigned DEFAULT NULL,
  `rpcaveragedlatency` bigint(40) unsigned DEFAULT NULL,
  `rpcclientbackoffpersec` bigint(40) unsigned DEFAULT NULL,
  `rpcclientsbytesread` bigint(40) unsigned DEFAULT NULL,
  `rpcclientsbyteswritten` bigint(40) unsigned DEFAULT NULL,
  `rpcclientsuncompressedbytesread` bigint(40) unsigned DEFAULT NULL,
  `rpcclientsuncompressedbyteswritten` bigint(40) unsigned DEFAULT NULL,
  `rpcnumofslowpackets` bigint(40) unsigned DEFAULT NULL,
  `rpcoperationspersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpacketspersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolasyncnotificationsgeneratedpersec` bigint(40) unsigned DEFAULT NULL,
  `rpcpoolcontexthandles` int(10) unsigned DEFAULT NULL,
  `rpcpoolparkedasyncnotificationcalls` int(10) unsigned DEFAULT NULL,
  `rpcpoolpools` int(10) unsigned DEFAULT NULL,
  `rpcpoolsessionnotificationspending` int(10) unsigned DEFAULT NULL,
  `rpcpoolsessions` int(10) unsigned DEFAULT NULL,
  `rpcrequests` bigint(40) unsigned DEFAULT NULL,
  `rpcrequestspeak` int(10) unsigned DEFAULT NULL,
  `rpcrequesttimeoutdetected` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentcreationrate` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentdeletionrate` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentmodificationrate` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentscreated` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentsdeleted` bigint(40) unsigned DEFAULT NULL,
  `singleappointmentsmodified` int(10) unsigned DEFAULT NULL,
  `slowqpthreads` bigint(40) unsigned DEFAULT NULL,
  `slowsearchthreads` bigint(40) unsigned DEFAULT NULL,
  `totalparkedasyncnotificationcalls` bigint(40) unsigned DEFAULT NULL,
  `usercount` bigint(40) unsigned DEFAULT NULL,
  `viewcleanupcategorizationindexdeletionspersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanupdvuentrydeletionspersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanuprestrictionindexdeletionspersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanupsearchindexdeletionspersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanupsortindexdeletionspersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanuptasksnullifiedpersec` bigint(40) unsigned DEFAULT NULL,
  `viewcleanuptaskspersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanbytesscanned` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilescleaned` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilescleanedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilesquarantined` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilesquarantinedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilesscanned` bigint(40) unsigned DEFAULT NULL,
  `virusscanfilesscannedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanfoldersscannedinbackground` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagescleaned` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagescleanedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesdeleted` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesdeletedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesprocessed` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesprocessedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesquarantined` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesquarantinedpersec` bigint(40) unsigned DEFAULT NULL,
  `virusscanmessagesscannedinbackground` bigint(40) unsigned DEFAULT NULL,
  `virusscanqueuelength` bigint(40) unsigned DEFAULT NULL,
  `vmlargestblocksize` bigint(40) unsigned DEFAULT NULL,
  `vmtotal16mbfreeblocks` int(10) unsigned DEFAULT NULL,
  `vmtotalfreeblocks` int(10) unsigned DEFAULT NULL,
  `vmtotallargefreeblockbytes` bigint(40) unsigned DEFAULT NULL,
  `writebytesrpcclientspersec` bigint(40) unsigned DEFAULT NULL,
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