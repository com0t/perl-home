/*!50003 DROP PROCEDURE IF EXISTS `RemoveSANDevice` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `RemoveSANDevice`(devID bigint)
BEGIN
	delete from `RISC_Discovery`.cfccporttable where deviceid=devID;
	delete from `RISC_Discovery`.cfmmulticastroottable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiintrprttable where deviceid=devID;
	delete from `RISC_Discovery`.csanbasesvcinterfacetable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsitgtporttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsilutable where deviceid=devID;
	delete from `RISC_Discovery`.cfcsdvvirtrealdevmaptable where deviceid=devID;
	delete from `RISC_Discovery`.fcsplatformtable where deviceid=devID;
	delete from `RISC_Discovery`.csanbasesvcclustermemberiftable where deviceid=devID;
	delete from `RISC_Discovery`.fcsmgmtaddrlisttable where deviceid=devID;
	delete from `RISC_Discovery`.cspanvsanfiltertable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiflowtable where deviceid=devID;
	delete from `RISC_Discovery`.fcsnodenamelisttable where deviceid=devID;
	delete from `RISC_Discovery`.cfcsdvvirtdevicetable where deviceid=devID;
	delete from `RISC_Discovery`.cstserviceconfigtable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiattintrprttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiintrdevtable where deviceid=devID;
	delete from `RISC_Discovery`.cspansourcesvsantable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoextscsigeninstancetable where deviceid=devID;
	delete from `RISC_Discovery`.fcsstatstable where deviceid=devID;
	delete from `RISC_Discovery`.fcroutetable where deviceid=devID;
	delete from `RISC_Discovery`.fciftable where deviceid=devID;
	delete from `RISC_Discovery`.cfcspifstatstable where deviceid=devID;
	delete from `RISC_Discovery`.virtualnwiftable where deviceid=devID;
	delete from `RISC_Discovery`.fciferrortable where deviceid=devID;
	delete from `RISC_Discovery`.fctraceroutehopstable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiauthorizedintrtable where deviceid=devID;
	delete from `RISC_Discovery`.cstmoduletable where deviceid=devID;
	delete from `RISC_Discovery`.fcifelptable where deviceid=devID;
	delete from `RISC_Discovery`.fcpingstatstable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsidsctgttable where deviceid=devID;
	delete from `RISC_Discovery`.cspansourcesiftable where deviceid=devID;
	delete from `RISC_Discovery`.fcifc2accountingtable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsidscluntable where deviceid=devID;
	delete from `RISC_Discovery`.fcifcaptable where deviceid=devID;
	delete from `RISC_Discovery`.fctraceroutetable where deviceid=devID;
	delete from `RISC_Discovery`.fcifflogintable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoextscsiintrdisctgttable where deviceid=devID;
	delete from `RISC_Discovery`.fcifcfaccountingtable where deviceid=devID;
	delete from `RISC_Discovery`.fcsporttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsitgtdevtable where deviceid=devID;
	delete from `RISC_Discovery`.fctrunkiftable where deviceid=devID;
	delete from `RISC_Discovery`.cfcsplocalpasswdtable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsidsclunidtable where deviceid=devID;
	delete from `RISC_Discovery`.cfcspremotepasswdtable where deviceid=devID;
	delete from `RISC_Discovery`.fcifstattable where deviceid=devID;
	delete from `RISC_Discovery`.cspansessiontable where deviceid=devID;
	delete from `RISC_Discovery`.fcsdiscoverystatustable where deviceid=devID;
	delete from `RISC_Discovery`.cfcspiftable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsitrnspttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiflowwraccstatustable where deviceid=devID;
	delete from `RISC_Discovery`.fcpingtable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiflowstatsstatustable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoextscsiintrdisclunstable where deviceid=devID;
	delete from `RISC_Discovery`.cspanvsanfilteroptable where deviceid=devID;
	delete from `RISC_Discovery`.fcifc3accountingtable where deviceid=devID;
	delete from `RISC_Discovery`.fcifrnidinfotable where deviceid=devID;
	delete from `RISC_Discovery`.fcifgigetable where deviceid=devID;
	delete from `RISC_Discovery`.cfdmihbainfotable where deviceid=devID;
	delete from `RISC_Discovery`.fcifcaposmtable where deviceid=devID;
	delete from `RISC_Discovery`.cfdaconfigtable where deviceid=devID;
	delete from `RISC_Discovery`.csanbasesvcdeviceporttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiporttable where deviceid=devID;
	delete from `RISC_Discovery`.csanbasesvcclustermemberstable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiinstancetable where deviceid=devID;
	delete from `RISC_Discovery`.fcifcapfrmtable where deviceid=devID;
	delete from `RISC_Discovery`.fcsattachportnamelisttable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiflowstatstable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsidevicetable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoextscsipartiallundisctable where deviceid=devID;
	delete from `RISC_Discovery`.csanbasesvcclustertable where deviceid=devID;
	delete from `RISC_Discovery`.cfdmihbaportentry where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsilunmaptable where deviceid=devID;
	delete from `RISC_Discovery`.cipnetworkinterfacetable where deviceid=devID;
	delete from `RISC_Discovery`.fcsportlisttable where deviceid=devID;
	delete from `RISC_Discovery`.cspansourcesvsancfgtable where deviceid=devID;
	delete from `RISC_Discovery`.cipnetworktable where deviceid=devID;
	delete from `RISC_Discovery`.ciscoscsiatttgtporttable where deviceid=devID;
	delete from `RISC_Discovery`.fcrouteflowstattable where deviceid=devID;
	delete from `RISC_Discovery`.fcsietable where deviceid=devID;
	delete from `RISC_Discovery`.swfcporttable where deviceid=devID;
	delete from `RISC_Discovery`.frutable where deviceid=devID;
	delete from `RISC_Discovery`.swenddevicerlstable where deviceid=devID;
	delete from `RISC_Discovery`.swblmperffltmnttable where deviceid=devID;
	delete from `RISC_Discovery`.swgrouptable where deviceid=devID;
	delete from `RISC_Discovery`.swtrunktable where deviceid=devID;
	delete from `RISC_Discovery`.swnbtable where deviceid=devID;
	delete from `RISC_Discovery`.swblmperfeemnttable where deviceid=devID;
	delete from `RISC_Discovery`.swagtcmtytable where deviceid=devID;
	delete from `RISC_Discovery`.swfwclassareatable where deviceid=devID;
	delete from `RISC_Discovery`.swfabricmemtable where deviceid=devID;
	delete from `RISC_Discovery`.swfwthresholdtable where deviceid=devID;
	delete from `RISC_Discovery`.swgroupmemtable where deviceid=devID;
	delete from `RISC_Discovery`.fcipextendedlinktable where deviceid=devID;
	delete from `RISC_Discovery`.cptable where deviceid=devID;
	delete from `RISC_Discovery`.swblmperfalpamnttable where deviceid=devID;
	delete from `RISC_Discovery`.fruhistorytable where deviceid=devID;
	delete from `RISC_Discovery`.swsensortable where deviceid=devID;
	delete from `RISC_Discovery`.swtrunkgrptable where deviceid=devID;
	delete from `RISC_Discovery`.swnslocaltable where deviceid=devID;
	delete from `RISC_Discovery`.sweventtable where deviceid=devID;
	delete from `RISC_Discovery`.t11nsregtable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsstatstable where deviceid=devID;
	delete from `RISC_Discovery`.t11fspflinktable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxporttable where deviceid=devID;
	delete from `RISC_Discovery`.t11fspftable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsactivetable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportc2accountingtable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsnodenamelisttable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcroutetable where deviceid=devID;
	delete from `RISC_Discovery`.fcmswitchtable where deviceid=devID;
	delete from `RISC_Discovery`.fcmportstatstable where deviceid=devID;
	delete from `RISC_Discovery`.t11vfporttable where deviceid=devID;
	delete from `RISC_Discovery`.t11zssettable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsactivezonetable where deviceid=devID;
	delete from `RISC_Discovery`.fcmlinktable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsfabricdiscoverytable where deviceid=devID;
	delete from `RISC_Discovery`.t11zssetzonetable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcrscnnotifycontroltable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsattribblocktable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsservertable where deviceid=devID;
	delete from `RISC_Discovery`.t11famdatabasetable where deviceid=devID;
	delete from `RISC_Discovery`.t11vfvirtualswitchtable where deviceid=devID;
	delete from `RISC_Discovery`.t11zszonetable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsplatformtable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsstatstable where deviceid=devID;
	delete from `RISC_Discovery`.fcmporterrorstable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcrscnregtable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsaliastable where deviceid=devID;
	delete from `RISC_Discovery`.t11nsrejecttable where deviceid=devID;
	delete from `RISC_Discovery`.t11nsinfosubsettable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportphystable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportstatustable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxporterrortable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsactiveattribtable where deviceid=devID;
	delete from `RISC_Discovery`.t11vfcoreswitchtable where deviceid=devID;
	delete from `RISC_Discovery`.t11nsregfc4descriptortable where deviceid=devID;
	delete from `RISC_Discovery`.t11fspfiftable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportc1accountingtable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcrscnstatstable where deviceid=devID;
	delete from `RISC_Discovery`.t11famiftable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsietable where deviceid=devID;
	delete from `RISC_Discovery`.fc_t11famtable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsattribtable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsactivatetable where deviceid=devID;
	delete from `RISC_Discovery`.t11famareatable where deviceid=devID;
	delete from `RISC_Discovery`.fcmfxporttable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsdiscoverystatetable where deviceid=devID;
	delete from `RISC_Discovery`.t11famfcidcachetable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxlogintable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsmgmtaddrlisttable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportc3accountingtable where deviceid=devID;
	delete from `RISC_Discovery`.t11vflocallyenabledtable where deviceid=devID;
	delete from `RISC_Discovery`.t11nsstatstable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsporttable where deviceid=devID;
	delete from `RISC_Discovery`.fcminstancetable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsactivezonemembertable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsattachportnamelisttable where deviceid=devID;
	delete from `RISC_Discovery`.fcmportlcstatstable where deviceid=devID;
	delete from `RISC_Discovery`.fcmflogintable where deviceid=devID;
	delete from `RISC_Discovery`.t11fspflsrtable where deviceid=devID;
	delete from `RISC_Discovery`.fcfemoduletable where deviceid=devID;
	delete from `RISC_Discovery`.t11zsnotifycontroltable where deviceid=devID;
	delete from `RISC_Discovery`.fcmisporttable where deviceid=devID;
	delete from `RISC_Discovery`.t11zszonemembertable where deviceid=devID;
	delete from `RISC_Discovery`.fcfxportcaptable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcsnotifycontroltable where deviceid=devID;
	delete from `RISC_Discovery`.fcmporttable where deviceid=devID;
	delete from `RISC_Discovery`.t11fcroutefabrictable where deviceid=devID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;