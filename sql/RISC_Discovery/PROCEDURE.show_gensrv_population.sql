/*!50003 DROP PROCEDURE IF EXISTS `show_gensrv_population` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `show_gensrv_population`(devid bigint unsigned)
BEGIN
	declare server int;
	declare sysinfo int;
	declare device int;
	declare part int;
	declare filesystem int;
	declare storage int;
	declare applications int;
	declare processes int;
	declare intf int;
	declare iptables int;
	declare entity int;

	select count(*) into server from gensrvserver where deviceid = devid;
	select count(*) into sysinfo from snmpsysinfo where deviceid = devid;
	select count(*) into device from gensrvdevice where deviceid = devid;
	select count(*) into part from gensrvpartition where deviceid = devid;
	select count(*) into filesystem from gensrvfilesystem where deviceid = devid;
	select count(*) into storage from gensrvstorage where deviceid = devid;
	select count(*) into applications from gensrvapplications where deviceid = devid;
	select count(*) into processes from gensrvprocesses where deviceid = devid;
	select count(*) into intf from interfaces where deviceid = devid;
	select count(*) into iptables from iptables where deviceid = devid;
	select count(*) into entity from deviceentity where deviceid = devid;

	select server,sysinfo,device,part,filesystem,storage,applications,processes,intf,iptables,entity;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
