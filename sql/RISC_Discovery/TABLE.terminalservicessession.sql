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
-- Table structure for table `terminalservicessession`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `terminalservicessession` (
  `deviceid` bigint(40) DEFAULT NULL,
  `scantime` int(11) DEFAULT NULL,
  `Caption` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Frequency_Object` bigint(40) DEFAULT NULL,
  `Frequency_PerfTime` bigint(40) DEFAULT NULL,
  `Frequency_Sys100NS` bigint(40) DEFAULT NULL,
  `HandleCount` bigint(40) DEFAULT NULL,
  `InputAsyncFrameError` bigint(40) DEFAULT NULL,
  `InputAsyncOverflow` bigint(40) DEFAULT NULL,
  `InputAsyncOverrun` bigint(40) DEFAULT NULL,
  `InputAsyncParityError` bigint(40) DEFAULT NULL,
  `InputBytes` bigint(40) DEFAULT NULL,
  `InputCompressedBytes` bigint(40) DEFAULT NULL,
  `InputCompressFlushes` bigint(40) DEFAULT NULL,
  `InputCompressionRatio` bigint(40) DEFAULT NULL,
  `InputErrors` bigint(40) DEFAULT NULL,
  `InputFrames` bigint(40) DEFAULT NULL,
  `InputTimeouts` bigint(40) DEFAULT NULL,
  `InputTransportErrors` bigint(40) DEFAULT NULL,
  `InputWaitForOutBuf` bigint(40) DEFAULT NULL,
  `InputWdBytes` bigint(40) DEFAULT NULL,
  `InputWdFrames` bigint(40) DEFAULT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `OutputAsyncFrameError` bigint(40) DEFAULT NULL,
  `OutputAsyncOverflow` bigint(40) DEFAULT NULL,
  `OutputAsyncOverrun` bigint(40) DEFAULT NULL,
  `OutputAsyncParityError` bigint(40) DEFAULT NULL,
  `OutputBytes` bigint(40) DEFAULT NULL,
  `OutputCompressedBytes` bigint(40) DEFAULT NULL,
  `OutputCompressFlushes` bigint(40) DEFAULT NULL,
  `OutputCompressionRatio` bigint(40) DEFAULT NULL,
  `OutputErrors` bigint(40) DEFAULT NULL,
  `OutputFrames` bigint(40) DEFAULT NULL,
  `OutputTimeouts` bigint(40) DEFAULT NULL,
  `OutputTransportErrors` bigint(40) DEFAULT NULL,
  `OutputWaitForOutBuf` bigint(40) DEFAULT NULL,
  `OutputWdBytes` bigint(40) DEFAULT NULL,
  `OutputWdFrames` bigint(40) DEFAULT NULL,
  `PageFaultsPersec` bigint(40) DEFAULT NULL,
  `PageFileBytes` bigint(40) DEFAULT NULL,
  `PageFileBytesPeak` bigint(40) DEFAULT NULL,
  `PercentPrivilegedTime` bigint(40) DEFAULT NULL,
  `PercentProcessorTime` bigint(40) DEFAULT NULL,
  `PercentUserTime` bigint(40) DEFAULT NULL,
  `PoolNonpagedBytes` bigint(40) DEFAULT NULL,
  `PoolPagedBytes` bigint(40) DEFAULT NULL,
  `PrivateBytes` bigint(40) DEFAULT NULL,
  `ProtocolBitmapCacheHitRatio` bigint(40) DEFAULT NULL,
  `ProtocolBitmapCacheHits` bigint(40) DEFAULT NULL,
  `ProtocolBitmapCacheReads` bigint(40) DEFAULT NULL,
  `ProtocolBrushCacheHitRatio` bigint(40) DEFAULT NULL,
  `ProtocolBrushCacheHits` bigint(40) DEFAULT NULL,
  `ProtocolBrushCacheReads` bigint(40) DEFAULT NULL,
  `ProtocolGlyphCacheHitRatio` bigint(40) DEFAULT NULL,
  `ProtocolGlyphCacheHits` bigint(40) DEFAULT NULL,
  `ProtocolGlyphCacheReads` bigint(40) DEFAULT NULL,
  `ProtocolSaveScreenBitmapCacheHitRatio` bigint(40) DEFAULT NULL,
  `ProtocolSaveScreenBitmapCacheHits` bigint(40) DEFAULT NULL,
  `ProtocolSaveScreenBitmapCacheReads` bigint(40) DEFAULT NULL,
  `ThreadCount` bigint(40) DEFAULT NULL,
  `Timestamp_Object` bigint(40) DEFAULT NULL,
  `Timestamp_PerfTime` bigint(40) DEFAULT NULL,
  `Timestamp_Sys100NS` bigint(40) DEFAULT NULL,
  `TotalAsyncFrameError` bigint(40) DEFAULT NULL,
  `TotalAsyncOverflow` bigint(40) DEFAULT NULL,
  `TotalAsyncOverrun` bigint(40) DEFAULT NULL,
  `TotalAsyncParityError` bigint(40) DEFAULT NULL,
  `TotalBytes` bigint(40) DEFAULT NULL,
  `TotalCompressedBytes` bigint(40) DEFAULT NULL,
  `TotalCompressFlushes` bigint(40) DEFAULT NULL,
  `TotalCompressionRatio` bigint(40) DEFAULT NULL,
  `TotalErrors` bigint(40) DEFAULT NULL,
  `TotalFrames` bigint(40) DEFAULT NULL,
  `TotalProtocolCacheHitRatio` bigint(40) DEFAULT NULL,
  `TotalProtocolCacheHits` bigint(40) DEFAULT NULL,
  `TotalProtocolCacheReads` bigint(40) DEFAULT NULL,
  `TotalTimeouts` bigint(40) DEFAULT NULL,
  `TotalTransportErrors` bigint(40) DEFAULT NULL,
  `TotalWaitForOutBuf` bigint(40) DEFAULT NULL,
  `TotalWdBytes` bigint(40) DEFAULT NULL,
  `TotalWdFrames` bigint(40) DEFAULT NULL,
  `VirtualBytes` bigint(40) DEFAULT NULL,
  `VirtualBytesPeak` bigint(40) DEFAULT NULL,
  `WorkingSet` bigint(40) DEFAULT NULL,
  `WorkingSetPeak` bigint(40) DEFAULT NULL,
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
