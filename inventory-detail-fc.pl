#!/usr/bin/perl 
#
## 
use SNMP::Info;
use RISC::riscUtility;
use RISC::riscSNMP;
use RISC::riscCreds;
use Data::Dumper;
use lib 'lib';
$|++;

my $deviceid	= shift;
my $target	= shift;
my $credid	= shift;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} = 1;

my $credobj = riscCreds->new($target);
my $cred = $credobj->getSNMP($credid);
unless ($cred) {
	out("failed to pull SNMP cred: $credobj->{'error'}");
	exit(1);
}

my $snmp_opts = {};

my $info = riscSNMP::connect($cred,$target,$snmp_opts);
unless ($info) {
	out("failed SNMP connection");
	exit(1);
}

dbg("collecting global data");
eval {
	$name = $info->interfaces();
	$intindex = $info->i_index();
	$description = $info->i_description();
	$type = $info->i_type();
	$speed = $info->i_speed();
	$mac = $info->i_mac();
	$operstatus = $info->i_up();
	$adminstatus = $info->i_up_admin();
	$ipr_dest = $info->ipr_route();
	$ipr_ifindex = $info->ipr_if();
	$ipr_1 = $info->ipr_1();
	$ipr_2 = $info->ipr_2();
	$ipr_3 = $info->ipr_3();
	$ipr_4 = $info->ipr_4();
	$ipr_5 = $info->ipr_5();
	$ipr_nexthop = $info->ipr_dest();
	$ipr_type = $info->ipr_type();
	$ipr_proto = $info->ipr_proto();
	$ipr_age = $info->ipr_age();
	$ipr_mask = $info->ipr_mask();
}; if ($@) {
	out("failed to pull global data: $@");
}

#dbg("creating temporary tables");
#$mysql->do("CREATE TEMPORARY TABLE tmp_foo LIKE foo");

dbg("running collection");
#GatherIPTables();
#GetEntity();
#GetInterfaces();
#GetRoutes();
#GetSysDescription();
GetMDSInfo();
getFCInfo();

#dbg("rolling tmp tables into permanent");
#$mysql->do("INSERT INTO foo SELECT * FROM tmp_foo");

dbg("finish");
$mysql->disconnect();
exit(0);



sub GetMDSInfo {
	eval {
		#Get Devices-match 'mds'
		$sth60 = $mysql->prepare_cached("INSERT INTO fcsNetwork (deviceid,Net_Index,Switch_WWN) VALUES (?,?,?)");
		$sth61 = $mysql->prepare_cached("INSERT INTO fcsInterface (deviceid,SwitchPort_WWN,port_ifindex,port_Inet_Type,port_Inet_addr) VALUES (?,?,?,?,?)");
		$sth62 = $mysql->prepare_cached("INSERT INTO fcsDeviceAlias (deviceid,DeviceAlias,DeviceType,ID,RowStatus) VALUES (?,?,?,?,?)");
		$sth63 = $mysql->prepare_cached("INSERT INTO fcshbaInfo (deviceid,InfoID,NodeName,Mfg,SerialNum,Model,HWVer,DriverVer,ObtROMVer,FWVer,OSInfo,MaxCTPayload) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
		$sth64 = $mysql->prepare_cached("INSERT INTO fcshbaPort (deviceid,PortID,SupportedFC4Type,SupportedSpeed,MaxFrameSize,OSDevName,HostName) VALUES (?,?,?,?,?,?,?)");
		$sth65 = $mysql->prepare_cached("INSERT INTO fcsFDMIIF (deviceid,WWN,AdminMode,OperMode,AdminSpeed,BeaconMode,PortChIfIndex,OperStatDescr,AdminTrunkMode,OperTrunkMode,AllowedVsanList2k,AllowedVsanList4k,ActiveVsanList2k,ActiveVsanList4k,BbCreditModel,HoldTime,TransmitterType,ConnectorType,SerialNum,Revision,Vendor,SFPSerialIDData,PartNumber,AdminRxBbCredit,AdminRxBbCreditModelSL,AdminRxBbCreditModelFX,OperRxBbCredit,RxDataFieldSize,ActiveVsanUpList2k,ActiveVsanUpList4k,PortRateMode,AdminRxPerfBuffer,OperRxPerfBuffer,BbScn,PortInitStatus,AdminRxBbCreditExtended,TunnelIfIndex,ServiceState,AdminBbScnMode) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		$sth66 = $mysql->prepare_cached("INSERT INTO fcsTrunkIf (deviceid,OperStatus,OperStatusCause,OperStatusCauseDesc) VALUES (?,?,?,?)");
		$sth67 = $mysql->prepare_cached("INSERT INTO fcsElpEntry (deviceid,NbrNodeName,NbrPortName,RxZBbCredit,CosSuppAgreed,Class2Seqdel,Class2RxDataFieldSize,Class3Seqdel,Class3RxDataFieldSize,ClassFXII,ClassFRxDataFieldSize,ClassFConcurrentSeq,ClassFEndToEndCredit,ClassFOpenSeq) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		$sth68 = $mysql->prepare_cached("INSERT INTO fcsRNIDInfo (deviceid,status,TypeNum,ModeNum,Manufacture,PlantofMfg,SerialNum,UnitType,PortID) VALUES (?,?,?,?,?,?,?,?,?)");
		$sth69 = $mysql->prepare_cached("INSERT INTO fcsIfGig (deviceid,PortChanIfIndex,AutoNegotiate,BeaconMode) VALUES (?,?,?,?)");
		#FCS Network
		my $netindex = $info->clp_Network_Index();
		my $switch_wwn = $info->clp_Network_SwitchWWN();
		foreach my $iid (keys %$netindex){
			$val_netindex = "";
			$val_switch_wwn = "";
			$val_netindex = $netindex->{$iid};
			$val_switch_wwn = $switch_wwn->{$iid};
			$sth60->execute($deviceid,$val_netindex,$val_switch_wwn);
		}
		$sth60->finish();


		#FCS Network Interface Table
		my $netportswitchwwn = $info->clp_Network_Port_SwitchWWN();
		my $netportintindex = $info->clp_Network_Port_IfIndex();
		my $netportaddrtype = $info->clp_Network_Port_InetAddrType();
		my $networkinetaddr = $info->clp_Network_Port_InetQAddr();
		foreach my $iid (keys %$netportswitchwwn){
			$val_netportswitchwwn = "";
			$val_netportintindex = "";
			$val_netportaddrtype = "";
			$val_networkinetaddr = "";
			$val_netportswitchwwn = $netportswitchwwn->{$iid};
			$val_netportintindex = $netportintindex->{$iid};
			$val_netportaddrtype = $netportaddrtype->{$iid};
			$val_networkinetaddr = $networkinetaddr->{$iid};
			$sth61->execute($deviceid,$val_netportswitchwwn,$val_netportintindex,$val_netportaddrtype,$val_networkinetaddr);
		}
		$sth61->finish();



		#FCS Network device alias
		my $devicealias = $info->cfda_Config_DeviceAlias();
		my $devicetype = $info->cfda_Config_DeviceType();
		my $confdeviceid = $info->cfda_Config_DeviceID();
		my $rowstatus = $info->cfda_Config_RowStatus();
		foreach my $iid (keys %$devicealias){
			$val_devicealias = "";
			$val_devicetype = "";
			$val_confdeviceid = "";
			$val_rowstatus = "";
			$val_devicealias = $devicealias->{$iid};
			$val_devicetype = $devicetype->{$iid};
			$val_confdeviceid = $confdeviceid->{$iid};
			$val_rowstatus = $rowstatus->{$iid};
			$sth62->execute($deviceid,$val_devicealias,$val_devicetype,$val_confdeviceid,$val_rowstatus);
		}
		$sth62->finish();


		#FCS HBA Info
		my $hba_infoid = $info->cfdmi_HbaInfo_InfoId();
		my $hba_nodename = $info->cfdmi_HbaInfo_NodeName();
		my $hba_mfg = $info->cfdmi_HbaInfo_Mfg();
		my $hba_sn = $info->cfdmi_HbaInfo_Sn();
		my $hba_model = $info->cfdmi_HbaInfo_Model();
		my $hba_modeldesc = $info->cfdmi_HbaInfo_ModelDescr();
		my $hba_hwver = $info->cfdmi_HbaInfo_HwVer();
		my $hba_driverver = $info->cfdmi_HbaInfo_DriverVer();
		my $hba_romver = $info->cfdmi_HbaInfo_ObtROMVer();
		my $hba_fwver = $info->cfdmi_HbaInfo_FwVer();
		my $hba_os = $info->cfdmi_HbaInfo_OSInfo();
		my $hba_maxpayload = $info->cfdmi_HbaInfo_MaxCTPayload();
		foreach my $iid (keys %$hba_infoid){
			$val_hba_infoid = "";
			$val_hba_nodename = "";
			$val_hba_mfg = "";
			$val_hba_sn = "";
			$val_hba_model = "";
			$val_hba_modeldesc = "";
			$val_hba_hwver = "";
			$val_hba_driverver = "";
			$val_hba_romver = "";
			$val_hba_fwver = "";
			$val_hba_os = "";
			$val_hba_maxpayload = "";
			$val_hba_infoid = $hba_infoid->{$iid};
			$val_hba_nodename = $hba_nodename->{$iid};
			$val_hba_mfg = $hba_mfg->{$iid};
			$val_hba_sn = $hba_sn->{$iid};
			$val_hba_model = $hba_model->{$iid};
			$val_hba_modeldesc = $hba_modeldesc->{$iid};
			$val_hba_hwver = $hba_hwver->{$iid};
			$val_hba_driverver = $hba_driverver->{$iid};
			$val_hba_romver = $hba_romver->{$iid};
			$val_hba_fwver = $hba_fwver->{$iid};
			$val_hba_os = $hba_os->{$iid};
			$val_hba_maxpayload = $hba_maxpayload->{$iid};
			$sth63->execute($deviceid,$val_hba_infoid,$val_hba_nodename,$val_hba_mfg,$val_hba_sn,$val_hba_model,$val_hba_modeldesc,$val_hba_hwver,$val_hba_driverver,$val_hba_romver,$val_hba_fwver,$val_hba_os,$val_hba_maxpayload);
		}
		$sth63->finish();


		#FCS HBA Port Table
		my $hba_portid = $info->cfdmi_HbaPort_Id();
		my $hba_supportedfc4type = $info->cfdmi_HbaPort_SupportedFC4Type();
		my $hba_supportspeed = $info->cfdmi_HbaPort_SupportedSpeed();
		my $hba_curspeed = $info->cfdmi_HbaPort_CurrentSpeed();
		my $hba_maxframesize = $info->cfdmi_HbaPort_MaxFrameSize();
		my $hba_osdevname = $info->cfdmi_HbaPort_OsDevName();
		my $hba_hostname = $info->cfdmi_HbaPort_HostName();
		foreach my $iid (keys %$hba_portid){
			$val_hba_portid = "";
			$val_hba_supportedfc4type = "";
			$val_hba_supportspeed = "";
			$val_hba_curspeed = "";
			$val_hba_maxframesize = "";
			$val_hba_osdevname = "";
			$val_hba_hostname = "";
			$val_hba_portid = $hba_portid->{$iid};
			$val_hba_supportedfc4type = $hba_supportedfc4type->{$iid};
			$val_hba_supportspeed = $hba_supportspeed->{$iid};
			$val_hba_curspeed = $hba_curspeed->{$iid};
			$val_hba_maxframesize = $hba_maxframesize->{$iid};
			$val_hba_osdevname = $hba_osdevname->{$iid};
			$val_hba_hostname = $hba_hostname->{$iid};

			$sth64->execute($deviceid,$val_hba_portid,$val_hba_supportedfc4type,$val_hba_supportspeed,$val_hba_curspeed,$val_hba_maxframesize,$val_hba_osdevname,$val_hba_hostname);
		}
		$sth64->finish();


		#FCS Interface info
		my $If_Wwn = $info->fcIf_Wwn();
		my $If_AdminMode = $info->fcIf_AdminMode();
		my $If_OperMode = $info->fcIf_OperMode();
		my $If_AdminSpeed = $info->fcIf_AdminSpeed();
		my $If_BeaconMode = $info->fcIf_BeaconMode();
		my $If_PortChannelIfIndex = $info->fcIf_PortChannelIfIndex();
		my $If_OperStatusCauseDescr = $info->fcIf_OperStatusCauseDescr();
		my $If_AdminTrunkMode = $info->fcIf_AdminTrunkMode();
		my $If_OperTrunkMode = $info->fcIf_OperTrunkMode();
		my $If_AllowedVsanList2k = $info->fcIf_AllowedVsanList2k();
		my $If_AllowedVsanList4k = $info->fcIf_AllowedVsanList4k();
		my $If_ActiveVsanList2k = $info->fcIf_ActiveVsanList2k();
		my $If_ActiveVsanList4k = $info->fcIf_ActiveVsanList4k();
		my $If_BbCreditModel = $info->fcIf_BbCreditModel();
		my $If_HoldTime = $info->fcIf_HoldTime();
		my $If_TransmitterType = $info->fcIf_TransmitterType();
		my $If_ConnectorType = $info->fcIf_ConnectorType();
		my $If_SerialNo = $info->fcIf_SerialNo();
		my $If_Revision = $info->fcIf_Revision();
		my $If_Vendor = $info->fcIf_Vendor();
		my $If_SFPSerialIDData = $info->fcIf_SFPSerialIDData();
		my $If_PartNumber = $info->fcIf_PartNumber();
		my $If_AdminRxBbCredit = $info->fcIf_AdminRxBbCredit();
		my $If_AdminRxBbCreditModelSL = $info->fcIf_AdminRxBbCreditModelSL();
		my $If_AdminRxBbCreditModelFx = $info->fcIf_AdminRxBbCreditModelFx();
		my $If_OperRxBbCredit = $info->fcIf_OperRxBbCredit();
		my $If_RxDataFieldSize = $info->fcIf_RxDataFieldSize();
		my $If_ActiveVsanUpList2k = $info->fcIf_ActiveVsanUpList2k();
		my $If_ActiveVsanUpList4k = $info->fcIf_ActiveVsanUpList4k();
		my $If_PortRateMode = $info->fcIf_PortRateMode();
		my $If_AdminRxPerfBuffer = $info->fcIf_AdminRxPerfBuffer();
		my $If_OperRxPerfBuffer = $info->fcIf_OperRxPerfBuffer();
		my $If_BbScn = $info->fcIf_BbScn();
		my $If_PortInitStatus = $info->fcIf_PortInitStatus();
		my $If_AdminRxBbCreditExtended = $info->fcIf_AdminRxBbCreditExtended();
		my $If_TunnelIfIndex = $info->fcIf_TunnelIfIndex();
		my $If_ServiceState = $info->fcIf_ServiceState();
		my $If_AdminBbScnMode = $info->fcIf_AdminBbScnMode();
		foreach my $iid (keys %$If_Wwn){
			$val_If_Wwn = "";
			$val_If_AdminMode = "";
			$val_If_OperMode = "";
			$val_If_AdminSpeed = "";
			$val_If_BeaconMode = "";
			$val_If_PortChannelIfIndex = "";
			$val_If_OperStatusCauseDescr = "";
			$val_If_AdminTrunkMode = "";
			$val_If_OperTrunkMode = "";
			$val_If_AllowedVsanList2k = "";
			$val_If_AllowedVsanList4k = "";
			$val_If_ActiveVsanList2k = "";
			$val_If_ActiveVsanList4k = "";
			$val_If_BbCreditModel = "";
			$val_If_HoldTime = "";
			$val_If_TransmitterType = "";
			$val_If_ConnectorType = "";
			$val_If_SerialNo = "";
			$val_If_Revision = "";
			$val_If_Vendor = "";
			$val_If_SFPSerialIDData = "";
			$val_If_PartNumber = "";
			$val_If_AdminRxBbCredit = "";
			$val_If_AdminRxBbCreditModelSL = "";
			$val_If_AdminRxBbCreditModelFx = "";
			$val_If_OperRxBbCredit = "";
			$val_If_RxDataFieldSize = "";
			$val_If_ActiveVsanUpList2k = "";
			$val_If_ActiveVsanUpList4k = "";
			$val_If_PortRateMode = "";
			$val_If_AdminRxPerfBuffer = "";
			$val_If_OperRxPerfBuffer = "";
			$val_If_BbScn = "";
			$val_If_PortInitStatus = "";
			$val_If_AdminRxBbCreditExtended = "";
			$val_If_TunnelIfIndex = "";
			$val_If_ServiceState = "";
			$val_If_AdminBbScnMode = "";
			$val_If_Wwn = $If_Wwn->{$iid};
			$val_If_AdminMode = $If_AdminMode->{$iid};
			$val_If_OperMode = $If_OperMode->{$iid};
			$val_If_AdminSpeed = $If_AdminSpeed->{$iid};
			$val_If_BeaconMode = $If_BeaconMode->{$iid};
			$val_If_PortChannelIfIndex = $If_PortChannelIfIndex->{$iid};
			$val_If_OperStatusCauseDescr = $If_OperStatusCauseDescr->{$iid};
			$val_If_AdminTrunkMode = $If_AdminTrunkMode->{$iid};
			$val_If_OperTrunkMode = $If_OperTrunkMode->{$iid};
			$val_If_AllowedVsanList2k = $If_AllowedVsanList2k->{$iid};
			$val_If_AllowedVsanList4k = $If_AllowedVsanList4k->{$iid};
			$val_If_ActiveVsanList2k = $If_ActiveVsanList2k->{$iid};
			$val_If_ActiveVsanList4k = $If_ActiveVsanList4k->{$iid};
			$val_If_BbCreditModel = $If_BbCreditModel->{$iid};
			$val_If_HoldTime = $If_HoldTime->{$iid};
			$val_If_TransmitterType = $If_TransmitterType->{$iid};
			$val_If_ConnectorType = $If_ConnectorType->{$iid};
			$val_If_SerialNo = $If_SerialNo->{$iid};
			$val_If_Revision = $If_Revision->{$iid};
			$val_If_Vendor = $If_Vendor->{$iid};
			$val_If_SFPSerialIDData = $If_SFPSerialIDData->{$iid};
			$val_If_PartNumber = $If_PartNumber->{$iid};
			$val_If_AdminRxBbCredit = $If_AdminRxBbCredit->{$iid};
			$val_If_AdminRxBbCreditModelSL = $If_AdminRxBbCreditModelSL->{$iid};
			$val_If_AdminRxBbCreditModelFx = $If_AdminRxBbCreditModelFx->{$iid};
			$val_If_OperRxBbCredit = $If_OperRxBbCredit->{$iid};
			$val_If_RxDataFieldSize = $If_RxDataFieldSize->{$iid};
			$val_If_ActiveVsanUpList2k = $If_ActiveVsanUpList2k->{$iid};
			$val_If_ActiveVsanUpList4k = $If_ActiveVsanUpList4k->{$iid};
			$val_If_PortRateMode = $If_PortRateMode->{$iid};
			$val_If_AdminRxPerfBuffer = $If_AdminRxPerfBuffer->{$iid};
			$val_If_OperRxPerfBuffer = $If_OperRxPerfBuffer->{$iid};
			$val_If_BbScn = $If_BbScn->{$iid};
			$val_If_PortInitStatus = $If_PortInitStatus->{$iid};
			$val_If_AdminRxBbCreditExtended = $If_AdminRxBbCreditExtended->{$iid};
			$val_If_TunnelIfIndex = $If_TunnelIfIndex->{$iid};
			$val_If_ServiceState = $If_ServiceState->{$iid};
			$val_If_AdminBbScnMode = $If_AdminBbScnMode->{$iid};
			$sth65->execute($deviceid,$val_If_Wwn,$val_If_AdminMode,$val_If_OperMode,$val_If_AdminSpeed,$val_If_BeaconMode,$val_If_PortChannelIfIndex,$val_If_OperStatusCauseDescr,$val_If_AdminTrunkMode,$val_If_OperTrunkMode,$val_If_AllowedVsanList2k,$val_If_AllowedVsanList4k,$val_If_ActiveVsanList2k,$val_If_ActiveVsanList4k,$val_If_BbCreditModel,$val_If_HoldTime,$val_If_TransmitterType,$val_If_ConnectorType,$val_If_SerialNo,$val_If_Revision,$val_If_Vendor,$val_If_SFPSerialIDData,$val_If_PartNumber,$val_If_AdminRxBbCredit,$val_If_AdminRxBbCreditModelSL,$val_If_AdminRxBbCreditModelFx,$val_If_OperRxBbCredit,$val_If_RxDataFieldSize,$val_If_ActiveVsanUpList2k,$val_If_ActiveVsanUpList4k,$val_If_PortRateMode,$val_If_AdminRxPerfBuffer,$val_If_OperRxPerfBuffer,$val_If_BbScn,$val_If_PortInitStatus,$val_If_AdminRxBbCreditExtended,$val_If_TunnelIfIndex,$val_If_ServiceState,$val_If_AdminBbScnMode);
		}
		$sth65->finish();

		#FCS Trunk Interface table
		my $ifoperstatus = $info->fc_Trunk_IfOperStatus();
		my $ifoperstatuscause = $info->fc_Trunk_IfOperStatusCause();
		my $ifoperstatuscausedesc = $info->fc_Trunk_IfOperStatusCauseDescr();
		foreach my $iid (keys %$ifoperstatus){
			$val_ifoperstatus = "";
			$val_ifoperstatuscause = "";
			$val_ifoperstatuscausedesc = "";
			$val_ifoperstatus = $ifoperstatus->{$iid};
			$val_ifoperstatuscause = $ifoperstatuscause->{$iid};
			$val_ifoperstatuscausedesc = $ifoperstatuscausedesc->{$iid};
			$sth66->execute($deviceid,$val_ifoperstatus,$val_ifoperstatuscause,$val_ifoperstatuscausedesc);
		}
		$sth66->finish();

		#FCS neighbor info
		my $nbrnodename = $info->fcIf_Elp_NbrNodeName();
		my $nbrportname = $info->fcIf_Elp_NbrPortName();
		my $rxBbcredit = $info->fcIf_Elp_RxBbCredit();
		my $cossuppagreed = $info->fcIf_Elp_CosSuppAgreed();
		my $class2SeqDelivAgreed = $info->fcIf_Elp_Class2SeqDelivAgreed();
		my $class2RxDataFieldSize = $info->fcIf_Elp_Class2RxDataFieldSize();
		my $class3seqDelivAgreed = $info->fcIf_Elp_Class3SeqDelivAgreed();
		my $class3RxDataFieldSize = $info->fcIf_Elp_Class3RxDataFieldSize();
		my $ClassFXii = $info->fcIf_Elp_ClassFXII();
		my $classFRxDatafieldSize = $info->fcIf_Elp_ClassFRxDataFieldSize();
		my $classFConcurrentSeq = $info->fcIf_Elp_ClassFConcurrentSeq();
		my $ClassFEndtoEndCredit = $info->fcIf_Elp_ClassFEndToEndCredit();
		my $classFOpenSeq = $info->fcIf_Elp_ClassFOpenSeq();
		foreach my $iid (keys %$nbrnodename){
			$val_nbrnodename = "";
			$val_nbrportname = "";
			$val_rxBbcredit = "";
			$val_cossuppagreed = "";
			$val_class2SeqDelivAgreed = "";
			$val_class2RxDataFieldSize = "";
			$val_class3seqDelivAgreed = "";
			$val_class3RxDataFieldSize = "";
			$val_ClassFXii = "";
			$val_classFRxDatafieldSize = "";
			$val_classFConcurrentSeq = "";
			$val_ClassFEndtoEndCredit = "";
			$val_classFOpenSeq = "";
			$val_nbrnodename = $nbrnodename->{$iid};
			$val_nbrportname = $nbrportname->{$iid};
			$val_rxBbcredit = $rxBbcredit->{$iid};
			$val_cossuppagreed = $cossuppagreed->{$iid};
			$val_class2SeqDelivAgreed = $class2SeqDelivAgreed->{$iid};
			$val_class2RxDataFieldSize = $class2RxDataFieldSize->{$iid};
			$val_class3seqDelivAgreed = $class3seqDelivAgreed->{$iid};
			$val_class3RxDataFieldSize = $class3RxDataFieldSize->{$iid};
			$val_ClassFXii = $ClassFXii->{$iid};
			$val_classFRxDatafieldSize = $classFRxDatafieldSize->{$iid};
			$val_classFConcurrentSeq = $classFConcurrentSeq->{$iid};
			$val_ClassFEndtoEndCredit = $ClassFEndtoEndCredit->{$iid};
			$val_classFOpenSeq = $classFOpenSeq->{$iid};
			$sth67->execute($deviceid,$val_nbrnodename,$val_nbrportname,$val_rxBbcredit,$val_cossuppagreed,$val_class2SeqDelivAgreed,$val_class2RxDataFieldSize,$val_class3seqDelivAgreed,$val_class3RxDataFieldSize,$val_ClassFXii,$val_classFRxDatafieldSize,$val_classFConcurrentSeq,$val_ClassFEndtoEndCredit,$val_classFOpenSeq);
		}
		$sth67->finish();

		#FCS RNID Info table
		my $RNIDInfoStatus = $info->fcIf_RNIDInfo_Status();
		my $InfoTypeNum = $info->fcIf_RNIDInfo_TypeNumber();
		my $InfoModeNum = $info->fcIf_RNIDInfo_ModeNumber();
		my $InfoManufacture = $info->fcIf_RNIDInfo_Manufacture();
		my $PlantOfMfg = $info->fcIf_RNIDInfo_PlantOfMfg();
		my $SerialNum = $info->fcIf_RNIDInfo_SerialNumber();
		my $UnitType = $info->fcIf_RNIDInfo_UnitType();
		my $PortID = $info->fcIf_RNIDInfo_PortId();
		foreach my $iid (keys %$RNIDInfoStatus){
			$val_RNIDInfoStatus = "";
			$val_InfoTypeNum = "";
			$val_InfoModeNum = "";
			$val_InfoManufacture = "";
			$val_PlantOfMfg = "";
			$val_SerialNum = "";
			$val_UnitType = "";
			$val_PortID = "";
			$val_RNIDInfoStatus = $RNIDInfoStatus->{$iid};
			$val_InfoTypeNum = $InfoTypeNum->{$iid};
			$val_InfoModeNum = $InfoModeNum->{$iid};
			$val_InfoManufacture = $InfoManufacture->{$iid};
			$val_PlantOfMfg = $PlantOfMfg->{$iid};
			$val_SerialNum = $SerialNum->{$iid};
			$val_UnitType = $UnitType->{$iid};
			$val_PortID = $PortID->{$iid};
			$sth68->execute($deviceid,$val_RNIDInfoStatus,$val_InfoTypeNum,$val_InfoModeNum,$val_InfoManufacture,$val_PlantOfMfg,$val_SerialNum,$val_UnitType,$val_PortID);
		}
		$sth68->finish();

		#FCS Gig Table
		my $portchanIfIndex = $info->fcIf_GigE_PortChannelIfIndex();
		my $autoneg = $info->fcIf_GigE_AutoNegotiate();
		my $beaconmode = $info->fcIf_GigE_BeaconMode();
		foreach my $iid (keys %$portchanIfIndex){
			$val_portchanIfIndex = "";
			$val_autoneg = "";
			$val_beaconmode = "";
			$val_portchanIfIndex = $portchanIfIndex->{$iid};
			$val_autoneg = $autoneg->{$iid};
			$val_beaconmode = $beaconmode->{$iid};
			$sth69->execute($deviceid,$val_portchanIfIndex,$val_autoneg,$val_beaconmode);
		}
		$sth69->finish();
	}; if ($@){
		out("failed to pull FCS: $@");
	}
}

sub getFCInfo {
	eval {
		##FC INVENTORY
		my $t11nsregtable_sth = $mysql->prepare_cached("INSERT INTO t11nsregtable(deviceid,scantime,fc_t11NsRegFabricIndex,fc_t11NsRegPortIdentifier,fc_t11NsRegPortName,fc_t11NsRegNodeName,fc_t11NsRegClassOfSvc,fc_t11NsRegNodeIpAddress,fc_t11NsRegProcAssoc,fc_t11NsRegFc4Type,fc_t11NsRegPortType,fc_t11NsRegPortIpAddress,fc_t11NsRegFabricPortName,fc_t11NsRegHardAddress,fc_t11NsRegSymbolicPortName,fc_t11NsRegSymbolicNodeName,fc_t11NsRegFc4Features,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11zsstatstable_sth = $mysql->prepare_cached("INSERT INTO t11zsstatstable(deviceid,scantime,fc_t11ZsOutMergeRequests,fc_t11ZsInMergeAccepts,fc_t11ZsInMergeRequests,fc_t11ZsOutMergeAccepts,fc_t11ZsOutChangeRequests,fc_t11ZsInChangeAccepts,fc_t11ZsInChangeRequests,fc_t11ZsOutChangeAccepts,fc_t11ZsInZsRequests,fc_t11ZsOutZsRejects,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fspflinktable_sth = $mysql->prepare_cached("INSERT INTO t11fspflinktable(deviceid,scantime,fc_t11FspfLinkIndex,fc_t11FspfLinkNbrDomainId,fc_t11FspfLinkPortIndex,fc_t11FspfLinkNbrPortIndex,fc_t11FspfLinkType,fc_t11FspfLinkCost,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
		my $fcfxporttable_sth = $mysql->prepare_cached("INSERT INTO fcfxporttable(deviceid,scantime,fc_fcFxPortIndex,fc_fcFxPortIntermixSupported,fc_fcFxPortStackedConnMode,fc_fcFxPortClass2SeqDeliv,fc_fcFxPortClass3SeqDeliv,fc_fcFxPortHoldTime,fc_fcFxPortName,fc_fcFxPortFcphVersionHigh,fc_fcFxPortFcphVersionLow,fc_fcFxPortBbCredit,fc_fcFxPortRxBufSize,fc_fcFxPortRatov,fc_fcFxPortEdtov,fc_fcFxPortCosSupported,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fspftable_sth = $mysql->prepare_cached("INSERT INTO t11fspftable(deviceid,scantime,fc_t11FspfFabricIndex,fc_t11FspfMinLsArrival,fc_t11FspfMinLsInterval,fc_t11FspfLsRefreshTime,fc_t11FspfMaxAge,fc_t11FspfMaxAgeDiscards,fc_t11FspfPathComputations,fc_t11FspfChecksumErrors,fc_t11FspfLsrs,fc_t11FspfCreateTime,fc_t11FspfAdminStatus,fc_t11FspfOperStatus,fc_t11FspfNbrStateChangNotifyEnable,fc_t11FspfSetToDefault,fc_t11FspfStorageType,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11zsactivetable_sth = $mysql->prepare_cached("INSERT INTO t11zsactivetable(deviceid,scantime,fc_t11ZsActiveZoneSetName,fc_t11ZsActiveActivateTime,snmpindex) VALUES (?,?,?,?,?)");
		my $fcfxportc2accountingtable_sth = $mysql->prepare_cached("INSERT INTO fcfxportc2accountingtable(deviceid,scantime,fc_fcFxPortC2InFrames,fc_fcFxPortC2OutFrames,fc_fcFxPortC2InOctets,fc_fcFxPortC2OutOctets,fc_fcFxPortC2Discards,fc_fcFxPortC2FbsyFrames,fc_fcFxPortC2FrjtFrames,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsnodenamelisttable_sth = $mysql->prepare_cached("INSERT INTO t11fcsnodenamelisttable(deviceid,scantime,fc_t11FcsNodeNameListIndex,fc_t11FcsNodeName,snmpindex) VALUES (?,?,?,?,?)");
		my $t11fcroutetable_sth = $mysql->prepare_cached("INSERT INTO t11fcroutetable(deviceid,scantime,fc_t11FcRouteDestAddrId,fc_t11FcRouteDestMask,fc_t11FcRouteSrcAddrId,fc_t11FcRouteSrcMask,fc_t11FcRouteInInterface,fc_t11FcRouteProto,fc_t11FcRouteOutInterface,fc_t11FcRouteDomainId,fc_t11FcRouteMetric,fc_t11FcRouteType,fc_t11FcRouteIfDown,fc_t11FcRouteStorageType,fc_t11FcRouteRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $fcmswitchtable_sth = $mysql->prepare_cached("INSERT INTO fcmswitchtable(deviceid,scantime,fc_fcmSwitchIndex,fc_fcmSwitchDomainId,fc_fcmSwitchPrincipal,fc_fcmSwitchWWN,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $fcmportstatstable_sth = $mysql->prepare_cached("INSERT INTO fcmportstatstable(deviceid,scantime,fc_fcmPortBBCreditZeros,fc_fcmPortFullInputBuffers,fc_fcmPortClass2RxFrames,fc_fcmPortClass2RxOctets,fc_fcmPortClass2TxFrames,fc_fcmPortClass2TxOctets,fc_fcmPortClass2Discards,fc_fcmPortClass2RxFbsyFrames,fc_fcmPortClass2RxPbsyFrames,fc_fcmPortClass2RxFrjtFrames,fc_fcmPortClass2RxPrjtFrames,fc_fcmPortClass2TxFbsyFrames,fc_fcmPortClass2TxPbsyFrames,fc_fcmPortClass2TxFrjtFrames,fc_fcmPortClass2TxPrjtFrames,fc_fcmPortClass3RxFrames,fc_fcmPortClass3RxOctets,fc_fcmPortClass3TxFrames,fc_fcmPortClass3TxOctets,fc_fcmPortClass3Discards,fc_fcmPortClassFRxFrames,fc_fcmPortClassFRxOctets,fc_fcmPortClassFTxFrames,fc_fcmPortClassFTxOctets,fc_fcmPortClassFDiscards,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11vfporttable_sth = $mysql->prepare_cached("INSERT INTO t11vfporttable(deviceid,scantime,fc_t11vfPortVfId,fc_t11vfPortTaggingAdminStatus,fc_t11vfPortTaggingOperStatus,fc_t11vfPortStorageType,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11zssettable_sth = $mysql->prepare_cached("INSERT INTO t11zssettable(deviceid,scantime,fc_t11ZsSetIndex,fc_t11ZsSetName,fc_t11ZsSetRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11zsactivezonetable_sth = $mysql->prepare_cached("INSERT INTO t11zsactivezonetable(deviceid,scantime,fc_t11ZsActiveZoneIndex,fc_t11ZsActiveZoneName,fc_t11ZsActiveZoneBroadcastZoning,fc_t11ZsActiveZoneHardZoning,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $fcmlinktable_sth = $mysql->prepare_cached("INSERT INTO fcmlinktable(deviceid,scantime,fc_fcmLinkIndex,fc_fcmLinkEnd1NodeWwn,fc_fcmLinkEnd1PhysPortNumber,fc_fcmLinkEnd1PortWwn,fc_fcmLinkEnd2NodeWwn,fc_fcmLinkEnd2PhysPortNumber,fc_fcmLinkEnd2PortWwn,fc_fcmLinkEnd2AgentAddress,fc_fcmLinkEnd2PortType,fc_fcmLinkEnd2UnitType,fc_fcmLinkEnd2FcAddressId,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsfabricdiscoverytable_sth = $mysql->prepare_cached("INSERT INTO t11fcsfabricdiscoverytable(deviceid,scantime,fc_t11FcsFabricDiscoveryRangeLow,fc_t11FcsFabricDiscoveryRangeHigh,fc_t11FcsFabricDiscoveryStart,fc_t11FcsFabricDiscoveryTimeOut,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11zssetzonetable_sth = $mysql->prepare_cached("INSERT INTO t11zssetzonetable(deviceid,scantime,fc_t11ZsSetZoneRowStatus,snmpindex) VALUES (?,?,?,?)");
		my $t11fcrscnnotifycontroltable_sth = $mysql->prepare_cached("INSERT INTO t11fcrscnnotifycontroltable(deviceid,scantime,fc_t11FcRscnIlsRejectNotifyEnable,fc_t11FcRscnElsRejectNotifyEnable,fc_t11FcRscnRejectedRequestString,fc_t11FcRscnRejectedRequestSource,fc_t11FcRscnRejectReasonCode,fc_t11FcRscnRejectReasonCodeExp,fc_t11FcRscnRejectReasonVendorCode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
		my $t11zsattribblocktable_sth = $mysql->prepare_cached("INSERT INTO t11zsattribblocktable(deviceid,scantime,fc_t11ZsAttribBlockIndex,fc_t11ZsAttribBlockName,fc_t11ZsAttribBlockRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11zsservertable_sth = $mysql->prepare_cached("INSERT INTO t11zsservertable(deviceid,scantime,fc_t11ZsServerFabricIndex,fc_t11ZsServerCapabilityObject,fc_t11ZsServerDatabaseStorageType,fc_t11ZsServerDistribute,fc_t11ZsServerCommit,fc_t11ZsServerResult,fc_t11ZsServerReasonCode,fc_t11ZsServerReasonCodeExp,fc_t11ZsServerReasonVendorCode,fc_t11ZsServerLastChange,fc_t11ZsServerHardZoning,fc_t11ZsServerReadFromDatabase,fc_t11ZsServerOperationMode,fc_t11ZsServerChangeModeResult,fc_t11ZsServerDefaultZoneSetting,fc_t11ZsServerMergeControlSetting,fc_t11ZsServerDefZoneBroadcast,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11famdatabasetable_sth = $mysql->prepare_cached("INSERT INTO t11famdatabasetable(deviceid,scantime,fc_t11FamDatabaseDomainId,fc_t11FamDatabaseSwitchWwn,snmpindex) VALUES (?,?,?,?,?)");
		my $t11vfvirtualswitchtable_sth = $mysql->prepare_cached("INSERT INTO t11vfvirtualswitchtable(deviceid,scantime,fc_t11vfVirtualSwitchVfId,fc_t11vfVirtualSwitchCoreSwitchName,fc_t11vfVirtualSwitchRowStatus,fc_t11vfVirtualSwitchStorageType,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11zszonetable_sth = $mysql->prepare_cached("INSERT INTO t11zszonetable(deviceid,scantime,fc_t11ZsZoneIndex,fc_t11ZsZoneName,fc_t11ZsZoneAttribBlock,fc_t11ZsZoneRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11fcsplatformtable_sth = $mysql->prepare_cached("INSERT INTO t11fcsplatformtable(deviceid,scantime,fc_t11FcsPlatformIndex,fc_t11FcsPlatformName,fc_t11FcsPlatformType,fc_t11FcsPlatformNodeNameListIndex,fc_t11FcsPlatformMgmtAddrListIndex,fc_t11FcsPlatformVendorId,fc_t11FcsPlatformProductId,fc_t11FcsPlatformProductRevLevel,fc_t11FcsPlatformDescription,fc_t11FcsPlatformLabel,fc_t11FcsPlatformLocation,fc_t11FcsPlatformSystemID,fc_t11FcsPlatformSysMgmtAddr,fc_t11FcsPlatformClusterId,fc_t11FcsPlatformClusterMgmtAddr,fc_t11FcsPlatformFC4Types,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsstatstable_sth = $mysql->prepare_cached("INSERT INTO t11fcsstatstable(deviceid,scantime,fc_t11FcsInGetReqs,fc_t11FcsOutGetReqs,fc_t11FcsInRegReqs,fc_t11FcsOutRegReqs,fc_t11FcsInDeregReqs,fc_t11FcsOutDeregReqs,fc_t11FcsRejects,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
		my $fcmporterrorstable_sth = $mysql->prepare_cached("INSERT INTO fcmporterrorstable(deviceid,scantime,fc_fcmPortRxLinkResets,fc_fcmPortTxLinkResets,fc_fcmPortLinkResets,fc_fcmPortRxOfflineSequences,fc_fcmPortTxOfflineSequences,fc_fcmPortLinkFailures,fc_fcmPortLossofSynchs,fc_fcmPortLossofSignals,fc_fcmPortPrimSeqProtocolErrors,fc_fcmPortInvalidTxWords,fc_fcmPortInvalidCRCs,fc_fcmPortInvalidOrderedSets,fc_fcmPortFrameTooLongs,fc_fcmPortTruncatedFrames,fc_fcmPortAddressErrors,fc_fcmPortDelimiterErrors,fc_fcmPortEncodingDisparityErrors,fc_fcmPortOtherErrors,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcrscnregtable_sth = $mysql->prepare_cached("INSERT INTO t11fcrscnregtable(deviceid,scantime,fc_t11FcRscnFabricIndex,fc_t11FcRscnRegFcId,fc_t11FcRscnRegType,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11zsaliastable_sth = $mysql->prepare_cached("INSERT INTO t11zsaliastable(deviceid,scantime,fc_t11ZsAliasIndex,fc_t11ZsAliasName,fc_t11ZsAliasRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11nsrejecttable_sth = $mysql->prepare_cached("INSERT INTO t11nsrejecttable(deviceid,scantime,fc_t11NsRejectCtCommandString,fc_t11NsRejectReasonCode,fc_t11NsRejReasonCodeExp,fc_t11NsRejReasonVendorCode,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11nsinfosubsettable_sth = $mysql->prepare_cached("INSERT INTO t11nsinfosubsettable(deviceid,scantime,fc_t11NsInfoSubsetIndex,fc_t11NsInfoSubsetSwitchIndex,fc_t11NsInfoSubsetTableLastChange,fc_t11NsInfoSubsetNumRows,fc_t11NsInfoSubsetTotalRejects,fc_t11NsInfoSubsetRejReqNotfyEnable,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
		my $fcfxportphystable_sth = $mysql->prepare_cached("INSERT INTO fcfxportphystable(deviceid,scantime,fc_fcFxPortPhysAdminStatus,fc_fcFxPortPhysOperStatus,fc_fcFxPortPhysLastChange,fc_fcFxPortPhysRttov,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $fcfxportstatustable_sth = $mysql->prepare_cached("INSERT INTO fcfxportstatustable(deviceid,scantime,fc_fcFxPortID,fc_fcFxPortBbCreditAvailable,fc_fcFxPortOperMode,fc_fcFxPortAdminMode,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $fcfxporterrortable_sth = $mysql->prepare_cached("INSERT INTO fcfxporterrortable(deviceid,scantime,fc_fcFxPortLinkFailures,fc_fcFxPortLinkResetOuts,fc_fcFxPortOlsIns,fc_fcFxPortOlsOuts,fc_fcFxPortSyncLosses,fc_fcFxPortSigLosses,fc_fcFxPortPrimSeqProtoErrors,fc_fcFxPortInvalidTxWords,fc_fcFxPortInvalidCrcs,fc_fcFxPortDelimiterErrors,fc_fcFxPortAddressIdErrors,fc_fcFxPortLinkResetIns,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11zsactiveattribtable_sth = $mysql->prepare_cached("INSERT INTO t11zsactiveattribtable(deviceid,scantime,fc_t11ZsActiveAttribIndex,fc_t11ZsActiveAttribType,fc_t11ZsActiveAttribValue,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11vfcoreswitchtable_sth = $mysql->prepare_cached("INSERT INTO t11vfcoreswitchtable(deviceid,scantime,fc_t11vfCoreSwitchSwitchName,fc_t11vfCoreSwitchMaxSupported,fc_t11vfCoreSwitchStorageType,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11nsregfc4descriptortable_sth = $mysql->prepare_cached("INSERT INTO t11nsregfc4descriptortable(deviceid,scantime,fc_t11NsRegFc4TypeValue,fc_t11NsRegFc4Descriptor,snmpindex) VALUES (?,?,?,?,?)");
		my $t11fspfiftable_sth = $mysql->prepare_cached("INSERT INTO t11fspfiftable(deviceid,scantime,fc_t11FspfIfIndex,fc_t11FspfIfHelloInterval,fc_t11FspfIfDeadInterval,fc_t11FspfIfRetransmitInterval,fc_t11FspfIfInLsuPkts,fc_t11FspfIfInLsaPkts,fc_t11FspfIfOutLsuPkts,fc_t11FspfIfOutLsaPkts,fc_t11FspfIfOutHelloPkts,fc_t11FspfIfInHelloPkts,fc_t11FspfIfRetransmittedLsuPkts,fc_t11FspfIfInErrorPkts,fc_t11FspfIfNbrState,fc_t11FspfIfNbrDomainId,fc_t11FspfIfNbrPortIndex,fc_t11FspfIfAdminStatus,fc_t11FspfIfCreateTime,fc_t11FspfIfSetToDefault,fc_t11FspfIfLinkCostFactor,fc_t11FspfIfStorageType,fc_t11FspfIfRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $fcfxportc1accountingtable_sth = $mysql->prepare_cached("INSERT INTO fcfxportc1accountingtable(deviceid,scantime,fc_fcFxPortC1InFrames,fc_fcFxPortC1ConnTime,fc_fcFxPortC1OutFrames,fc_fcFxPortC1InOctets,fc_fcFxPortC1OutOctets,fc_fcFxPortC1Discards,fc_fcFxPortC1FbsyFrames,fc_fcFxPortC1FrjtFrames,fc_fcFxPortC1InConnections,fc_fcFxPortC1OutConnections,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcrscnstatstable_sth = $mysql->prepare_cached("INSERT INTO t11fcrscnstatstable(deviceid,scantime,fc_t11FcRscnInScrs,fc_t11FcRscnInRscns,fc_t11FcRscnOutRscns,fc_t11FcRscnInSwRscns,fc_t11FcRscnOutSwRscns,fc_t11FcRscnScrRejects,fc_t11FcRscnRscnRejects,fc_t11FcRscnSwRscnRejects,fc_t11FcRscnInUnspecifiedRscns,fc_t11FcRscnOutUnspecifiedRscns,fc_t11FcRscnInChangedAttribRscns,fc_t11FcRscnOutChangedAttribRscns,fc_t11FcRscnInChangedServiceRscns,fc_t11FcRscnOutChangedServiceRscns,fc_t11FcRscnInChangedSwitchRscns,fc_t11FcRscnOutChangedSwitchRscns,fc_t11FcRscnInRemovedRscns,fc_t11FcRscnOutRemovedRscns,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11famiftable_sth = $mysql->prepare_cached("INSERT INTO t11famiftable(deviceid,scantime,fc_t11FamIfRcfReject,fc_t11FamIfRole,fc_t11FamIfRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11fcsietable_sth = $mysql->prepare_cached("INSERT INTO t11fcsietable(deviceid,scantime,fc_t11FcsIeName,fc_t11FcsIeType,fc_t11FcsIeDomainId,fc_t11FcsIeMgmtId,fc_t11FcsIeFabricName,fc_t11FcsIeLogicalName,fc_t11FcsIeMgmtAddrListIndex,fc_t11FcsIeInfoList,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
		my $fc_t11famtable_sth = $mysql->prepare_cached("INSERT INTO fc_t11famtable(deviceid,scantime,fc_t11FamFabricIndex,fc_t11FamConfigDomainId,fc_t11FamConfigDomainIdType,fc_t11FamAutoReconfigure,fc_t11FamContiguousAllocation,fc_t11FamPriority,fc_t11FamPrincipalSwitchWwn,fc_t11FamLocalSwitchWwn,fc_t11FamAssignedAreaIdList,fc_t11FamGrantedFcIds,fc_t11FamRecoveredFcIds,fc_t11FamFreeFcIds,fc_t11FamAssignedFcIds,fc_t11FamAvailableFcIds,fc_t11FamRunningPriority,fc_t11FamPrincSwRunningPriority,fc_t11FamState,fc_t11FamLocalPrincipalSwitchSlctns,fc_t11FamPrincipalSwitchSelections,fc_t11FamBuildFabrics,fc_t11FamFabricReconfigures,fc_t11FamDomainId,fc_t11FamSticky,fc_t11FamRestart,fc_t11FamRcFabricNotifyEnable,fc_t11FamEnable,fc_t11FamFabricName,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11zsattribtable_sth = $mysql->prepare_cached("INSERT INTO t11zsattribtable(deviceid,scantime,fc_t11ZsAttribIndex,fc_t11ZsAttribType,fc_t11ZsAttribValue,fc_t11ZsAttribRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
		my $t11zsactivatetable_sth = $mysql->prepare_cached("INSERT INTO t11zsactivatetable(deviceid,scantime,fc_t11ZsActivateRequest,fc_t11ZsActivateDeactivate,fc_t11ZsActivateResult,fc_t11ZsActivateFailCause,fc_t11ZsActivateFailDomainId,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
		my $t11famareatable_sth = $mysql->prepare_cached("INSERT INTO t11famareatable(deviceid,scantime,fc_t11FamAreaAreaId,fc_t11FamAreaAssignedPortIdList,snmpindex) VALUES (?,?,?,?,?)");
		my $fcmfxporttable_sth = $mysql->prepare_cached("INSERT INTO fcmfxporttable(deviceid,scantime,fc_fcmFxPortRatov,fc_fcmFxPortEdtov,fc_fcmFxPortRttov,fc_fcmFxPortHoldTime,fc_fcmFxPortCapBbCreditMax,fc_fcmFxPortCapBbCreditMin,fc_fcmFxPortCapDataFieldSizeMax,fc_fcmFxPortCapDataFieldSizeMin,fc_fcmFxPortCapClass2SeqDeliv,fc_fcmFxPortCapClass3SeqDeliv,fc_fcmFxPortCapHoldTimeMax,fc_fcmFxPortCapHoldTimeMin,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsdiscoverystatetable_sth = $mysql->prepare_cached("INSERT INTO t11fcsdiscoverystatetable(deviceid,scantime,fc_t11FcsFabricIndex,fc_t11FcsDiscoveryStatus,fc_t11FcsDiscoveryCompleteTime,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11famfcidcachetable_sth = $mysql->prepare_cached("INSERT INTO t11famfcidcachetable(deviceid,scantime,fc_t11FamFcIdCacheWwn,fc_t11FamFcIdCacheAreaIdPortId,fc_t11FamFcIdCachePortIds,snmpindex) VALUES (?,?,?,?,?,?)");
		my $fcfxlogintable_sth = $mysql->prepare_cached("INSERT INTO fcfxlogintable(deviceid,scantime,fc_fcFxPortNxLoginIndex,fc_fcFxPortNxPortName,fc_fcFxPortConnectedNxPort,fc_fcFxPortBbCreditModel,fc_fcFxPortFcphVersionAgreed,fc_fcFxPortNxPortBbCredit,fc_fcFxPortNxPortRxDataFieldSize,fc_fcFxPortCosSuppAgreed,fc_fcFxPortIntermixSuppAgreed,fc_fcFxPortStackedConnModeAgreed,fc_fcFxPortClass2SeqDelivAgreed,fc_fcFxPortClass3SeqDelivAgreed,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsmgmtaddrlisttable_sth = $mysql->prepare_cached("INSERT INTO t11fcsmgmtaddrlisttable(deviceid,scantime,fc_t11FcsMgmtAddrListIndex,fc_t11FcsMgmtAddrIndex,fc_t11FcsMgmtAddr,snmpindex) VALUES (?,?,?,?,?,?)");
		my $fcfxportc3accountingtable_sth = $mysql->prepare_cached("INSERT INTO fcfxportc3accountingtable(deviceid,scantime,fc_fcFxPortC3InFrames,fc_fcFxPortC3OutFrames,fc_fcFxPortC3InOctets,fc_fcFxPortC3OutOctets,fc_fcFxPortC3Discards,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
		my $t11vflocallyenabledtable_sth = $mysql->prepare_cached("INSERT INTO t11vflocallyenabledtable(deviceid,scantime,fc_t11vfLocallyEnabledPortIfIndex,fc_t11vfLocallyEnabledVfId,fc_t11vfLocallyEnabledOperStatus,fc_t11vfLocallyEnabledRowStatus,fc_t11vfLocallyEnabledStorageType,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
		my $t11nsstatstable_sth = $mysql->prepare_cached("INSERT INTO t11nsstatstable(deviceid,scantime,fc_t11NsInGetReqs,fc_t11NsOutGetReqs,fc_t11NsInRegReqs,fc_t11NsInDeRegReqs,fc_t11NsInRscns,fc_t11NsOutRscns,fc_t11NsRejects,fc_t11NsDatabaseFull,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsporttable_sth = $mysql->prepare_cached("INSERT INTO t11fcsporttable(deviceid,scantime,fc_t11FcsPortName,fc_t11FcsPortType,fc_t11FcsPortTxType,fc_t11FcsPortModuleType,fc_t11FcsPortPhyPortNum,fc_t11FcsPortAttachPortNameIndex,fc_t11FcsPortState,fc_t11FcsPortSpeedCapab,fc_t11FcsPortOperSpeed,fc_t11FcsPortZoningEnfStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $fcminstancetable_sth = $mysql->prepare_cached("INSERT INTO fcminstancetable(deviceid,scantime,fc_fcmInstanceIndex,fc_fcmInstanceWwn,fc_fcmInstanceFunctions,fc_fcmInstancePhysicalIndex,fc_fcmInstanceSoftwareIndex,fc_fcmInstanceStatus,fc_fcmInstanceTextName,fc_fcmInstanceDescr,fc_fcmInstanceFabricId,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11zsactivezonemembertable_sth = $mysql->prepare_cached("INSERT INTO t11zsactivezonemembertable(deviceid,scantime,fc_t11ZsActiveZoneMemberIndex,fc_t11ZsActiveZoneMemberFormat,fc_t11ZsActiveZoneMemberID,snmpindex) VALUES (?,?,?,?,?,?)");
		my $t11fcsattachportnamelisttable_sth = $mysql->prepare_cached("INSERT INTO t11fcsattachportnamelisttable(deviceid,scantime,fc_t11FcsAttachPortNameListIndex,fc_t11FcsAttachPortName,snmpindex) VALUES (?,?,?,?,?)");
		my $fcmportlcstatstable_sth = $mysql->prepare_cached("INSERT INTO fcmportlcstatstable(deviceid,scantime,fc_fcmPortLcBBCreditZeros,fc_fcmPortLcFullInputBuffers,fc_fcmPortLcClass2RxFrames,fc_fcmPortLcClass2RxOctets,fc_fcmPortLcClass2TxFrames,fc_fcmPortLcClass2TxOctets,fc_fcmPortLcClass2Discards,fc_fcmPortLcClass2RxFbsyFrames,fc_fcmPortLcClass2RxPbsyFrames,fc_fcmPortLcClass2RxFrjtFrames,fc_fcmPortLcClass2RxPrjtFrames,fc_fcmPortLcClass2TxFbsyFrames,fc_fcmPortLcClass2TxPbsyFrames,fc_fcmPortLcClass2TxFrjtFrames,fc_fcmPortLcClass2TxPrjtFrames,fc_fcmPortLcClass3RxFrames,fc_fcmPortLcClass3RxOctets,fc_fcmPortLcClass3TxFrames,fc_fcmPortLcClass3TxOctets,fc_fcmPortLcClass3Discards,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $fcmflogintable_sth = $mysql->prepare_cached("INSERT INTO fcmflogintable(deviceid,scantime,fc_fcmFLoginNxPortIndex,fc_fcmFLoginPortWwn,fc_fcmFLoginNodeWwn,fc_fcmFLoginBbCreditModel,fc_fcmFLoginBbCredit,fc_fcmFLoginClassesAgreed,fc_fcmFLoginClass2SeqDelivAgreed,fc_fcmFLoginClass2DataFieldSize,fc_fcmFLoginClass3SeqDelivAgreed,fc_fcmFLoginClass3DataFieldSize,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fspflsrtable_sth = $mysql->prepare_cached("INSERT INTO t11fspflsrtable(deviceid,scantime,fc_t11FspfLsrDomainId,fc_t11FspfLsrType,fc_t11FspfLsrAdvDomainId,fc_t11FspfLsrAge,fc_t11FspfLsrIncarnationNumber,fc_t11FspfLsrCheckSum,fc_t11FspfLsrLinks,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
		my $fcfemoduletable_sth = $mysql->prepare_cached("INSERT INTO fcfemoduletable(deviceid,scantime,fc_fcFeModuleIndex,fc_fcFeModuleDescr,fc_fcFeModuleObjectID,fc_fcFeModuleOperStatus,fc_fcFeModuleLastChange,fc_fcFeModuleFxPortCapacity,fc_fcFeModuleName,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
		my $t11zsnotifycontroltable_sth = $mysql->prepare_cached("INSERT INTO t11zsnotifycontroltable(deviceid,scantime,fc_t11ZsNotifyRequestRejectEnable,fc_t11ZsNotifyMergeFailureEnable,fc_t11ZsNotifyMergeSuccessEnable,fc_t11ZsNotifyDefZoneChangeEnable,fc_t11ZsNotifyActivateEnable,fc_t11ZsRejectCtCommandString,fc_t11ZsRejectRequestSource,fc_t11ZsRejectReasonCode,fc_t11ZsRejectReasonCodeExp,fc_t11ZsRejectReasonVendorCode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $fcmisporttable_sth = $mysql->prepare_cached("INSERT INTO fcmisporttable(deviceid,scantime,fc_fcmISPortClassFCredit,fc_fcmISPortClassFDataFieldSize,snmpindex) VALUES (?,?,?,?,?)");
		my $t11zszonemembertable_sth = $mysql->prepare_cached("INSERT INTO t11zszonemembertable(deviceid,scantime,fc_t11ZsZoneMemberParentType,fc_t11ZsZoneMemberParentIndex,fc_t11ZsZoneMemberIndex,fc_t11ZsZoneMemberFormat,fc_t11ZsZoneMemberID,fc_t11ZsZoneMemberRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
		my $fcfxportcaptable_sth = $mysql->prepare_cached("INSERT INTO fcfxportcaptable(deviceid,scantime,fc_fcFxPortCapFcphVersionHigh,fc_fcFxPortCapClass2SeqDeliv,fc_fcFxPortCapClass3SeqDeliv,fc_fcFxPortCapHoldTimeMax,fc_fcFxPortCapHoldTimeMin,fc_fcFxPortCapFcphVersionLow,fc_fcFxPortCapBbCreditMax,fc_fcFxPortCapBbCreditMin,fc_fcFxPortCapRxDataFieldSizeMax,fc_fcFxPortCapRxDataFieldSizeMin,fc_fcFxPortCapCos,fc_fcFxPortCapIntermix,fc_fcFxPortCapStackedConnMode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcsnotifycontroltable_sth = $mysql->prepare_cached("INSERT INTO t11fcsnotifycontroltable(deviceid,scantime,fc_t11FcsReqRejectNotifyEnable,fc_t11FcsDiscoveryCompNotifyEnable,fc_t11FcsMgmtAddrChangeNotifyEnable,fc_t11FcsRejectCtCommandString,fc_t11FcsRejectRequestSource,fc_t11FcsRejectReasonCode,fc_t11FcsRejectReasonCodeExp,fc_t11FcsRejectReasonVendorCode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
		my $fcmporttable_sth = $mysql->prepare_cached("INSERT INTO fcmporttable(deviceid,scantime,fc_fcmPortInstanceIndex,fc_fcmPortWwn,fc_fcmPortNodeWwn,fc_fcmPortAdminType,fc_fcmPortOperType,fc_fcmPortFcCapClass,fc_fcmPortFcOperClass,fc_fcmPortTransmitterType,fc_fcmPortConnectorType,fc_fcmPortSerialNumber,fc_fcmPortPhysicalNumber,fc_fcmPortAdminSpeed,fc_fcmPortCapProtocols,fc_fcmPortOperProtocols,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $t11fcroutefabrictable_sth = $mysql->prepare_cached("INSERT INTO t11fcroutefabrictable(deviceid,scantime,fc_t11FcRouteFabricIndex,fc_t11FcRouteFabricLastChange,snmpindex) VALUES (?,?,?,?,?)");

##Collect information for tablet11nsregtable
		my $fc_t11NsRegFabricIndex=$info->fc_t11NsRegFabricIndex();
		my $fc_t11NsRegPortIdentifier=$info->fc_t11NsRegPortIdentifier();
		my $fc_t11NsRegPortName=$info->fc_t11NsRegPortName();
		my $fc_t11NsRegNodeName=$info->fc_t11NsRegNodeName();
		my $fc_t11NsRegClassOfSvc=$info->fc_t11NsRegClassOfSvc();
		my $fc_t11NsRegNodeIpAddress=$info->fc_t11NsRegNodeIpAddress();
		my $fc_t11NsRegProcAssoc=$info->fc_t11NsRegProcAssoc();
		my $fc_t11NsRegFc4Type=$info->fc_t11NsRegFc4Type();
		my $fc_t11NsRegPortType=$info->fc_t11NsRegPortType();
		my $fc_t11NsRegPortIpAddress=$info->fc_t11NsRegPortIpAddress();
		my $fc_t11NsRegFabricPortName=$info->fc_t11NsRegFabricPortName();
		my $fc_t11NsRegHardAddress=$info->fc_t11NsRegHardAddress();
		my $fc_t11NsRegSymbolicPortName=$info->fc_t11NsRegSymbolicPortName();
		my $fc_t11NsRegSymbolicNodeName=$info->fc_t11NsRegSymbolicNodeName();
		my $fc_t11NsRegFc4Features=$info->fc_t11NsRegFc4Features();

##Collect information for tablet11zsstatstable
		my $fc_t11ZsOutMergeRequests=$info->fc_t11ZsOutMergeRequests();
		my $fc_t11ZsInMergeAccepts=$info->fc_t11ZsInMergeAccepts();
		my $fc_t11ZsInMergeRequests=$info->fc_t11ZsInMergeRequests();
		my $fc_t11ZsOutMergeAccepts=$info->fc_t11ZsOutMergeAccepts();
		my $fc_t11ZsOutChangeRequests=$info->fc_t11ZsOutChangeRequests();
		my $fc_t11ZsInChangeAccepts=$info->fc_t11ZsInChangeAccepts();
		my $fc_t11ZsInChangeRequests=$info->fc_t11ZsInChangeRequests();
		my $fc_t11ZsOutChangeAccepts=$info->fc_t11ZsOutChangeAccepts();
		my $fc_t11ZsInZsRequests=$info->fc_t11ZsInZsRequests();
		my $fc_t11ZsOutZsRejects=$info->fc_t11ZsOutZsRejects();

##Collect information for tablet11fspflinktable
		my $fc_t11FspfLinkIndex=$info->fc_t11FspfLinkIndex();
		my $fc_t11FspfLinkNbrDomainId=$info->fc_t11FspfLinkNbrDomainId();
		my $fc_t11FspfLinkPortIndex=$info->fc_t11FspfLinkPortIndex();
		my $fc_t11FspfLinkNbrPortIndex=$info->fc_t11FspfLinkNbrPortIndex();
		my $fc_t11FspfLinkType=$info->fc_t11FspfLinkType();
		my $fc_t11FspfLinkCost=$info->fc_t11FspfLinkCost();

##Collect information for tablefcfxporttable
		my $fc_fcFxPortIndex=$info->fc_fcFxPortIndex();
		my $fc_fcFxPortIntermixSupported=$info->fc_fcFxPortIntermixSupported();
		my $fc_fcFxPortStackedConnMode=$info->fc_fcFxPortStackedConnMode();
		my $fc_fcFxPortClass2SeqDeliv=$info->fc_fcFxPortClass2SeqDeliv();
		my $fc_fcFxPortClass3SeqDeliv=$info->fc_fcFxPortClass3SeqDeliv();
		my $fc_fcFxPortHoldTime=$info->fc_fcFxPortHoldTime();
		my $fc_fcFxPortName=$info->fc_fcFxPortName();
		my $fc_fcFxPortFcphVersionHigh=$info->fc_fcFxPortFcphVersionHigh();
		my $fc_fcFxPortFcphVersionLow=$info->fc_fcFxPortFcphVersionLow();
		my $fc_fcFxPortBbCredit=$info->fc_fcFxPortBbCredit();
		my $fc_fcFxPortRxBufSize=$info->fc_fcFxPortRxBufSize();
		my $fc_fcFxPortRatov=$info->fc_fcFxPortRatov();
		my $fc_fcFxPortEdtov=$info->fc_fcFxPortEdtov();
		my $fc_fcFxPortCosSupported=$info->fc_fcFxPortCosSupported();

##Collect information for tablet11fspftable
		my $fc_t11FspfFabricIndex=$info->fc_t11FspfFabricIndex();
		my $fc_t11FspfMinLsArrival=$info->fc_t11FspfMinLsArrival();
		my $fc_t11FspfMinLsInterval=$info->fc_t11FspfMinLsInterval();
		my $fc_t11FspfLsRefreshTime=$info->fc_t11FspfLsRefreshTime();
		my $fc_t11FspfMaxAge=$info->fc_t11FspfMaxAge();
		my $fc_t11FspfMaxAgeDiscards=$info->fc_t11FspfMaxAgeDiscards();
		my $fc_t11FspfPathComputations=$info->fc_t11FspfPathComputations();
		my $fc_t11FspfChecksumErrors=$info->fc_t11FspfChecksumErrors();
		my $fc_t11FspfLsrs=$info->fc_t11FspfLsrs();
		my $fc_t11FspfCreateTime=$info->fc_t11FspfCreateTime();
		my $fc_t11FspfAdminStatus=$info->fc_t11FspfAdminStatus();
		my $fc_t11FspfOperStatus=$info->fc_t11FspfOperStatus();
		my $fc_t11FspfNbrStateChangNotifyEnable=$info->fc_t11FspfNbrStateChangNotifyEnable();
		my $fc_t11FspfSetToDefault=$info->fc_t11FspfSetToDefault();
		my $fc_t11FspfStorageType=$info->fc_t11FspfStorageType();

##Collect information for tablet11zsactivetable
		my $fc_t11ZsActiveZoneSetName=$info->fc_t11ZsActiveZoneSetName();
		my $fc_t11ZsActiveActivateTime=$info->fc_t11ZsActiveActivateTime();

##Collect information for tablefcfxportc2accountingtable
		my $fc_fcFxPortC2InFrames=$info->fc_fcFxPortC2InFrames();
		my $fc_fcFxPortC2OutFrames=$info->fc_fcFxPortC2OutFrames();
		my $fc_fcFxPortC2InOctets=$info->fc_fcFxPortC2InOctets();
		my $fc_fcFxPortC2OutOctets=$info->fc_fcFxPortC2OutOctets();
		my $fc_fcFxPortC2Discards=$info->fc_fcFxPortC2Discards();
		my $fc_fcFxPortC2FbsyFrames=$info->fc_fcFxPortC2FbsyFrames();
		my $fc_fcFxPortC2FrjtFrames=$info->fc_fcFxPortC2FrjtFrames();

##Collect information for tablet11fcsnodenamelisttable
		my $fc_t11FcsNodeNameListIndex=$info->fc_t11FcsNodeNameListIndex();
		my $fc_t11FcsNodeName=$info->fc_t11FcsNodeName();

##Collect information for tablet11fcroutetable
		my $fc_t11FcRouteDestAddrId=$info->fc_t11FcRouteDestAddrId();
		my $fc_t11FcRouteDestMask=$info->fc_t11FcRouteDestMask();
		my $fc_t11FcRouteSrcAddrId=$info->fc_t11FcRouteSrcAddrId();
		my $fc_t11FcRouteSrcMask=$info->fc_t11FcRouteSrcMask();
		my $fc_t11FcRouteInInterface=$info->fc_t11FcRouteInInterface();
		my $fc_t11FcRouteProto=$info->fc_t11FcRouteProto();
		my $fc_t11FcRouteOutInterface=$info->fc_t11FcRouteOutInterface();
		my $fc_t11FcRouteDomainId=$info->fc_t11FcRouteDomainId();
		my $fc_t11FcRouteMetric=$info->fc_t11FcRouteMetric();
		my $fc_t11FcRouteType=$info->fc_t11FcRouteType();
		my $fc_t11FcRouteIfDown=$info->fc_t11FcRouteIfDown();
		my $fc_t11FcRouteStorageType=$info->fc_t11FcRouteStorageType();
		my $fc_t11FcRouteRowStatus=$info->fc_t11FcRouteRowStatus();

##Collect information for tablefcmswitchtable
		my $fc_fcmSwitchIndex=$info->fc_fcmSwitchIndex();
		my $fc_fcmSwitchDomainId=$info->fc_fcmSwitchDomainId();
		my $fc_fcmSwitchPrincipal=$info->fc_fcmSwitchPrincipal();
		my $fc_fcmSwitchWWN=$info->fc_fcmSwitchWWN();

##Collect information for tablefcmportstatstable
		my $fc_fcmPortBBCreditZeros=$info->fc_fcmPortBBCreditZeros();
		my $fc_fcmPortFullInputBuffers=$info->fc_fcmPortFullInputBuffers();
		my $fc_fcmPortClass2RxFrames=$info->fc_fcmPortClass2RxFrames();
		my $fc_fcmPortClass2RxOctets=$info->fc_fcmPortClass2RxOctets();
		my $fc_fcmPortClass2TxFrames=$info->fc_fcmPortClass2TxFrames();
		my $fc_fcmPortClass2TxOctets=$info->fc_fcmPortClass2TxOctets();
		my $fc_fcmPortClass2Discards=$info->fc_fcmPortClass2Discards();
		my $fc_fcmPortClass2RxFbsyFrames=$info->fc_fcmPortClass2RxFbsyFrames();
		my $fc_fcmPortClass2RxPbsyFrames=$info->fc_fcmPortClass2RxPbsyFrames();
		my $fc_fcmPortClass2RxFrjtFrames=$info->fc_fcmPortClass2RxFrjtFrames();
		my $fc_fcmPortClass2RxPrjtFrames=$info->fc_fcmPortClass2RxPrjtFrames();
		my $fc_fcmPortClass2TxFbsyFrames=$info->fc_fcmPortClass2TxFbsyFrames();
		my $fc_fcmPortClass2TxPbsyFrames=$info->fc_fcmPortClass2TxPbsyFrames();
		my $fc_fcmPortClass2TxFrjtFrames=$info->fc_fcmPortClass2TxFrjtFrames();
		my $fc_fcmPortClass2TxPrjtFrames=$info->fc_fcmPortClass2TxPrjtFrames();
		my $fc_fcmPortClass3RxFrames=$info->fc_fcmPortClass3RxFrames();
		my $fc_fcmPortClass3RxOctets=$info->fc_fcmPortClass3RxOctets();
		my $fc_fcmPortClass3TxFrames=$info->fc_fcmPortClass3TxFrames();
		my $fc_fcmPortClass3TxOctets=$info->fc_fcmPortClass3TxOctets();
		my $fc_fcmPortClass3Discards=$info->fc_fcmPortClass3Discards();
		my $fc_fcmPortClassFRxFrames=$info->fc_fcmPortClassFRxFrames();
		my $fc_fcmPortClassFRxOctets=$info->fc_fcmPortClassFRxOctets();
		my $fc_fcmPortClassFTxFrames=$info->fc_fcmPortClassFTxFrames();
		my $fc_fcmPortClassFTxOctets=$info->fc_fcmPortClassFTxOctets();
		my $fc_fcmPortClassFDiscards=$info->fc_fcmPortClassFDiscards();

##Collect information for tablet11vfporttable
		my $fc_t11vfPortVfId=$info->fc_t11vfPortVfId();
		my $fc_t11vfPortTaggingAdminStatus=$info->fc_t11vfPortTaggingAdminStatus();
		my $fc_t11vfPortTaggingOperStatus=$info->fc_t11vfPortTaggingOperStatus();
		my $fc_t11vfPortStorageType=$info->fc_t11vfPortStorageType();

##Collect information for tablet11zssettable
		my $fc_t11ZsSetIndex=$info->fc_t11ZsSetIndex();
		my $fc_t11ZsSetName=$info->fc_t11ZsSetName();
		my $fc_t11ZsSetRowStatus=$info->fc_t11ZsSetRowStatus();

##Collect information for tablet11zsactivezonetable
		my $fc_t11ZsActiveZoneIndex=$info->fc_t11ZsActiveZoneIndex();
		my $fc_t11ZsActiveZoneName=$info->fc_t11ZsActiveZoneName();
		my $fc_t11ZsActiveZoneBroadcastZoning=$info->fc_t11ZsActiveZoneBroadcastZoning();
		my $fc_t11ZsActiveZoneHardZoning=$info->fc_t11ZsActiveZoneHardZoning();

##Collect information for tablefcmlinktable
		my $fc_fcmLinkIndex=$info->fc_fcmLinkIndex();
		my $fc_fcmLinkEnd1NodeWwn=$info->fc_fcmLinkEnd1NodeWwn();
		my $fc_fcmLinkEnd1PhysPortNumber=$info->fc_fcmLinkEnd1PhysPortNumber();
		my $fc_fcmLinkEnd1PortWwn=$info->fc_fcmLinkEnd1PortWwn();
		my $fc_fcmLinkEnd2NodeWwn=$info->fc_fcmLinkEnd2NodeWwn();
		my $fc_fcmLinkEnd2PhysPortNumber=$info->fc_fcmLinkEnd2PhysPortNumber();
		my $fc_fcmLinkEnd2PortWwn=$info->fc_fcmLinkEnd2PortWwn();
		my $fc_fcmLinkEnd2AgentAddress=$info->fc_fcmLinkEnd2AgentAddress();
		my $fc_fcmLinkEnd2PortType=$info->fc_fcmLinkEnd2PortType();
		my $fc_fcmLinkEnd2UnitType=$info->fc_fcmLinkEnd2UnitType();
		my $fc_fcmLinkEnd2FcAddressId=$info->fc_fcmLinkEnd2FcAddressId();

##Collect information for tablet11fcsfabricdiscoverytable
		my $fc_t11FcsFabricDiscoveryRangeLow=$info->fc_t11FcsFabricDiscoveryRangeLow();
		my $fc_t11FcsFabricDiscoveryRangeHigh=$info->fc_t11FcsFabricDiscoveryRangeHigh();
		my $fc_t11FcsFabricDiscoveryStart=$info->fc_t11FcsFabricDiscoveryStart();
		my $fc_t11FcsFabricDiscoveryTimeOut=$info->fc_t11FcsFabricDiscoveryTimeOut();

##Collect information for tablet11zssetzonetable
		my $fc_t11ZsSetZoneRowStatus=$info->fc_t11ZsSetZoneRowStatus();

##Collect information for tablet11fcrscnnotifycontroltable
		my $fc_t11FcRscnIlsRejectNotifyEnable=$info->fc_t11FcRscnIlsRejectNotifyEnable();
		my $fc_t11FcRscnElsRejectNotifyEnable=$info->fc_t11FcRscnElsRejectNotifyEnable();
		my $fc_t11FcRscnRejectedRequestString=$info->fc_t11FcRscnRejectedRequestString();
		my $fc_t11FcRscnRejectedRequestSource=$info->fc_t11FcRscnRejectedRequestSource();
		my $fc_t11FcRscnRejectReasonCode=$info->fc_t11FcRscnRejectReasonCode();
		my $fc_t11FcRscnRejectReasonCodeExp=$info->fc_t11FcRscnRejectReasonCodeExp();
		my $fc_t11FcRscnRejectReasonVendorCode=$info->fc_t11FcRscnRejectReasonVendorCode();

##Collect information for tablet11zsattribblocktable
		my $fc_t11ZsAttribBlockIndex=$info->fc_t11ZsAttribBlockIndex();
		my $fc_t11ZsAttribBlockName=$info->fc_t11ZsAttribBlockName();
		my $fc_t11ZsAttribBlockRowStatus=$info->fc_t11ZsAttribBlockRowStatus();

##Collect information for tablet11zsservertable
		my $fc_t11ZsServerFabricIndex=$info->fc_t11ZsServerFabricIndex();
		my $fc_t11ZsServerCapabilityObject=$info->fc_t11ZsServerCapabilityObject();
		my $fc_t11ZsServerDatabaseStorageType=$info->fc_t11ZsServerDatabaseStorageType();
		my $fc_t11ZsServerDistribute=$info->fc_t11ZsServerDistribute();
		my $fc_t11ZsServerCommit=$info->fc_t11ZsServerCommit();
		my $fc_t11ZsServerResult=$info->fc_t11ZsServerResult();
		my $fc_t11ZsServerReasonCode=$info->fc_t11ZsServerReasonCode();
		my $fc_t11ZsServerReasonCodeExp=$info->fc_t11ZsServerReasonCodeExp();
		my $fc_t11ZsServerReasonVendorCode=$info->fc_t11ZsServerReasonVendorCode();
		my $fc_t11ZsServerLastChange=$info->fc_t11ZsServerLastChange();
		my $fc_t11ZsServerHardZoning=$info->fc_t11ZsServerHardZoning();
		my $fc_t11ZsServerReadFromDatabase=$info->fc_t11ZsServerReadFromDatabase();
		my $fc_t11ZsServerOperationMode=$info->fc_t11ZsServerOperationMode();
		my $fc_t11ZsServerChangeModeResult=$info->fc_t11ZsServerChangeModeResult();
		my $fc_t11ZsServerDefaultZoneSetting=$info->fc_t11ZsServerDefaultZoneSetting();
		my $fc_t11ZsServerMergeControlSetting=$info->fc_t11ZsServerMergeControlSetting();
		my $fc_t11ZsServerDefZoneBroadcast=$info->fc_t11ZsServerDefZoneBroadcast();

##Collect information for tablet11famdatabasetable
		my $fc_t11FamDatabaseDomainId=$info->fc_t11FamDatabaseDomainId();
		my $fc_t11FamDatabaseSwitchWwn=$info->fc_t11FamDatabaseSwitchWwn();

##Collect information for tablet11vfvirtualswitchtable
		my $fc_t11vfVirtualSwitchVfId=$info->fc_t11vfVirtualSwitchVfId();
		my $fc_t11vfVirtualSwitchCoreSwitchName=$info->fc_t11vfVirtualSwitchCoreSwitchName();
		my $fc_t11vfVirtualSwitchRowStatus=$info->fc_t11vfVirtualSwitchRowStatus();
		my $fc_t11vfVirtualSwitchStorageType=$info->fc_t11vfVirtualSwitchStorageType();

##Collect information for tablet11zszonetable
		my $fc_t11ZsZoneIndex=$info->fc_t11ZsZoneIndex();
		my $fc_t11ZsZoneName=$info->fc_t11ZsZoneName();
		my $fc_t11ZsZoneAttribBlock=$info->fc_t11ZsZoneAttribBlock();
		my $fc_t11ZsZoneRowStatus=$info->fc_t11ZsZoneRowStatus();

##Collect information for tablet11fcsplatformtable
		my $fc_t11FcsPlatformIndex=$info->fc_t11FcsPlatformIndex();
		my $fc_t11FcsPlatformName=$info->fc_t11FcsPlatformName();
		my $fc_t11FcsPlatformType=$info->fc_t11FcsPlatformType();
		my $fc_t11FcsPlatformNodeNameListIndex=$info->fc_t11FcsPlatformNodeNameListIndex();
		my $fc_t11FcsPlatformMgmtAddrListIndex=$info->fc_t11FcsPlatformMgmtAddrListIndex();
		my $fc_t11FcsPlatformVendorId=$info->fc_t11FcsPlatformVendorId();
		my $fc_t11FcsPlatformProductId=$info->fc_t11FcsPlatformProductId();
		my $fc_t11FcsPlatformProductRevLevel=$info->fc_t11FcsPlatformProductRevLevel();
		my $fc_t11FcsPlatformDescription=$info->fc_t11FcsPlatformDescription();
		my $fc_t11FcsPlatformLabel=$info->fc_t11FcsPlatformLabel();
		my $fc_t11FcsPlatformLocation=$info->fc_t11FcsPlatformLocation();
		my $fc_t11FcsPlatformSystemID=$info->fc_t11FcsPlatformSystemID();
		my $fc_t11FcsPlatformSysMgmtAddr=$info->fc_t11FcsPlatformSysMgmtAddr();
		my $fc_t11FcsPlatformClusterId=$info->fc_t11FcsPlatformClusterId();
		my $fc_t11FcsPlatformClusterMgmtAddr=$info->fc_t11FcsPlatformClusterMgmtAddr();
		my $fc_t11FcsPlatformFC4Types=$info->fc_t11FcsPlatformFC4Types();

##Collect information for tablet11fcsstatstable
		my $fc_t11FcsInGetReqs=$info->fc_t11FcsInGetReqs();
		my $fc_t11FcsOutGetReqs=$info->fc_t11FcsOutGetReqs();
		my $fc_t11FcsInRegReqs=$info->fc_t11FcsInRegReqs();
		my $fc_t11FcsOutRegReqs=$info->fc_t11FcsOutRegReqs();
		my $fc_t11FcsInDeregReqs=$info->fc_t11FcsInDeregReqs();
		my $fc_t11FcsOutDeregReqs=$info->fc_t11FcsOutDeregReqs();
		my $fc_t11FcsRejects=$info->fc_t11FcsRejects();

##Collect information for tablefcmporterrorstable
		my $fc_fcmPortRxLinkResets=$info->fc_fcmPortRxLinkResets();
		my $fc_fcmPortTxLinkResets=$info->fc_fcmPortTxLinkResets();
		my $fc_fcmPortLinkResets=$info->fc_fcmPortLinkResets();
		my $fc_fcmPortRxOfflineSequences=$info->fc_fcmPortRxOfflineSequences();
		my $fc_fcmPortTxOfflineSequences=$info->fc_fcmPortTxOfflineSequences();
		my $fc_fcmPortLinkFailures=$info->fc_fcmPortLinkFailures();
		my $fc_fcmPortLossofSynchs=$info->fc_fcmPortLossofSynchs();
		my $fc_fcmPortLossofSignals=$info->fc_fcmPortLossofSignals();
		my $fc_fcmPortPrimSeqProtocolErrors=$info->fc_fcmPortPrimSeqProtocolErrors();
		my $fc_fcmPortInvalidTxWords=$info->fc_fcmPortInvalidTxWords();
		my $fc_fcmPortInvalidCRCs=$info->fc_fcmPortInvalidCRCs();
		my $fc_fcmPortInvalidOrderedSets=$info->fc_fcmPortInvalidOrderedSets();
		my $fc_fcmPortFrameTooLongs=$info->fc_fcmPortFrameTooLongs();
		my $fc_fcmPortTruncatedFrames=$info->fc_fcmPortTruncatedFrames();
		my $fc_fcmPortAddressErrors=$info->fc_fcmPortAddressErrors();
		my $fc_fcmPortDelimiterErrors=$info->fc_fcmPortDelimiterErrors();
		my $fc_fcmPortEncodingDisparityErrors=$info->fc_fcmPortEncodingDisparityErrors();
		my $fc_fcmPortOtherErrors=$info->fc_fcmPortOtherErrors();

##Collect information for tablet11fcrscnregtable
		my $fc_t11FcRscnFabricIndex=$info->fc_t11FcRscnFabricIndex();
		my $fc_t11FcRscnRegFcId=$info->fc_t11FcRscnRegFcId();
		my $fc_t11FcRscnRegType=$info->fc_t11FcRscnRegType();

##Collect information for tablet11zsaliastable
		my $fc_t11ZsAliasIndex=$info->fc_t11ZsAliasIndex();
		my $fc_t11ZsAliasName=$info->fc_t11ZsAliasName();
		my $fc_t11ZsAliasRowStatus=$info->fc_t11ZsAliasRowStatus();

##Collect information for tablet11nsrejecttable
		my $fc_t11NsRejectCtCommandString=$info->fc_t11NsRejectCtCommandString();
		my $fc_t11NsRejectReasonCode=$info->fc_t11NsRejectReasonCode();
		my $fc_t11NsRejReasonCodeExp=$info->fc_t11NsRejReasonCodeExp();
		my $fc_t11NsRejReasonVendorCode=$info->fc_t11NsRejReasonVendorCode();

##Collect information for tablet11nsinfosubsettable
		my $fc_t11NsInfoSubsetIndex=$info->fc_t11NsInfoSubsetIndex();
		my $fc_t11NsInfoSubsetSwitchIndex=$info->fc_t11NsInfoSubsetSwitchIndex();
		my $fc_t11NsInfoSubsetTableLastChange=$info->fc_t11NsInfoSubsetTableLastChange();
		my $fc_t11NsInfoSubsetNumRows=$info->fc_t11NsInfoSubsetNumRows();
		my $fc_t11NsInfoSubsetTotalRejects=$info->fc_t11NsInfoSubsetTotalRejects();
		my $fc_t11NsInfoSubsetRejReqNotfyEnable=$info->fc_t11NsInfoSubsetRejReqNotfyEnable();

##Collect information for tablefcfxportphystable
		my $fc_fcFxPortPhysAdminStatus=$info->fc_fcFxPortPhysAdminStatus();
		my $fc_fcFxPortPhysOperStatus=$info->fc_fcFxPortPhysOperStatus();
		my $fc_fcFxPortPhysLastChange=$info->fc_fcFxPortPhysLastChange();
		my $fc_fcFxPortPhysRttov=$info->fc_fcFxPortPhysRttov();

##Collect information for tablefcfxportstatustable
		my $fc_fcFxPortID=$info->fc_fcFxPortID();
		my $fc_fcFxPortBbCreditAvailable=$info->fc_fcFxPortBbCreditAvailable();
		my $fc_fcFxPortOperMode=$info->fc_fcFxPortOperMode();
		my $fc_fcFxPortAdminMode=$info->fc_fcFxPortAdminMode();

##Collect information for tablefcfxporterrortable
		my $fc_fcFxPortLinkFailures=$info->fc_fcFxPortLinkFailures();
		my $fc_fcFxPortLinkResetOuts=$info->fc_fcFxPortLinkResetOuts();
		my $fc_fcFxPortOlsIns=$info->fc_fcFxPortOlsIns();
		my $fc_fcFxPortOlsOuts=$info->fc_fcFxPortOlsOuts();
		my $fc_fcFxPortSyncLosses=$info->fc_fcFxPortSyncLosses();
		my $fc_fcFxPortSigLosses=$info->fc_fcFxPortSigLosses();
		my $fc_fcFxPortPrimSeqProtoErrors=$info->fc_fcFxPortPrimSeqProtoErrors();
		my $fc_fcFxPortInvalidTxWords=$info->fc_fcFxPortInvalidTxWords();
		my $fc_fcFxPortInvalidCrcs=$info->fc_fcFxPortInvalidCrcs();
		my $fc_fcFxPortDelimiterErrors=$info->fc_fcFxPortDelimiterErrors();
		my $fc_fcFxPortAddressIdErrors=$info->fc_fcFxPortAddressIdErrors();
		my $fc_fcFxPortLinkResetIns=$info->fc_fcFxPortLinkResetIns();

##Collect information for tablet11zsactiveattribtable
		my $fc_t11ZsActiveAttribIndex=$info->fc_t11ZsActiveAttribIndex();
		my $fc_t11ZsActiveAttribType=$info->fc_t11ZsActiveAttribType();
		my $fc_t11ZsActiveAttribValue=$info->fc_t11ZsActiveAttribValue();

##Collect information for tablet11vfcoreswitchtable
		my $fc_t11vfCoreSwitchSwitchName=$info->fc_t11vfCoreSwitchSwitchName();
		my $fc_t11vfCoreSwitchMaxSupported=$info->fc_t11vfCoreSwitchMaxSupported();
		my $fc_t11vfCoreSwitchStorageType=$info->fc_t11vfCoreSwitchStorageType();

##Collect information for tablet11nsregfc4descriptortable
		my $fc_t11NsRegFc4TypeValue=$info->fc_t11NsRegFc4TypeValue();
		my $fc_t11NsRegFc4Descriptor=$info->fc_t11NsRegFc4Descriptor();

##Collect information for tablet11fspfiftable
		my $fc_t11FspfIfIndex=$info->fc_t11FspfIfIndex();
		my $fc_t11FspfIfHelloInterval=$info->fc_t11FspfIfHelloInterval();
		my $fc_t11FspfIfDeadInterval=$info->fc_t11FspfIfDeadInterval();
		my $fc_t11FspfIfRetransmitInterval=$info->fc_t11FspfIfRetransmitInterval();
		my $fc_t11FspfIfInLsuPkts=$info->fc_t11FspfIfInLsuPkts();
		my $fc_t11FspfIfInLsaPkts=$info->fc_t11FspfIfInLsaPkts();
		my $fc_t11FspfIfOutLsuPkts=$info->fc_t11FspfIfOutLsuPkts();
		my $fc_t11FspfIfOutLsaPkts=$info->fc_t11FspfIfOutLsaPkts();
		my $fc_t11FspfIfOutHelloPkts=$info->fc_t11FspfIfOutHelloPkts();
		my $fc_t11FspfIfInHelloPkts=$info->fc_t11FspfIfInHelloPkts();
		my $fc_t11FspfIfRetransmittedLsuPkts=$info->fc_t11FspfIfRetransmittedLsuPkts();
		my $fc_t11FspfIfInErrorPkts=$info->fc_t11FspfIfInErrorPkts();
		my $fc_t11FspfIfNbrState=$info->fc_t11FspfIfNbrState();
		my $fc_t11FspfIfNbrDomainId=$info->fc_t11FspfIfNbrDomainId();
		my $fc_t11FspfIfNbrPortIndex=$info->fc_t11FspfIfNbrPortIndex();
		my $fc_t11FspfIfAdminStatus=$info->fc_t11FspfIfAdminStatus();
		my $fc_t11FspfIfCreateTime=$info->fc_t11FspfIfCreateTime();
		my $fc_t11FspfIfSetToDefault=$info->fc_t11FspfIfSetToDefault();
		my $fc_t11FspfIfLinkCostFactor=$info->fc_t11FspfIfLinkCostFactor();
		my $fc_t11FspfIfStorageType=$info->fc_t11FspfIfStorageType();
		my $fc_t11FspfIfRowStatus=$info->fc_t11FspfIfRowStatus();

##Collect information for tablefcfxportc1accountingtable
		my $fc_fcFxPortC1InFrames=$info->fc_fcFxPortC1InFrames();
		my $fc_fcFxPortC1ConnTime=$info->fc_fcFxPortC1ConnTime();
		my $fc_fcFxPortC1OutFrames=$info->fc_fcFxPortC1OutFrames();
		my $fc_fcFxPortC1InOctets=$info->fc_fcFxPortC1InOctets();
		my $fc_fcFxPortC1OutOctets=$info->fc_fcFxPortC1OutOctets();
		my $fc_fcFxPortC1Discards=$info->fc_fcFxPortC1Discards();
		my $fc_fcFxPortC1FbsyFrames=$info->fc_fcFxPortC1FbsyFrames();
		my $fc_fcFxPortC1FrjtFrames=$info->fc_fcFxPortC1FrjtFrames();
		my $fc_fcFxPortC1InConnections=$info->fc_fcFxPortC1InConnections();
		my $fc_fcFxPortC1OutConnections=$info->fc_fcFxPortC1OutConnections();

##Collect information for tablet11fcrscnstatstable
		my $fc_t11FcRscnInScrs=$info->fc_t11FcRscnInScrs();
		my $fc_t11FcRscnInRscns=$info->fc_t11FcRscnInRscns();
		my $fc_t11FcRscnOutRscns=$info->fc_t11FcRscnOutRscns();
		my $fc_t11FcRscnInSwRscns=$info->fc_t11FcRscnInSwRscns();
		my $fc_t11FcRscnOutSwRscns=$info->fc_t11FcRscnOutSwRscns();
		my $fc_t11FcRscnScrRejects=$info->fc_t11FcRscnScrRejects();
		my $fc_t11FcRscnRscnRejects=$info->fc_t11FcRscnRscnRejects();
		my $fc_t11FcRscnSwRscnRejects=$info->fc_t11FcRscnSwRscnRejects();
		my $fc_t11FcRscnInUnspecifiedRscns=$info->fc_t11FcRscnInUnspecifiedRscns();
		my $fc_t11FcRscnOutUnspecifiedRscns=$info->fc_t11FcRscnOutUnspecifiedRscns();
		my $fc_t11FcRscnInChangedAttribRscns=$info->fc_t11FcRscnInChangedAttribRscns();
		my $fc_t11FcRscnOutChangedAttribRscns=$info->fc_t11FcRscnOutChangedAttribRscns();
		my $fc_t11FcRscnInChangedServiceRscns=$info->fc_t11FcRscnInChangedServiceRscns();
		my $fc_t11FcRscnOutChangedServiceRscns=$info->fc_t11FcRscnOutChangedServiceRscns();
		my $fc_t11FcRscnInChangedSwitchRscns=$info->fc_t11FcRscnInChangedSwitchRscns();
		my $fc_t11FcRscnOutChangedSwitchRscns=$info->fc_t11FcRscnOutChangedSwitchRscns();
		my $fc_t11FcRscnInRemovedRscns=$info->fc_t11FcRscnInRemovedRscns();
		my $fc_t11FcRscnOutRemovedRscns=$info->fc_t11FcRscnOutRemovedRscns();

##Collect information for tablet11famiftable
		my $fc_t11FamIfRcfReject=$info->fc_t11FamIfRcfReject();
		my $fc_t11FamIfRole=$info->fc_t11FamIfRole();
		my $fc_t11FamIfRowStatus=$info->fc_t11FamIfRowStatus();

##Collect information for tablet11fcsietable
		my $fc_t11FcsIeName=$info->fc_t11FcsIeName();
		my $fc_t11FcsIeType=$info->fc_t11FcsIeType();
		my $fc_t11FcsIeDomainId=$info->fc_t11FcsIeDomainId();
		my $fc_t11FcsIeMgmtId=$info->fc_t11FcsIeMgmtId();
		my $fc_t11FcsIeFabricName=$info->fc_t11FcsIeFabricName();
		my $fc_t11FcsIeLogicalName=$info->fc_t11FcsIeLogicalName();
		my $fc_t11FcsIeMgmtAddrListIndex=$info->fc_t11FcsIeMgmtAddrListIndex();
		my $fc_t11FcsIeInfoList=$info->fc_t11FcsIeInfoList();

##Collect information for tablefc_t11famtable
		my $fc_t11FamFabricIndex=$info->fc_t11FamFabricIndex();
		my $fc_t11FamConfigDomainId=$info->fc_t11FamConfigDomainId();
		my $fc_t11FamConfigDomainIdType=$info->fc_t11FamConfigDomainIdType();
		my $fc_t11FamAutoReconfigure=$info->fc_t11FamAutoReconfigure();
		my $fc_t11FamContiguousAllocation=$info->fc_t11FamContiguousAllocation();
		my $fc_t11FamPriority=$info->fc_t11FamPriority();
		my $fc_t11FamPrincipalSwitchWwn=$info->fc_t11FamPrincipalSwitchWwn();
		my $fc_t11FamLocalSwitchWwn=$info->fc_t11FamLocalSwitchWwn();
		my $fc_t11FamAssignedAreaIdList=$info->fc_t11FamAssignedAreaIdList();
		my $fc_t11FamGrantedFcIds=$info->fc_t11FamGrantedFcIds();
		my $fc_t11FamRecoveredFcIds=$info->fc_t11FamRecoveredFcIds();
		my $fc_t11FamFreeFcIds=$info->fc_t11FamFreeFcIds();
		my $fc_t11FamAssignedFcIds=$info->fc_t11FamAssignedFcIds();
		my $fc_t11FamAvailableFcIds=$info->fc_t11FamAvailableFcIds();
		my $fc_t11FamRunningPriority=$info->fc_t11FamRunningPriority();
		my $fc_t11FamPrincSwRunningPriority=$info->fc_t11FamPrincSwRunningPriority();
		my $fc_t11FamState=$info->fc_t11FamState();
		my $fc_t11FamLocalPrincipalSwitchSlctns=$info->fc_t11FamLocalPrincipalSwitchSlctns();
		my $fc_t11FamPrincipalSwitchSelections=$info->fc_t11FamPrincipalSwitchSelections();
		my $fc_t11FamBuildFabrics=$info->fc_t11FamBuildFabrics();
		my $fc_t11FamFabricReconfigures=$info->fc_t11FamFabricReconfigures();
		my $fc_t11FamDomainId=$info->fc_t11FamDomainId();
		my $fc_t11FamSticky=$info->fc_t11FamSticky();
		my $fc_t11FamRestart=$info->fc_t11FamRestart();
		my $fc_t11FamRcFabricNotifyEnable=$info->fc_t11FamRcFabricNotifyEnable();
		my $fc_t11FamEnable=$info->fc_t11FamEnable();
		my $fc_t11FamFabricName=$info->fc_t11FamFabricName();

##Collect information for tablet11zsattribtable
		my $fc_t11ZsAttribIndex=$info->fc_t11ZsAttribIndex();
		my $fc_t11ZsAttribType=$info->fc_t11ZsAttribType();
		my $fc_t11ZsAttribValue=$info->fc_t11ZsAttribValue();
		my $fc_t11ZsAttribRowStatus=$info->fc_t11ZsAttribRowStatus();

##Collect information for tablet11zsactivatetable
		my $fc_t11ZsActivateRequest=$info->fc_t11ZsActivateRequest();
		my $fc_t11ZsActivateDeactivate=$info->fc_t11ZsActivateDeactivate();
		my $fc_t11ZsActivateResult=$info->fc_t11ZsActivateResult();
		my $fc_t11ZsActivateFailCause=$info->fc_t11ZsActivateFailCause();
		my $fc_t11ZsActivateFailDomainId=$info->fc_t11ZsActivateFailDomainId();

##Collect information for tablet11famareatable
		my $fc_t11FamAreaAreaId=$info->fc_t11FamAreaAreaId();
		my $fc_t11FamAreaAssignedPortIdList=$info->fc_t11FamAreaAssignedPortIdList();

##Collect information for tablefcmfxporttable
		my $fc_fcmFxPortRatov=$info->fc_fcmFxPortRatov();
		my $fc_fcmFxPortEdtov=$info->fc_fcmFxPortEdtov();
		my $fc_fcmFxPortRttov=$info->fc_fcmFxPortRttov();
		my $fc_fcmFxPortHoldTime=$info->fc_fcmFxPortHoldTime();
		my $fc_fcmFxPortCapBbCreditMax=$info->fc_fcmFxPortCapBbCreditMax();
		my $fc_fcmFxPortCapBbCreditMin=$info->fc_fcmFxPortCapBbCreditMin();
		my $fc_fcmFxPortCapDataFieldSizeMax=$info->fc_fcmFxPortCapDataFieldSizeMax();
		my $fc_fcmFxPortCapDataFieldSizeMin=$info->fc_fcmFxPortCapDataFieldSizeMin();
		my $fc_fcmFxPortCapClass2SeqDeliv=$info->fc_fcmFxPortCapClass2SeqDeliv();
		my $fc_fcmFxPortCapClass3SeqDeliv=$info->fc_fcmFxPortCapClass3SeqDeliv();
		my $fc_fcmFxPortCapHoldTimeMax=$info->fc_fcmFxPortCapHoldTimeMax();
		my $fc_fcmFxPortCapHoldTimeMin=$info->fc_fcmFxPortCapHoldTimeMin();

##Collect information for tablet11fcsdiscoverystatetable
		my $fc_t11FcsFabricIndex=$info->fc_t11FcsFabricIndex();
		my $fc_t11FcsDiscoveryStatus=$info->fc_t11FcsDiscoveryStatus();
		my $fc_t11FcsDiscoveryCompleteTime=$info->fc_t11FcsDiscoveryCompleteTime();

##Collect information for tablet11famfcidcachetable
		my $fc_t11FamFcIdCacheWwn=$info->fc_t11FamFcIdCacheWwn();
		my $fc_t11FamFcIdCacheAreaIdPortId=$info->fc_t11FamFcIdCacheAreaIdPortId();
		my $fc_t11FamFcIdCachePortIds=$info->fc_t11FamFcIdCachePortIds();

##Collect information for tablefcfxlogintable
		my $fc_fcFxPortNxLoginIndex=$info->fc_fcFxPortNxLoginIndex();
		my $fc_fcFxPortNxPortName=$info->fc_fcFxPortNxPortName();
		my $fc_fcFxPortConnectedNxPort=$info->fc_fcFxPortConnectedNxPort();
		my $fc_fcFxPortBbCreditModel=$info->fc_fcFxPortBbCreditModel();
		my $fc_fcFxPortFcphVersionAgreed=$info->fc_fcFxPortFcphVersionAgreed();
		my $fc_fcFxPortNxPortBbCredit=$info->fc_fcFxPortNxPortBbCredit();
		my $fc_fcFxPortNxPortRxDataFieldSize=$info->fc_fcFxPortNxPortRxDataFieldSize();
		my $fc_fcFxPortCosSuppAgreed=$info->fc_fcFxPortCosSuppAgreed();
		my $fc_fcFxPortIntermixSuppAgreed=$info->fc_fcFxPortIntermixSuppAgreed();
		my $fc_fcFxPortStackedConnModeAgreed=$info->fc_fcFxPortStackedConnModeAgreed();
		my $fc_fcFxPortClass2SeqDelivAgreed=$info->fc_fcFxPortClass2SeqDelivAgreed();
		my $fc_fcFxPortClass3SeqDelivAgreed=$info->fc_fcFxPortClass3SeqDelivAgreed();

##Collect information for tablet11fcsmgmtaddrlisttable
		my $fc_t11FcsMgmtAddrListIndex=$info->fc_t11FcsMgmtAddrListIndex();
		my $fc_t11FcsMgmtAddrIndex=$info->fc_t11FcsMgmtAddrIndex();
		my $fc_t11FcsMgmtAddr=$info->fc_t11FcsMgmtAddr();

##Collect information for tablefcfxportc3accountingtable
		my $fc_fcFxPortC3InFrames=$info->fc_fcFxPortC3InFrames();
		my $fc_fcFxPortC3OutFrames=$info->fc_fcFxPortC3OutFrames();
		my $fc_fcFxPortC3InOctets=$info->fc_fcFxPortC3InOctets();
		my $fc_fcFxPortC3OutOctets=$info->fc_fcFxPortC3OutOctets();
		my $fc_fcFxPortC3Discards=$info->fc_fcFxPortC3Discards();

##Collect information for tablet11vflocallyenabledtable
		my $fc_t11vfLocallyEnabledPortIfIndex=$info->fc_t11vfLocallyEnabledPortIfIndex();
		my $fc_t11vfLocallyEnabledVfId=$info->fc_t11vfLocallyEnabledVfId();
		my $fc_t11vfLocallyEnabledOperStatus=$info->fc_t11vfLocallyEnabledOperStatus();
		my $fc_t11vfLocallyEnabledRowStatus=$info->fc_t11vfLocallyEnabledRowStatus();
		my $fc_t11vfLocallyEnabledStorageType=$info->fc_t11vfLocallyEnabledStorageType();

##Collect information for tablet11nsstatstable
		my $fc_t11NsInGetReqs=$info->fc_t11NsInGetReqs();
		my $fc_t11NsOutGetReqs=$info->fc_t11NsOutGetReqs();
		my $fc_t11NsInRegReqs=$info->fc_t11NsInRegReqs();
		my $fc_t11NsInDeRegReqs=$info->fc_t11NsInDeRegReqs();
		my $fc_t11NsInRscns=$info->fc_t11NsInRscns();
		my $fc_t11NsOutRscns=$info->fc_t11NsOutRscns();
		my $fc_t11NsRejects=$info->fc_t11NsRejects();
		my $fc_t11NsDatabaseFull=$info->fc_t11NsDatabaseFull();

##Collect information for tablet11fcsporttable
		my $fc_t11FcsPortName=$info->fc_t11FcsPortName();
		my $fc_t11FcsPortType=$info->fc_t11FcsPortType();
		my $fc_t11FcsPortTxType=$info->fc_t11FcsPortTxType();
		my $fc_t11FcsPortModuleType=$info->fc_t11FcsPortModuleType();
		my $fc_t11FcsPortPhyPortNum=$info->fc_t11FcsPortPhyPortNum();
		my $fc_t11FcsPortAttachPortNameIndex=$info->fc_t11FcsPortAttachPortNameIndex();
		my $fc_t11FcsPortState=$info->fc_t11FcsPortState();
		my $fc_t11FcsPortSpeedCapab=$info->fc_t11FcsPortSpeedCapab();
		my $fc_t11FcsPortOperSpeed=$info->fc_t11FcsPortOperSpeed();
		my $fc_t11FcsPortZoningEnfStatus=$info->fc_t11FcsPortZoningEnfStatus();

##Collect information for tablefcminstancetable
		my $fc_fcmInstanceIndex=$info->fc_fcmInstanceIndex();
		my $fc_fcmInstanceWwn=$info->fc_fcmInstanceWwn();
		my $fc_fcmInstanceFunctions=$info->fc_fcmInstanceFunctions();
		my $fc_fcmInstancePhysicalIndex=$info->fc_fcmInstancePhysicalIndex();
		my $fc_fcmInstanceSoftwareIndex=$info->fc_fcmInstanceSoftwareIndex();
		my $fc_fcmInstanceStatus=$info->fc_fcmInstanceStatus();
		my $fc_fcmInstanceTextName=$info->fc_fcmInstanceTextName();
		my $fc_fcmInstanceDescr=$info->fc_fcmInstanceDescr();
		my $fc_fcmInstanceFabricId=$info->fc_fcmInstanceFabricId();

##Collect information for tablet11zsactivezonemembertable
		my $fc_t11ZsActiveZoneMemberIndex=$info->fc_t11ZsActiveZoneMemberIndex();
		my $fc_t11ZsActiveZoneMemberFormat=$info->fc_t11ZsActiveZoneMemberFormat();
		my $fc_t11ZsActiveZoneMemberID=$info->fc_t11ZsActiveZoneMemberID();

##Collect information for tablet11fcsattachportnamelisttable
		my $fc_t11FcsAttachPortNameListIndex=$info->fc_t11FcsAttachPortNameListIndex();
		my $fc_t11FcsAttachPortName=$info->fc_t11FcsAttachPortName();

##Collect information for tablefcmportlcstatstable
		my $fc_fcmPortLcBBCreditZeros=$info->fc_fcmPortLcBBCreditZeros();
		my $fc_fcmPortLcFullInputBuffers=$info->fc_fcmPortLcFullInputBuffers();
		my $fc_fcmPortLcClass2RxFrames=$info->fc_fcmPortLcClass2RxFrames();
		my $fc_fcmPortLcClass2RxOctets=$info->fc_fcmPortLcClass2RxOctets();
		my $fc_fcmPortLcClass2TxFrames=$info->fc_fcmPortLcClass2TxFrames();
		my $fc_fcmPortLcClass2TxOctets=$info->fc_fcmPortLcClass2TxOctets();
		my $fc_fcmPortLcClass2Discards=$info->fc_fcmPortLcClass2Discards();
		my $fc_fcmPortLcClass2RxFbsyFrames=$info->fc_fcmPortLcClass2RxFbsyFrames();
		my $fc_fcmPortLcClass2RxPbsyFrames=$info->fc_fcmPortLcClass2RxPbsyFrames();
		my $fc_fcmPortLcClass2RxFrjtFrames=$info->fc_fcmPortLcClass2RxFrjtFrames();
		my $fc_fcmPortLcClass2RxPrjtFrames=$info->fc_fcmPortLcClass2RxPrjtFrames();
		my $fc_fcmPortLcClass2TxFbsyFrames=$info->fc_fcmPortLcClass2TxFbsyFrames();
		my $fc_fcmPortLcClass2TxPbsyFrames=$info->fc_fcmPortLcClass2TxPbsyFrames();
		my $fc_fcmPortLcClass2TxFrjtFrames=$info->fc_fcmPortLcClass2TxFrjtFrames();
		my $fc_fcmPortLcClass2TxPrjtFrames=$info->fc_fcmPortLcClass2TxPrjtFrames();
		my $fc_fcmPortLcClass3RxFrames=$info->fc_fcmPortLcClass3RxFrames();
		my $fc_fcmPortLcClass3RxOctets=$info->fc_fcmPortLcClass3RxOctets();
		my $fc_fcmPortLcClass3TxFrames=$info->fc_fcmPortLcClass3TxFrames();
		my $fc_fcmPortLcClass3TxOctets=$info->fc_fcmPortLcClass3TxOctets();
		my $fc_fcmPortLcClass3Discards=$info->fc_fcmPortLcClass3Discards();

##Collect information for tablefcmflogintable
		my $fc_fcmFLoginNxPortIndex=$info->fc_fcmFLoginNxPortIndex();
		my $fc_fcmFLoginPortWwn=$info->fc_fcmFLoginPortWwn();
		my $fc_fcmFLoginNodeWwn=$info->fc_fcmFLoginNodeWwn();
		my $fc_fcmFLoginBbCreditModel=$info->fc_fcmFLoginBbCreditModel();
		my $fc_fcmFLoginBbCredit=$info->fc_fcmFLoginBbCredit();
		my $fc_fcmFLoginClassesAgreed=$info->fc_fcmFLoginClassesAgreed();
		my $fc_fcmFLoginClass2SeqDelivAgreed=$info->fc_fcmFLoginClass2SeqDelivAgreed();
		my $fc_fcmFLoginClass2DataFieldSize=$info->fc_fcmFLoginClass2DataFieldSize();
		my $fc_fcmFLoginClass3SeqDelivAgreed=$info->fc_fcmFLoginClass3SeqDelivAgreed();
		my $fc_fcmFLoginClass3DataFieldSize=$info->fc_fcmFLoginClass3DataFieldSize();

##Collect information for tablet11fspflsrtable
		my $fc_t11FspfLsrDomainId=$info->fc_t11FspfLsrDomainId();
		my $fc_t11FspfLsrType=$info->fc_t11FspfLsrType();
		my $fc_t11FspfLsrAdvDomainId=$info->fc_t11FspfLsrAdvDomainId();
		my $fc_t11FspfLsrAge=$info->fc_t11FspfLsrAge();
		my $fc_t11FspfLsrIncarnationNumber=$info->fc_t11FspfLsrIncarnationNumber();
		my $fc_t11FspfLsrCheckSum=$info->fc_t11FspfLsrCheckSum();
		my $fc_t11FspfLsrLinks=$info->fc_t11FspfLsrLinks();

##Collect information for tablefcfemoduletable
		my $fc_fcFeModuleIndex=$info->fc_fcFeModuleIndex();
		my $fc_fcFeModuleDescr=$info->fc_fcFeModuleDescr();
		my $fc_fcFeModuleObjectID=$info->fc_fcFeModuleObjectID();
		my $fc_fcFeModuleOperStatus=$info->fc_fcFeModuleOperStatus();
		my $fc_fcFeModuleLastChange=$info->fc_fcFeModuleLastChange();
		my $fc_fcFeModuleFxPortCapacity=$info->fc_fcFeModuleFxPortCapacity();
		my $fc_fcFeModuleName=$info->fc_fcFeModuleName();

##Collect information for tablet11zsnotifycontroltable
		my $fc_t11ZsNotifyRequestRejectEnable=$info->fc_t11ZsNotifyRequestRejectEnable();
		my $fc_t11ZsNotifyMergeFailureEnable=$info->fc_t11ZsNotifyMergeFailureEnable();
		my $fc_t11ZsNotifyMergeSuccessEnable=$info->fc_t11ZsNotifyMergeSuccessEnable();
		my $fc_t11ZsNotifyDefZoneChangeEnable=$info->fc_t11ZsNotifyDefZoneChangeEnable();
		my $fc_t11ZsNotifyActivateEnable=$info->fc_t11ZsNotifyActivateEnable();
		my $fc_t11ZsRejectCtCommandString=$info->fc_t11ZsRejectCtCommandString();
		my $fc_t11ZsRejectRequestSource=$info->fc_t11ZsRejectRequestSource();
		my $fc_t11ZsRejectReasonCode=$info->fc_t11ZsRejectReasonCode();
		my $fc_t11ZsRejectReasonCodeExp=$info->fc_t11ZsRejectReasonCodeExp();
		my $fc_t11ZsRejectReasonVendorCode=$info->fc_t11ZsRejectReasonVendorCode();

##Collect information for tablefcmisporttable
		my $fc_fcmISPortClassFCredit=$info->fc_fcmISPortClassFCredit();
		my $fc_fcmISPortClassFDataFieldSize=$info->fc_fcmISPortClassFDataFieldSize();

##Collect information for tablet11zszonemembertable
		my $fc_t11ZsZoneMemberParentType=$info->fc_t11ZsZoneMemberParentType();
		my $fc_t11ZsZoneMemberParentIndex=$info->fc_t11ZsZoneMemberParentIndex();
		my $fc_t11ZsZoneMemberIndex=$info->fc_t11ZsZoneMemberIndex();
		my $fc_t11ZsZoneMemberFormat=$info->fc_t11ZsZoneMemberFormat();
		my $fc_t11ZsZoneMemberID=$info->fc_t11ZsZoneMemberID();
		my $fc_t11ZsZoneMemberRowStatus=$info->fc_t11ZsZoneMemberRowStatus();

##Collect information for tablefcfxportcaptable
		my $fc_fcFxPortCapFcphVersionHigh=$info->fc_fcFxPortCapFcphVersionHigh();
		my $fc_fcFxPortCapClass2SeqDeliv=$info->fc_fcFxPortCapClass2SeqDeliv();
		my $fc_fcFxPortCapClass3SeqDeliv=$info->fc_fcFxPortCapClass3SeqDeliv();
		my $fc_fcFxPortCapHoldTimeMax=$info->fc_fcFxPortCapHoldTimeMax();
		my $fc_fcFxPortCapHoldTimeMin=$info->fc_fcFxPortCapHoldTimeMin();
		my $fc_fcFxPortCapFcphVersionLow=$info->fc_fcFxPortCapFcphVersionLow();
		my $fc_fcFxPortCapBbCreditMax=$info->fc_fcFxPortCapBbCreditMax();
		my $fc_fcFxPortCapBbCreditMin=$info->fc_fcFxPortCapBbCreditMin();
		my $fc_fcFxPortCapRxDataFieldSizeMax=$info->fc_fcFxPortCapRxDataFieldSizeMax();
		my $fc_fcFxPortCapRxDataFieldSizeMin=$info->fc_fcFxPortCapRxDataFieldSizeMin();
		my $fc_fcFxPortCapCos=$info->fc_fcFxPortCapCos();
		my $fc_fcFxPortCapIntermix=$info->fc_fcFxPortCapIntermix();
		my $fc_fcFxPortCapStackedConnMode=$info->fc_fcFxPortCapStackedConnMode();

##Collect information for tablet11fcsnotifycontroltable
		my $fc_t11FcsReqRejectNotifyEnable=$info->fc_t11FcsReqRejectNotifyEnable();
		my $fc_t11FcsDiscoveryCompNotifyEnable=$info->fc_t11FcsDiscoveryCompNotifyEnable();
		my $fc_t11FcsMgmtAddrChangeNotifyEnable=$info->fc_t11FcsMgmtAddrChangeNotifyEnable();
		my $fc_t11FcsRejectCtCommandString=$info->fc_t11FcsRejectCtCommandString();
		my $fc_t11FcsRejectRequestSource=$info->fc_t11FcsRejectRequestSource();
		my $fc_t11FcsRejectReasonCode=$info->fc_t11FcsRejectReasonCode();
		my $fc_t11FcsRejectReasonCodeExp=$info->fc_t11FcsRejectReasonCodeExp();
		my $fc_t11FcsRejectReasonVendorCode=$info->fc_t11FcsRejectReasonVendorCode();

##Collect information for tablefcmporttable
		my $fc_fcmPortInstanceIndex=$info->fc_fcmPortInstanceIndex();
		my $fc_fcmPortWwn=$info->fc_fcmPortWwn();
		my $fc_fcmPortNodeWwn=$info->fc_fcmPortNodeWwn();
		my $fc_fcmPortAdminType=$info->fc_fcmPortAdminType();
		my $fc_fcmPortOperType=$info->fc_fcmPortOperType();
		my $fc_fcmPortFcCapClass=$info->fc_fcmPortFcCapClass();
		my $fc_fcmPortFcOperClass=$info->fc_fcmPortFcOperClass();
		my $fc_fcmPortTransmitterType=$info->fc_fcmPortTransmitterType();
		my $fc_fcmPortConnectorType=$info->fc_fcmPortConnectorType();
		my $fc_fcmPortSerialNumber=$info->fc_fcmPortSerialNumber();
		my $fc_fcmPortPhysicalNumber=$info->fc_fcmPortPhysicalNumber();
		my $fc_fcmPortAdminSpeed=$info->fc_fcmPortAdminSpeed();
		my $fc_fcmPortCapProtocols=$info->fc_fcmPortCapProtocols();
		my $fc_fcmPortOperProtocols=$info->fc_fcmPortOperProtocols();

##Collect information for tablet11fcroutefabrictable
		my $fc_t11FcRouteFabricIndex=$info->fc_t11FcRouteFabricIndex();
		my $fc_t11FcRouteFabricLastChange=$info->fc_t11FcRouteFabricLastChange();

		foreach my $putinv (keys %$fc_t11NsRegFc4Features) {
			my $fc_t11NsRegFabricIndex_1=$fc_t11NsRegFabricIndex->{$putinv};
			my $fc_t11NsRegPortIdentifier_1=$fc_t11NsRegPortIdentifier->{$putinv};
			my $fc_t11NsRegPortName_1=$fc_t11NsRegPortName->{$putinv};
			my $fc_t11NsRegNodeName_1=$fc_t11NsRegNodeName->{$putinv};
			my $fc_t11NsRegClassOfSvc_1=$fc_t11NsRegClassOfSvc->{$putinv};
			my $fc_t11NsRegNodeIpAddress_1=$fc_t11NsRegNodeIpAddress->{$putinv};
			my $fc_t11NsRegProcAssoc_1=$fc_t11NsRegProcAssoc->{$putinv};
			my $fc_t11NsRegFc4Type_1=$fc_t11NsRegFc4Type->{$putinv};
			my $fc_t11NsRegPortType_1=$fc_t11NsRegPortType->{$putinv};
			my $fc_t11NsRegPortIpAddress_1=$fc_t11NsRegPortIpAddress->{$putinv};
			my $fc_t11NsRegFabricPortName_1=$fc_t11NsRegFabricPortName->{$putinv};
			my $fc_t11NsRegHardAddress_1=$fc_t11NsRegHardAddress->{$putinv};
			my $fc_t11NsRegSymbolicPortName_1=$fc_t11NsRegSymbolicPortName->{$putinv};
			my $fc_t11NsRegSymbolicNodeName_1=$fc_t11NsRegSymbolicNodeName->{$putinv};
			my $fc_t11NsRegFc4Features_1=$fc_t11NsRegFc4Features->{$putinv};
			$t11nsregtable_sth->execute($deviceid,$scantime,$fc_t11NsRegFabricIndex_1,$fc_t11NsRegPortIdentifier_1,$fc_t11NsRegPortName_1,$fc_t11NsRegNodeName_1,$fc_t11NsRegClassOfSvc_1,$fc_t11NsRegNodeIpAddress_1,$fc_t11NsRegProcAssoc_1,$fc_t11NsRegFc4Type_1,$fc_t11NsRegPortType_1,$fc_t11NsRegPortIpAddress_1,$fc_t11NsRegFabricPortName_1,$fc_t11NsRegHardAddress_1,$fc_t11NsRegSymbolicPortName_1,$fc_t11NsRegSymbolicNodeName_1,$fc_t11NsRegFc4Features_1,$putinv);
		}

		foreach my $putinv (keys %$fc_t11ZsOutZsRejects) {
			my $fc_t11ZsOutMergeRequests_1=$fc_t11ZsOutMergeRequests->{$putinv};
			my $fc_t11ZsInMergeAccepts_1=$fc_t11ZsInMergeAccepts->{$putinv};
			my $fc_t11ZsInMergeRequests_1=$fc_t11ZsInMergeRequests->{$putinv};
			my $fc_t11ZsOutMergeAccepts_1=$fc_t11ZsOutMergeAccepts->{$putinv};
			my $fc_t11ZsOutChangeRequests_1=$fc_t11ZsOutChangeRequests->{$putinv};
			my $fc_t11ZsInChangeAccepts_1=$fc_t11ZsInChangeAccepts->{$putinv};
			my $fc_t11ZsInChangeRequests_1=$fc_t11ZsInChangeRequests->{$putinv};
			my $fc_t11ZsOutChangeAccepts_1=$fc_t11ZsOutChangeAccepts->{$putinv};
			my $fc_t11ZsInZsRequests_1=$fc_t11ZsInZsRequests->{$putinv};
			my $fc_t11ZsOutZsRejects_1=$fc_t11ZsOutZsRejects->{$putinv};
			$t11zsstatstable_sth->execute($deviceid,$scantime,$fc_t11ZsOutMergeRequests_1,$fc_t11ZsInMergeAccepts_1,$fc_t11ZsInMergeRequests_1,$fc_t11ZsOutMergeAccepts_1,$fc_t11ZsOutChangeRequests_1,$fc_t11ZsInChangeAccepts_1,$fc_t11ZsInChangeRequests_1,$fc_t11ZsOutChangeAccepts_1,$fc_t11ZsInZsRequests_1,$fc_t11ZsOutZsRejects_1,$putinv);
		}

		foreach my $putinv (keys %$fc_t11FspfLinkCost){
			my $fc_t11FspfLinkIndex_1=$fc_t11FspfLinkIndex->{$putinv};
			my $fc_t11FspfLinkNbrDomainId_1=$fc_t11FspfLinkNbrDomainId->{$putinv};
			my $fc_t11FspfLinkPortIndex_1=$fc_t11FspfLinkPortIndex->{$putinv};
			my $fc_t11FspfLinkNbrPortIndex_1=$fc_t11FspfLinkNbrPortIndex->{$putinv};
			my $fc_t11FspfLinkType_1=$fc_t11FspfLinkType->{$putinv};
			my $fc_t11FspfLinkCost_1=$fc_t11FspfLinkCost->{$putinv};
			$t11fspflinktable_sth->execute($deviceid,$scantime,$fc_t11FspfLinkIndex_1,$fc_t11FspfLinkNbrDomainId_1,$fc_t11FspfLinkPortIndex_1,$fc_t11FspfLinkNbrPortIndex_1,$fc_t11FspfLinkType_1,$fc_t11FspfLinkCost_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortCosSupported){
			my $fc_fcFxPortIndex_1=$fc_fcFxPortIndex->{$putinv};
			my $fc_fcFxPortIntermixSupported_1=$fc_fcFxPortIntermixSupported->{$putinv};
			my $fc_fcFxPortStackedConnMode_1=$fc_fcFxPortStackedConnMode->{$putinv};
			my $fc_fcFxPortClass2SeqDeliv_1=$fc_fcFxPortClass2SeqDeliv->{$putinv};
			my $fc_fcFxPortClass3SeqDeliv_1=$fc_fcFxPortClass3SeqDeliv->{$putinv};
			my $fc_fcFxPortHoldTime_1=$fc_fcFxPortHoldTime->{$putinv};
			my $fc_fcFxPortName_1=$fc_fcFxPortName->{$putinv};
			my $fc_fcFxPortFcphVersionHigh_1=$fc_fcFxPortFcphVersionHigh->{$putinv};
			my $fc_fcFxPortFcphVersionLow_1=$fc_fcFxPortFcphVersionLow->{$putinv};
			my $fc_fcFxPortBbCredit_1=$fc_fcFxPortBbCredit->{$putinv};
			my $fc_fcFxPortRxBufSize_1=$fc_fcFxPortRxBufSize->{$putinv};
			my $fc_fcFxPortRatov_1=$fc_fcFxPortRatov->{$putinv};
			my $fc_fcFxPortEdtov_1=$fc_fcFxPortEdtov->{$putinv};
			my $fc_fcFxPortCosSupported_1=$fc_fcFxPortCosSupported->{$putinv};
			$fcfxporttable_sth->execute($deviceid,$scantime,$fc_fcFxPortIndex_1,$fc_fcFxPortIntermixSupported_1,$fc_fcFxPortStackedConnMode_1,$fc_fcFxPortClass2SeqDeliv_1,$fc_fcFxPortClass3SeqDeliv_1,$fc_fcFxPortHoldTime_1,$fc_fcFxPortName_1,$fc_fcFxPortFcphVersionHigh_1,$fc_fcFxPortFcphVersionLow_1,$fc_fcFxPortBbCredit_1,$fc_fcFxPortRxBufSize_1,$fc_fcFxPortRatov_1,$fc_fcFxPortEdtov_1,$fc_fcFxPortCosSupported_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FspfStorageType){
			my $fc_t11FspfFabricIndex_1=$fc_t11FspfFabricIndex->{$putinv};
			my $fc_t11FspfMinLsArrival_1=$fc_t11FspfMinLsArrival->{$putinv};
			my $fc_t11FspfMinLsInterval_1=$fc_t11FspfMinLsInterval->{$putinv};
			my $fc_t11FspfLsRefreshTime_1=$fc_t11FspfLsRefreshTime->{$putinv};
			my $fc_t11FspfMaxAge_1=$fc_t11FspfMaxAge->{$putinv};
			my $fc_t11FspfMaxAgeDiscards_1=$fc_t11FspfMaxAgeDiscards->{$putinv};
			my $fc_t11FspfPathComputations_1=$fc_t11FspfPathComputations->{$putinv};
			my $fc_t11FspfChecksumErrors_1=$fc_t11FspfChecksumErrors->{$putinv};
			my $fc_t11FspfLsrs_1=$fc_t11FspfLsrs->{$putinv};
			my $fc_t11FspfCreateTime_1=$fc_t11FspfCreateTime->{$putinv};
			my $fc_t11FspfAdminStatus_1=$fc_t11FspfAdminStatus->{$putinv};
			my $fc_t11FspfOperStatus_1=$fc_t11FspfOperStatus->{$putinv};
			my $fc_t11FspfNbrStateChangNotifyEnable_1=$fc_t11FspfNbrStateChangNotifyEnable->{$putinv};
			my $fc_t11FspfSetToDefault_1=$fc_t11FspfSetToDefault->{$putinv};
			my $fc_t11FspfStorageType_1=$fc_t11FspfStorageType->{$putinv};
			$t11fspftable_sth->execute($deviceid,$scantime,$fc_t11FspfFabricIndex_1,$fc_t11FspfMinLsArrival_1,$fc_t11FspfMinLsInterval_1,$fc_t11FspfLsRefreshTime_1,$fc_t11FspfMaxAge_1,$fc_t11FspfMaxAgeDiscards_1,$fc_t11FspfPathComputations_1,$fc_t11FspfChecksumErrors_1,$fc_t11FspfLsrs_1,$fc_t11FspfCreateTime_1,$fc_t11FspfAdminStatus_1,$fc_t11FspfOperStatus_1,$fc_t11FspfNbrStateChangNotifyEnable_1,$fc_t11FspfSetToDefault_1,$fc_t11FspfStorageType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsActiveActivateTime){
			my $fc_t11ZsActiveZoneSetName_1=$fc_t11ZsActiveZoneSetName->{$putinv};
			my $fc_t11ZsActiveActivateTime_1=$fc_t11ZsActiveActivateTime->{$putinv};
			$t11zsactivetable_sth->execute($deviceid,$scantime,$fc_t11ZsActiveZoneSetName_1,$fc_t11ZsActiveActivateTime_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortC2FrjtFrames){
			my $fc_fcFxPortC2InFrames_1=$fc_fcFxPortC2InFrames->{$putinv};
			my $fc_fcFxPortC2OutFrames_1=$fc_fcFxPortC2OutFrames->{$putinv};
			my $fc_fcFxPortC2InOctets_1=$fc_fcFxPortC2InOctets->{$putinv};
			my $fc_fcFxPortC2OutOctets_1=$fc_fcFxPortC2OutOctets->{$putinv};
			my $fc_fcFxPortC2Discards_1=$fc_fcFxPortC2Discards->{$putinv};
			my $fc_fcFxPortC2FbsyFrames_1=$fc_fcFxPortC2FbsyFrames->{$putinv};
			my $fc_fcFxPortC2FrjtFrames_1=$fc_fcFxPortC2FrjtFrames->{$putinv};
			$fcfxportc2accountingtable_sth->execute($deviceid,$scantime,$fc_fcFxPortC2InFrames_1,$fc_fcFxPortC2OutFrames_1,$fc_fcFxPortC2InOctets_1,$fc_fcFxPortC2OutOctets_1,$fc_fcFxPortC2Discards_1,$fc_fcFxPortC2FbsyFrames_1,$fc_fcFxPortC2FrjtFrames_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsNodeName){
			my $fc_t11FcsNodeNameListIndex_1=$fc_t11FcsNodeNameListIndex->{$putinv};
			my $fc_t11FcsNodeName_1=$fc_t11FcsNodeName->{$putinv};
			$t11fcsnodenamelisttable_sth->execute($deviceid,$scantime,$fc_t11FcsNodeNameListIndex_1,$fc_t11FcsNodeName_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcRouteRowStatus){
			my $fc_t11FcRouteDestAddrId_1=$fc_t11FcRouteDestAddrId->{$putinv};
			my $fc_t11FcRouteDestMask_1=$fc_t11FcRouteDestMask->{$putinv};
			my $fc_t11FcRouteSrcAddrId_1=$fc_t11FcRouteSrcAddrId->{$putinv};
			my $fc_t11FcRouteSrcMask_1=$fc_t11FcRouteSrcMask->{$putinv};
			my $fc_t11FcRouteInInterface_1=$fc_t11FcRouteInInterface->{$putinv};
			my $fc_t11FcRouteProto_1=$fc_t11FcRouteProto->{$putinv};
			my $fc_t11FcRouteOutInterface_1=$fc_t11FcRouteOutInterface->{$putinv};
			my $fc_t11FcRouteDomainId_1=$fc_t11FcRouteDomainId->{$putinv};
			my $fc_t11FcRouteMetric_1=$fc_t11FcRouteMetric->{$putinv};
			my $fc_t11FcRouteType_1=$fc_t11FcRouteType->{$putinv};
			my $fc_t11FcRouteIfDown_1=$fc_t11FcRouteIfDown->{$putinv};
			my $fc_t11FcRouteStorageType_1=$fc_t11FcRouteStorageType->{$putinv};
			my $fc_t11FcRouteRowStatus_1=$fc_t11FcRouteRowStatus->{$putinv};
			$t11fcroutetable_sth->execute($deviceid,$scantime,$fc_t11FcRouteDestAddrId_1,$fc_t11FcRouteDestMask_1,$fc_t11FcRouteSrcAddrId_1,$fc_t11FcRouteSrcMask_1,$fc_t11FcRouteInInterface_1,$fc_t11FcRouteProto_1,$fc_t11FcRouteOutInterface_1,$fc_t11FcRouteDomainId_1,$fc_t11FcRouteMetric_1,$fc_t11FcRouteType_1,$fc_t11FcRouteIfDown_1,$fc_t11FcRouteStorageType_1,$fc_t11FcRouteRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmSwitchWWN){
			my $fc_fcmSwitchIndex_1=$fc_fcmSwitchIndex->{$putinv};
			my $fc_fcmSwitchDomainId_1=$fc_fcmSwitchDomainId->{$putinv};
			my $fc_fcmSwitchPrincipal_1=$fc_fcmSwitchPrincipal->{$putinv};
			my $fc_fcmSwitchWWN_1=$fc_fcmSwitchWWN->{$putinv};
			$fcmswitchtable_sth->execute($deviceid,$scantime,$fc_fcmSwitchIndex_1,$fc_fcmSwitchDomainId_1,$fc_fcmSwitchPrincipal_1,$fc_fcmSwitchWWN_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmPortClassFDiscards){
			my $fc_fcmPortBBCreditZeros_1=$fc_fcmPortBBCreditZeros->{$putinv};
			my $fc_fcmPortFullInputBuffers_1=$fc_fcmPortFullInputBuffers->{$putinv};
			my $fc_fcmPortClass2RxFrames_1=$fc_fcmPortClass2RxFrames->{$putinv};
			my $fc_fcmPortClass2RxOctets_1=$fc_fcmPortClass2RxOctets->{$putinv};
			my $fc_fcmPortClass2TxFrames_1=$fc_fcmPortClass2TxFrames->{$putinv};
			my $fc_fcmPortClass2TxOctets_1=$fc_fcmPortClass2TxOctets->{$putinv};
			my $fc_fcmPortClass2Discards_1=$fc_fcmPortClass2Discards->{$putinv};
			my $fc_fcmPortClass2RxFbsyFrames_1=$fc_fcmPortClass2RxFbsyFrames->{$putinv};
			my $fc_fcmPortClass2RxPbsyFrames_1=$fc_fcmPortClass2RxPbsyFrames->{$putinv};
			my $fc_fcmPortClass2RxFrjtFrames_1=$fc_fcmPortClass2RxFrjtFrames->{$putinv};
			my $fc_fcmPortClass2RxPrjtFrames_1=$fc_fcmPortClass2RxPrjtFrames->{$putinv};
			my $fc_fcmPortClass2TxFbsyFrames_1=$fc_fcmPortClass2TxFbsyFrames->{$putinv};
			my $fc_fcmPortClass2TxPbsyFrames_1=$fc_fcmPortClass2TxPbsyFrames->{$putinv};
			my $fc_fcmPortClass2TxFrjtFrames_1=$fc_fcmPortClass2TxFrjtFrames->{$putinv};
			my $fc_fcmPortClass2TxPrjtFrames_1=$fc_fcmPortClass2TxPrjtFrames->{$putinv};
			my $fc_fcmPortClass3RxFrames_1=$fc_fcmPortClass3RxFrames->{$putinv};
			my $fc_fcmPortClass3RxOctets_1=$fc_fcmPortClass3RxOctets->{$putinv};
			my $fc_fcmPortClass3TxFrames_1=$fc_fcmPortClass3TxFrames->{$putinv};
			my $fc_fcmPortClass3TxOctets_1=$fc_fcmPortClass3TxOctets->{$putinv};
			my $fc_fcmPortClass3Discards_1=$fc_fcmPortClass3Discards->{$putinv};
			my $fc_fcmPortClassFRxFrames_1=$fc_fcmPortClassFRxFrames->{$putinv};
			my $fc_fcmPortClassFRxOctets_1=$fc_fcmPortClassFRxOctets->{$putinv};
			my $fc_fcmPortClassFTxFrames_1=$fc_fcmPortClassFTxFrames->{$putinv};
			my $fc_fcmPortClassFTxOctets_1=$fc_fcmPortClassFTxOctets->{$putinv};
			my $fc_fcmPortClassFDiscards_1=$fc_fcmPortClassFDiscards->{$putinv};
			$fcmportstatstable_sth->execute($deviceid,$scantime,$fc_fcmPortBBCreditZeros_1,$fc_fcmPortFullInputBuffers_1,$fc_fcmPortClass2RxFrames_1,$fc_fcmPortClass2RxOctets_1,$fc_fcmPortClass2TxFrames_1,$fc_fcmPortClass2TxOctets_1,$fc_fcmPortClass2Discards_1,$fc_fcmPortClass2RxFbsyFrames_1,$fc_fcmPortClass2RxPbsyFrames_1,$fc_fcmPortClass2RxFrjtFrames_1,$fc_fcmPortClass2RxPrjtFrames_1,$fc_fcmPortClass2TxFbsyFrames_1,$fc_fcmPortClass2TxPbsyFrames_1,$fc_fcmPortClass2TxFrjtFrames_1,$fc_fcmPortClass2TxPrjtFrames_1,$fc_fcmPortClass3RxFrames_1,$fc_fcmPortClass3RxOctets_1,$fc_fcmPortClass3TxFrames_1,$fc_fcmPortClass3TxOctets_1,$fc_fcmPortClass3Discards_1,$fc_fcmPortClassFRxFrames_1,$fc_fcmPortClassFRxOctets_1,$fc_fcmPortClassFTxFrames_1,$fc_fcmPortClassFTxOctets_1,$fc_fcmPortClassFDiscards_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11vfPortStorageType){
			my $fc_t11vfPortVfId_1=$fc_t11vfPortVfId->{$putinv};
			my $fc_t11vfPortTaggingAdminStatus_1=$fc_t11vfPortTaggingAdminStatus->{$putinv};
			my $fc_t11vfPortTaggingOperStatus_1=$fc_t11vfPortTaggingOperStatus->{$putinv};
			my $fc_t11vfPortStorageType_1=$fc_t11vfPortStorageType->{$putinv};
			$t11vfporttable_sth->execute($deviceid,$scantime,$fc_t11vfPortVfId_1,$fc_t11vfPortTaggingAdminStatus_1,$fc_t11vfPortTaggingOperStatus_1,$fc_t11vfPortStorageType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsSetRowStatus){
			my $fc_t11ZsSetIndex_1=$fc_t11ZsSetIndex->{$putinv};
			my $fc_t11ZsSetName_1=$fc_t11ZsSetName->{$putinv};
			my $fc_t11ZsSetRowStatus_1=$fc_t11ZsSetRowStatus->{$putinv};
			$t11zssettable_sth->execute($deviceid,$scantime,$fc_t11ZsSetIndex_1,$fc_t11ZsSetName_1,$fc_t11ZsSetRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsActiveZoneHardZoning){
			my $fc_t11ZsActiveZoneIndex_1=$fc_t11ZsActiveZoneIndex->{$putinv};
			my $fc_t11ZsActiveZoneName_1=$fc_t11ZsActiveZoneName->{$putinv};
			my $fc_t11ZsActiveZoneBroadcastZoning_1=$fc_t11ZsActiveZoneBroadcastZoning->{$putinv};
			my $fc_t11ZsActiveZoneHardZoning_1=$fc_t11ZsActiveZoneHardZoning->{$putinv};
			$t11zsactivezonetable_sth->execute($deviceid,$scantime,$fc_t11ZsActiveZoneIndex_1,$fc_t11ZsActiveZoneName_1,$fc_t11ZsActiveZoneBroadcastZoning_1,$fc_t11ZsActiveZoneHardZoning_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmLinkEnd2FcAddressId){
			my $fc_fcmLinkIndex_1=$fc_fcmLinkIndex->{$putinv};
			my $fc_fcmLinkEnd1NodeWwn_1=$fc_fcmLinkEnd1NodeWwn->{$putinv};
			my $fc_fcmLinkEnd1PhysPortNumber_1=$fc_fcmLinkEnd1PhysPortNumber->{$putinv};
			my $fc_fcmLinkEnd1PortWwn_1=$fc_fcmLinkEnd1PortWwn->{$putinv};
			my $fc_fcmLinkEnd2NodeWwn_1=$fc_fcmLinkEnd2NodeWwn->{$putinv};
			my $fc_fcmLinkEnd2PhysPortNumber_1=$fc_fcmLinkEnd2PhysPortNumber->{$putinv};
			my $fc_fcmLinkEnd2PortWwn_1=$fc_fcmLinkEnd2PortWwn->{$putinv};
			my $fc_fcmLinkEnd2AgentAddress_1=$fc_fcmLinkEnd2AgentAddress->{$putinv};
			my $fc_fcmLinkEnd2PortType_1=$fc_fcmLinkEnd2PortType->{$putinv};
			my $fc_fcmLinkEnd2UnitType_1=$fc_fcmLinkEnd2UnitType->{$putinv};
			my $fc_fcmLinkEnd2FcAddressId_1=$fc_fcmLinkEnd2FcAddressId->{$putinv};
			$fcmlinktable_sth->execute($deviceid,$scantime,$fc_fcmLinkIndex_1,$fc_fcmLinkEnd1NodeWwn_1,$fc_fcmLinkEnd1PhysPortNumber_1,$fc_fcmLinkEnd1PortWwn_1,$fc_fcmLinkEnd2NodeWwn_1,$fc_fcmLinkEnd2PhysPortNumber_1,$fc_fcmLinkEnd2PortWwn_1,$fc_fcmLinkEnd2AgentAddress_1,$fc_fcmLinkEnd2PortType_1,$fc_fcmLinkEnd2UnitType_1,$fc_fcmLinkEnd2FcAddressId_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsFabricDiscoveryTimeOut){
			my $fc_t11FcsFabricDiscoveryRangeLow_1=$fc_t11FcsFabricDiscoveryRangeLow->{$putinv};
			my $fc_t11FcsFabricDiscoveryRangeHigh_1=$fc_t11FcsFabricDiscoveryRangeHigh->{$putinv};
			my $fc_t11FcsFabricDiscoveryStart_1=$fc_t11FcsFabricDiscoveryStart->{$putinv};
			my $fc_t11FcsFabricDiscoveryTimeOut_1=$fc_t11FcsFabricDiscoveryTimeOut->{$putinv};
			$t11fcsfabricdiscoverytable_sth->execute($deviceid,$scantime,$fc_t11FcsFabricDiscoveryRangeLow_1,$fc_t11FcsFabricDiscoveryRangeHigh_1,$fc_t11FcsFabricDiscoveryStart_1,$fc_t11FcsFabricDiscoveryTimeOut_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsSetZoneRowStatus){
			my $fc_t11ZsSetZoneRowStatus_1=$fc_t11ZsSetZoneRowStatus->{$putinv};
			$t11zssetzonetable_sth->execute($deviceid,$scantime,$fc_t11ZsSetZoneRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcRscnRejectReasonVendorCode){
			my $fc_t11FcRscnIlsRejectNotifyEnable_1=$fc_t11FcRscnIlsRejectNotifyEnable->{$putinv};
			my $fc_t11FcRscnElsRejectNotifyEnable_1=$fc_t11FcRscnElsRejectNotifyEnable->{$putinv};
			my $fc_t11FcRscnRejectedRequestString_1=$fc_t11FcRscnRejectedRequestString->{$putinv};
			my $fc_t11FcRscnRejectedRequestSource_1=$fc_t11FcRscnRejectedRequestSource->{$putinv};
			my $fc_t11FcRscnRejectReasonCode_1=$fc_t11FcRscnRejectReasonCode->{$putinv};
			my $fc_t11FcRscnRejectReasonCodeExp_1=$fc_t11FcRscnRejectReasonCodeExp->{$putinv};
			my $fc_t11FcRscnRejectReasonVendorCode_1=$fc_t11FcRscnRejectReasonVendorCode->{$putinv};
			$t11fcrscnnotifycontroltable_sth->execute($deviceid,$scantime,$fc_t11FcRscnIlsRejectNotifyEnable_1,$fc_t11FcRscnElsRejectNotifyEnable_1,$fc_t11FcRscnRejectedRequestString_1,$fc_t11FcRscnRejectedRequestSource_1,$fc_t11FcRscnRejectReasonCode_1,$fc_t11FcRscnRejectReasonCodeExp_1,$fc_t11FcRscnRejectReasonVendorCode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsAttribBlockRowStatus){
			my $fc_t11ZsAttribBlockIndex_1=$fc_t11ZsAttribBlockIndex->{$putinv};
			my $fc_t11ZsAttribBlockName_1=$fc_t11ZsAttribBlockName->{$putinv};
			my $fc_t11ZsAttribBlockRowStatus_1=$fc_t11ZsAttribBlockRowStatus->{$putinv};
			$t11zsattribblocktable_sth->execute($deviceid,$scantime,$fc_t11ZsAttribBlockIndex_1,$fc_t11ZsAttribBlockName_1,$fc_t11ZsAttribBlockRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsServerDefZoneBroadcast){
			my $fc_t11ZsServerFabricIndex_1=$fc_t11ZsServerFabricIndex->{$putinv};
			my $fc_t11ZsServerCapabilityObject_1=$fc_t11ZsServerCapabilityObject->{$putinv};
			my $fc_t11ZsServerDatabaseStorageType_1=$fc_t11ZsServerDatabaseStorageType->{$putinv};
			my $fc_t11ZsServerDistribute_1=$fc_t11ZsServerDistribute->{$putinv};
			my $fc_t11ZsServerCommit_1=$fc_t11ZsServerCommit->{$putinv};
			my $fc_t11ZsServerResult_1=$fc_t11ZsServerResult->{$putinv};
			my $fc_t11ZsServerReasonCode_1=$fc_t11ZsServerReasonCode->{$putinv};
			my $fc_t11ZsServerReasonCodeExp_1=$fc_t11ZsServerReasonCodeExp->{$putinv};
			my $fc_t11ZsServerReasonVendorCode_1=$fc_t11ZsServerReasonVendorCode->{$putinv};
			my $fc_t11ZsServerLastChange_1=$fc_t11ZsServerLastChange->{$putinv};
			my $fc_t11ZsServerHardZoning_1=$fc_t11ZsServerHardZoning->{$putinv};
			my $fc_t11ZsServerReadFromDatabase_1=$fc_t11ZsServerReadFromDatabase->{$putinv};
			my $fc_t11ZsServerOperationMode_1=$fc_t11ZsServerOperationMode->{$putinv};
			my $fc_t11ZsServerChangeModeResult_1=$fc_t11ZsServerChangeModeResult->{$putinv};
			my $fc_t11ZsServerDefaultZoneSetting_1=$fc_t11ZsServerDefaultZoneSetting->{$putinv};
			my $fc_t11ZsServerMergeControlSetting_1=$fc_t11ZsServerMergeControlSetting->{$putinv};
			my $fc_t11ZsServerDefZoneBroadcast_1=$fc_t11ZsServerDefZoneBroadcast->{$putinv};
			$t11zsservertable_sth->execute($deviceid,$scantime,$fc_t11ZsServerFabricIndex_1,$fc_t11ZsServerCapabilityObject_1,$fc_t11ZsServerDatabaseStorageType_1,$fc_t11ZsServerDistribute_1,$fc_t11ZsServerCommit_1,$fc_t11ZsServerResult_1,$fc_t11ZsServerReasonCode_1,$fc_t11ZsServerReasonCodeExp_1,$fc_t11ZsServerReasonVendorCode_1,$fc_t11ZsServerLastChange_1,$fc_t11ZsServerHardZoning_1,$fc_t11ZsServerReadFromDatabase_1,$fc_t11ZsServerOperationMode_1,$fc_t11ZsServerChangeModeResult_1,$fc_t11ZsServerDefaultZoneSetting_1,$fc_t11ZsServerMergeControlSetting_1,$fc_t11ZsServerDefZoneBroadcast_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FamDatabaseSwitchWwn){
			my $fc_t11FamDatabaseDomainId_1=$fc_t11FamDatabaseDomainId->{$putinv};
			my $fc_t11FamDatabaseSwitchWwn_1=$fc_t11FamDatabaseSwitchWwn->{$putinv};
			$t11famdatabasetable_sth->execute($deviceid,$scantime,$fc_t11FamDatabaseDomainId_1,$fc_t11FamDatabaseSwitchWwn_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11vfVirtualSwitchStorageType){
			my $fc_t11vfVirtualSwitchVfId_1=$fc_t11vfVirtualSwitchVfId->{$putinv};
			my $fc_t11vfVirtualSwitchCoreSwitchName_1=$fc_t11vfVirtualSwitchCoreSwitchName->{$putinv};
			my $fc_t11vfVirtualSwitchRowStatus_1=$fc_t11vfVirtualSwitchRowStatus->{$putinv};
			my $fc_t11vfVirtualSwitchStorageType_1=$fc_t11vfVirtualSwitchStorageType->{$putinv};
			$t11vfvirtualswitchtable_sth->execute($deviceid,$scantime,$fc_t11vfVirtualSwitchVfId_1,$fc_t11vfVirtualSwitchCoreSwitchName_1,$fc_t11vfVirtualSwitchRowStatus_1,$fc_t11vfVirtualSwitchStorageType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsZoneRowStatus){
			my $fc_t11ZsZoneIndex_1=$fc_t11ZsZoneIndex->{$putinv};
			my $fc_t11ZsZoneName_1=$fc_t11ZsZoneName->{$putinv};
			my $fc_t11ZsZoneAttribBlock_1=$fc_t11ZsZoneAttribBlock->{$putinv};
			my $fc_t11ZsZoneRowStatus_1=$fc_t11ZsZoneRowStatus->{$putinv};
			$t11zszonetable_sth->execute($deviceid,$scantime,$fc_t11ZsZoneIndex_1,$fc_t11ZsZoneName_1,$fc_t11ZsZoneAttribBlock_1,$fc_t11ZsZoneRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsPlatformFC4Types){
			my $fc_t11FcsPlatformIndex_1=$fc_t11FcsPlatformIndex->{$putinv};
			my $fc_t11FcsPlatformName_1=$fc_t11FcsPlatformName->{$putinv};
			my $fc_t11FcsPlatformType_1=$fc_t11FcsPlatformType->{$putinv};
			my $fc_t11FcsPlatformNodeNameListIndex_1=$fc_t11FcsPlatformNodeNameListIndex->{$putinv};
			my $fc_t11FcsPlatformMgmtAddrListIndex_1=$fc_t11FcsPlatformMgmtAddrListIndex->{$putinv};
			my $fc_t11FcsPlatformVendorId_1=$fc_t11FcsPlatformVendorId->{$putinv};
			my $fc_t11FcsPlatformProductId_1=$fc_t11FcsPlatformProductId->{$putinv};
			my $fc_t11FcsPlatformProductRevLevel_1=$fc_t11FcsPlatformProductRevLevel->{$putinv};
			my $fc_t11FcsPlatformDescription_1=$fc_t11FcsPlatformDescription->{$putinv};
			my $fc_t11FcsPlatformLabel_1=$fc_t11FcsPlatformLabel->{$putinv};
			my $fc_t11FcsPlatformLocation_1=$fc_t11FcsPlatformLocation->{$putinv};
			my $fc_t11FcsPlatformSystemID_1=$fc_t11FcsPlatformSystemID->{$putinv};
			my $fc_t11FcsPlatformSysMgmtAddr_1=$fc_t11FcsPlatformSysMgmtAddr->{$putinv};
			my $fc_t11FcsPlatformClusterId_1=$fc_t11FcsPlatformClusterId->{$putinv};
			my $fc_t11FcsPlatformClusterMgmtAddr_1=$fc_t11FcsPlatformClusterMgmtAddr->{$putinv};
			my $fc_t11FcsPlatformFC4Types_1=$fc_t11FcsPlatformFC4Types->{$putinv};
			$t11fcsplatformtable_sth->execute($deviceid,$scantime,$fc_t11FcsPlatformIndex_1,$fc_t11FcsPlatformName_1,$fc_t11FcsPlatformType_1,$fc_t11FcsPlatformNodeNameListIndex_1,$fc_t11FcsPlatformMgmtAddrListIndex_1,$fc_t11FcsPlatformVendorId_1,$fc_t11FcsPlatformProductId_1,$fc_t11FcsPlatformProductRevLevel_1,$fc_t11FcsPlatformDescription_1,$fc_t11FcsPlatformLabel_1,$fc_t11FcsPlatformLocation_1,$fc_t11FcsPlatformSystemID_1,$fc_t11FcsPlatformSysMgmtAddr_1,$fc_t11FcsPlatformClusterId_1,$fc_t11FcsPlatformClusterMgmtAddr_1,$fc_t11FcsPlatformFC4Types_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsRejects){
			my $fc_t11FcsInGetReqs_1=$fc_t11FcsInGetReqs->{$putinv};
			my $fc_t11FcsOutGetReqs_1=$fc_t11FcsOutGetReqs->{$putinv};
			my $fc_t11FcsInRegReqs_1=$fc_t11FcsInRegReqs->{$putinv};
			my $fc_t11FcsOutRegReqs_1=$fc_t11FcsOutRegReqs->{$putinv};
			my $fc_t11FcsInDeregReqs_1=$fc_t11FcsInDeregReqs->{$putinv};
			my $fc_t11FcsOutDeregReqs_1=$fc_t11FcsOutDeregReqs->{$putinv};
			my $fc_t11FcsRejects_1=$fc_t11FcsRejects->{$putinv};
			$t11fcsstatstable_sth->execute($deviceid,$scantime,$fc_t11FcsInGetReqs_1,$fc_t11FcsOutGetReqs_1,$fc_t11FcsInRegReqs_1,$fc_t11FcsOutRegReqs_1,$fc_t11FcsInDeregReqs_1,$fc_t11FcsOutDeregReqs_1,$fc_t11FcsRejects_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmPortOtherErrors){
			my $fc_fcmPortRxLinkResets_1=$fc_fcmPortRxLinkResets->{$putinv};
			my $fc_fcmPortTxLinkResets_1=$fc_fcmPortTxLinkResets->{$putinv};
			my $fc_fcmPortLinkResets_1=$fc_fcmPortLinkResets->{$putinv};
			my $fc_fcmPortRxOfflineSequences_1=$fc_fcmPortRxOfflineSequences->{$putinv};
			my $fc_fcmPortTxOfflineSequences_1=$fc_fcmPortTxOfflineSequences->{$putinv};
			my $fc_fcmPortLinkFailures_1=$fc_fcmPortLinkFailures->{$putinv};
			my $fc_fcmPortLossofSynchs_1=$fc_fcmPortLossofSynchs->{$putinv};
			my $fc_fcmPortLossofSignals_1=$fc_fcmPortLossofSignals->{$putinv};
			my $fc_fcmPortPrimSeqProtocolErrors_1=$fc_fcmPortPrimSeqProtocolErrors->{$putinv};
			my $fc_fcmPortInvalidTxWords_1=$fc_fcmPortInvalidTxWords->{$putinv};
			my $fc_fcmPortInvalidCRCs_1=$fc_fcmPortInvalidCRCs->{$putinv};
			my $fc_fcmPortInvalidOrderedSets_1=$fc_fcmPortInvalidOrderedSets->{$putinv};
			my $fc_fcmPortFrameTooLongs_1=$fc_fcmPortFrameTooLongs->{$putinv};
			my $fc_fcmPortTruncatedFrames_1=$fc_fcmPortTruncatedFrames->{$putinv};
			my $fc_fcmPortAddressErrors_1=$fc_fcmPortAddressErrors->{$putinv};
			my $fc_fcmPortDelimiterErrors_1=$fc_fcmPortDelimiterErrors->{$putinv};
			my $fc_fcmPortEncodingDisparityErrors_1=$fc_fcmPortEncodingDisparityErrors->{$putinv};
			my $fc_fcmPortOtherErrors_1=$fc_fcmPortOtherErrors->{$putinv};
			$fcmporterrorstable_sth->execute($deviceid,$scantime,$fc_fcmPortRxLinkResets_1,$fc_fcmPortTxLinkResets_1,$fc_fcmPortLinkResets_1,$fc_fcmPortRxOfflineSequences_1,$fc_fcmPortTxOfflineSequences_1,$fc_fcmPortLinkFailures_1,$fc_fcmPortLossofSynchs_1,$fc_fcmPortLossofSignals_1,$fc_fcmPortPrimSeqProtocolErrors_1,$fc_fcmPortInvalidTxWords_1,$fc_fcmPortInvalidCRCs_1,$fc_fcmPortInvalidOrderedSets_1,$fc_fcmPortFrameTooLongs_1,$fc_fcmPortTruncatedFrames_1,$fc_fcmPortAddressErrors_1,$fc_fcmPortDelimiterErrors_1,$fc_fcmPortEncodingDisparityErrors_1,$fc_fcmPortOtherErrors_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcRscnRegType){
			my $fc_t11FcRscnFabricIndex_1=$fc_t11FcRscnFabricIndex->{$putinv};
			my $fc_t11FcRscnRegFcId_1=$fc_t11FcRscnRegFcId->{$putinv};
			my $fc_t11FcRscnRegType_1=$fc_t11FcRscnRegType->{$putinv};
			$t11fcrscnregtable_sth->execute($deviceid,$scantime,$fc_t11FcRscnFabricIndex_1,$fc_t11FcRscnRegFcId_1,$fc_t11FcRscnRegType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsAliasRowStatus){
			my $fc_t11ZsAliasIndex_1=$fc_t11ZsAliasIndex->{$putinv};
			my $fc_t11ZsAliasName_1=$fc_t11ZsAliasName->{$putinv};
			my $fc_t11ZsAliasRowStatus_1=$fc_t11ZsAliasRowStatus->{$putinv};
			$t11zsaliastable_sth->execute($deviceid,$scantime,$fc_t11ZsAliasIndex_1,$fc_t11ZsAliasName_1,$fc_t11ZsAliasRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11NsRejReasonVendorCode){
			my $fc_t11NsRejectCtCommandString_1=$fc_t11NsRejectCtCommandString->{$putinv};
			my $fc_t11NsRejectReasonCode_1=$fc_t11NsRejectReasonCode->{$putinv};
			my $fc_t11NsRejReasonCodeExp_1=$fc_t11NsRejReasonCodeExp->{$putinv};
			my $fc_t11NsRejReasonVendorCode_1=$fc_t11NsRejReasonVendorCode->{$putinv};
			$t11nsrejecttable_sth->execute($deviceid,$scantime,$fc_t11NsRejectCtCommandString_1,$fc_t11NsRejectReasonCode_1,$fc_t11NsRejReasonCodeExp_1,$fc_t11NsRejReasonVendorCode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11NsInfoSubsetRejReqNotfyEnable){
			my $fc_t11NsInfoSubsetIndex_1=$fc_t11NsInfoSubsetIndex->{$putinv};
			my $fc_t11NsInfoSubsetSwitchIndex_1=$fc_t11NsInfoSubsetSwitchIndex->{$putinv};
			my $fc_t11NsInfoSubsetTableLastChange_1=$fc_t11NsInfoSubsetTableLastChange->{$putinv};
			my $fc_t11NsInfoSubsetNumRows_1=$fc_t11NsInfoSubsetNumRows->{$putinv};
			my $fc_t11NsInfoSubsetTotalRejects_1=$fc_t11NsInfoSubsetTotalRejects->{$putinv};
			my $fc_t11NsInfoSubsetRejReqNotfyEnable_1=$fc_t11NsInfoSubsetRejReqNotfyEnable->{$putinv};
			$t11nsinfosubsettable_sth->execute($deviceid,$scantime,$fc_t11NsInfoSubsetIndex_1,$fc_t11NsInfoSubsetSwitchIndex_1,$fc_t11NsInfoSubsetTableLastChange_1,$fc_t11NsInfoSubsetNumRows_1,$fc_t11NsInfoSubsetTotalRejects_1,$fc_t11NsInfoSubsetRejReqNotfyEnable_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortPhysRttov){
			my $fc_fcFxPortPhysAdminStatus_1=$fc_fcFxPortPhysAdminStatus->{$putinv};
			my $fc_fcFxPortPhysOperStatus_1=$fc_fcFxPortPhysOperStatus->{$putinv};
			my $fc_fcFxPortPhysLastChange_1=$fc_fcFxPortPhysLastChange->{$putinv};
			my $fc_fcFxPortPhysRttov_1=$fc_fcFxPortPhysRttov->{$putinv};
			$fcfxportphystable_sth->execute($deviceid,$scantime,$fc_fcFxPortPhysAdminStatus_1,$fc_fcFxPortPhysOperStatus_1,$fc_fcFxPortPhysLastChange_1,$fc_fcFxPortPhysRttov_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortAdminMode){
			my $fc_fcFxPortID_1=$fc_fcFxPortID->{$putinv};
			my $fc_fcFxPortBbCreditAvailable_1=$fc_fcFxPortBbCreditAvailable->{$putinv};
			my $fc_fcFxPortOperMode_1=$fc_fcFxPortOperMode->{$putinv};
			my $fc_fcFxPortAdminMode_1=$fc_fcFxPortAdminMode->{$putinv};
			$fcfxportstatustable_sth->execute($deviceid,$scantime,$fc_fcFxPortID_1,$fc_fcFxPortBbCreditAvailable_1,$fc_fcFxPortOperMode_1,$fc_fcFxPortAdminMode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortLinkResetIns){
			my $fc_fcFxPortLinkFailures_1=$fc_fcFxPortLinkFailures->{$putinv};
			my $fc_fcFxPortLinkResetOuts_1=$fc_fcFxPortLinkResetOuts->{$putinv};
			my $fc_fcFxPortOlsIns_1=$fc_fcFxPortOlsIns->{$putinv};
			my $fc_fcFxPortOlsOuts_1=$fc_fcFxPortOlsOuts->{$putinv};
			my $fc_fcFxPortSyncLosses_1=$fc_fcFxPortSyncLosses->{$putinv};
			my $fc_fcFxPortSigLosses_1=$fc_fcFxPortSigLosses->{$putinv};
			my $fc_fcFxPortPrimSeqProtoErrors_1=$fc_fcFxPortPrimSeqProtoErrors->{$putinv};
			my $fc_fcFxPortInvalidTxWords_1=$fc_fcFxPortInvalidTxWords->{$putinv};
			my $fc_fcFxPortInvalidCrcs_1=$fc_fcFxPortInvalidCrcs->{$putinv};
			my $fc_fcFxPortDelimiterErrors_1=$fc_fcFxPortDelimiterErrors->{$putinv};
			my $fc_fcFxPortAddressIdErrors_1=$fc_fcFxPortAddressIdErrors->{$putinv};
			my $fc_fcFxPortLinkResetIns_1=$fc_fcFxPortLinkResetIns->{$putinv};
			$fcfxporterrortable_sth->execute($deviceid,$scantime,$fc_fcFxPortLinkFailures_1,$fc_fcFxPortLinkResetOuts_1,$fc_fcFxPortOlsIns_1,$fc_fcFxPortOlsOuts_1,$fc_fcFxPortSyncLosses_1,$fc_fcFxPortSigLosses_1,$fc_fcFxPortPrimSeqProtoErrors_1,$fc_fcFxPortInvalidTxWords_1,$fc_fcFxPortInvalidCrcs_1,$fc_fcFxPortDelimiterErrors_1,$fc_fcFxPortAddressIdErrors_1,$fc_fcFxPortLinkResetIns_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsActiveAttribValue){
			my $fc_t11ZsActiveAttribIndex_1=$fc_t11ZsActiveAttribIndex->{$putinv};
			my $fc_t11ZsActiveAttribType_1=$fc_t11ZsActiveAttribType->{$putinv};
			my $fc_t11ZsActiveAttribValue_1=$fc_t11ZsActiveAttribValue->{$putinv};
			$t11zsactiveattribtable_sth->execute($deviceid,$scantime,$fc_t11ZsActiveAttribIndex_1,$fc_t11ZsActiveAttribType_1,$fc_t11ZsActiveAttribValue_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11vfCoreSwitchStorageType){
			my $fc_t11vfCoreSwitchSwitchName_1=$fc_t11vfCoreSwitchSwitchName->{$putinv};
			my $fc_t11vfCoreSwitchMaxSupported_1=$fc_t11vfCoreSwitchMaxSupported->{$putinv};
			my $fc_t11vfCoreSwitchStorageType_1=$fc_t11vfCoreSwitchStorageType->{$putinv};
			$t11vfcoreswitchtable_sth->execute($deviceid,$scantime,$fc_t11vfCoreSwitchSwitchName_1,$fc_t11vfCoreSwitchMaxSupported_1,$fc_t11vfCoreSwitchStorageType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11NsRegFc4Descriptor){
			my $fc_t11NsRegFc4TypeValue_1=$fc_t11NsRegFc4TypeValue->{$putinv};
			my $fc_t11NsRegFc4Descriptor_1=$fc_t11NsRegFc4Descriptor->{$putinv};
			$t11nsregfc4descriptortable_sth->execute($deviceid,$scantime,$fc_t11NsRegFc4TypeValue_1,$fc_t11NsRegFc4Descriptor_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FspfIfRowStatus){
			my $fc_t11FspfIfIndex_1=$fc_t11FspfIfIndex->{$putinv};
			my $fc_t11FspfIfHelloInterval_1=$fc_t11FspfIfHelloInterval->{$putinv};
			my $fc_t11FspfIfDeadInterval_1=$fc_t11FspfIfDeadInterval->{$putinv};
			my $fc_t11FspfIfRetransmitInterval_1=$fc_t11FspfIfRetransmitInterval->{$putinv};
			my $fc_t11FspfIfInLsuPkts_1=$fc_t11FspfIfInLsuPkts->{$putinv};
			my $fc_t11FspfIfInLsaPkts_1=$fc_t11FspfIfInLsaPkts->{$putinv};
			my $fc_t11FspfIfOutLsuPkts_1=$fc_t11FspfIfOutLsuPkts->{$putinv};
			my $fc_t11FspfIfOutLsaPkts_1=$fc_t11FspfIfOutLsaPkts->{$putinv};
			my $fc_t11FspfIfOutHelloPkts_1=$fc_t11FspfIfOutHelloPkts->{$putinv};
			my $fc_t11FspfIfInHelloPkts_1=$fc_t11FspfIfInHelloPkts->{$putinv};
			my $fc_t11FspfIfRetransmittedLsuPkts_1=$fc_t11FspfIfRetransmittedLsuPkts->{$putinv};
			my $fc_t11FspfIfInErrorPkts_1=$fc_t11FspfIfInErrorPkts->{$putinv};
			my $fc_t11FspfIfNbrState_1=$fc_t11FspfIfNbrState->{$putinv};
			my $fc_t11FspfIfNbrDomainId_1=$fc_t11FspfIfNbrDomainId->{$putinv};
			my $fc_t11FspfIfNbrPortIndex_1=$fc_t11FspfIfNbrPortIndex->{$putinv};
			my $fc_t11FspfIfAdminStatus_1=$fc_t11FspfIfAdminStatus->{$putinv};
			my $fc_t11FspfIfCreateTime_1=$fc_t11FspfIfCreateTime->{$putinv};
			my $fc_t11FspfIfSetToDefault_1=$fc_t11FspfIfSetToDefault->{$putinv};
			my $fc_t11FspfIfLinkCostFactor_1=$fc_t11FspfIfLinkCostFactor->{$putinv};
			my $fc_t11FspfIfStorageType_1=$fc_t11FspfIfStorageType->{$putinv};
			my $fc_t11FspfIfRowStatus_1=$fc_t11FspfIfRowStatus->{$putinv};
			$t11fspfiftable_sth->execute($deviceid,$scantime,$fc_t11FspfIfIndex_1,$fc_t11FspfIfHelloInterval_1,$fc_t11FspfIfDeadInterval_1,$fc_t11FspfIfRetransmitInterval_1,$fc_t11FspfIfInLsuPkts_1,$fc_t11FspfIfInLsaPkts_1,$fc_t11FspfIfOutLsuPkts_1,$fc_t11FspfIfOutLsaPkts_1,$fc_t11FspfIfOutHelloPkts_1,$fc_t11FspfIfInHelloPkts_1,$fc_t11FspfIfRetransmittedLsuPkts_1,$fc_t11FspfIfInErrorPkts_1,$fc_t11FspfIfNbrState_1,$fc_t11FspfIfNbrDomainId_1,$fc_t11FspfIfNbrPortIndex_1,$fc_t11FspfIfAdminStatus_1,$fc_t11FspfIfCreateTime_1,$fc_t11FspfIfSetToDefault_1,$fc_t11FspfIfLinkCostFactor_1,$fc_t11FspfIfStorageType_1,$fc_t11FspfIfRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortC1OutConnections){
			my $fc_fcFxPortC1InFrames_1=$fc_fcFxPortC1InFrames->{$putinv};
			my $fc_fcFxPortC1ConnTime_1=$fc_fcFxPortC1ConnTime->{$putinv};
			my $fc_fcFxPortC1OutFrames_1=$fc_fcFxPortC1OutFrames->{$putinv};
			my $fc_fcFxPortC1InOctets_1=$fc_fcFxPortC1InOctets->{$putinv};
			my $fc_fcFxPortC1OutOctets_1=$fc_fcFxPortC1OutOctets->{$putinv};
			my $fc_fcFxPortC1Discards_1=$fc_fcFxPortC1Discards->{$putinv};
			my $fc_fcFxPortC1FbsyFrames_1=$fc_fcFxPortC1FbsyFrames->{$putinv};
			my $fc_fcFxPortC1FrjtFrames_1=$fc_fcFxPortC1FrjtFrames->{$putinv};
			my $fc_fcFxPortC1InConnections_1=$fc_fcFxPortC1InConnections->{$putinv};
			my $fc_fcFxPortC1OutConnections_1=$fc_fcFxPortC1OutConnections->{$putinv};
			$fcfxportc1accountingtable_sth->execute($deviceid,$scantime,$fc_fcFxPortC1InFrames_1,$fc_fcFxPortC1ConnTime_1,$fc_fcFxPortC1OutFrames_1,$fc_fcFxPortC1InOctets_1,$fc_fcFxPortC1OutOctets_1,$fc_fcFxPortC1Discards_1,$fc_fcFxPortC1FbsyFrames_1,$fc_fcFxPortC1FrjtFrames_1,$fc_fcFxPortC1InConnections_1,$fc_fcFxPortC1OutConnections_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcRscnOutRemovedRscns){
			my $fc_t11FcRscnInScrs_1=$fc_t11FcRscnInScrs->{$putinv};
			my $fc_t11FcRscnInRscns_1=$fc_t11FcRscnInRscns->{$putinv};
			my $fc_t11FcRscnOutRscns_1=$fc_t11FcRscnOutRscns->{$putinv};
			my $fc_t11FcRscnInSwRscns_1=$fc_t11FcRscnInSwRscns->{$putinv};
			my $fc_t11FcRscnOutSwRscns_1=$fc_t11FcRscnOutSwRscns->{$putinv};
			my $fc_t11FcRscnScrRejects_1=$fc_t11FcRscnScrRejects->{$putinv};
			my $fc_t11FcRscnRscnRejects_1=$fc_t11FcRscnRscnRejects->{$putinv};
			my $fc_t11FcRscnSwRscnRejects_1=$fc_t11FcRscnSwRscnRejects->{$putinv};
			my $fc_t11FcRscnInUnspecifiedRscns_1=$fc_t11FcRscnInUnspecifiedRscns->{$putinv};
			my $fc_t11FcRscnOutUnspecifiedRscns_1=$fc_t11FcRscnOutUnspecifiedRscns->{$putinv};
			my $fc_t11FcRscnInChangedAttribRscns_1=$fc_t11FcRscnInChangedAttribRscns->{$putinv};
			my $fc_t11FcRscnOutChangedAttribRscns_1=$fc_t11FcRscnOutChangedAttribRscns->{$putinv};
			my $fc_t11FcRscnInChangedServiceRscns_1=$fc_t11FcRscnInChangedServiceRscns->{$putinv};
			my $fc_t11FcRscnOutChangedServiceRscns_1=$fc_t11FcRscnOutChangedServiceRscns->{$putinv};
			my $fc_t11FcRscnInChangedSwitchRscns_1=$fc_t11FcRscnInChangedSwitchRscns->{$putinv};
			my $fc_t11FcRscnOutChangedSwitchRscns_1=$fc_t11FcRscnOutChangedSwitchRscns->{$putinv};
			my $fc_t11FcRscnInRemovedRscns_1=$fc_t11FcRscnInRemovedRscns->{$putinv};
			my $fc_t11FcRscnOutRemovedRscns_1=$fc_t11FcRscnOutRemovedRscns->{$putinv};
			$t11fcrscnstatstable_sth->execute($deviceid,$scantime,$fc_t11FcRscnInScrs_1,$fc_t11FcRscnInRscns_1,$fc_t11FcRscnOutRscns_1,$fc_t11FcRscnInSwRscns_1,$fc_t11FcRscnOutSwRscns_1,$fc_t11FcRscnScrRejects_1,$fc_t11FcRscnRscnRejects_1,$fc_t11FcRscnSwRscnRejects_1,$fc_t11FcRscnInUnspecifiedRscns_1,$fc_t11FcRscnOutUnspecifiedRscns_1,$fc_t11FcRscnInChangedAttribRscns_1,$fc_t11FcRscnOutChangedAttribRscns_1,$fc_t11FcRscnInChangedServiceRscns_1,$fc_t11FcRscnOutChangedServiceRscns_1,$fc_t11FcRscnInChangedSwitchRscns_1,$fc_t11FcRscnOutChangedSwitchRscns_1,$fc_t11FcRscnInRemovedRscns_1,$fc_t11FcRscnOutRemovedRscns_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FamIfRowStatus){
			my $fc_t11FamIfRcfReject_1=$fc_t11FamIfRcfReject->{$putinv};
			my $fc_t11FamIfRole_1=$fc_t11FamIfRole->{$putinv};
			my $fc_t11FamIfRowStatus_1=$fc_t11FamIfRowStatus->{$putinv};
			$t11famiftable_sth->execute($deviceid,$scantime,$fc_t11FamIfRcfReject_1,$fc_t11FamIfRole_1,$fc_t11FamIfRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsIeInfoList){
			my $fc_t11FcsIeName_1=$fc_t11FcsIeName->{$putinv};
			my $fc_t11FcsIeType_1=$fc_t11FcsIeType->{$putinv};
			my $fc_t11FcsIeDomainId_1=$fc_t11FcsIeDomainId->{$putinv};
			my $fc_t11FcsIeMgmtId_1=$fc_t11FcsIeMgmtId->{$putinv};
			my $fc_t11FcsIeFabricName_1=$fc_t11FcsIeFabricName->{$putinv};
			my $fc_t11FcsIeLogicalName_1=$fc_t11FcsIeLogicalName->{$putinv};
			my $fc_t11FcsIeMgmtAddrListIndex_1=$fc_t11FcsIeMgmtAddrListIndex->{$putinv};
			my $fc_t11FcsIeInfoList_1=$fc_t11FcsIeInfoList->{$putinv};
			$t11fcsietable_sth->execute($deviceid,$scantime,$fc_t11FcsIeName_1,$fc_t11FcsIeType_1,$fc_t11FcsIeDomainId_1,$fc_t11FcsIeMgmtId_1,$fc_t11FcsIeFabricName_1,$fc_t11FcsIeLogicalName_1,$fc_t11FcsIeMgmtAddrListIndex_1,$fc_t11FcsIeInfoList_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FamFabricName){
			my $fc_t11FamFabricIndex_1=$fc_t11FamFabricIndex->{$putinv};
			my $fc_t11FamConfigDomainId_1=$fc_t11FamConfigDomainId->{$putinv};
			my $fc_t11FamConfigDomainIdType_1=$fc_t11FamConfigDomainIdType->{$putinv};
			my $fc_t11FamAutoReconfigure_1=$fc_t11FamAutoReconfigure->{$putinv};
			my $fc_t11FamContiguousAllocation_1=$fc_t11FamContiguousAllocation->{$putinv};
			my $fc_t11FamPriority_1=$fc_t11FamPriority->{$putinv};
			my $fc_t11FamPrincipalSwitchWwn_1=$fc_t11FamPrincipalSwitchWwn->{$putinv};
			my $fc_t11FamLocalSwitchWwn_1=$fc_t11FamLocalSwitchWwn->{$putinv};
			my $fc_t11FamAssignedAreaIdList_1=$fc_t11FamAssignedAreaIdList->{$putinv};
			my $fc_t11FamGrantedFcIds_1=$fc_t11FamGrantedFcIds->{$putinv};
			my $fc_t11FamRecoveredFcIds_1=$fc_t11FamRecoveredFcIds->{$putinv};
			my $fc_t11FamFreeFcIds_1=$fc_t11FamFreeFcIds->{$putinv};
			my $fc_t11FamAssignedFcIds_1=$fc_t11FamAssignedFcIds->{$putinv};
			my $fc_t11FamAvailableFcIds_1=$fc_t11FamAvailableFcIds->{$putinv};
			my $fc_t11FamRunningPriority_1=$fc_t11FamRunningPriority->{$putinv};
			my $fc_t11FamPrincSwRunningPriority_1=$fc_t11FamPrincSwRunningPriority->{$putinv};
			my $fc_t11FamState_1=$fc_t11FamState->{$putinv};
			my $fc_t11FamLocalPrincipalSwitchSlctns_1=$fc_t11FamLocalPrincipalSwitchSlctns->{$putinv};
			my $fc_t11FamPrincipalSwitchSelections_1=$fc_t11FamPrincipalSwitchSelections->{$putinv};
			my $fc_t11FamBuildFabrics_1=$fc_t11FamBuildFabrics->{$putinv};
			my $fc_t11FamFabricReconfigures_1=$fc_t11FamFabricReconfigures->{$putinv};
			my $fc_t11FamDomainId_1=$fc_t11FamDomainId->{$putinv};
			my $fc_t11FamSticky_1=$fc_t11FamSticky->{$putinv};
			my $fc_t11FamRestart_1=$fc_t11FamRestart->{$putinv};
			my $fc_t11FamRcFabricNotifyEnable_1=$fc_t11FamRcFabricNotifyEnable->{$putinv};
			my $fc_t11FamEnable_1=$fc_t11FamEnable->{$putinv};
			my $fc_t11FamFabricName_1=$fc_t11FamFabricName->{$putinv};
			$fc_t11famtable_sth->execute($deviceid,$scantime,$fc_t11FamFabricIndex_1,$fc_t11FamConfigDomainId_1,$fc_t11FamConfigDomainIdType_1,$fc_t11FamAutoReconfigure_1,$fc_t11FamContiguousAllocation_1,$fc_t11FamPriority_1,$fc_t11FamPrincipalSwitchWwn_1,$fc_t11FamLocalSwitchWwn_1,$fc_t11FamAssignedAreaIdList_1,$fc_t11FamGrantedFcIds_1,$fc_t11FamRecoveredFcIds_1,$fc_t11FamFreeFcIds_1,$fc_t11FamAssignedFcIds_1,$fc_t11FamAvailableFcIds_1,$fc_t11FamRunningPriority_1,$fc_t11FamPrincSwRunningPriority_1,$fc_t11FamState_1,$fc_t11FamLocalPrincipalSwitchSlctns_1,$fc_t11FamPrincipalSwitchSelections_1,$fc_t11FamBuildFabrics_1,$fc_t11FamFabricReconfigures_1,$fc_t11FamDomainId_1,$fc_t11FamSticky_1,$fc_t11FamRestart_1,$fc_t11FamRcFabricNotifyEnable_1,$fc_t11FamEnable_1,$fc_t11FamFabricName_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsAttribRowStatus){
			my $fc_t11ZsAttribIndex_1=$fc_t11ZsAttribIndex->{$putinv};
			my $fc_t11ZsAttribType_1=$fc_t11ZsAttribType->{$putinv};
			my $fc_t11ZsAttribValue_1=$fc_t11ZsAttribValue->{$putinv};
			my $fc_t11ZsAttribRowStatus_1=$fc_t11ZsAttribRowStatus->{$putinv};
			$t11zsattribtable_sth->execute($deviceid,$scantime,$fc_t11ZsAttribIndex_1,$fc_t11ZsAttribType_1,$fc_t11ZsAttribValue_1,$fc_t11ZsAttribRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsActivateFailDomainId){
			my $fc_t11ZsActivateRequest_1=$fc_t11ZsActivateRequest->{$putinv};
			my $fc_t11ZsActivateDeactivate_1=$fc_t11ZsActivateDeactivate->{$putinv};
			my $fc_t11ZsActivateResult_1=$fc_t11ZsActivateResult->{$putinv};
			my $fc_t11ZsActivateFailCause_1=$fc_t11ZsActivateFailCause->{$putinv};
			my $fc_t11ZsActivateFailDomainId_1=$fc_t11ZsActivateFailDomainId->{$putinv};
			$t11zsactivatetable_sth->execute($deviceid,$scantime,$fc_t11ZsActivateRequest_1,$fc_t11ZsActivateDeactivate_1,$fc_t11ZsActivateResult_1,$fc_t11ZsActivateFailCause_1,$fc_t11ZsActivateFailDomainId_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FamAreaAssignedPortIdList){
			my $fc_t11FamAreaAreaId_1=$fc_t11FamAreaAreaId->{$putinv};
			my $fc_t11FamAreaAssignedPortIdList_1=$fc_t11FamAreaAssignedPortIdList->{$putinv};
			$t11famareatable_sth->execute($deviceid,$scantime,$fc_t11FamAreaAreaId_1,$fc_t11FamAreaAssignedPortIdList_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmFxPortCapHoldTimeMin){
			my $fc_fcmFxPortRatov_1=$fc_fcmFxPortRatov->{$putinv};
			my $fc_fcmFxPortEdtov_1=$fc_fcmFxPortEdtov->{$putinv};
			my $fc_fcmFxPortRttov_1=$fc_fcmFxPortRttov->{$putinv};
			my $fc_fcmFxPortHoldTime_1=$fc_fcmFxPortHoldTime->{$putinv};
			my $fc_fcmFxPortCapBbCreditMax_1=$fc_fcmFxPortCapBbCreditMax->{$putinv};
			my $fc_fcmFxPortCapBbCreditMin_1=$fc_fcmFxPortCapBbCreditMin->{$putinv};
			my $fc_fcmFxPortCapDataFieldSizeMax_1=$fc_fcmFxPortCapDataFieldSizeMax->{$putinv};
			my $fc_fcmFxPortCapDataFieldSizeMin_1=$fc_fcmFxPortCapDataFieldSizeMin->{$putinv};
			my $fc_fcmFxPortCapClass2SeqDeliv_1=$fc_fcmFxPortCapClass2SeqDeliv->{$putinv};
			my $fc_fcmFxPortCapClass3SeqDeliv_1=$fc_fcmFxPortCapClass3SeqDeliv->{$putinv};
			my $fc_fcmFxPortCapHoldTimeMax_1=$fc_fcmFxPortCapHoldTimeMax->{$putinv};
			my $fc_fcmFxPortCapHoldTimeMin_1=$fc_fcmFxPortCapHoldTimeMin->{$putinv};
			$fcmfxporttable_sth->execute($deviceid,$scantime,$fc_fcmFxPortRatov_1,$fc_fcmFxPortEdtov_1,$fc_fcmFxPortRttov_1,$fc_fcmFxPortHoldTime_1,$fc_fcmFxPortCapBbCreditMax_1,$fc_fcmFxPortCapBbCreditMin_1,$fc_fcmFxPortCapDataFieldSizeMax_1,$fc_fcmFxPortCapDataFieldSizeMin_1,$fc_fcmFxPortCapClass2SeqDeliv_1,$fc_fcmFxPortCapClass3SeqDeliv_1,$fc_fcmFxPortCapHoldTimeMax_1,$fc_fcmFxPortCapHoldTimeMin_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsDiscoveryCompleteTime){
			my $fc_t11FcsFabricIndex_1=$fc_t11FcsFabricIndex->{$putinv};
			my $fc_t11FcsDiscoveryStatus_1=$fc_t11FcsDiscoveryStatus->{$putinv};
			my $fc_t11FcsDiscoveryCompleteTime_1=$fc_t11FcsDiscoveryCompleteTime->{$putinv};
			$t11fcsdiscoverystatetable_sth->execute($deviceid,$scantime,$fc_t11FcsFabricIndex_1,$fc_t11FcsDiscoveryStatus_1,$fc_t11FcsDiscoveryCompleteTime_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FamFcIdCachePortIds){
			my $fc_t11FamFcIdCacheWwn_1=$fc_t11FamFcIdCacheWwn->{$putinv};
			my $fc_t11FamFcIdCacheAreaIdPortId_1=$fc_t11FamFcIdCacheAreaIdPortId->{$putinv};
			my $fc_t11FamFcIdCachePortIds_1=$fc_t11FamFcIdCachePortIds->{$putinv};
			$t11famfcidcachetable_sth->execute($deviceid,$scantime,$fc_t11FamFcIdCacheWwn_1,$fc_t11FamFcIdCacheAreaIdPortId_1,$fc_t11FamFcIdCachePortIds_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortClass3SeqDelivAgreed){
			my $fc_fcFxPortNxLoginIndex_1=$fc_fcFxPortNxLoginIndex->{$putinv};
			my $fc_fcFxPortNxPortName_1=$fc_fcFxPortNxPortName->{$putinv};
			my $fc_fcFxPortConnectedNxPort_1=$fc_fcFxPortConnectedNxPort->{$putinv};
			my $fc_fcFxPortBbCreditModel_1=$fc_fcFxPortBbCreditModel->{$putinv};
			my $fc_fcFxPortFcphVersionAgreed_1=$fc_fcFxPortFcphVersionAgreed->{$putinv};
			my $fc_fcFxPortNxPortBbCredit_1=$fc_fcFxPortNxPortBbCredit->{$putinv};
			my $fc_fcFxPortNxPortRxDataFieldSize_1=$fc_fcFxPortNxPortRxDataFieldSize->{$putinv};
			my $fc_fcFxPortCosSuppAgreed_1=$fc_fcFxPortCosSuppAgreed->{$putinv};
			my $fc_fcFxPortIntermixSuppAgreed_1=$fc_fcFxPortIntermixSuppAgreed->{$putinv};
			my $fc_fcFxPortStackedConnModeAgreed_1=$fc_fcFxPortStackedConnModeAgreed->{$putinv};
			my $fc_fcFxPortClass2SeqDelivAgreed_1=$fc_fcFxPortClass2SeqDelivAgreed->{$putinv};
			my $fc_fcFxPortClass3SeqDelivAgreed_1=$fc_fcFxPortClass3SeqDelivAgreed->{$putinv};
			$fcfxlogintable_sth->execute($deviceid,$scantime,$fc_fcFxPortNxLoginIndex_1,$fc_fcFxPortNxPortName_1,$fc_fcFxPortConnectedNxPort_1,$fc_fcFxPortBbCreditModel_1,$fc_fcFxPortFcphVersionAgreed_1,$fc_fcFxPortNxPortBbCredit_1,$fc_fcFxPortNxPortRxDataFieldSize_1,$fc_fcFxPortCosSuppAgreed_1,$fc_fcFxPortIntermixSuppAgreed_1,$fc_fcFxPortStackedConnModeAgreed_1,$fc_fcFxPortClass2SeqDelivAgreed_1,$fc_fcFxPortClass3SeqDelivAgreed_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsMgmtAddr){
			my $fc_t11FcsMgmtAddrListIndex_1=$fc_t11FcsMgmtAddrListIndex->{$putinv};
			my $fc_t11FcsMgmtAddrIndex_1=$fc_t11FcsMgmtAddrIndex->{$putinv};
			my $fc_t11FcsMgmtAddr_1=$fc_t11FcsMgmtAddr->{$putinv};
			$t11fcsmgmtaddrlisttable_sth->execute($deviceid,$scantime,$fc_t11FcsMgmtAddrListIndex_1,$fc_t11FcsMgmtAddrIndex_1,$fc_t11FcsMgmtAddr_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortC3Discards){
			my $fc_fcFxPortC3InFrames_1=$fc_fcFxPortC3InFrames->{$putinv};
			my $fc_fcFxPortC3OutFrames_1=$fc_fcFxPortC3OutFrames->{$putinv};
			my $fc_fcFxPortC3InOctets_1=$fc_fcFxPortC3InOctets->{$putinv};
			my $fc_fcFxPortC3OutOctets_1=$fc_fcFxPortC3OutOctets->{$putinv};
			my $fc_fcFxPortC3Discards_1=$fc_fcFxPortC3Discards->{$putinv};
			$fcfxportc3accountingtable_sth->execute($deviceid,$scantime,$fc_fcFxPortC3InFrames_1,$fc_fcFxPortC3OutFrames_1,$fc_fcFxPortC3InOctets_1,$fc_fcFxPortC3OutOctets_1,$fc_fcFxPortC3Discards_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11vfLocallyEnabledStorageType){
			my $fc_t11vfLocallyEnabledPortIfIndex_1=$fc_t11vfLocallyEnabledPortIfIndex->{$putinv};
			my $fc_t11vfLocallyEnabledVfId_1=$fc_t11vfLocallyEnabledVfId->{$putinv};
			my $fc_t11vfLocallyEnabledOperStatus_1=$fc_t11vfLocallyEnabledOperStatus->{$putinv};
			my $fc_t11vfLocallyEnabledRowStatus_1=$fc_t11vfLocallyEnabledRowStatus->{$putinv};
			my $fc_t11vfLocallyEnabledStorageType_1=$fc_t11vfLocallyEnabledStorageType->{$putinv};
			$t11vflocallyenabledtable_sth->execute($deviceid,$scantime,$fc_t11vfLocallyEnabledPortIfIndex_1,$fc_t11vfLocallyEnabledVfId_1,$fc_t11vfLocallyEnabledOperStatus_1,$fc_t11vfLocallyEnabledRowStatus_1,$fc_t11vfLocallyEnabledStorageType_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11NsDatabaseFull){
			my $fc_t11NsInGetReqs_1=$fc_t11NsInGetReqs->{$putinv};
			my $fc_t11NsOutGetReqs_1=$fc_t11NsOutGetReqs->{$putinv};
			my $fc_t11NsInRegReqs_1=$fc_t11NsInRegReqs->{$putinv};
			my $fc_t11NsInDeRegReqs_1=$fc_t11NsInDeRegReqs->{$putinv};
			my $fc_t11NsInRscns_1=$fc_t11NsInRscns->{$putinv};
			my $fc_t11NsOutRscns_1=$fc_t11NsOutRscns->{$putinv};
			my $fc_t11NsRejects_1=$fc_t11NsRejects->{$putinv};
			my $fc_t11NsDatabaseFull_1=$fc_t11NsDatabaseFull->{$putinv};
			$t11nsstatstable_sth->execute($deviceid,$scantime,$fc_t11NsInGetReqs_1,$fc_t11NsOutGetReqs_1,$fc_t11NsInRegReqs_1,$fc_t11NsInDeRegReqs_1,$fc_t11NsInRscns_1,$fc_t11NsOutRscns_1,$fc_t11NsRejects_1,$fc_t11NsDatabaseFull_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsPortZoningEnfStatus){
			my $fc_t11FcsPortName_1=$fc_t11FcsPortName->{$putinv};
			my $fc_t11FcsPortType_1=$fc_t11FcsPortType->{$putinv};
			my $fc_t11FcsPortTxType_1=$fc_t11FcsPortTxType->{$putinv};
			my $fc_t11FcsPortModuleType_1=$fc_t11FcsPortModuleType->{$putinv};
			my $fc_t11FcsPortPhyPortNum_1=$fc_t11FcsPortPhyPortNum->{$putinv};
			my $fc_t11FcsPortAttachPortNameIndex_1=$fc_t11FcsPortAttachPortNameIndex->{$putinv};
			my $fc_t11FcsPortState_1=$fc_t11FcsPortState->{$putinv};
			my $fc_t11FcsPortSpeedCapab_1=$fc_t11FcsPortSpeedCapab->{$putinv};
			my $fc_t11FcsPortOperSpeed_1=$fc_t11FcsPortOperSpeed->{$putinv};
			my $fc_t11FcsPortZoningEnfStatus_1=$fc_t11FcsPortZoningEnfStatus->{$putinv};
			$t11fcsporttable_sth->execute($deviceid,$scantime,$fc_t11FcsPortName_1,$fc_t11FcsPortType_1,$fc_t11FcsPortTxType_1,$fc_t11FcsPortModuleType_1,$fc_t11FcsPortPhyPortNum_1,$fc_t11FcsPortAttachPortNameIndex_1,$fc_t11FcsPortState_1,$fc_t11FcsPortSpeedCapab_1,$fc_t11FcsPortOperSpeed_1,$fc_t11FcsPortZoningEnfStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmInstanceFabricId){
			my $fc_fcmInstanceIndex_1=$fc_fcmInstanceIndex->{$putinv};
			my $fc_fcmInstanceWwn_1=$fc_fcmInstanceWwn->{$putinv};
			my $fc_fcmInstanceFunctions_1=$fc_fcmInstanceFunctions->{$putinv};
			my $fc_fcmInstancePhysicalIndex_1=$fc_fcmInstancePhysicalIndex->{$putinv};
			my $fc_fcmInstanceSoftwareIndex_1=$fc_fcmInstanceSoftwareIndex->{$putinv};
			my $fc_fcmInstanceStatus_1=$fc_fcmInstanceStatus->{$putinv};
			my $fc_fcmInstanceTextName_1=$fc_fcmInstanceTextName->{$putinv};
			my $fc_fcmInstanceDescr_1=$fc_fcmInstanceDescr->{$putinv};
			my $fc_fcmInstanceFabricId_1=$fc_fcmInstanceFabricId->{$putinv};
			$fcminstancetable_sth->execute($deviceid,$scantime,$fc_fcmInstanceIndex_1,$fc_fcmInstanceWwn_1,$fc_fcmInstanceFunctions_1,$fc_fcmInstancePhysicalIndex_1,$fc_fcmInstanceSoftwareIndex_1,$fc_fcmInstanceStatus_1,$fc_fcmInstanceTextName_1,$fc_fcmInstanceDescr_1,$fc_fcmInstanceFabricId_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsActiveZoneMemberID){
			my $fc_t11ZsActiveZoneMemberIndex_1=$fc_t11ZsActiveZoneMemberIndex->{$putinv};
			my $fc_t11ZsActiveZoneMemberFormat_1=$fc_t11ZsActiveZoneMemberFormat->{$putinv};
			my $fc_t11ZsActiveZoneMemberID_1=$fc_t11ZsActiveZoneMemberID->{$putinv};
			$t11zsactivezonemembertable_sth->execute($deviceid,$scantime,$fc_t11ZsActiveZoneMemberIndex_1,$fc_t11ZsActiveZoneMemberFormat_1,$fc_t11ZsActiveZoneMemberID_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsAttachPortName){
			my $fc_t11FcsAttachPortNameListIndex_1=$fc_t11FcsAttachPortNameListIndex->{$putinv};
			my $fc_t11FcsAttachPortName_1=$fc_t11FcsAttachPortName->{$putinv};
			$t11fcsattachportnamelisttable_sth->execute($deviceid,$scantime,$fc_t11FcsAttachPortNameListIndex_1,$fc_t11FcsAttachPortName_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmPortLcClass3Discards){
			my $fc_fcmPortLcBBCreditZeros_1=$fc_fcmPortLcBBCreditZeros->{$putinv};
			my $fc_fcmPortLcFullInputBuffers_1=$fc_fcmPortLcFullInputBuffers->{$putinv};
			my $fc_fcmPortLcClass2RxFrames_1=$fc_fcmPortLcClass2RxFrames->{$putinv};
			my $fc_fcmPortLcClass2RxOctets_1=$fc_fcmPortLcClass2RxOctets->{$putinv};
			my $fc_fcmPortLcClass2TxFrames_1=$fc_fcmPortLcClass2TxFrames->{$putinv};
			my $fc_fcmPortLcClass2TxOctets_1=$fc_fcmPortLcClass2TxOctets->{$putinv};
			my $fc_fcmPortLcClass2Discards_1=$fc_fcmPortLcClass2Discards->{$putinv};
			my $fc_fcmPortLcClass2RxFbsyFrames_1=$fc_fcmPortLcClass2RxFbsyFrames->{$putinv};
			my $fc_fcmPortLcClass2RxPbsyFrames_1=$fc_fcmPortLcClass2RxPbsyFrames->{$putinv};
			my $fc_fcmPortLcClass2RxFrjtFrames_1=$fc_fcmPortLcClass2RxFrjtFrames->{$putinv};
			my $fc_fcmPortLcClass2RxPrjtFrames_1=$fc_fcmPortLcClass2RxPrjtFrames->{$putinv};
			my $fc_fcmPortLcClass2TxFbsyFrames_1=$fc_fcmPortLcClass2TxFbsyFrames->{$putinv};
			my $fc_fcmPortLcClass2TxPbsyFrames_1=$fc_fcmPortLcClass2TxPbsyFrames->{$putinv};
			my $fc_fcmPortLcClass2TxFrjtFrames_1=$fc_fcmPortLcClass2TxFrjtFrames->{$putinv};
			my $fc_fcmPortLcClass2TxPrjtFrames_1=$fc_fcmPortLcClass2TxPrjtFrames->{$putinv};
			my $fc_fcmPortLcClass3RxFrames_1=$fc_fcmPortLcClass3RxFrames->{$putinv};
			my $fc_fcmPortLcClass3RxOctets_1=$fc_fcmPortLcClass3RxOctets->{$putinv};
			my $fc_fcmPortLcClass3TxFrames_1=$fc_fcmPortLcClass3TxFrames->{$putinv};
			my $fc_fcmPortLcClass3TxOctets_1=$fc_fcmPortLcClass3TxOctets->{$putinv};
			my $fc_fcmPortLcClass3Discards_1=$fc_fcmPortLcClass3Discards->{$putinv};
			$fcmportlcstatstable_sth->execute($deviceid,$scantime,$fc_fcmPortLcBBCreditZeros_1,$fc_fcmPortLcFullInputBuffers_1,$fc_fcmPortLcClass2RxFrames_1,$fc_fcmPortLcClass2RxOctets_1,$fc_fcmPortLcClass2TxFrames_1,$fc_fcmPortLcClass2TxOctets_1,$fc_fcmPortLcClass2Discards_1,$fc_fcmPortLcClass2RxFbsyFrames_1,$fc_fcmPortLcClass2RxPbsyFrames_1,$fc_fcmPortLcClass2RxFrjtFrames_1,$fc_fcmPortLcClass2RxPrjtFrames_1,$fc_fcmPortLcClass2TxFbsyFrames_1,$fc_fcmPortLcClass2TxPbsyFrames_1,$fc_fcmPortLcClass2TxFrjtFrames_1,$fc_fcmPortLcClass2TxPrjtFrames_1,$fc_fcmPortLcClass3RxFrames_1,$fc_fcmPortLcClass3RxOctets_1,$fc_fcmPortLcClass3TxFrames_1,$fc_fcmPortLcClass3TxOctets_1,$fc_fcmPortLcClass3Discards_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmFLoginClass3DataFieldSize){
			my $fc_fcmFLoginNxPortIndex_1=$fc_fcmFLoginNxPortIndex->{$putinv};
			my $fc_fcmFLoginPortWwn_1=$fc_fcmFLoginPortWwn->{$putinv};
			my $fc_fcmFLoginNodeWwn_1=$fc_fcmFLoginNodeWwn->{$putinv};
			my $fc_fcmFLoginBbCreditModel_1=$fc_fcmFLoginBbCreditModel->{$putinv};
			my $fc_fcmFLoginBbCredit_1=$fc_fcmFLoginBbCredit->{$putinv};
			my $fc_fcmFLoginClassesAgreed_1=$fc_fcmFLoginClassesAgreed->{$putinv};
			my $fc_fcmFLoginClass2SeqDelivAgreed_1=$fc_fcmFLoginClass2SeqDelivAgreed->{$putinv};
			my $fc_fcmFLoginClass2DataFieldSize_1=$fc_fcmFLoginClass2DataFieldSize->{$putinv};
			my $fc_fcmFLoginClass3SeqDelivAgreed_1=$fc_fcmFLoginClass3SeqDelivAgreed->{$putinv};
			my $fc_fcmFLoginClass3DataFieldSize_1=$fc_fcmFLoginClass3DataFieldSize->{$putinv};
			$fcmflogintable_sth->execute($deviceid,$scantime,$fc_fcmFLoginNxPortIndex_1,$fc_fcmFLoginPortWwn_1,$fc_fcmFLoginNodeWwn_1,$fc_fcmFLoginBbCreditModel_1,$fc_fcmFLoginBbCredit_1,$fc_fcmFLoginClassesAgreed_1,$fc_fcmFLoginClass2SeqDelivAgreed_1,$fc_fcmFLoginClass2DataFieldSize_1,$fc_fcmFLoginClass3SeqDelivAgreed_1,$fc_fcmFLoginClass3DataFieldSize_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FspfLsrLinks){
			my $fc_t11FspfLsrDomainId_1=$fc_t11FspfLsrDomainId->{$putinv};
			my $fc_t11FspfLsrType_1=$fc_t11FspfLsrType->{$putinv};
			my $fc_t11FspfLsrAdvDomainId_1=$fc_t11FspfLsrAdvDomainId->{$putinv};
			my $fc_t11FspfLsrAge_1=$fc_t11FspfLsrAge->{$putinv};
			my $fc_t11FspfLsrIncarnationNumber_1=$fc_t11FspfLsrIncarnationNumber->{$putinv};
			my $fc_t11FspfLsrCheckSum_1=$fc_t11FspfLsrCheckSum->{$putinv};
			my $fc_t11FspfLsrLinks_1=$fc_t11FspfLsrLinks->{$putinv};
			$t11fspflsrtable_sth->execute($deviceid,$scantime,$fc_t11FspfLsrDomainId_1,$fc_t11FspfLsrType_1,$fc_t11FspfLsrAdvDomainId_1,$fc_t11FspfLsrAge_1,$fc_t11FspfLsrIncarnationNumber_1,$fc_t11FspfLsrCheckSum_1,$fc_t11FspfLsrLinks_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFeModuleName){
			my $fc_fcFeModuleIndex_1=$fc_fcFeModuleIndex->{$putinv};
			my $fc_fcFeModuleDescr_1=$fc_fcFeModuleDescr->{$putinv};
			my $fc_fcFeModuleObjectID_1=$fc_fcFeModuleObjectID->{$putinv};
			my $fc_fcFeModuleOperStatus_1=$fc_fcFeModuleOperStatus->{$putinv};
			my $fc_fcFeModuleLastChange_1=$fc_fcFeModuleLastChange->{$putinv};
			my $fc_fcFeModuleFxPortCapacity_1=$fc_fcFeModuleFxPortCapacity->{$putinv};
			my $fc_fcFeModuleName_1=$fc_fcFeModuleName->{$putinv};
			$fcfemoduletable_sth->execute($deviceid,$scantime,$fc_fcFeModuleIndex_1,$fc_fcFeModuleDescr_1,$fc_fcFeModuleObjectID_1,$fc_fcFeModuleOperStatus_1,$fc_fcFeModuleLastChange_1,$fc_fcFeModuleFxPortCapacity_1,$fc_fcFeModuleName_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsRejectReasonVendorCode){
			my $fc_t11ZsNotifyRequestRejectEnable_1=$fc_t11ZsNotifyRequestRejectEnable->{$putinv};
			my $fc_t11ZsNotifyMergeFailureEnable_1=$fc_t11ZsNotifyMergeFailureEnable->{$putinv};
			my $fc_t11ZsNotifyMergeSuccessEnable_1=$fc_t11ZsNotifyMergeSuccessEnable->{$putinv};
			my $fc_t11ZsNotifyDefZoneChangeEnable_1=$fc_t11ZsNotifyDefZoneChangeEnable->{$putinv};
			my $fc_t11ZsNotifyActivateEnable_1=$fc_t11ZsNotifyActivateEnable->{$putinv};
			my $fc_t11ZsRejectCtCommandString_1=$fc_t11ZsRejectCtCommandString->{$putinv};
			my $fc_t11ZsRejectRequestSource_1=$fc_t11ZsRejectRequestSource->{$putinv};
			my $fc_t11ZsRejectReasonCode_1=$fc_t11ZsRejectReasonCode->{$putinv};
			my $fc_t11ZsRejectReasonCodeExp_1=$fc_t11ZsRejectReasonCodeExp->{$putinv};
			my $fc_t11ZsRejectReasonVendorCode_1=$fc_t11ZsRejectReasonVendorCode->{$putinv};
			$t11zsnotifycontroltable_sth->execute($deviceid,$scantime,$fc_t11ZsNotifyRequestRejectEnable_1,$fc_t11ZsNotifyMergeFailureEnable_1,$fc_t11ZsNotifyMergeSuccessEnable_1,$fc_t11ZsNotifyDefZoneChangeEnable_1,$fc_t11ZsNotifyActivateEnable_1,$fc_t11ZsRejectCtCommandString_1,$fc_t11ZsRejectRequestSource_1,$fc_t11ZsRejectReasonCode_1,$fc_t11ZsRejectReasonCodeExp_1,$fc_t11ZsRejectReasonVendorCode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmISPortClassFDataFieldSize){
			my $fc_fcmISPortClassFCredit_1=$fc_fcmISPortClassFCredit->{$putinv};
			my $fc_fcmISPortClassFDataFieldSize_1=$fc_fcmISPortClassFDataFieldSize->{$putinv};
			$fcmisporttable_sth->execute($deviceid,$scantime,$fc_fcmISPortClassFCredit_1,$fc_fcmISPortClassFDataFieldSize_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11ZsZoneMemberRowStatus){
			my $fc_t11ZsZoneMemberParentType_1=$fc_t11ZsZoneMemberParentType->{$putinv};
			my $fc_t11ZsZoneMemberParentIndex_1=$fc_t11ZsZoneMemberParentIndex->{$putinv};
			my $fc_t11ZsZoneMemberIndex_1=$fc_t11ZsZoneMemberIndex->{$putinv};
			my $fc_t11ZsZoneMemberFormat_1=$fc_t11ZsZoneMemberFormat->{$putinv};
			my $fc_t11ZsZoneMemberID_1=$fc_t11ZsZoneMemberID->{$putinv};
			my $fc_t11ZsZoneMemberRowStatus_1=$fc_t11ZsZoneMemberRowStatus->{$putinv};
			$t11zszonemembertable_sth->execute($deviceid,$scantime,$fc_t11ZsZoneMemberParentType_1,$fc_t11ZsZoneMemberParentIndex_1,$fc_t11ZsZoneMemberIndex_1,$fc_t11ZsZoneMemberFormat_1,$fc_t11ZsZoneMemberID_1,$fc_t11ZsZoneMemberRowStatus_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcFxPortCapStackedConnMode){
			my $fc_fcFxPortCapFcphVersionHigh_1=$fc_fcFxPortCapFcphVersionHigh->{$putinv};
			my $fc_fcFxPortCapClass2SeqDeliv_1=$fc_fcFxPortCapClass2SeqDeliv->{$putinv};
			my $fc_fcFxPortCapClass3SeqDeliv_1=$fc_fcFxPortCapClass3SeqDeliv->{$putinv};
			my $fc_fcFxPortCapHoldTimeMax_1=$fc_fcFxPortCapHoldTimeMax->{$putinv};
			my $fc_fcFxPortCapHoldTimeMin_1=$fc_fcFxPortCapHoldTimeMin->{$putinv};
			my $fc_fcFxPortCapFcphVersionLow_1=$fc_fcFxPortCapFcphVersionLow->{$putinv};
			my $fc_fcFxPortCapBbCreditMax_1=$fc_fcFxPortCapBbCreditMax->{$putinv};
			my $fc_fcFxPortCapBbCreditMin_1=$fc_fcFxPortCapBbCreditMin->{$putinv};
			my $fc_fcFxPortCapRxDataFieldSizeMax_1=$fc_fcFxPortCapRxDataFieldSizeMax->{$putinv};
			my $fc_fcFxPortCapRxDataFieldSizeMin_1=$fc_fcFxPortCapRxDataFieldSizeMin->{$putinv};
			my $fc_fcFxPortCapCos_1=$fc_fcFxPortCapCos->{$putinv};
			my $fc_fcFxPortCapIntermix_1=$fc_fcFxPortCapIntermix->{$putinv};
			my $fc_fcFxPortCapStackedConnMode_1=$fc_fcFxPortCapStackedConnMode->{$putinv};
			$fcfxportcaptable_sth->execute($deviceid,$scantime,$fc_fcFxPortCapFcphVersionHigh_1,$fc_fcFxPortCapClass2SeqDeliv_1,$fc_fcFxPortCapClass3SeqDeliv_1,$fc_fcFxPortCapHoldTimeMax_1,$fc_fcFxPortCapHoldTimeMin_1,$fc_fcFxPortCapFcphVersionLow_1,$fc_fcFxPortCapBbCreditMax_1,$fc_fcFxPortCapBbCreditMin_1,$fc_fcFxPortCapRxDataFieldSizeMax_1,$fc_fcFxPortCapRxDataFieldSizeMin_1,$fc_fcFxPortCapCos_1,$fc_fcFxPortCapIntermix_1,$fc_fcFxPortCapStackedConnMode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcsRejectReasonVendorCode){
			my $fc_t11FcsReqRejectNotifyEnable_1=$fc_t11FcsReqRejectNotifyEnable->{$putinv};
			my $fc_t11FcsDiscoveryCompNotifyEnable_1=$fc_t11FcsDiscoveryCompNotifyEnable->{$putinv};
			my $fc_t11FcsMgmtAddrChangeNotifyEnable_1=$fc_t11FcsMgmtAddrChangeNotifyEnable->{$putinv};
			my $fc_t11FcsRejectCtCommandString_1=$fc_t11FcsRejectCtCommandString->{$putinv};
			my $fc_t11FcsRejectRequestSource_1=$fc_t11FcsRejectRequestSource->{$putinv};
			my $fc_t11FcsRejectReasonCode_1=$fc_t11FcsRejectReasonCode->{$putinv};
			my $fc_t11FcsRejectReasonCodeExp_1=$fc_t11FcsRejectReasonCodeExp->{$putinv};
			my $fc_t11FcsRejectReasonVendorCode_1=$fc_t11FcsRejectReasonVendorCode->{$putinv};
			$t11fcsnotifycontroltable_sth->execute($deviceid,$scantime,$fc_t11FcsReqRejectNotifyEnable_1,$fc_t11FcsDiscoveryCompNotifyEnable_1,$fc_t11FcsMgmtAddrChangeNotifyEnable_1,$fc_t11FcsRejectCtCommandString_1,$fc_t11FcsRejectRequestSource_1,$fc_t11FcsRejectReasonCode_1,$fc_t11FcsRejectReasonCodeExp_1,$fc_t11FcsRejectReasonVendorCode_1,$putinv);
		}
		foreach my $putinv (keys %$fc_fcmPortOperProtocols){
			my $fc_fcmPortInstanceIndex_1=$fc_fcmPortInstanceIndex->{$putinv};
			my $fc_fcmPortWwn_1=$fc_fcmPortWwn->{$putinv};
			my $fc_fcmPortNodeWwn_1=$fc_fcmPortNodeWwn->{$putinv};
			my $fc_fcmPortAdminType_1=$fc_fcmPortAdminType->{$putinv};
			my $fc_fcmPortOperType_1=$fc_fcmPortOperType->{$putinv};
			my $fc_fcmPortFcCapClass_1=$fc_fcmPortFcCapClass->{$putinv};
			my $fc_fcmPortFcOperClass_1=$fc_fcmPortFcOperClass->{$putinv};
			my $fc_fcmPortTransmitterType_1=$fc_fcmPortTransmitterType->{$putinv};
			my $fc_fcmPortConnectorType_1=$fc_fcmPortConnectorType->{$putinv};
			my $fc_fcmPortSerialNumber_1=$fc_fcmPortSerialNumber->{$putinv};
			my $fc_fcmPortPhysicalNumber_1=$fc_fcmPortPhysicalNumber->{$putinv};
			my $fc_fcmPortAdminSpeed_1=$fc_fcmPortAdminSpeed->{$putinv};
			my $fc_fcmPortCapProtocols_1=$fc_fcmPortCapProtocols->{$putinv};
			my $fc_fcmPortOperProtocols_1=$fc_fcmPortOperProtocols->{$putinv};
			$fcmporttable_sth->execute($deviceid,$scantime,$fc_fcmPortInstanceIndex_1,$fc_fcmPortWwn_1,$fc_fcmPortNodeWwn_1,$fc_fcmPortAdminType_1,$fc_fcmPortOperType_1,$fc_fcmPortFcCapClass_1,$fc_fcmPortFcOperClass_1,$fc_fcmPortTransmitterType_1,$fc_fcmPortConnectorType_1,$fc_fcmPortSerialNumber_1,$fc_fcmPortPhysicalNumber_1,$fc_fcmPortAdminSpeed_1,$fc_fcmPortCapProtocols_1,$fc_fcmPortOperProtocols_1,$putinv);
		}
		foreach my $putinv (keys %$fc_t11FcRouteFabricLastChange){
			my $fc_t11FcRouteFabricIndex_1=$fc_t11FcRouteFabricIndex->{$putinv};
			my $fc_t11FcRouteFabricLastChange_1=$fc_t11FcRouteFabricLastChange->{$putinv};
			$t11fcroutefabrictable_sth->execute($deviceid,$scantime,$fc_t11FcRouteFabricIndex_1,$fc_t11FcRouteFabricLastChange_1,$putinv);
		}
##Now do Vendor specific inventory based on the type of FC Switch
		my $vendortype = $info->description();
		if ($vendortype =~ /mds/i || $vendortype =~ /NX-OS/i) {
#Do Cisco MDS Inventory
			my $cfccporttable_sth = $mysql->prepare_cached("INSERT INTO cfccporttable(deviceid,scantime,fc_cFCCEdgeQuenchPktsRecd,fc_cFCCEdgeQuenchPktsSent,fc_cFCCPathQuenchPktsRecd,fc_cFCCPathQuenchPktsSent,fc_cFCCCurrentCongestionState,fc_cFCCLastCongestedTime,fc_cFCCLastCongestionStartTime,fc_cFCCIsRateLimitingApplied,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
			my $cfmmulticastroottable_sth = $mysql->prepare_cached("INSERT INTO cfmmulticastroottable(deviceid,scantime,fc_cfmMulticastRootConfigMode,fc_cfmMulticastRootOperMode,fc_cfmMulticastRootDomainId,fc_cfmMulticastRootRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $ciscoscsiintrprttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiintrprttable(deviceid,scantime,fc_ciscoScsiIntrPrtName,fc_ciscoScsiIntrPrtIdentifier,fc_ciscoScsiIntrPrtOutCommands,fc_ciscoScsiIntrPrtWrMegaBytes,fc_ciscoScsiIntrPrtReadMegaBytes,fc_ciscoScsiIntrPrtHSOutCommands,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $csanbasesvcinterfacetable_sth = $mysql->prepare_cached("INSERT INTO csanbasesvcinterfacetable(deviceid,scantime,fc_cSanBaseSvcInterfaceIndex,fc_cSanBaseSvcInterfaceState,fc_cSanBaseSvcInterfaceClusterId,fc_cSanBaseSvcInterfaceStorageType,fc_cSanBaseSvcInterfaceRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $ciscoscsitgtporttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsitgtporttable(deviceid,scantime,fc_ciscoScsiTgtPortName,fc_ciscoScsiTgtPortIdentifier,fc_ciscoScsiTgtPortInCommands,fc_ciscoScsiTgtPortWrMegaBytes,fc_ciscoScsiTgtPortReadMegaBytes,fc_ciscoScsiTgtPortHSInCommands,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $ciscoscsilutable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsilutable(deviceid,scantime,fc_ciscoScsiLuIndex,fc_ciscoScsiLuDefaultLun,fc_ciscoScsiLuWwnName,fc_ciscoScsiLuVendorId,fc_ciscoScsiLuProductId,fc_ciscoScsiLuRevisionId,fc_ciscoScsiLuPeripheralType,fc_ciscoScsiLuStatus,fc_ciscoScsiLuState,fc_ciscoScsiLuInCommands,fc_ciscoScsiLuReadMegaBytes,fc_ciscoScsiLuWrittenMegaBytes,fc_ciscoScsiLuInResets,fc_ciscoScsiLuOutQueueFullStatus,fc_ciscoScsiLuHSInCommands,fc_ciscoScsiLuIdIndex,fc_ciscoScsiLuIdCodeSet,fc_ciscoScsiLuIdAssociation,fc_ciscoScsiLuIdType,fc_ciscoScsiLuIdValue,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cfcsdvvirtrealdevmaptable_sth = $mysql->prepare_cached("INSERT INTO cfcsdvvirtrealdevmaptable(deviceid,scantime,fc_cFcSdvVirtRealDevMapIndex,fc_cFcSdvVirtRealDeviceIdType,fc_cFcSdvVirtRealDeviceId,fc_cFcSdvVirtRealDevMapType,fc_cFcSdvVirtRealDevMapStorageType,fc_cFcSdvVirtRealDevMapRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $fcsplatformtable_sth = $mysql->prepare_cached("INSERT INTO fcsplatformtable(deviceid,scantime,fc_fcsPlatformIndex,fc_fcsPlatformName,fc_fcsPlatformType,fc_fcsPlatformNodeNameListIndex,fc_fcsPlatformMgmtAddrListIndex,fc_fcsPlatformConfigSource,fc_fcsPlatformValidation,fc_fcsPlatformValidationResult,fc_fcsPlatformRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			my $csanbasesvcclustermemberiftable_sth = $mysql->prepare_cached("INSERT INTO csanbasesvcclustermemberiftable(deviceid,scantime,fc_cSanBaseSvcClusterInterfaceIndex,fc_cSanBaseSvcClusterInterfaceState,snmpindex) VALUES (?,?,?,?,?)");
			my $fcsmgmtaddrlisttable_sth = $mysql->prepare_cached("INSERT INTO fcsmgmtaddrlisttable(deviceid,scantime,fc_fcsMgmtAddrListIndex,fc_fcsMgmtAddrIndex,fc_fcsMgmtAddr,fc_fcsMgmtAddrConfigSource,fc_fcsMgmtAddrRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $cspanvsanfiltertable_sth = $mysql->prepare_cached("INSERT INTO cspanvsanfiltertable(deviceid,scantime,fc_cspanVsanFilterSessIndex,fc_cspanVsanFilterVsans2k,fc_cspanVsanFilterVsans4k,snmpindex) VALUES (?,?,?,?,?,?)");
			my $ciscoscsiflowtable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiflowtable(deviceid,scantime,fc_ciscoScsiFlowId,fc_ciscoScsiFlowIntrWwn,fc_ciscoScsiFlowTargetWwn,fc_ciscoScsiFlowIntrVsan,fc_ciscoScsiFlowTargetVsan,fc_ciscoScsiFlowAllLuns,fc_ciscoScsiFlowWriteAcc,fc_ciscoScsiFlowBufCount,fc_ciscoScsiFlowStatsEnabled,fc_ciscoScsiFlowClearStats,fc_ciscoScsiFlowIntrVrfStatus,fc_ciscoScsiFlowTgtVrfStatus,fc_ciscoScsiFlowIntrLCStatus,fc_ciscoScsiFlowTgtLCStatus,fc_ciscoScsiFlowRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcsnodenamelisttable_sth = $mysql->prepare_cached("INSERT INTO fcsnodenamelisttable(deviceid,scantime,fc_fcsNodeNameListIndex,fc_fcsNodeName,fc_fcsNodeNameConfigSource,fc_fcsNodeNameRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $cfcsdvvirtdevicetable_sth = $mysql->prepare_cached("INSERT INTO cfcsdvvirtdevicetable(deviceid,scantime,fc_cFcSdvVdIndex,fc_cFcSdvVdName,fc_cFcSdvVdVirtDomain,fc_cFcSdvVdFcId,fc_cFcSdvVdPwwn,fc_cFcSdvVdNwwn,fc_cFcSdvVdAssignedFcId,fc_cFcSdvVdRealDevMapList,fc_cFcSdvVdStorageType,fc_cFcSdvVdRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cstserviceconfigtable_sth = $mysql->prepare_cached("INSERT INTO cstserviceconfigtable(deviceid,scantime,fc_cstCVTNodeWwn,fc_cstCVTPortWwn,fc_cstServiceConfigRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $ciscoscsiattintrprttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiattintrprttable(deviceid,scantime,fc_ciscoScsiAttIntrPrtIdx,fc_ciscoScsiAttIntrPrtAuthIntrIdx,fc_ciscoScsiAttIntrPrtName,fc_ciscoScsiAttIntrPrtId,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $ciscoscsiintrdevtable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiintrdevtable(deviceid,scantime,fc_ciscoScsiIntrDevAccMode,fc_ciscoScsiIntrDevOutResets,snmpindex) VALUES (?,?,?,?,?)");
			my $cspansourcesvsantable_sth = $mysql->prepare_cached("INSERT INTO cspansourcesvsantable(deviceid,scantime,fc_cspanSourcesVsans2k,fc_cspanSourcesVsans4k,snmpindex) VALUES (?,?,?,?,?)");
			my $ciscoextscsigeninstancetable_sth = $mysql->prepare_cached("INSERT INTO ciscoextscsigeninstancetable(deviceid,scantime,fc_ciscoExtScsiDiskGrpId,fc_ciscoExtScsiLineCardOrSup,snmpindex) VALUES (?,?,?,?,?)");
			my $fcsstatstable_sth = $mysql->prepare_cached("INSERT INTO fcsstatstable(deviceid,scantime,fc_fcsRxGetReqs,fc_fcsTxGetReqs,fc_fcsRxRegReqs,fc_fcsTxRegReqs,fc_fcsRxDeregReqs,fc_fcsTxDeregReqs,fc_fcsTxRscns,fc_fcsRxRscns,fc_fcsRejects,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcroutetable_sth = $mysql->prepare_cached("INSERT INTO fcroutetable(deviceid,scantime,fc_fcRouteDestAddrId,fc_fcRouteDestMask,fc_fcRouteProto,fc_fcRouteInterface,fc_fcRouteDomainId,fc_fcRouteMetric,fc_fcRouteType,fc_fcRoutePermanent,fc_fcRouteRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fciftable_sth = $mysql->prepare_cached("INSERT INTO fciftable(deviceid,scantime,fc_fcIfWwn,fc_fcIfAdminMode,fc_fcIfOperMode,fc_fcIfAdminSpeed,fc_fcIfBeaconMode,fc_fcIfPortChannelIfIndex,fc_fcIfOperStatusCause,fc_fcIfOperStatusCauseDescr,fc_fcIfAdminTrunkMode,fc_fcIfOperTrunkMode,fc_fcIfAllowedVsanList2k,fc_fcIfAllowedVsanList4k,fc_fcIfActiveVsanList2k,fc_fcIfActiveVsanList4k,fc_fcIfBbCreditModel,fc_fcIfHoldTime,fc_fcIfTransmitterType,fc_fcIfConnectorType,fc_fcIfSerialNo,fc_fcIfRevision,fc_fcIfVendor,fc_fcIfSFPSerialIDData,fc_fcIfPartNumber,fc_fcIfAdminRxBbCredit,fc_fcIfAdminRxBbCreditModeISL,fc_fcIfAdminRxBbCreditModeFx,fc_fcIfOperRxBbCredit,fc_fcIfRxDataFieldSize,fc_fcIfActiveVsanUpList2k,fc_fcIfActiveVsanUpList4k,fc_fcIfPortRateMode,fc_fcIfAdminRxPerfBuffer,fc_fcIfOperRxPerfBuffer,fc_fcIfBbScn,fc_fcIfPortInitStatus,fc_fcIfAdminRxBbCreditExtended,fc_fcIfFcTunnelIfIndex,fc_fcIfServiceState,fc_fcIfAdminBbScnMode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cfcspifstatstable_sth = $mysql->prepare_cached("INSERT INTO cfcspifstatstable(deviceid,scantime,fc_cfcspIfAuthSucceeded,fc_cfcspIfAuthFailed,fc_cfcspIfAuthByPassed,snmpindex) VALUES (?,?,?,?,?,?)");
			my $virtualnwiftable_sth = $mysql->prepare_cached("INSERT INTO virtualnwiftable(deviceid,scantime,fc_virtualNwIfType,fc_virtualNwIfId,fc_virtualNwIfIndex,fc_virtualNwIfFcId,fc_virtualNwIfOperStatusCause,fc_virtualNwIfOperStatusCauseDescr,fc_virtualNwIfRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $fciferrortable_sth = $mysql->prepare_cached("INSERT INTO fciferrortable(deviceid,scantime,fc_fcIfLinkFailures,fc_fcIfSyncLosses,fc_fcIfSigLosses,fc_fcIfPrimSeqProtoErrors,fc_fcIfInvalidTxWords,fc_fcIfInvalidCrcs,fc_fcIfDelimiterErrors,fc_fcIfAddressIdErrors,fc_fcIfLinkResetIns,fc_fcIfLinkResetOuts,fc_fcIfOlsIns,fc_fcIfOlsOuts,fc_fcIfRuntFramesIn,fc_fcIfJabberFramesIn,fc_fcIfTxWaitCount,fc_fcIfFramesTooLong,fc_fcIfFramesTooShort,fc_fcIfLRRIn,fc_fcIfLRROut,fc_fcIfNOSIn,fc_fcIfNOSOut,fc_fcIfFragFrames,fc_fcIfEOFaFrames,fc_fcIfUnknownClassFrames,fc_fcIf8b10bDisparityErrors,fc_fcIfFramesDiscard,fc_fcIfELPFailures,fc_fcIfBBCreditTransistionFromZero,fc_fcIfEISLFramesDiscard,fc_fcIfFramingErrorFrames,fc_fcIfLipF8In,fc_fcIfLipF8Out,fc_fcIfNonLipF8In,fc_fcIfNonLipF8Out,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fctraceroutehopstable_sth = $mysql->prepare_cached("INSERT INTO fctraceroutehopstable(deviceid,scantime,fc_fcTraceRouteHopsHopIndex,fc_fcTraceRouteHopsHopAddr,fc_fcTraceRouteHopsHopLatencyValid,fc_fcTraceRouteHopsHopLatency,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $ciscoscsiauthorizedintrtable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiauthorizedintrtable(deviceid,scantime,fc_ciscoScsiAuthIntrTgtPortIndex,fc_ciscoScsiAuthIntrIndex,fc_ciscoScsiAuthIntrDevOrPort,fc_ciscoScsiAuthIntrName,fc_ciscoScsiAuthIntrLunMapIndex,fc_ciscoScsiAuthIntrAttachedTimes,fc_ciscoScsiAuthIntrOutCommands,fc_ciscoScsiAuthIntrReadMegaBytes,fc_ciscoScsiAuthIntrWrMegaBytes,fc_ciscoScsiAuthIntrHSOutCommands,fc_ciscoScsiAuthIntrLastCreation,fc_ciscoScsiAuthIntrRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cstmoduletable_sth = $mysql->prepare_cached("INSERT INTO cstmoduletable(deviceid,scantime,fc_cstModuleId,snmpindex) VALUES (?,?,?,?)");
			my $fcifelptable_sth = $mysql->prepare_cached("INSERT INTO fcifelptable(deviceid,scantime,fc_fcIfElpNbrNodeName,fc_fcIfElpNbrPortName,fc_fcIfElpRxBbCredit,fc_fcIfElpTxBbCredit,fc_fcIfElpCosSuppAgreed,fc_fcIfElpClass2SeqDelivAgreed,fc_fcIfElpClass2RxDataFieldSize,fc_fcIfElpClass3SeqDelivAgreed,fc_fcIfElpClass3RxDataFieldSize,fc_fcIfElpClassFXII,fc_fcIfElpClassFRxDataFieldSize,fc_fcIfElpClassFConcurrentSeq,fc_fcIfElpClassFEndToEndCredit,fc_fcIfElpClassFOpenSeq,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcpingstatstable_sth = $mysql->prepare_cached("INSERT INTO fcpingstatstable(deviceid,scantime,fc_fcPingTxPackets,fc_fcPingRxPackets,fc_fcPingMinRtt,fc_fcPingAvgRtt,fc_fcPingMaxRtt,fc_fcPingNumTimeouts,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $ciscoscsidsctgttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsidsctgttable(deviceid,scantime,fc_ciscoScsiDscTgtIntrPortIndex,fc_ciscoScsiDscTgtIndex,fc_ciscoScsiDscTgtDevOrPort,fc_ciscoScsiDscTgtName,fc_ciscoScsiDscTgtConfigured,fc_ciscoScsiDscTgtDiscovered,fc_ciscoScsiDscTgtInCommands,fc_ciscoScsiDscTgtWrMegaBytes,fc_ciscoScsiDscTgtReadMegaBytes,fc_ciscoScsiDscTgtHSInCommands,fc_ciscoScsiDscTgtLastCreation,fc_ciscoScsiDscTgtRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cspansourcesiftable_sth = $mysql->prepare_cached("INSERT INTO cspansourcesiftable(deviceid,scantime,fc_cspanSourcesIfIndex,fc_cspanSourcesDirection,fc_cspanSourcesRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $fcifc2accountingtable_sth = $mysql->prepare_cached("INSERT INTO fcifc2accountingtable(deviceid,scantime,fc_fcIfC2InFrames,fc_fcIfC2OutFrames,fc_fcIfC2InOctets,fc_fcIfC2OutOctets,fc_fcIfC2Discards,fc_fcIfC2FbsyFrames,fc_fcIfC2FrjtFrames,fc_fcIfC2PBSYFrames,fc_fcIfC2PRJTFrames,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsidscluntable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsidscluntable(deviceid,scantime,fc_ciscoScsiDscLunIndex,fc_ciscoScsiDscLunLun,snmpindex) VALUES (?,?,?,?,?)");
			my $fcifcaptable_sth = $mysql->prepare_cached("INSERT INTO fcifcaptable(deviceid,scantime,fc_fcIfCapFcphVersionHigh,fc_fcIfCapFcphVersionLow,fc_fcIfCapRxBbCreditMax,fc_fcIfCapRxBbCreditMin,fc_fcIfCapRxDataFieldSizeMax,fc_fcIfCapRxDataFieldSizeMin,fc_fcIfCapCos,fc_fcIfCapClass2SeqDeliv,fc_fcIfCapClass3SeqDeliv,fc_fcIfCapHoldTimeMax,fc_fcIfCapHoldTimeMin,fc_fcIfCapISLRxBbCreditMax,fc_fcIfCapISLRxBbCreditMin,fc_fcIfCapRxBbCreditWriteable,fc_fcIfCapRxBbCreditDefault,fc_fcIfCapISLRxBbCreditDefault,fc_fcIfCapBbScnCapable,fc_fcIfCapBbScnMax,fc_fcIfCapOsmFrmCapable,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fctraceroutetable_sth = $mysql->prepare_cached("INSERT INTO fctraceroutetable(deviceid,scantime,fc_fcTraceRouteIndex,fc_fcTraceRouteVsanIndex,fc_fcTraceRouteTargetAddrType,fc_fcTraceRouteTargetAddr,fc_fcTraceRouteTimeout,fc_fcTraceRouteAdminStatus,fc_fcTraceRouteOperStatus,fc_fcTraceRouteAgeInterval,fc_fcTraceRouteTrapOnCompletion,fc_fcTraceRouteRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcifflogintable_sth = $mysql->prepare_cached("INSERT INTO fcifflogintable(deviceid,scantime,fc_fcIfNxLoginIndex,fc_fcIfNxPortNodeName,fc_fcIfNxPortName,fc_fcIfNxPortAddress,fc_fcIfNxFcphVersionAgreed,fc_fcIfNxRxBbCredit,fc_fcIfNxTxBbCredit,fc_fcIfNxClass2RxDataFieldSize,fc_fcIfNxClass3RxDataFieldSize,fc_fcIfNxCosSuppAgreed,fc_fcIfNxClass2SeqDelivAgreed,fc_fcIfNxClass3SeqDelivAgreed,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $ciscoextscsiintrdisctgttable_sth = $mysql->prepare_cached("INSERT INTO ciscoextscsiintrdisctgttable(deviceid,scantime,fc_ciscoExtScsiIntrDiscTgtVsanId,fc_ciscoExtScsiIntrDiscTgtDevType,fc_ciscoExtScsiIntrDiscTgtVendorId,fc_ciscoExtScsiIntrDiscTgtProductId,fc_ciscoExtScsiIntrDiscTgtRevLevel,fc_ciscoExtScsiIntrDiscTgtOtherInfo,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $fcifcfaccountingtable_sth = $mysql->prepare_cached("INSERT INTO fcifcfaccountingtable(deviceid,scantime,fc_fcIfCfInFrames,fc_fcIfCfOutFrames,fc_fcIfCfInOctets,fc_fcIfCfOutOctets,fc_fcIfCfDiscards,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $fcsporttable_sth = $mysql->prepare_cached("INSERT INTO fcsporttable(deviceid,scantime,fc_fcsPortName,fc_fcsPortType,fc_fcsPortTXType,fc_fcsPortModuleType,fc_fcsPortPhyPortNum,fc_fcsPortAttachPortNameIndex,fc_fcsPortState,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsitgtdevtable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsitgtdevtable(deviceid,scantime,fc_ciscoScsiTgtDevNumberOfLUs,fc_ciscoScsiTgtDeviceStatus,fc_ciscoScsiTgtDevNonAccLUs,snmpindex) VALUES (?,?,?,?,?,?)");
			my $fctrunkiftable_sth = $mysql->prepare_cached("INSERT INTO fctrunkiftable(deviceid,scantime,fc_fcTrunkIfOperStatus,fc_fcTrunkIfOperStatusCause,fc_fcTrunkIfOperStatusCauseDescr,snmpindex) VALUES (?,?,?,?,?,?)");
			my $cfcsplocalpasswdtable_sth = $mysql->prepare_cached("INSERT INTO cfcsplocalpasswdtable(deviceid,scantime,fc_cfcspSwitchWwn,fc_cfcspLocalPasswd,fc_cfcspLocalPassRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $ciscoscsidsclunidtable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsidsclunidtable(deviceid,scantime,fc_ciscoScsiDscLunIdIndex,fc_ciscoScsiDscLunIdCodeSet,fc_ciscoScsiDscLunIdAssociation,fc_ciscoScsiDscLunIdType,fc_ciscoScsiDscLunIdValue,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $cfcspremotepasswdtable_sth = $mysql->prepare_cached("INSERT INTO cfcspremotepasswdtable(deviceid,scantime,fc_cfcspRemoteSwitchWwn,fc_cfcspRemotePasswd,fc_cfcspRemotePassRowStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $fcifstattable_sth = $mysql->prepare_cached("INSERT INTO fcifstattable(deviceid,scantime,fc_fcIfCurrRxBbCredit,fc_fcIfCurrTxBbCredit,snmpindex) VALUES (?,?,?,?,?)");
			my $cspansessiontable_sth = $mysql->prepare_cached("INSERT INTO cspansessiontable(deviceid,scantime,fc_cspanSessionIndex,fc_cspanSessionDestIfIndex,fc_cspanSessionAdminStatus,fc_cspanSessionOperStatus,fc_cspanSessionInactiveReason,fc_cspanSessionRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?)");
			my $fcsdiscoverystatustable_sth = $mysql->prepare_cached("INSERT INTO fcsdiscoverystatustable(deviceid,scantime,fc_fcsDiscoveryStatus,fc_fcsDiscoveryCompleteTime,snmpindex) VALUES (?,?,?,?,?)");
			my $cfcspiftable_sth = $mysql->prepare_cached("INSERT INTO cfcspiftable(deviceid,scantime,fc_cfcspMode,fc_cfcspReauthInterval,fc_cfcspReauthenticate,snmpindex) VALUES (?,?,?,?,?,?)");
			my $ciscoscsitrnspttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsitrnspttable(deviceid,scantime,fc_ciscoScsiTrnsptIndex,fc_ciscoScsiTrnsptType,fc_ciscoScsiTrnsptPointer,fc_ciscoScsiTrnsptDevName,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $ciscoscsiflowwraccstatustable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiflowwraccstatustable(deviceid,scantime,fc_ciscoScsiFlowWrAccCfgStatus,fc_ciscoScsiFlowWrAccIntrCfgStatus,fc_ciscoScsiFlowWrAccTgtCfgStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $fcpingtable_sth = $mysql->prepare_cached("INSERT INTO fcpingtable(deviceid,scantime,fc_fcPingIndex,fc_fcPingVsanIndex,fc_fcPingAddressType,fc_fcPingAddress,fc_fcPingPacketCount,fc_fcPingPayloadSize,fc_fcPingPacketTimeout,fc_fcPingDelay,fc_fcPingAgeInterval,fc_fcPingUsrPriority,fc_fcPingAdminStatus,fc_fcPingOperStatus,fc_fcPingTrapOnCompletion,fc_fcPingRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsiflowstatsstatustable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiflowstatsstatustable(deviceid,scantime,fc_ciscoScsiFlowStatsCfgStatus,fc_ciscoScsiFlowStatsIntrCfgStatus,fc_ciscoScsiFlowStatsTgtCfgStatus,snmpindex) VALUES (?,?,?,?,?,?)");
			my $ciscoextscsiintrdisclunstable_sth = $mysql->prepare_cached("INSERT INTO ciscoextscsiintrdisclunstable(deviceid,scantime,fc_ciscoExtScsiIntrDiscLunCapacity,fc_ciscoExtScsiIntrDiscLunNumber,fc_ciscoExtScsiIntrDiscLunSerialNum,fc_ciscoExtScsiIntrDiscLunOs,fc_ciscoExtScsiIntrDiscLunPortId,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $cspanvsanfilteroptable_sth = $mysql->prepare_cached("INSERT INTO cspanvsanfilteroptable(deviceid,scantime,fc_cspanVsanFilterOpSessIndex,fc_cspanVsanFilterOpCommand,fc_cspanVsanFilterOpVsans2k,fc_cspanVsanFilterOpVsans4k,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $fcifc3accountingtable_sth = $mysql->prepare_cached("INSERT INTO fcifc3accountingtable(deviceid,scantime,fc_fcIfC3InFrames,fc_fcIfC3OutFrames,fc_fcIfC3InOctets,fc_fcIfC3OutOctets,fc_fcIfC3Discards,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $fcifrnidinfotable_sth = $mysql->prepare_cached("INSERT INTO fcifrnidinfotable(deviceid,scantime,fc_fcIfRNIDInfoStatus,fc_fcIfRNIDInfoTypeNumber,fc_fcIfRNIDInfoModelNumber,fc_fcIfRNIDInfoManufacturer,fc_fcIfRNIDInfoPlantOfMfg,fc_fcIfRNIDInfoSerialNumber,fc_fcIfRNIDInfoUnitType,fc_fcIfRNIDInfoPortId,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
			my $fcifgigetable_sth = $mysql->prepare_cached("INSERT INTO fcifgigetable(deviceid,scantime,fc_fcIfGigEPortChannelIfIndex,fc_fcIfGigEAutoNegotiate,fc_fcIfGigEBeaconMode,snmpindex) VALUES (?,?,?,?,?,?)");
			my $cfdmihbainfotable_sth = $mysql->prepare_cached("INSERT INTO cfdmihbainfotable(deviceid,scantime,fc_cfdmiHbaInfoId,fc_cfdmiHbaInfoNodeName,fc_cfdmiHbaInfoMfg,fc_cfdmiHbaInfoSn,fc_cfdmiHbaInfoModel,fc_cfdmiHbaInfoModelDescr,fc_cfdmiHbaInfoHwVer,fc_cfdmiHbaInfoDriverVer,fc_cfdmiHbaInfoOptROMVer,fc_cfdmiHbaInfoFwVer,fc_cfdmiHbaInfoOSInfo,fc_cfdmiHbaInfoMaxCTPayload,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcifcaposmtable_sth = $mysql->prepare_cached("INSERT INTO fcifcaposmtable(deviceid,scantime,fc_fcIfCapOsmRxBbCreditWriteable,fc_fcIfCapOsmRxBbCreditMax,fc_fcIfCapOsmRxBbCreditMin,fc_fcIfCapOsmRxBbCreditDefault,fc_fcIfCapOsmISLRxBbCreditMax,fc_fcIfCapOsmISLRxBbCreditMin,fc_fcIfCapOsmISLRxBbCreditDefault,fc_fcIfCapOsmRxPerfBufWriteable,fc_fcIfCapOsmRxPerfBufMax,fc_fcIfCapOsmRxPerfBufMin,fc_fcIfCapOsmRxPerfBufDefault,fc_fcIfCapOsmISLRxPerfBufMax,fc_fcIfCapOsmISLRxPerfBufMin,fc_fcIfCapOsmISLRxPerfBufDefault,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $cfdaconfigtable_sth = $mysql->prepare_cached("INSERT INTO cfdaconfigtable(deviceid,scantime,fc_cfdaConfigDeviceAlias,fc_cfdaConfigDeviceType,fc_cfdaConfigDeviceId,fc_cfdaConfigRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $csanbasesvcdeviceporttable_sth = $mysql->prepare_cached("INSERT INTO csanbasesvcdeviceporttable(deviceid,scantime,fc_cSanBaseSvcDevicePortName,fc_cSanBaseSvcDevicePortClusterId,fc_cSanBaseSvcDevicePortStorageType,fc_cSanBaseSvcDevicePortRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $ciscoscsiporttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiporttable(deviceid,scantime,fc_ciscoScsiPortIndex,fc_ciscoScsiPortRole,fc_ciscoScsiPortTrnsptPtr,fc_ciscoScsiPortBusyStatuses,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $csanbasesvcclustermemberstable_sth = $mysql->prepare_cached("INSERT INTO csanbasesvcclustermemberstable(deviceid,scantime,fc_cSanBaseSvcClusterMemberInetAddrType,fc_cSanBaseSvcClusterMemberInetAddr,fc_cSanBaseSvcClusterMemberFabric,fc_cSanBaseSvcClusterMemberIsLocal,fc_cSanBaseSvcClusterMemberIsMaster,fc_cSanBaseSvcClusterMemberStorageType,fc_cSanBaseSvcClusterMemberRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsiinstancetable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiinstancetable(deviceid,scantime,fc_ciscoScsiInstIndex,fc_ciscoScsiInstAlias,fc_ciscoScsiInstSoftwareIndex,fc_ciscoScsiInstVendorVersion,fc_ciscoScsiInstNotifEnable,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $fcifcapfrmtable_sth = $mysql->prepare_cached("INSERT INTO fcifcapfrmtable(deviceid,scantime,fc_fcIfCapFrmRxBbCreditWriteable,fc_fcIfCapFrmRxBbCreditMax,fc_fcIfCapFrmRxBbCreditMin,fc_fcIfCapFrmRxBbCreditDefault,fc_fcIfCapFrmISLRxBbCreditMax,fc_fcIfCapFrmISLRxBbCreditMin,fc_fcIfCapFrmISLRxBbCreditDefault,fc_fcIfCapFrmRxPerfBufWriteable,fc_fcIfCapFrmRxPerfBufMax,fc_fcIfCapFrmRxPerfBufMin,fc_fcIfCapFrmRxPerfBufDefault,fc_fcIfCapFrmISLRxPerfBufMax,fc_fcIfCapFrmISLRxPerfBufMin,fc_fcIfCapFrmISLRxPerfBufDefault,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcsattachportnamelisttable_sth = $mysql->prepare_cached("INSERT INTO fcsattachportnamelisttable(deviceid,scantime,fc_fcsAttachPortNameListIndex,fc_fcsAttachPortName,snmpindex) VALUES (?,?,?,?,?)");
			my $ciscoscsiflowstatstable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiflowstatstable(deviceid,scantime,fc_ciscoScsiFlowLunId,fc_ciscoScsiFlowRdIos,fc_ciscoScsiFlowRdFailedIos,fc_ciscoScsiFlowRdTimeouts,fc_ciscoScsiFlowRdBlocks,fc_ciscoScsiFlowRdMaxBlocks,fc_ciscoScsiFlowRdMinTime,fc_ciscoScsiFlowRdMaxTime,fc_ciscoScsiFlowRdsActive,fc_ciscoScsiFlowWrIos,fc_ciscoScsiFlowWrFailedIos,fc_ciscoScsiFlowWrTimeouts,fc_ciscoScsiFlowWrBlocks,fc_ciscoScsiFlowWrMaxBlocks,fc_ciscoScsiFlowWrMinTime,fc_ciscoScsiFlowWrMaxTime,fc_ciscoScsiFlowWrsActive,fc_ciscoScsiFlowTestUnitRdys,fc_ciscoScsiFlowRepLuns,fc_ciscoScsiFlowInquirys,fc_ciscoScsiFlowRdCapacitys,fc_ciscoScsiFlowModeSenses,fc_ciscoScsiFlowReqSenses,fc_ciscoScsiFlowRxFc2Frames,fc_ciscoScsiFlowTxFc2Frames,fc_ciscoScsiFlowRxFc2Octets,fc_ciscoScsiFlowTxFc2Octets,fc_ciscoScsiFlowBusyStatuses,fc_ciscoScsiFlowStatusResvConfs,fc_ciscoScsiFlowTskSetFulStatuses,fc_ciscoScsiFlowAcaActiveStatuses,fc_ciscoScsiFlowSenseKeyNotRdyErrs,fc_ciscoScsiFlowSenseKeyMedErrs,fc_ciscoScsiFlowSenseKeyHwErrs,fc_ciscoScsiFlowSenseKeyIllReqErrs,fc_ciscoScsiFlowSenseKeyUnitAttErrs,fc_ciscoScsiFlowSenseKeyDatProtErrs,fc_ciscoScsiFlowSenseKeyBlankErrs,fc_ciscoScsiFlowSenseKeyCpAbrtErrs,fc_ciscoScsiFlowSenseKeyAbrtCmdErrs,fc_ciscoScsiFlowSenseKeyVolFlowErrs,fc_ciscoScsiFlowSenseKeyMiscmpErrs,fc_ciscoScsiFlowAbts,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsidevicetable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsidevicetable(deviceid,scantime,fc_ciscoScsiDeviceIndex,fc_ciscoScsiDeviceAlias,fc_ciscoScsiDeviceRole,fc_ciscoScsiDevicePortNumber,fc_ciscoScsiDeviceResets,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $ciscoextscsipartiallundisctable_sth = $mysql->prepare_cached("INSERT INTO ciscoextscsipartiallundisctable(deviceid,scantime,fc_ciscoExtScsiPartialLunDomId,fc_ciscoExtScsiPartialLunRowStatus,snmpindex) VALUES (?,?,?,?,?)");
			my $csanbasesvcclustertable_sth = $mysql->prepare_cached("INSERT INTO csanbasesvcclustertable(deviceid,scantime,fc_cSanBaseSvcClusterId,fc_cSanBaseSvcClusterName,fc_cSanBaseSvcClusterState,fc_cSanBaseSvcClusterMasterInetAddrType,fc_cSanBaseSvcClusterMasterInetAddr,fc_cSanBaseSvcClusterStorageType,fc_cSanBaseSvcClusterRowStatus,fc_cSanBaseSvcClusterApplication,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
			my $cfdmihbaportentry_sth = $mysql->prepare_cached("INSERT INTO cfdmihbaportentry(deviceid,scantime,fc_cfdmiHbaPortId,fc_cfdmiHbaPortSupportedFC4Type,fc_cfdmiHbaPortSupportedSpeed,fc_cfdmiHbaPortCurrentSpeed,fc_cfdmiHbaPortMaxFrameSize,fc_cfdmiHbaPortOsDevName,fc_cfdmiHbaPortHostName,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $ciscoscsilunmaptable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsilunmaptable(deviceid,scantime,fc_ciscoScsiLunMapIndex,fc_ciscoScsiLunMapLun,fc_ciscoScsiLunMapLuIndex,fc_ciscoScsiLunMapRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $cipnetworkinterfacetable_sth = $mysql->prepare_cached("INSERT INTO cipnetworkinterfacetable(deviceid,scantime,fc_cIpNetworkGigEPortSwitchWWN,fc_cIpNetworkGigEPortIfIndex,fc_cIpNetworkGigEPortInetAddrType,fc_cIpNetworkGigEPortInetAddr,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $fcsportlisttable_sth = $mysql->prepare_cached("INSERT INTO fcsportlisttable(deviceid,scantime,fc_fcsPortListIndex,snmpindex) VALUES (?,?,?,?)");
			my $cspansourcesvsancfgtable_sth = $mysql->prepare_cached("INSERT INTO cspansourcesvsancfgtable(deviceid,scantime,fc_cspanSourcesVsanCfgSessIndex,fc_cspanSourcesVsanCfgCommand,fc_cspanSourcesVsanCfgVsans2k,fc_cspanSourcesVsanCfgVsans4k,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $cipnetworktable_sth = $mysql->prepare_cached("INSERT INTO cipnetworktable(deviceid,scantime,fc_cIpNetworkIndex,fc_cIpNetworkSwitchWWN,snmpindex) VALUES (?,?,?,?,?)");
			my $ciscoscsiatttgtporttable_sth = $mysql->prepare_cached("INSERT INTO ciscoscsiatttgtporttable(deviceid,scantime,fc_ciscoScsiAttTgtPortIndex,fc_ciscoScsiAttTgtPortDscTgtIdx,fc_ciscoScsiAttTgtPortName,fc_ciscoScsiAttTgtPortIdentifier,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $fcrouteflowstattable_sth = $mysql->prepare_cached("INSERT INTO fcrouteflowstattable(deviceid,scantime,fc_fcRouteFlowIndex,fc_fcRouteFlowType,fc_fcRouteFlowVsanId,fc_fcRouteFlowDestId,fc_fcRouteFlowSrcId,fc_fcRouteFlowMask,fc_fcRouteFlowPort,fc_fcRouteFlowFrames,fc_fcRouteFlowBytes,fc_fcRouteFlowCreationTime,fc_fcRouteFlowRowStatus,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $fcsietable_sth = $mysql->prepare_cached("INSERT INTO fcsietable(deviceid,scantime,fc_fcsIeName,fc_fcsIeType,fc_fcsIeDomainId,fc_fcsIeMgmtId,fc_fcsIeFabricName,fc_fcsIeLogicalName,fc_fcsIeMgmtAddrListIndex,fc_fcsIeInfoList,fc_fcsIePortListIndex,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
##Collect information for tablecfccporttable
			my $fc_cFCCEdgeQuenchPktsRecd=$info->fc_cFCCEdgeQuenchPktsRecd();
			my $fc_cFCCEdgeQuenchPktsSent=$info->fc_cFCCEdgeQuenchPktsSent();
			my $fc_cFCCPathQuenchPktsRecd=$info->fc_cFCCPathQuenchPktsRecd();
			my $fc_cFCCPathQuenchPktsSent=$info->fc_cFCCPathQuenchPktsSent();
			my $fc_cFCCCurrentCongestionState=$info->fc_cFCCCurrentCongestionState();
			my $fc_cFCCLastCongestedTime=$info->fc_cFCCLastCongestedTime();
			my $fc_cFCCLastCongestionStartTime=$info->fc_cFCCLastCongestionStartTime();
			my $fc_cFCCIsRateLimitingApplied=$info->fc_cFCCIsRateLimitingApplied();

##Collect information for tablecfmmulticastroottable
			my $fc_cfmMulticastRootConfigMode=$info->fc_cfmMulticastRootConfigMode();
			my $fc_cfmMulticastRootOperMode=$info->fc_cfmMulticastRootOperMode();
			my $fc_cfmMulticastRootDomainId=$info->fc_cfmMulticastRootDomainId();
			my $fc_cfmMulticastRootRowStatus=$info->fc_cfmMulticastRootRowStatus();

##Collect information for tableciscoscsiintrprttable
			my $fc_ciscoScsiIntrPrtName=$info->fc_ciscoScsiIntrPrtName();
			my $fc_ciscoScsiIntrPrtIdentifier=$info->fc_ciscoScsiIntrPrtIdentifier();
			my $fc_ciscoScsiIntrPrtOutCommands=$info->fc_ciscoScsiIntrPrtOutCommands();
			my $fc_ciscoScsiIntrPrtWrMegaBytes=$info->fc_ciscoScsiIntrPrtWrMegaBytes();
			my $fc_ciscoScsiIntrPrtReadMegaBytes=$info->fc_ciscoScsiIntrPrtReadMegaBytes();
			my $fc_ciscoScsiIntrPrtHSOutCommands=$info->fc_ciscoScsiIntrPrtHSOutCommands();

##Collect information for tablecsanbasesvcinterfacetable
			my $fc_cSanBaseSvcInterfaceIndex=$info->fc_cSanBaseSvcInterfaceIndex();
			my $fc_cSanBaseSvcInterfaceState=$info->fc_cSanBaseSvcInterfaceState();
			my $fc_cSanBaseSvcInterfaceClusterId=$info->fc_cSanBaseSvcInterfaceClusterId();
			my $fc_cSanBaseSvcInterfaceStorageType=$info->fc_cSanBaseSvcInterfaceStorageType();
			my $fc_cSanBaseSvcInterfaceRowStatus=$info->fc_cSanBaseSvcInterfaceRowStatus();

##Collect information for tableciscoscsitgtporttable
			my $fc_ciscoScsiTgtPortName=$info->fc_ciscoScsiTgtPortName();
			my $fc_ciscoScsiTgtPortIdentifier=$info->fc_ciscoScsiTgtPortIdentifier();
			my $fc_ciscoScsiTgtPortInCommands=$info->fc_ciscoScsiTgtPortInCommands();
			my $fc_ciscoScsiTgtPortWrMegaBytes=$info->fc_ciscoScsiTgtPortWrMegaBytes();
			my $fc_ciscoScsiTgtPortReadMegaBytes=$info->fc_ciscoScsiTgtPortReadMegaBytes();
			my $fc_ciscoScsiTgtPortHSInCommands=$info->fc_ciscoScsiTgtPortHSInCommands();

##Collect information for tableciscoscsilutable
			my $fc_ciscoScsiLuIndex=$info->fc_ciscoScsiLuIndex();
			my $fc_ciscoScsiLuDefaultLun=$info->fc_ciscoScsiLuDefaultLun();
			my $fc_ciscoScsiLuWwnName=$info->fc_ciscoScsiLuWwnName();
			my $fc_ciscoScsiLuVendorId=$info->fc_ciscoScsiLuVendorId();
			my $fc_ciscoScsiLuProductId=$info->fc_ciscoScsiLuProductId();
			my $fc_ciscoScsiLuRevisionId=$info->fc_ciscoScsiLuRevisionId();
			my $fc_ciscoScsiLuPeripheralType=$info->fc_ciscoScsiLuPeripheralType();
			my $fc_ciscoScsiLuStatus=$info->fc_ciscoScsiLuStatus();
			my $fc_ciscoScsiLuState=$info->fc_ciscoScsiLuState();
			my $fc_ciscoScsiLuInCommands=$info->fc_ciscoScsiLuInCommands();
			my $fc_ciscoScsiLuReadMegaBytes=$info->fc_ciscoScsiLuReadMegaBytes();
			my $fc_ciscoScsiLuWrittenMegaBytes=$info->fc_ciscoScsiLuWrittenMegaBytes();
			my $fc_ciscoScsiLuInResets=$info->fc_ciscoScsiLuInResets();
			my $fc_ciscoScsiLuOutQueueFullStatus=$info->fc_ciscoScsiLuOutQueueFullStatus();
			my $fc_ciscoScsiLuHSInCommands=$info->fc_ciscoScsiLuHSInCommands();
			my $fc_ciscoScsiLuIdIndex=$info->fc_ciscoScsiLuIdIndex();
			my $fc_ciscoScsiLuIdCodeSet=$info->fc_ciscoScsiLuIdCodeSet();
			my $fc_ciscoScsiLuIdAssociation=$info->fc_ciscoScsiLuIdAssociation();
			my $fc_ciscoScsiLuIdType=$info->fc_ciscoScsiLuIdType();
			my $fc_ciscoScsiLuIdValue=$info->fc_ciscoScsiLuIdValue();

##Collect information for tablecfcsdvvirtrealdevmaptable
			my $fc_cFcSdvVirtRealDevMapIndex=$info->fc_cFcSdvVirtRealDevMapIndex();
			my $fc_cFcSdvVirtRealDeviceIdType=$info->fc_cFcSdvVirtRealDeviceIdType();
			my $fc_cFcSdvVirtRealDeviceId=$info->fc_cFcSdvVirtRealDeviceId();
			my $fc_cFcSdvVirtRealDevMapType=$info->fc_cFcSdvVirtRealDevMapType();
			my $fc_cFcSdvVirtRealDevMapStorageType=$info->fc_cFcSdvVirtRealDevMapStorageType();
			my $fc_cFcSdvVirtRealDevMapRowStatus=$info->fc_cFcSdvVirtRealDevMapRowStatus();

##Collect information for tablefcsplatformtable
			my $fc_fcsPlatformIndex=$info->fc_fcsPlatformIndex();
			my $fc_fcsPlatformName=$info->fc_fcsPlatformName();
			my $fc_fcsPlatformType=$info->fc_fcsPlatformType();
			my $fc_fcsPlatformNodeNameListIndex=$info->fc_fcsPlatformNodeNameListIndex();
			my $fc_fcsPlatformMgmtAddrListIndex=$info->fc_fcsPlatformMgmtAddrListIndex();
			my $fc_fcsPlatformConfigSource=$info->fc_fcsPlatformConfigSource();
			my $fc_fcsPlatformValidation=$info->fc_fcsPlatformValidation();
			my $fc_fcsPlatformValidationResult=$info->fc_fcsPlatformValidationResult();
			my $fc_fcsPlatformRowStatus=$info->fc_fcsPlatformRowStatus();

##Collect information for tablecsanbasesvcclustermemberiftable
			my $fc_cSanBaseSvcClusterInterfaceIndex=$info->fc_cSanBaseSvcClusterInterfaceIndex();
			my $fc_cSanBaseSvcClusterInterfaceState=$info->fc_cSanBaseSvcClusterInterfaceState();

##Collect information for tablefcsmgmtaddrlisttable
			my $fc_fcsMgmtAddrListIndex=$info->fc_fcsMgmtAddrListIndex();
			my $fc_fcsMgmtAddrIndex=$info->fc_fcsMgmtAddrIndex();
			my $fc_fcsMgmtAddr=$info->fc_fcsMgmtAddr();
			my $fc_fcsMgmtAddrConfigSource=$info->fc_fcsMgmtAddrConfigSource();
			my $fc_fcsMgmtAddrRowStatus=$info->fc_fcsMgmtAddrRowStatus();

##Collect information for tablecspanvsanfiltertable
			my $fc_cspanVsanFilterSessIndex=$info->fc_cspanVsanFilterSessIndex();
			my $fc_cspanVsanFilterVsans2k=$info->fc_cspanVsanFilterVsans2k();
			my $fc_cspanVsanFilterVsans4k=$info->fc_cspanVsanFilterVsans4k();

##Collect information for tableciscoscsiflowtable
			my $fc_ciscoScsiFlowId=$info->fc_ciscoScsiFlowId();
			my $fc_ciscoScsiFlowIntrWwn=$info->fc_ciscoScsiFlowIntrWwn();
			my $fc_ciscoScsiFlowTargetWwn=$info->fc_ciscoScsiFlowTargetWwn();
			my $fc_ciscoScsiFlowIntrVsan=$info->fc_ciscoScsiFlowIntrVsan();
			my $fc_ciscoScsiFlowTargetVsan=$info->fc_ciscoScsiFlowTargetVsan();
			my $fc_ciscoScsiFlowAllLuns=$info->fc_ciscoScsiFlowAllLuns();
			my $fc_ciscoScsiFlowWriteAcc=$info->fc_ciscoScsiFlowWriteAcc();
			my $fc_ciscoScsiFlowBufCount=$info->fc_ciscoScsiFlowBufCount();
			my $fc_ciscoScsiFlowStatsEnabled=$info->fc_ciscoScsiFlowStatsEnabled();
			my $fc_ciscoScsiFlowClearStats=$info->fc_ciscoScsiFlowClearStats();
			my $fc_ciscoScsiFlowIntrVrfStatus=$info->fc_ciscoScsiFlowIntrVrfStatus();
			my $fc_ciscoScsiFlowTgtVrfStatus=$info->fc_ciscoScsiFlowTgtVrfStatus();
			my $fc_ciscoScsiFlowIntrLCStatus=$info->fc_ciscoScsiFlowIntrLCStatus();
			my $fc_ciscoScsiFlowTgtLCStatus=$info->fc_ciscoScsiFlowTgtLCStatus();
			my $fc_ciscoScsiFlowRowStatus=$info->fc_ciscoScsiFlowRowStatus();

##Collect information for tablefcsnodenamelisttable
			my $fc_fcsNodeNameListIndex=$info->fc_fcsNodeNameListIndex();
			my $fc_fcsNodeName=$info->fc_fcsNodeName();
			my $fc_fcsNodeNameConfigSource=$info->fc_fcsNodeNameConfigSource();
			my $fc_fcsNodeNameRowStatus=$info->fc_fcsNodeNameRowStatus();

##Collect information for tablecfcsdvvirtdevicetable
			my $fc_cFcSdvVdIndex=$info->fc_cFcSdvVdIndex();
			my $fc_cFcSdvVdName=$info->fc_cFcSdvVdName();
			my $fc_cFcSdvVdVirtDomain=$info->fc_cFcSdvVdVirtDomain();
			my $fc_cFcSdvVdFcId=$info->fc_cFcSdvVdFcId();
			my $fc_cFcSdvVdPwwn=$info->fc_cFcSdvVdPwwn();
			my $fc_cFcSdvVdNwwn=$info->fc_cFcSdvVdNwwn();
			my $fc_cFcSdvVdAssignedFcId=$info->fc_cFcSdvVdAssignedFcId();
			my $fc_cFcSdvVdRealDevMapList=$info->fc_cFcSdvVdRealDevMapList();
			my $fc_cFcSdvVdStorageType=$info->fc_cFcSdvVdStorageType();
			my $fc_cFcSdvVdRowStatus=$info->fc_cFcSdvVdRowStatus();

##Collect information for tablecstserviceconfigtable
			my $fc_cstCVTNodeWwn=$info->fc_cstCVTNodeWwn();
			my $fc_cstCVTPortWwn=$info->fc_cstCVTPortWwn();
			my $fc_cstServiceConfigRowStatus=$info->fc_cstServiceConfigRowStatus();

##Collect information for tableciscoscsiattintrprttable
			my $fc_ciscoScsiAttIntrPrtIdx=$info->fc_ciscoScsiAttIntrPrtIdx();
			my $fc_ciscoScsiAttIntrPrtAuthIntrIdx=$info->fc_ciscoScsiAttIntrPrtAuthIntrIdx();
			my $fc_ciscoScsiAttIntrPrtName=$info->fc_ciscoScsiAttIntrPrtName();
			my $fc_ciscoScsiAttIntrPrtId=$info->fc_ciscoScsiAttIntrPrtId();

##Collect information for tableciscoscsiintrdevtable
			my $fc_ciscoScsiIntrDevAccMode=$info->fc_ciscoScsiIntrDevAccMode();
			my $fc_ciscoScsiIntrDevOutResets=$info->fc_ciscoScsiIntrDevOutResets();

##Collect information for tablecspansourcesvsantable
			my $fc_cspanSourcesVsans2k=$info->fc_cspanSourcesVsans2k();
			my $fc_cspanSourcesVsans4k=$info->fc_cspanSourcesVsans4k();

##Collect information for tableciscoextscsigeninstancetable
			my $fc_ciscoExtScsiDiskGrpId=$info->fc_ciscoExtScsiDiskGrpId();
			my $fc_ciscoExtScsiLineCardOrSup=$info->fc_ciscoExtScsiLineCardOrSup();

##Collect information for tablefcsstatstable
			my $fc_fcsRxGetReqs=$info->fc_fcsRxGetReqs();
			my $fc_fcsTxGetReqs=$info->fc_fcsTxGetReqs();
			my $fc_fcsRxRegReqs=$info->fc_fcsRxRegReqs();
			my $fc_fcsTxRegReqs=$info->fc_fcsTxRegReqs();
			my $fc_fcsRxDeregReqs=$info->fc_fcsRxDeregReqs();
			my $fc_fcsTxDeregReqs=$info->fc_fcsTxDeregReqs();
			my $fc_fcsTxRscns=$info->fc_fcsTxRscns();
			my $fc_fcsRxRscns=$info->fc_fcsRxRscns();
			my $fc_fcsRejects=$info->fc_fcsRejects();

##Collect information for tablefcroutetable
			my $fc_fcRouteDestAddrId=$info->fc_fcRouteDestAddrId();
			my $fc_fcRouteDestMask=$info->fc_fcRouteDestMask();
			my $fc_fcRouteProto=$info->fc_fcRouteProto();
			my $fc_fcRouteInterface=$info->fc_fcRouteInterface();
			my $fc_fcRouteDomainId=$info->fc_fcRouteDomainId();
			my $fc_fcRouteMetric=$info->fc_fcRouteMetric();
			my $fc_fcRouteType=$info->fc_fcRouteType();
			my $fc_fcRoutePermanent=$info->fc_fcRoutePermanent();
			my $fc_fcRouteRowStatus=$info->fc_fcRouteRowStatus();

##Collect information for tablefciftable
			my $fc_fcIfWwn=$info->fc_fcIfWwn();
			my $fc_fcIfAdminMode=$info->fc_fcIfAdminMode();
			my $fc_fcIfOperMode=$info->fc_fcIfOperMode();
			my $fc_fcIfAdminSpeed=$info->fc_fcIfAdminSpeed();
			my $fc_fcIfBeaconMode=$info->fc_fcIfBeaconMode();
			my $fc_fcIfPortChannelIfIndex=$info->fc_fcIfPortChannelIfIndex();
			my $fc_fcIfOperStatusCause=$info->fc_fcIfOperStatusCause();
			my $fc_fcIfOperStatusCauseDescr=$info->fc_fcIfOperStatusCauseDescr();
			my $fc_fcIfAdminTrunkMode=$info->fc_fcIfAdminTrunkMode();
			my $fc_fcIfOperTrunkMode=$info->fc_fcIfOperTrunkMode();
			my $fc_fcIfAllowedVsanList2k=$info->fc_fcIfAllowedVsanList2k();
			my $fc_fcIfAllowedVsanList4k=$info->fc_fcIfAllowedVsanList4k();
			my $fc_fcIfActiveVsanList2k=$info->fc_fcIfActiveVsanList2k();
			my $fc_fcIfActiveVsanList4k=$info->fc_fcIfActiveVsanList4k();
			my $fc_fcIfBbCreditModel=$info->fc_fcIfBbCreditModel();
			my $fc_fcIfHoldTime=$info->fc_fcIfHoldTime();
			my $fc_fcIfTransmitterType=$info->fc_fcIfTransmitterType();
			my $fc_fcIfConnectorType=$info->fc_fcIfConnectorType();
			my $fc_fcIfSerialNo=$info->fc_fcIfSerialNo();
			my $fc_fcIfRevision=$info->fc_fcIfRevision();
			my $fc_fcIfVendor=$info->fc_fcIfVendor();
			my $fc_fcIfSFPSerialIDData=$info->fc_fcIfSFPSerialIDData();
			my $fc_fcIfPartNumber=$info->fc_fcIfPartNumber();
			my $fc_fcIfAdminRxBbCredit=$info->fc_fcIfAdminRxBbCredit();
			my $fc_fcIfAdminRxBbCreditModeISL=$info->fc_fcIfAdminRxBbCreditModeISL();
			my $fc_fcIfAdminRxBbCreditModeFx=$info->fc_fcIfAdminRxBbCreditModeFx();
			my $fc_fcIfOperRxBbCredit=$info->fc_fcIfOperRxBbCredit();
			my $fc_fcIfRxDataFieldSize=$info->fc_fcIfRxDataFieldSize();
			my $fc_fcIfActiveVsanUpList2k=$info->fc_fcIfActiveVsanUpList2k();
			my $fc_fcIfActiveVsanUpList4k=$info->fc_fcIfActiveVsanUpList4k();
			my $fc_fcIfPortRateMode=$info->fc_fcIfPortRateMode();
			my $fc_fcIfAdminRxPerfBuffer=$info->fc_fcIfAdminRxPerfBuffer();
			my $fc_fcIfOperRxPerfBuffer=$info->fc_fcIfOperRxPerfBuffer();
			my $fc_fcIfBbScn=$info->fc_fcIfBbScn();
			my $fc_fcIfPortInitStatus=$info->fc_fcIfPortInitStatus();
			my $fc_fcIfAdminRxBbCreditExtended=$info->fc_fcIfAdminRxBbCreditExtended();
			my $fc_fcIfFcTunnelIfIndex=$info->fc_fcIfFcTunnelIfIndex();
			my $fc_fcIfServiceState=$info->fc_fcIfServiceState();
			my $fc_fcIfAdminBbScnMode=$info->fc_fcIfAdminBbScnMode();

##Collect information for tablecfcspifstatstable
			my $fc_cfcspIfAuthSucceeded=$info->fc_cfcspIfAuthSucceeded();
			my $fc_cfcspIfAuthFailed=$info->fc_cfcspIfAuthFailed();
			my $fc_cfcspIfAuthByPassed=$info->fc_cfcspIfAuthByPassed();

##Collect information for tablevirtualnwiftable
			my $fc_virtualNwIfType=$info->fc_virtualNwIfType();
			my $fc_virtualNwIfId=$info->fc_virtualNwIfId();
			my $fc_virtualNwIfIndex=$info->fc_virtualNwIfIndex();
			my $fc_virtualNwIfFcId=$info->fc_virtualNwIfFcId();
			my $fc_virtualNwIfOperStatusCause=$info->fc_virtualNwIfOperStatusCause();
			my $fc_virtualNwIfOperStatusCauseDescr=$info->fc_virtualNwIfOperStatusCauseDescr();
			my $fc_virtualNwIfRowStatus=$info->fc_virtualNwIfRowStatus();

##Collect information for tablefciferrortable
			my $fc_fcIfLinkFailures=$info->fc_fcIfLinkFailures();
			my $fc_fcIfSyncLosses=$info->fc_fcIfSyncLosses();
			my $fc_fcIfSigLosses=$info->fc_fcIfSigLosses();
			my $fc_fcIfPrimSeqProtoErrors=$info->fc_fcIfPrimSeqProtoErrors();
			my $fc_fcIfInvalidTxWords=$info->fc_fcIfInvalidTxWords();
			my $fc_fcIfInvalidCrcs=$info->fc_fcIfInvalidCrcs();
			my $fc_fcIfDelimiterErrors=$info->fc_fcIfDelimiterErrors();
			my $fc_fcIfAddressIdErrors=$info->fc_fcIfAddressIdErrors();
			my $fc_fcIfLinkResetIns=$info->fc_fcIfLinkResetIns();
			my $fc_fcIfLinkResetOuts=$info->fc_fcIfLinkResetOuts();
			my $fc_fcIfOlsIns=$info->fc_fcIfOlsIns();
			my $fc_fcIfOlsOuts=$info->fc_fcIfOlsOuts();
			my $fc_fcIfRuntFramesIn=$info->fc_fcIfRuntFramesIn();
			my $fc_fcIfJabberFramesIn=$info->fc_fcIfJabberFramesIn();
			my $fc_fcIfTxWaitCount=$info->fc_fcIfTxWaitCount();
			my $fc_fcIfFramesTooLong=$info->fc_fcIfFramesTooLong();
			my $fc_fcIfFramesTooShort=$info->fc_fcIfFramesTooShort();
			my $fc_fcIfLRRIn=$info->fc_fcIfLRRIn();
			my $fc_fcIfLRROut=$info->fc_fcIfLRROut();
			my $fc_fcIfNOSIn=$info->fc_fcIfNOSIn();
			my $fc_fcIfNOSOut=$info->fc_fcIfNOSOut();
			my $fc_fcIfFragFrames=$info->fc_fcIfFragFrames();
			my $fc_fcIfEOFaFrames=$info->fc_fcIfEOFaFrames();
			my $fc_fcIfUnknownClassFrames=$info->fc_fcIfUnknownClassFrames();
			my $fc_fcIf8b10bDisparityErrors=$info->fc_fcIf8b10bDisparityErrors();
			my $fc_fcIfFramesDiscard=$info->fc_fcIfFramesDiscard();
			my $fc_fcIfELPFailures=$info->fc_fcIfELPFailures();
			my $fc_fcIfBBCreditTransistionFromZero=$info->fc_fcIfBBCreditTransistionFromZero();
			my $fc_fcIfEISLFramesDiscard=$info->fc_fcIfEISLFramesDiscard();
			my $fc_fcIfFramingErrorFrames=$info->fc_fcIfFramingErrorFrames();
			my $fc_fcIfLipF8In=$info->fc_fcIfLipF8In();
			my $fc_fcIfLipF8Out=$info->fc_fcIfLipF8Out();
			my $fc_fcIfNonLipF8In=$info->fc_fcIfNonLipF8In();
			my $fc_fcIfNonLipF8Out=$info->fc_fcIfNonLipF8Out();

##Collect information for tablefctraceroutehopstable
			my $fc_fcTraceRouteHopsHopIndex=$info->fc_fcTraceRouteHopsHopIndex();
			my $fc_fcTraceRouteHopsHopAddr=$info->fc_fcTraceRouteHopsHopAddr();
			my $fc_fcTraceRouteHopsHopLatencyValid=$info->fc_fcTraceRouteHopsHopLatencyValid();
			my $fc_fcTraceRouteHopsHopLatency=$info->fc_fcTraceRouteHopsHopLatency();

##Collect information for tableciscoscsiauthorizedintrtable
			my $fc_ciscoScsiAuthIntrTgtPortIndex=$info->fc_ciscoScsiAuthIntrTgtPortIndex();
			my $fc_ciscoScsiAuthIntrIndex=$info->fc_ciscoScsiAuthIntrIndex();
			my $fc_ciscoScsiAuthIntrDevOrPort=$info->fc_ciscoScsiAuthIntrDevOrPort();
			my $fc_ciscoScsiAuthIntrName=$info->fc_ciscoScsiAuthIntrName();
			my $fc_ciscoScsiAuthIntrLunMapIndex=$info->fc_ciscoScsiAuthIntrLunMapIndex();
			my $fc_ciscoScsiAuthIntrAttachedTimes=$info->fc_ciscoScsiAuthIntrAttachedTimes();
			my $fc_ciscoScsiAuthIntrOutCommands=$info->fc_ciscoScsiAuthIntrOutCommands();
			my $fc_ciscoScsiAuthIntrReadMegaBytes=$info->fc_ciscoScsiAuthIntrReadMegaBytes();
			my $fc_ciscoScsiAuthIntrWrMegaBytes=$info->fc_ciscoScsiAuthIntrWrMegaBytes();
			my $fc_ciscoScsiAuthIntrHSOutCommands=$info->fc_ciscoScsiAuthIntrHSOutCommands();
			my $fc_ciscoScsiAuthIntrLastCreation=$info->fc_ciscoScsiAuthIntrLastCreation();
			my $fc_ciscoScsiAuthIntrRowStatus=$info->fc_ciscoScsiAuthIntrRowStatus();

##Collect information for tablecstmoduletable
			my $fc_cstModuleId=$info->fc_cstModuleId();

##Collect information for tablefcifelptable
			my $fc_fcIfElpNbrNodeName=$info->fc_fcIfElpNbrNodeName();
			my $fc_fcIfElpNbrPortName=$info->fc_fcIfElpNbrPortName();
			my $fc_fcIfElpRxBbCredit=$info->fc_fcIfElpRxBbCredit();
			my $fc_fcIfElpTxBbCredit=$info->fc_fcIfElpTxBbCredit();
			my $fc_fcIfElpCosSuppAgreed=$info->fc_fcIfElpCosSuppAgreed();
			my $fc_fcIfElpClass2SeqDelivAgreed=$info->fc_fcIfElpClass2SeqDelivAgreed();
			my $fc_fcIfElpClass2RxDataFieldSize=$info->fc_fcIfElpClass2RxDataFieldSize();
			my $fc_fcIfElpClass3SeqDelivAgreed=$info->fc_fcIfElpClass3SeqDelivAgreed();
			my $fc_fcIfElpClass3RxDataFieldSize=$info->fc_fcIfElpClass3RxDataFieldSize();
			my $fc_fcIfElpClassFXII=$info->fc_fcIfElpClassFXII();
			my $fc_fcIfElpClassFRxDataFieldSize=$info->fc_fcIfElpClassFRxDataFieldSize();
			my $fc_fcIfElpClassFConcurrentSeq=$info->fc_fcIfElpClassFConcurrentSeq();
			my $fc_fcIfElpClassFEndToEndCredit=$info->fc_fcIfElpClassFEndToEndCredit();
			my $fc_fcIfElpClassFOpenSeq=$info->fc_fcIfElpClassFOpenSeq();

##Collect information for tablefcpingstatstable
			my $fc_fcPingTxPackets=$info->fc_fcPingTxPackets();
			my $fc_fcPingRxPackets=$info->fc_fcPingRxPackets();
			my $fc_fcPingMinRtt=$info->fc_fcPingMinRtt();
			my $fc_fcPingAvgRtt=$info->fc_fcPingAvgRtt();
			my $fc_fcPingMaxRtt=$info->fc_fcPingMaxRtt();
			my $fc_fcPingNumTimeouts=$info->fc_fcPingNumTimeouts();

##Collect information for tableciscoscsidsctgttable
			my $fc_ciscoScsiDscTgtIntrPortIndex=$info->fc_ciscoScsiDscTgtIntrPortIndex();
			my $fc_ciscoScsiDscTgtIndex=$info->fc_ciscoScsiDscTgtIndex();
			my $fc_ciscoScsiDscTgtDevOrPort=$info->fc_ciscoScsiDscTgtDevOrPort();
			my $fc_ciscoScsiDscTgtName=$info->fc_ciscoScsiDscTgtName();
			my $fc_ciscoScsiDscTgtConfigured=$info->fc_ciscoScsiDscTgtConfigured();
			my $fc_ciscoScsiDscTgtDiscovered=$info->fc_ciscoScsiDscTgtDiscovered();
			my $fc_ciscoScsiDscTgtInCommands=$info->fc_ciscoScsiDscTgtInCommands();
			my $fc_ciscoScsiDscTgtWrMegaBytes=$info->fc_ciscoScsiDscTgtWrMegaBytes();
			my $fc_ciscoScsiDscTgtReadMegaBytes=$info->fc_ciscoScsiDscTgtReadMegaBytes();
			my $fc_ciscoScsiDscTgtHSInCommands=$info->fc_ciscoScsiDscTgtHSInCommands();
			my $fc_ciscoScsiDscTgtLastCreation=$info->fc_ciscoScsiDscTgtLastCreation();
			my $fc_ciscoScsiDscTgtRowStatus=$info->fc_ciscoScsiDscTgtRowStatus();

##Collect information for tablecspansourcesiftable
			my $fc_cspanSourcesIfIndex=$info->fc_cspanSourcesIfIndex();
			my $fc_cspanSourcesDirection=$info->fc_cspanSourcesDirection();
			my $fc_cspanSourcesRowStatus=$info->fc_cspanSourcesRowStatus();

##Collect information for tablefcifc2accountingtable
			my $fc_fcIfC2InFrames=$info->fc_fcIfC2InFrames();
			my $fc_fcIfC2OutFrames=$info->fc_fcIfC2OutFrames();
			my $fc_fcIfC2InOctets=$info->fc_fcIfC2InOctets();
			my $fc_fcIfC2OutOctets=$info->fc_fcIfC2OutOctets();
			my $fc_fcIfC2Discards=$info->fc_fcIfC2Discards();
			my $fc_fcIfC2FbsyFrames=$info->fc_fcIfC2FbsyFrames();
			my $fc_fcIfC2FrjtFrames=$info->fc_fcIfC2FrjtFrames();
			my $fc_fcIfC2PBSYFrames=$info->fc_fcIfC2PBSYFrames();
			my $fc_fcIfC2PRJTFrames=$info->fc_fcIfC2PRJTFrames();

##Collect information for tableciscoscsidscluntable
			my $fc_ciscoScsiDscLunIndex=$info->fc_ciscoScsiDscLunIndex();
			my $fc_ciscoScsiDscLunLun=$info->fc_ciscoScsiDscLunLun();

##Collect information for tablefcifcaptable
			my $fc_fcIfCapFcphVersionHigh=$info->fc_fcIfCapFcphVersionHigh();
			my $fc_fcIfCapFcphVersionLow=$info->fc_fcIfCapFcphVersionLow();
			my $fc_fcIfCapRxBbCreditMax=$info->fc_fcIfCapRxBbCreditMax();
			my $fc_fcIfCapRxBbCreditMin=$info->fc_fcIfCapRxBbCreditMin();
			my $fc_fcIfCapRxDataFieldSizeMax=$info->fc_fcIfCapRxDataFieldSizeMax();
			my $fc_fcIfCapRxDataFieldSizeMin=$info->fc_fcIfCapRxDataFieldSizeMin();
			my $fc_fcIfCapCos=$info->fc_fcIfCapCos();
			my $fc_fcIfCapClass2SeqDeliv=$info->fc_fcIfCapClass2SeqDeliv();
			my $fc_fcIfCapClass3SeqDeliv=$info->fc_fcIfCapClass3SeqDeliv();
			my $fc_fcIfCapHoldTimeMax=$info->fc_fcIfCapHoldTimeMax();
			my $fc_fcIfCapHoldTimeMin=$info->fc_fcIfCapHoldTimeMin();
			my $fc_fcIfCapISLRxBbCreditMax=$info->fc_fcIfCapISLRxBbCreditMax();
			my $fc_fcIfCapISLRxBbCreditMin=$info->fc_fcIfCapISLRxBbCreditMin();
			my $fc_fcIfCapRxBbCreditWriteable=$info->fc_fcIfCapRxBbCreditWriteable();
			my $fc_fcIfCapRxBbCreditDefault=$info->fc_fcIfCapRxBbCreditDefault();
			my $fc_fcIfCapISLRxBbCreditDefault=$info->fc_fcIfCapISLRxBbCreditDefault();
			my $fc_fcIfCapBbScnCapable=$info->fc_fcIfCapBbScnCapable();
			my $fc_fcIfCapBbScnMax=$info->fc_fcIfCapBbScnMax();
			my $fc_fcIfCapOsmFrmCapable=$info->fc_fcIfCapOsmFrmCapable();

##Collect information for tablefctraceroutetable
			my $fc_fcTraceRouteIndex=$info->fc_fcTraceRouteIndex();
			my $fc_fcTraceRouteVsanIndex=$info->fc_fcTraceRouteVsanIndex();
			my $fc_fcTraceRouteTargetAddrType=$info->fc_fcTraceRouteTargetAddrType();
			my $fc_fcTraceRouteTargetAddr=$info->fc_fcTraceRouteTargetAddr();
			my $fc_fcTraceRouteTimeout=$info->fc_fcTraceRouteTimeout();
			my $fc_fcTraceRouteAdminStatus=$info->fc_fcTraceRouteAdminStatus();
			my $fc_fcTraceRouteOperStatus=$info->fc_fcTraceRouteOperStatus();
			my $fc_fcTraceRouteAgeInterval=$info->fc_fcTraceRouteAgeInterval();
			my $fc_fcTraceRouteTrapOnCompletion=$info->fc_fcTraceRouteTrapOnCompletion();
			my $fc_fcTraceRouteRowStatus=$info->fc_fcTraceRouteRowStatus();

##Collect information for tablefcifflogintable
			my $fc_fcIfNxLoginIndex=$info->fc_fcIfNxLoginIndex();
			my $fc_fcIfNxPortNodeName=$info->fc_fcIfNxPortNodeName();
			my $fc_fcIfNxPortName=$info->fc_fcIfNxPortName();
			my $fc_fcIfNxPortAddress=$info->fc_fcIfNxPortAddress();
			my $fc_fcIfNxFcphVersionAgreed=$info->fc_fcIfNxFcphVersionAgreed();
			my $fc_fcIfNxRxBbCredit=$info->fc_fcIfNxRxBbCredit();
			my $fc_fcIfNxTxBbCredit=$info->fc_fcIfNxTxBbCredit();
			my $fc_fcIfNxClass2RxDataFieldSize=$info->fc_fcIfNxClass2RxDataFieldSize();
			my $fc_fcIfNxClass3RxDataFieldSize=$info->fc_fcIfNxClass3RxDataFieldSize();
			my $fc_fcIfNxCosSuppAgreed=$info->fc_fcIfNxCosSuppAgreed();
			my $fc_fcIfNxClass2SeqDelivAgreed=$info->fc_fcIfNxClass2SeqDelivAgreed();
			my $fc_fcIfNxClass3SeqDelivAgreed=$info->fc_fcIfNxClass3SeqDelivAgreed();

##Collect information for tableciscoextscsiintrdisctgttable
			my $fc_ciscoExtScsiIntrDiscTgtVsanId=$info->fc_ciscoExtScsiIntrDiscTgtVsanId();
			my $fc_ciscoExtScsiIntrDiscTgtDevType=$info->fc_ciscoExtScsiIntrDiscTgtDevType();
			my $fc_ciscoExtScsiIntrDiscTgtVendorId=$info->fc_ciscoExtScsiIntrDiscTgtVendorId();
			my $fc_ciscoExtScsiIntrDiscTgtProductId=$info->fc_ciscoExtScsiIntrDiscTgtProductId();
			my $fc_ciscoExtScsiIntrDiscTgtRevLevel=$info->fc_ciscoExtScsiIntrDiscTgtRevLevel();
			my $fc_ciscoExtScsiIntrDiscTgtOtherInfo=$info->fc_ciscoExtScsiIntrDiscTgtOtherInfo();

##Collect information for tablefcifcfaccountingtable
			my $fc_fcIfCfInFrames=$info->fc_fcIfCfInFrames();
			my $fc_fcIfCfOutFrames=$info->fc_fcIfCfOutFrames();
			my $fc_fcIfCfInOctets=$info->fc_fcIfCfInOctets();
			my $fc_fcIfCfOutOctets=$info->fc_fcIfCfOutOctets();
			my $fc_fcIfCfDiscards=$info->fc_fcIfCfDiscards();

##Collect information for tablefcsporttable
			my $fc_fcsPortName=$info->fc_fcsPortName();
			my $fc_fcsPortType=$info->fc_fcsPortType();
			my $fc_fcsPortTXType=$info->fc_fcsPortTXType();
			my $fc_fcsPortModuleType=$info->fc_fcsPortModuleType();
			my $fc_fcsPortPhyPortNum=$info->fc_fcsPortPhyPortNum();
			my $fc_fcsPortAttachPortNameIndex=$info->fc_fcsPortAttachPortNameIndex();
			my $fc_fcsPortState=$info->fc_fcsPortState();

##Collect information for tableciscoscsitgtdevtable
			my $fc_ciscoScsiTgtDevNumberOfLUs=$info->fc_ciscoScsiTgtDevNumberOfLUs();
			my $fc_ciscoScsiTgtDeviceStatus=$info->fc_ciscoScsiTgtDeviceStatus();
			my $fc_ciscoScsiTgtDevNonAccLUs=$info->fc_ciscoScsiTgtDevNonAccLUs();

##Collect information for tablefctrunkiftable
			my $fc_fcTrunkIfOperStatus=$info->fc_fcTrunkIfOperStatus();
			my $fc_fcTrunkIfOperStatusCause=$info->fc_fcTrunkIfOperStatusCause();
			my $fc_fcTrunkIfOperStatusCauseDescr=$info->fc_fcTrunkIfOperStatusCauseDescr();

##Collect information for tablecfcsplocalpasswdtable
			my $fc_cfcspSwitchWwn=$info->fc_cfcspSwitchWwn();
			my $fc_cfcspLocalPasswd=$info->fc_cfcspLocalPasswd();
			my $fc_cfcspLocalPassRowStatus=$info->fc_cfcspLocalPassRowStatus();

##Collect information for tableciscoscsidsclunidtable
			my $fc_ciscoScsiDscLunIdIndex=$info->fc_ciscoScsiDscLunIdIndex();
			my $fc_ciscoScsiDscLunIdCodeSet=$info->fc_ciscoScsiDscLunIdCodeSet();
			my $fc_ciscoScsiDscLunIdAssociation=$info->fc_ciscoScsiDscLunIdAssociation();
			my $fc_ciscoScsiDscLunIdType=$info->fc_ciscoScsiDscLunIdType();
			my $fc_ciscoScsiDscLunIdValue=$info->fc_ciscoScsiDscLunIdValue();

##Collect information for tablecfcspremotepasswdtable
			my $fc_cfcspRemoteSwitchWwn=$info->fc_cfcspRemoteSwitchWwn();
			my $fc_cfcspRemotePasswd=$info->fc_cfcspRemotePasswd();
			my $fc_cfcspRemotePassRowStatus=$info->fc_cfcspRemotePassRowStatus();

##Collect information for tablefcifstattable
			my $fc_fcIfCurrRxBbCredit=$info->fc_fcIfCurrRxBbCredit();
			my $fc_fcIfCurrTxBbCredit=$info->fc_fcIfCurrTxBbCredit();

##Collect information for tablecspansessiontable
			my $fc_cspanSessionIndex=$info->fc_cspanSessionIndex();
			my $fc_cspanSessionDestIfIndex=$info->fc_cspanSessionDestIfIndex();
			my $fc_cspanSessionAdminStatus=$info->fc_cspanSessionAdminStatus();
			my $fc_cspanSessionOperStatus=$info->fc_cspanSessionOperStatus();
			my $fc_cspanSessionInactiveReason=$info->fc_cspanSessionInactiveReason();
			my $fc_cspanSessionRowStatus=$info->fc_cspanSessionRowStatus();

##Collect information for tablefcsdiscoverystatustable
			my $fc_fcsDiscoveryStatus=$info->fc_fcsDiscoveryStatus();
			my $fc_fcsDiscoveryCompleteTime=$info->fc_fcsDiscoveryCompleteTime();

##Collect information for tablecfcspiftable
			my $fc_cfcspMode=$info->fc_cfcspMode();
			my $fc_cfcspReauthInterval=$info->fc_cfcspReauthInterval();
			my $fc_cfcspReauthenticate=$info->fc_cfcspReauthenticate();

##Collect information for tableciscoscsitrnspttable
			my $fc_ciscoScsiTrnsptIndex=$info->fc_ciscoScsiTrnsptIndex();
			my $fc_ciscoScsiTrnsptType=$info->fc_ciscoScsiTrnsptType();
			my $fc_ciscoScsiTrnsptPointer=$info->fc_ciscoScsiTrnsptPointer();
			my $fc_ciscoScsiTrnsptDevName=$info->fc_ciscoScsiTrnsptDevName();

##Collect information for tableciscoscsiflowwraccstatustable
			my $fc_ciscoScsiFlowWrAccCfgStatus=$info->fc_ciscoScsiFlowWrAccCfgStatus();
			my $fc_ciscoScsiFlowWrAccIntrCfgStatus=$info->fc_ciscoScsiFlowWrAccIntrCfgStatus();
			my $fc_ciscoScsiFlowWrAccTgtCfgStatus=$info->fc_ciscoScsiFlowWrAccTgtCfgStatus();

##Collect information for tablefcpingtable
			my $fc_fcPingIndex=$info->fc_fcPingIndex();
			my $fc_fcPingVsanIndex=$info->fc_fcPingVsanIndex();
			my $fc_fcPingAddressType=$info->fc_fcPingAddressType();
			my $fc_fcPingAddress=$info->fc_fcPingAddress();
			my $fc_fcPingPacketCount=$info->fc_fcPingPacketCount();
			my $fc_fcPingPayloadSize=$info->fc_fcPingPayloadSize();
			my $fc_fcPingPacketTimeout=$info->fc_fcPingPacketTimeout();
			my $fc_fcPingDelay=$info->fc_fcPingDelay();
			my $fc_fcPingAgeInterval=$info->fc_fcPingAgeInterval();
			my $fc_fcPingUsrPriority=$info->fc_fcPingUsrPriority();
			my $fc_fcPingAdminStatus=$info->fc_fcPingAdminStatus();
			my $fc_fcPingOperStatus=$info->fc_fcPingOperStatus();
			my $fc_fcPingTrapOnCompletion=$info->fc_fcPingTrapOnCompletion();
			my $fc_fcPingRowStatus=$info->fc_fcPingRowStatus();

##Collect information for tableciscoscsiflowstatsstatustable
			my $fc_ciscoScsiFlowStatsCfgStatus=$info->fc_ciscoScsiFlowStatsCfgStatus();
			my $fc_ciscoScsiFlowStatsIntrCfgStatus=$info->fc_ciscoScsiFlowStatsIntrCfgStatus();
			my $fc_ciscoScsiFlowStatsTgtCfgStatus=$info->fc_ciscoScsiFlowStatsTgtCfgStatus();

##Collect information for tableciscoextscsiintrdisclunstable
			my $fc_ciscoExtScsiIntrDiscLunCapacity=$info->fc_ciscoExtScsiIntrDiscLunCapacity();
			my $fc_ciscoExtScsiIntrDiscLunNumber=$info->fc_ciscoExtScsiIntrDiscLunNumber();
			my $fc_ciscoExtScsiIntrDiscLunSerialNum=$info->fc_ciscoExtScsiIntrDiscLunSerialNum();
			my $fc_ciscoExtScsiIntrDiscLunOs=$info->fc_ciscoExtScsiIntrDiscLunOs();
			my $fc_ciscoExtScsiIntrDiscLunPortId=$info->fc_ciscoExtScsiIntrDiscLunPortId();

##Collect information for tablecspanvsanfilteroptable
			my $fc_cspanVsanFilterOpSessIndex=$info->fc_cspanVsanFilterOpSessIndex();
			my $fc_cspanVsanFilterOpCommand=$info->fc_cspanVsanFilterOpCommand();
			my $fc_cspanVsanFilterOpVsans2k=$info->fc_cspanVsanFilterOpVsans2k();
			my $fc_cspanVsanFilterOpVsans4k=$info->fc_cspanVsanFilterOpVsans4k();

##Collect information for tablefcifc3accountingtable
			my $fc_fcIfC3InFrames=$info->fc_fcIfC3InFrames();
			my $fc_fcIfC3OutFrames=$info->fc_fcIfC3OutFrames();
			my $fc_fcIfC3InOctets=$info->fc_fcIfC3InOctets();
			my $fc_fcIfC3OutOctets=$info->fc_fcIfC3OutOctets();
			my $fc_fcIfC3Discards=$info->fc_fcIfC3Discards();

##Collect information for tablefcifrnidinfotable
			my $fc_fcIfRNIDInfoStatus=$info->fc_fcIfRNIDInfoStatus();
			my $fc_fcIfRNIDInfoTypeNumber=$info->fc_fcIfRNIDInfoTypeNumber();
			my $fc_fcIfRNIDInfoModelNumber=$info->fc_fcIfRNIDInfoModelNumber();
			my $fc_fcIfRNIDInfoManufacturer=$info->fc_fcIfRNIDInfoManufacturer();
			my $fc_fcIfRNIDInfoPlantOfMfg=$info->fc_fcIfRNIDInfoPlantOfMfg();
			my $fc_fcIfRNIDInfoSerialNumber=$info->fc_fcIfRNIDInfoSerialNumber();
			my $fc_fcIfRNIDInfoUnitType=$info->fc_fcIfRNIDInfoUnitType();
			my $fc_fcIfRNIDInfoPortId=$info->fc_fcIfRNIDInfoPortId();

##Collect information for tablefcifgigetable
			my $fc_fcIfGigEPortChannelIfIndex=$info->fc_fcIfGigEPortChannelIfIndex();
			my $fc_fcIfGigEAutoNegotiate=$info->fc_fcIfGigEAutoNegotiate();
			my $fc_fcIfGigEBeaconMode=$info->fc_fcIfGigEBeaconMode();

##Collect information for tablecfdmihbainfotable
			my $fc_cfdmiHbaInfoId=$info->fc_cfdmiHbaInfoId();
			my $fc_cfdmiHbaInfoNodeName=$info->fc_cfdmiHbaInfoNodeName();
			my $fc_cfdmiHbaInfoMfg=$info->fc_cfdmiHbaInfoMfg();
			my $fc_cfdmiHbaInfoSn=$info->fc_cfdmiHbaInfoSn();
			my $fc_cfdmiHbaInfoModel=$info->fc_cfdmiHbaInfoModel();
			my $fc_cfdmiHbaInfoModelDescr=$info->fc_cfdmiHbaInfoModelDescr();
			my $fc_cfdmiHbaInfoHwVer=$info->fc_cfdmiHbaInfoHwVer();
			my $fc_cfdmiHbaInfoDriverVer=$info->fc_cfdmiHbaInfoDriverVer();
			my $fc_cfdmiHbaInfoOptROMVer=$info->fc_cfdmiHbaInfoOptROMVer();
			my $fc_cfdmiHbaInfoFwVer=$info->fc_cfdmiHbaInfoFwVer();
			my $fc_cfdmiHbaInfoOSInfo=$info->fc_cfdmiHbaInfoOSInfo();
			my $fc_cfdmiHbaInfoMaxCTPayload=$info->fc_cfdmiHbaInfoMaxCTPayload();

##Collect information for tablefcifcaposmtable
			my $fc_fcIfCapOsmRxBbCreditWriteable=$info->fc_fcIfCapOsmRxBbCreditWriteable();
			my $fc_fcIfCapOsmRxBbCreditMax=$info->fc_fcIfCapOsmRxBbCreditMax();
			my $fc_fcIfCapOsmRxBbCreditMin=$info->fc_fcIfCapOsmRxBbCreditMin();
			my $fc_fcIfCapOsmRxBbCreditDefault=$info->fc_fcIfCapOsmRxBbCreditDefault();
			my $fc_fcIfCapOsmISLRxBbCreditMax=$info->fc_fcIfCapOsmISLRxBbCreditMax();
			my $fc_fcIfCapOsmISLRxBbCreditMin=$info->fc_fcIfCapOsmISLRxBbCreditMin();
			my $fc_fcIfCapOsmISLRxBbCreditDefault=$info->fc_fcIfCapOsmISLRxBbCreditDefault();
			my $fc_fcIfCapOsmRxPerfBufWriteable=$info->fc_fcIfCapOsmRxPerfBufWriteable();
			my $fc_fcIfCapOsmRxPerfBufMax=$info->fc_fcIfCapOsmRxPerfBufMax();
			my $fc_fcIfCapOsmRxPerfBufMin=$info->fc_fcIfCapOsmRxPerfBufMin();
			my $fc_fcIfCapOsmRxPerfBufDefault=$info->fc_fcIfCapOsmRxPerfBufDefault();
			my $fc_fcIfCapOsmISLRxPerfBufMax=$info->fc_fcIfCapOsmISLRxPerfBufMax();
			my $fc_fcIfCapOsmISLRxPerfBufMin=$info->fc_fcIfCapOsmISLRxPerfBufMin();
			my $fc_fcIfCapOsmISLRxPerfBufDefault=$info->fc_fcIfCapOsmISLRxPerfBufDefault();

##Collect information for tablecfdaconfigtable
			my $fc_cfdaConfigDeviceAlias=$info->fc_cfdaConfigDeviceAlias();
			my $fc_cfdaConfigDeviceType=$info->fc_cfdaConfigDeviceType();
			my $fc_cfdaConfigDeviceId=$info->fc_cfdaConfigDeviceId();
			my $fc_cfdaConfigRowStatus=$info->fc_cfdaConfigRowStatus();

##Collect information for tablecsanbasesvcdeviceporttable
			my $fc_cSanBaseSvcDevicePortName=$info->fc_cSanBaseSvcDevicePortName();
			my $fc_cSanBaseSvcDevicePortClusterId=$info->fc_cSanBaseSvcDevicePortClusterId();
			my $fc_cSanBaseSvcDevicePortStorageType=$info->fc_cSanBaseSvcDevicePortStorageType();
			my $fc_cSanBaseSvcDevicePortRowStatus=$info->fc_cSanBaseSvcDevicePortRowStatus();

##Collect information for tableciscoscsiporttable
			my $fc_ciscoScsiPortIndex=$info->fc_ciscoScsiPortIndex();
			my $fc_ciscoScsiPortRole=$info->fc_ciscoScsiPortRole();
			my $fc_ciscoScsiPortTrnsptPtr=$info->fc_ciscoScsiPortTrnsptPtr();
			my $fc_ciscoScsiPortBusyStatuses=$info->fc_ciscoScsiPortBusyStatuses();

##Collect information for tablecsanbasesvcclustermemberstable
			my $fc_cSanBaseSvcClusterMemberInetAddrType=$info->fc_cSanBaseSvcClusterMemberInetAddrType();
			my $fc_cSanBaseSvcClusterMemberInetAddr=$info->fc_cSanBaseSvcClusterMemberInetAddr();
			my $fc_cSanBaseSvcClusterMemberFabric=$info->fc_cSanBaseSvcClusterMemberFabric();
			my $fc_cSanBaseSvcClusterMemberIsLocal=$info->fc_cSanBaseSvcClusterMemberIsLocal();
			my $fc_cSanBaseSvcClusterMemberIsMaster=$info->fc_cSanBaseSvcClusterMemberIsMaster();
			my $fc_cSanBaseSvcClusterMemberStorageType=$info->fc_cSanBaseSvcClusterMemberStorageType();
			my $fc_cSanBaseSvcClusterMemberRowStatus=$info->fc_cSanBaseSvcClusterMemberRowStatus();

##Collect information for tableciscoscsiinstancetable
			my $fc_ciscoScsiInstIndex=$info->fc_ciscoScsiInstIndex();
			my $fc_ciscoScsiInstAlias=$info->fc_ciscoScsiInstAlias();
			my $fc_ciscoScsiInstSoftwareIndex=$info->fc_ciscoScsiInstSoftwareIndex();
			my $fc_ciscoScsiInstVendorVersion=$info->fc_ciscoScsiInstVendorVersion();
			my $fc_ciscoScsiInstNotifEnable=$info->fc_ciscoScsiInstNotifEnable();

##Collect information for tablefcifcapfrmtable
			my $fc_fcIfCapFrmRxBbCreditWriteable=$info->fc_fcIfCapFrmRxBbCreditWriteable();
			my $fc_fcIfCapFrmRxBbCreditMax=$info->fc_fcIfCapFrmRxBbCreditMax();
			my $fc_fcIfCapFrmRxBbCreditMin=$info->fc_fcIfCapFrmRxBbCreditMin();
			my $fc_fcIfCapFrmRxBbCreditDefault=$info->fc_fcIfCapFrmRxBbCreditDefault();
			my $fc_fcIfCapFrmISLRxBbCreditMax=$info->fc_fcIfCapFrmISLRxBbCreditMax();
			my $fc_fcIfCapFrmISLRxBbCreditMin=$info->fc_fcIfCapFrmISLRxBbCreditMin();
			my $fc_fcIfCapFrmISLRxBbCreditDefault=$info->fc_fcIfCapFrmISLRxBbCreditDefault();
			my $fc_fcIfCapFrmRxPerfBufWriteable=$info->fc_fcIfCapFrmRxPerfBufWriteable();
			my $fc_fcIfCapFrmRxPerfBufMax=$info->fc_fcIfCapFrmRxPerfBufMax();
			my $fc_fcIfCapFrmRxPerfBufMin=$info->fc_fcIfCapFrmRxPerfBufMin();
			my $fc_fcIfCapFrmRxPerfBufDefault=$info->fc_fcIfCapFrmRxPerfBufDefault();
			my $fc_fcIfCapFrmISLRxPerfBufMax=$info->fc_fcIfCapFrmISLRxPerfBufMax();
			my $fc_fcIfCapFrmISLRxPerfBufMin=$info->fc_fcIfCapFrmISLRxPerfBufMin();
			my $fc_fcIfCapFrmISLRxPerfBufDefault=$info->fc_fcIfCapFrmISLRxPerfBufDefault();

##Collect information for tablefcsattachportnamelisttable
			my $fc_fcsAttachPortNameListIndex=$info->fc_fcsAttachPortNameListIndex();
			my $fc_fcsAttachPortName=$info->fc_fcsAttachPortName();

##Collect information for tableciscoscsiflowstatstable
			my $fc_ciscoScsiFlowLunId=$info->fc_ciscoScsiFlowLunId();
			my $fc_ciscoScsiFlowRdIos=$info->fc_ciscoScsiFlowRdIos();
			my $fc_ciscoScsiFlowRdFailedIos=$info->fc_ciscoScsiFlowRdFailedIos();
			my $fc_ciscoScsiFlowRdTimeouts=$info->fc_ciscoScsiFlowRdTimeouts();
			my $fc_ciscoScsiFlowRdBlocks=$info->fc_ciscoScsiFlowRdBlocks();
			my $fc_ciscoScsiFlowRdMaxBlocks=$info->fc_ciscoScsiFlowRdMaxBlocks();
			my $fc_ciscoScsiFlowRdMinTime=$info->fc_ciscoScsiFlowRdMinTime();
			my $fc_ciscoScsiFlowRdMaxTime=$info->fc_ciscoScsiFlowRdMaxTime();
			my $fc_ciscoScsiFlowRdsActive=$info->fc_ciscoScsiFlowRdsActive();
			my $fc_ciscoScsiFlowWrIos=$info->fc_ciscoScsiFlowWrIos();
			my $fc_ciscoScsiFlowWrFailedIos=$info->fc_ciscoScsiFlowWrFailedIos();
			my $fc_ciscoScsiFlowWrTimeouts=$info->fc_ciscoScsiFlowWrTimeouts();
			my $fc_ciscoScsiFlowWrBlocks=$info->fc_ciscoScsiFlowWrBlocks();
			my $fc_ciscoScsiFlowWrMaxBlocks=$info->fc_ciscoScsiFlowWrMaxBlocks();
			my $fc_ciscoScsiFlowWrMinTime=$info->fc_ciscoScsiFlowWrMinTime();
			my $fc_ciscoScsiFlowWrMaxTime=$info->fc_ciscoScsiFlowWrMaxTime();
			my $fc_ciscoScsiFlowWrsActive=$info->fc_ciscoScsiFlowWrsActive();
			my $fc_ciscoScsiFlowTestUnitRdys=$info->fc_ciscoScsiFlowTestUnitRdys();
			my $fc_ciscoScsiFlowRepLuns=$info->fc_ciscoScsiFlowRepLuns();
			my $fc_ciscoScsiFlowInquirys=$info->fc_ciscoScsiFlowInquirys();
			my $fc_ciscoScsiFlowRdCapacitys=$info->fc_ciscoScsiFlowRdCapacitys();
			my $fc_ciscoScsiFlowModeSenses=$info->fc_ciscoScsiFlowModeSenses();
			my $fc_ciscoScsiFlowReqSenses=$info->fc_ciscoScsiFlowReqSenses();
			my $fc_ciscoScsiFlowRxFc2Frames=$info->fc_ciscoScsiFlowRxFc2Frames();
			my $fc_ciscoScsiFlowTxFc2Frames=$info->fc_ciscoScsiFlowTxFc2Frames();
			my $fc_ciscoScsiFlowRxFc2Octets=$info->fc_ciscoScsiFlowRxFc2Octets();
			my $fc_ciscoScsiFlowTxFc2Octets=$info->fc_ciscoScsiFlowTxFc2Octets();
			my $fc_ciscoScsiFlowBusyStatuses=$info->fc_ciscoScsiFlowBusyStatuses();
			my $fc_ciscoScsiFlowStatusResvConfs=$info->fc_ciscoScsiFlowStatusResvConfs();
			my $fc_ciscoScsiFlowTskSetFulStatuses=$info->fc_ciscoScsiFlowTskSetFulStatuses();
			my $fc_ciscoScsiFlowAcaActiveStatuses=$info->fc_ciscoScsiFlowAcaActiveStatuses();
			my $fc_ciscoScsiFlowSenseKeyNotRdyErrs=$info->fc_ciscoScsiFlowSenseKeyNotRdyErrs();
			my $fc_ciscoScsiFlowSenseKeyMedErrs=$info->fc_ciscoScsiFlowSenseKeyMedErrs();
			my $fc_ciscoScsiFlowSenseKeyHwErrs=$info->fc_ciscoScsiFlowSenseKeyHwErrs();
			my $fc_ciscoScsiFlowSenseKeyIllReqErrs=$info->fc_ciscoScsiFlowSenseKeyIllReqErrs();
			my $fc_ciscoScsiFlowSenseKeyUnitAttErrs=$info->fc_ciscoScsiFlowSenseKeyUnitAttErrs();
			my $fc_ciscoScsiFlowSenseKeyDatProtErrs=$info->fc_ciscoScsiFlowSenseKeyDatProtErrs();
			my $fc_ciscoScsiFlowSenseKeyBlankErrs=$info->fc_ciscoScsiFlowSenseKeyBlankErrs();
			my $fc_ciscoScsiFlowSenseKeyCpAbrtErrs=$info->fc_ciscoScsiFlowSenseKeyCpAbrtErrs();
			my $fc_ciscoScsiFlowSenseKeyAbrtCmdErrs=$info->fc_ciscoScsiFlowSenseKeyAbrtCmdErrs();
			my $fc_ciscoScsiFlowSenseKeyVolFlowErrs=$info->fc_ciscoScsiFlowSenseKeyVolFlowErrs();
			my $fc_ciscoScsiFlowSenseKeyMiscmpErrs=$info->fc_ciscoScsiFlowSenseKeyMiscmpErrs();
			my $fc_ciscoScsiFlowAbts=$info->fc_ciscoScsiFlowAbts();

##Collect information for tableciscoscsidevicetable
			my $fc_ciscoScsiDeviceIndex=$info->fc_ciscoScsiDeviceIndex();
			my $fc_ciscoScsiDeviceAlias=$info->fc_ciscoScsiDeviceAlias();
			my $fc_ciscoScsiDeviceRole=$info->fc_ciscoScsiDeviceRole();
			my $fc_ciscoScsiDevicePortNumber=$info->fc_ciscoScsiDevicePortNumber();
			my $fc_ciscoScsiDeviceResets=$info->fc_ciscoScsiDeviceResets();

##Collect information for tableciscoextscsipartiallundisctable
			my $fc_ciscoExtScsiPartialLunDomId=$info->fc_ciscoExtScsiPartialLunDomId();
			my $fc_ciscoExtScsiPartialLunRowStatus=$info->fc_ciscoExtScsiPartialLunRowStatus();

##Collect information for tablecsanbasesvcclustertable
			my $fc_cSanBaseSvcClusterId=$info->fc_cSanBaseSvcClusterId();
			my $fc_cSanBaseSvcClusterName=$info->fc_cSanBaseSvcClusterName();
			my $fc_cSanBaseSvcClusterState=$info->fc_cSanBaseSvcClusterState();
			my $fc_cSanBaseSvcClusterMasterInetAddrType=$info->fc_cSanBaseSvcClusterMasterInetAddrType();
			my $fc_cSanBaseSvcClusterMasterInetAddr=$info->fc_cSanBaseSvcClusterMasterInetAddr();
			my $fc_cSanBaseSvcClusterStorageType=$info->fc_cSanBaseSvcClusterStorageType();
			my $fc_cSanBaseSvcClusterRowStatus=$info->fc_cSanBaseSvcClusterRowStatus();
			my $fc_cSanBaseSvcClusterApplication=$info->fc_cSanBaseSvcClusterApplication();

##Collect information for tablecfdmihbaportentry
			my $fc_cfdmiHbaPortId=$info->fc_cfdmiHbaPortId();
			my $fc_cfdmiHbaPortSupportedFC4Type=$info->fc_cfdmiHbaPortSupportedFC4Type();
			my $fc_cfdmiHbaPortSupportedSpeed=$info->fc_cfdmiHbaPortSupportedSpeed();
			my $fc_cfdmiHbaPortCurrentSpeed=$info->fc_cfdmiHbaPortCurrentSpeed();
			my $fc_cfdmiHbaPortMaxFrameSize=$info->fc_cfdmiHbaPortMaxFrameSize();
			my $fc_cfdmiHbaPortOsDevName=$info->fc_cfdmiHbaPortOsDevName();
			my $fc_cfdmiHbaPortHostName=$info->fc_cfdmiHbaPortHostName();

##Collect information for tableciscoscsilunmaptable
			my $fc_ciscoScsiLunMapIndex=$info->fc_ciscoScsiLunMapIndex();
			my $fc_ciscoScsiLunMapLun=$info->fc_ciscoScsiLunMapLun();
			my $fc_ciscoScsiLunMapLuIndex=$info->fc_ciscoScsiLunMapLuIndex();
			my $fc_ciscoScsiLunMapRowStatus=$info->fc_ciscoScsiLunMapRowStatus();

##Collect information for tablecipnetworkinterfacetable
			my $fc_cIpNetworkGigEPortSwitchWWN=$info->fc_cIpNetworkGigEPortSwitchWWN();
			my $fc_cIpNetworkGigEPortIfIndex=$info->fc_cIpNetworkGigEPortIfIndex();
			my $fc_cIpNetworkGigEPortInetAddrType=$info->fc_cIpNetworkGigEPortInetAddrType();
			my $fc_cIpNetworkGigEPortInetAddr=$info->fc_cIpNetworkGigEPortInetAddr();

##Collect information for tablefcsportlisttable
			my $fc_fcsPortListIndex=$info->fc_fcsPortListIndex();

##Collect information for tablecspansourcesvsancfgtable
			my $fc_cspanSourcesVsanCfgSessIndex=$info->fc_cspanSourcesVsanCfgSessIndex();
			my $fc_cspanSourcesVsanCfgCommand=$info->fc_cspanSourcesVsanCfgCommand();
			my $fc_cspanSourcesVsanCfgVsans2k=$info->fc_cspanSourcesVsanCfgVsans2k();
			my $fc_cspanSourcesVsanCfgVsans4k=$info->fc_cspanSourcesVsanCfgVsans4k();

##Collect information for tablecipnetworktable
			my $fc_cIpNetworkIndex=$info->fc_cIpNetworkIndex();
			my $fc_cIpNetworkSwitchWWN=$info->fc_cIpNetworkSwitchWWN();

##Collect information for tableciscoscsiatttgtporttable
			my $fc_ciscoScsiAttTgtPortIndex=$info->fc_ciscoScsiAttTgtPortIndex();
			my $fc_ciscoScsiAttTgtPortDscTgtIdx=$info->fc_ciscoScsiAttTgtPortDscTgtIdx();
			my $fc_ciscoScsiAttTgtPortName=$info->fc_ciscoScsiAttTgtPortName();
			my $fc_ciscoScsiAttTgtPortIdentifier=$info->fc_ciscoScsiAttTgtPortIdentifier();

##Collect information for tablefcrouteflowstattable
			my $fc_fcRouteFlowIndex=$info->fc_fcRouteFlowIndex();
			my $fc_fcRouteFlowType=$info->fc_fcRouteFlowType();
			my $fc_fcRouteFlowVsanId=$info->fc_fcRouteFlowVsanId();
			my $fc_fcRouteFlowDestId=$info->fc_fcRouteFlowDestId();
			my $fc_fcRouteFlowSrcId=$info->fc_fcRouteFlowSrcId();
			my $fc_fcRouteFlowMask=$info->fc_fcRouteFlowMask();
			my $fc_fcRouteFlowPort=$info->fc_fcRouteFlowPort();
			my $fc_fcRouteFlowFrames=$info->fc_fcRouteFlowFrames();
			my $fc_fcRouteFlowBytes=$info->fc_fcRouteFlowBytes();
			my $fc_fcRouteFlowCreationTime=$info->fc_fcRouteFlowCreationTime();
			my $fc_fcRouteFlowRowStatus=$info->fc_fcRouteFlowRowStatus();

##Collect information for tablefcsietable
			my $fc_fcsIeName=$info->fc_fcsIeName();
			my $fc_fcsIeType=$info->fc_fcsIeType();
			my $fc_fcsIeDomainId=$info->fc_fcsIeDomainId();
			my $fc_fcsIeMgmtId=$info->fc_fcsIeMgmtId();
			my $fc_fcsIeFabricName=$info->fc_fcsIeFabricName();
			my $fc_fcsIeLogicalName=$info->fc_fcsIeLogicalName();
			my $fc_fcsIeMgmtAddrListIndex=$info->fc_fcsIeMgmtAddrListIndex();
			my $fc_fcsIeInfoList=$info->fc_fcsIeInfoList();
			my $fc_fcsIePortListIndex=$info->fc_fcsIePortListIndex();

			foreach my $putinv (keys %$fc_cFCCIsRateLimitingApplied){
				my $fc_cFCCEdgeQuenchPktsRecd_1=$fc_cFCCEdgeQuenchPktsRecd->{$putinv};
				my $fc_cFCCEdgeQuenchPktsSent_1=$fc_cFCCEdgeQuenchPktsSent->{$putinv};
				my $fc_cFCCPathQuenchPktsRecd_1=$fc_cFCCPathQuenchPktsRecd->{$putinv};
				my $fc_cFCCPathQuenchPktsSent_1=$fc_cFCCPathQuenchPktsSent->{$putinv};
				my $fc_cFCCCurrentCongestionState_1=$fc_cFCCCurrentCongestionState->{$putinv};
				my $fc_cFCCLastCongestedTime_1=$fc_cFCCLastCongestedTime->{$putinv};
				my $fc_cFCCLastCongestionStartTime_1=$fc_cFCCLastCongestionStartTime->{$putinv};
				my $fc_cFCCIsRateLimitingApplied_1=$fc_cFCCIsRateLimitingApplied->{$putinv};
				$cfccporttable_sth->execute($deviceid,$scantime,$fc_cFCCEdgeQuenchPktsRecd_1,$fc_cFCCEdgeQuenchPktsSent_1,$fc_cFCCPathQuenchPktsRecd_1,$fc_cFCCPathQuenchPktsSent_1,$fc_cFCCCurrentCongestionState_1,$fc_cFCCLastCongestedTime_1,$fc_cFCCLastCongestionStartTime_1,$fc_cFCCIsRateLimitingApplied_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfmMulticastRootRowStatus){
				my $fc_cfmMulticastRootConfigMode_1=$fc_cfmMulticastRootConfigMode->{$putinv};
				my $fc_cfmMulticastRootOperMode_1=$fc_cfmMulticastRootOperMode->{$putinv};
				my $fc_cfmMulticastRootDomainId_1=$fc_cfmMulticastRootDomainId->{$putinv};
				my $fc_cfmMulticastRootRowStatus_1=$fc_cfmMulticastRootRowStatus->{$putinv};
				$cfmmulticastroottable_sth->execute($deviceid,$scantime,$fc_cfmMulticastRootConfigMode_1,$fc_cfmMulticastRootOperMode_1,$fc_cfmMulticastRootDomainId_1,$fc_cfmMulticastRootRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiIntrPrtHSOutCommands){
				my $fc_ciscoScsiIntrPrtName_1=$fc_ciscoScsiIntrPrtName->{$putinv};
				my $fc_ciscoScsiIntrPrtIdentifier_1=$fc_ciscoScsiIntrPrtIdentifier->{$putinv};
				my $fc_ciscoScsiIntrPrtOutCommands_1=$fc_ciscoScsiIntrPrtOutCommands->{$putinv};
				my $fc_ciscoScsiIntrPrtWrMegaBytes_1=$fc_ciscoScsiIntrPrtWrMegaBytes->{$putinv};
				my $fc_ciscoScsiIntrPrtReadMegaBytes_1=$fc_ciscoScsiIntrPrtReadMegaBytes->{$putinv};
				my $fc_ciscoScsiIntrPrtHSOutCommands_1=$fc_ciscoScsiIntrPrtHSOutCommands->{$putinv};
				$ciscoscsiintrprttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiIntrPrtName_1,$fc_ciscoScsiIntrPrtIdentifier_1,$fc_ciscoScsiIntrPrtOutCommands_1,$fc_ciscoScsiIntrPrtWrMegaBytes_1,$fc_ciscoScsiIntrPrtReadMegaBytes_1,$fc_ciscoScsiIntrPrtHSOutCommands_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cSanBaseSvcInterfaceRowStatus){
				my $fc_cSanBaseSvcInterfaceIndex_1=$fc_cSanBaseSvcInterfaceIndex->{$putinv};
				my $fc_cSanBaseSvcInterfaceState_1=$fc_cSanBaseSvcInterfaceState->{$putinv};
				my $fc_cSanBaseSvcInterfaceClusterId_1=$fc_cSanBaseSvcInterfaceClusterId->{$putinv};
				my $fc_cSanBaseSvcInterfaceStorageType_1=$fc_cSanBaseSvcInterfaceStorageType->{$putinv};
				my $fc_cSanBaseSvcInterfaceRowStatus_1=$fc_cSanBaseSvcInterfaceRowStatus->{$putinv};
				$csanbasesvcinterfacetable_sth->execute($deviceid,$scantime,$fc_cSanBaseSvcInterfaceIndex_1,$fc_cSanBaseSvcInterfaceState_1,$fc_cSanBaseSvcInterfaceClusterId_1,$fc_cSanBaseSvcInterfaceStorageType_1,$fc_cSanBaseSvcInterfaceRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiTgtPortHSInCommands){
				my $fc_ciscoScsiTgtPortName_1=$fc_ciscoScsiTgtPortName->{$putinv};
				my $fc_ciscoScsiTgtPortIdentifier_1=$fc_ciscoScsiTgtPortIdentifier->{$putinv};
				my $fc_ciscoScsiTgtPortInCommands_1=$fc_ciscoScsiTgtPortInCommands->{$putinv};
				my $fc_ciscoScsiTgtPortWrMegaBytes_1=$fc_ciscoScsiTgtPortWrMegaBytes->{$putinv};
				my $fc_ciscoScsiTgtPortReadMegaBytes_1=$fc_ciscoScsiTgtPortReadMegaBytes->{$putinv};
				my $fc_ciscoScsiTgtPortHSInCommands_1=$fc_ciscoScsiTgtPortHSInCommands->{$putinv};
				$ciscoscsitgtporttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiTgtPortName_1,$fc_ciscoScsiTgtPortIdentifier_1,$fc_ciscoScsiTgtPortInCommands_1,$fc_ciscoScsiTgtPortWrMegaBytes_1,$fc_ciscoScsiTgtPortReadMegaBytes_1,$fc_ciscoScsiTgtPortHSInCommands_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiLuIdValue){
				my $fc_ciscoScsiLuIndex_1=$fc_ciscoScsiLuIndex->{$putinv};
				my $fc_ciscoScsiLuDefaultLun_1=$fc_ciscoScsiLuDefaultLun->{$putinv};
				my $fc_ciscoScsiLuWwnName_1=$fc_ciscoScsiLuWwnName->{$putinv};
				my $fc_ciscoScsiLuVendorId_1=$fc_ciscoScsiLuVendorId->{$putinv};
				my $fc_ciscoScsiLuProductId_1=$fc_ciscoScsiLuProductId->{$putinv};
				my $fc_ciscoScsiLuRevisionId_1=$fc_ciscoScsiLuRevisionId->{$putinv};
				my $fc_ciscoScsiLuPeripheralType_1=$fc_ciscoScsiLuPeripheralType->{$putinv};
				my $fc_ciscoScsiLuStatus_1=$fc_ciscoScsiLuStatus->{$putinv};
				my $fc_ciscoScsiLuState_1=$fc_ciscoScsiLuState->{$putinv};
				my $fc_ciscoScsiLuInCommands_1=$fc_ciscoScsiLuInCommands->{$putinv};
				my $fc_ciscoScsiLuReadMegaBytes_1=$fc_ciscoScsiLuReadMegaBytes->{$putinv};
				my $fc_ciscoScsiLuWrittenMegaBytes_1=$fc_ciscoScsiLuWrittenMegaBytes->{$putinv};
				my $fc_ciscoScsiLuInResets_1=$fc_ciscoScsiLuInResets->{$putinv};
				my $fc_ciscoScsiLuOutQueueFullStatus_1=$fc_ciscoScsiLuOutQueueFullStatus->{$putinv};
				my $fc_ciscoScsiLuHSInCommands_1=$fc_ciscoScsiLuHSInCommands->{$putinv};
				my $fc_ciscoScsiLuIdIndex_1=$fc_ciscoScsiLuIdIndex->{$putinv};
				my $fc_ciscoScsiLuIdCodeSet_1=$fc_ciscoScsiLuIdCodeSet->{$putinv};
				my $fc_ciscoScsiLuIdAssociation_1=$fc_ciscoScsiLuIdAssociation->{$putinv};
				my $fc_ciscoScsiLuIdType_1=$fc_ciscoScsiLuIdType->{$putinv};
				my $fc_ciscoScsiLuIdValue_1=$fc_ciscoScsiLuIdValue->{$putinv};
				$ciscoscsilutable_sth->execute($deviceid,$scantime,$fc_ciscoScsiLuIndex_1,$fc_ciscoScsiLuDefaultLun_1,$fc_ciscoScsiLuWwnName_1,$fc_ciscoScsiLuVendorId_1,$fc_ciscoScsiLuProductId_1,$fc_ciscoScsiLuRevisionId_1,$fc_ciscoScsiLuPeripheralType_1,$fc_ciscoScsiLuStatus_1,$fc_ciscoScsiLuState_1,$fc_ciscoScsiLuInCommands_1,$fc_ciscoScsiLuReadMegaBytes_1,$fc_ciscoScsiLuWrittenMegaBytes_1,$fc_ciscoScsiLuInResets_1,$fc_ciscoScsiLuOutQueueFullStatus_1,$fc_ciscoScsiLuHSInCommands_1,$fc_ciscoScsiLuIdIndex_1,$fc_ciscoScsiLuIdCodeSet_1,$fc_ciscoScsiLuIdAssociation_1,$fc_ciscoScsiLuIdType_1,$fc_ciscoScsiLuIdValue_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cFcSdvVirtRealDevMapRowStatus){
				my $fc_cFcSdvVirtRealDevMapIndex_1=$fc_cFcSdvVirtRealDevMapIndex->{$putinv};
				my $fc_cFcSdvVirtRealDeviceIdType_1=$fc_cFcSdvVirtRealDeviceIdType->{$putinv};
				my $fc_cFcSdvVirtRealDeviceId_1=$fc_cFcSdvVirtRealDeviceId->{$putinv};
				my $fc_cFcSdvVirtRealDevMapType_1=$fc_cFcSdvVirtRealDevMapType->{$putinv};
				my $fc_cFcSdvVirtRealDevMapStorageType_1=$fc_cFcSdvVirtRealDevMapStorageType->{$putinv};
				my $fc_cFcSdvVirtRealDevMapRowStatus_1=$fc_cFcSdvVirtRealDevMapRowStatus->{$putinv};
				$cfcsdvvirtrealdevmaptable_sth->execute($deviceid,$scantime,$fc_cFcSdvVirtRealDevMapIndex_1,$fc_cFcSdvVirtRealDeviceIdType_1,$fc_cFcSdvVirtRealDeviceId_1,$fc_cFcSdvVirtRealDevMapType_1,$fc_cFcSdvVirtRealDevMapStorageType_1,$fc_cFcSdvVirtRealDevMapRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsPlatformRowStatus){
				my $fc_fcsPlatformIndex_1=$fc_fcsPlatformIndex->{$putinv};
				my $fc_fcsPlatformName_1=$fc_fcsPlatformName->{$putinv};
				my $fc_fcsPlatformType_1=$fc_fcsPlatformType->{$putinv};
				my $fc_fcsPlatformNodeNameListIndex_1=$fc_fcsPlatformNodeNameListIndex->{$putinv};
				my $fc_fcsPlatformMgmtAddrListIndex_1=$fc_fcsPlatformMgmtAddrListIndex->{$putinv};
				my $fc_fcsPlatformConfigSource_1=$fc_fcsPlatformConfigSource->{$putinv};
				my $fc_fcsPlatformValidation_1=$fc_fcsPlatformValidation->{$putinv};
				my $fc_fcsPlatformValidationResult_1=$fc_fcsPlatformValidationResult->{$putinv};
				my $fc_fcsPlatformRowStatus_1=$fc_fcsPlatformRowStatus->{$putinv};
				$fcsplatformtable_sth->execute($deviceid,$scantime,$fc_fcsPlatformIndex_1,$fc_fcsPlatformName_1,$fc_fcsPlatformType_1,$fc_fcsPlatformNodeNameListIndex_1,$fc_fcsPlatformMgmtAddrListIndex_1,$fc_fcsPlatformConfigSource_1,$fc_fcsPlatformValidation_1,$fc_fcsPlatformValidationResult_1,$fc_fcsPlatformRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cSanBaseSvcClusterInterfaceState){
				my $fc_cSanBaseSvcClusterInterfaceIndex_1=$fc_cSanBaseSvcClusterInterfaceIndex->{$putinv};
				my $fc_cSanBaseSvcClusterInterfaceState_1=$fc_cSanBaseSvcClusterInterfaceState->{$putinv};
				$csanbasesvcclustermemberiftable_sth->execute($deviceid,$scantime,$fc_cSanBaseSvcClusterInterfaceIndex_1,$fc_cSanBaseSvcClusterInterfaceState_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsMgmtAddrRowStatus){
				my $fc_fcsMgmtAddrListIndex_1=$fc_fcsMgmtAddrListIndex->{$putinv};
				my $fc_fcsMgmtAddrIndex_1=$fc_fcsMgmtAddrIndex->{$putinv};
				my $fc_fcsMgmtAddr_1=$fc_fcsMgmtAddr->{$putinv};
				my $fc_fcsMgmtAddrConfigSource_1=$fc_fcsMgmtAddrConfigSource->{$putinv};
				my $fc_fcsMgmtAddrRowStatus_1=$fc_fcsMgmtAddrRowStatus->{$putinv};
				$fcsmgmtaddrlisttable_sth->execute($deviceid,$scantime,$fc_fcsMgmtAddrListIndex_1,$fc_fcsMgmtAddrIndex_1,$fc_fcsMgmtAddr_1,$fc_fcsMgmtAddrConfigSource_1,$fc_fcsMgmtAddrRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanVsanFilterVsans4k){
				my $fc_cspanVsanFilterSessIndex_1=$fc_cspanVsanFilterSessIndex->{$putinv};
				my $fc_cspanVsanFilterVsans2k_1=$fc_cspanVsanFilterVsans2k->{$putinv};
				my $fc_cspanVsanFilterVsans4k_1=$fc_cspanVsanFilterVsans4k->{$putinv};
				$cspanvsanfiltertable_sth->execute($deviceid,$scantime,$fc_cspanVsanFilterSessIndex_1,$fc_cspanVsanFilterVsans2k_1,$fc_cspanVsanFilterVsans4k_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiFlowRowStatus){
				my $fc_ciscoScsiFlowId_1=$fc_ciscoScsiFlowId->{$putinv};
				my $fc_ciscoScsiFlowIntrWwn_1=$fc_ciscoScsiFlowIntrWwn->{$putinv};
				my $fc_ciscoScsiFlowTargetWwn_1=$fc_ciscoScsiFlowTargetWwn->{$putinv};
				my $fc_ciscoScsiFlowIntrVsan_1=$fc_ciscoScsiFlowIntrVsan->{$putinv};
				my $fc_ciscoScsiFlowTargetVsan_1=$fc_ciscoScsiFlowTargetVsan->{$putinv};
				my $fc_ciscoScsiFlowAllLuns_1=$fc_ciscoScsiFlowAllLuns->{$putinv};
				my $fc_ciscoScsiFlowWriteAcc_1=$fc_ciscoScsiFlowWriteAcc->{$putinv};
				my $fc_ciscoScsiFlowBufCount_1=$fc_ciscoScsiFlowBufCount->{$putinv};
				my $fc_ciscoScsiFlowStatsEnabled_1=$fc_ciscoScsiFlowStatsEnabled->{$putinv};
				my $fc_ciscoScsiFlowClearStats_1=$fc_ciscoScsiFlowClearStats->{$putinv};
				my $fc_ciscoScsiFlowIntrVrfStatus_1=$fc_ciscoScsiFlowIntrVrfStatus->{$putinv};
				my $fc_ciscoScsiFlowTgtVrfStatus_1=$fc_ciscoScsiFlowTgtVrfStatus->{$putinv};
				my $fc_ciscoScsiFlowIntrLCStatus_1=$fc_ciscoScsiFlowIntrLCStatus->{$putinv};
				my $fc_ciscoScsiFlowTgtLCStatus_1=$fc_ciscoScsiFlowTgtLCStatus->{$putinv};
				my $fc_ciscoScsiFlowRowStatus_1=$fc_ciscoScsiFlowRowStatus->{$putinv};
				$ciscoscsiflowtable_sth->execute($deviceid,$scantime,$fc_ciscoScsiFlowId_1,$fc_ciscoScsiFlowIntrWwn_1,$fc_ciscoScsiFlowTargetWwn_1,$fc_ciscoScsiFlowIntrVsan_1,$fc_ciscoScsiFlowTargetVsan_1,$fc_ciscoScsiFlowAllLuns_1,$fc_ciscoScsiFlowWriteAcc_1,$fc_ciscoScsiFlowBufCount_1,$fc_ciscoScsiFlowStatsEnabled_1,$fc_ciscoScsiFlowClearStats_1,$fc_ciscoScsiFlowIntrVrfStatus_1,$fc_ciscoScsiFlowTgtVrfStatus_1,$fc_ciscoScsiFlowIntrLCStatus_1,$fc_ciscoScsiFlowTgtLCStatus_1,$fc_ciscoScsiFlowRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsNodeNameRowStatus){
				my $fc_fcsNodeNameListIndex_1=$fc_fcsNodeNameListIndex->{$putinv};
				my $fc_fcsNodeName_1=$fc_fcsNodeName->{$putinv};
				my $fc_fcsNodeNameConfigSource_1=$fc_fcsNodeNameConfigSource->{$putinv};
				my $fc_fcsNodeNameRowStatus_1=$fc_fcsNodeNameRowStatus->{$putinv};
				$fcsnodenamelisttable_sth->execute($deviceid,$scantime,$fc_fcsNodeNameListIndex_1,$fc_fcsNodeName_1,$fc_fcsNodeNameConfigSource_1,$fc_fcsNodeNameRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cFcSdvVdRowStatus){
				my $fc_cFcSdvVdIndex_1=$fc_cFcSdvVdIndex->{$putinv};
				my $fc_cFcSdvVdName_1=$fc_cFcSdvVdName->{$putinv};
				my $fc_cFcSdvVdVirtDomain_1=$fc_cFcSdvVdVirtDomain->{$putinv};
				my $fc_cFcSdvVdFcId_1=$fc_cFcSdvVdFcId->{$putinv};
				my $fc_cFcSdvVdPwwn_1=$fc_cFcSdvVdPwwn->{$putinv};
				my $fc_cFcSdvVdNwwn_1=$fc_cFcSdvVdNwwn->{$putinv};
				my $fc_cFcSdvVdAssignedFcId_1=$fc_cFcSdvVdAssignedFcId->{$putinv};
				my $fc_cFcSdvVdRealDevMapList_1=$fc_cFcSdvVdRealDevMapList->{$putinv};
				my $fc_cFcSdvVdStorageType_1=$fc_cFcSdvVdStorageType->{$putinv};
				my $fc_cFcSdvVdRowStatus_1=$fc_cFcSdvVdRowStatus->{$putinv};
				$cfcsdvvirtdevicetable_sth->execute($deviceid,$scantime,$fc_cFcSdvVdIndex_1,$fc_cFcSdvVdName_1,$fc_cFcSdvVdVirtDomain_1,$fc_cFcSdvVdFcId_1,$fc_cFcSdvVdPwwn_1,$fc_cFcSdvVdNwwn_1,$fc_cFcSdvVdAssignedFcId_1,$fc_cFcSdvVdRealDevMapList_1,$fc_cFcSdvVdStorageType_1,$fc_cFcSdvVdRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cstServiceConfigRowStatus){
				my $fc_cstCVTNodeWwn_1=$fc_cstCVTNodeWwn->{$putinv};
				my $fc_cstCVTPortWwn_1=$fc_cstCVTPortWwn->{$putinv};
				my $fc_cstServiceConfigRowStatus_1=$fc_cstServiceConfigRowStatus->{$putinv};
				$cstserviceconfigtable_sth->execute($deviceid,$scantime,$fc_cstCVTNodeWwn_1,$fc_cstCVTPortWwn_1,$fc_cstServiceConfigRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiAttIntrPrtId){
				my $fc_ciscoScsiAttIntrPrtIdx_1=$fc_ciscoScsiAttIntrPrtIdx->{$putinv};
				my $fc_ciscoScsiAttIntrPrtAuthIntrIdx_1=$fc_ciscoScsiAttIntrPrtAuthIntrIdx->{$putinv};
				my $fc_ciscoScsiAttIntrPrtName_1=$fc_ciscoScsiAttIntrPrtName->{$putinv};
				my $fc_ciscoScsiAttIntrPrtId_1=$fc_ciscoScsiAttIntrPrtId->{$putinv};
				$ciscoscsiattintrprttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiAttIntrPrtIdx_1,$fc_ciscoScsiAttIntrPrtAuthIntrIdx_1,$fc_ciscoScsiAttIntrPrtName_1,$fc_ciscoScsiAttIntrPrtId_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiIntrDevOutResets){
				my $fc_ciscoScsiIntrDevAccMode_1=$fc_ciscoScsiIntrDevAccMode->{$putinv};
				my $fc_ciscoScsiIntrDevOutResets_1=$fc_ciscoScsiIntrDevOutResets->{$putinv};
				$ciscoscsiintrdevtable_sth->execute($deviceid,$scantime,$fc_ciscoScsiIntrDevAccMode_1,$fc_ciscoScsiIntrDevOutResets_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanSourcesVsans4k){
				my $fc_cspanSourcesVsans2k_1=$fc_cspanSourcesVsans2k->{$putinv};
				my $fc_cspanSourcesVsans4k_1=$fc_cspanSourcesVsans4k->{$putinv};
				$cspansourcesvsantable_sth->execute($deviceid,$scantime,$fc_cspanSourcesVsans2k_1,$fc_cspanSourcesVsans4k_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoExtScsiLineCardOrSup){
				my $fc_ciscoExtScsiDiskGrpId_1=$fc_ciscoExtScsiDiskGrpId->{$putinv};
				my $fc_ciscoExtScsiLineCardOrSup_1=$fc_ciscoExtScsiLineCardOrSup->{$putinv};
				$ciscoextscsigeninstancetable_sth->execute($deviceid,$scantime,$fc_ciscoExtScsiDiskGrpId_1,$fc_ciscoExtScsiLineCardOrSup_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsRejects){
				my $fc_fcsRxGetReqs_1=$fc_fcsRxGetReqs->{$putinv};
				my $fc_fcsTxGetReqs_1=$fc_fcsTxGetReqs->{$putinv};
				my $fc_fcsRxRegReqs_1=$fc_fcsRxRegReqs->{$putinv};
				my $fc_fcsTxRegReqs_1=$fc_fcsTxRegReqs->{$putinv};
				my $fc_fcsRxDeregReqs_1=$fc_fcsRxDeregReqs->{$putinv};
				my $fc_fcsTxDeregReqs_1=$fc_fcsTxDeregReqs->{$putinv};
				my $fc_fcsTxRscns_1=$fc_fcsTxRscns->{$putinv};
				my $fc_fcsRxRscns_1=$fc_fcsRxRscns->{$putinv};
				my $fc_fcsRejects_1=$fc_fcsRejects->{$putinv};
				$fcsstatstable_sth->execute($deviceid,$scantime,$fc_fcsRxGetReqs_1,$fc_fcsTxGetReqs_1,$fc_fcsRxRegReqs_1,$fc_fcsTxRegReqs_1,$fc_fcsRxDeregReqs_1,$fc_fcsTxDeregReqs_1,$fc_fcsTxRscns_1,$fc_fcsRxRscns_1,$fc_fcsRejects_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcRouteRowStatus){
				my $fc_fcRouteDestAddrId_1=$fc_fcRouteDestAddrId->{$putinv};
				my $fc_fcRouteDestMask_1=$fc_fcRouteDestMask->{$putinv};
				my $fc_fcRouteProto_1=$fc_fcRouteProto->{$putinv};
				my $fc_fcRouteInterface_1=$fc_fcRouteInterface->{$putinv};
				my $fc_fcRouteDomainId_1=$fc_fcRouteDomainId->{$putinv};
				my $fc_fcRouteMetric_1=$fc_fcRouteMetric->{$putinv};
				my $fc_fcRouteType_1=$fc_fcRouteType->{$putinv};
				my $fc_fcRoutePermanent_1=$fc_fcRoutePermanent->{$putinv};
				my $fc_fcRouteRowStatus_1=$fc_fcRouteRowStatus->{$putinv};
				$fcroutetable_sth->execute($deviceid,$scantime,$fc_fcRouteDestAddrId_1,$fc_fcRouteDestMask_1,$fc_fcRouteProto_1,$fc_fcRouteInterface_1,$fc_fcRouteDomainId_1,$fc_fcRouteMetric_1,$fc_fcRouteType_1,$fc_fcRoutePermanent_1,$fc_fcRouteRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfAdminBbScnMode){
				my $fc_fcIfWwn_1=$fc_fcIfWwn->{$putinv};
				my $fc_fcIfAdminMode_1=$fc_fcIfAdminMode->{$putinv};
				my $fc_fcIfOperMode_1=$fc_fcIfOperMode->{$putinv};
				my $fc_fcIfAdminSpeed_1=$fc_fcIfAdminSpeed->{$putinv};
				my $fc_fcIfBeaconMode_1=$fc_fcIfBeaconMode->{$putinv};
				my $fc_fcIfPortChannelIfIndex_1=$fc_fcIfPortChannelIfIndex->{$putinv};
				my $fc_fcIfOperStatusCause_1=$fc_fcIfOperStatusCause->{$putinv};
				my $fc_fcIfOperStatusCauseDescr_1=$fc_fcIfOperStatusCauseDescr->{$putinv};
				my $fc_fcIfAdminTrunkMode_1=$fc_fcIfAdminTrunkMode->{$putinv};
				my $fc_fcIfOperTrunkMode_1=$fc_fcIfOperTrunkMode->{$putinv};
				my $fc_fcIfAllowedVsanList2k_1=$fc_fcIfAllowedVsanList2k->{$putinv};
				my $fc_fcIfAllowedVsanList4k_1=$fc_fcIfAllowedVsanList4k->{$putinv};
				my $fc_fcIfActiveVsanList2k_1=$fc_fcIfActiveVsanList2k->{$putinv};
				my $fc_fcIfActiveVsanList4k_1=$fc_fcIfActiveVsanList4k->{$putinv};
				my $fc_fcIfBbCreditModel_1=$fc_fcIfBbCreditModel->{$putinv};
				my $fc_fcIfHoldTime_1=$fc_fcIfHoldTime->{$putinv};
				my $fc_fcIfTransmitterType_1=$fc_fcIfTransmitterType->{$putinv};
				my $fc_fcIfConnectorType_1=$fc_fcIfConnectorType->{$putinv};
				my $fc_fcIfSerialNo_1=$fc_fcIfSerialNo->{$putinv};
				my $fc_fcIfRevision_1=$fc_fcIfRevision->{$putinv};
				my $fc_fcIfVendor_1=$fc_fcIfVendor->{$putinv};
				my $fc_fcIfSFPSerialIDData_1=$fc_fcIfSFPSerialIDData->{$putinv};
				my $fc_fcIfPartNumber_1=$fc_fcIfPartNumber->{$putinv};
				my $fc_fcIfAdminRxBbCredit_1=$fc_fcIfAdminRxBbCredit->{$putinv};
				my $fc_fcIfAdminRxBbCreditModeISL_1=$fc_fcIfAdminRxBbCreditModeISL->{$putinv};
				my $fc_fcIfAdminRxBbCreditModeFx_1=$fc_fcIfAdminRxBbCreditModeFx->{$putinv};
				my $fc_fcIfOperRxBbCredit_1=$fc_fcIfOperRxBbCredit->{$putinv};
				my $fc_fcIfRxDataFieldSize_1=$fc_fcIfRxDataFieldSize->{$putinv};
				my $fc_fcIfActiveVsanUpList2k_1=$fc_fcIfActiveVsanUpList2k->{$putinv};
				my $fc_fcIfActiveVsanUpList4k_1=$fc_fcIfActiveVsanUpList4k->{$putinv};
				my $fc_fcIfPortRateMode_1=$fc_fcIfPortRateMode->{$putinv};
				my $fc_fcIfAdminRxPerfBuffer_1=$fc_fcIfAdminRxPerfBuffer->{$putinv};
				my $fc_fcIfOperRxPerfBuffer_1=$fc_fcIfOperRxPerfBuffer->{$putinv};
				my $fc_fcIfBbScn_1=$fc_fcIfBbScn->{$putinv};
				my $fc_fcIfPortInitStatus_1=$fc_fcIfPortInitStatus->{$putinv};
				my $fc_fcIfAdminRxBbCreditExtended_1=$fc_fcIfAdminRxBbCreditExtended->{$putinv};
				my $fc_fcIfFcTunnelIfIndex_1=$fc_fcIfFcTunnelIfIndex->{$putinv};
				my $fc_fcIfServiceState_1=$fc_fcIfServiceState->{$putinv};
				my $fc_fcIfAdminBbScnMode_1=$fc_fcIfAdminBbScnMode->{$putinv};
				$fciftable_sth->execute($deviceid,$scantime,$fc_fcIfWwn_1,$fc_fcIfAdminMode_1,$fc_fcIfOperMode_1,$fc_fcIfAdminSpeed_1,$fc_fcIfBeaconMode_1,$fc_fcIfPortChannelIfIndex_1,$fc_fcIfOperStatusCause_1,$fc_fcIfOperStatusCauseDescr_1,$fc_fcIfAdminTrunkMode_1,$fc_fcIfOperTrunkMode_1,$fc_fcIfAllowedVsanList2k_1,$fc_fcIfAllowedVsanList4k_1,$fc_fcIfActiveVsanList2k_1,$fc_fcIfActiveVsanList4k_1,$fc_fcIfBbCreditModel_1,$fc_fcIfHoldTime_1,$fc_fcIfTransmitterType_1,$fc_fcIfConnectorType_1,$fc_fcIfSerialNo_1,$fc_fcIfRevision_1,$fc_fcIfVendor_1,$fc_fcIfSFPSerialIDData_1,$fc_fcIfPartNumber_1,$fc_fcIfAdminRxBbCredit_1,$fc_fcIfAdminRxBbCreditModeISL_1,$fc_fcIfAdminRxBbCreditModeFx_1,$fc_fcIfOperRxBbCredit_1,$fc_fcIfRxDataFieldSize_1,$fc_fcIfActiveVsanUpList2k_1,$fc_fcIfActiveVsanUpList4k_1,$fc_fcIfPortRateMode_1,$fc_fcIfAdminRxPerfBuffer_1,$fc_fcIfOperRxPerfBuffer_1,$fc_fcIfBbScn_1,$fc_fcIfPortInitStatus_1,$fc_fcIfAdminRxBbCreditExtended_1,$fc_fcIfFcTunnelIfIndex_1,$fc_fcIfServiceState_1,$fc_fcIfAdminBbScnMode_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfcspIfAuthByPassed){
				my $fc_cfcspIfAuthSucceeded_1=$fc_cfcspIfAuthSucceeded->{$putinv};
				my $fc_cfcspIfAuthFailed_1=$fc_cfcspIfAuthFailed->{$putinv};
				my $fc_cfcspIfAuthByPassed_1=$fc_cfcspIfAuthByPassed->{$putinv};
				$cfcspifstatstable_sth->execute($deviceid,$scantime,$fc_cfcspIfAuthSucceeded_1,$fc_cfcspIfAuthFailed_1,$fc_cfcspIfAuthByPassed_1,$putinv);
			}
			foreach my $putinv (keys %$fc_virtualNwIfRowStatus){
				my $fc_virtualNwIfType_1=$fc_virtualNwIfType->{$putinv};
				my $fc_virtualNwIfId_1=$fc_virtualNwIfId->{$putinv};
				my $fc_virtualNwIfIndex_1=$fc_virtualNwIfIndex->{$putinv};
				my $fc_virtualNwIfFcId_1=$fc_virtualNwIfFcId->{$putinv};
				my $fc_virtualNwIfOperStatusCause_1=$fc_virtualNwIfOperStatusCause->{$putinv};
				my $fc_virtualNwIfOperStatusCauseDescr_1=$fc_virtualNwIfOperStatusCauseDescr->{$putinv};
				my $fc_virtualNwIfRowStatus_1=$fc_virtualNwIfRowStatus->{$putinv};
				$virtualnwiftable_sth->execute($deviceid,$scantime,$fc_virtualNwIfType_1,$fc_virtualNwIfId_1,$fc_virtualNwIfIndex_1,$fc_virtualNwIfFcId_1,$fc_virtualNwIfOperStatusCause_1,$fc_virtualNwIfOperStatusCauseDescr_1,$fc_virtualNwIfRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfNonLipF8Out){
				my $fc_fcIfLinkFailures_1=$fc_fcIfLinkFailures->{$putinv};
				my $fc_fcIfSyncLosses_1=$fc_fcIfSyncLosses->{$putinv};
				my $fc_fcIfSigLosses_1=$fc_fcIfSigLosses->{$putinv};
				my $fc_fcIfPrimSeqProtoErrors_1=$fc_fcIfPrimSeqProtoErrors->{$putinv};
				my $fc_fcIfInvalidTxWords_1=$fc_fcIfInvalidTxWords->{$putinv};
				my $fc_fcIfInvalidCrcs_1=$fc_fcIfInvalidCrcs->{$putinv};
				my $fc_fcIfDelimiterErrors_1=$fc_fcIfDelimiterErrors->{$putinv};
				my $fc_fcIfAddressIdErrors_1=$fc_fcIfAddressIdErrors->{$putinv};
				my $fc_fcIfLinkResetIns_1=$fc_fcIfLinkResetIns->{$putinv};
				my $fc_fcIfLinkResetOuts_1=$fc_fcIfLinkResetOuts->{$putinv};
				my $fc_fcIfOlsIns_1=$fc_fcIfOlsIns->{$putinv};
				my $fc_fcIfOlsOuts_1=$fc_fcIfOlsOuts->{$putinv};
				my $fc_fcIfRuntFramesIn_1=$fc_fcIfRuntFramesIn->{$putinv};
				my $fc_fcIfJabberFramesIn_1=$fc_fcIfJabberFramesIn->{$putinv};
				my $fc_fcIfTxWaitCount_1=$fc_fcIfTxWaitCount->{$putinv};
				my $fc_fcIfFramesTooLong_1=$fc_fcIfFramesTooLong->{$putinv};
				my $fc_fcIfFramesTooShort_1=$fc_fcIfFramesTooShort->{$putinv};
				my $fc_fcIfLRRIn_1=$fc_fcIfLRRIn->{$putinv};
				my $fc_fcIfLRROut_1=$fc_fcIfLRROut->{$putinv};
				my $fc_fcIfNOSIn_1=$fc_fcIfNOSIn->{$putinv};
				my $fc_fcIfNOSOut_1=$fc_fcIfNOSOut->{$putinv};
				my $fc_fcIfFragFrames_1=$fc_fcIfFragFrames->{$putinv};
				my $fc_fcIfEOFaFrames_1=$fc_fcIfEOFaFrames->{$putinv};
				my $fc_fcIfUnknownClassFrames_1=$fc_fcIfUnknownClassFrames->{$putinv};
				my $fc_fcIf8b10bDisparityErrors_1=$fc_fcIf8b10bDisparityErrors->{$putinv};
				my $fc_fcIfFramesDiscard_1=$fc_fcIfFramesDiscard->{$putinv};
				my $fc_fcIfELPFailures_1=$fc_fcIfELPFailures->{$putinv};
				my $fc_fcIfBBCreditTransistionFromZero_1=$fc_fcIfBBCreditTransistionFromZero->{$putinv};
				my $fc_fcIfEISLFramesDiscard_1=$fc_fcIfEISLFramesDiscard->{$putinv};
				my $fc_fcIfFramingErrorFrames_1=$fc_fcIfFramingErrorFrames->{$putinv};
				my $fc_fcIfLipF8In_1=$fc_fcIfLipF8In->{$putinv};
				my $fc_fcIfLipF8Out_1=$fc_fcIfLipF8Out->{$putinv};
				my $fc_fcIfNonLipF8In_1=$fc_fcIfNonLipF8In->{$putinv};
				my $fc_fcIfNonLipF8Out_1=$fc_fcIfNonLipF8Out->{$putinv};
				$fciferrortable_sth->execute($deviceid,$scantime,$fc_fcIfLinkFailures_1,$fc_fcIfSyncLosses_1,$fc_fcIfSigLosses_1,$fc_fcIfPrimSeqProtoErrors_1,$fc_fcIfInvalidTxWords_1,$fc_fcIfInvalidCrcs_1,$fc_fcIfDelimiterErrors_1,$fc_fcIfAddressIdErrors_1,$fc_fcIfLinkResetIns_1,$fc_fcIfLinkResetOuts_1,$fc_fcIfOlsIns_1,$fc_fcIfOlsOuts_1,$fc_fcIfRuntFramesIn_1,$fc_fcIfJabberFramesIn_1,$fc_fcIfTxWaitCount_1,$fc_fcIfFramesTooLong_1,$fc_fcIfFramesTooShort_1,$fc_fcIfLRRIn_1,$fc_fcIfLRROut_1,$fc_fcIfNOSIn_1,$fc_fcIfNOSOut_1,$fc_fcIfFragFrames_1,$fc_fcIfEOFaFrames_1,$fc_fcIfUnknownClassFrames_1,$fc_fcIf8b10bDisparityErrors_1,$fc_fcIfFramesDiscard_1,$fc_fcIfELPFailures_1,$fc_fcIfBBCreditTransistionFromZero_1,$fc_fcIfEISLFramesDiscard_1,$fc_fcIfFramingErrorFrames_1,$fc_fcIfLipF8In_1,$fc_fcIfLipF8Out_1,$fc_fcIfNonLipF8In_1,$fc_fcIfNonLipF8Out_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcTraceRouteHopsHopLatency){
				my $fc_fcTraceRouteHopsHopIndex_1=$fc_fcTraceRouteHopsHopIndex->{$putinv};
				my $fc_fcTraceRouteHopsHopAddr_1=$fc_fcTraceRouteHopsHopAddr->{$putinv};
				my $fc_fcTraceRouteHopsHopLatencyValid_1=$fc_fcTraceRouteHopsHopLatencyValid->{$putinv};
				my $fc_fcTraceRouteHopsHopLatency_1=$fc_fcTraceRouteHopsHopLatency->{$putinv};
				$fctraceroutehopstable_sth->execute($deviceid,$scantime,$fc_fcTraceRouteHopsHopIndex_1,$fc_fcTraceRouteHopsHopAddr_1,$fc_fcTraceRouteHopsHopLatencyValid_1,$fc_fcTraceRouteHopsHopLatency_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiAuthIntrRowStatus){
				my $fc_ciscoScsiAuthIntrTgtPortIndex_1=$fc_ciscoScsiAuthIntrTgtPortIndex->{$putinv};
				my $fc_ciscoScsiAuthIntrIndex_1=$fc_ciscoScsiAuthIntrIndex->{$putinv};
				my $fc_ciscoScsiAuthIntrDevOrPort_1=$fc_ciscoScsiAuthIntrDevOrPort->{$putinv};
				my $fc_ciscoScsiAuthIntrName_1=$fc_ciscoScsiAuthIntrName->{$putinv};
				my $fc_ciscoScsiAuthIntrLunMapIndex_1=$fc_ciscoScsiAuthIntrLunMapIndex->{$putinv};
				my $fc_ciscoScsiAuthIntrAttachedTimes_1=$fc_ciscoScsiAuthIntrAttachedTimes->{$putinv};
				my $fc_ciscoScsiAuthIntrOutCommands_1=$fc_ciscoScsiAuthIntrOutCommands->{$putinv};
				my $fc_ciscoScsiAuthIntrReadMegaBytes_1=$fc_ciscoScsiAuthIntrReadMegaBytes->{$putinv};
				my $fc_ciscoScsiAuthIntrWrMegaBytes_1=$fc_ciscoScsiAuthIntrWrMegaBytes->{$putinv};
				my $fc_ciscoScsiAuthIntrHSOutCommands_1=$fc_ciscoScsiAuthIntrHSOutCommands->{$putinv};
				my $fc_ciscoScsiAuthIntrLastCreation_1=$fc_ciscoScsiAuthIntrLastCreation->{$putinv};
				my $fc_ciscoScsiAuthIntrRowStatus_1=$fc_ciscoScsiAuthIntrRowStatus->{$putinv};
				$ciscoscsiauthorizedintrtable_sth->execute($deviceid,$scantime,$fc_ciscoScsiAuthIntrTgtPortIndex_1,$fc_ciscoScsiAuthIntrIndex_1,$fc_ciscoScsiAuthIntrDevOrPort_1,$fc_ciscoScsiAuthIntrName_1,$fc_ciscoScsiAuthIntrLunMapIndex_1,$fc_ciscoScsiAuthIntrAttachedTimes_1,$fc_ciscoScsiAuthIntrOutCommands_1,$fc_ciscoScsiAuthIntrReadMegaBytes_1,$fc_ciscoScsiAuthIntrWrMegaBytes_1,$fc_ciscoScsiAuthIntrHSOutCommands_1,$fc_ciscoScsiAuthIntrLastCreation_1,$fc_ciscoScsiAuthIntrRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cstModuleId){
				my $fc_cstModuleId_1=$fc_cstModuleId->{$putinv};
				$cstmoduletable_sth->execute($deviceid,$scantime,$fc_cstModuleId_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfElpClassFOpenSeq){
				my $fc_fcIfElpNbrNodeName_1=$fc_fcIfElpNbrNodeName->{$putinv};
				my $fc_fcIfElpNbrPortName_1=$fc_fcIfElpNbrPortName->{$putinv};
				my $fc_fcIfElpRxBbCredit_1=$fc_fcIfElpRxBbCredit->{$putinv};
				my $fc_fcIfElpTxBbCredit_1=$fc_fcIfElpTxBbCredit->{$putinv};
				my $fc_fcIfElpCosSuppAgreed_1=$fc_fcIfElpCosSuppAgreed->{$putinv};
				my $fc_fcIfElpClass2SeqDelivAgreed_1=$fc_fcIfElpClass2SeqDelivAgreed->{$putinv};
				my $fc_fcIfElpClass2RxDataFieldSize_1=$fc_fcIfElpClass2RxDataFieldSize->{$putinv};
				my $fc_fcIfElpClass3SeqDelivAgreed_1=$fc_fcIfElpClass3SeqDelivAgreed->{$putinv};
				my $fc_fcIfElpClass3RxDataFieldSize_1=$fc_fcIfElpClass3RxDataFieldSize->{$putinv};
				my $fc_fcIfElpClassFXII_1=$fc_fcIfElpClassFXII->{$putinv};
				my $fc_fcIfElpClassFRxDataFieldSize_1=$fc_fcIfElpClassFRxDataFieldSize->{$putinv};
				my $fc_fcIfElpClassFConcurrentSeq_1=$fc_fcIfElpClassFConcurrentSeq->{$putinv};
				my $fc_fcIfElpClassFEndToEndCredit_1=$fc_fcIfElpClassFEndToEndCredit->{$putinv};
				my $fc_fcIfElpClassFOpenSeq_1=$fc_fcIfElpClassFOpenSeq->{$putinv};
				$fcifelptable_sth->execute($deviceid,$scantime,$fc_fcIfElpNbrNodeName_1,$fc_fcIfElpNbrPortName_1,$fc_fcIfElpRxBbCredit_1,$fc_fcIfElpTxBbCredit_1,$fc_fcIfElpCosSuppAgreed_1,$fc_fcIfElpClass2SeqDelivAgreed_1,$fc_fcIfElpClass2RxDataFieldSize_1,$fc_fcIfElpClass3SeqDelivAgreed_1,$fc_fcIfElpClass3RxDataFieldSize_1,$fc_fcIfElpClassFXII_1,$fc_fcIfElpClassFRxDataFieldSize_1,$fc_fcIfElpClassFConcurrentSeq_1,$fc_fcIfElpClassFEndToEndCredit_1,$fc_fcIfElpClassFOpenSeq_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcPingNumTimeouts){
				my $fc_fcPingTxPackets_1=$fc_fcPingTxPackets->{$putinv};
				my $fc_fcPingRxPackets_1=$fc_fcPingRxPackets->{$putinv};
				my $fc_fcPingMinRtt_1=$fc_fcPingMinRtt->{$putinv};
				my $fc_fcPingAvgRtt_1=$fc_fcPingAvgRtt->{$putinv};
				my $fc_fcPingMaxRtt_1=$fc_fcPingMaxRtt->{$putinv};
				my $fc_fcPingNumTimeouts_1=$fc_fcPingNumTimeouts->{$putinv};
				$fcpingstatstable_sth->execute($deviceid,$scantime,$fc_fcPingTxPackets_1,$fc_fcPingRxPackets_1,$fc_fcPingMinRtt_1,$fc_fcPingAvgRtt_1,$fc_fcPingMaxRtt_1,$fc_fcPingNumTimeouts_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiDscTgtRowStatus){
				my $fc_ciscoScsiDscTgtIntrPortIndex_1=$fc_ciscoScsiDscTgtIntrPortIndex->{$putinv};
				my $fc_ciscoScsiDscTgtIndex_1=$fc_ciscoScsiDscTgtIndex->{$putinv};
				my $fc_ciscoScsiDscTgtDevOrPort_1=$fc_ciscoScsiDscTgtDevOrPort->{$putinv};
				my $fc_ciscoScsiDscTgtName_1=$fc_ciscoScsiDscTgtName->{$putinv};
				my $fc_ciscoScsiDscTgtConfigured_1=$fc_ciscoScsiDscTgtConfigured->{$putinv};
				my $fc_ciscoScsiDscTgtDiscovered_1=$fc_ciscoScsiDscTgtDiscovered->{$putinv};
				my $fc_ciscoScsiDscTgtInCommands_1=$fc_ciscoScsiDscTgtInCommands->{$putinv};
				my $fc_ciscoScsiDscTgtWrMegaBytes_1=$fc_ciscoScsiDscTgtWrMegaBytes->{$putinv};
				my $fc_ciscoScsiDscTgtReadMegaBytes_1=$fc_ciscoScsiDscTgtReadMegaBytes->{$putinv};
				my $fc_ciscoScsiDscTgtHSInCommands_1=$fc_ciscoScsiDscTgtHSInCommands->{$putinv};
				my $fc_ciscoScsiDscTgtLastCreation_1=$fc_ciscoScsiDscTgtLastCreation->{$putinv};
				my $fc_ciscoScsiDscTgtRowStatus_1=$fc_ciscoScsiDscTgtRowStatus->{$putinv};
				$ciscoscsidsctgttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiDscTgtIntrPortIndex_1,$fc_ciscoScsiDscTgtIndex_1,$fc_ciscoScsiDscTgtDevOrPort_1,$fc_ciscoScsiDscTgtName_1,$fc_ciscoScsiDscTgtConfigured_1,$fc_ciscoScsiDscTgtDiscovered_1,$fc_ciscoScsiDscTgtInCommands_1,$fc_ciscoScsiDscTgtWrMegaBytes_1,$fc_ciscoScsiDscTgtReadMegaBytes_1,$fc_ciscoScsiDscTgtHSInCommands_1,$fc_ciscoScsiDscTgtLastCreation_1,$fc_ciscoScsiDscTgtRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanSourcesRowStatus){
				my $fc_cspanSourcesIfIndex_1=$fc_cspanSourcesIfIndex->{$putinv};
				my $fc_cspanSourcesDirection_1=$fc_cspanSourcesDirection->{$putinv};
				my $fc_cspanSourcesRowStatus_1=$fc_cspanSourcesRowStatus->{$putinv};
				$cspansourcesiftable_sth->execute($deviceid,$scantime,$fc_cspanSourcesIfIndex_1,$fc_cspanSourcesDirection_1,$fc_cspanSourcesRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfC2PRJTFrames){
				my $fc_fcIfC2InFrames_1=$fc_fcIfC2InFrames->{$putinv};
				my $fc_fcIfC2OutFrames_1=$fc_fcIfC2OutFrames->{$putinv};
				my $fc_fcIfC2InOctets_1=$fc_fcIfC2InOctets->{$putinv};
				my $fc_fcIfC2OutOctets_1=$fc_fcIfC2OutOctets->{$putinv};
				my $fc_fcIfC2Discards_1=$fc_fcIfC2Discards->{$putinv};
				my $fc_fcIfC2FbsyFrames_1=$fc_fcIfC2FbsyFrames->{$putinv};
				my $fc_fcIfC2FrjtFrames_1=$fc_fcIfC2FrjtFrames->{$putinv};
				my $fc_fcIfC2PBSYFrames_1=$fc_fcIfC2PBSYFrames->{$putinv};
				my $fc_fcIfC2PRJTFrames_1=$fc_fcIfC2PRJTFrames->{$putinv};
				$fcifc2accountingtable_sth->execute($deviceid,$scantime,$fc_fcIfC2InFrames_1,$fc_fcIfC2OutFrames_1,$fc_fcIfC2InOctets_1,$fc_fcIfC2OutOctets_1,$fc_fcIfC2Discards_1,$fc_fcIfC2FbsyFrames_1,$fc_fcIfC2FrjtFrames_1,$fc_fcIfC2PBSYFrames_1,$fc_fcIfC2PRJTFrames_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiDscLunLun){
				my $fc_ciscoScsiDscLunIndex_1=$fc_ciscoScsiDscLunIndex->{$putinv};
				my $fc_ciscoScsiDscLunLun_1=$fc_ciscoScsiDscLunLun->{$putinv};
				$ciscoscsidscluntable_sth->execute($deviceid,$scantime,$fc_ciscoScsiDscLunIndex_1,$fc_ciscoScsiDscLunLun_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfCapOsmFrmCapable){
				my $fc_fcIfCapFcphVersionHigh_1=$fc_fcIfCapFcphVersionHigh->{$putinv};
				my $fc_fcIfCapFcphVersionLow_1=$fc_fcIfCapFcphVersionLow->{$putinv};
				my $fc_fcIfCapRxBbCreditMax_1=$fc_fcIfCapRxBbCreditMax->{$putinv};
				my $fc_fcIfCapRxBbCreditMin_1=$fc_fcIfCapRxBbCreditMin->{$putinv};
				my $fc_fcIfCapRxDataFieldSizeMax_1=$fc_fcIfCapRxDataFieldSizeMax->{$putinv};
				my $fc_fcIfCapRxDataFieldSizeMin_1=$fc_fcIfCapRxDataFieldSizeMin->{$putinv};
				my $fc_fcIfCapCos_1=$fc_fcIfCapCos->{$putinv};
				my $fc_fcIfCapClass2SeqDeliv_1=$fc_fcIfCapClass2SeqDeliv->{$putinv};
				my $fc_fcIfCapClass3SeqDeliv_1=$fc_fcIfCapClass3SeqDeliv->{$putinv};
				my $fc_fcIfCapHoldTimeMax_1=$fc_fcIfCapHoldTimeMax->{$putinv};
				my $fc_fcIfCapHoldTimeMin_1=$fc_fcIfCapHoldTimeMin->{$putinv};
				my $fc_fcIfCapISLRxBbCreditMax_1=$fc_fcIfCapISLRxBbCreditMax->{$putinv};
				my $fc_fcIfCapISLRxBbCreditMin_1=$fc_fcIfCapISLRxBbCreditMin->{$putinv};
				my $fc_fcIfCapRxBbCreditWriteable_1=$fc_fcIfCapRxBbCreditWriteable->{$putinv};
				my $fc_fcIfCapRxBbCreditDefault_1=$fc_fcIfCapRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapISLRxBbCreditDefault_1=$fc_fcIfCapISLRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapBbScnCapable_1=$fc_fcIfCapBbScnCapable->{$putinv};
				my $fc_fcIfCapBbScnMax_1=$fc_fcIfCapBbScnMax->{$putinv};
				my $fc_fcIfCapOsmFrmCapable_1=$fc_fcIfCapOsmFrmCapable->{$putinv};
				$fcifcaptable_sth->execute($deviceid,$scantime,$fc_fcIfCapFcphVersionHigh_1,$fc_fcIfCapFcphVersionLow_1,$fc_fcIfCapRxBbCreditMax_1,$fc_fcIfCapRxBbCreditMin_1,$fc_fcIfCapRxDataFieldSizeMax_1,$fc_fcIfCapRxDataFieldSizeMin_1,$fc_fcIfCapCos_1,$fc_fcIfCapClass2SeqDeliv_1,$fc_fcIfCapClass3SeqDeliv_1,$fc_fcIfCapHoldTimeMax_1,$fc_fcIfCapHoldTimeMin_1,$fc_fcIfCapISLRxBbCreditMax_1,$fc_fcIfCapISLRxBbCreditMin_1,$fc_fcIfCapRxBbCreditWriteable_1,$fc_fcIfCapRxBbCreditDefault_1,$fc_fcIfCapISLRxBbCreditDefault_1,$fc_fcIfCapBbScnCapable_1,$fc_fcIfCapBbScnMax_1,$fc_fcIfCapOsmFrmCapable_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcTraceRouteRowStatus){
				my $fc_fcTraceRouteIndex_1=$fc_fcTraceRouteIndex->{$putinv};
				my $fc_fcTraceRouteVsanIndex_1=$fc_fcTraceRouteVsanIndex->{$putinv};
				my $fc_fcTraceRouteTargetAddrType_1=$fc_fcTraceRouteTargetAddrType->{$putinv};
				my $fc_fcTraceRouteTargetAddr_1=$fc_fcTraceRouteTargetAddr->{$putinv};
				my $fc_fcTraceRouteTimeout_1=$fc_fcTraceRouteTimeout->{$putinv};
				my $fc_fcTraceRouteAdminStatus_1=$fc_fcTraceRouteAdminStatus->{$putinv};
				my $fc_fcTraceRouteOperStatus_1=$fc_fcTraceRouteOperStatus->{$putinv};
				my $fc_fcTraceRouteAgeInterval_1=$fc_fcTraceRouteAgeInterval->{$putinv};
				my $fc_fcTraceRouteTrapOnCompletion_1=$fc_fcTraceRouteTrapOnCompletion->{$putinv};
				my $fc_fcTraceRouteRowStatus_1=$fc_fcTraceRouteRowStatus->{$putinv};
				$fctraceroutetable_sth->execute($deviceid,$scantime,$fc_fcTraceRouteIndex_1,$fc_fcTraceRouteVsanIndex_1,$fc_fcTraceRouteTargetAddrType_1,$fc_fcTraceRouteTargetAddr_1,$fc_fcTraceRouteTimeout_1,$fc_fcTraceRouteAdminStatus_1,$fc_fcTraceRouteOperStatus_1,$fc_fcTraceRouteAgeInterval_1,$fc_fcTraceRouteTrapOnCompletion_1,$fc_fcTraceRouteRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfNxClass3SeqDelivAgreed){
				my $fc_fcIfNxLoginIndex_1=$fc_fcIfNxLoginIndex->{$putinv};
				my $fc_fcIfNxPortNodeName_1=$fc_fcIfNxPortNodeName->{$putinv};
				my $fc_fcIfNxPortName_1=$fc_fcIfNxPortName->{$putinv};
				my $fc_fcIfNxPortAddress_1=$fc_fcIfNxPortAddress->{$putinv};
				my $fc_fcIfNxFcphVersionAgreed_1=$fc_fcIfNxFcphVersionAgreed->{$putinv};
				my $fc_fcIfNxRxBbCredit_1=$fc_fcIfNxRxBbCredit->{$putinv};
				my $fc_fcIfNxTxBbCredit_1=$fc_fcIfNxTxBbCredit->{$putinv};
				my $fc_fcIfNxClass2RxDataFieldSize_1=$fc_fcIfNxClass2RxDataFieldSize->{$putinv};
				my $fc_fcIfNxClass3RxDataFieldSize_1=$fc_fcIfNxClass3RxDataFieldSize->{$putinv};
				my $fc_fcIfNxCosSuppAgreed_1=$fc_fcIfNxCosSuppAgreed->{$putinv};
				my $fc_fcIfNxClass2SeqDelivAgreed_1=$fc_fcIfNxClass2SeqDelivAgreed->{$putinv};
				my $fc_fcIfNxClass3SeqDelivAgreed_1=$fc_fcIfNxClass3SeqDelivAgreed->{$putinv};
				$fcifflogintable_sth->execute($deviceid,$scantime,$fc_fcIfNxLoginIndex_1,$fc_fcIfNxPortNodeName_1,$fc_fcIfNxPortName_1,$fc_fcIfNxPortAddress_1,$fc_fcIfNxFcphVersionAgreed_1,$fc_fcIfNxRxBbCredit_1,$fc_fcIfNxTxBbCredit_1,$fc_fcIfNxClass2RxDataFieldSize_1,$fc_fcIfNxClass3RxDataFieldSize_1,$fc_fcIfNxCosSuppAgreed_1,$fc_fcIfNxClass2SeqDelivAgreed_1,$fc_fcIfNxClass3SeqDelivAgreed_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoExtScsiIntrDiscTgtOtherInfo){
				my $fc_ciscoExtScsiIntrDiscTgtVsanId_1=$fc_ciscoExtScsiIntrDiscTgtVsanId->{$putinv};
				my $fc_ciscoExtScsiIntrDiscTgtDevType_1=$fc_ciscoExtScsiIntrDiscTgtDevType->{$putinv};
				my $fc_ciscoExtScsiIntrDiscTgtVendorId_1=$fc_ciscoExtScsiIntrDiscTgtVendorId->{$putinv};
				my $fc_ciscoExtScsiIntrDiscTgtProductId_1=$fc_ciscoExtScsiIntrDiscTgtProductId->{$putinv};
				my $fc_ciscoExtScsiIntrDiscTgtRevLevel_1=$fc_ciscoExtScsiIntrDiscTgtRevLevel->{$putinv};
				my $fc_ciscoExtScsiIntrDiscTgtOtherInfo_1=$fc_ciscoExtScsiIntrDiscTgtOtherInfo->{$putinv};
				$ciscoextscsiintrdisctgttable_sth->execute($deviceid,$scantime,$fc_ciscoExtScsiIntrDiscTgtVsanId_1,$fc_ciscoExtScsiIntrDiscTgtDevType_1,$fc_ciscoExtScsiIntrDiscTgtVendorId_1,$fc_ciscoExtScsiIntrDiscTgtProductId_1,$fc_ciscoExtScsiIntrDiscTgtRevLevel_1,$fc_ciscoExtScsiIntrDiscTgtOtherInfo_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfCfDiscards){
				my $fc_fcIfCfInFrames_1=$fc_fcIfCfInFrames->{$putinv};
				my $fc_fcIfCfOutFrames_1=$fc_fcIfCfOutFrames->{$putinv};
				my $fc_fcIfCfInOctets_1=$fc_fcIfCfInOctets->{$putinv};
				my $fc_fcIfCfOutOctets_1=$fc_fcIfCfOutOctets->{$putinv};
				my $fc_fcIfCfDiscards_1=$fc_fcIfCfDiscards->{$putinv};
				$fcifcfaccountingtable_sth->execute($deviceid,$scantime,$fc_fcIfCfInFrames_1,$fc_fcIfCfOutFrames_1,$fc_fcIfCfInOctets_1,$fc_fcIfCfOutOctets_1,$fc_fcIfCfDiscards_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsPortState){
				my $fc_fcsPortName_1=$fc_fcsPortName->{$putinv};
				my $fc_fcsPortType_1=$fc_fcsPortType->{$putinv};
				my $fc_fcsPortTXType_1=$fc_fcsPortTXType->{$putinv};
				my $fc_fcsPortModuleType_1=$fc_fcsPortModuleType->{$putinv};
				my $fc_fcsPortPhyPortNum_1=$fc_fcsPortPhyPortNum->{$putinv};
				my $fc_fcsPortAttachPortNameIndex_1=$fc_fcsPortAttachPortNameIndex->{$putinv};
				my $fc_fcsPortState_1=$fc_fcsPortState->{$putinv};
				$fcsporttable_sth->execute($deviceid,$scantime,$fc_fcsPortName_1,$fc_fcsPortType_1,$fc_fcsPortTXType_1,$fc_fcsPortModuleType_1,$fc_fcsPortPhyPortNum_1,$fc_fcsPortAttachPortNameIndex_1,$fc_fcsPortState_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiTgtDevNonAccLUs){
				my $fc_ciscoScsiTgtDevNumberOfLUs_1=$fc_ciscoScsiTgtDevNumberOfLUs->{$putinv};
				my $fc_ciscoScsiTgtDeviceStatus_1=$fc_ciscoScsiTgtDeviceStatus->{$putinv};
				my $fc_ciscoScsiTgtDevNonAccLUs_1=$fc_ciscoScsiTgtDevNonAccLUs->{$putinv};
				$ciscoscsitgtdevtable_sth->execute($deviceid,$scantime,$fc_ciscoScsiTgtDevNumberOfLUs_1,$fc_ciscoScsiTgtDeviceStatus_1,$fc_ciscoScsiTgtDevNonAccLUs_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcTrunkIfOperStatusCauseDescr){
				my $fc_fcTrunkIfOperStatus_1=$fc_fcTrunkIfOperStatus->{$putinv};
				my $fc_fcTrunkIfOperStatusCause_1=$fc_fcTrunkIfOperStatusCause->{$putinv};
				my $fc_fcTrunkIfOperStatusCauseDescr_1=$fc_fcTrunkIfOperStatusCauseDescr->{$putinv};
				$fctrunkiftable_sth->execute($deviceid,$scantime,$fc_fcTrunkIfOperStatus_1,$fc_fcTrunkIfOperStatusCause_1,$fc_fcTrunkIfOperStatusCauseDescr_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfcspLocalPassRowStatus){
				my $fc_cfcspSwitchWwn_1=$fc_cfcspSwitchWwn->{$putinv};
				my $fc_cfcspLocalPasswd_1=$fc_cfcspLocalPasswd->{$putinv};
				my $fc_cfcspLocalPassRowStatus_1=$fc_cfcspLocalPassRowStatus->{$putinv};
				$cfcsplocalpasswdtable_sth->execute($deviceid,$scantime,$fc_cfcspSwitchWwn_1,$fc_cfcspLocalPasswd_1,$fc_cfcspLocalPassRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiDscLunIdValue){
				my $fc_ciscoScsiDscLunIdIndex_1=$fc_ciscoScsiDscLunIdIndex->{$putinv};
				my $fc_ciscoScsiDscLunIdCodeSet_1=$fc_ciscoScsiDscLunIdCodeSet->{$putinv};
				my $fc_ciscoScsiDscLunIdAssociation_1=$fc_ciscoScsiDscLunIdAssociation->{$putinv};
				my $fc_ciscoScsiDscLunIdType_1=$fc_ciscoScsiDscLunIdType->{$putinv};
				my $fc_ciscoScsiDscLunIdValue_1=$fc_ciscoScsiDscLunIdValue->{$putinv};
				$ciscoscsidsclunidtable_sth->execute($deviceid,$scantime,$fc_ciscoScsiDscLunIdIndex_1,$fc_ciscoScsiDscLunIdCodeSet_1,$fc_ciscoScsiDscLunIdAssociation_1,$fc_ciscoScsiDscLunIdType_1,$fc_ciscoScsiDscLunIdValue_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfcspRemotePassRowStatus){
				my $fc_cfcspRemoteSwitchWwn_1=$fc_cfcspRemoteSwitchWwn->{$putinv};
				my $fc_cfcspRemotePasswd_1=$fc_cfcspRemotePasswd->{$putinv};
				my $fc_cfcspRemotePassRowStatus_1=$fc_cfcspRemotePassRowStatus->{$putinv};
				$cfcspremotepasswdtable_sth->execute($deviceid,$scantime,$fc_cfcspRemoteSwitchWwn_1,$fc_cfcspRemotePasswd_1,$fc_cfcspRemotePassRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfCurrTxBbCredit){
				my $fc_fcIfCurrRxBbCredit_1=$fc_fcIfCurrRxBbCredit->{$putinv};
				my $fc_fcIfCurrTxBbCredit_1=$fc_fcIfCurrTxBbCredit->{$putinv};
				$fcifstattable_sth->execute($deviceid,$scantime,$fc_fcIfCurrRxBbCredit_1,$fc_fcIfCurrTxBbCredit_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanSessionRowStatus){
				my $fc_cspanSessionIndex_1=$fc_cspanSessionIndex->{$putinv};
				my $fc_cspanSessionDestIfIndex_1=$fc_cspanSessionDestIfIndex->{$putinv};
				my $fc_cspanSessionAdminStatus_1=$fc_cspanSessionAdminStatus->{$putinv};
				my $fc_cspanSessionOperStatus_1=$fc_cspanSessionOperStatus->{$putinv};
				my $fc_cspanSessionInactiveReason_1=$fc_cspanSessionInactiveReason->{$putinv};
				my $fc_cspanSessionRowStatus_1=$fc_cspanSessionRowStatus->{$putinv};
				$cspansessiontable_sth->execute($deviceid,$scantime,$fc_cspanSessionIndex_1,$fc_cspanSessionDestIfIndex_1,$fc_cspanSessionAdminStatus_1,$fc_cspanSessionOperStatus_1,$fc_cspanSessionInactiveReason_1,$fc_cspanSessionRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsDiscoveryCompleteTime){
				my $fc_fcsDiscoveryStatus_1=$fc_fcsDiscoveryStatus->{$putinv};
				my $fc_fcsDiscoveryCompleteTime_1=$fc_fcsDiscoveryCompleteTime->{$putinv};
				$fcsdiscoverystatustable_sth->execute($deviceid,$scantime,$fc_fcsDiscoveryStatus_1,$fc_fcsDiscoveryCompleteTime_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfcspReauthenticate){
				my $fc_cfcspMode_1=$fc_cfcspMode->{$putinv};
				my $fc_cfcspReauthInterval_1=$fc_cfcspReauthInterval->{$putinv};
				my $fc_cfcspReauthenticate_1=$fc_cfcspReauthenticate->{$putinv};
				$cfcspiftable_sth->execute($deviceid,$scantime,$fc_cfcspMode_1,$fc_cfcspReauthInterval_1,$fc_cfcspReauthenticate_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiTrnsptDevName){
				my $fc_ciscoScsiTrnsptIndex_1=$fc_ciscoScsiTrnsptIndex->{$putinv};
				my $fc_ciscoScsiTrnsptType_1=$fc_ciscoScsiTrnsptType->{$putinv};
				my $fc_ciscoScsiTrnsptPointer_1=$fc_ciscoScsiTrnsptPointer->{$putinv};
				my $fc_ciscoScsiTrnsptDevName_1=$fc_ciscoScsiTrnsptDevName->{$putinv};
				$ciscoscsitrnspttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiTrnsptIndex_1,$fc_ciscoScsiTrnsptType_1,$fc_ciscoScsiTrnsptPointer_1,$fc_ciscoScsiTrnsptDevName_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiFlowWrAccTgtCfgStatus){
				my $fc_ciscoScsiFlowWrAccCfgStatus_1=$fc_ciscoScsiFlowWrAccCfgStatus->{$putinv};
				my $fc_ciscoScsiFlowWrAccIntrCfgStatus_1=$fc_ciscoScsiFlowWrAccIntrCfgStatus->{$putinv};
				my $fc_ciscoScsiFlowWrAccTgtCfgStatus_1=$fc_ciscoScsiFlowWrAccTgtCfgStatus->{$putinv};
				$ciscoscsiflowwraccstatustable_sth->execute($deviceid,$scantime,$fc_ciscoScsiFlowWrAccCfgStatus_1,$fc_ciscoScsiFlowWrAccIntrCfgStatus_1,$fc_ciscoScsiFlowWrAccTgtCfgStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcPingRowStatus){
				my $fc_fcPingIndex_1=$fc_fcPingIndex->{$putinv};
				my $fc_fcPingVsanIndex_1=$fc_fcPingVsanIndex->{$putinv};
				my $fc_fcPingAddressType_1=$fc_fcPingAddressType->{$putinv};
				my $fc_fcPingAddress_1=$fc_fcPingAddress->{$putinv};
				my $fc_fcPingPacketCount_1=$fc_fcPingPacketCount->{$putinv};
				my $fc_fcPingPayloadSize_1=$fc_fcPingPayloadSize->{$putinv};
				my $fc_fcPingPacketTimeout_1=$fc_fcPingPacketTimeout->{$putinv};
				my $fc_fcPingDelay_1=$fc_fcPingDelay->{$putinv};
				my $fc_fcPingAgeInterval_1=$fc_fcPingAgeInterval->{$putinv};
				my $fc_fcPingUsrPriority_1=$fc_fcPingUsrPriority->{$putinv};
				my $fc_fcPingAdminStatus_1=$fc_fcPingAdminStatus->{$putinv};
				my $fc_fcPingOperStatus_1=$fc_fcPingOperStatus->{$putinv};
				my $fc_fcPingTrapOnCompletion_1=$fc_fcPingTrapOnCompletion->{$putinv};
				my $fc_fcPingRowStatus_1=$fc_fcPingRowStatus->{$putinv};
				$fcpingtable_sth->execute($deviceid,$scantime,$fc_fcPingIndex_1,$fc_fcPingVsanIndex_1,$fc_fcPingAddressType_1,$fc_fcPingAddress_1,$fc_fcPingPacketCount_1,$fc_fcPingPayloadSize_1,$fc_fcPingPacketTimeout_1,$fc_fcPingDelay_1,$fc_fcPingAgeInterval_1,$fc_fcPingUsrPriority_1,$fc_fcPingAdminStatus_1,$fc_fcPingOperStatus_1,$fc_fcPingTrapOnCompletion_1,$fc_fcPingRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiFlowStatsTgtCfgStatus){
				my $fc_ciscoScsiFlowStatsCfgStatus_1=$fc_ciscoScsiFlowStatsCfgStatus->{$putinv};
				my $fc_ciscoScsiFlowStatsIntrCfgStatus_1=$fc_ciscoScsiFlowStatsIntrCfgStatus->{$putinv};
				my $fc_ciscoScsiFlowStatsTgtCfgStatus_1=$fc_ciscoScsiFlowStatsTgtCfgStatus->{$putinv};
				$ciscoscsiflowstatsstatustable_sth->execute($deviceid,$scantime,$fc_ciscoScsiFlowStatsCfgStatus_1,$fc_ciscoScsiFlowStatsIntrCfgStatus_1,$fc_ciscoScsiFlowStatsTgtCfgStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoExtScsiIntrDiscLunPortId){
				my $fc_ciscoExtScsiIntrDiscLunCapacity_1=$fc_ciscoExtScsiIntrDiscLunCapacity->{$putinv};
				my $fc_ciscoExtScsiIntrDiscLunNumber_1=$fc_ciscoExtScsiIntrDiscLunNumber->{$putinv};
				my $fc_ciscoExtScsiIntrDiscLunSerialNum_1=$fc_ciscoExtScsiIntrDiscLunSerialNum->{$putinv};
				my $fc_ciscoExtScsiIntrDiscLunOs_1=$fc_ciscoExtScsiIntrDiscLunOs->{$putinv};
				my $fc_ciscoExtScsiIntrDiscLunPortId_1=$fc_ciscoExtScsiIntrDiscLunPortId->{$putinv};
				$ciscoextscsiintrdisclunstable_sth->execute($deviceid,$scantime,$fc_ciscoExtScsiIntrDiscLunCapacity_1,$fc_ciscoExtScsiIntrDiscLunNumber_1,$fc_ciscoExtScsiIntrDiscLunSerialNum_1,$fc_ciscoExtScsiIntrDiscLunOs_1,$fc_ciscoExtScsiIntrDiscLunPortId_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanVsanFilterOpVsans4k){
				my $fc_cspanVsanFilterOpSessIndex_1=$fc_cspanVsanFilterOpSessIndex->{$putinv};
				my $fc_cspanVsanFilterOpCommand_1=$fc_cspanVsanFilterOpCommand->{$putinv};
				my $fc_cspanVsanFilterOpVsans2k_1=$fc_cspanVsanFilterOpVsans2k->{$putinv};
				my $fc_cspanVsanFilterOpVsans4k_1=$fc_cspanVsanFilterOpVsans4k->{$putinv};
				$cspanvsanfilteroptable_sth->execute($deviceid,$scantime,$fc_cspanVsanFilterOpSessIndex_1,$fc_cspanVsanFilterOpCommand_1,$fc_cspanVsanFilterOpVsans2k_1,$fc_cspanVsanFilterOpVsans4k_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfC3Discards){
				my $fc_fcIfC3InFrames_1=$fc_fcIfC3InFrames->{$putinv};
				my $fc_fcIfC3OutFrames_1=$fc_fcIfC3OutFrames->{$putinv};
				my $fc_fcIfC3InOctets_1=$fc_fcIfC3InOctets->{$putinv};
				my $fc_fcIfC3OutOctets_1=$fc_fcIfC3OutOctets->{$putinv};
				my $fc_fcIfC3Discards_1=$fc_fcIfC3Discards->{$putinv};
				$fcifc3accountingtable_sth->execute($deviceid,$scantime,$fc_fcIfC3InFrames_1,$fc_fcIfC3OutFrames_1,$fc_fcIfC3InOctets_1,$fc_fcIfC3OutOctets_1,$fc_fcIfC3Discards_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfRNIDInfoPortId){
				my $fc_fcIfRNIDInfoStatus_1=$fc_fcIfRNIDInfoStatus->{$putinv};
				my $fc_fcIfRNIDInfoTypeNumber_1=$fc_fcIfRNIDInfoTypeNumber->{$putinv};
				my $fc_fcIfRNIDInfoModelNumber_1=$fc_fcIfRNIDInfoModelNumber->{$putinv};
				my $fc_fcIfRNIDInfoManufacturer_1=$fc_fcIfRNIDInfoManufacturer->{$putinv};
				my $fc_fcIfRNIDInfoPlantOfMfg_1=$fc_fcIfRNIDInfoPlantOfMfg->{$putinv};
				my $fc_fcIfRNIDInfoSerialNumber_1=$fc_fcIfRNIDInfoSerialNumber->{$putinv};
				my $fc_fcIfRNIDInfoUnitType_1=$fc_fcIfRNIDInfoUnitType->{$putinv};
				my $fc_fcIfRNIDInfoPortId_1=$fc_fcIfRNIDInfoPortId->{$putinv};
				$fcifrnidinfotable_sth->execute($deviceid,$scantime,$fc_fcIfRNIDInfoStatus_1,$fc_fcIfRNIDInfoTypeNumber_1,$fc_fcIfRNIDInfoModelNumber_1,$fc_fcIfRNIDInfoManufacturer_1,$fc_fcIfRNIDInfoPlantOfMfg_1,$fc_fcIfRNIDInfoSerialNumber_1,$fc_fcIfRNIDInfoUnitType_1,$fc_fcIfRNIDInfoPortId_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfGigEBeaconMode){
				my $fc_fcIfGigEPortChannelIfIndex_1=$fc_fcIfGigEPortChannelIfIndex->{$putinv};
				my $fc_fcIfGigEAutoNegotiate_1=$fc_fcIfGigEAutoNegotiate->{$putinv};
				my $fc_fcIfGigEBeaconMode_1=$fc_fcIfGigEBeaconMode->{$putinv};
				$fcifgigetable_sth->execute($deviceid,$scantime,$fc_fcIfGigEPortChannelIfIndex_1,$fc_fcIfGigEAutoNegotiate_1,$fc_fcIfGigEBeaconMode_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfdmiHbaInfoMaxCTPayload){
				my $fc_cfdmiHbaInfoId_1=$fc_cfdmiHbaInfoId->{$putinv};
				my $fc_cfdmiHbaInfoNodeName_1=$fc_cfdmiHbaInfoNodeName->{$putinv};
				my $fc_cfdmiHbaInfoMfg_1=$fc_cfdmiHbaInfoMfg->{$putinv};
				my $fc_cfdmiHbaInfoSn_1=$fc_cfdmiHbaInfoSn->{$putinv};
				my $fc_cfdmiHbaInfoModel_1=$fc_cfdmiHbaInfoModel->{$putinv};
				my $fc_cfdmiHbaInfoModelDescr_1=$fc_cfdmiHbaInfoModelDescr->{$putinv};
				my $fc_cfdmiHbaInfoHwVer_1=$fc_cfdmiHbaInfoHwVer->{$putinv};
				my $fc_cfdmiHbaInfoDriverVer_1=$fc_cfdmiHbaInfoDriverVer->{$putinv};
				my $fc_cfdmiHbaInfoOptROMVer_1=$fc_cfdmiHbaInfoOptROMVer->{$putinv};
				my $fc_cfdmiHbaInfoFwVer_1=$fc_cfdmiHbaInfoFwVer->{$putinv};
				my $fc_cfdmiHbaInfoOSInfo_1=$fc_cfdmiHbaInfoOSInfo->{$putinv};
				my $fc_cfdmiHbaInfoMaxCTPayload_1=$fc_cfdmiHbaInfoMaxCTPayload->{$putinv};
				$cfdmihbainfotable_sth->execute($deviceid,$scantime,$fc_cfdmiHbaInfoId_1,$fc_cfdmiHbaInfoNodeName_1,$fc_cfdmiHbaInfoMfg_1,$fc_cfdmiHbaInfoSn_1,$fc_cfdmiHbaInfoModel_1,$fc_cfdmiHbaInfoModelDescr_1,$fc_cfdmiHbaInfoHwVer_1,$fc_cfdmiHbaInfoDriverVer_1,$fc_cfdmiHbaInfoOptROMVer_1,$fc_cfdmiHbaInfoFwVer_1,$fc_cfdmiHbaInfoOSInfo_1,$fc_cfdmiHbaInfoMaxCTPayload_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfCapOsmISLRxPerfBufDefault){
				my $fc_fcIfCapOsmRxBbCreditWriteable_1=$fc_fcIfCapOsmRxBbCreditWriteable->{$putinv};
				my $fc_fcIfCapOsmRxBbCreditMax_1=$fc_fcIfCapOsmRxBbCreditMax->{$putinv};
				my $fc_fcIfCapOsmRxBbCreditMin_1=$fc_fcIfCapOsmRxBbCreditMin->{$putinv};
				my $fc_fcIfCapOsmRxBbCreditDefault_1=$fc_fcIfCapOsmRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapOsmISLRxBbCreditMax_1=$fc_fcIfCapOsmISLRxBbCreditMax->{$putinv};
				my $fc_fcIfCapOsmISLRxBbCreditMin_1=$fc_fcIfCapOsmISLRxBbCreditMin->{$putinv};
				my $fc_fcIfCapOsmISLRxBbCreditDefault_1=$fc_fcIfCapOsmISLRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapOsmRxPerfBufWriteable_1=$fc_fcIfCapOsmRxPerfBufWriteable->{$putinv};
				my $fc_fcIfCapOsmRxPerfBufMax_1=$fc_fcIfCapOsmRxPerfBufMax->{$putinv};
				my $fc_fcIfCapOsmRxPerfBufMin_1=$fc_fcIfCapOsmRxPerfBufMin->{$putinv};
				my $fc_fcIfCapOsmRxPerfBufDefault_1=$fc_fcIfCapOsmRxPerfBufDefault->{$putinv};
				my $fc_fcIfCapOsmISLRxPerfBufMax_1=$fc_fcIfCapOsmISLRxPerfBufMax->{$putinv};
				my $fc_fcIfCapOsmISLRxPerfBufMin_1=$fc_fcIfCapOsmISLRxPerfBufMin->{$putinv};
				my $fc_fcIfCapOsmISLRxPerfBufDefault_1=$fc_fcIfCapOsmISLRxPerfBufDefault->{$putinv};
				$fcifcaposmtable_sth->execute($deviceid,$scantime,$fc_fcIfCapOsmRxBbCreditWriteable_1,$fc_fcIfCapOsmRxBbCreditMax_1,$fc_fcIfCapOsmRxBbCreditMin_1,$fc_fcIfCapOsmRxBbCreditDefault_1,$fc_fcIfCapOsmISLRxBbCreditMax_1,$fc_fcIfCapOsmISLRxBbCreditMin_1,$fc_fcIfCapOsmISLRxBbCreditDefault_1,$fc_fcIfCapOsmRxPerfBufWriteable_1,$fc_fcIfCapOsmRxPerfBufMax_1,$fc_fcIfCapOsmRxPerfBufMin_1,$fc_fcIfCapOsmRxPerfBufDefault_1,$fc_fcIfCapOsmISLRxPerfBufMax_1,$fc_fcIfCapOsmISLRxPerfBufMin_1,$fc_fcIfCapOsmISLRxPerfBufDefault_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfdaConfigRowStatus){
				my $fc_cfdaConfigDeviceAlias_1=$fc_cfdaConfigDeviceAlias->{$putinv};
				my $fc_cfdaConfigDeviceType_1=$fc_cfdaConfigDeviceType->{$putinv};
				my $fc_cfdaConfigDeviceId_1=$fc_cfdaConfigDeviceId->{$putinv};
				my $fc_cfdaConfigRowStatus_1=$fc_cfdaConfigRowStatus->{$putinv};
				$cfdaconfigtable_sth->execute($deviceid,$scantime,$fc_cfdaConfigDeviceAlias_1,$fc_cfdaConfigDeviceType_1,$fc_cfdaConfigDeviceId_1,$fc_cfdaConfigRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cSanBaseSvcDevicePortRowStatus){
				my $fc_cSanBaseSvcDevicePortName_1=$fc_cSanBaseSvcDevicePortName->{$putinv};
				my $fc_cSanBaseSvcDevicePortClusterId_1=$fc_cSanBaseSvcDevicePortClusterId->{$putinv};
				my $fc_cSanBaseSvcDevicePortStorageType_1=$fc_cSanBaseSvcDevicePortStorageType->{$putinv};
				my $fc_cSanBaseSvcDevicePortRowStatus_1=$fc_cSanBaseSvcDevicePortRowStatus->{$putinv};
				$csanbasesvcdeviceporttable_sth->execute($deviceid,$scantime,$fc_cSanBaseSvcDevicePortName_1,$fc_cSanBaseSvcDevicePortClusterId_1,$fc_cSanBaseSvcDevicePortStorageType_1,$fc_cSanBaseSvcDevicePortRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiPortBusyStatuses){
				my $fc_ciscoScsiPortIndex_1=$fc_ciscoScsiPortIndex->{$putinv};
				my $fc_ciscoScsiPortRole_1=$fc_ciscoScsiPortRole->{$putinv};
				my $fc_ciscoScsiPortTrnsptPtr_1=$fc_ciscoScsiPortTrnsptPtr->{$putinv};
				my $fc_ciscoScsiPortBusyStatuses_1=$fc_ciscoScsiPortBusyStatuses->{$putinv};
				$ciscoscsiporttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiPortIndex_1,$fc_ciscoScsiPortRole_1,$fc_ciscoScsiPortTrnsptPtr_1,$fc_ciscoScsiPortBusyStatuses_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cSanBaseSvcClusterMemberRowStatus){
				my $fc_cSanBaseSvcClusterMemberInetAddrType_1=$fc_cSanBaseSvcClusterMemberInetAddrType->{$putinv};
				my $fc_cSanBaseSvcClusterMemberInetAddr_1=$fc_cSanBaseSvcClusterMemberInetAddr->{$putinv};
				my $fc_cSanBaseSvcClusterMemberFabric_1=$fc_cSanBaseSvcClusterMemberFabric->{$putinv};
				my $fc_cSanBaseSvcClusterMemberIsLocal_1=$fc_cSanBaseSvcClusterMemberIsLocal->{$putinv};
				my $fc_cSanBaseSvcClusterMemberIsMaster_1=$fc_cSanBaseSvcClusterMemberIsMaster->{$putinv};
				my $fc_cSanBaseSvcClusterMemberStorageType_1=$fc_cSanBaseSvcClusterMemberStorageType->{$putinv};
				my $fc_cSanBaseSvcClusterMemberRowStatus_1=$fc_cSanBaseSvcClusterMemberRowStatus->{$putinv};
				$csanbasesvcclustermemberstable_sth->execute($deviceid,$scantime,$fc_cSanBaseSvcClusterMemberInetAddrType_1,$fc_cSanBaseSvcClusterMemberInetAddr_1,$fc_cSanBaseSvcClusterMemberFabric_1,$fc_cSanBaseSvcClusterMemberIsLocal_1,$fc_cSanBaseSvcClusterMemberIsMaster_1,$fc_cSanBaseSvcClusterMemberStorageType_1,$fc_cSanBaseSvcClusterMemberRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiInstNotifEnable){
				my $fc_ciscoScsiInstIndex_1=$fc_ciscoScsiInstIndex->{$putinv};
				my $fc_ciscoScsiInstAlias_1=$fc_ciscoScsiInstAlias->{$putinv};
				my $fc_ciscoScsiInstSoftwareIndex_1=$fc_ciscoScsiInstSoftwareIndex->{$putinv};
				my $fc_ciscoScsiInstVendorVersion_1=$fc_ciscoScsiInstVendorVersion->{$putinv};
				my $fc_ciscoScsiInstNotifEnable_1=$fc_ciscoScsiInstNotifEnable->{$putinv};
				$ciscoscsiinstancetable_sth->execute($deviceid,$scantime,$fc_ciscoScsiInstIndex_1,$fc_ciscoScsiInstAlias_1,$fc_ciscoScsiInstSoftwareIndex_1,$fc_ciscoScsiInstVendorVersion_1,$fc_ciscoScsiInstNotifEnable_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcIfCapFrmISLRxPerfBufDefault){
				my $fc_fcIfCapFrmRxBbCreditWriteable_1=$fc_fcIfCapFrmRxBbCreditWriteable->{$putinv};
				my $fc_fcIfCapFrmRxBbCreditMax_1=$fc_fcIfCapFrmRxBbCreditMax->{$putinv};
				my $fc_fcIfCapFrmRxBbCreditMin_1=$fc_fcIfCapFrmRxBbCreditMin->{$putinv};
				my $fc_fcIfCapFrmRxBbCreditDefault_1=$fc_fcIfCapFrmRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapFrmISLRxBbCreditMax_1=$fc_fcIfCapFrmISLRxBbCreditMax->{$putinv};
				my $fc_fcIfCapFrmISLRxBbCreditMin_1=$fc_fcIfCapFrmISLRxBbCreditMin->{$putinv};
				my $fc_fcIfCapFrmISLRxBbCreditDefault_1=$fc_fcIfCapFrmISLRxBbCreditDefault->{$putinv};
				my $fc_fcIfCapFrmRxPerfBufWriteable_1=$fc_fcIfCapFrmRxPerfBufWriteable->{$putinv};
				my $fc_fcIfCapFrmRxPerfBufMax_1=$fc_fcIfCapFrmRxPerfBufMax->{$putinv};
				my $fc_fcIfCapFrmRxPerfBufMin_1=$fc_fcIfCapFrmRxPerfBufMin->{$putinv};
				my $fc_fcIfCapFrmRxPerfBufDefault_1=$fc_fcIfCapFrmRxPerfBufDefault->{$putinv};
				my $fc_fcIfCapFrmISLRxPerfBufMax_1=$fc_fcIfCapFrmISLRxPerfBufMax->{$putinv};
				my $fc_fcIfCapFrmISLRxPerfBufMin_1=$fc_fcIfCapFrmISLRxPerfBufMin->{$putinv};
				my $fc_fcIfCapFrmISLRxPerfBufDefault_1=$fc_fcIfCapFrmISLRxPerfBufDefault->{$putinv};
				$fcifcapfrmtable_sth->execute($deviceid,$scantime,$fc_fcIfCapFrmRxBbCreditWriteable_1,$fc_fcIfCapFrmRxBbCreditMax_1,$fc_fcIfCapFrmRxBbCreditMin_1,$fc_fcIfCapFrmRxBbCreditDefault_1,$fc_fcIfCapFrmISLRxBbCreditMax_1,$fc_fcIfCapFrmISLRxBbCreditMin_1,$fc_fcIfCapFrmISLRxBbCreditDefault_1,$fc_fcIfCapFrmRxPerfBufWriteable_1,$fc_fcIfCapFrmRxPerfBufMax_1,$fc_fcIfCapFrmRxPerfBufMin_1,$fc_fcIfCapFrmRxPerfBufDefault_1,$fc_fcIfCapFrmISLRxPerfBufMax_1,$fc_fcIfCapFrmISLRxPerfBufMin_1,$fc_fcIfCapFrmISLRxPerfBufDefault_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsAttachPortName){
				my $fc_fcsAttachPortNameListIndex_1=$fc_fcsAttachPortNameListIndex->{$putinv};
				my $fc_fcsAttachPortName_1=$fc_fcsAttachPortName->{$putinv};
				$fcsattachportnamelisttable_sth->execute($deviceid,$scantime,$fc_fcsAttachPortNameListIndex_1,$fc_fcsAttachPortName_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiFlowAbts){
				my $fc_ciscoScsiFlowLunId_1=$fc_ciscoScsiFlowLunId->{$putinv};
				my $fc_ciscoScsiFlowRdIos_1=$fc_ciscoScsiFlowRdIos->{$putinv};
				my $fc_ciscoScsiFlowRdFailedIos_1=$fc_ciscoScsiFlowRdFailedIos->{$putinv};
				my $fc_ciscoScsiFlowRdTimeouts_1=$fc_ciscoScsiFlowRdTimeouts->{$putinv};
				my $fc_ciscoScsiFlowRdBlocks_1=$fc_ciscoScsiFlowRdBlocks->{$putinv};
				my $fc_ciscoScsiFlowRdMaxBlocks_1=$fc_ciscoScsiFlowRdMaxBlocks->{$putinv};
				my $fc_ciscoScsiFlowRdMinTime_1=$fc_ciscoScsiFlowRdMinTime->{$putinv};
				my $fc_ciscoScsiFlowRdMaxTime_1=$fc_ciscoScsiFlowRdMaxTime->{$putinv};
				my $fc_ciscoScsiFlowRdsActive_1=$fc_ciscoScsiFlowRdsActive->{$putinv};
				my $fc_ciscoScsiFlowWrIos_1=$fc_ciscoScsiFlowWrIos->{$putinv};
				my $fc_ciscoScsiFlowWrFailedIos_1=$fc_ciscoScsiFlowWrFailedIos->{$putinv};
				my $fc_ciscoScsiFlowWrTimeouts_1=$fc_ciscoScsiFlowWrTimeouts->{$putinv};
				my $fc_ciscoScsiFlowWrBlocks_1=$fc_ciscoScsiFlowWrBlocks->{$putinv};
				my $fc_ciscoScsiFlowWrMaxBlocks_1=$fc_ciscoScsiFlowWrMaxBlocks->{$putinv};
				my $fc_ciscoScsiFlowWrMinTime_1=$fc_ciscoScsiFlowWrMinTime->{$putinv};
				my $fc_ciscoScsiFlowWrMaxTime_1=$fc_ciscoScsiFlowWrMaxTime->{$putinv};
				my $fc_ciscoScsiFlowWrsActive_1=$fc_ciscoScsiFlowWrsActive->{$putinv};
				my $fc_ciscoScsiFlowTestUnitRdys_1=$fc_ciscoScsiFlowTestUnitRdys->{$putinv};
				my $fc_ciscoScsiFlowRepLuns_1=$fc_ciscoScsiFlowRepLuns->{$putinv};
				my $fc_ciscoScsiFlowInquirys_1=$fc_ciscoScsiFlowInquirys->{$putinv};
				my $fc_ciscoScsiFlowRdCapacitys_1=$fc_ciscoScsiFlowRdCapacitys->{$putinv};
				my $fc_ciscoScsiFlowModeSenses_1=$fc_ciscoScsiFlowModeSenses->{$putinv};
				my $fc_ciscoScsiFlowReqSenses_1=$fc_ciscoScsiFlowReqSenses->{$putinv};
				my $fc_ciscoScsiFlowRxFc2Frames_1=$fc_ciscoScsiFlowRxFc2Frames->{$putinv};
				my $fc_ciscoScsiFlowTxFc2Frames_1=$fc_ciscoScsiFlowTxFc2Frames->{$putinv};
				my $fc_ciscoScsiFlowRxFc2Octets_1=$fc_ciscoScsiFlowRxFc2Octets->{$putinv};
				my $fc_ciscoScsiFlowTxFc2Octets_1=$fc_ciscoScsiFlowTxFc2Octets->{$putinv};
				my $fc_ciscoScsiFlowBusyStatuses_1=$fc_ciscoScsiFlowBusyStatuses->{$putinv};
				my $fc_ciscoScsiFlowStatusResvConfs_1=$fc_ciscoScsiFlowStatusResvConfs->{$putinv};
				my $fc_ciscoScsiFlowTskSetFulStatuses_1=$fc_ciscoScsiFlowTskSetFulStatuses->{$putinv};
				my $fc_ciscoScsiFlowAcaActiveStatuses_1=$fc_ciscoScsiFlowAcaActiveStatuses->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyNotRdyErrs_1=$fc_ciscoScsiFlowSenseKeyNotRdyErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyMedErrs_1=$fc_ciscoScsiFlowSenseKeyMedErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyHwErrs_1=$fc_ciscoScsiFlowSenseKeyHwErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyIllReqErrs_1=$fc_ciscoScsiFlowSenseKeyIllReqErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyUnitAttErrs_1=$fc_ciscoScsiFlowSenseKeyUnitAttErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyDatProtErrs_1=$fc_ciscoScsiFlowSenseKeyDatProtErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyBlankErrs_1=$fc_ciscoScsiFlowSenseKeyBlankErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyCpAbrtErrs_1=$fc_ciscoScsiFlowSenseKeyCpAbrtErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyAbrtCmdErrs_1=$fc_ciscoScsiFlowSenseKeyAbrtCmdErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyVolFlowErrs_1=$fc_ciscoScsiFlowSenseKeyVolFlowErrs->{$putinv};
				my $fc_ciscoScsiFlowSenseKeyMiscmpErrs_1=$fc_ciscoScsiFlowSenseKeyMiscmpErrs->{$putinv};
				my $fc_ciscoScsiFlowAbts_1=$fc_ciscoScsiFlowAbts->{$putinv};
				$ciscoscsiflowstatstable_sth->execute($deviceid,$scantime,$fc_ciscoScsiFlowLunId_1,$fc_ciscoScsiFlowRdIos_1,$fc_ciscoScsiFlowRdFailedIos_1,$fc_ciscoScsiFlowRdTimeouts_1,$fc_ciscoScsiFlowRdBlocks_1,$fc_ciscoScsiFlowRdMaxBlocks_1,$fc_ciscoScsiFlowRdMinTime_1,$fc_ciscoScsiFlowRdMaxTime_1,$fc_ciscoScsiFlowRdsActive_1,$fc_ciscoScsiFlowWrIos_1,$fc_ciscoScsiFlowWrFailedIos_1,$fc_ciscoScsiFlowWrTimeouts_1,$fc_ciscoScsiFlowWrBlocks_1,$fc_ciscoScsiFlowWrMaxBlocks_1,$fc_ciscoScsiFlowWrMinTime_1,$fc_ciscoScsiFlowWrMaxTime_1,$fc_ciscoScsiFlowWrsActive_1,$fc_ciscoScsiFlowTestUnitRdys_1,$fc_ciscoScsiFlowRepLuns_1,$fc_ciscoScsiFlowInquirys_1,$fc_ciscoScsiFlowRdCapacitys_1,$fc_ciscoScsiFlowModeSenses_1,$fc_ciscoScsiFlowReqSenses_1,$fc_ciscoScsiFlowRxFc2Frames_1,$fc_ciscoScsiFlowTxFc2Frames_1,$fc_ciscoScsiFlowRxFc2Octets_1,$fc_ciscoScsiFlowTxFc2Octets_1,$fc_ciscoScsiFlowBusyStatuses_1,$fc_ciscoScsiFlowStatusResvConfs_1,$fc_ciscoScsiFlowTskSetFulStatuses_1,$fc_ciscoScsiFlowAcaActiveStatuses_1,$fc_ciscoScsiFlowSenseKeyNotRdyErrs_1,$fc_ciscoScsiFlowSenseKeyMedErrs_1,$fc_ciscoScsiFlowSenseKeyHwErrs_1,$fc_ciscoScsiFlowSenseKeyIllReqErrs_1,$fc_ciscoScsiFlowSenseKeyUnitAttErrs_1,$fc_ciscoScsiFlowSenseKeyDatProtErrs_1,$fc_ciscoScsiFlowSenseKeyBlankErrs_1,$fc_ciscoScsiFlowSenseKeyCpAbrtErrs_1,$fc_ciscoScsiFlowSenseKeyAbrtCmdErrs_1,$fc_ciscoScsiFlowSenseKeyVolFlowErrs_1,$fc_ciscoScsiFlowSenseKeyMiscmpErrs_1,$fc_ciscoScsiFlowAbts_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiDeviceResets){
				my $fc_ciscoScsiDeviceIndex_1=$fc_ciscoScsiDeviceIndex->{$putinv};
				my $fc_ciscoScsiDeviceAlias_1=$fc_ciscoScsiDeviceAlias->{$putinv};
				my $fc_ciscoScsiDeviceRole_1=$fc_ciscoScsiDeviceRole->{$putinv};
				my $fc_ciscoScsiDevicePortNumber_1=$fc_ciscoScsiDevicePortNumber->{$putinv};
				my $fc_ciscoScsiDeviceResets_1=$fc_ciscoScsiDeviceResets->{$putinv};
				$ciscoscsidevicetable_sth->execute($deviceid,$scantime,$fc_ciscoScsiDeviceIndex_1,$fc_ciscoScsiDeviceAlias_1,$fc_ciscoScsiDeviceRole_1,$fc_ciscoScsiDevicePortNumber_1,$fc_ciscoScsiDeviceResets_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoExtScsiPartialLunRowStatus){
				my $fc_ciscoExtScsiPartialLunDomId_1=$fc_ciscoExtScsiPartialLunDomId->{$putinv};
				my $fc_ciscoExtScsiPartialLunRowStatus_1=$fc_ciscoExtScsiPartialLunRowStatus->{$putinv};
				$ciscoextscsipartiallundisctable_sth->execute($deviceid,$scantime,$fc_ciscoExtScsiPartialLunDomId_1,$fc_ciscoExtScsiPartialLunRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cSanBaseSvcClusterApplication){
				my $fc_cSanBaseSvcClusterId_1=$fc_cSanBaseSvcClusterId->{$putinv};
				my $fc_cSanBaseSvcClusterName_1=$fc_cSanBaseSvcClusterName->{$putinv};
				my $fc_cSanBaseSvcClusterState_1=$fc_cSanBaseSvcClusterState->{$putinv};
				my $fc_cSanBaseSvcClusterMasterInetAddrType_1=$fc_cSanBaseSvcClusterMasterInetAddrType->{$putinv};
				my $fc_cSanBaseSvcClusterMasterInetAddr_1=$fc_cSanBaseSvcClusterMasterInetAddr->{$putinv};
				my $fc_cSanBaseSvcClusterStorageType_1=$fc_cSanBaseSvcClusterStorageType->{$putinv};
				my $fc_cSanBaseSvcClusterRowStatus_1=$fc_cSanBaseSvcClusterRowStatus->{$putinv};
				my $fc_cSanBaseSvcClusterApplication_1=$fc_cSanBaseSvcClusterApplication->{$putinv};
				$csanbasesvcclustertable_sth->execute($deviceid,$scantime,$fc_cSanBaseSvcClusterId_1,$fc_cSanBaseSvcClusterName_1,$fc_cSanBaseSvcClusterState_1,$fc_cSanBaseSvcClusterMasterInetAddrType_1,$fc_cSanBaseSvcClusterMasterInetAddr_1,$fc_cSanBaseSvcClusterStorageType_1,$fc_cSanBaseSvcClusterRowStatus_1,$fc_cSanBaseSvcClusterApplication_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cfdmiHbaPortHostName){
				my $fc_cfdmiHbaPortId_1=$fc_cfdmiHbaPortId->{$putinv};
				my $fc_cfdmiHbaPortSupportedFC4Type_1=$fc_cfdmiHbaPortSupportedFC4Type->{$putinv};
				my $fc_cfdmiHbaPortSupportedSpeed_1=$fc_cfdmiHbaPortSupportedSpeed->{$putinv};
				my $fc_cfdmiHbaPortCurrentSpeed_1=$fc_cfdmiHbaPortCurrentSpeed->{$putinv};
				my $fc_cfdmiHbaPortMaxFrameSize_1=$fc_cfdmiHbaPortMaxFrameSize->{$putinv};
				my $fc_cfdmiHbaPortOsDevName_1=$fc_cfdmiHbaPortOsDevName->{$putinv};
				my $fc_cfdmiHbaPortHostName_1=$fc_cfdmiHbaPortHostName->{$putinv};
				$cfdmihbaportentry_sth->execute($deviceid,$scantime,$fc_cfdmiHbaPortId_1,$fc_cfdmiHbaPortSupportedFC4Type_1,$fc_cfdmiHbaPortSupportedSpeed_1,$fc_cfdmiHbaPortCurrentSpeed_1,$fc_cfdmiHbaPortMaxFrameSize_1,$fc_cfdmiHbaPortOsDevName_1,$fc_cfdmiHbaPortHostName_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiLunMapRowStatus){
				my $fc_ciscoScsiLunMapIndex_1=$fc_ciscoScsiLunMapIndex->{$putinv};
				my $fc_ciscoScsiLunMapLun_1=$fc_ciscoScsiLunMapLun->{$putinv};
				my $fc_ciscoScsiLunMapLuIndex_1=$fc_ciscoScsiLunMapLuIndex->{$putinv};
				my $fc_ciscoScsiLunMapRowStatus_1=$fc_ciscoScsiLunMapRowStatus->{$putinv};
				$ciscoscsilunmaptable_sth->execute($deviceid,$scantime,$fc_ciscoScsiLunMapIndex_1,$fc_ciscoScsiLunMapLun_1,$fc_ciscoScsiLunMapLuIndex_1,$fc_ciscoScsiLunMapRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cIpNetworkGigEPortInetAddr){
				my $fc_cIpNetworkGigEPortSwitchWWN_1=$fc_cIpNetworkGigEPortSwitchWWN->{$putinv};
				my $fc_cIpNetworkGigEPortIfIndex_1=$fc_cIpNetworkGigEPortIfIndex->{$putinv};
				my $fc_cIpNetworkGigEPortInetAddrType_1=$fc_cIpNetworkGigEPortInetAddrType->{$putinv};
				my $fc_cIpNetworkGigEPortInetAddr_1=$fc_cIpNetworkGigEPortInetAddr->{$putinv};
				$cipnetworkinterfacetable_sth->execute($deviceid,$scantime,$fc_cIpNetworkGigEPortSwitchWWN_1,$fc_cIpNetworkGigEPortIfIndex_1,$fc_cIpNetworkGigEPortInetAddrType_1,$fc_cIpNetworkGigEPortInetAddr_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsPortListIndex){
				my $fc_fcsPortListIndex_1=$fc_fcsPortListIndex->{$putinv};
				$fcsportlisttable_sth->execute($deviceid,$scantime,$fc_fcsPortListIndex_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cspanSourcesVsanCfgVsans4k){
				my $fc_cspanSourcesVsanCfgSessIndex_1=$fc_cspanSourcesVsanCfgSessIndex->{$putinv};
				my $fc_cspanSourcesVsanCfgCommand_1=$fc_cspanSourcesVsanCfgCommand->{$putinv};
				my $fc_cspanSourcesVsanCfgVsans2k_1=$fc_cspanSourcesVsanCfgVsans2k->{$putinv};
				my $fc_cspanSourcesVsanCfgVsans4k_1=$fc_cspanSourcesVsanCfgVsans4k->{$putinv};
				$cspansourcesvsancfgtable_sth->execute($deviceid,$scantime,$fc_cspanSourcesVsanCfgSessIndex_1,$fc_cspanSourcesVsanCfgCommand_1,$fc_cspanSourcesVsanCfgVsans2k_1,$fc_cspanSourcesVsanCfgVsans4k_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cIpNetworkSwitchWWN){
				my $fc_cIpNetworkIndex_1=$fc_cIpNetworkIndex->{$putinv};
				my $fc_cIpNetworkSwitchWWN_1=$fc_cIpNetworkSwitchWWN->{$putinv};
				$cipnetworktable_sth->execute($deviceid,$scantime,$fc_cIpNetworkIndex_1,$fc_cIpNetworkSwitchWWN_1,$putinv);
			}
			foreach my $putinv (keys %$fc_ciscoScsiAttTgtPortIdentifier){
				my $fc_ciscoScsiAttTgtPortIndex_1=$fc_ciscoScsiAttTgtPortIndex->{$putinv};
				my $fc_ciscoScsiAttTgtPortDscTgtIdx_1=$fc_ciscoScsiAttTgtPortDscTgtIdx->{$putinv};
				my $fc_ciscoScsiAttTgtPortName_1=$fc_ciscoScsiAttTgtPortName->{$putinv};
				my $fc_ciscoScsiAttTgtPortIdentifier_1=$fc_ciscoScsiAttTgtPortIdentifier->{$putinv};
				$ciscoscsiatttgtporttable_sth->execute($deviceid,$scantime,$fc_ciscoScsiAttTgtPortIndex_1,$fc_ciscoScsiAttTgtPortDscTgtIdx_1,$fc_ciscoScsiAttTgtPortName_1,$fc_ciscoScsiAttTgtPortIdentifier_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcRouteFlowRowStatus){
				my $fc_fcRouteFlowIndex_1=$fc_fcRouteFlowIndex->{$putinv};
				my $fc_fcRouteFlowType_1=$fc_fcRouteFlowType->{$putinv};
				my $fc_fcRouteFlowVsanId_1=$fc_fcRouteFlowVsanId->{$putinv};
				my $fc_fcRouteFlowDestId_1=$fc_fcRouteFlowDestId->{$putinv};
				my $fc_fcRouteFlowSrcId_1=$fc_fcRouteFlowSrcId->{$putinv};
				my $fc_fcRouteFlowMask_1=$fc_fcRouteFlowMask->{$putinv};
				my $fc_fcRouteFlowPort_1=$fc_fcRouteFlowPort->{$putinv};
				my $fc_fcRouteFlowFrames_1=$fc_fcRouteFlowFrames->{$putinv};
				my $fc_fcRouteFlowBytes_1=$fc_fcRouteFlowBytes->{$putinv};
				my $fc_fcRouteFlowCreationTime_1=$fc_fcRouteFlowCreationTime->{$putinv};
				my $fc_fcRouteFlowRowStatus_1=$fc_fcRouteFlowRowStatus->{$putinv};
				$fcrouteflowstattable_sth->execute($deviceid,$scantime,$fc_fcRouteFlowIndex_1,$fc_fcRouteFlowType_1,$fc_fcRouteFlowVsanId_1,$fc_fcRouteFlowDestId_1,$fc_fcRouteFlowSrcId_1,$fc_fcRouteFlowMask_1,$fc_fcRouteFlowPort_1,$fc_fcRouteFlowFrames_1,$fc_fcRouteFlowBytes_1,$fc_fcRouteFlowCreationTime_1,$fc_fcRouteFlowRowStatus_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcsIePortListIndex){
				my $fc_fcsIeName_1=$fc_fcsIeName->{$putinv};
				my $fc_fcsIeType_1=$fc_fcsIeType->{$putinv};
				my $fc_fcsIeDomainId_1=$fc_fcsIeDomainId->{$putinv};
				my $fc_fcsIeMgmtId_1=$fc_fcsIeMgmtId->{$putinv};
				my $fc_fcsIeFabricName_1=$fc_fcsIeFabricName->{$putinv};
				my $fc_fcsIeLogicalName_1=$fc_fcsIeLogicalName->{$putinv};
				my $fc_fcsIeMgmtAddrListIndex_1=$fc_fcsIeMgmtAddrListIndex->{$putinv};
				my $fc_fcsIeInfoList_1=$fc_fcsIeInfoList->{$putinv};
				my $fc_fcsIePortListIndex_1=$fc_fcsIePortListIndex->{$putinv};
				$fcsietable_sth->execute($deviceid,$scantime,$fc_fcsIeName_1,$fc_fcsIeType_1,$fc_fcsIeDomainId_1,$fc_fcsIeMgmtId_1,$fc_fcsIeFabricName_1,$fc_fcsIeLogicalName_1,$fc_fcsIeMgmtAddrListIndex_1,$fc_fcsIeInfoList_1,$fc_fcsIePortListIndex_1,$putinv);
			}
		} elsif ($vendortype =~ /fibre/i) {
			my $swfcporttable_sth = $mysql->prepare_cached("INSERT INTO swfcporttable(deviceid,scantime,fc_swFCPortIndex,fc_swFCPortType,fc_swFCPortPhyState,fc_swFCPortOpStatus,fc_swFCPortAdmStatus,fc_swFCPortLinkState,fc_swFCPortTxType,fc_swFCPortTxWords,fc_swFCPortRxWords,fc_swFCPortTxFrames,fc_swFCPortRxFrames,fc_swFCPortRxC2Frames,fc_swFCPortRxC3Frames,fc_swFCPortRxLCs,fc_swFCPortRxMcasts,fc_swFCPortTooManyRdys,fc_swFCPortNoTxCredits,fc_swFCPortRxEncInFrs,fc_swFCPortRxCrcs,fc_swFCPortRxTruncs,fc_swFCPortRxTooLongs,fc_swFCPortRxBadEofs,fc_swFCPortRxEncOutFrs,fc_swFCPortRxBadOs,fc_swFCPortC3Discards,fc_swFCPortMcastTimedOuts,fc_swFCPortTxMcasts,fc_swFCPortLipIns,fc_swFCPortLipOuts,fc_swFCPortLipLastAlpa,fc_swFCPortWwn,fc_swFCPortSpeed,fc_swFCPortName,fc_swFCPortSpecifier,fc_swFCPortFlag,fc_swFCPortBrcdType,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $frutable_sth = $mysql->prepare_cached("INSERT INTO frutable(deviceid,scantime,fc_fruClass,fc_fruStatus,fc_fruObjectNum,fc_fruSupplierId,fc_fruSupplierPartNum,fc_fruSupplierSerialNum,fc_fruSupplierRevCode,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $swenddevicerlstable_sth = $mysql->prepare_cached("INSERT INTO swenddevicerlstable(deviceid,scantime,fc_swEndDevicePort,fc_swEndDeviceAlpa,fc_swEndDevicePortID,fc_swEndDeviceLinkFailure,fc_swEndDeviceSyncLoss,fc_swEndDeviceSigLoss,fc_swEndDeviceProtoErr,fc_swEndDeviceInvalidWord,fc_swEndDeviceInvalidCRC,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			my $swblmperffltmnttable_sth = $mysql->prepare_cached("INSERT INTO swblmperffltmnttable(deviceid,scantime,fc_swBlmPerfFltPort,fc_swBlmPerfFltRefkey,fc_swBlmPerfFltCnt,fc_swBlmPerfFltAlias,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $swgrouptable_sth = $mysql->prepare_cached("INSERT INTO swgrouptable(deviceid,scantime,fc_swGroupIndex,fc_swGroupName,fc_swGroupType,snmpindex) VALUES (?,?,?,?,?,?)");
			my $swtrunktable_sth = $mysql->prepare_cached("INSERT INTO swtrunktable(deviceid,scantime,fc_swTrunkPortIndex,fc_swTrunkGroupNumber,fc_swTrunkMaster,fc_swPortTrunked,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $swnbtable_sth = $mysql->prepare_cached("INSERT INTO swnbtable(deviceid,scantime,fc_swNbIndex,fc_swNbMyPort,fc_swNbRemDomain,fc_swNbRemPort,fc_swNbBaudRate,fc_swNbIslState,fc_swNbIslCost,fc_swNbRemPortName,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
			my $swblmperfeemnttable_sth = $mysql->prepare_cached("INSERT INTO swblmperfeemnttable(deviceid,scantime,fc_swBlmPerfEEPort,fc_swBlmPerfEERefKey,fc_swBlmPerfEECRC,fc_swBlmPerfEEFCWRx,fc_swBlmPerfEEFCWTx,fc_swBlmPerfEESid,fc_swBlmPerfEEDid,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $swagtcmtytable_sth = $mysql->prepare_cached("INSERT INTO swagtcmtytable(deviceid,scantime,fc_swAgtCmtyIdx,fc_swAgtCmtyStr,fc_swAgtTrapRcp,fc_swAgtTrapSeverityLevel,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $swfwclassareatable_sth = $mysql->prepare_cached("INSERT INTO swfwclassareatable(deviceid,scantime,fc_swFwClassAreaIndex,fc_swFwWriteThVals,fc_swFwDefaultUnit,fc_swFwDefaultTimebase,fc_swFwDefaultLow,fc_swFwDefaultHigh,fc_swFwDefaultBufSize,fc_swFwCustUnit,fc_swFwCustTimebase,fc_swFwCustLow,fc_swFwCustHigh,fc_swFwCustBufSize,fc_swFwThLevel,fc_swFwWriteActVals,fc_swFwDefaultChangedActs,fc_swFwDefaultExceededActs,fc_swFwDefaultBelowActs,fc_swFwDefaultAboveActs,fc_swFwDefaultInBetweenActs,fc_swFwCustChangedActs,fc_swFwCustExceededActs,fc_swFwCustBelowActs,fc_swFwCustAboveActs,fc_swFwCustInBetweenActs,fc_swFwValidActs,fc_swFwActLevel,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $swfabricmemtable_sth = $mysql->prepare_cached("INSERT INTO swfabricmemtable(deviceid,scantime,fc_swFabricMemWwn,fc_swFabricMemDid,fc_swFabricMemName,fc_swFabricMemEIP,fc_swFabricMemFCIP,fc_swFabricMemGWIP,fc_swFabricMemType,fc_swFabricMemShortVersion,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
			my $swfwthresholdtable_sth = $mysql->prepare_cached("INSERT INTO swfwthresholdtable(deviceid,scantime,fc_swFwThresholdIndex,fc_swFwStatus,fc_swFwName,fc_swFwLabel,fc_swFwCurVal,fc_swFwLastEvent,fc_swFwLastEventVal,fc_swFwLastEventTime,fc_swFwLastState,fc_swFwBehaviorType,fc_swFwBehaviorInt,fc_swFwLastSeverityLevel,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $swgroupmemtable_sth = $mysql->prepare_cached("INSERT INTO swgroupmemtable(deviceid,scantime,fc_swGroupId,fc_swGroupMemWwn,fc_swGroupMemPos,snmpindex) VALUES (?,?,?,?,?,?)");
			my $fcipextendedlinktable_sth = $mysql->prepare_cached("INSERT INTO fcipextendedlinktable(deviceid,scantime,fc_fcipExtendedLinkIfIndex,fc_fcipExtendedLinkTcpRetransmits,fc_fcipExtendedLinkTcpDroppedPackets,fc_fcipExtendedLinkTcpSmoothedRTT,fc_fcipExtendedLinkCompressionRatio,fc_fcipExtendedLinkRawBytes,fc_fcipExtendedLinkCompressedBytes,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $cptable_sth = $mysql->prepare_cached("INSERT INTO cptable(deviceid,scantime,fc_cpStatus,fc_cpIpAddress,fc_cpIpMask,fc_cpIpGateway,fc_cpLastEvent,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $swblmperfalpamnttable_sth = $mysql->prepare_cached("INSERT INTO swblmperfalpamnttable(deviceid,scantime,fc_swBlmPerfAlpaPort,fc_swBlmPerfAlpaIndx,fc_swBlmPerfAlpa,fc_swBlmPerfAlpaCRCCnt,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $fruhistorytable_sth = $mysql->prepare_cached("INSERT INTO fruhistorytable(deviceid,scantime,fc_fruHistoryIndex,fc_fruHistoryClass,fc_fruHistoryObjectNum,fc_fruHistoryEvent,fc_fruHistoryTime,fc_fruHistoryFactoryPartNum,fc_fruHistoryFactorySerialNum,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?)");
			my $swsensortable_sth = $mysql->prepare_cached("INSERT INTO swsensortable(deviceid,scantime,fc_swSensorIndex,fc_swSensorType,fc_swSensorStatus,fc_swSensorValue,fc_swSensorInfo,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
			my $swtrunkgrptable_sth = $mysql->prepare_cached("INSERT INTO swtrunkgrptable(deviceid,scantime,fc_swTrunkGrpNumber,fc_swTrunkGrpMaster,fc_swTrunkGrpTx,fc_swTrunkGrpRx,snmpindex) VALUES (?,?,?,?,?,?,?)");
			my $swnslocaltable_sth = $mysql->prepare_cached("INSERT INTO swnslocaltable(deviceid,scantime,fc_swNsEntryIndex,fc_swNsPortID,fc_swNsPortType,fc_swNsPortName,fc_swNsPortSymb,fc_swNsNodeName,fc_swNsNodeSymb,fc_swNsIPA,fc_swNsIpAddress,fc_swNsCos,fc_swNsFc4,fc_swNsIpNxPort,fc_swNsWwn,fc_swNsHardAddr,snmpindex) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			my $sweventtable_sth = $mysql->prepare_cached("INSERT INTO sweventtable(deviceid,scantime,fc_swEventIndex,fc_swEventTimeInfo,fc_swEventLevel,fc_swEventRepeatCount,fc_swEventDescr,snmpindex) VALUES (?,?,?,?,?,?,?,?)");
##Collect information for tableswfcporttable
			my $fc_swFCPortIndex=$info->fc_swFCPortIndex();
			my $fc_swFCPortType=$info->fc_swFCPortType();
			my $fc_swFCPortPhyState=$info->fc_swFCPortPhyState();
			my $fc_swFCPortOpStatus=$info->fc_swFCPortOpStatus();
			my $fc_swFCPortAdmStatus=$info->fc_swFCPortAdmStatus();
			my $fc_swFCPortLinkState=$info->fc_swFCPortLinkState();
			my $fc_swFCPortTxType=$info->fc_swFCPortTxType();
			my $fc_swFCPortTxWords=$info->fc_swFCPortTxWords();
			my $fc_swFCPortRxWords=$info->fc_swFCPortRxWords();
			my $fc_swFCPortTxFrames=$info->fc_swFCPortTxFrames();
			my $fc_swFCPortRxFrames=$info->fc_swFCPortRxFrames();
			my $fc_swFCPortRxC2Frames=$info->fc_swFCPortRxC2Frames();
			my $fc_swFCPortRxC3Frames=$info->fc_swFCPortRxC3Frames();
			my $fc_swFCPortRxLCs=$info->fc_swFCPortRxLCs();
			my $fc_swFCPortRxMcasts=$info->fc_swFCPortRxMcasts();
			my $fc_swFCPortTooManyRdys=$info->fc_swFCPortTooManyRdys();
			my $fc_swFCPortNoTxCredits=$info->fc_swFCPortNoTxCredits();
			my $fc_swFCPortRxEncInFrs=$info->fc_swFCPortRxEncInFrs();
			my $fc_swFCPortRxCrcs=$info->fc_swFCPortRxCrcs();
			my $fc_swFCPortRxTruncs=$info->fc_swFCPortRxTruncs();
			my $fc_swFCPortRxTooLongs=$info->fc_swFCPortRxTooLongs();
			my $fc_swFCPortRxBadEofs=$info->fc_swFCPortRxBadEofs();
			my $fc_swFCPortRxEncOutFrs=$info->fc_swFCPortRxEncOutFrs();
			my $fc_swFCPortRxBadOs=$info->fc_swFCPortRxBadOs();
			my $fc_swFCPortC3Discards=$info->fc_swFCPortC3Discards();
			my $fc_swFCPortMcastTimedOuts=$info->fc_swFCPortMcastTimedOuts();
			my $fc_swFCPortTxMcasts=$info->fc_swFCPortTxMcasts();
			my $fc_swFCPortLipIns=$info->fc_swFCPortLipIns();
			my $fc_swFCPortLipOuts=$info->fc_swFCPortLipOuts();
			my $fc_swFCPortLipLastAlpa=$info->fc_swFCPortLipLastAlpa();
			my $fc_swFCPortWwn=$info->fc_swFCPortWwn();
			my $fc_swFCPortSpeed=$info->fc_swFCPortSpeed();
			my $fc_swFCPortName=$info->fc_swFCPortName();
			my $fc_swFCPortSpecifier=$info->fc_swFCPortSpecifier();
			my $fc_swFCPortFlag=$info->fc_swFCPortFlag();
			my $fc_swFCPortBrcdType=$info->fc_swFCPortBrcdType();

##Collect information for tablefrutable
			my $fc_fruClass=$info->fc_fruClass();
			my $fc_fruStatus=$info->fc_fruStatus();
			my $fc_fruObjectNum=$info->fc_fruObjectNum();
			my $fc_fruSupplierId=$info->fc_fruSupplierId();
			my $fc_fruSupplierPartNum=$info->fc_fruSupplierPartNum();
			my $fc_fruSupplierSerialNum=$info->fc_fruSupplierSerialNum();
			my $fc_fruSupplierRevCode=$info->fc_fruSupplierRevCode();

##Collect information for tableswenddevicerlstable
			my $fc_swEndDevicePort=$info->fc_swEndDevicePort();
			my $fc_swEndDeviceAlpa=$info->fc_swEndDeviceAlpa();
			my $fc_swEndDevicePortID=$info->fc_swEndDevicePortID();
			my $fc_swEndDeviceLinkFailure=$info->fc_swEndDeviceLinkFailure();
			my $fc_swEndDeviceSyncLoss=$info->fc_swEndDeviceSyncLoss();
			my $fc_swEndDeviceSigLoss=$info->fc_swEndDeviceSigLoss();
			my $fc_swEndDeviceProtoErr=$info->fc_swEndDeviceProtoErr();
			my $fc_swEndDeviceInvalidWord=$info->fc_swEndDeviceInvalidWord();
			my $fc_swEndDeviceInvalidCRC=$info->fc_swEndDeviceInvalidCRC();

##Collect information for tableswblmperffltmnttable
			my $fc_swBlmPerfFltPort=$info->fc_swBlmPerfFltPort();
			my $fc_swBlmPerfFltRefkey=$info->fc_swBlmPerfFltRefkey();
			my $fc_swBlmPerfFltCnt=$info->fc_swBlmPerfFltCnt();
			my $fc_swBlmPerfFltAlias=$info->fc_swBlmPerfFltAlias();

##Collect information for tableswgrouptable
			my $fc_swGroupIndex=$info->fc_swGroupIndex();
			my $fc_swGroupName=$info->fc_swGroupName();
			my $fc_swGroupType=$info->fc_swGroupType();

##Collect information for tableswtrunktable
			my $fc_swTrunkPortIndex=$info->fc_swTrunkPortIndex();
			my $fc_swTrunkGroupNumber=$info->fc_swTrunkGroupNumber();
			my $fc_swTrunkMaster=$info->fc_swTrunkMaster();
			my $fc_swPortTrunked=$info->fc_swPortTrunked();

##Collect information for tableswnbtable
			my $fc_swNbIndex=$info->fc_swNbIndex();
			my $fc_swNbMyPort=$info->fc_swNbMyPort();
			my $fc_swNbRemDomain=$info->fc_swNbRemDomain();
			my $fc_swNbRemPort=$info->fc_swNbRemPort();
			my $fc_swNbBaudRate=$info->fc_swNbBaudRate();
			my $fc_swNbIslState=$info->fc_swNbIslState();
			my $fc_swNbIslCost=$info->fc_swNbIslCost();
			my $fc_swNbRemPortName=$info->fc_swNbRemPortName();

##Collect information for tableswblmperfeemnttable
			my $fc_swBlmPerfEEPort=$info->fc_swBlmPerfEEPort();
			my $fc_swBlmPerfEERefKey=$info->fc_swBlmPerfEERefKey();
			my $fc_swBlmPerfEECRC=$info->fc_swBlmPerfEECRC();
			my $fc_swBlmPerfEEFCWRx=$info->fc_swBlmPerfEEFCWRx();
			my $fc_swBlmPerfEEFCWTx=$info->fc_swBlmPerfEEFCWTx();
			my $fc_swBlmPerfEESid=$info->fc_swBlmPerfEESid();
			my $fc_swBlmPerfEEDid=$info->fc_swBlmPerfEEDid();

##Collect information for tableswagtcmtytable
			my $fc_swAgtCmtyIdx=$info->fc_swAgtCmtyIdx();
			my $fc_swAgtCmtyStr=$info->fc_swAgtCmtyStr();
			my $fc_swAgtTrapRcp=$info->fc_swAgtTrapRcp();
			my $fc_swAgtTrapSeverityLevel=$info->fc_swAgtTrapSeverityLevel();

##Collect information for tableswfwclassareatable
			my $fc_swFwClassAreaIndex=$info->fc_swFwClassAreaIndex();
			my $fc_swFwWriteThVals=$info->fc_swFwWriteThVals();
			my $fc_swFwDefaultUnit=$info->fc_swFwDefaultUnit();
			my $fc_swFwDefaultTimebase=$info->fc_swFwDefaultTimebase();
			my $fc_swFwDefaultLow=$info->fc_swFwDefaultLow();
			my $fc_swFwDefaultHigh=$info->fc_swFwDefaultHigh();
			my $fc_swFwDefaultBufSize=$info->fc_swFwDefaultBufSize();
			my $fc_swFwCustUnit=$info->fc_swFwCustUnit();
			my $fc_swFwCustTimebase=$info->fc_swFwCustTimebase();
			my $fc_swFwCustLow=$info->fc_swFwCustLow();
			my $fc_swFwCustHigh=$info->fc_swFwCustHigh();
			my $fc_swFwCustBufSize=$info->fc_swFwCustBufSize();
			my $fc_swFwThLevel=$info->fc_swFwThLevel();
			my $fc_swFwWriteActVals=$info->fc_swFwWriteActVals();
			my $fc_swFwDefaultChangedActs=$info->fc_swFwDefaultChangedActs();
			my $fc_swFwDefaultExceededActs=$info->fc_swFwDefaultExceededActs();
			my $fc_swFwDefaultBelowActs=$info->fc_swFwDefaultBelowActs();
			my $fc_swFwDefaultAboveActs=$info->fc_swFwDefaultAboveActs();
			my $fc_swFwDefaultInBetweenActs=$info->fc_swFwDefaultInBetweenActs();
			my $fc_swFwCustChangedActs=$info->fc_swFwCustChangedActs();
			my $fc_swFwCustExceededActs=$info->fc_swFwCustExceededActs();
			my $fc_swFwCustBelowActs=$info->fc_swFwCustBelowActs();
			my $fc_swFwCustAboveActs=$info->fc_swFwCustAboveActs();
			my $fc_swFwCustInBetweenActs=$info->fc_swFwCustInBetweenActs();
			my $fc_swFwValidActs=$info->fc_swFwValidActs();
			my $fc_swFwActLevel=$info->fc_swFwActLevel();

##Collect information for tableswfabricmemtable
			my $fc_swFabricMemWwn=$info->fc_swFabricMemWwn();
			my $fc_swFabricMemDid=$info->fc_swFabricMemDid();
			my $fc_swFabricMemName=$info->fc_swFabricMemName();
			my $fc_swFabricMemEIP=$info->fc_swFabricMemEIP();
			my $fc_swFabricMemFCIP=$info->fc_swFabricMemFCIP();
			my $fc_swFabricMemGWIP=$info->fc_swFabricMemGWIP();
			my $fc_swFabricMemType=$info->fc_swFabricMemType();
			my $fc_swFabricMemShortVersion=$info->fc_swFabricMemShortVersion();

##Collect information for tableswfwthresholdtable
			my $fc_swFwThresholdIndex=$info->fc_swFwThresholdIndex();
			my $fc_swFwStatus=$info->fc_swFwStatus();
			my $fc_swFwName=$info->fc_swFwName();
			my $fc_swFwLabel=$info->fc_swFwLabel();
			my $fc_swFwCurVal=$info->fc_swFwCurVal();
			my $fc_swFwLastEvent=$info->fc_swFwLastEvent();
			my $fc_swFwLastEventVal=$info->fc_swFwLastEventVal();
			my $fc_swFwLastEventTime=$info->fc_swFwLastEventTime();
			my $fc_swFwLastState=$info->fc_swFwLastState();
			my $fc_swFwBehaviorType=$info->fc_swFwBehaviorType();
			my $fc_swFwBehaviorInt=$info->fc_swFwBehaviorInt();
			my $fc_swFwLastSeverityLevel=$info->fc_swFwLastSeverityLevel();

##Collect information for tableswgroupmemtable
			my $fc_swGroupId=$info->fc_swGroupId();
			my $fc_swGroupMemWwn=$info->fc_swGroupMemWwn();
			my $fc_swGroupMemPos=$info->fc_swGroupMemPos();

##Collect information for tablefcipextendedlinktable
			my $fc_fcipExtendedLinkIfIndex=$info->fc_fcipExtendedLinkIfIndex();
			my $fc_fcipExtendedLinkTcpRetransmits=$info->fc_fcipExtendedLinkTcpRetransmits();
			my $fc_fcipExtendedLinkTcpDroppedPackets=$info->fc_fcipExtendedLinkTcpDroppedPackets();
			my $fc_fcipExtendedLinkTcpSmoothedRTT=$info->fc_fcipExtendedLinkTcpSmoothedRTT();
			my $fc_fcipExtendedLinkCompressionRatio=$info->fc_fcipExtendedLinkCompressionRatio();
			my $fc_fcipExtendedLinkRawBytes=$info->fc_fcipExtendedLinkRawBytes();
			my $fc_fcipExtendedLinkCompressedBytes=$info->fc_fcipExtendedLinkCompressedBytes();

##Collect information for tablecptable
			my $fc_cpStatus=$info->fc_cpStatus();
			my $fc_cpIpAddress=$info->fc_cpIpAddress();
			my $fc_cpIpMask=$info->fc_cpIpMask();
			my $fc_cpIpGateway=$info->fc_cpIpGateway();
			my $fc_cpLastEvent=$info->fc_cpLastEvent();

##Collect information for tableswblmperfalpamnttable
			my $fc_swBlmPerfAlpaPort=$info->fc_swBlmPerfAlpaPort();
			my $fc_swBlmPerfAlpaIndx=$info->fc_swBlmPerfAlpaIndx();
			my $fc_swBlmPerfAlpa=$info->fc_swBlmPerfAlpa();
			my $fc_swBlmPerfAlpaCRCCnt=$info->fc_swBlmPerfAlpaCRCCnt();

##Collect information for tablefruhistorytable
			my $fc_fruHistoryIndex=$info->fc_fruHistoryIndex();
			my $fc_fruHistoryClass=$info->fc_fruHistoryClass();
			my $fc_fruHistoryObjectNum=$info->fc_fruHistoryObjectNum();
			my $fc_fruHistoryEvent=$info->fc_fruHistoryEvent();
			my $fc_fruHistoryTime=$info->fc_fruHistoryTime();
			my $fc_fruHistoryFactoryPartNum=$info->fc_fruHistoryFactoryPartNum();
			my $fc_fruHistoryFactorySerialNum=$info->fc_fruHistoryFactorySerialNum();

##Collect information for tableswsensortable
			my $fc_swSensorIndex=$info->fc_swSensorIndex();
			my $fc_swSensorType=$info->fc_swSensorType();
			my $fc_swSensorStatus=$info->fc_swSensorStatus();
			my $fc_swSensorValue=$info->fc_swSensorValue();
			my $fc_swSensorInfo=$info->fc_swSensorInfo();

##Collect information for tableswtrunkgrptable
			my $fc_swTrunkGrpNumber=$info->fc_swTrunkGrpNumber();
			my $fc_swTrunkGrpMaster=$info->fc_swTrunkGrpMaster();
			my $fc_swTrunkGrpTx=$info->fc_swTrunkGrpTx();
			my $fc_swTrunkGrpRx=$info->fc_swTrunkGrpRx();

##Collect information for tableswnslocaltable
			my $fc_swNsEntryIndex=$info->fc_swNsEntryIndex();
			my $fc_swNsPortID=$info->fc_swNsPortID();
			my $fc_swNsPortType=$info->fc_swNsPortType();
			my $fc_swNsPortName=$info->fc_swNsPortName();
			my $fc_swNsPortSymb=$info->fc_swNsPortSymb();
			my $fc_swNsNodeName=$info->fc_swNsNodeName();
			my $fc_swNsNodeSymb=$info->fc_swNsNodeSymb();
			my $fc_swNsIPA=$info->fc_swNsIPA();
			my $fc_swNsIpAddress=$info->fc_swNsIpAddress();
			my $fc_swNsCos=$info->fc_swNsCos();
			my $fc_swNsFc4=$info->fc_swNsFc4();
			my $fc_swNsIpNxPort=$info->fc_swNsIpNxPort();
			my $fc_swNsWwn=$info->fc_swNsWwn();
			my $fc_swNsHardAddr=$info->fc_swNsHardAddr();

##Collect information for tablesweventtable
			my $fc_swEventIndex=$info->fc_swEventIndex();
			my $fc_swEventTimeInfo=$info->fc_swEventTimeInfo();
			my $fc_swEventLevel=$info->fc_swEventLevel();
			my $fc_swEventRepeatCount=$info->fc_swEventRepeatCount();
			my $fc_swEventDescr=$info->fc_swEventDescr();

			foreach my $putinv (keys %$fc_swFCPortBrcdType){
				my $fc_swFCPortIndex_1=$fc_swFCPortIndex->{$putinv};
				my $fc_swFCPortType_1=$fc_swFCPortType->{$putinv};
				my $fc_swFCPortPhyState_1=$fc_swFCPortPhyState->{$putinv};
				my $fc_swFCPortOpStatus_1=$fc_swFCPortOpStatus->{$putinv};
				my $fc_swFCPortAdmStatus_1=$fc_swFCPortAdmStatus->{$putinv};
				my $fc_swFCPortLinkState_1=$fc_swFCPortLinkState->{$putinv};
				my $fc_swFCPortTxType_1=$fc_swFCPortTxType->{$putinv};
				my $fc_swFCPortTxWords_1=$fc_swFCPortTxWords->{$putinv};
				my $fc_swFCPortRxWords_1=$fc_swFCPortRxWords->{$putinv};
				my $fc_swFCPortTxFrames_1=$fc_swFCPortTxFrames->{$putinv};
				my $fc_swFCPortRxFrames_1=$fc_swFCPortRxFrames->{$putinv};
				my $fc_swFCPortRxC2Frames_1=$fc_swFCPortRxC2Frames->{$putinv};
				my $fc_swFCPortRxC3Frames_1=$fc_swFCPortRxC3Frames->{$putinv};
				my $fc_swFCPortRxLCs_1=$fc_swFCPortRxLCs->{$putinv};
				my $fc_swFCPortRxMcasts_1=$fc_swFCPortRxMcasts->{$putinv};
				my $fc_swFCPortTooManyRdys_1=$fc_swFCPortTooManyRdys->{$putinv};
				my $fc_swFCPortNoTxCredits_1=$fc_swFCPortNoTxCredits->{$putinv};
				my $fc_swFCPortRxEncInFrs_1=$fc_swFCPortRxEncInFrs->{$putinv};
				my $fc_swFCPortRxCrcs_1=$fc_swFCPortRxCrcs->{$putinv};
				my $fc_swFCPortRxTruncs_1=$fc_swFCPortRxTruncs->{$putinv};
				my $fc_swFCPortRxTooLongs_1=$fc_swFCPortRxTooLongs->{$putinv};
				my $fc_swFCPortRxBadEofs_1=$fc_swFCPortRxBadEofs->{$putinv};
				my $fc_swFCPortRxEncOutFrs_1=$fc_swFCPortRxEncOutFrs->{$putinv};
				my $fc_swFCPortRxBadOs_1=$fc_swFCPortRxBadOs->{$putinv};
				my $fc_swFCPortC3Discards_1=$fc_swFCPortC3Discards->{$putinv};
				my $fc_swFCPortMcastTimedOuts_1=$fc_swFCPortMcastTimedOuts->{$putinv};
				my $fc_swFCPortTxMcasts_1=$fc_swFCPortTxMcasts->{$putinv};
				my $fc_swFCPortLipIns_1=$fc_swFCPortLipIns->{$putinv};
				my $fc_swFCPortLipOuts_1=$fc_swFCPortLipOuts->{$putinv};
				my $fc_swFCPortLipLastAlpa_1=$fc_swFCPortLipLastAlpa->{$putinv};
				my $fc_swFCPortWwn_1=$fc_swFCPortWwn->{$putinv};
				my $fc_swFCPortSpeed_1=$fc_swFCPortSpeed->{$putinv};
				my $fc_swFCPortName_1=$fc_swFCPortName->{$putinv};
				my $fc_swFCPortSpecifier_1=$fc_swFCPortSpecifier->{$putinv};
				my $fc_swFCPortFlag_1=$fc_swFCPortFlag->{$putinv};
				my $fc_swFCPortBrcdType_1=$fc_swFCPortBrcdType->{$putinv};
				$swfcporttable_sth->execute($deviceid,$scantime,$fc_swFCPortIndex_1,$fc_swFCPortType_1,$fc_swFCPortPhyState_1,$fc_swFCPortOpStatus_1,$fc_swFCPortAdmStatus_1,$fc_swFCPortLinkState_1,$fc_swFCPortTxType_1,$fc_swFCPortTxWords_1,$fc_swFCPortRxWords_1,$fc_swFCPortTxFrames_1,$fc_swFCPortRxFrames_1,$fc_swFCPortRxC2Frames_1,$fc_swFCPortRxC3Frames_1,$fc_swFCPortRxLCs_1,$fc_swFCPortRxMcasts_1,$fc_swFCPortTooManyRdys_1,$fc_swFCPortNoTxCredits_1,$fc_swFCPortRxEncInFrs_1,$fc_swFCPortRxCrcs_1,$fc_swFCPortRxTruncs_1,$fc_swFCPortRxTooLongs_1,$fc_swFCPortRxBadEofs_1,$fc_swFCPortRxEncOutFrs_1,$fc_swFCPortRxBadOs_1,$fc_swFCPortC3Discards_1,$fc_swFCPortMcastTimedOuts_1,$fc_swFCPortTxMcasts_1,$fc_swFCPortLipIns_1,$fc_swFCPortLipOuts_1,$fc_swFCPortLipLastAlpa_1,$fc_swFCPortWwn_1,$fc_swFCPortSpeed_1,$fc_swFCPortName_1,$fc_swFCPortSpecifier_1,$fc_swFCPortFlag_1,$fc_swFCPortBrcdType_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fruSupplierRevCode){
				my $fc_fruClass_1=$fc_fruClass->{$putinv};
				my $fc_fruStatus_1=$fc_fruStatus->{$putinv};
				my $fc_fruObjectNum_1=$fc_fruObjectNum->{$putinv};
				my $fc_fruSupplierId_1=$fc_fruSupplierId->{$putinv};
				my $fc_fruSupplierPartNum_1=$fc_fruSupplierPartNum->{$putinv};
				my $fc_fruSupplierSerialNum_1=$fc_fruSupplierSerialNum->{$putinv};
				my $fc_fruSupplierRevCode_1=$fc_fruSupplierRevCode->{$putinv};
				$frutable_sth->execute($deviceid,$scantime,$fc_fruClass_1,$fc_fruStatus_1,$fc_fruObjectNum_1,$fc_fruSupplierId_1,$fc_fruSupplierPartNum_1,$fc_fruSupplierSerialNum_1,$fc_fruSupplierRevCode_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swEndDeviceInvalidCRC){
				my $fc_swEndDevicePort_1=$fc_swEndDevicePort->{$putinv};
				my $fc_swEndDeviceAlpa_1=$fc_swEndDeviceAlpa->{$putinv};
				my $fc_swEndDevicePortID_1=$fc_swEndDevicePortID->{$putinv};
				my $fc_swEndDeviceLinkFailure_1=$fc_swEndDeviceLinkFailure->{$putinv};
				my $fc_swEndDeviceSyncLoss_1=$fc_swEndDeviceSyncLoss->{$putinv};
				my $fc_swEndDeviceSigLoss_1=$fc_swEndDeviceSigLoss->{$putinv};
				my $fc_swEndDeviceProtoErr_1=$fc_swEndDeviceProtoErr->{$putinv};
				my $fc_swEndDeviceInvalidWord_1=$fc_swEndDeviceInvalidWord->{$putinv};
				my $fc_swEndDeviceInvalidCRC_1=$fc_swEndDeviceInvalidCRC->{$putinv};
				$swenddevicerlstable_sth->execute($deviceid,$scantime,$fc_swEndDevicePort_1,$fc_swEndDeviceAlpa_1,$fc_swEndDevicePortID_1,$fc_swEndDeviceLinkFailure_1,$fc_swEndDeviceSyncLoss_1,$fc_swEndDeviceSigLoss_1,$fc_swEndDeviceProtoErr_1,$fc_swEndDeviceInvalidWord_1,$fc_swEndDeviceInvalidCRC_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swBlmPerfFltAlias){
				my $fc_swBlmPerfFltPort_1=$fc_swBlmPerfFltPort->{$putinv};
				my $fc_swBlmPerfFltRefkey_1=$fc_swBlmPerfFltRefkey->{$putinv};
				my $fc_swBlmPerfFltCnt_1=$fc_swBlmPerfFltCnt->{$putinv};
				my $fc_swBlmPerfFltAlias_1=$fc_swBlmPerfFltAlias->{$putinv};
				$swblmperffltmnttable_sth->execute($deviceid,$scantime,$fc_swBlmPerfFltPort_1,$fc_swBlmPerfFltRefkey_1,$fc_swBlmPerfFltCnt_1,$fc_swBlmPerfFltAlias_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swGroupType){
				my $fc_swGroupIndex_1=$fc_swGroupIndex->{$putinv};
				my $fc_swGroupName_1=$fc_swGroupName->{$putinv};
				my $fc_swGroupType_1=$fc_swGroupType->{$putinv};
				$swgrouptable_sth->execute($deviceid,$scantime,$fc_swGroupIndex_1,$fc_swGroupName_1,$fc_swGroupType_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swPortTrunked){
				my $fc_swTrunkPortIndex_1=$fc_swTrunkPortIndex->{$putinv};
				my $fc_swTrunkGroupNumber_1=$fc_swTrunkGroupNumber->{$putinv};
				my $fc_swTrunkMaster_1=$fc_swTrunkMaster->{$putinv};
				my $fc_swPortTrunked_1=$fc_swPortTrunked->{$putinv};
				$swtrunktable_sth->execute($deviceid,$scantime,$fc_swTrunkPortIndex_1,$fc_swTrunkGroupNumber_1,$fc_swTrunkMaster_1,$fc_swPortTrunked_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swNbRemPortName){
				my $fc_swNbIndex_1=$fc_swNbIndex->{$putinv};
				my $fc_swNbMyPort_1=$fc_swNbMyPort->{$putinv};
				my $fc_swNbRemDomain_1=$fc_swNbRemDomain->{$putinv};
				my $fc_swNbRemPort_1=$fc_swNbRemPort->{$putinv};
				my $fc_swNbBaudRate_1=$fc_swNbBaudRate->{$putinv};
				my $fc_swNbIslState_1=$fc_swNbIslState->{$putinv};
				my $fc_swNbIslCost_1=$fc_swNbIslCost->{$putinv};
				my $fc_swNbRemPortName_1=$fc_swNbRemPortName->{$putinv};
				$swnbtable_sth->execute($deviceid,$scantime,$fc_swNbIndex_1,$fc_swNbMyPort_1,$fc_swNbRemDomain_1,$fc_swNbRemPort_1,$fc_swNbBaudRate_1,$fc_swNbIslState_1,$fc_swNbIslCost_1,$fc_swNbRemPortName_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swBlmPerfEEDid){
				my $fc_swBlmPerfEEPort_1=$fc_swBlmPerfEEPort->{$putinv};
				my $fc_swBlmPerfEERefKey_1=$fc_swBlmPerfEERefKey->{$putinv};
				my $fc_swBlmPerfEECRC_1=$fc_swBlmPerfEECRC->{$putinv};
				my $fc_swBlmPerfEEFCWRx_1=$fc_swBlmPerfEEFCWRx->{$putinv};
				my $fc_swBlmPerfEEFCWTx_1=$fc_swBlmPerfEEFCWTx->{$putinv};
				my $fc_swBlmPerfEESid_1=$fc_swBlmPerfEESid->{$putinv};
				my $fc_swBlmPerfEEDid_1=$fc_swBlmPerfEEDid->{$putinv};
				$swblmperfeemnttable_sth->execute($deviceid,$scantime,$fc_swBlmPerfEEPort_1,$fc_swBlmPerfEERefKey_1,$fc_swBlmPerfEECRC_1,$fc_swBlmPerfEEFCWRx_1,$fc_swBlmPerfEEFCWTx_1,$fc_swBlmPerfEESid_1,$fc_swBlmPerfEEDid_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swAgtTrapSeverityLevel){
				my $fc_swAgtCmtyIdx_1=$fc_swAgtCmtyIdx->{$putinv};
				my $fc_swAgtCmtyStr_1=$fc_swAgtCmtyStr->{$putinv};
				my $fc_swAgtTrapRcp_1=$fc_swAgtTrapRcp->{$putinv};
				my $fc_swAgtTrapSeverityLevel_1=$fc_swAgtTrapSeverityLevel->{$putinv};
				$swagtcmtytable_sth->execute($deviceid,$scantime,$fc_swAgtCmtyIdx_1,$fc_swAgtCmtyStr_1,$fc_swAgtTrapRcp_1,$fc_swAgtTrapSeverityLevel_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swFwActLevel){
				my $fc_swFwClassAreaIndex_1=$fc_swFwClassAreaIndex->{$putinv};
				my $fc_swFwWriteThVals_1=$fc_swFwWriteThVals->{$putinv};
				my $fc_swFwDefaultUnit_1=$fc_swFwDefaultUnit->{$putinv};
				my $fc_swFwDefaultTimebase_1=$fc_swFwDefaultTimebase->{$putinv};
				my $fc_swFwDefaultLow_1=$fc_swFwDefaultLow->{$putinv};
				my $fc_swFwDefaultHigh_1=$fc_swFwDefaultHigh->{$putinv};
				my $fc_swFwDefaultBufSize_1=$fc_swFwDefaultBufSize->{$putinv};
				my $fc_swFwCustUnit_1=$fc_swFwCustUnit->{$putinv};
				my $fc_swFwCustTimebase_1=$fc_swFwCustTimebase->{$putinv};
				my $fc_swFwCustLow_1=$fc_swFwCustLow->{$putinv};
				my $fc_swFwCustHigh_1=$fc_swFwCustHigh->{$putinv};
				my $fc_swFwCustBufSize_1=$fc_swFwCustBufSize->{$putinv};
				my $fc_swFwThLevel_1=$fc_swFwThLevel->{$putinv};
				my $fc_swFwWriteActVals_1=$fc_swFwWriteActVals->{$putinv};
				my $fc_swFwDefaultChangedActs_1=$fc_swFwDefaultChangedActs->{$putinv};
				my $fc_swFwDefaultExceededActs_1=$fc_swFwDefaultExceededActs->{$putinv};
				my $fc_swFwDefaultBelowActs_1=$fc_swFwDefaultBelowActs->{$putinv};
				my $fc_swFwDefaultAboveActs_1=$fc_swFwDefaultAboveActs->{$putinv};
				my $fc_swFwDefaultInBetweenActs_1=$fc_swFwDefaultInBetweenActs->{$putinv};
				my $fc_swFwCustChangedActs_1=$fc_swFwCustChangedActs->{$putinv};
				my $fc_swFwCustExceededActs_1=$fc_swFwCustExceededActs->{$putinv};
				my $fc_swFwCustBelowActs_1=$fc_swFwCustBelowActs->{$putinv};
				my $fc_swFwCustAboveActs_1=$fc_swFwCustAboveActs->{$putinv};
				my $fc_swFwCustInBetweenActs_1=$fc_swFwCustInBetweenActs->{$putinv};
				my $fc_swFwValidActs_1=$fc_swFwValidActs->{$putinv};
				my $fc_swFwActLevel_1=$fc_swFwActLevel->{$putinv};
				$swfwclassareatable_sth->execute($deviceid,$scantime,$fc_swFwClassAreaIndex_1,$fc_swFwWriteThVals_1,$fc_swFwDefaultUnit_1,$fc_swFwDefaultTimebase_1,$fc_swFwDefaultLow_1,$fc_swFwDefaultHigh_1,$fc_swFwDefaultBufSize_1,$fc_swFwCustUnit_1,$fc_swFwCustTimebase_1,$fc_swFwCustLow_1,$fc_swFwCustHigh_1,$fc_swFwCustBufSize_1,$fc_swFwThLevel_1,$fc_swFwWriteActVals_1,$fc_swFwDefaultChangedActs_1,$fc_swFwDefaultExceededActs_1,$fc_swFwDefaultBelowActs_1,$fc_swFwDefaultAboveActs_1,$fc_swFwDefaultInBetweenActs_1,$fc_swFwCustChangedActs_1,$fc_swFwCustExceededActs_1,$fc_swFwCustBelowActs_1,$fc_swFwCustAboveActs_1,$fc_swFwCustInBetweenActs_1,$fc_swFwValidActs_1,$fc_swFwActLevel_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swFabricMemShortVersion){
				my $fc_swFabricMemWwn_1=$fc_swFabricMemWwn->{$putinv};
				my $fc_swFabricMemDid_1=$fc_swFabricMemDid->{$putinv};
				my $fc_swFabricMemName_1=$fc_swFabricMemName->{$putinv};
				my $fc_swFabricMemEIP_1=$fc_swFabricMemEIP->{$putinv};
				my $fc_swFabricMemFCIP_1=$fc_swFabricMemFCIP->{$putinv};
				my $fc_swFabricMemGWIP_1=$fc_swFabricMemGWIP->{$putinv};
				my $fc_swFabricMemType_1=$fc_swFabricMemType->{$putinv};
				my $fc_swFabricMemShortVersion_1=$fc_swFabricMemShortVersion->{$putinv};
				$swfabricmemtable_sth->execute($deviceid,$scantime,$fc_swFabricMemWwn_1,$fc_swFabricMemDid_1,$fc_swFabricMemName_1,$fc_swFabricMemEIP_1,$fc_swFabricMemFCIP_1,$fc_swFabricMemGWIP_1,$fc_swFabricMemType_1,$fc_swFabricMemShortVersion_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swFwLastSeverityLevel){
				my $fc_swFwThresholdIndex_1=$fc_swFwThresholdIndex->{$putinv};
				my $fc_swFwStatus_1=$fc_swFwStatus->{$putinv};
				my $fc_swFwName_1=$fc_swFwName->{$putinv};
				my $fc_swFwLabel_1=$fc_swFwLabel->{$putinv};
				my $fc_swFwCurVal_1=$fc_swFwCurVal->{$putinv};
				my $fc_swFwLastEvent_1=$fc_swFwLastEvent->{$putinv};
				my $fc_swFwLastEventVal_1=$fc_swFwLastEventVal->{$putinv};
				my $fc_swFwLastEventTime_1=$fc_swFwLastEventTime->{$putinv};
				my $fc_swFwLastState_1=$fc_swFwLastState->{$putinv};
				my $fc_swFwBehaviorType_1=$fc_swFwBehaviorType->{$putinv};
				my $fc_swFwBehaviorInt_1=$fc_swFwBehaviorInt->{$putinv};
				my $fc_swFwLastSeverityLevel_1=$fc_swFwLastSeverityLevel->{$putinv};
				$swfwthresholdtable_sth->execute($deviceid,$scantime,$fc_swFwThresholdIndex_1,$fc_swFwStatus_1,$fc_swFwName_1,$fc_swFwLabel_1,$fc_swFwCurVal_1,$fc_swFwLastEvent_1,$fc_swFwLastEventVal_1,$fc_swFwLastEventTime_1,$fc_swFwLastState_1,$fc_swFwBehaviorType_1,$fc_swFwBehaviorInt_1,$fc_swFwLastSeverityLevel_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swGroupMemPos){
				my $fc_swGroupId_1=$fc_swGroupId->{$putinv};
				my $fc_swGroupMemWwn_1=$fc_swGroupMemWwn->{$putinv};
				my $fc_swGroupMemPos_1=$fc_swGroupMemPos->{$putinv};
				$swgroupmemtable_sth->execute($deviceid,$scantime,$fc_swGroupId_1,$fc_swGroupMemWwn_1,$fc_swGroupMemPos_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fcipExtendedLinkCompressedBytes){
				my $fc_fcipExtendedLinkIfIndex_1=$fc_fcipExtendedLinkIfIndex->{$putinv};
				my $fc_fcipExtendedLinkTcpRetransmits_1=$fc_fcipExtendedLinkTcpRetransmits->{$putinv};
				my $fc_fcipExtendedLinkTcpDroppedPackets_1=$fc_fcipExtendedLinkTcpDroppedPackets->{$putinv};
				my $fc_fcipExtendedLinkTcpSmoothedRTT_1=$fc_fcipExtendedLinkTcpSmoothedRTT->{$putinv};
				my $fc_fcipExtendedLinkCompressionRatio_1=$fc_fcipExtendedLinkCompressionRatio->{$putinv};
				my $fc_fcipExtendedLinkRawBytes_1=$fc_fcipExtendedLinkRawBytes->{$putinv};
				my $fc_fcipExtendedLinkCompressedBytes_1=$fc_fcipExtendedLinkCompressedBytes->{$putinv};
				$fcipextendedlinktable_sth->execute($deviceid,$scantime,$fc_fcipExtendedLinkIfIndex_1,$fc_fcipExtendedLinkTcpRetransmits_1,$fc_fcipExtendedLinkTcpDroppedPackets_1,$fc_fcipExtendedLinkTcpSmoothedRTT_1,$fc_fcipExtendedLinkCompressionRatio_1,$fc_fcipExtendedLinkRawBytes_1,$fc_fcipExtendedLinkCompressedBytes_1,$putinv);
			}
			foreach my $putinv (keys %$fc_cpLastEvent){
				my $fc_cpStatus_1=$fc_cpStatus->{$putinv};
				my $fc_cpIpAddress_1=$fc_cpIpAddress->{$putinv};
				my $fc_cpIpMask_1=$fc_cpIpMask->{$putinv};
				my $fc_cpIpGateway_1=$fc_cpIpGateway->{$putinv};
				my $fc_cpLastEvent_1=$fc_cpLastEvent->{$putinv};
				$cptable_sth->execute($deviceid,$scantime,$fc_cpStatus_1,$fc_cpIpAddress_1,$fc_cpIpMask_1,$fc_cpIpGateway_1,$fc_cpLastEvent_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swBlmPerfAlpaCRCCnt){
				my $fc_swBlmPerfAlpaPort_1=$fc_swBlmPerfAlpaPort->{$putinv};
				my $fc_swBlmPerfAlpaIndx_1=$fc_swBlmPerfAlpaIndx->{$putinv};
				my $fc_swBlmPerfAlpa_1=$fc_swBlmPerfAlpa->{$putinv};
				my $fc_swBlmPerfAlpaCRCCnt_1=$fc_swBlmPerfAlpaCRCCnt->{$putinv};
				$swblmperfalpamnttable_sth->execute($deviceid,$scantime,$fc_swBlmPerfAlpaPort_1,$fc_swBlmPerfAlpaIndx_1,$fc_swBlmPerfAlpa_1,$fc_swBlmPerfAlpaCRCCnt_1,$putinv);
			}
			foreach my $putinv (keys %$fc_fruHistoryFactorySerialNum){
				my $fc_fruHistoryIndex_1=$fc_fruHistoryIndex->{$putinv};
				my $fc_fruHistoryClass_1=$fc_fruHistoryClass->{$putinv};
				my $fc_fruHistoryObjectNum_1=$fc_fruHistoryObjectNum->{$putinv};
				my $fc_fruHistoryEvent_1=$fc_fruHistoryEvent->{$putinv};
				my $fc_fruHistoryTime_1=$fc_fruHistoryTime->{$putinv};
				my $fc_fruHistoryFactoryPartNum_1=$fc_fruHistoryFactoryPartNum->{$putinv};
				my $fc_fruHistoryFactorySerialNum_1=$fc_fruHistoryFactorySerialNum->{$putinv};
				$fruhistorytable_sth->execute($deviceid,$scantime,$fc_fruHistoryIndex_1,$fc_fruHistoryClass_1,$fc_fruHistoryObjectNum_1,$fc_fruHistoryEvent_1,$fc_fruHistoryTime_1,$fc_fruHistoryFactoryPartNum_1,$fc_fruHistoryFactorySerialNum_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swSensorInfo){
				my $fc_swSensorIndex_1=$fc_swSensorIndex->{$putinv};
				my $fc_swSensorType_1=$fc_swSensorType->{$putinv};
				my $fc_swSensorStatus_1=$fc_swSensorStatus->{$putinv};
				my $fc_swSensorValue_1=$fc_swSensorValue->{$putinv};
				my $fc_swSensorInfo_1=$fc_swSensorInfo->{$putinv};
				$swsensortable_sth->execute($deviceid,$scantime,$fc_swSensorIndex_1,$fc_swSensorType_1,$fc_swSensorStatus_1,$fc_swSensorValue_1,$fc_swSensorInfo_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swTrunkGrpRx){
				my $fc_swTrunkGrpNumber_1=$fc_swTrunkGrpNumber->{$putinv};
				my $fc_swTrunkGrpMaster_1=$fc_swTrunkGrpMaster->{$putinv};
				my $fc_swTrunkGrpTx_1=$fc_swTrunkGrpTx->{$putinv};
				my $fc_swTrunkGrpRx_1=$fc_swTrunkGrpRx->{$putinv};
				$swtrunkgrptable_sth->execute($deviceid,$scantime,$fc_swTrunkGrpNumber_1,$fc_swTrunkGrpMaster_1,$fc_swTrunkGrpTx_1,$fc_swTrunkGrpRx_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swNsHardAddr){
				my $fc_swNsEntryIndex_1=$fc_swNsEntryIndex->{$putinv};
				my $fc_swNsPortID_1=$fc_swNsPortID->{$putinv};
				my $fc_swNsPortType_1=$fc_swNsPortType->{$putinv};
				my $fc_swNsPortName_1=$fc_swNsPortName->{$putinv};
				my $fc_swNsPortSymb_1=$fc_swNsPortSymb->{$putinv};
				my $fc_swNsNodeName_1=$fc_swNsNodeName->{$putinv};
				my $fc_swNsNodeSymb_1=$fc_swNsNodeSymb->{$putinv};
				my $fc_swNsIPA_1=$fc_swNsIPA->{$putinv};
				my $fc_swNsIpAddress_1=$fc_swNsIpAddress->{$putinv};
				my $fc_swNsCos_1=$fc_swNsCos->{$putinv};
				my $fc_swNsFc4_1=$fc_swNsFc4->{$putinv};
				my $fc_swNsIpNxPort_1=$fc_swNsIpNxPort->{$putinv};
				my $fc_swNsWwn_1=$fc_swNsWwn->{$putinv};
				my $fc_swNsHardAddr_1=$fc_swNsHardAddr->{$putinv};
				$swnslocaltable_sth->execute($deviceid,$scantime,$fc_swNsEntryIndex_1,$fc_swNsPortID_1,$fc_swNsPortType_1,$fc_swNsPortName_1,$fc_swNsPortSymb_1,$fc_swNsNodeName_1,$fc_swNsNodeSymb_1,$fc_swNsIPA_1,$fc_swNsIpAddress_1,$fc_swNsCos_1,$fc_swNsFc4_1,$fc_swNsIpNxPort_1,$fc_swNsWwn_1,$fc_swNsHardAddr_1,$putinv);
			}
			foreach my $putinv (keys %$fc_swEventDescr){
				my $fc_swEventIndex_1=$fc_swEventIndex->{$putinv};
				my $fc_swEventTimeInfo_1=$fc_swEventTimeInfo->{$putinv};
				my $fc_swEventLevel_1=$fc_swEventLevel->{$putinv};
				my $fc_swEventRepeatCount_1=$fc_swEventRepeatCount->{$putinv};
				my $fc_swEventDescr_1=$fc_swEventDescr->{$putinv};
				$sweventtable_sth->execute($deviceid,$scantime,$fc_swEventIndex_1,$fc_swEventTimeInfo_1,$fc_swEventLevel_1,$fc_swEventRepeatCount_1,$fc_swEventDescr_1,$putinv);
			}
		}
	}; if ($@) {print "Error with Fibre Channel Inventory: $@\n";}
}

##
# utility subs
##

sub out {
	my ($str) = @_;
	print "$0: $deviceid ($target): $str\n";
}

sub dbg {
	my ($str) = @_;
	out($str) if ($debugging);
}

##
# the following subs are not called here, but I didn't want to delete them
##

sub GetSysDescription {
	eval {
		my $sth500 = $mysql->prepare_cached("INSERT INTO snmpsysinfo (deviceid,sysdescription,sysuptime,syscontact,sysname,syslocation,sysservices,sysoid) values (?,?,?,?,?,?,?,?)");
		my $snmpsysdescription = $info->description();
		my $snmpsysuptime = $info->uptime();
		my $snmpsyscontact = $info->contact();
		my $snmpsyslocation = $info->location();
		my $snmpsyslayers = $info->layers();
		my $snmpsysname = $info->name();
		my $sysoid = $info->id();
		$sth500->execute($deviceid,$snmpsysdescription,$snmpsysuptime,$snmpsyscontact,$snmpsysname,$snmpsyslocation,$snmpsysservices,$sysoid);
	}; if ($@) {
		out("failed to pull snmpsysinfo: $@");
	}
}

sub GetInterfaces {
	eval {
		my $sth = $mysql->prepare_cached("INSERT INTO interfaces (deviceid,name,description,type,speed,intindex,mac,adminstatus,operstatus) VALUES (?,?,?,?,?,?,?,?,?)");
		foreach my $instance (keys %$intindex) {
			my $iname = $name->{$instance};
			my $iintindex = $intindex->{$instance};
			my $idescription = $description->{$instance};
			my $itype = $type->{$instance};
			my $ispeed = $speed->{$instance};
			my $imac = $mac->{$instance};
			my $ioperstatus = $operstatus->{$instance};
			my $iadminstatus = $adminstatus->{$instance};
			$sth->execute($deviceid,$iname,$idescription,$itype,$ispeed,$iintindex,$imac,$iadminstatus,$ioperstatus);
		}
		$sth->finish();
	}; if ($@) {
		out("failed to pull interfaces: $@");
	}
}

sub GetRoutes {
	eval {
		my $sth15 = $mysql->prepare_cached("INSERT INTO iproutes (deviceid,ipRouteDest,ipRouteIfIndex,ipRouteMetric1,ipRouteMetric2,ipRouteMetric3,ipRouteMetric4,ipRouteNextHop,ipRouteType,ipRouteProto,ipRouteAge,ipRouteMask,ipRouteMetric5) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		foreach my $rrid (keys %$ipr_dest) {
			my $route_dest = $ipr_dest->{$rrid};
			my $route_int = $ipr_ifindex->{$rrid};
			my $route_1 = $ipr_1->{$rrid};
			my $route_2 = $ipr_2->{$rrid};
			my $route_3 = $ipr_3->{$rrid};
			my $route_4 = $ipr_4->{$rrid};
			my $route_5 = $ipr_5->{$rrid};
			my $route_nh = $ipr_nexthop->{$rrid};
			my $route_type = $ipr_type->{$rrid};
			my $route_proto = $ipr_proto->{$rrid};
			my $route_age = $ipr_age->{$rrid};
			my $route_mask = $ipr_mask->{$rrid};
			$sth15->execute($deviceid,$route_dest,$route_int,$route_1,$route_2,$route_3,$route_4,$route_nh,$route_type,$route_proto,$route_age,$route_mask,$route_5);
		}
		$sth15->finish();
	}; if ($@) {
		out("failed to pull routes: $@");
	}
}

sub GetEntity {
	eval {
		my $sth4 = $mysql->prepare_cached("INSERT INTO deviceentity (deviceid,class,description,fwver,hwver,map_id,model,name,parent,serial,swver,type,physindex,manufacturer) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $e_class = $info->e_class();
		my $e_description = $info->e_descr();
		my $e_fwver = $info->e_fwver();
		my $e_hwver = $info->e_hwver();
		my $e_map_id = $info->e_pos();
		my $e_model = $info->e_model();
		my $e_name = $info->e_name();
		my $e_parent = $info->e_parent();
		my $e_serial = $info->e_serial();
		my $e_swver = $info->e_swver();
		my $e_type = $info->e_type();
		my $e_vendor = $info->e_vendor();
		my $e_index = $info->e_index();
		foreach my $indices (keys %$e_class) {
			my $cl = $e_class->{$indices};
			my $des = $e_description->{$indices};
			my $fw = $e_fwver->{$indices};
			my $hw = $e_hwver->{$indices};
			my $map = $e_map_id->{indices}; #filling this with Position now - JL 12/09
			    my $mo = $e_model->{$indices};
			my $na = $e_name->{$indices};
			my $pa = $e_parent->{$indices};
			my $sw = $e_swver->{$indices};
			my $ty = $e_type->{$indices};
			my $ser = $e_serial->{$indices};
			my $indx = $e_index->{$indices};
			my $vend = $e_vendor->{$indices};
			$sth4->execute($deviceid,$cl,$des,$fw,$hw,$map,$mo,$na,$pa,$ser,$sw,$ty,$indices,$vend);
		}
		$sth4->finish();
	}; if ($@) {
		out("failed to pull deviceentity: $@");
	}
}

sub GatherIPTables {
	eval {
		$sth7 = $mysql->prepare_cached("INSERT INTO iptables (deviceid,ip,netmask,intindex) VALUES (?,?,?,?)");
		my $ipindex    = $info->ip_index();
		my $iptable    = $info->ip_table();
		my $ipnetmask  = $info->ip_netmask();
		foreach $x (keys %$ipnetmask){
			my $ipintindex = $ipindex->{$x};
			my $ipnetmaskvalue = $ipnetmask->{$x};
			$sth7->execute($deviceid, $x, $ipnetmaskvalue,$ipintindex);
		}
		$sth7->finish();
	}; if ($@) {
		out("failed to pull iptables: $@");
	}
}

