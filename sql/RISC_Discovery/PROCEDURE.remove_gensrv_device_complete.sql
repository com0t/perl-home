/*!50003 DROP PROCEDURE IF EXISTS `remove_gensrv_device_complete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `remove_gensrv_device_complete`(devid bigint unsigned)
BEGIN
	DELETE FROM ssh_inv_detail WHERE deviceid = devid;
	DELETE FROM snmpsysinfo WHERE deviceid = devid;
	DELETE FROM gensrvserver WHERE deviceid = devid;
	DELETE FROM gensrvdevice WHERE deviceid = devid;
	DELETE FROM gensrvstorage WHERE deviceid = devid;
	DELETE FROM gensrvpartition WHERE deviceid = devid;
	DELETE FROM gensrvfilesystem WHERE deviceid = devid;
	DELETE FROM gensrvapplications WHERE deviceid = devid;
	DELETE FROM gensrvprocesses WHERE deviceid = devid;
	DELETE FROM gensrvperfcpu WHERE deviceid = devid;
	DELETE FROM gensrvperfdisk WHERE deviceid = devid;
	DELETE FROM gensrvperfdiskio WHERE deviceid = devid;
	DELETE FROM gensrvperfmem WHERE deviceid = devid;
	DELETE FROM riscdevice WHERE deviceid = devid;
	DELETE FROM credentials WHERE deviceid = devid;
	DELETE FROM iptables WHERE deviceid = devid;
	DELETE FROM iproutes WHERE deviceid = devid;
	DELETE FROM interfaces WHERE deviceid = devid;
	DELETE FROM deviceentity WHERE deviceid = devid;
	DELETE FROM ssh_inv_hardware WHERE deviceid = devid;
	DELETE FROM deviceid_fingerprint_map WHERE deviceid = did;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;