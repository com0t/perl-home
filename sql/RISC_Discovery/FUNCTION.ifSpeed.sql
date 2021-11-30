/*!50003 DROP FUNCTION IF EXISTS `ifSpeed` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE FUNCTION `ifSpeed`(var1 char(50)) RETURNS bigint(40)
NO SQL
BEGIN
	declare final bigint;
	if var1 regexp 'mb' then set final = ((cast(var1 as unsigned))*1000000);
	elseif var1 regexp 'gb' then set final = ((cast(var1 as unsigned))*1000000000);
	elseif var1 regexp 'kb' then set final = ((cast(var1 as unsigned))*1000);
	elseif var1 regexp 'Dual T1' then set final = 3088000;
	elseif var1 = 'T1' then set final = 1544000;
	elseif var1 regexp 'T3' then set final = 45000000;
	else set final = cast(var1 as unsigned);
	END IF;
	return final;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
