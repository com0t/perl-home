#!/usr/bin/env perl
use SNMP::Info;
use Data::Dumper;

use RISC::riscUtility;
use RISC::Collect::PerfSummary;

#database connect
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

#Get Devices
my $getcred;
if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$getcred = $mysql2->prepare_cached("select * from credentials where credid=? limit 1");
} else {
	$getcred = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
										cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
										cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
										cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
										port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
										scantime,eu,ap,removed
										from credentials where credid = ? limit 1");
}

my $deviceid = shift;
my $devip = shift;
my $credid = shift;
my $vendor = shift;

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

## perfsummary
my $summarytime = time();
my $summary = RISC::Collect::PerfSummary::get($mysql,$deviceid,'network');
$summary->{'attempt'} = $summarytime;

$getcred->execute($credid);
$credential = $getcred->fetchrow_hashref();
getSNMP($credential,$devip);

#Use info to get traffic stats with IP, SNMP String, Device ID (in that order)
#$objtype='SNMP::Info::Layer3::Cisco';
#eval "require $objtype;";
#$info = $objtype->new('Debug'=>1,'AutoSpecify'=>0,'DestHost'=>$ARGV[0],'BigInt'=>1,'Version'=>1,'Community'=>$ARGV[1]);
my @statsPass1 = getIfStats($info);
$info->clear_cache();
sleep 30;
my @statsPass2 = getIfStats($info);
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

my $sth = $mysql->prepare_cached("INSERT INTO traffic (deviceid,intindex,totalbytesin,totalbytesout,kbpsin,kbpsout,scantime,inputerrors,outputerrors,indiscards,outdiscards,inucastpkts,outucastpkts,outqlength,uptime) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $sth1 = $mysql->prepare_cached("INSERT INTO trafficstaterror (deviceid,intindex,scantime,bytesin1,bytesin2,bytesout1,bytesout2,errorin1,errorin2,errorout1,errorout2,discardin1,discardin2,discardout1,discardout2,uptime1,uptime2) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
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
	if (defined $bytesIn1 && defined $bytesOut1 && defined $bytesIn2 && defined $bytesOut2 && $operstatus2 eq 'up' && $adminstatus2 eq 'up') {
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
		$sth->execute($deviceid,$intID,$bytesInMeasures,$bytesOutMeasures,$kbpsIn,$kbpsOut,$scantime,$eIn2,$eOut2,$dIn2,$dOut2,$pktsInT,$pktsOutT,$queueLengthT,$timeMeasures);
		$summary->{'traffic'} = $summarytime;
	} else {
		my $scantime = time;
		# commented out by jl -- $sth1->execute($deviceid,$intID,$scantime,$bytesIn1,$bytesIn2,$bytesOut1,$bytesOut2,$eIn1,$eIn2,$eOut1,$eOut2,$dIn1,$dIn2,$dOut1,$dOut2,$uptime1,$uptime2);
	}
}
$sth->finish();

