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
-- Table structure for table `icasession`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `icasession` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `Caption` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Frequency_Object` bigint(40) DEFAULT NULL,
  `Frequency_PerfTime` bigint(40) DEFAULT NULL,
  `Frequency_Sys100NS` bigint(40) DEFAULT NULL,
  `InputAudioBandwidth` bigint(40) DEFAULT NULL,
  `InputClipboardBandwidt` bigint(40) DEFAULT NULL,
  `InputCOM1Bandwidth` bigint(40) DEFAULT NULL,
  `InputCOM2Bandwidth` bigint(40) DEFAULT NULL,
  `InputCOMBandwidth` bigint(40) DEFAULT NULL,
  `InputControlChannelBandwidth` bigint(40) DEFAULT NULL,
  `InputDriveBandwidth` bigint(40) DEFAULT NULL,
  `InputFontDataBandwidth` bigint(40) DEFAULT NULL,
  `InputLicensingBandwidth` bigint(40) DEFAULT NULL,
  `InputLPT1Bandwidth` bigint(40) DEFAULT NULL,
  `InputLPT2Bandwidth` bigint(40) DEFAULT NULL,
  `InputManagementBandwidth` bigint(40) DEFAULT NULL,
  `InputPNBandwidth` bigint(40) DEFAULT NULL,
  `InputPrinterBandwidth` bigint(40) DEFAULT NULL,
  `InputSeamlessBandwidth` bigint(40) DEFAULT NULL,
  `InputSessionBandwidth` bigint(40) DEFAULT NULL,
  `InputSessionCompression` bigint(40) DEFAULT NULL,
  `InputSessionLineSpeed` bigint(40) DEFAULT NULL,
  `InputSpeedScreenDataChannelBandwidth` bigint(40) DEFAULT NULL,
  `InputTextEchoBandwidth` bigint(40) DEFAULT NULL,
  `InputThinWireBandwidth` bigint(40) DEFAULT NULL,
  `InputVideoFrameBandwidth` bigint(40) DEFAULT NULL,
  `LatencyLastRecorded` bigint(40) DEFAULT NULL,
  `LatencySessionAverage` bigint(40) DEFAULT NULL,
  `LatencySessionDeviation` bigint(40) DEFAULT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `OutputAudioBandwidth` bigint(40) DEFAULT NULL,
  `OutputClipboardBandwidth` bigint(40) DEFAULT NULL,
  `OutputCOM1Bandwidth` bigint(40) DEFAULT NULL,
  `OutputCOM2Bandwidth` bigint(40) DEFAULT NULL,
  `OutputCOMBandwidth` bigint(40) DEFAULT NULL,
  `OutputControlChannelBandwidth` bigint(40) DEFAULT NULL,
  `OutputDriveBandwidth` bigint(40) DEFAULT NULL,
  `OutputFontDataBandwidth` bigint(40) DEFAULT NULL,
  `OutputLicensingBandwidth` bigint(40) DEFAULT NULL,
  `OutputLPT1Bandwidth` bigint(40) DEFAULT NULL,
  `OutputLPT2Bandwidth` bigint(40) DEFAULT NULL,
  `OutputManagementBandwidth` bigint(40) DEFAULT NULL,
  `OutputPNBandwidth` bigint(40) DEFAULT NULL,
  `OutputPrinterBandwidth` bigint(40) DEFAULT NULL,
  `OutputSeamlessBandwidth` bigint(40) DEFAULT NULL,
  `OutputSessionBandwidth` bigint(40) DEFAULT NULL,
  `OutputSessionCompression` bigint(40) DEFAULT NULL,
  `OutputSessionLineSpeed` bigint(40) DEFAULT NULL,
  `OutputSpeedScreenDataChannelBandwidth` bigint(40) DEFAULT NULL,
  `OutputTextEchoBandwidth` bigint(40) DEFAULT NULL,
  `OutputThinWireBandwidth` bigint(40) DEFAULT NULL,
  `OutputVideoFrameBandwidth` bigint(40) DEFAULT NULL,
  `Timestamp_Object` bigint(40) DEFAULT NULL,
  `Timestamp_PerfTime` bigint(40) DEFAULT NULL,
  `Timestamp_Sys100NS` bigint(40) DEFAULT NULL,
  KEY `Index_1` (`deviceid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-07 18:11:22
