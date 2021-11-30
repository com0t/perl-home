/*!50003 DROP FUNCTION IF EXISTS `updatebpsin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE FUNCTION `updatebpsin`(var1 bigint(40), var2 int,var3 int,var4 bigint) RETURNS bigint(20)
BEGIN
	set @deviceid=var1;
	set @intindex=var2;
	set @scantime2=var3;
	set @bytes2=var4;
	select totalbytesin,scantime into @bytes1,@scantime1 from `RISC_Discovery`.traffic where deviceid=@deviceid AND intindex=@intindex AND scantime<@scantime2 order by scantime DESC limit 1;
	select if(@bytes2>=@bytes1,(@bytes2-@bytes1)/(@scantime2-@scantime1)*8,((@bytes2+4294967295)-@bytes1)/(@scantime2-@scantime1)*8)
	into @bpsin;
	select ifnull(@bpsin,0) into @bpsin;
	return @bpsin;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
