#!/usr/bin/perl 
#
##
use RISC::riscUtility;
use RISC::riscSNMP;
use RISC::riscCreds;
use Data::Dumper;
use lib 'lib';
$|++;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} = 1;

#my $mysql2 = riscUtility::getDBH('risc_discovery',1);
#$mysql2->{mysql_auto_reconnect} = 1;
#	
##Get Devices
#my $getcred;
#if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
#	$getcred = $mysql2->prepare_cached("select * from credentials where credid=? limit 1");
#} else {
#	$getcred = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
#											cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
#											cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
#											cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
#											port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
#											scantime,eu,ap,removed
#										from credentials where credid = ? limit 1");
#}
#$deviceid=shift;
#$winmachine = shift;
#print "$deviceid\n";
#my $credid=shift;
#$getcred->execute($credid);
#$credential = $getcred->fetchrow_hashref();
#getSNMP($credential,$winmachine);

my $deviceid	= shift;
my $target	= shift;
my $credid	= shift;

my $credobj = riscCreds->new();
my $cred = $credobj->getSNMP($credid);
unless ($cred) {
	out("failed to get SNMP credential: $credobj->{'error'}");
	exit(1);
}
$credobj->disconnect();

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

dbg("collecting data");
getTPInfo();

dbg("finish");
$mysql->disconnect();
exit(0);


