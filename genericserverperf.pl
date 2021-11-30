#!/usr/bin/env perl
use strict;
use RISC::riscCreds;
use RISC::riscSNMP;
use RISC::riscUtility;
use RISC::Collect::PerfSummary;
$|++;

my $MAX_RUNTIME = 240;	## 4 minutes
my $no_process_args_indicator = '(RN150: process argument collection opted out)';

my $deviceid = shift;
my $devIP    = shift;
my $credid   = shift;

my $mysql = riscUtility::getDBH('RISC_Discovery', 1);
$mysql->{mysql_auto_reconnect} = 1;

my $scantime = time();

my $summary = RISC::Collect::PerfSummary::get($mysql, $deviceid, 'gensrv-snmp');
$summary->{'attempt'} = $scantime;

my $c    = riscCreds->new($devIP);
my $cred = $c->getSNMP($credid);
unless ($cred) {
	$summary->{'error'} = "could not pull credential data";
	RISC::Collect::PerfSummary::set($mysql, $summary);
	die "failed to pull credential: $c->{'error'}\n";
}
$c->disconnect();

my (
	$snmp,
	$absolutes
);

eval {
	local $SIG{TERM} = sub { my $sig = shift; die "SIG$sig\n"; };
	local $SIG{ALRM} = sub { die "RISCTIMEOUT\n"; };
	alarm $MAX_RUNTIME;

	$snmp = riscSNMP::connect($cred, $devIP);
	unless ($snmp) {
		$summary->{'error'} = "failed SNMP connection";
		RISC::Collect::PerfSummary::set($mysql, $summary);
		die "failed SNMP connection to $devIP\n";
	}

	my $insert_cpu = $mysql->prepare_cached("
		INSERT INTO gensrvperfcpu
		(deviceid,cpuindex,cpunames,cpuload,cpuerrorflag,cpuerrormsg,scantime)
		VALUES (?,?,?,?,?,?,?)
	");
	my $insert_mem = $mysql->prepare_cached("
		INSERT INTO gensrvperfmem
		(deviceid,totalswap,availswap,totalreal,availreal,minimumswap,memshared,membuffer,memcached,memswaperror,memswaperrormsg,scantime)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
	");
	my $insert_disk = $mysql->prepare_cached("
		INSERT INTO gensrvperfdisk
		(deviceid,storageindex,storagesize,storageused,scantime)
		VALUES (?,?,?,?,?)
	");
	my $insert_conn = $mysql->prepare_cached("
		INSERT INTO windowsconnection
		(deviceid,scantime,protocol,laddr,lport,faddr,fport,state,pid)
		VALUES (?,?,?,?,?,?,?,?,?)
	");
	my $insert_proc = $mysql->prepare_cached("
		INSERT INTO gensrvprocesses
		(deviceid,swrunindex,swrunname,swrunid,swrunpath,swrunparameters,swruntype,swrunstatus,swrunperfcpu,swrunperfmem,scantime)
		VALUES (?,?,?,?,?,?,?,?,?,?,?)
	");
	my $insert_diskio = $mysql->prepare_cached("
		INSERT INTO gensrvperfdiskio
		(deviceid,scantime,diskindex,diskiodevice,diskiobytesread,diskiobyteswrite,diskioreads,diskiowrites)
		VALUES (?,?,?,?,?,?,?,?)
	");
	my $insert_diskio_secondary = $mysql->prepare_cached("
		INSERT INTO gensrvperfdiskio_secondary
		(deviceid,scantime,diskindex,diskiodevice,diskiobytesread,diskiobyteswrite,diskioreads,diskiowrites)
		VALUES (?,?,?,?,?,?,?,?)
	");

	## get level for interface statistics
	my $intflvl = $mysql->selectrow_hashref("
		SELECT level
		FROM credentials
		WHERE deviceid = $deviceid
	")->{'level'};

	## cpu util
	eval {
		my $val_cpuindex = 2;    ## because that's what cloudCalc expects
		my $val_cpunames;        ## comma-separated list of cpuids
		my $val_cpuerrorflag;    ## always undef, holdover from previous collection method (laTable)
		my $val_cpuerrormsg;     ## always undef, holdover from previous collection method (laTable)

		my $procLoads = $snmp->hr_processorLoad();

		if (defined($procLoads)) {
			my $totproc;
			my $countproc;
			my $namesproc;
			foreach my $cpuid (keys %{$procLoads}) {
				$totproc += $procLoads->{$cpuid};
				$countproc++;
				$namesproc .= $cpuid . ",";
			}
			chop $namesproc;
			$val_cpunames = $namesproc;
			my $val_cpuload = $totproc / $countproc;
			$insert_cpu->execute($deviceid, $val_cpuindex, $val_cpunames, $val_cpuload, $val_cpuerrorflag, $val_cpuerrormsg, $scantime);
			$summary->{'cpu'} = $scantime;
		} else {
			$summary->{'error'} .= ' cpu:nodata';
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in cpu: $@";
		output("ERROR in CPU collection: $@");
	}

	## memory util
	eval {
		my $memtotalswap    = $snmp->linux_memTotalSwap();
		my $memavailswap    = $snmp->linux_memAvailSwap();
		my $memtotalreal    = $snmp->linux_memTotalReal();
		my $memavailreal    = $snmp->linux_memAvailReal();
		my $memminswap      = $snmp->linux_memMinimumSwap();
		my $memshared       = $snmp->linux_memShared();
		my $membuffer       = $snmp->linux_memBuffer();
		my $memcached       = $snmp->linux_memCached();
		my $memswaperror    = $snmp->linux_memSwapError();
		my $memswaperrormsg = $snmp->linux_memSwapErrorMsg();
		if (defined($memtotalreal) and defined($memavailreal)) {
			$insert_mem->execute($deviceid, $memtotalswap, $memavailswap, $memtotalreal, $memavailreal, $memminswap, $memshared, $membuffer, $memcached, $memswaperror,
				$memswaperrormsg, $scantime);
			$summary->{'mem'} = $scantime;
		} else {
			$summary->{'error'} .= ' mem:nodata';
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in memory: $@";
		output("ERROR in MEM collection: $@");
	}

	## storage util
	eval {
		my $storindex      = $snmp->hr_storageIndex();
		my $storsize       = $snmp->hr_storageSize();
		my $storused       = $snmp->hr_storageUsed();
		my $allocationUnit = $snmp->hr_storageAllocationUnits();
		if (defined($storsize) and defined($storused) and defined($allocationUnit)) {
			foreach my $siid (keys %$storindex) {
				my $val_storindex = $storindex->{$siid};
				my $val_storsize  = $storsize->{$siid} * $allocationUnit->{$siid};
				my $val_storused  = $storused->{$siid} * $allocationUnit->{$siid};
				$insert_disk->execute($deviceid, $val_storindex, $val_storsize, $val_storused, $scantime);
			}
			$summary->{'diskutil'} = $scantime;
		} else {
			$summary->{'error'} .= ' diskutil:nodata';
		}
	}; if ($@) {
		pass_timeout_exception($@);
		output("ERROR in DISK collection: $@");
		$summary->{'error'} = "error in diskutil: $@";
	}

	## network connections
	eval {
		my $connections = $snmp->getNetworkStats();
		if (defined($connections)) {
			## to determine if we got RFC4022 tcpConnectionTable we count the number of
			## period-delimited fields in the connection index for the first connection
			## RFC4022 will have at least 14 fields (more for v6)
			## older implementation will have exactly 10 fields, and is v4 only
			my @rfc4022 = split(/\./, $connections->{1}->{'index'});
			$summary->{'rfc4022'} = 1 if (scalar @rfc4022 > 10);

			foreach my $conn (keys %$connections) {
				my $laddr = $connections->{$conn}->{'localAddress'};
				my $lport = $connections->{$conn}->{'localPort'};
				my $faddr = $connections->{$conn}->{'remoteAddress'};
				my $fport = $connections->{$conn}->{'remotePort'};
				my $prot  = $connections->{$conn}->{'protocol'};
				my $state = $connections->{$conn}->{'connectionState'};
				my $pid   = $connections->{$conn}->{'processid'};
				$insert_conn->execute($deviceid, $scantime, $prot, $laddr, $lport, $faddr, $fport, $state, $pid);
			}
			$summary->{'netstat'} = $scantime;
		} else {
			$summary->{'error'} .= ' netstat:nodata';
			## could set rfc4022 to 0 here
			## if we never get this, then it will be 0
			## if we stop getting this, we probably want to retain the state
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in netstat: $@";
		output("ERROR in NETSTAT collection: $@");
	}

	## running processes
	eval {
		my $swrunindex      = $snmp->hr_swRunIndex();
		my $swrunname       = $snmp->hr_swRunName();
		my $swrunid         = $snmp->hr_swRunID();
		my $swrunpath       = $snmp->hr_swRunPath();
		my $swrunparameters = $snmp->hr_swRunParameters();
		my $swruntype       = $snmp->hr_swRunType();
		my $swrunstatus     = $snmp->hr_swRunStatus();
		my $swrunperfcpu    = $snmp->hr_swRunPerfCPU();
		my $swrunperfmem    = $snmp->hr_swRunPerfMem();
		if (defined($swrunname) and defined($swrunpath) and defined($swrunparameters)) {
			foreach my $iid (keys %$swrunindex) {
				my $val_swrunindex      = '';
				my $val_swrunname       = '';
				my $val_swrunid         = '';
				my $val_swrunpath       = '';
				my $val_swrunparameters = '';
				my $val_swruntype       = '';
				my $val_swrunstatus     = '';
				my $val_swrunperfcpu    = '';
				my $val_swrunperfmem    = '';
				$val_swrunindex      = $swrunindex->{$iid};
				$val_swrunname       = $swrunname->{$iid};
				$val_swrunid         = $swrunid->{$iid};
				$val_swrunpath       = $swrunpath->{$iid};
				if ((riscUtility::checkfeature('no-process-args'))
					and ($swrunparameters->{$iid}))
				{
					$val_swrunparameters = $no_process_args_indicator;
				} else {
					$val_swrunparameters = $swrunparameters->{$iid};
				}
				$val_swruntype       = $swruntype->{$iid};
				$val_swrunstatus     = $swrunstatus->{$iid};
				$val_swrunperfcpu    = $swrunperfcpu->{$iid};
				$val_swrunperfmem    = $swrunperfmem->{$iid};
				$insert_proc->execute(
					$deviceid,
					$val_swrunindex,
					$val_swrunname,
					$val_swrunid,
					$val_swrunpath,
					$val_swrunparameters,
					$val_swruntype,
					$val_swrunstatus,
					$val_swrunperfcpu,
					$val_swrunperfmem,
					$scantime
				);
			}
			$summary->{'processes'} = $scantime;
		} else {
			$summary->{'error'} .= ' processes:nodata';
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in processes: $@";
		output("ERROR in SWRUN collection: $@");
	}

	## diskio
	eval {
		my $diskioindex        = $snmp->ucd_io_index();
		my $diskiodevice       = $snmp->ucd_io_device();
		my $diskiobytesread    = $snmp->ucd_io_bytes_read();
		my $diskiobyteswritten = $snmp->ucd_io_bytes_write();
		my $diskioreads        = $snmp->ucd_io_reads();
		my $diskiowrites       = $snmp->ucd_io_writes();
		if (defined($diskiodevice) and defined($diskiobytesread) and defined($diskioreads)) {    ## should be a good sample
			foreach my $did (keys %$diskioindex) {
				$diskiobytesread->{$did}    = 0 unless (defined($diskiobytesread->{$did}));
				$diskiobyteswritten->{$did} = 0 unless (defined($diskiobyteswritten->{$did}));
				$diskioreads->{$did}        = 0 unless (defined($diskioreads->{$did}));
				$diskiowrites->{$did}       = 0 unless (defined($diskiowrites->{$did}));
				if (check_diskio_device($diskiodevice->{$did})) {
					$insert_diskio->execute(
						$deviceid, $scantime, $did, $diskiodevice->{$did},
						$diskiobytesread->{$did},
						$diskiobyteswritten->{$did},
						$diskioreads->{$did}, $diskiowrites->{$did}
					);
				} else {
					$insert_diskio_secondary->execute(
						$deviceid, $scantime, $did, $diskiodevice->{$did},
						$diskiobytesread->{$did},
						$diskiobyteswritten->{$did},
						$diskioreads->{$did}, $diskiowrites->{$did}
					);
				}
			}
			$summary->{'diskio'} = $scantime;
		} else {
			$summary->{'error'} .= ' diskio:nodata';
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in diskio: $@";
		output("ERROR in DISKIO collection: $@");
	}

	## interface statistics
	eval {
		$absolutes = $mysql->selectall_hashref("
			SELECT
				intindex,
				inputerrors,
				outputerrors,
				indiscards,
				outdiscards,
				outqlength,
				scantime
			FROM traffic_absolute_log
			WHERE deviceid = $deviceid
		","intindex");
		$absolutes = -1 unless $absolutes;
		my $stat;
		if ($intflvl eq '64bit') {
			$stat = traffic64();
		} elsif($intflvl eq '32bit') {
			$stat = traffic32();
		} else {
			$stat = 'unknown-counter-size';
		}
		if ($stat) {    ## returns undef, or an error string
			$summary->{'error'} .= " traffic:$stat";
		} else {
			$summary->{'traffic'} = $scantime;
		}
	}; if ($@) {
		pass_timeout_exception($@);
		$summary->{'error'} = "error in traffic: $@";
		output("ERROR in INTERFACE collection: $@\n");
	}
}; if ($@) {
	chomp(my $failure = $@);
	if ($failure =~ /RISCTIMEOUT/) {
		$failure = 'local timeout';
	} elsif ($failure =~ /SIGTERM/) {
		$failure = 'batch timeout or external kill';
	} else {
		$failure = "exception: $failure";
	}
	$summary->{'error'} = $failure;
	RISC::Collect::PerfSummary::set($mysql, $summary);
	exit(1);
}

RISC::Collect::PerfSummary::set($mysql, $summary);
exit(0);

sub output {
	my $msg = shift;
	print "genericserverperf: $deviceid: $msg\n";
}

## raise the caught exception another level if it is a timeout exception
sub pass_timeout_exception {
	my ($exception) = @_;
	die "$exception\n" if ($exception =~ /RISCTIMEOUT|SIGTERM/);
	return;
}

## returns true if the provided disk device is one we care about
sub check_diskio_device {
	my $dev = shift;

	## check first for virtual devices
	if (($dev =~ /ram/)
		or ($dev =~ /^loop/)
		or ($dev =~ /^pass/)
		or ($dev =~ /^dm-/))
	{
		return 0;
	## check for non-disk storage devices, ie floppy/optical drives
	} elsif (($dev =~ /^fd/)
		or ($dev =~ /^cd/)
		or ($dev =~ /^sr/))
	{
		return 0;
	## check for valid normal disk names
	} elsif (($dev =~ /^(h|s|v|xv)d[a-z]+$/)
		or ($dev =~ /^(a|)da\d+$/)
		or ($dev =~ /^xbd\d+$/)
		or ($dev =~ /^sd\d+$/))
	{
		return 1;
	## check for devices under RAID controllers
	} elsif (($dev =~ /cciss\/c\d+d\d+$/)) {
		return 1;
	## everything else
	} else {
		return 0;
	}
}

sub traffic64 {
	my $insertAbsolutes = $mysql->prepare("
		insert into traffic_absolute_log
		(deviceid,intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime)
		values (?,?,?,?,?,?,?,?)
		on duplicate key update inputerrors = ?, outputerrors = ?, indiscards = ?, outdiscards = ?, outqlength = ?, scantime = ?
	");

	my $ifOctetsIn       = $snmp->load_i_octet_in64();
	my $ifOctetsOut      = $snmp->load_i_octet_out64();
	my $sysUpTime        = $snmp->uptime();
	my $ifErrorsIn       = $snmp->load_i_errors_in();
	my $ifErrorsOut      = $snmp->load_i_errors_out();
	my $ifDiscardsIn     = $snmp->load_i_discards_in();
	my $ifDiscardsOut    = $snmp->load_i_discards_out();
	my $ifUcastPktsIn    = $snmp->load_i_pkts_ucast_in64();
	my $ifUcastPktsOut   = $snmp->load_i_pkts_ucast_out64();
	my $ifQueueLengthOut = $snmp->load_i_qlen_out();
	my $ifStatus         = $snmp->load_i_up();
	my $ifAdminStatus    = $snmp->load_i_up_admin();

	unless (defined($ifOctetsIn) and defined($ifOctetsOut) and defined($ifUcastPktsIn) and defined($ifUcastPktsOut)) {
		return 'nodata';    ## return an error message, returning undef indicates success
	}

	my $insertRow = $mysql->prepare("
		INSERT INTO traffic_raw
		(deviceid,intindex,bytesin,bytesout,packetsin,packetsout,discardsin,discardsout,errorsin,errorsout,outqlength,status,adminstatus,sysuptime,scantime)
		VALUES ($deviceid,?,?,?,?,?,?,?,?,?,?,?,?,?,$scantime)
	");
	my $insertRow2 = $mysql->prepare("
		INSERT into traffic_raw
		(deviceid,intindex,bytesin,bytesout,packetsin,packetsout,discardsin,discardsout,errorsin,errorsout,outqlength,status,adminstatus,sysuptime,scantime,valuetype)
		VALUES ($deviceid,?,?,?,?,?,?,?,?,?,?,?,?,?,$scantime,'absolute')"
	);

	foreach my $intindex (keys %$ifOctetsIn) {
		my $bytesin     = $ifOctetsIn->{$intindex};
		my $bytesout    = $ifOctetsOut->{$intindex};
		my $packetsin   = $ifUcastPktsIn->{$intindex};
		my $packetsout  = $ifUcastPktsOut->{$intindex};
		my $discardsin  = $ifDiscardsIn->{$intindex};
		my $discardsout = $ifDiscardsOut->{$intindex};
		my $errorsin    = $ifErrorsIn->{$intindex};
		my $errorsout   = $ifErrorsOut->{$intindex};
		my $outqlength  = $ifQueueLengthOut->{$intindex};
		my $status      = $ifStatus->{$intindex};
		my $adminstatus = $ifAdminStatus->{$intindex};
		my $sysuptime   = $sysUpTime;
		next unless (defined($bytesin) && defined($bytesout) && $status eq 'up' && $adminstatus eq 'up');
		my $absCheck = $mysql->selectrow_hashref("select * from traffic_absolute_log where deviceid = $deviceid and intindex = $intindex limit 1");

		if (defined($absCheck->{'deviceid'})) {
			my $absvalues = checkAbsolutes($absolutes, $intindex, $errorsin, $errorsout, $discardsin, $discardsout, $outqlength);
			$insertRow->execute(
				$intindex,
				$bytesin,
				$bytesout,
				$packetsin,
				$packetsout,
				$absvalues->{'indiscards'},
				$absvalues->{'outdiscards'},
				$absvalues->{'inputerrors'},
				$absvalues->{'outputerrors'},
				$absvalues->{'outqlength'},
				$status,
				$adminstatus,
				$sysuptime
			);
			$insertAbsolutes->execute(
				$deviceid,
				$intindex,
				$errorsin,
				$errorsout,
				$discardsin,
				$discardsout,
				$outqlength,
				$scantime,
				$errorsin,
				$errorsout,
				$discardsin,
				$discardsout,
				$outqlength,
				$scantime
			);
		} else {
			$insertRow2->execute(
				$intindex,
				$bytesin,
				$bytesout,
				$packetsin,
				$packetsout,
				$discardsin,
				$discardsout,
				$errorsin,
				$errorsout,
				$outqlength,
				$status,
				$adminstatus,
				$sysuptime
			);
		}
	}
	return undef;    ## this is a success return, to differentiate from returning an error message
}

sub traffic32 {
	my $_scantime;
	my @statsPass1 = getIfStats32();
	$snmp->clear_cache();
	sleep 30;
	my @statsPass2 = getIfStats32();

	my $p1In        = $statsPass1[0][0];
	my $p1Out       = $statsPass1[0][1];
	my $p2In        = $statsPass2[0][0];
	my $p2Out       = $statsPass2[0][1];
	my $e1In        = $statsPass1[0][2];
	my $e2In        = $statsPass2[0][2];
	my $e1Out       = $statsPass1[0][3];
	my $e2Out       = $statsPass2[0][3];
	my $d1In        = $statsPass1[0][4];
	my $d2In        = $statsPass2[0][4];
	my $d1Out       = $statsPass1[0][5];
	my $d2Out       = $statsPass2[0][5];
	my $uptime1     = $statsPass1[0][6];
	my $uptime2     = $statsPass2[0][6];
	my $pktsIn1     = $statsPass1[0][7];
	my $pktsIn2     = $statsPass2[0][7];
	my $pktsOut1    = $statsPass1[0][8];
	my $pktsOut2    = $statsPass2[0][8];
	my $queuelen    = $statsPass2[0][9];
	my $operstatus  = $statsPass2[0][10];
	my $adminstatus = $statsPass2[0][11];
	my $delay       = ($uptime2 - $uptime1) / 100;

	unless (defined($p1In) and defined($p2In) and defined($pktsOut1) and defined($pktsOut2)) {    ## decent sample, presumably
		return 'nodata';                                                                          ## return an error message, undef indicates success
	}

	my $insertTraffic = $mysql->prepare_cached("
		INSERT INTO traffic
		(deviceid,intindex,totalbytesin,totalbytesout,kbpsin,kbpsout,scantime,inputerrors,outputerrors,indiscards,outdiscards,inucastpkts,outucastpkts,outqlength,uptime)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
	my $insertAbsolutes = $mysql->prepare("
		INSERT INTO traffic_absolute_log
		(deviceid,intindex,inputerrors,outputerrors,indiscards,outdiscards,outqlength,scantime)
		VALUES (?,?,?,?,?,?,?,?)
		ON DUPLICATE KEY UPDATE inputerrors = ?, outputerrors = ?, indiscards = ?, outdiscards = ?, outqlength = ?, scantime = ?
	");

	foreach my $intID (sort (keys %$p2In)) {
		my $bytesIn1         = $p1In->{$intID};
		my $bytesOut1        = $p1Out->{$intID};
		my $bytesIn2         = $p2In->{$intID};
		my $bytesOut2        = $p2Out->{$intID};
		my $eIn1             = $e1In->{$intID};
		my $eIn2             = $e2In->{$intID};
		my $eOut1            = $e1Out->{$intID};
		my $eOut2            = $e2Out->{$intID};
		my $dIn1             = $d1In->{$intID};
		my $dIn2             = $d2In->{$intID};
		my $dOut1            = $d1Out->{$intID};
		my $dOut2            = $d2Out->{$intID};
		my $pktsInT1         = $pktsIn1->{$intID};
		my $pktsInT2         = $pktsIn2->{$intID};
		my $pktsOutT1        = $pktsOut1->{$intID};
		my $pktsOutT2        = $pktsOut2->{$intID};
		my $queueLengthT     = $queuelen->{$intID};
		my $operstatus2      = $operstatus->{$intID};
		my $adminstatus2     = $adminstatus->{$intID};
		my $bytesInMeasures  = 1;
		my $bytesOutMeasures = 1;
		my $timeMeasures     = $uptime1 . ":" . $uptime2;
		if (defined $bytesIn1 && defined $bytesOut1 && defined $bytesIn2 && defined $bytesOut2 && $operstatus2 eq 'up' && $adminstatus2 eq 'up') {
			my $kbpsIn  = bwCalc($bytesIn1,  $bytesIn2,  $delay);
			my $kbpsOut = bwCalc($bytesOut1, $bytesOut2, $delay);
			my $pktsInT;
			my $pktsOutT;
			if ($pktsInT2 > $pktsInT1) {
				$pktsInT = $pktsInT2 - $pktsInT1;
			} elsif ($pktsInT1 > $pktsInT2) {
				$pktsInT = ($pktsInT2 + 4294967295) - $pktsInT1;
			}
			if ($pktsOutT2 > $pktsOutT1) {
				$pktsOutT = $pktsOutT2 - $pktsOutT1;
			} elsif ($pktsOutT1 > $pktsOutT2) {
				$pktsOutT = ($pktsOutT2 + 4294967295) - $pktsOutT1;
			}
			$_scantime = time();
			my $absvalues = checkAbsolutes($absolutes, $intID, $eIn2, $eOut2, $dIn2, $dOut2, $queueLengthT);
			$insertTraffic->execute(
				$deviceid, $intID, $bytesInMeasures, $bytesOutMeasures, $kbpsIn, $kbpsOut, $scantime,
				$absvalues->{'inputerrors'},
				$absvalues->{'outputerrors'},
				$absvalues->{'indiscards'},
				$absvalues->{'outdiscards'},
				$pktsInT, $pktsOutT, $absvalues->{'outqlength'},
				$timeMeasures
			);
			$insertAbsolutes->execute($deviceid, $intID, $eIn2, $eOut2, $dIn2, $dOut2, $queueLengthT, $scantime, $eIn2, $eOut2, $dIn2, $dOut2, $queueLengthT, $scantime);
		} else {
			$_scantime = time();
		}
	}
	$insertTraffic->finish();
	return undef;    ## this is a success return, an defined return indicates an error message
}

sub getIfStats32 {
	my $ifOctetsIn       = $snmp->load_i_octet_in();
	my $ifOctetsOut      = $snmp->load_i_octet_out();
	my $sysUpTime        = $snmp->uptime();
	my $ifErrorsIn       = $snmp->load_i_errors_in();
	my $ifErrorsOut      = $snmp->load_i_errors_out();
	my $ifDiscardsIn     = $snmp->load_i_discards_in();
	my $ifDiscardsOut    = $snmp->load_i_discards_out();
	my $ifUcastPktsIn    = $snmp->load_i_pkts_ucast_in();
	my $ifUcastPktsOut   = $snmp->load_i_pkts_ucast_out();
	my $ifQueueLengthOut = $snmp->load_i_qlen_out();
	my $ifStatus         = $snmp->load_i_up();
	my $ifAdminStatus    = $snmp->load_i_up_admin();

	return [
		$ifOctetsIn,
		$ifOctetsOut,
		$ifErrorsIn,
		$ifErrorsOut,
		$ifDiscardsIn,
		$ifDiscardsOut,
		$sysUpTime,
		$ifUcastPktsIn,
		$ifUcastPktsOut,
		$ifQueueLengthOut,
		$ifStatus,
		$ifAdminStatus
	];
}

sub checkAbsolutes {
	my $absolutes    = shift;
	my $intindex     = shift;
	my $eIn2         = shift;
	my $eOut2        = shift;
	my $dIn2         = shift;
	my $dOut2        = shift;
	my $queueLengthT = shift;
	my $maxgap       = 1200;
	my $return;

	my ($eIn1, $eOut1, $dIn1, $dOut1, $ql1);
	unless ($absolutes == -1) {
		$eIn1  = $absolutes->{$intindex}->{'inputerrors'};
		$eOut1 = $absolutes->{$intindex}->{'outputerrors'};
		$dIn1  = $absolutes->{$intindex}->{'indiscards'};
		$dOut1 = $absolutes->{$intindex}->{'outdiscards'};
		$ql1   = $absolutes->{$intindex}->{'outqlength'};
	}

	#check time lapse
	# and guard against null errors/discards in current poll or previous poll
	if (   $absolutes == -1
		|| (!defined($eIn1) || !defined($eOut1) || !defined($dIn1) || !defined($dOut1))
		|| (!defined($eIn2) || !defined($eOut2) || !defined($dIn2) || !defined($dOut2))
		|| (time() - $absolutes->{$intindex}->{'scantime'}) > 1200)
	{
		$return->{'inputerrors'}  = -1;
		$return->{'outputerrors'} = -1;
		$return->{'indiscards'}   = -1;
		$return->{'outdiscards'}  = -1;
		$return->{'outqlength'}   = -1;
	} else {
		$return->{'inputerrors'}  = $eIn2 - $eIn1;
		$return->{'outputerrors'} = $eOut2 - $eOut1;
		$return->{'indiscards'}   = $dIn2 - $dIn1;
		$return->{'outdiscards'}  = $dOut2 - $dOut1;
		$return->{'outqlength'}   = $queueLengthT - $ql1;
	}
	return $return;
}

sub bwCalc {
	my $measure1 = shift;
	my $measure2 = shift;
	my $bw_delay = shift;
	my $bps;
	if ($measure2 < $measure1) {
		$bps = ((($measure2 + 4294967295) - $measure1) / $bw_delay) * 8;
	} else {
		$bps = (($measure2 - $measure1) / $bw_delay) * 8;
	}
	return $bps;
}

