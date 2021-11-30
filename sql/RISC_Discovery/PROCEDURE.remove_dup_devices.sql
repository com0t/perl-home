/*!50003 DROP PROCEDURE IF EXISTS `remove_dup_devices` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `remove_dup_devices`()
BEGIN
	drop temporary table if exists devicebyip;
	create temporary table devicebyip (
		deviceid bigint,
		ipaddress varchar(75),
		num int
	);
	insert into devicebyip select deviceid, ipaddress, count(*) from riscdevice where
	deviceid not in (select deviceid from windowsos where deviceid is not null)
	and deviceid not in (select deviceid from riscvmwarematrix where deviceid is not null)
	group by ipaddress having count(*) >= 2 order by count(*) desc;
	delete from riscdevice where macaddr not regexp ':' and deviceid in (select deviceid from devicebyip);
	drop temporary table devicebyip;
	delete from riscdevice where macaddr not regexp ':' and ipaddress in (select ip from iptables);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