sub getTPInfo {
	eval {
		my $tpuserauthfailhistory_sth = $mysql->prepare_cached("insert into tpuserauthfailhistory(deviceid,scantime,CiscoTP_ctpSysUserAuthFailHistoryIndex,CiscoTP_ctpSysUserAuthFailSourceAddrType,CiscoTP_ctpSysUserAuthFailSourceAddr,CiscoTP_ctpSysUserAuthFailSourcePort,CiscoTP_ctpSysUserAuthFailUserName,CiscoTP_ctpSysUserAuthFailAccessProtocol,CiscoTP_ctpSysUserAuthFailTimeStamp,snmpindex) values (?,?,?,?,?,?,?,?,?,?)");
		my $tphdmiperipheralstatus_sth = $mysql->prepare_cached("insert into tphdmiperipheralstatus(deviceid,scantime,CiscoTP_ctpHDMIPeripheralIndex,CiscoTP_ctpHDMIPeripheralCableStatus,CiscoTP_ctpHDMIPeripheralPowerStatus,snmpindex) values (?,?,?,?,?,?)");
		my $tpperipheralattribute_sth = $mysql->prepare_cached("insert into tpperipheralattribute(deviceid,scantime,CiscoTP_ctpPeripheralAttributeIndex,CiscoTP_ctpPeripheralAttributeDescr,CiscoTP_ctpPeripheralAttributeValue,snmpindex) values (?,?,?,?,?,?)");
		my $tprtpstreamsource_sth = $mysql->prepare_cached("insert into tprtpstreamsource(deviceid,scantime,CiscoTP_ctpcStreamSource,CiscoTP_ctpcTxActive,CiscoTP_ctpcTxTotalBytes,CiscoTP_ctpcTxTotalPackets,CiscoTP_ctpcTxLostPackets,CiscoTP_ctpcTxPeriodLostPackets,CiscoTP_ctpcTxCallLostPackets,CiscoTP_ctpcTxIDRPackets,CiscoTP_ctpcTxShapingWindow,CiscoTP_ctpcRxActive,CiscoTP_ctpcRxTotalBytes,CiscoTP_ctpcRxTotalPackets,CiscoTP_ctpcRxLostPackets,CiscoTP_ctpcRxPeriodLostPackets,CiscoTP_ctpcRxCallLostPackets,CiscoTP_ctpcRxOutOfOrderPackets,CiscoTP_ctpcRxDuplicatePackets,CiscoTP_ctpcRxLatePackets,CiscoTP_ctpcRxIDRPackets,CiscoTP_ctpcRxShapingWindow,CiscoTP_ctpcRxCallAuthFailure,CiscoTP_ctpcAvgPeriodJitter,CiscoTP_ctpcAvgCallJitter,CiscoTP_ctpcMaxPeriodJitter,CiscoTP_ctpcMaxCallJitter,CiscoTP_ctpcMaxCallJitterRecTime,snmpindex) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $tprs232peripheralstatus_sth = $mysql->prepare_cached("insert into tprs232peripheralstatus(deviceid,scantime,CiscoTP_ctpRS232PeripheralIndex,CiscoTP_ctpRS232PortIndex,CiscoTP_ctpRS232PeripheralConnStatus,snmpindex) values (?,?,?,?,?,?)");
		my $tpeventhistory_sth = $mysql->prepare_cached("insert into tpeventhistory(deviceid,scantime,CiscoTP_ctpcStatEventHistoryIndex,CiscoTP_ctpcStatEventMonObjectInst,CiscoTP_ctpcStatEventCrossedValue,CiscoTP_ctpcStatEventCrossedType,CiscoTP_ctpcStatEventTimeStamp,snmpindex) values (?,?,?,?,?,?,?,?)");
		my $tpperipheralerrorhistory_sth = $mysql->prepare_cached("insert into tpperipheralerrorhistory(deviceid,scantime,CiscoTP_ctpPeripheralErrorHistoryIndex,CiscoTP_ctpPeripheralErrorIndex,CiscoTP_ctpPeripheralErrorStatus,CiscoTP_ctpPeripheralErrorTimeStamp,snmpindex) values (?,?,?,?,?,?,?)");
		my $tpcallglobal_sth = $mysql->prepare_cached("insert into tpcallglobal(deviceid,scantime,CiscoTP_ctpcStatNotifyEnable,CiscoTP_ctpcMgmtSysConnNotifyEnable,CiscoTP_ctpcLocalAddrType,CiscoTP_ctpcLocalAddr,CiscoTP_ctpcMode,CiscoTP_ctpcStatOverallCalls,CiscoTP_ctpcStatOverallCallTime,CiscoTP_ctpcStatTotalCalls,CiscoTP_ctpcStatTotalCallTime,CiscoTP_ctpcSamplePeriod,snmpindex) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $tprtpstreamtype_sth = $mysql->prepare_cached("insert into tprtpstreamtype(deviceid,scantime,CiscoTP_ctpcStreamType,CiscoTP_ctpcAvgPeriodLatency,CiscoTP_ctpcAvgCallLatency,CiscoTP_ctpcMaxPeriodLatency,CiscoTP_ctpcMaxCallLatency,CiscoTP_ctpcMaxCallLatencyRecTime,snmpindex) values (?,?,?,?,?,?,?,?,?)");
		my $tplocaldirnum_sth = $mysql->prepare_cached("insert into tplocaldirnum(deviceid,scantime,CiscoTP_ctpcLocalDirNumIndex,CiscoTP_ctpcLocalDirNum,snmpindex) values (?,?,?,?,?)");
		my $tpmanagementsystem_sth = $mysql->prepare_cached("insert into tpmanagementsystem(deviceid,scantime,CiscoTP_ctpcMgmtSysIndex,CiscoTP_ctpcMgmtSysAddrType,CiscoTP_ctpcMgmtSysAddr,snmpindex) values (?,?,?,?,?,?)");
		my $tpcalldetail_sth = $mysql->prepare_cached("insert into tpcalldetail(deviceid,scantime,CiscoTP_ctpcIndex,CiscoTP_ctpcDirection,CiscoTP_ctpcState,CiscoTP_ctpcInitialBitRate,CiscoTP_ctpcLatestBitRate,CiscoTP_ctpcRowStatus,CiscoTP_ctpcRemoteDirNum,CiscoTP_ctpcLocalSIPCallId,CiscoTP_ctpcTxDestAddrType,CiscoTP_ctpcTxDestAddr,CiscoTP_ctpcStartDateAndTime,CiscoTP_ctpcDuration,CiscoTP_ctpcType,CiscoTP_ctpcSecurity,snmpindex) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my $tpdviperipheralstatus_sth = $mysql->prepare_cached("insert into tpdviperipheralstatus(deviceid,scantime,CiscoTP_ctpDVIPeripheralIndex,CiscoTP_ctpDVIPeripheralCableStatus,snmpindex) values (?,?,?,?,?)");
		my $tpperipheralstatus_sth = $mysql->prepare_cached("insert into tpperipheralstatus(deviceid,scantime,CiscoTP_ctpPeripheralIndex,CiscoTP_ctpPeripheralDescription,CiscoTP_ctpPeripheralStatus,snmpindex) values (?,?,?,?,?,?)");
		my $tpcallmonitor_sth = $mysql->prepare_cached("insert into tpcallmonitor(deviceid,scantime,CiscoTP_ctpcStatMonitoredType,CiscoTP_ctpcStatMonitoredStreamType,CiscoTP_ctpcStatMonitoredUnit,CiscoTP_ctpcStatRisingThreshold,CiscoTP_ctpcStatFallingThreshold,CiscoTP_ctpcStatStartupAlarm,CiscoTP_ctpcStatMonitoredStatus,snmpindex) values (?,?,?,?,?,?,?,?,?,?)");
		my $tpethernetperipheralstatus_sth = $mysql->prepare_cached("insert into tpethernetperipheralstatus(deviceid,scantime,CiscoTP_ctpEtherPeripheralIndex,CiscoTP_ctpEtherPeripheralIfIndex,CiscoTP_ctpEtherPeripheralAddrType,CiscoTP_ctpEtherPeripheralAddr,CiscoTP_ctpEtherPeripheralStatus,snmpindex) values (?,?,?,?,?,?,?,?)");

		##Collect information for tabletpuserauthfailhistory
		my $CiscoTP_ctpSysUserAuthFailHistoryIndex=$tpinfo->CiscoTP_ctpSysUserAuthFailHistoryIndex();
		my $CiscoTP_ctpSysUserAuthFailSourceAddrType=$tpinfo->CiscoTP_ctpSysUserAuthFailSourceAddrType();
		my $CiscoTP_ctpSysUserAuthFailSourceAddr=$tpinfo->CiscoTP_ctpSysUserAuthFailSourceAddr();
		my $CiscoTP_ctpSysUserAuthFailSourcePort=$tpinfo->CiscoTP_ctpSysUserAuthFailSourcePort();
		my $CiscoTP_ctpSysUserAuthFailUserName=$tpinfo->CiscoTP_ctpSysUserAuthFailUserName();
		my $CiscoTP_ctpSysUserAuthFailAccessProtocol=$tpinfo->CiscoTP_ctpSysUserAuthFailAccessProtocol();
		my $CiscoTP_ctpSysUserAuthFailTimeStamp=$tpinfo->CiscoTP_ctpSysUserAuthFailTimeStamp();

		##Collect information for tabletphdmiperipheralstatus
		my $CiscoTP_ctpHDMIPeripheralIndex=$tpinfo->CiscoTP_ctpHDMIPeripheralIndex();
		my $CiscoTP_ctpHDMIPeripheralCableStatus=$tpinfo->CiscoTP_ctpHDMIPeripheralCableStatus();
		my $CiscoTP_ctpHDMIPeripheralPowerStatus=$tpinfo->CiscoTP_ctpHDMIPeripheralPowerStatus();

		##Collect information for tabletpperipheralattribute
		my $CiscoTP_ctpPeripheralAttributeIndex=$tpinfo->CiscoTP_ctpPeripheralAttributeIndex();
		my $CiscoTP_ctpPeripheralAttributeDescr=$tpinfo->CiscoTP_ctpPeripheralAttributeDescr();
		my $CiscoTP_ctpPeripheralAttributeValue=$tpinfo->CiscoTP_ctpPeripheralAttributeValue();

		##Collect information for tabletprtpstreamsource
		my $CiscoTP_ctpcStreamSource=$tpinfo->CiscoTP_ctpcStreamSource();
		my $CiscoTP_ctpcTxActive=$tpinfo->CiscoTP_ctpcTxActive();
		my $CiscoTP_ctpcTxTotalBytes=$tpinfo->CiscoTP_ctpcTxTotalBytes();
		my $CiscoTP_ctpcTxTotalPackets=$tpinfo->CiscoTP_ctpcTxTotalPackets();
		my $CiscoTP_ctpcTxLostPackets=$tpinfo->CiscoTP_ctpcTxLostPackets();
		my $CiscoTP_ctpcTxPeriodLostPackets=$tpinfo->CiscoTP_ctpcTxPeriodLostPackets();
		my $CiscoTP_ctpcTxCallLostPackets=$tpinfo->CiscoTP_ctpcTxCallLostPackets();
		my $CiscoTP_ctpcTxIDRPackets=$tpinfo->CiscoTP_ctpcTxIDRPackets();
		my $CiscoTP_ctpcTxShapingWindow=$tpinfo->CiscoTP_ctpcTxShapingWindow();
		my $CiscoTP_ctpcRxActive=$tpinfo->CiscoTP_ctpcRxActive();
		my $CiscoTP_ctpcRxTotalBytes=$tpinfo->CiscoTP_ctpcRxTotalBytes();
		my $CiscoTP_ctpcRxTotalPackets=$tpinfo->CiscoTP_ctpcRxTotalPackets();
		my $CiscoTP_ctpcRxLostPackets=$tpinfo->CiscoTP_ctpcRxLostPackets();
		my $CiscoTP_ctpcRxPeriodLostPackets=$tpinfo->CiscoTP_ctpcRxPeriodLostPackets();
		my $CiscoTP_ctpcRxCallLostPackets=$tpinfo->CiscoTP_ctpcRxCallLostPackets();
		my $CiscoTP_ctpcRxOutOfOrderPackets=$tpinfo->CiscoTP_ctpcRxOutOfOrderPackets();
		my $CiscoTP_ctpcRxDuplicatePackets=$tpinfo->CiscoTP_ctpcRxDuplicatePackets();
		my $CiscoTP_ctpcRxLatePackets=$tpinfo->CiscoTP_ctpcRxLatePackets();
		my $CiscoTP_ctpcRxIDRPackets=$tpinfo->CiscoTP_ctpcRxIDRPackets();
		my $CiscoTP_ctpcRxShapingWindow=$tpinfo->CiscoTP_ctpcRxShapingWindow();
		my $CiscoTP_ctpcRxCallAuthFailure=$tpinfo->CiscoTP_ctpcRxCallAuthFailure();
		my $CiscoTP_ctpcAvgPeriodJitter=$tpinfo->CiscoTP_ctpcAvgPeriodJitter();
		my $CiscoTP_ctpcAvgCallJitter=$tpinfo->CiscoTP_ctpcAvgCallJitter();
		my $CiscoTP_ctpcMaxPeriodJitter=$tpinfo->CiscoTP_ctpcMaxPeriodJitter();
		my $CiscoTP_ctpcMaxCallJitter=$tpinfo->CiscoTP_ctpcMaxCallJitter();
		my $CiscoTP_ctpcMaxCallJitterRecTime=$tpinfo->CiscoTP_ctpcMaxCallJitterRecTime();

		##Collect information for tabletprs232peripheralstatus
		my $CiscoTP_ctpRS232PeripheralIndex=$tpinfo->CiscoTP_ctpRS232PeripheralIndex();
		my $CiscoTP_ctpRS232PortIndex=$tpinfo->CiscoTP_ctpRS232PortIndex();
		my $CiscoTP_ctpRS232PeripheralConnStatus=$tpinfo->CiscoTP_ctpRS232PeripheralConnStatus();

		##Collect information for tabletpeventhistory
		my $CiscoTP_ctpcStatEventHistoryIndex=$tpinfo->CiscoTP_ctpcStatEventHistoryIndex();
		my $CiscoTP_ctpcStatEventMonObjectInst=$tpinfo->CiscoTP_ctpcStatEventMonObjectInst();
		my $CiscoTP_ctpcStatEventCrossedValue=$tpinfo->CiscoTP_ctpcStatEventCrossedValue();
		my $CiscoTP_ctpcStatEventCrossedType=$tpinfo->CiscoTP_ctpcStatEventCrossedType();
		my $CiscoTP_ctpcStatEventTimeStamp=$tpinfo->CiscoTP_ctpcStatEventTimeStamp();

		##Collect information for tabletpperipheralerrorhistory
		my $CiscoTP_ctpPeripheralErrorHistoryIndex=$tpinfo->CiscoTP_ctpPeripheralErrorHistoryIndex();
		my $CiscoTP_ctpPeripheralErrorIndex=$tpinfo->CiscoTP_ctpPeripheralErrorIndex();
		my $CiscoTP_ctpPeripheralErrorStatus=$tpinfo->CiscoTP_ctpPeripheralErrorStatus();
		my $CiscoTP_ctpPeripheralErrorTimeStamp=$tpinfo->CiscoTP_ctpPeripheralErrorTimeStamp();

		##Collect information for tabletpcallglobal
		my $CiscoTP_ctpcStatNotifyEnable=$tpinfo->CiscoTP_ctpcStatNotifyEnable();
		my $CiscoTP_ctpcMgmtSysConnNotifyEnable=$tpinfo->CiscoTP_ctpcMgmtSysConnNotifyEnable();
		my $CiscoTP_ctpcLocalAddrType=$tpinfo->CiscoTP_ctpcLocalAddrType();
		my $CiscoTP_ctpcLocalAddr=$tpinfo->CiscoTP_ctpcLocalAddr();
		my $CiscoTP_ctpcMode=$tpinfo->CiscoTP_ctpcMode();
		my $CiscoTP_ctpcStatOverallCalls=$tpinfo->CiscoTP_ctpcStatOverallCalls();
		my $CiscoTP_ctpcStatOverallCallTime=$tpinfo->CiscoTP_ctpcStatOverallCallTime();
		my $CiscoTP_ctpcStatTotalCalls=$tpinfo->CiscoTP_ctpcStatTotalCalls();
		my $CiscoTP_ctpcStatTotalCallTime=$tpinfo->CiscoTP_ctpcStatTotalCallTime();
		my $CiscoTP_ctpcSamplePeriod=$tpinfo->CiscoTP_ctpcSamplePeriod();

		##Collect information for tabletprtpstreamtype
		my $CiscoTP_ctpcStreamType=$tpinfo->CiscoTP_ctpcStreamType();
		my $CiscoTP_ctpcAvgPeriodLatency=$tpinfo->CiscoTP_ctpcAvgPeriodLatency();
		my $CiscoTP_ctpcAvgCallLatency=$tpinfo->CiscoTP_ctpcAvgCallLatency();
		my $CiscoTP_ctpcMaxPeriodLatency=$tpinfo->CiscoTP_ctpcMaxPeriodLatency();
		my $CiscoTP_ctpcMaxCallLatency=$tpinfo->CiscoTP_ctpcMaxCallLatency();
		my $CiscoTP_ctpcMaxCallLatencyRecTime=$tpinfo->CiscoTP_ctpcMaxCallLatencyRecTime();

		##Collect information for tabletplocaldirnum
		my $CiscoTP_ctpcLocalDirNumIndex=$tpinfo->CiscoTP_ctpcLocalDirNumIndex();
		my $CiscoTP_ctpcLocalDirNum=$tpinfo->CiscoTP_ctpcLocalDirNum();

		##Collect information for tabletpmanagementsystem
		my $CiscoTP_ctpcMgmtSysIndex=$tpinfo->CiscoTP_ctpcMgmtSysIndex();
		my $CiscoTP_ctpcMgmtSysAddrType=$tpinfo->CiscoTP_ctpcMgmtSysAddrType();
		my $CiscoTP_ctpcMgmtSysAddr=$tpinfo->CiscoTP_ctpcMgmtSysAddr();

		##Collect information for tabletpcalldetail
		my $CiscoTP_ctpcIndex=$tpinfo->CiscoTP_ctpcIndex();
		my $CiscoTP_ctpcDirection=$tpinfo->CiscoTP_ctpcDirection();
		my $CiscoTP_ctpcState=$tpinfo->CiscoTP_ctpcState();
		my $CiscoTP_ctpcInitialBitRate=$tpinfo->CiscoTP_ctpcInitialBitRate();
		my $CiscoTP_ctpcLatestBitRate=$tpinfo->CiscoTP_ctpcLatestBitRate();
		my $CiscoTP_ctpcRowStatus=$tpinfo->CiscoTP_ctpcRowStatus();
		my $CiscoTP_ctpcRemoteDirNum=$tpinfo->CiscoTP_ctpcRemoteDirNum();
		my $CiscoTP_ctpcLocalSIPCallId=$tpinfo->CiscoTP_ctpcLocalSIPCallId();
		my $CiscoTP_ctpcTxDestAddrType=$tpinfo->CiscoTP_ctpcTxDestAddrType();
		my $CiscoTP_ctpcTxDestAddr=$tpinfo->CiscoTP_ctpcTxDestAddr();
		my $CiscoTP_ctpcStartDateAndTime=$tpinfo->CiscoTP_ctpcStartDateAndTime();
		my $CiscoTP_ctpcDuration=$tpinfo->CiscoTP_ctpcDuration();
		my $CiscoTP_ctpcType=$tpinfo->CiscoTP_ctpcType();
		my $CiscoTP_ctpcSecurity=$tpinfo->CiscoTP_ctpcSecurity();

		##Collect information for tabletpdviperipheralstatus
		my $CiscoTP_ctpDVIPeripheralIndex=$tpinfo->CiscoTP_ctpDVIPeripheralIndex();
		my $CiscoTP_ctpDVIPeripheralCableStatus=$tpinfo->CiscoTP_ctpDVIPeripheralCableStatus();

		##Collect information for tabletpperipheralstatus
		my $CiscoTP_ctpPeripheralIndex=$tpinfo->CiscoTP_ctpPeripheralIndex();
		my $CiscoTP_ctpPeripheralDescription=$tpinfo->CiscoTP_ctpPeripheralDescription();
		my $CiscoTP_ctpPeripheralStatus=$tpinfo->CiscoTP_ctpPeripheralStatus();

		##Collect information for tabletpcallmonitor
		my $CiscoTP_ctpcStatMonitoredType=$tpinfo->CiscoTP_ctpcStatMonitoredType();
		my $CiscoTP_ctpcStatMonitoredStreamType=$tpinfo->CiscoTP_ctpcStatMonitoredStreamType();
		my $CiscoTP_ctpcStatMonitoredUnit=$tpinfo->CiscoTP_ctpcStatMonitoredUnit();
		my $CiscoTP_ctpcStatRisingThreshold=$tpinfo->CiscoTP_ctpcStatRisingThreshold();
		my $CiscoTP_ctpcStatFallingThreshold=$tpinfo->CiscoTP_ctpcStatFallingThreshold();
		my $CiscoTP_ctpcStatStartupAlarm=$tpinfo->CiscoTP_ctpcStatStartupAlarm();
		my $CiscoTP_ctpcStatMonitoredStatus=$tpinfo->CiscoTP_ctpcStatMonitoredStatus();

		##Collect information for tabletpethernetperipheralstatus
		my $CiscoTP_ctpEtherPeripheralIndex=$tpinfo->CiscoTP_ctpEtherPeripheralIndex();
		my $CiscoTP_ctpEtherPeripheralIfIndex=$tpinfo->CiscoTP_ctpEtherPeripheralIfIndex();
		my $CiscoTP_ctpEtherPeripheralAddrType=$tpinfo->CiscoTP_ctpEtherPeripheralAddrType();
		my $CiscoTP_ctpEtherPeripheralAddr=$tpinfo->CiscoTP_ctpEtherPeripheralAddr();
		my $CiscoTP_ctpEtherPeripheralStatus=$tpinfo->CiscoTP_ctpEtherPeripheralStatus();

		foreach my $putinv (keys %$CiscoTP_ctpSysUserAuthFailTimeStamp){
			my $CiscoTP_ctpSysUserAuthFailHistoryIndex_1=$CiscoTP_ctpSysUserAuthFailHistoryIndex->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailSourceAddrType_1=$CiscoTP_ctpSysUserAuthFailSourceAddrType->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailSourceAddr_1=$CiscoTP_ctpSysUserAuthFailSourceAddr->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailSourcePort_1=$CiscoTP_ctpSysUserAuthFailSourcePort->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailUserName_1=$CiscoTP_ctpSysUserAuthFailUserName->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailAccessProtocol_1=$CiscoTP_ctpSysUserAuthFailAccessProtocol->{$putinv};
			my $CiscoTP_ctpSysUserAuthFailTimeStamp_1=$CiscoTP_ctpSysUserAuthFailTimeStamp->{$putinv};
			$tpuserauthfailhistory_sth->execute($deviceid,$scantime,$CiscoTP_ctpSysUserAuthFailHistoryIndex_1,$CiscoTP_ctpSysUserAuthFailSourceAddrType_1,$CiscoTP_ctpSysUserAuthFailSourceAddr_1,$CiscoTP_ctpSysUserAuthFailSourcePort_1,$CiscoTP_ctpSysUserAuthFailUserName_1,$CiscoTP_ctpSysUserAuthFailAccessProtocol_1,$CiscoTP_ctpSysUserAuthFailTimeStamp_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpHDMIPeripheralPowerStatus){
			my $CiscoTP_ctpHDMIPeripheralIndex_1=$CiscoTP_ctpHDMIPeripheralIndex->{$putinv};
			my $CiscoTP_ctpHDMIPeripheralCableStatus_1=$CiscoTP_ctpHDMIPeripheralCableStatus->{$putinv};
			my $CiscoTP_ctpHDMIPeripheralPowerStatus_1=$CiscoTP_ctpHDMIPeripheralPowerStatus->{$putinv};
			$tphdmiperipheralstatus_sth->execute($deviceid,$scantime,$CiscoTP_ctpHDMIPeripheralIndex_1,$CiscoTP_ctpHDMIPeripheralCableStatus_1,$CiscoTP_ctpHDMIPeripheralPowerStatus_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpPeripheralAttributeValue){
			my $CiscoTP_ctpPeripheralAttributeIndex_1=$CiscoTP_ctpPeripheralAttributeIndex->{$putinv};
			my $CiscoTP_ctpPeripheralAttributeDescr_1=$CiscoTP_ctpPeripheralAttributeDescr->{$putinv};
			my $CiscoTP_ctpPeripheralAttributeValue_1=$CiscoTP_ctpPeripheralAttributeValue->{$putinv};
			$tpperipheralattribute_sth->execute($deviceid,$scantime,$CiscoTP_ctpPeripheralAttributeIndex_1,$CiscoTP_ctpPeripheralAttributeDescr_1,$CiscoTP_ctpPeripheralAttributeValue_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcMaxCallJitterRecTime){
			my $CiscoTP_ctpcStreamSource_1=$CiscoTP_ctpcStreamSource->{$putinv};
			my $CiscoTP_ctpcTxActive_1=$CiscoTP_ctpcTxActive->{$putinv};
			my $CiscoTP_ctpcTxTotalBytes_1=$CiscoTP_ctpcTxTotalBytes->{$putinv};
			my $CiscoTP_ctpcTxTotalPackets_1=$CiscoTP_ctpcTxTotalPackets->{$putinv};
			my $CiscoTP_ctpcTxLostPackets_1=$CiscoTP_ctpcTxLostPackets->{$putinv};
			my $CiscoTP_ctpcTxPeriodLostPackets_1=$CiscoTP_ctpcTxPeriodLostPackets->{$putinv};
			my $CiscoTP_ctpcTxCallLostPackets_1=$CiscoTP_ctpcTxCallLostPackets->{$putinv};
			my $CiscoTP_ctpcTxIDRPackets_1=$CiscoTP_ctpcTxIDRPackets->{$putinv};
			my $CiscoTP_ctpcTxShapingWindow_1=$CiscoTP_ctpcTxShapingWindow->{$putinv};
			my $CiscoTP_ctpcRxActive_1=$CiscoTP_ctpcRxActive->{$putinv};
			my $CiscoTP_ctpcRxTotalBytes_1=$CiscoTP_ctpcRxTotalBytes->{$putinv};
			my $CiscoTP_ctpcRxTotalPackets_1=$CiscoTP_ctpcRxTotalPackets->{$putinv};
			my $CiscoTP_ctpcRxLostPackets_1=$CiscoTP_ctpcRxLostPackets->{$putinv};
			my $CiscoTP_ctpcRxPeriodLostPackets_1=$CiscoTP_ctpcRxPeriodLostPackets->{$putinv};
			my $CiscoTP_ctpcRxCallLostPackets_1=$CiscoTP_ctpcRxCallLostPackets->{$putinv};
			my $CiscoTP_ctpcRxOutOfOrderPackets_1=$CiscoTP_ctpcRxOutOfOrderPackets->{$putinv};
			my $CiscoTP_ctpcRxDuplicatePackets_1=$CiscoTP_ctpcRxDuplicatePackets->{$putinv};
			my $CiscoTP_ctpcRxLatePackets_1=$CiscoTP_ctpcRxLatePackets->{$putinv};
			my $CiscoTP_ctpcRxIDRPackets_1=$CiscoTP_ctpcRxIDRPackets->{$putinv};
			my $CiscoTP_ctpcRxShapingWindow_1=$CiscoTP_ctpcRxShapingWindow->{$putinv};
			my $CiscoTP_ctpcRxCallAuthFailure_1=$CiscoTP_ctpcRxCallAuthFailure->{$putinv};
			my $CiscoTP_ctpcAvgPeriodJitter_1=$CiscoTP_ctpcAvgPeriodJitter->{$putinv};
			my $CiscoTP_ctpcAvgCallJitter_1=$CiscoTP_ctpcAvgCallJitter->{$putinv};
			my $CiscoTP_ctpcMaxPeriodJitter_1=$CiscoTP_ctpcMaxPeriodJitter->{$putinv};
			my $CiscoTP_ctpcMaxCallJitter_1=$CiscoTP_ctpcMaxCallJitter->{$putinv};
			my $CiscoTP_ctpcMaxCallJitterRecTime_1=$CiscoTP_ctpcMaxCallJitterRecTime->{$putinv};
			$tprtpstreamsource_sth->execute($deviceid,$scantime,$CiscoTP_ctpcStreamSource_1,$CiscoTP_ctpcTxActive_1,$CiscoTP_ctpcTxTotalBytes_1,$CiscoTP_ctpcTxTotalPackets_1,$CiscoTP_ctpcTxLostPackets_1,$CiscoTP_ctpcTxPeriodLostPackets_1,$CiscoTP_ctpcTxCallLostPackets_1,$CiscoTP_ctpcTxIDRPackets_1,$CiscoTP_ctpcTxShapingWindow_1,$CiscoTP_ctpcRxActive_1,$CiscoTP_ctpcRxTotalBytes_1,$CiscoTP_ctpcRxTotalPackets_1,$CiscoTP_ctpcRxLostPackets_1,$CiscoTP_ctpcRxPeriodLostPackets_1,$CiscoTP_ctpcRxCallLostPackets_1,$CiscoTP_ctpcRxOutOfOrderPackets_1,$CiscoTP_ctpcRxDuplicatePackets_1,$CiscoTP_ctpcRxLatePackets_1,$CiscoTP_ctpcRxIDRPackets_1,$CiscoTP_ctpcRxShapingWindow_1,$CiscoTP_ctpcRxCallAuthFailure_1,$CiscoTP_ctpcAvgPeriodJitter_1,$CiscoTP_ctpcAvgCallJitter_1,$CiscoTP_ctpcMaxPeriodJitter_1,$CiscoTP_ctpcMaxCallJitter_1,$CiscoTP_ctpcMaxCallJitterRecTime_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpRS232PeripheralConnStatus){
			my $CiscoTP_ctpRS232PeripheralIndex_1=$CiscoTP_ctpRS232PeripheralIndex->{$putinv};
			my $CiscoTP_ctpRS232PortIndex_1=$CiscoTP_ctpRS232PortIndex->{$putinv};
			my $CiscoTP_ctpRS232PeripheralConnStatus_1=$CiscoTP_ctpRS232PeripheralConnStatus->{$putinv};
			$tprs232peripheralstatus_sth->execute($deviceid,$scantime,$CiscoTP_ctpRS232PeripheralIndex_1,$CiscoTP_ctpRS232PortIndex_1,$CiscoTP_ctpRS232PeripheralConnStatus_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcStatEventTimeStamp){
			my $CiscoTP_ctpcStatEventHistoryIndex_1=$CiscoTP_ctpcStatEventHistoryIndex->{$putinv};
			my $CiscoTP_ctpcStatEventMonObjectInst_1=$CiscoTP_ctpcStatEventMonObjectInst->{$putinv};
			my $CiscoTP_ctpcStatEventCrossedValue_1=$CiscoTP_ctpcStatEventCrossedValue->{$putinv};
			my $CiscoTP_ctpcStatEventCrossedType_1=$CiscoTP_ctpcStatEventCrossedType->{$putinv};
			my $CiscoTP_ctpcStatEventTimeStamp_1=$CiscoTP_ctpcStatEventTimeStamp->{$putinv};
			$tpeventhistory_sth->execute($deviceid,$scantime,$CiscoTP_ctpcStatEventHistoryIndex_1,$CiscoTP_ctpcStatEventMonObjectInst_1,$CiscoTP_ctpcStatEventCrossedValue_1,$CiscoTP_ctpcStatEventCrossedType_1,$CiscoTP_ctpcStatEventTimeStamp_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpPeripheralErrorTimeStamp){
			my $CiscoTP_ctpPeripheralErrorHistoryIndex_1=$CiscoTP_ctpPeripheralErrorHistoryIndex->{$putinv};
			my $CiscoTP_ctpPeripheralErrorIndex_1=$CiscoTP_ctpPeripheralErrorIndex->{$putinv};
			my $CiscoTP_ctpPeripheralErrorStatus_1=$CiscoTP_ctpPeripheralErrorStatus->{$putinv};
			my $CiscoTP_ctpPeripheralErrorTimeStamp_1=$CiscoTP_ctpPeripheralErrorTimeStamp->{$putinv};
			$tpperipheralerrorhistory_sth->execute($deviceid,$scantime,$CiscoTP_ctpPeripheralErrorHistoryIndex_1,$CiscoTP_ctpPeripheralErrorIndex_1,$CiscoTP_ctpPeripheralErrorStatus_1,$CiscoTP_ctpPeripheralErrorTimeStamp_1,$putinv);
		}
		#Insert globals - no foreach loop here
		my $CiscoTP_ctpcStatNotifyEnable_1=$CiscoTP_ctpcStatNotifyEnable;
		my $CiscoTP_ctpcMgmtSysConnNotifyEnable_1=$CiscoTP_ctpcMgmtSysConnNotifyEnable;
		my $CiscoTP_ctpcLocalAddrType_1=$CiscoTP_ctpcLocalAddrType;
		my $CiscoTP_ctpcLocalAddr_1=$CiscoTP_ctpcLocalAddr;
		my $CiscoTP_ctpcMode_1=$CiscoTP_ctpcMode;
		my $CiscoTP_ctpcStatOverallCalls_1=$CiscoTP_ctpcStatOverallCalls;
		my $CiscoTP_ctpcStatOverallCallTime_1=$CiscoTP_ctpcStatOverallCallTime;
		my $CiscoTP_ctpcStatTotalCalls_1=$CiscoTP_ctpcStatTotalCalls;
		my $CiscoTP_ctpcStatTotalCallTime_1=$CiscoTP_ctpcStatTotalCallTime;
		my $CiscoTP_ctpcSamplePeriod_1=$CiscoTP_ctpcSamplePeriod;
		$tpcallglobal_sth->execute($deviceid,$scantime,$CiscoTP_ctpcStatNotifyEnable_1,$CiscoTP_ctpcMgmtSysConnNotifyEnable_1,$CiscoTP_ctpcLocalAddrType_1,$CiscoTP_ctpcLocalAddr_1,$CiscoTP_ctpcMode_1,$CiscoTP_ctpcStatOverallCalls_1,$CiscoTP_ctpcStatOverallCallTime_1,$CiscoTP_ctpcStatTotalCalls_1,$CiscoTP_ctpcStatTotalCallTime_1,$CiscoTP_ctpcSamplePeriod_1,$putinv);

		foreach my $putinv (keys %$CiscoTP_ctpcMaxCallLatencyRecTime){
			my $CiscoTP_ctpcStreamType_1=$CiscoTP_ctpcStreamType->{$putinv};
			my $CiscoTP_ctpcAvgPeriodLatency_1=$CiscoTP_ctpcAvgPeriodLatency->{$putinv};
			my $CiscoTP_ctpcAvgCallLatency_1=$CiscoTP_ctpcAvgCallLatency->{$putinv};
			my $CiscoTP_ctpcMaxPeriodLatency_1=$CiscoTP_ctpcMaxPeriodLatency->{$putinv};
			my $CiscoTP_ctpcMaxCallLatency_1=$CiscoTP_ctpcMaxCallLatency->{$putinv};
			my $CiscoTP_ctpcMaxCallLatencyRecTime_1=$CiscoTP_ctpcMaxCallLatencyRecTime->{$putinv};
			$tprtpstreamtype_sth->execute($deviceid,$scantime,$CiscoTP_ctpcStreamType_1,$CiscoTP_ctpcAvgPeriodLatency_1,$CiscoTP_ctpcAvgCallLatency_1,$CiscoTP_ctpcMaxPeriodLatency_1,$CiscoTP_ctpcMaxCallLatency_1,$CiscoTP_ctpcMaxCallLatencyRecTime_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcLocalDirNum){
			my $CiscoTP_ctpcLocalDirNumIndex_1=$CiscoTP_ctpcLocalDirNumIndex->{$putinv};
			my $CiscoTP_ctpcLocalDirNum_1=$CiscoTP_ctpcLocalDirNum->{$putinv};
			$tplocaldirnum_sth->execute($deviceid,$scantime,$CiscoTP_ctpcLocalDirNumIndex_1,$CiscoTP_ctpcLocalDirNum_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcMgmtSysAddr){
			my $CiscoTP_ctpcMgmtSysIndex_1=$CiscoTP_ctpcMgmtSysIndex->{$putinv};
			my $CiscoTP_ctpcMgmtSysAddrType_1=$CiscoTP_ctpcMgmtSysAddrType->{$putinv};
			my $CiscoTP_ctpcMgmtSysAddr_1=$CiscoTP_ctpcMgmtSysAddr->{$putinv};
			$tpmanagementsystem_sth->execute($deviceid,$scantime,$CiscoTP_ctpcMgmtSysIndex_1,$CiscoTP_ctpcMgmtSysAddrType_1,$CiscoTP_ctpcMgmtSysAddr_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcSecurity){
			my $CiscoTP_ctpcIndex_1=$CiscoTP_ctpcIndex->{$putinv};
			my $CiscoTP_ctpcDirection_1=$CiscoTP_ctpcDirection->{$putinv};
			my $CiscoTP_ctpcState_1=$CiscoTP_ctpcState->{$putinv};
			my $CiscoTP_ctpcInitialBitRate_1=$CiscoTP_ctpcInitialBitRate->{$putinv};
			my $CiscoTP_ctpcLatestBitRate_1=$CiscoTP_ctpcLatestBitRate->{$putinv};
			my $CiscoTP_ctpcRowStatus_1=$CiscoTP_ctpcRowStatus->{$putinv};
			my $CiscoTP_ctpcRemoteDirNum_1=$CiscoTP_ctpcRemoteDirNum->{$putinv};
			my $CiscoTP_ctpcLocalSIPCallId_1=$CiscoTP_ctpcLocalSIPCallId->{$putinv};
			my $CiscoTP_ctpcTxDestAddrType_1=$CiscoTP_ctpcTxDestAddrType->{$putinv};
			my $CiscoTP_ctpcTxDestAddr_1=$CiscoTP_ctpcTxDestAddr->{$putinv};
			my $CiscoTP_ctpcStartDateAndTime_1=$CiscoTP_ctpcStartDateAndTime->{$putinv};
			my $CiscoTP_ctpcDuration_1=$CiscoTP_ctpcDuration->{$putinv};
			my $CiscoTP_ctpcType_1=$CiscoTP_ctpcType->{$putinv};
			my $CiscoTP_ctpcSecurity_1=$CiscoTP_ctpcSecurity->{$putinv};
			$tpcalldetail_sth->execute($deviceid,$scantime,$CiscoTP_ctpcIndex_1,$CiscoTP_ctpcDirection_1,$CiscoTP_ctpcState_1,$CiscoTP_ctpcInitialBitRate_1,$CiscoTP_ctpcLatestBitRate_1,$CiscoTP_ctpcRowStatus_1,$CiscoTP_ctpcRemoteDirNum_1,$CiscoTP_ctpcLocalSIPCallId_1,$CiscoTP_ctpcTxDestAddrType_1,$CiscoTP_ctpcTxDestAddr_1,$CiscoTP_ctpcStartDateAndTime_1,$CiscoTP_ctpcDuration_1,$CiscoTP_ctpcType_1,$CiscoTP_ctpcSecurity_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpDVIPeripheralCableStatus){
			my $CiscoTP_ctpDVIPeripheralIndex_1=$CiscoTP_ctpDVIPeripheralIndex->{$putinv};
			my $CiscoTP_ctpDVIPeripheralCableStatus_1=$CiscoTP_ctpDVIPeripheralCableStatus->{$putinv};
			$tpdviperipheralstatus_sth->execute($deviceid,$scantime,$CiscoTP_ctpDVIPeripheralIndex_1,$CiscoTP_ctpDVIPeripheralCableStatus_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpPeripheralStatus){
			my $CiscoTP_ctpPeripheralIndex_1=$CiscoTP_ctpPeripheralIndex->{$putinv};
			my $CiscoTP_ctpPeripheralDescription_1=$CiscoTP_ctpPeripheralDescription->{$putinv};
			my $CiscoTP_ctpPeripheralStatus_1=$CiscoTP_ctpPeripheralStatus->{$putinv};
			$tpperipheralstatus_sth->execute($deviceid,$scantime,$CiscoTP_ctpPeripheralIndex_1,$CiscoTP_ctpPeripheralDescription_1,$CiscoTP_ctpPeripheralStatus_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpcStatMonitoredStatus){
			my $CiscoTP_ctpcStatMonitoredType_1=$CiscoTP_ctpcStatMonitoredType->{$putinv};
			my $CiscoTP_ctpcStatMonitoredStreamType_1=$CiscoTP_ctpcStatMonitoredStreamType->{$putinv};
			my $CiscoTP_ctpcStatMonitoredUnit_1=$CiscoTP_ctpcStatMonitoredUnit->{$putinv};
			my $CiscoTP_ctpcStatRisingThreshold_1=$CiscoTP_ctpcStatRisingThreshold->{$putinv};
			my $CiscoTP_ctpcStatFallingThreshold_1=$CiscoTP_ctpcStatFallingThreshold->{$putinv};
			my $CiscoTP_ctpcStatStartupAlarm_1=$CiscoTP_ctpcStatStartupAlarm->{$putinv};
			my $CiscoTP_ctpcStatMonitoredStatus_1=$CiscoTP_ctpcStatMonitoredStatus->{$putinv};
			$tpcallmonitor_sth->execute($deviceid,$scantime,$CiscoTP_ctpcStatMonitoredType_1,$CiscoTP_ctpcStatMonitoredStreamType_1,$CiscoTP_ctpcStatMonitoredUnit_1,$CiscoTP_ctpcStatRisingThreshold_1,$CiscoTP_ctpcStatFallingThreshold_1,$CiscoTP_ctpcStatStartupAlarm_1,$CiscoTP_ctpcStatMonitoredStatus_1,$putinv);
		}
		foreach my $putinv (keys %$CiscoTP_ctpEtherPeripheralStatus){
			my $CiscoTP_ctpEtherPeripheralIndex_1=$CiscoTP_ctpEtherPeripheralIndex->{$putinv};
			my $CiscoTP_ctpEtherPeripheralIfIndex_1=$CiscoTP_ctpEtherPeripheralIfIndex->{$putinv};
			my $CiscoTP_ctpEtherPeripheralAddrType_1=$CiscoTP_ctpEtherPeripheralAddrType->{$putinv};
			my $CiscoTP_ctpEtherPeripheralAddr_1=$CiscoTP_ctpEtherPeripheralAddr->{$putinv};
			my $CiscoTP_ctpEtherPeripheralStatus_1=$CiscoTP_ctpEtherPeripheralStatus->{$putinv};
			$tpethernetperipheralstatus_sth->execute($deviceid,$scantime,$CiscoTP_ctpEtherPeripheralIndex_1,$CiscoTP_ctpEtherPeripheralIfIndex_1,$CiscoTP_ctpEtherPeripheralAddrType_1,$CiscoTP_ctpEtherPeripheralAddr_1,$CiscoTP_ctpEtherPeripheralStatus_1,$putinv);
		}
	}; if ($@) {
		out("failed to pull telepresence inventory: $@");
	};
}

sub out {
	my ($str) = @_;
	print "$0: $deviceid ($target): $str\n";
}

sub dbg {
	my ($str) = @_;
	out($str) if ($debugging);
}
