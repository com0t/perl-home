/*!50003 DROP PROCEDURE IF EXISTS `mac_manufacturer_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `mac_manufacturer_update`()
BEGIN
	drop temporary table if exists iptomanufacturer;
	create temporary table iptomanufacturer (
		deviceid bigint,
		mac varchar(75),
		manufacturer varchar(200)
	);
	select database() into @db;
	select length(table_name) into @tableexists from `INFORMATION_SCHEMA`.TABLES where table_schema = @db AND table_name LIKE 'realtime';
	select ifnull(@tableexists,99999) into @testme;
	case @testme
	WHEN 99999 THEN
		update riscdevice set sysdescription = sysdescription;
	ELSE update riscdevice set sysdescription = (select group_CONCAT(Name," : ",Class," : Callmanager(",Callmanager,")",Status) from realtime where riscdevice.ipaddress = realtime.IpAddress group by realtime.IpAddress) where riscdevice.ipaddress in (select IpAddress from realtime) and riscdevice.macaddr not regexp ':';
	END CASE;
	insert into iptomanufacturer (deviceid, mac) select riscdevice.deviceid, iptomac.mac from riscdevice, iptomac where riscdevice.sysdescription regexp 'unknown' and riscdevice.ipaddress=iptomac.remoteip;
	update iptomanufacturer, macmanufacturer set iptomanufacturer.manufacturer=macmanufacturer.manufacturer where substring(iptomanufacturer.mac,1,8)=macmanufacturer.oui;
	update riscdevice, iptomanufacturer set riscdevice.sysdescription=concat('Inaccessible Device, Mac Manufacturer: ',iptomanufacturer.manufacturer)where riscdevice.sysdescription='unknown' and iptomanufacturer.manufacturer is not null and riscdevice.deviceid=iptomanufacturer.deviceid and not exists (select * from windowsos where windowsos.deviceid=riscdevice.deviceid);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
