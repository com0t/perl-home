/*!50003 DROP FUNCTION IF EXISTS `RISC_Flow_Protocol2` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE FUNCTION `RISC_Flow_Protocol2`(vsourcePort int, vdestPort int, vtransport varchar(40)) RETURNS char(255) CHARSET latin1
BEGIN

	declare destName varchar(255);
	declare sourceName varchar(255);
	declare otherName varchar(255);
	set destName='not defined';
	set sourceName='not defined';
	set otherName='not defined';
	select name into destName from protocol where transport=vtransport and vdestPort>=DestStartPort AND vdestPort<=DestEndPort limit 1;
	if (destName='not defined') THEN
		select name into sourceName from protocol where transport=vtransport and vsourcePort>=SourceStartPort AND vsourcePort<=SourceEndPort limit 1;
		if (sourceName='not defined') THEN
			select IF((vtransport='udp' AND vsourcePort >= 16384 AND vsourcePort <= 32768 AND vdestPort >= 16384 AND vdestPort <= 32768),'RTP',otherName) into otherName;
			select IF((vtransport='udp' AND vsourcePort >= 55000 AND vdestPort >= 55000),'TrafficSim',otherName) into otherName;
			if (otherName='not defined') THEN
				if (vtransport='tcp' or vtransport='udp') THEN
					set otherName=concat(vtransport,'-',least(vsourcePort,vdestPort));
					return otherName;
				else
					set otherName=vtransport;
					return vtransport;
				end if;
			else
				return otherName;
			end if;
		else
			return sourceName;
		end if;
	else
		return destName;
	end if;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
