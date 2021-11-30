#!/usr/bin/env perl

use SNMP::Info;
use Data::Dumper;

use RISC::riscUtility;
use RISC::Collect::PerfSummary;
use RISC::Collect::Logger;

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

my $deviceid = shift;
my $devip = shift;
my $credid = shift;
my $vendor = shift;
my $level = shift;

my $logger = RISC::Collect::Logger->new(
	join('::', qw( perf network ), $deviceid, $devip, $credid, $vendor, $level)
);
$logger->info('begin');
$SNMP::Info::logger = $logger;

my $scantime = time();
my $absolutes = $mysql->selectall_hashref("select intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime from traffic_absolute_log where deviceid = $deviceid","intindex");
$absolutes = -1 unless $absolutes;

my $credential;
if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$credential = $mysql2->selectrow_hashref("select * from credentials where credid=$credid limit 1");
} else {
	$credential = $mysql2->selectrow_hashref("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
											cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
											cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
											cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
											port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
											scantime,eu,ap,removed
										from credentials where credid=$credid limit 1");
}

## perfsummary
my $summarytime = time();
my $summary = RISC::Collect::PerfSummary::get($mysql,$deviceid,'network');
$summary->{'attempt'} = $summarytime;

my $info = getSNMP($credential,$devip);

if ($level eq 'instant') {
	#collect based on instantaneous readings (no cooking)
	$info = $info->specify();
	getIfStatsInst($info,$mysql,$deviceid,$scantime,$absolutes);
#	devicePerf($info,$mysql2,$deviceid,$scantime);
} elsif ($level eq '64bit') {
	#collect based on 64bit counters
	getIfStats64($info,$mysql,$deviceid,$scantime,$absolutes);
#	devicePerf($info,$mysql2,$deviceid,$scantime);
} elsif ($level eq '32bit') {
	#collect 32bit counters
	get32Traffic($info,$deviceid,$scantime,$absolutes);
#	devicePerf($info,$mysql2,$deviceid,$scantime);
}

collectDevPerf($info,$mysql);

RISC::Collect::PerfSummary::set($mysql,$summary);

################################################################################

sub getSNMP {
	my $test=shift;
	my $ip=shift;
	my $info;
	my $version = $test->{'version'};
	my $passphrase = riscUtility::decode($test->{'passphrase'});
	my $context=$test->{'context'};
	my $securitylevel = $test->{'securitylevel'};
	my $securityname = riscUtility::decode($test->{'securityname'});
	my $authtype = $test->{'authtype'};
	my $authpass = riscUtility::decode($test->{'authpassphrase'});
#	if (!defined($test->{'privtype'}) || $test->{'privtype'} eq 'null' || riscUtility::decode($test->{'privtype'}) eq 'null') {
#		$privtype=undef;
#	}
	my $privuser = riscUtility::decode($test->{'privusername'});
	my $privpass = riscUtility::decode($test->{'privpassphrase'});	
	if ($version eq '1' || $version eq '2') {
		my $risc = escape($passphrase);
		$info = new SNMP::Info(
#		AutoSpecify => 1,
#		Debug => 1,
		DestHost => $ip,
		Community => $risc,
		Version => 2);
	}
	eval {
		unless (defined $info->name()) {
			my $risc = escape($passphrase);
			$info = new SNMP::Info(
#			AutoSpecify => 1,
#			Debug => 1,
			DestHost => $ip,
			Community => $risc,
			Version => 1);
		}
	};
	if ($test->{'version'} eq '3') {
		my $privType;
		my $secLevel;
		my $authType;
		my $context;
		if ($test->{'authtype'} eq 'MD5' || $test->{'authtype'} eq 'SHA') {
			$secLevel=$test->{'securitylevel'};
			$authType=$test->{'authtype'};
			if ($test->{'privtype'} eq 'null') {
				$privType=undef;
			} else {
				$privType=$test->{'privtype'};
			}
		} else {
			$secLevel=riscUtility::decode($test->{'securitylevel'});
			$authType=riscUtility::decode($test->{'authtype'});
			if (riscUtility::decode($test->{'privtype'}) eq 'null'){
				$privType=undef;
			} else {
				$privType=riscUtility::decode($test->{'privtype'});
			}
		}
		if ($test->{'context'} eq 'null') { ## php put in the string 'null'
			$context = undef;
		} else {
			$context = riscUtility::decode($test->{'context'});
			$context = undef if ($context eq 'null'); ## php put in the base64 digest of the string 'null'
		}
		$info = new SNMP::Info(
#			AutoSpecify =>1,
			DestHost=>$ip,
#			Debug=>1,
			Version=>3,
			SecName=>riscUtility::decode($test->{'securityname'}),
			SecLevel=>$secLevel,
			Context=>$context,
			AuthProto=>$authType,
			AuthPass=>escape(riscUtility::decode($test->{'authpassphrase'})),
			PrivProto=>$privType,
			PrivPass=>escape(riscUtility::decode($test->{'privpassphrase'}))
		)
	}

	unless (defined($info->name())) {
		my $err = "failed SNMP connection";
		$summary->{'error'} = $err;
		RISC::Collect::PerfSummary::set($mysql,$summary);
		die "$err to $ip\n";
	}

	return $info;
}

sub get32Traffic {
	my $info = shift;
	my $deviceid = shift;
	my $scantime = shift;
	#Use info to get traffic stats with IP, SNMP String, Device ID (in that order)
	#$objtype='SNMP::Info::Layer3::Cisco';
	#eval "require $objtype;";
	#$info = $objtype->new('Debug'=>1,'AutoSpecify'=>0,'DestHost'=>$ARGV[0],'BigInt'=>1,'Version'=>1,'Community'=>$ARGV[1]);
	my @statsPass1 = getIfStats32($info);
	$info->clear_cache();
	sleep 30;
	my @statsPass2 = getIfStats32($info);
	#print "Run2\n";
	my $p1In = $statsPass1[0][0];
	my $p1Out = $statsPass1[0][1];
	my $p2In = $statsPass2[0][0];
	my $p2Out = $statsPass2[0][1];
	my $e1In = $statsPass1[0][2];
	my $e2In = $statsPass2[0][2];
	my $e1Out = $statsPass1[0][3];
	my $e2Out = $statsPass2[0][3];
	my $d1In = $statsPass1[0][4];
	my $d2In = $statsPass2[0][4];
	my $d1Out = $statsPass1[0][5];
	my $d2Out = $statsPass2[0][5];
	my $uptime1 = $statsPass1[0][6];
	my $uptime2 = $statsPass2[0][6];
	my $pktsIn1 = $statsPass1[0][7];
	my $pktsIn2 = $statsPass2[0][7];
	my $pktsOut1 = $statsPass1[0][8];
	my $pktsOut2 = $statsPass2[0][8];
	my $queuelen = $statsPass2[0][9];
	my $operstatus = $statsPass2[0][10];
	my $adminstatus = $statsPass2[0][11];
	my $delay = ($uptime2-$uptime1)/100;

	my $mysql = riscUtility::getDBH('RISC_Discovery',1);

	my $sth = $mysql->prepare_cached("INSERT INTO traffic (deviceid,intindex,totalbytesin,totalbytesout,kbpsin,kbpsout,scantime,inputerrors,outputerrors,indiscards,outdiscards,inucastpkts,outucastpkts,outqlength,uptime) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
#	my $sth1 = $mysql->prepare_cached("INSERT INTO trafficstaterror (deviceid,intindex,scantime,bytesin1,bytesin2,bytesout1,bytesout2,errorin1,errorin2,errorout1,errorout2,discardin1,discardin2,discardout1,discardout2,uptime1,uptime2) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	my $insertAbsolutes = $mysql->prepare("insert into traffic_absolute_log (deviceid,intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime)
						    values(?,?,?,?,?,?,?,?) on duplicate key
						    update inputerrors = ?, outputerrors = ?, indiscards = ?, outdiscards = ?, outqlength = ?, scantime = ?");
	foreach $intID (sort (keys %$p2In)) {
		my $bytesIn1 = $p1In->{$intID};
		my $bytesOut1 = $p1Out->{$intID};
		my $bytesIn2 = $p2In->{$intID};
		my $bytesOut2 = $p2Out->{$intID};
		my $eIn1 = $e1In->{$intID};
		my $eIn2 = $e2In->{$intID};
		my $eOut1 = $e1Out->{$intID};
		my $eOut2 = $e2Out->{$intID};
		my $dIn1 = $d1In->{$intID};
		my $dIn2 = $d2In->{$intID};
		my $dOut1 = $d1Out->{$intID};
		my $dOut2 = $d2Out->{$intID};
		my $pktsInT1 = $pktsIn1->{$intID};
		my $pktsInT2 = $pktsIn2->{$intID};
		my $pktsOutT1 = $pktsOut1->{$intID};
		my $pktsOutT2 = $pktsOut2->{$intID};
		my $queueLengthT = $queuelen->{$intID};
		my $operstatus2 = $operstatus->{$intID};
		my $adminstatus2 = $adminstatus->{$intID};
		my $bytesInMeasures = 1; #$bytesIn1.":".$bytesIn2 --commented out by JL;
		my $bytesOutMeasures = 1;#$bytesOut1.":".$bytesOut2 -- commented out by JL;
		my $timeMeasures = $uptime1.":".$uptime2;
		if (defined $bytesIn1 && defined $bytesOut1 && defined $bytesIn2 && defined $bytesOut2 && $operstatus2 eq 'up' && $adminstatus2 eq 'up'){
			my $kbpsIn = bwCalc($bytesIn1,$bytesIn2,$delay);
			my $kbpsOut = bwCalc($bytesOut1,$bytesOut2,$delay);
			##Calculate the number of packets over 30 seconds
			if ($pktsInT2 > $pktsInT1) {
				$pktsInT = $pktsInT2-$pktsInT1;
			} elsif ($pktsInT1>$pktsInT2) {
				$pktsInT = ($pktsInT2+4294967295)-$pktsInT1;
			}
			if ($pktsOutT2 > $pktsOutT1) {
				$pktsOutT = $pktsOutT2-$pktsOutT1;
			} elsif ($pktsOutT1>$pktsOutT2) {
				$pktsOutT = ($pktsOutT2+4294967295)-$pktsOutT1;
			}
			my $scantime = time;
			my $absvalues = checkAbsolutes($absolutes,$intID,$eIn2,$eOut2,$dIn2,$dOut2,$queueLengthT);
			$sth->execute($deviceid,$intID,$bytesInMeasures,$bytesOutMeasures,$kbpsIn,$kbpsOut,$scantime,$absvalues->{'inputerrors'},$absvalues->{'outputerrors'},$absvalues->{'indiscards'},$absvalues->{'outdiscards'},$pktsInT,$pktsOutT,$absvalues->{'outqlength'},$timeMeasures);
			$insertAbsolutes->execute($deviceid,$intID,$eIn2,$eOut2,$dIn2,$dOut2,$queueLengthT,$scantime,$eIn2,$eOut2,$dIn2,$dOut2,$queueLengthT,$scantime);
			$summary->{'traffic'} = $summarytime;
		} else {
			my $scantime = time;
			# commented out by jl -- $sth1->execute($deviceid,$intID,$scantime,$bytesIn1,$bytesIn2,$bytesOut1,$bytesOut2,$eIn1,$eIn2,$eOut1,$eOut2,$dIn1,$dIn2,$dOut1,$dOut2,$uptime1,$uptime2);
		}
	}
	$sth->finish();
}

sub collectDevPerf {
	my $info = shift;
	my $mysql = shift;
	$sth2=$mysql->prepare_cached("INSERT INTO deviceperformance (deviceid,cpu_now,cpu_1_min,cpu_5_min,mem_total,mem_used,mem_free,mem_io_total,mem_io_free,mem_io_used,scantime,buffer_sm_miss,buffer_el_miss,buffer_md_miss,buffer_bg_miss,buffer_lg_miss,buffer_hg_miss,buffer_fail,buffer_no_mem,buffer_freemem) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	if ($vendor=~'cisco' || $vendor=~'Cisco') { 
		$info=$info->specify();
		my $cpu_now;
		my $cpu_1_min;
		my $cpu_5_min;
		print $info->class()."\n";
		if ($info->class()=~/fibre/i || $info->class()=~/CNexus7K/) {
			$cpu_now = $info->nexus_cpu();
			$cpu_1_min = $info->nexus_cpu_1min();
			$cpu_5_min = $info->nexus_cpu_5min();
		} else {
			$cpu_now=$info->cat_cpu();
			$cpu_1_min = $info->cat_cpu_1min();
			$cpu_5_min = $info->cat_cpu_5min();
		}
		$summary->{'cpu'} = $summarytime if (defined($cpu_now));
		my $mem_free = $info->ios_mem_free();
		my $mem_used = $info->ios_mem_used();
		my $mem_total = $mem_free+$mem_used;
		my $mem_io_free = $info->ios_io_mem_free();
		my $mem_io_used = $info->ios_io_mem_used();
		my $mem_io_total = $mem_io_free+$mem_io_used;
		$summary->{'mem'} = $summarytime if (defined($mem_used));
		my $buff_sm = $info->ciscomem_smmiss();
		my $buff_el = $info->ciscomem_elmiss();
		my $buff_md = $info->ciscomem_mdmiss();
		my $buff_bg = $info->ciscomem_bgmiss();
		my $buff_lg = $info->ciscomem_lgmiss();
		my $buff_hg = $info->ciscomem_hgmiss();
		my $buff_fail = $info->ciscomem_fail();
		my $buff_nomem = $info->ciscomem_nomem();
		my $buff_freemem = $info->ciscomem_freemem();
		my $scantime2 = time;
		$sth2->execute($deviceid,$cpu_now,$cpu_1_min,$cpu_5_min,$mem_total,$mem_used,$mem_free,$mem_io_total,$mem_io_free,$mem_io_used,$scantime2,$buff_sm,$buff_el,$buff_md,$buff_bg,$buff_lg,$buff_hg,$buff_fail,$buff_nomem,$buff_freemem);
	} else {
		$info=$info->specify();
		my $cpu_now=$info->cpu();
		my $cpu_1_min = $info->cpu_1_min();
		my $cpu_5_min = $info->cpu_5_min();
		$summary->{'cpu'} = $summarytime if (defined($cpu_now));
		my $mem_free = $info->mem_free();
		my $mem_used = $info->mem_used();
		my $mem_total = $info->mem_total();
		my $mem_io_total = -1;
		my $mem_io_free = -1;
		my $mem_io_used = -1;
		$summary->{'mem'} = $summarytime if (defined($mem_used));
		my $buff_sm = -1;
		my $buff_el = -1;
		my $buff_md = -1;
		my $buff_bg = -1;
		my $buff_lg = -1;
		my $buff_hg = -1;
		my $buff_fail = -1;
		my $buff_nomem = -1;
		my $buff_freemem = -1;
		my $scantime2 = time;
		$sth2->execute($deviceid,$cpu_now,$cpu_1_min,$cpu_5_min,$mem_total,$mem_used,$mem_free,$mem_io_total,$mem_io_free,$mem_io_used,$scantime2,$buff_sm,$buff_el,$buff_md,$buff_bg,$buff_lg,$buff_hg,$buff_fail,$buff_nomem,$buff_freemem);
	}
	$sth2->finish();
}

#check device
sub bwCalc {
	my $measure1 = $_[0];
	my $measure2 = $_[1];
	my $bw_delay = $_[2];
	my $bps;
	if ($measure2<$measure1) {
		$bps=((($measure2 + 4294967295)-$measure1)/$bw_delay)*8;	
	} else {
		$bps=(($measure2-$measure1)/$bw_delay)*8;
	}
	return $bps;
}

sub getIfStats32 {
	my $info=shift;
	my $ifOctetsIn = $info->load_i_octet_in();
	my $ifOctetsOut = $info->load_i_octet_out();
	my $sysUpTime = $info->uptime();
	my $ifErrorsIn = $info->load_i_errors_in();
	my $ifErrorsOut = $info->load_i_errors_out();
	my $ifDiscardsIn = $info->load_i_discards_in();
	my $ifDiscardsOut = $info->load_i_discards_out();
	my $ifUcastPktsIn = $info->load_i_pkts_ucast_in();
	my $ifUcastPktsOut = $info->load_i_pkts_ucast_out();
	my $ifQueueLengthOut = $info->load_i_qlen_out();
	my $ifStatus = $info->load_i_up();
	my $ifAdminStatus= $info->load_i_up_admin();
	return [$ifOctetsIn,$ifOctetsOut,$ifErrorsIn,$ifErrorsOut,$ifDiscardsIn,$ifDiscardsOut,$sysUpTime,$ifUcastPktsIn,$ifUcastPktsOut,$ifQueueLengthOut,$ifStatus,$ifAdminStatus];
}

sub getIfStats64 {
	my $info = shift;
	my $mysql = shift;
	my $deviceid = shift;
	my $scantime = shift;
	my $insertAbsolutes = $mysql->prepare("insert into traffic_absolute_log (deviceid,intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime)
						    values(?,?,?,?,?,?,?,?) on duplicate key
						    update inputerrors = ?, outputerrors = ?, indiscards = ?, outdiscards = ?, outqlength = ?, scantime = ?");
	#Get Interface details	
	$ifOctetsIn = $info->load_i_octet_in64();
	$ifOctetsOut = $info->load_i_octet_out64();
	$sysUpTime = $info->uptime();
	$ifErrorsIn = $info->load_i_errors_in();
	$ifErrorsOut = $info->load_i_errors_out();
	$ifDiscardsIn = $info->load_i_discards_in();
	$ifDiscardsOut = $info->load_i_discards_out();
	$ifUcastPktsIn = $info->load_i_pkts_ucast_in64();
	$ifUcastPktsOut = $info->load_i_pkts_ucast_out64();
	$ifQueueLengthOut = $info->load_i_qlen_out();
	$ifStatus = $info->load_i_up();
	$ifAdminStatus = $info->load_i_up_admin();

	$summary->{'traffic'} = $summarytime if (defined($ifOctetsIn) and defined($ifErrorsOut) and defined($ifUcastPktsIn));

	my $insertRow = $mysql->prepare("insert into traffic_raw (deviceid,intindex,bytesin,bytesout,packetsin,packetsout,discardsin,discardsout,errorsin,errorsout,outqlength,status,adminstatus,sysuptime,scantime)
					    values ($deviceid,?,?,?,?,?,?,?,?,?,?,?,?,?,$scantime)");
	my $insertRow2 = $mysql->prepare("insert into traffic_raw (deviceid,intindex,bytesin,bytesout,packetsin,packetsout,discardsin,discardsout,errorsin,errorsout,outqlength,status,adminstatus,sysuptime,scantime,valuetype)
					    values ($deviceid,?,?,?,?,?,?,?,?,?,?,?,?,?,$scantime,'absolute')");

	foreach my $intindex (keys %$ifOctetsIn) {
		my $bytesin = $ifOctetsIn->{$intindex};
		my $bytesout = $ifOctetsOut->{$intindex};
		my $packetsin = $ifUcastPktsIn->{$intindex};
		my $packetsout = $ifUcastPktsOut->{$intindex};
		my $discardsin = $ifDiscardsIn->{$intindex};
		my $discardsout = $ifDiscardsOut->{$intindex};
		my $errorsin = $ifErrorsIn->{$intindex};
		my $errorsout = $ifErrorsOut->{$intindex};
		my $outqlength = $ifQueueLengthOut->{$intindex};
		my $status = $ifStatus->{$intindex};
		my $adminstatus = $ifAdminStatus->{$intindex};
		my $sysuptime = $sysUpTime;
		next unless (defined($bytesin) && defined($bytesout) && $status eq 'up' && $adminstatus eq 'up');
		my $absCheck = $mysql->selectrow_hashref("select * from traffic_absolute_log where deviceid = $deviceid and intindex = $intindex limit 1");
		if (defined($absCheck->{'deviceid'})) {
			my $absvalues = checkAbsolutes($absolutes,$intindex,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength);
			$insertRow->execute($intindex,$bytesin,$bytesout,$packetsin,$packetsout,$absvalues->{'indiscards'},$absvalues->{'outdiscards'},$absvalues->{'inputerrors'},$absvalues->{'outputerrors'},$absvalues->{'outqlength'},$status,$adminstatus,$sysuptime);
			$insertAbsolutes->execute($deviceid,$intindex,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength,$scantime,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength,$scantime);
		} else {
			$insertRow2->execute($intindex,$bytesin,$bytesout,$packetsin,$packetsout,$discardsin,$discardsout,$errorsin,$errorsout,$outqlength,$status,$adminstatus,$sysuptime);
		}
	}
}


sub getIfStatsInst {
	my $info = shift;
	my $mysql = shift;
	my $deviceid = shift;
	my $scantime = shift;
	my $insertAbsolutes = $mysql->prepare("insert into traffic_absolute_log (deviceid,intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime)
						    values(?,?,?,?,?,?,?,?) on duplicate key
						    update inputerrors = ?, outputerrors = ?, indiscards = ?, outdiscards = ?, outqlength = ?, scantime = ?");
	#Get Interface details

#	$ifOctetsIn = $info->load_i_octet_in();
#	$ifOctetsOut = $info->load_i_octet_out();
	$sysUpTime = $info->uptime();
	$ifErrorsIn = $info->load_i_errors_in();
	$ifErrorsOut = $info->load_i_errors_out();
	$ifDiscardsIn = $info->load_i_discards_in();
	$ifDiscardsOut = $info->load_i_discards_out();
#	$ifUcastPktsIn = $info->load_i_pkts_ucast_in();
#	$ifUcastPktsOut = $info->load_i_pkts_ucast_out();
	$ifQueueLengthOut = $info->load_i_qlen_out();
	$ifStatus = $info->load_i_up();
	$ifAdminStatus = $info->load_i_up_admin();
	$ifInBitsSec = $info->load_i_cisco_inbps();
	$ifOutBitsSec = $info->load_i_cisco_outbps();
	$ifInPktsSec = $info->load_i_cisco_inpps();
	$ifOutPktsSec = $info->load_i_cisco_outpps();

	$summary->{'traffic'} = $summarytime if (defined($ifErrorsIn) and defined($ifDiscardsOut) and defined($ifInPktsSec));

	my $insertRow = $mysql->prepare("insert into traffic_inst (deviceid,intindex,kbpsin,kbpsout,errorsin,errorsout,discardsin,discardsout,outqlength,ppsin,ppsout,status,adminstatus,sysuptime,scantime)
					    values ($deviceid,?,?,?,?,?,?,?,?,?,?,?,?,?,$scantime)");

	foreach my $intindex (keys %$ifInBitsSec) {
		my $kbpsin = (($ifInBitsSec->{$intindex})/8)/1024;
		my $kbpsout = (($ifOutBitsSec->{$intindex})/8)/1024;
		my $errorsin = $ifErrorsIn->{$intindex};
		my $errorsout = $ifErrorsOut->{$intindex};
		my $discardsin = $ifDiscardsIn->{$intindex};
		my $discardsout = $ifDiscardsOut->{$intindex};
		my $outqlength = $ifQueueLengthOut->{$intindex};
		my $ppsin = $ifInPktsSec->{$intindex};
		my $ppsout = $ifOutPktsSec->{$intindex};
		my $status = $ifStatus->{$intindex};
		my $adminstatus = $ifAdminStatus->{$intindex};
		my $sysuptime = $sysUpTime;
		next unless (defined($kbpsin) && defined($kbpsout) && $status eq 'up' && $adminstatus eq 'up');
		my $absvalues = checkAbsolutes($absolutes,$intindex,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength);
		$insertRow->execute($intindex,$kbpsin,$kbpsout,$absvalues->{'inputerrors'},$absvalues->{'outputerrors'},$absvalues->{'indiscards'},$absvalues->{'outdiscards'},$absvalues->{'outqlength'},$ppsin,$ppsout,$status,$adminstatus,$sysuptime);
		$insertAbsolutes->execute($deviceid,$intindex,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength,$scantime,$errorsin,$errorsout,$discardsin,$discardsout,$outqlength,$scantime);
	}
}

sub escape {
	my $string=shift;
	#$string=~s/([\/\$\#\%\^\@\&\*\{\}\[\]\<\>\=])/\\$1/g;
	return $string;
}

sub checkAbsolutes {
	my $absolutes = shift;
	my $intindex = shift;
	my $eIn2 = shift;
	my $eOut2 = shift;
	my $dIn2 = shift;
	my $dOut2 = shift;
	my $queueLengthT = shift;
	my $maxgap = 1200;
	my $return;

	my ($eIn1,$eOut1,$dIn1,$dOut1,$ql1);
	unless ($absolutes == -1) {
		$eIn1 = $absolutes->{$intindex}->{'inputerrors'};
		$eOut1 = $absolutes->{$intindex}->{'outputerrors'};
		$dIn1 = $absolutes->{$intindex}->{'indiscards'};
		$dOut1 = $absolutes->{$intindex}->{'outdiscards'};
		$ql1 = $absolutes->{$intindex}->{'outqlength'};
	}

	#check time lapse
	# and guard against null errors/discards in current poll or previous poll
	if ($absolutes == -1 || 
		(!defined($eIn1) || !defined($eOut1) || !defined($dIn1) || !defined($dOut1)) || 
		(!defined($eIn2) || !defined($eOut2) || !defined($dIn2) || !defined($dOut2)) || 
		(time() - $absolutes->{$intindex}->{'scantime'}) > 1200) {
		$return->{'inputerrors'} = -1;
		$return->{'outputerrors'} = -1;
		$return->{'indiscards'} = -1;
		$return->{'outdiscards'} = -1;
		$return->{'outqlength'} = -1;
	} else {
		$return->{'inputerrors'} = $eIn2 - $eIn1;
		$return->{'outputerrors'} = $eOut2 - $eOut1;
		$return->{'indiscards'} = $dIn2 - $dIn1;
		$return->{'outdiscards'} = $dOut2 - $dOut1;
		$return->{'outqlength'} = $queueLengthT - $ql1;
	}
	return $return;
}