$sth2=$mysql->prepare_cached("INSERT INTO deviceperformance (deviceid,cpu_now,cpu_1_min,cpu_5_min,mem_total,mem_used,mem_free,mem_io_total,mem_io_free,mem_io_used,scantime,buffer_sm_miss,buffer_el_miss,buffer_md_miss,buffer_bg_miss,buffer_lg_miss,buffer_hg_miss,buffer_fail,buffer_no_mem,buffer_freemem) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

if ($vendor=~'cisco' || $vendor=~'Cisco') { 
	$info = $info->specify();
	my $cpu_now;
	my $cpu_1_min;
	my $cpu_5_min;
	print $info->class()."\n";
	if ($info->class()=~/fibre/i || $info->class()=~/CNexus7K/) {
		$cpu_now = $info->nexus_cpu();
		$cpu_1_min = $info->nexus_cpu_1min();
		$cpu_5_min = $info->nexus_cpu_5min();
	} else {
		$cpu_now = $info->cat_cpu();
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
	$info = $info->specify();
	my $cpu_now=$info->cpu();
	my $cpu_1_min = $info->cpu_1_min();
	my $cpu_5_min = $info->cpu_5_min();
	$summary->{'cpu'} = $summarytime if (defined($cpu_now));
	my $mem_free = $info->mem_free();
	my $mem_used = $info->mem_used();
	my $mem_total = $info->mem_total();
	my $mem_io_total = 0;
	my $mem_io_free = 0;
	my $mem_io_used = 0;
	$summary->{'mem'} = $summarytime if (defined($mem_used));
	my $scantime2 = time;
	$sth2->execute($deviceid,$cpu_now,$cpu_1_min,$cpu_5_min,$mem_total,$mem_used,$mem_free,$mem_io_total,$mem_io_free,$mem_io_used,$scantime2,$buff_sm,$buff_el,$buff_md,$buff_bg,$buff_lg,$buff_hg,$buff_fail,$buff_nomem,$buff_freemem);
}
$sth2->finish();

RISC::Collect::PerfSummary::set($mysql,$summary);

$mysql->disconnect();

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

sub getIfStats {
	my $info = $_[0];
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

sub getSNMP {
	my $test=shift;
	my $ip=shift;
	my $version = $test->{'version'};
	my $passphrase = riscUtility::decode($test->{'passphrase'});
	my $context=$test->{'context'};
	my $securitylevel = $test->{'securitylevel'};
	my $securityname = riscUtility::decode($test->{'securityname'});
	my $authtype = $test->{'authtype'};
	my $authpass = riscUtility::decode($test->{'authpassphrase'});
	if ($test->{'privtype'} eq 'null' || riscUtility::decode($test->{'privtype'}) eq 'null') {
		$privtype=undef;
	}
	my $privuser = riscUtility::decode($test->{'privusername'});
	my $privpass = riscUtility::decode($test->{'privpassphrase'});	
	if ($version eq '1' || $version eq '2') {
		my $risc = escape($passphrase);
		$info = new SNMP::Info(
		#AutoSpecify => 1,
		#Debug => 1,
		DestHost => $ip,
		Community => $risc,
		Version => 2);
        }
	eval {
		unless (defined $info->name()) {
			my $risc = escape($passphrase);
			$info = new SNMP::Info(
			#AutoSpecify => 1,
			#Debug => 1,
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
			AutoSpecify =>1,
			DestHost=>$ip,
			#Debug=>1,
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
}

sub stringpos3 {
	my $teststring = $_[0];
	my $position = $_[1];
	#find first position
	$teststring =~ /(^[0-9]*)\.([0-9]*)\.([0-9]*)/;
	if ($position==1){
		return $1;
	} elsif ($position==2) {
		return $2;
	} elsif ($position==3) {
		return $3;
	} elsif ($position==4) {
		return $4;
	}
}

sub stringpos4 {
	my $teststring = $_[0];
	my $position = $_[1];
	#find first position
	$teststring =~ /(^[0-9]*)\.([0-9]*)\.([0-9]*)\.([0-9]*)/;
	if ($position==1){
		return $1;
	} elsif ($position==2) {
		return $2;
	} elsif ($position==3) {
		return $3;
	} elsif ($position==4) {
		return $4;
	}
}

sub IntindexWithIP {
	my $teststring = $_[0];
	my $position = $_[1];
	$teststring =~ /(^[0-9]*)\.([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)/;
	if ($position==1) {
		return $1;
	} elsif ($position==2) {
		return $2;
	}
}

sub escape {
	my $string = shift;
	#$string=~s/([\/\$\#\%\^\@\&\*\{\}\[\]\<\>\=])/\\$1/g;
	return $string;
}

sub GetCallHistory {
	#Pull the call history table
	eval {
		$info->specify();
		my $callhistory=$mysql->prepare_cached("insert into callhistory (deviceid,scantime,callindex,callstarttime,callingnumber,callednumber,interfacenumber,destinationaddress,destinationhostname,disconnectcause,connecttime,disconnecttime,dialreason,connecttimeofday,disconnecttimeofday,transmitpackets,transmitbytes,receivepackets,receivebytes,recordedunits,currency,currencyamount,multiplier,uniqueid) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) on duplicate key update scantime=?,callindex=?,callstarttime=?,callingnumber=?,callednumber=?,interfacenumber=?,destinationaddress=?,destinationhostname=?,disconnectcause=?,connecttime=?,disconnecttime=?,dialreason=?,connecttimeofday=?,disconnecttimeofday=?,transmitpackets=>,transmitbytes=?,receivepackets=?,receivebytes=?,recordedunits=?,currency=?currencyamount=?,multiplier=?");
		my $ch_index=$info->call_history_index();
		my $ch_starttime=$info->call_history_start_time();
		my $ch_callingnumber=$info->call_history_calling_number();
		my $ch_callednumber=$info->call_history_called_number();
		my $ch_interface=$info->call_history_interface_number();
		my $ch_destaddr = $info->call_history_destination_address();
		my $ch_desthost = $info->call_history_destination_hostname();
		my $ch_disconnectcause = $info->call_history_disconnect_cause();
		my $ch_connecttime = $info->call_history_connect_time();
		my $ch_disconnecttime = $info->call_history_disconnect_time();
		my $ch_dialreason = $info->call_history_dial_reason();
		my $ch_connecttod = $info->call_history_connect_timeofday();
		my $ch_disconnecttod = $info->call_history_disconnect_timeofday();
		my $ch_transmitpkts = $info->call_history_transmit_packets();
		my $ch_transmitbytes = $info->call_history_transmit_bytes();
		my $ch_receivepkts = $info->call_history_receive_packets();
		my $ch_receivebytes = $info->call_history_receive_bytes();
		my $ch_recordedunits = $info->call_history_recorded_units();
		my $ch_currency = $info->call_history_currency();
		my $ch_currencyamount=$info->call_history_currency_amount();
		my $ch_multiplier = $info->call_history_multiplier();
		foreach my $call (keys %$ch_index) {
			my $ch_s_index = $ch_index->{$call};
			my $ch_s_starttime = $ch_starttime->{$call};
			my $ch_s_callingnum = $ch_callingnumber->{$call};
			my $ch_s_callednum = $ch_callednumber->{$call};
			my $ch_s_interface = $ch_interface->{$call};
			my $ch_s_destaddr = $ch_destaddr->{$call};
			my $ch_s_desthost = $ch_desthost->{$call};
			my $ch_s_cause = $ch_disconnectcause->{$call};
			my $ch_s_connecttime = $ch_connecttime->{$call};
			my $ch_s_disconnecttime = $ch_disconnecttime->{$call};
			my $ch_s_dialreason = $ch_dialreason->{$call};
			my $ch_s_connecttod=$ch_connecttod->{$call};
			my $ch_s_disconnecttod=$ch_disconnecttod->{$call};
			my $ch_s_transmitpkts = $ch_transmitpkts->{$call};
			my $ch_s_transmitbytes = $ch_transmitbytes->{$call};
			my $ch_s_receivepkts = $ch_receivepkts->{$call};
			my $ch_s_receivebytes = $ch_receivebytes->{$call};
			my $ch_s_recordedunits = $ch_recordedunits->{$call};
			my $ch_s_currency=$ch_currency->{$call};
			my $ch_s_currencyamount=$ch_currencyamount->{$call};
			my $ch_s_multiplier=$ch_multiplier->{$call};
			my $uniqueid=$deviceid.":".$ch_s_index;
			$callhistory->execute($deviceid,$scantime,$ch_s_index,$ch_s_starttime,$ch_s_callingnum,$ch_s_callednum,$ch_s_interface,$ch_s_destaddr,$ch_s_desthost,$ch_s_cause,$ch_s_connecttime,$ch_s_disconnecttime,$ch_s_dialreason,$ch_s_connecttod,$ch_s_disconnecttod,$ch_s_transmitpkts,$ch_s_transmitbytes,$ch_s_receivepkts,$ch_s_receivebytes,$ch_s_recordedunits,$ch_s_currency,$ch_s_currencyamount,$ch_s_multiplier,$uniqueid,$scantime,$ch_s_index,$ch_s_starttime,$ch_s_callingnum,$ch_s_callednum,$ch_s_interface,$ch_s_destaddr,$ch_s_desthost,$ch_s_cause,$ch_s_connecttime,$ch_s_disconnecttime,$ch_s_dialreason,$ch_s_connecttod,$ch_s_disconnecttod,$ch_s_transmitpkts,$ch_s_transmitbytes,$ch_s_receivepkts,$ch_s_receivebytes,$ch_s_recordedunits,$ch_s_currency,$ch_s_currencyamount,$ch_s_multiplier);
		}
		$callhistory->finish();
	}; if ($@) {
		print "Problem with routes:$@\n";
	}
}

