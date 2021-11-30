#!/usr/bin/perl
#
##
use strict;
use Data::Dumper;
use POSIX;
use Net::IP qw( ip_expand_address ip_is_ipv6 );

use RISC::riscCreds;
use RISC::riscUtility;
use RISC::riscSSH;
use RISC::CollectionValidation;
use RISC::Collect::PerfSummary;
use RISC::Collect::Quirks;
use RISC::Collect::ServiceConfig qw( detect_services );
use RISC::Collect::Logger;

$Data::Dumper::Sortkeys = 1;

my $cyberark_ssh = (-f "/etc/risc-feature/cyberark-ssh" && -f "/home/risc/conf/cyberark_config.json");

## seconds to complete collection before self-destructing
## check for a feature definition before using the hard default
my $MAX_RUNTIME	= riscUtility::checkfeature('gensrvssh-perf-device-max-runtime');
$MAX_RUNTIME	= 480 unless ($MAX_RUNTIME);	## 8 minutes

my $noinsert = 0;
$noinsert = $ENV{'NOINSERT'} if (defined($ENV{'NOINSERT'}));

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $no_process_args_indicator = '(RN150: process argument collection opted out)';

## collection validation mode
## the value of the VALIDATE environment variable should be
##   the path to the log file we'll write our data to
## if using validation mode, the $credid argument will be
##   the single-quoted, space-separated list of credential
##   fields in base64, being the same that is passed to the
##   simple credential test facility via the web UI
my $VALIDATE = 0;
$VALIDATE = $ENV{'VALIDATE'} if ($ENV{'VALIDATE'});

if ($VALIDATE) {
	# If running in validation mode, rename the process so it isn't killed by
	# other cleanup operations.
	$0 = 'gensrvssh-validation';
}

my ($deviceid, $target, $credid);

# use environment to avoid logging any sensitive strings - this is called with creds rather than credid by validation
if (my $risc_credentials = riscUtility::risc_credentials()) {
	($deviceid, $target, $credid) = map {
		$risc_credentials->{$_}
	} qw(deviceid target credid);
# the old fashioned way
} else {
	($deviceid, $target, $credid) = (shift, shift, shift);
}

my $logger = RISC::Collect::Logger->new(join("::", "gensrvssh-perf", $deviceid, $target));

## provision the validation driver
## if we aren't doing validation (the VALIDATE environment variable is not set)
##   the dummy driver is loaded that ignores all validation operations
## operational aspects that differ between validation mode and standard still need to check
my $validator = RISC::CollectionValidation->new({
	'logfile'	=> $ENV{'VALIDATE'},
	'debug'		=> $debugging
});
if (my $verr = $validator->err()) {
	print STDOUT 'Internal error: contact help@riscnetworks.com with error code CV01';
	print STDERR "$0::ERROR: $verr\n";
	$validator->exit('fail');
}
my $vsuccess	= $validator->cmdstatus_name('success');
my $vfail	= $validator->cmdstatus_name('fail');

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

my $scantime = time();

## perf summary
my ($summary,$localsummary);
unless ($VALIDATE) {
	$summary = RISC::Collect::PerfSummary::get($mysql,$deviceid,'gensrv-ssh');
	$summary->{'attempt'} = $scantime;
	## make a copy of the primary summary
	## successful collection of a metric is updated in the local summary
	## the primary summary is updated with the local summary if and when the insert of the data completes
	## this lets us properly record the data collection summary if we are aborted due to a local or batch timeout
	$localsummary = { %{$summary} };
}

my $ssh;
my $os;
my ($cpu,$mem);
my ($diskutil,$diskio,$diskiops);
my (@connections,$proc);
my ($uptime,$traf);

## begin collection
## this is protected in an eval to ensure that any condition causing an exception,
##   including runtime errors, local timeouts, and admin-level timeouts
##   do not allow the script to die without committing the perfsummary record

eval {

	## handle signals
	## in particular, create an alarm handler to self-destruct the process if
	##   the local timeout is exceeded
	## both are caught by the major eval such that the perfsummary record can
	##   be committed prior to exiting
	dbg('installing signal handlers and local alarm');
	local $SIG{TERM} = sub { my $sig = shift; die "SIG$sig\n"; };
	local $SIG{ALRM} = sub { die "RISCTIMEOUT\n"; };
	alarm $MAX_RUNTIME;

	## get the credential
	dbg('provisioning credential');
	my $cred;
	my $credobj = riscCreds->new($target);
	if ($VALIDATE) {
		my ($username,$ctx,$auth,$port,$priv,$keypass) = split(/\s+/,$credid);
		## Get creds if using CyberArk
		if ($cyberark_ssh) {
			my $credSet = $credobj->getGenSrvSSHCyberArkQueryString($auth);
			unless ($credSet) {
				my $errmsg = 'Failed to fetch credential: '. $credobj->get_error();

				$validator->log("<h3>PERFORMANCE</h3>\n", 0);
				$validator->log("<table>\n",            0);
				$validator->log("<tr><td>Connect</td>", 1);
				$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
				$validator->log("</table>\n",0);
				$validator->report_connection_failure($errmsg);
				$validator->finish();
				$validator->exit('fail');
			}
			$username = $credSet->{'username'};
			$auth = $credSet->{'passphrase'};
		}
		$cred = $credobj->prepGenSrvSSH({
			'credid'		=> 0,
			'username'		=> $username,
			'context'		=> $ctx,
			'passphrase'		=> $auth,
			'authpassphrase'	=> $keypass,
			'privtype'		=> $priv,
			'port'			=> $port
		});
	} else {
		$cred = $credobj->getGenSrvSSH($credid);
		unless ($cred) {
			$summary->{'error'} = "failed to get credential data";
			RISC::Collect::PerfSummary::set($mysql,$summary);
			$credobj->print_error();
			out("failed to get credential data for credid $credid");
			exit(1);
		}
	}
	$credobj->disconnect();

	## start validation log
	$validator->log("<h3>PERFORMANCE</h3>\n",0);
	$validator->log("<table>\n",0);
	$validator->log("<tr><td>Connect</td>",1);

	## connect
	dbg('connecting');
	$ssh = RISC::riscSSH->new({
		'debug'		=> $debugging,
		'validator'	=> $validator
	});
	$ssh->connect($target,$cred);
	unless($ssh->{'connected'}) {
		if ($VALIDATE) {
			$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
			$validator->log("</table>",0);
			$validator->finish();
			$validator->report_connection_failure($ssh->get_error());
			$validator->exit('fail');
		} else {
			$summary->{'error'} = "failed to connect: $ssh->{'err'}->{'msg'}";
			RISC::Collect::PerfSummary::set($mysql,$summary);
			$ssh->print_error();
			exit(1);
		}
	}
	$validator->log("<td class='$vsuccess'>$vsuccess</td></tr>\n",0);
	$validator->log("<tr><td>Supported OS</td>",1);

	## ensure the os is supported
	unless ($ssh->supported_os()) {
		if ($VALIDATE) {
			$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
			$validator->log("</table>\n",0);
			$validator->finish();
			$validator->report_supported_os_failure($ssh->{'os'});
			$validator->exit('fail');
		} else {
			$summary->{'error'} = "unsupported os: $ssh->{'os'}";
			RISC::Collect::PerfSummary::set($mysql,$summary);
			out("aborting due to unsupported os: $ssh->{'os'}");
			exit(1);
		}
	}

	if ($VALIDATE) {
		$validator->log("<td class='$vsuccess'>$vsuccess ($ssh->{'os'})</td></tr>\n",0);
	}

	$os = $ssh->{'os'};

	$validator->log("</table>\n",0);
	$validator->log("<h4>PERFORMANCE COMMANDS</h4>\n",0);

	my $storagequery = $mysql->prepare("SELECT storageindex,storagedescription FROM gensrvstorage WHERE deviceid = ?");
	my $intfquery = $mysql->prepare("SELECT intindex,description,adminstatus,operstatus FROM interfaces WHERE deviceid = ?");

	##
	# cpu
	##

	dbg('collecting cpu');
	if ($ssh->{'os'} eq 'Linux') {
		my $rawvmstat = $ssh->cmd('vmstat -w -S K 1 2', { 'vclass' => 'fallback' });
		unless ($rawvmstat) { ## try without -w flag (prevents truncation of large integers) for older systems that don't support it
			$rawvmstat = $ssh->cmd('vmstat -S K 1 2', { 'vclass' => 'fail' });
		}
		if ($rawvmstat) {
			my @rawvmstat = split(/\n/, $rawvmstat);
			shift @rawvmstat; ## first header line
			shift @rawvmstat; ## second header line
			shift @rawvmstat; ## first data line, which contains averages since the last boot
			foreach my $line (@rawvmstat) {
				next if (($line =~ /^procs/) or ($line =~ /^\s*r/));
				$line =~ s/^\s+//g; ## strip leading whitespace
				my @line = split(/\s+/, $line);
				$cpu->{'runwait'}	= $line[0];	## number of processes waiting to run
				$cpu->{'runblock'}	= $line[1];	## number of processes in blocking sleep
				$cpu->{'swapped'}	= $line[2];	## amount of swap used
				$cpu->{'free'}		= $line[3]; 	## amount of free memory available
				$cpu->{'buf'}		= $line[4];	## amount of buffer memory used
				$cpu->{'cache'}		= $line[5];	## amount of cache memory used
				$cpu->{'swapin'}	= $line[6];	## number of memory pages ibeing swapped from disk
				$cpu->{'swapout'}	= $line[7];	## number of memory pages being swapped to disk
				$cpu->{'ioin'}		= $line[8];	## number of disk blocks being read
				$cpu->{'ioout'}		= $line[9];	## number of disk blocks being written
				$cpu->{'interrupt'}	= $line[10];	## number of interrupts per second
				$cpu->{'context'}	= $line[11];	## number of context switches per second
				$cpu->{'user'}		= $line[12];	## percent of CPU time used by user processes
				$cpu->{'sys'}		= $line[13];	## percent of CPU time used by the kernel
				$cpu->{'idle'}		= $line[14];	## percent of CPU time idle
				$cpu->{'wait'}		= $line[15];	## percent of CPU time waiting on IO
				$cpu->{'steal'}		= $line[16];	## percent of CPU time stolen by hypervisor
				$cpu->{'busy'}		= 100 - $cpu->{'idle'};
			}
			$localsummary->{'cpu'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		my $vmstat = $ssh->cmd('vmstat 1 2', { 'vclass' => 'fail' });
		if ($vmstat) {
			my @vmstat = split(/\n/, $vmstat);
			my $data = $vmstat[-1]; ## last line has our actual data
			$data =~ s/^\s+//; ## trim leading space
			my @data = split(/\s+/, $data);
			$cpu->{'user'} = $data[13];
			$cpu->{'sys'}  = $data[14];
			$cpu->{'idle'} = $data[15];
			$cpu->{'busy'} = 100 - $cpu->{'idle'};
			$localsummary->{'cpu'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('CPU',$cpu);


	##
	# memory
	##

	dbg('collecting mem');
	if ($ssh->{'os'} eq 'Linux') {
		my $memraw = $ssh->cmd('cat /proc/meminfo',{ 'vclass' => 'fail' });
		if ($memraw) {
			my @memraw = split(/\n/,$memraw);
			foreach my $line (@memraw) {
				if ($line =~ /^MemTotal:\s+(\d+)/) {
					$mem->{'total'} = $1;
				}
				if ($line =~ /^MemFree:\s+(\d+)/) {
					$mem->{'free'} = $1;
				}
				if ($line =~ /^Buffers:\s+(\d+)/) {
					$mem->{'buffer'} = $1;
				}
				if ($line =~ /^Cached:\s+(\d+)/) {
					$mem->{'cache'} = $1;
				}
				if ($line =~ /Shmem:\s+(\d+)/) {
					$mem->{'shared'} = $1;
				}
				if ($line =~ /^SwapTotal:\s+(\d+)/) {
					$mem->{'swaptotal'} = $1;
				}
				if ($line =~ /^SwapFree:\s+(\d+)/) {
					$mem->{'swapfree'} = $1;
				}
			}
			## the heuristic is to alarm on swap if free is less than 15% of total
			$mem->{'swaperr'} = 'noError';
			$mem->{'swapmin'} = ceil($mem->{'swaptotal'} * 0.15);
			if (($mem->{'swapfree'} < $mem->{'swapmin'}) or ($mem->{'swapfree'} == 0)) {
				$mem->{'swaperr'} = 'error';
				$mem->{'swaperrmsg'} = 'Running out of swap space';
			}
			$localsummary->{'mem'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		my $pagesize = $ssh->cmd('pagesize',{ 'vclass' => 'fail' });
		my $vmstat = $ssh->cmd('vmstat -v',{ 'vclass' => 'fail' });
		my $lsps = $ssh->cmd('lsps -a',{ 'vclass' => 'fail' });
		if (defined($pagesize) and defined($vmstat) and defined($lsps)) {
			my ($pages) = $vmstat =~ /(\d+) memory pages/;
			my ($free) = $vmstat =~ /(\d+) free pages/;
			my ($cache) = $vmstat =~ /(\d+) file pages/;
			$mem->{'total'} = ($pages * $pagesize)/1024;	## B to KB
			$mem->{'free'} = ($free * $pagesize)/1024;	## B to KB
			$mem->{'cache'} = ($cache * $pagesize)/1024;	## B to KB
			## cannot find an AIX corollary to Linux buf, shared
			$mem->{'buffer'} = 0;
			$mem->{'shared'} = 0;
			my @lsps = split(/\n/,$lsps);
			shift @lsps; ## header
			my ($lv,$pv,$vg,$size,$percent) = split(/\s+/,$lsps[0]);
			($size) = $size =~ /^(\d+)/; ## according to the man page, this is always in MB
			$size *= 1024; ## to KB
			$mem->{'swaptotal'} = $size;
			$mem->{'swapfree'} = floor($size*((100 - $percent)/100)); ## utilization percent to free size
			$mem->{'swaperr'} = 'noError';
			$mem->{'swapmin'} = ceil($mem->{'swaptotal'} * 0.15);
			if (($mem->{'swapfree'} == 0) or ($mem->{'swapfree'} < $mem->{'swapmin'})) {
				$mem->{'swaperr'} = 'error';
				$mem->{'swaperrmsg'} = 'Running out of swap space';
			}
			$localsummary->{'mem'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('MEM',$mem);


	##
	# disk util
	##

	dbg('provisining fs list');
	my $diskhash;
	$storagequery->execute($deviceid);
	while (my $row = $storagequery->fetchrow_hashref()) {
		$diskhash->{$row->{'storagedescription'}} = $row->{'storageindex'};
	}
	$storagequery->finish();
	dbg('collecting diskutil');
	if ($ssh->{'os'} eq 'Linux') {
		my $df_cmd = 'df -P';
		# ignore non-zero exit, e.g. if 'Stale file handle' is returned due to bad NFS mounts
		if (riscUtility::checkfeature('ignore-linux-df-errors', $mysql)) {
			$df_cmd .= ' || true';
		}
		my $df = $ssh->cmd($df_cmd,{ 'priv' => 1, 'vclass' => 'fail' });
		if ($df) {
			my @df = split(/\n/,$df);
			shift @df; ## remove header line
			foreach my $line (@df) {
				my ($parent,$size,$used,$avail,$cap,$mp) = split(/\s+/,$line);
				next unless (defined($diskhash->{$mp}));
				$diskutil->{$mp}->{'index'} = $diskhash->{$mp};
				$diskutil->{$mp}->{'size'} = $size*1024;
				$diskutil->{$mp}->{'used'} = $used*1024;
				($diskutil->{$mp}->{'capacity'}) = $cap =~ /(\d+)%/;
			}
			$localsummary->{'diskutil'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		## normally, df doesn't require elevated priv
		## in some cases, certain filesystems cannot be shown without, and df returns an error
		## so, attempt df without priv first, then fall back to trying with priv if that fails
		my $df = $ssh->cmd('df -Pk',{ 'vclass' => 'fallback' });
		unless ($df) {
			$df = $ssh->cmd('df -Pk',{ 'priv' => 1, 'vclass' => 'fail' });
		}
		if ($df) {
			my @df = split(/\n/,$df);
			shift @df; ## remove header line
			foreach my $line (@df) {
				my ($parent,$size,$used,$avail,$cap,$mp) = split(/\s+/,$line);
				next unless (defined($diskhash->{$mp}));
				$diskutil->{$mp}->{'index'} = $diskhash->{$mp};
				$diskutil->{$mp}->{'size'} = $size*1024;
				$diskutil->{$mp}->{'used'} = $used*1024;
				($diskutil->{$mp}->{'capacity'}) = $cap =~ /(\d+)%/;
			}
			$localsummary->{'diskutil'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('FSUTIL',$diskutil);


	##
	# disk IO
	##

	dbg('collecting diskio');
	if ($ssh->{'os'} eq 'Linux') {
		my $rawdiskio = $ssh->cmd('cat /proc/diskstats',{ 'vclass' => 'fail' });
		if ($rawdiskio) {
			my @rawdiskio = split(/\n/,$rawdiskio);
			foreach my $line (@rawdiskio) {
				my @tokens = split(/\s+/,$line);
				my $dev = $tokens[3];
				if (check_diskio_device($dev)) { ## put virtual, partition, non-disk devices into the secondary table
					$diskio->{$dev}->{'reads'} = $tokens[4];
					$diskio->{$dev}->{'readmerged'} = $tokens[5];
					$diskio->{$dev}->{'readsectors'} = $tokens[6];
					$diskio->{$dev}->{'readbytes'} = $tokens[6]*512; ## number of blocks read * 512 byte blocks = bytes read
					$diskio->{$dev}->{'msecreading'} = $tokens[7];
					$diskio->{$dev}->{'writes'} = $tokens[8];
					$diskio->{$dev}->{'writemerged'} = $tokens[9];
					$diskio->{$dev}->{'writesectors'} = $tokens[10];
					$diskio->{$dev}->{'writebytes'} = $tokens[10]*512; ## number of blocks written * 512 byte blocks = bytes written
					$diskio->{$dev}->{'msecwriting'} = $tokens[11];
					$diskio->{$dev}->{'iopending'} = $tokens[12];
					$diskio->{$dev}->{'msecio'} = $tokens[13];
					$diskio->{$dev}->{'msecioweight'} = $tokens[14];
				}
			}
			$localsummary->{'diskio'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		## AIX does not give us the aggregate totals, but rather the per-second metrics, so we insert into a new gensrvperfdiskio_persecond table
		my $iostat = $ssh->cmd('iostat -Dl 1 1',{ 'vclass' => 'fail' });
		if ($iostat) {
			foreach my $dsk (split(/\n/, $iostat)) {
				## assume that all disks are named 'hdiskX'
				next unless ($dsk =~ /^hdisk/);
				my (
					$dev,
					$tmact,
					$xbps,
					$xtps,
					$xbread,
					$xbwrtn,
					$rps,
					$ravgsrv,
					$rminsrv,
					$rmaxsrv,
					$rto,
					$rfail,
					$wps,
					$wavgsrv,
					$wminsrv,
					$wmaxsrv,
					$wto,
					$wfail,
					$qavgtime,
					$qmintime,
					$qavgwqsz,
					$qavgsqsz,
					$qservqfull
				) = split(/\s+/, $dsk);
				$diskiops->{$dev}->{'tps'}	= si_to_base_b10($xtps);
				$diskiops->{$dev}->{'rps'}	= si_to_base_b10($rps);
				$diskiops->{$dev}->{'wps'}	= si_to_base_b10($wps);
				$diskiops->{$dev}->{'bytesps'}	= si_to_base_b10($xbps);
				$diskiops->{$dev}->{'bytesrps'}	= si_to_base_b10($xbread);
				$diskiops->{$dev}->{'byteswps'}	= si_to_base_b10($xbwrtn);
			}
			$localsummary->{'diskio'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('DISKIO', $diskio);
	dbg_dump('DISKIO_PERSEC', $diskiops);


	##
	# network connections
	##

	## fetch all ips for this device
	## we use these for listener sockets bound to all addresses
	dbg('provisining interface list');
	my $allips;
	if ($VALIDATE) {
		$allips = [];
	} else {
		$allips = $mysql->selectall_arrayref("
			SELECT ip
			FROM iptables
			WHERE deviceid = $deviceid
		",{ Slice => {} });
	}

	dbg('collecting netstat');

	# this feature flag determines if we're limiting listener collection to a 24-hour rate 
	# so that we don't fill up the disk on quirky assessments with lots of listeners (MCM-313)
	my $daily_listeners = riscUtility::checkfeature('daily-listeners', $mysql);

	# setting this flag to true will result in storing only the established connections
	my $filter_listeners = 0;
	if ($daily_listeners && !$VALIDATE) {
		my $q = RISC::Collect::Quirks->new({ db => $mysql });
		my $quirks = $q->get($deviceid);
		if ($quirks->{'listener_timestamp'} && time - 86400 < $quirks->{'listener_timestamp'}) {
			$filter_listeners = 1;	# the quirk exists and it has been less than 24 hours since collecting listeners
		} else {
			$logger->debug("keeping listeners");
			$quirks->{'listener_timestamp'} = time;
			$q->post($deviceid, $quirks);
		}
	}

	if ($ssh->{'os'} eq 'Linux') {
		my $rawnetstat = $ssh->cmd('netstat --inet --inet6 -n -p -a -t',{ 'priv' => 1, 'vclass' => 'fail' });
		if ($rawnetstat) {
			my @rawnetstat = split(/\n/,$rawnetstat);
			shift @rawnetstat; ## removes the first header row
			shift @rawnetstat; ## removes the second header row
			foreach my $conn (@rawnetstat) {
				my $netstat;
				if ($conn =~ /^tcp/i) {
					my @tcp = split(/\s+/,$conn);
					($netstat->{'pid'}) = $tcp[6] =~ /(\d+)\/.*/;
					$netstat->{'pid'} = 0 unless (defined($netstat->{'pid'}));
					$netstat->{'proto'} = $tcp[0];
					$netstat->{'rxqueue'} = $tcp[1];
					$netstat->{'txqueue'} = $tcp[2];
					## NOTE: this will only catch v4 addresses, or the v6 catch-all, complete v6 addresses will be ignored
					($netstat->{'laddr'},$netstat->{'lport'}) = $tcp[3] =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|::|\*):(\d+|\*)$/;
					($netstat->{'faddr'},$netstat->{'fport'}) = $tcp[4] =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|::|\*):(\d+|\*)$/;
					## map listener binds to all addresses in v6 format ('::') to '*'
					$netstat->{'laddr'} = '*' if ($netstat->{'laddr'} eq '::');
					$netstat->{'faddr'} = '0.0.0.0' if ($netstat->{'faddr'} eq '::');
					## expand ipv6 compacted addresses
					$netstat->{'laddr'} = ip_expand_address($netstat->{'laddr'},6) if (ip_is_ipv6($netstat->{'laddr'}));
					$netstat->{'faddr'} = ip_expand_address($netstat->{'faddr'},6) if (ip_is_ipv6($netstat->{'faddr'}));
					$netstat->{'fport'} = 0 if ($netstat->{'fport'} eq '*'); ## mark remote port as 0 for listening sockets
					$netstat->{'state'} = lc $tcp[5];
				}
				next unless (defined($netstat->{'laddr'}));
				next if ($daily_listeners && $filter_listeners && $netstat->{'state'} eq 'listen');

				## expand listener binds to all addresses as listener records to each inventoried ip on this device
				if ($netstat->{'laddr'} eq '*') {
					foreach my $ip (@{$allips}) {
						my $n = { %{$netstat} };
						$n->{'laddr'} = $ip->{'ip'};
						push(@connections,$n);
					}
				} else {
					push(@connections,$netstat);
				}
			}
			$localsummary->{'netstat'} = $scantime;
			$localsummary->{'rfc4022'} = 1;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		## here we have two methods, netstat and lsof
		## netstat on AIX cannot give us PIDs, but is guaranteed to be available
		## lsof can get us sockets with PIDs, but is not guaranteed to be available
		## first, determine if we have lsof, proceed with it if so, if not do the netstat method
		##
		## update: netstat is no longer permitted, due to lack of PIDs
		##	we run lsof, and if it fails we check the 'aix-netstat-fallback' feature flag
		##	if set, we run 'netstat', otherwise we have failed connectivity collection
		## XXX: the 'aix-netstat-fallback' feature flag is only implemented for a single customer
		##	as a one-off, so it should be removed
		my $lsof_vclass = ($ssh->aix_netstat_enable()) ? 'fallback'  : 'fail';
		my $lsof = $ssh->cmd('lsof -i -nP',{ 'priv' => 1, 'vclass' => $lsof_vclass });
		if ($lsof) {
			my @lsof = split(/\n/,$lsof);
			foreach my $line (@lsof) {
				my $conn;
				my ($cmd,$pid,$user,$fd,$inet,$dev,$sz,$layer4,$sock,$state) = split(/\s+/,$line);
				next unless ($layer4 =~ /TCP/i);
				$conn->{'proto'} = $layer4;
				$conn->{'pid'} = $pid;
				($conn->{'state'}) = $state =~ /\((.*)\)/;
				next unless ($conn->{'state'}); ## some TCP sockets don't list a state (?)
				next if ($daily_listeners && $filter_listeners && $conn->{'state'} eq 'listen');
				if ($sock =~ /->/) {	## this indicates we have a remote end to the socket
					my ($laddr,$lport,$faddr,$fport) = $sock =~ /(.*):(\d+)\-\>(.*):(\d+)/;
					if ($inet =~ /IPv6/i) {
						$laddr =~ s/[\[\]]//g;	## v6 addresses are typically wrapped in square brackets
						$faddr =~ s/[\[\]]//g;
						$laddr = ip_expand_address($laddr,6) if (ip_is_ipv6($laddr));
						$faddr = ip_expand_address($faddr,6) if (ip_is_ipv6($faddr));
					}
					$conn->{'laddr'} = $laddr;
					$conn->{'lport'} = $lport;
					$conn->{'faddr'} = $faddr;
					$conn->{'fport'} = $fport;
				} else {		## no remote end
					my $faddr;
					my ($laddr,$lport) = $sock =~ /(.*):(\d+)/;
					next unless (defined($laddr) and defined($lport)); ## we likely fail the match due to no defined port, ie: *:* (CLOSED)
					if ($inet eq 'IPv6') {
						$laddr = '::' if ($laddr eq '*');
						$laddr = ip_expand_address($laddr,6) if (ip_is_ipv6($laddr));
						$faddr = ip_expand_address('::',6);
					} else {
						$laddr = '0.0.0.0' if ($laddr eq '*');
						$faddr = '0.0.0.0';
					}
					$conn->{'laddr'} = $laddr;
					$conn->{'lport'} = $lport;
					$conn->{'faddr'} = $faddr;
					$conn->{'fport'} = 0;
				}
				push(@connections,$conn);
			}
			$localsummary->{'netstat'} = $scantime;
			$localsummary->{'rfc4022'} = 1;
		} elsif ($ssh->aix_netstat_enable()) {
			my $netstat = $ssh->cmd('netstat -an -f inet',{ 'vclass' => 'fail' });
			if ($netstat) {
				my @netstat = split(/\n/,$netstat);
				shift @netstat; ## header
				foreach my $line (@netstat) {
					my $conn;
					my @line = split(/\s+/,$line);
					$conn->{'proto'} = $line[0];
					next unless ($conn->{'proto'} =~ /tcp/i);
					my $v6 = 1 if ($conn->{'proto'} =~ /6/);
					$conn->{'proto'} =~ s/[46]$//; ## replace tcp4 or tcp6 with tcp

					my $local = $line[3];
					next if ($local eq '*.*'); ## doesn't make sense, but our test box was doing this: *.* *.* CLOSED
					my ($laddr,$lport) = $local =~ /(.*)\.(\d+)$/;
					if ($laddr eq '*') {
						if ($v6) {
							$laddr = '::';
						} else {
							$laddr = '0.0.0.0';
						}
					}
					$laddr = ip_expand_address($laddr,6) if (ip_is_ipv6($laddr));
					$conn->{'laddr'} = $laddr;
					$conn->{'lport'} = $lport;

					my $remote = $line[4];
					if ($remote eq '*.*') {
						my $faddr;
						if ($v6) {
							$faddr = ip_expand_address('::',6);
						} else {
							$faddr = '0.0.0.0';
						}
						$conn->{'faddr'} = $faddr;
						$conn->{'fport'} = 0;
					} else {
						my ($faddr,$fport) = $remote =~ /(.*)\.(\d+)$/;
						$faddr = ip_expand_address($faddr,6) if (ip_is_ipv6($faddr));
						$conn->{'faddr'} = $faddr;
						$conn->{'fport'} = $fport;
					}

					$conn->{'state'} = $line[5];
					next if ($daily_listeners && $filter_listeners && $conn->{'state'} eq 'listen');

					push(@connections,$conn);
				}
				$localsummary->{'netstat'} = $scantime;
				$localsummary->{'rfc4022'} = 0;
			} else {
				## failed 'netstat'
				$summary->{'error'} = $ssh->{'err'}->{'msg'};
			}
		} else {
			## failed 'lsof', and 'netstat' fallback not permitted
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('NETSTAT',\@connections);


	##
	# processes
	##

	dbg('collecting processes');
	if ($ssh->{'os'} eq 'Linux') {
		my $psraw = $ssh->cmd('ps axwww --no-headers -o pid,cputime,rsz,command',{ 'vclass' => 'fail' });
		if ($psraw) {
			my $failed_count = 0;
			my @lines = split(/\n/,$psraw);
			foreach my $line (@lines) {
				my ($pid,$hours,$minutes,$seconds,$perfmem,$process) = $line =~ /(\d+)\s+(\d+|\d+-\d+):(\d+):(\d+)\s+(\d+)\s+(.*)/;
				if (defined($pid) and defined($process)) {
					$proc->{$pid}->{'pid'} = $pid;
					## cputime is formed as [dd-]hh:mm:ss
					if ($hours =~ /(\d+)-(\d+)/) {
						$hours = ($2 + ($1 * 24));	## convert 'dd-hh' to days
					}
					my $cputime = (($hours * (60*60)) + ($minutes * 60) + $seconds) * 100; ## convert to centi-seconds per SNMP format
					$proc->{$pid}->{'perfcpu'} = $cputime;
					$proc->{$pid}->{'perfmem'} = $perfmem;
					if ($process =~ /(\S+)(\s(.*)|)/) {
						$proc->{$pid}->{'path'} = $1;
						$proc->{$pid}->{'args'} = $2;
						if ((riscUtility::checkfeature('no-process-args'))
							and ($proc->{$pid}->{'args'}))
						{
							$proc->{$pid}->{'args'} = $no_process_args_indicator;
						}
						$proc->{$pid}->{'name'} = $proc->{$pid}->{'path'};
						if ($proc->{$pid}->{'path'} =~ /^\//) {
							$proc->{$pid}->{'name'} =~ s/^.*[\/\\]//;
						}

					}
					$proc->{$pid}->{'runid'} = 0;
					if ($proc->{$pid}->{'perfmem'} == 0) {		## kernel threads won't use user memory, flag these as type OS
						$proc->{$pid}->{'runtype'} = 'operatingSystem';
					} else {
						$proc->{$pid}->{'runtype'} = 'application';
					}
					$proc->{$pid}->{'runstatus'} = 'running';
				} else {
					$failed_count++;
					$summary->{'error'} = "processes: failed to parse $failed_count entries";
				}
			}
			$localsummary->{'processes'} = $scantime unless ($failed_count);
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		my $psraw = $ssh->cmd('ps -e -o pid,cputime,rssize,args',{ 'vclass' => 'fail' });
		if ($psraw) {
			my @psraw = split(/\n/,$psraw);
			shift @psraw; ## header
			foreach my $line (@psraw) {
				my ($pid,$cpu,$rss,$cmd) = $line =~ /(\d+)\s+(\S+)\s+(\d+)\s+(.*)$/;
				$proc->{$pid}->{'pid'} = $pid;
				$proc->{$pid}->{'perfmem'} = $rss;
				my ($hour,$min,$sec) = split(/:/,$cpu);
				$proc->{$pid}->{'perfcpu'} = (($hour*(60*60)) + ($min*60) + $sec) * 100; ## centi-seconds
				my @proc = split(/\s+/,$cmd);
				my $name = $proc[0];
				$proc->{$pid}->{'path'} = $name;
				$name =~ s/^.*[\/\\]//;
				$proc->{$pid}->{'name'} = $name;
				shift @proc;
				$proc->{$pid}->{'args'} = join(" ",@proc);
				## static snmp stuff
				$proc->{$pid}->{'runid'} = 0;
				$proc->{$pid}->{'runstatus'} = 'running';
				$proc->{$pid}->{'runtype'} = 'application'; ## we requested only applications (not kernel stuff) in the ps commmand
			}
			$localsummary->{'processes'} = $scantime;
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	}
	dbg_dump('PROCESSES',$proc);
	my $processcount = keys %{$proc};
	dbg_dump('PROCESSCOUNT',$processcount);


	##
	# uptime (for traffic)
	##

	dbg('collecting uptime');
	if ($ssh->{'os'} eq 'Linux') {
		my $upraw = $ssh->cmd('cat /proc/uptime',{ 'vclass' => 'fail' });
		if ($upraw =~ /(\d+)\.(\d+)/) {
			$uptime = ceil("$1.$2");
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		## gets the elapsed time since init started
		## ostensibly, this was the boot time
		## the '=' trailing etime effectively disables the header
		my $upraw = $ssh->cmd('ps -o etime= -p1',{ 'vclass' => 'fail' });
		if ($upraw) {
			## format is: [[ dd-]hh:]mm:ss (man ps, etime)
			my $days = 0;
			my $hours = 0;
			my $min = 0;
			my $sec = 0;
			my @uptime = split(/:/,$upraw);
			my $numfields = scalar @uptime;
			if ($numfields > 2) { ## we have hours, and potentially days as well
				my $dayhour = $uptime[0];
				if ($dayhour =~ /-/) {
					($days,$hours) = $dayhour =~ /(\d+)-(\d+)/;
				} else {
					$hours = $dayhour;
				}
				$min = $uptime[1];
				$sec = $uptime[2];
			} else { ## we don't have hours, been up less than an hour
				$min = $uptime[0];
				$sec = $uptime[1];
			}
			$uptime = $sec + ($min*60) + ($hours*(60*60)) + ($days*(60*60*24));
		} else {
			abrt("failed to pull uptime");	##TODO handle this better? it's only needed for traffic
		}
	}
	dbg_dump('UPTIME',$uptime);


	##
	# traffic (network interfaces)
	##

	dbg('provisioning interface list from inventory for traffic');
	my $intfhash;
	$intfquery->execute($deviceid);
	while (my $v = $intfquery->fetchrow_hashref()) {
		$intfhash->{$v->{'description'}}->{'index'} = $v->{'intindex'};
		$intfhash->{$v->{'description'}}->{'adminstatus'} = $v->{'adminstatus'};
		$intfhash->{$v->{'description'}}->{'operstatus'} = $v->{'operstatus'};
	}
	dbg_dump('INTFHASH',$intfhash);
	$intfquery->finish();
	dbg('collecting traffic');
	if ($ssh->{'os'} eq 'Linux') {
		## the collection below using /proc/net/dev gets us most of the values,
		##   but we do not get adminstatus or txqueuelen; we need ifconfig for this
		## we used to use ifconfig $intf, but this differs from ifconfig in inventory,
		##   making sudo configuration more difficult than it needs to be
		dbg('pulling ifconfig for adminstatus and txqueuelen');
		my $ifconfig;
		my $raw_ifconfig = $ssh->cmd('LC_ALL=C ifconfig -a',{ 'priv' => 1, 'vclass' => 'fallback' });
		unless ($raw_ifconfig) {
			## commands typically located in /sbin may have issues with PATH on modern systems
			## try it by absolute path before giving up
			$raw_ifconfig = $ssh->cmd('LC_ALL=C /sbin/ifconfig -a',{ 'priv' => 1, 'vclass' => 'fail' });
		}
		if ($raw_ifconfig) {
			my @interfaces = split(/\n\n/,$raw_ifconfig);
			foreach my $interface (@interfaces) {
				my @lines = split(/\n/,$interface);
				my $first_line = $lines[0];
				my ($ifname) = $first_line =~ /^(\S+)\s/;
				$ifname =~ s/:$//;
				$ifconfig->{$ifname} = $interface;
			}
		}
		my $rawtraffic = $ssh->cmd('cat /proc/net/dev',{ 'vclass' => 'fail' });
		if ($rawtraffic) {
			my $is_actually_an_error = 0;
			my @rawtraffic = split(/\n/,$rawtraffic);
			shift @rawtraffic; ## throw away first header row
			shift @rawtraffic; ## throw away second header row
			foreach my $line (@rawtraffic) {
				$line =~ s/^\s+//; ## strip leading whitespace
				my @stat = split(/\s+/,$line);
				my ($intf) = $stat[0] =~ /(.*):$/;
				## handle the condition where no space between interface name and first column causes
				## us to incorrectly determine name, ie eth0:89798789
				unless ($intf) {
					if ($stat[0] =~ /.*:\d+/) {
						my $stat1;
						($intf,$stat1) = $stat[0] =~ /(.*):(\d+)/;
						shift @stat;
						unshift(@stat,$stat1);
						unshift(@stat,$intf);
					}

				}
				unless (($VALIDATE) or (defined($intfhash->{$intf}))) {
					dbg("skipping uninventoried network device: $intf");
					next;
				}
				my $idx = $intfhash->{$intf}->{'index'};
				$traf->{$idx}->{'name'} = $intf;
				$traf->{$idx}->{'rxbytes'} = $stat[1];
				$traf->{$idx}->{'rxpackets'} = $stat[2];
				$traf->{$idx}->{'rxerrors'} = $stat[3];
				$traf->{$idx}->{'rxdrops'} = $stat[4];
				$traf->{$idx}->{'rxfifo'} = $stat[5];
				$traf->{$idx}->{'rxframe'} = $stat[6];
				$traf->{$idx}->{'rxcompressed'} = $stat[7];
				$traf->{$idx}->{'rxmulticast'} = $stat[8];
				$traf->{$idx}->{'txbytes'} = $stat[9];
				$traf->{$idx}->{'txpackets'} = $stat[10];
				$traf->{$idx}->{'txerrors'} = $stat[11];
				$traf->{$idx}->{'txdrops'} = $stat[12];
				$traf->{$idx}->{'txfifo'} = $stat[13];
				$traf->{$idx}->{'txcollisions'} = $stat[14];
				$traf->{$idx}->{'txcarrier'} = $stat[15];
				$traf->{$idx}->{'txcompressed'} = $stat[16];
				$traf->{$idx}->{'operstatus'} = 'unknown';
				$traf->{$idx}->{'operstatus'} = $ssh->cmd("cat /sys/class/net/$intf/operstate",{ 'vclass' => 'fail' });
				## get adminstatus and queue length
				$traf->{$idx}->{'adminstatus'} = 'down';
				$traf->{$idx}->{'txqueuelen'} = 0;
				if ($ifconfig->{$intf}) {
					my @ifconfig = split(/\n/,$ifconfig->{$intf});
					foreach my $ifline (@ifconfig) {
						if ($ifline =~ /MTU/) { ## MTU identifies the options/flags line
							$ifline =~ s/^\s+//;
							my @intfopts = split(/\s+/,$ifline);
							if (grep {$_ eq 'UP'} @intfopts) {
								$traf->{$idx}->{'adminstatus'} = 'up';
							}
						}
						if ($ifline =~ /txqueuelen:(\d+)/) {
							$traf->{$idx}->{'txqueuelen'} = $1;
						}
					}
				} else {
					## this is set because 'ifconfig' failed, so we cannot get adminstatus or txqueuelen
					## consider traffic a failure, so the user can address the issue
					$is_actually_an_error = 1;
					$traf->{$idx}->{'adminstatus'} = 'unknown';
					$traf->{$idx}->{'txqueuelen'} = 0;
					$summary->{'error'} = 'traffic:ifconfig-failed';
				}
			}
			unless ($is_actually_an_error) {
				$localsummary->{'traffic'} = $scantime;
			}
		} else {
			$summary->{'error'} = $ssh->{'err'}->{'msg'};
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		## here we loop through our interfaces and do the requests for the traffic data
		## this allows us to keep track of which interfaces we received data for, and which we did not
		## if we failed to pull stats for any interfaces, we don't mark the summary good, and set the error
		##   to the list of interfaces we failed to pull
		my $intfdata;
		my $cmderror = 0;
		my $cmderror_str = "failed to pull interface stats for: ";
		foreach my $dev (keys %{$intfhash}) {
			next if ($dev =~ /^lo/);	## cannot query loopbacks, will error
			my $entstat = $ssh->cmd("entstat $dev",{ 'vclass' => 'fail' });
			if ($entstat) {
				$intfdata->{$dev} = $entstat;
			} else {
				$cmderror++;
				$cmderror_str .= " $dev";
			}
		}
		foreach my $dev (keys %{$intfdata}) {
			my $raw = $intfdata->{$dev};
			my @raw = split(/\n/,$raw);
			foreach my $line (@raw) {
				my $idx = $intfhash->{$dev}->{'index'};
				$traf->{$idx}->{'adminstatus'} = $intfhash->{$dev}->{'adminstatus'};
				$traf->{$idx}->{'operstatus'} = $intfhash->{$dev}->{'operstatus'};
				if ($line =~ /^Packets: (\d+)\s+Packets: (\d+)$/) {
					$traf->{$idx}->{'txpackets'} = $1;
					$traf->{$idx}->{'rxpackets'} = $2;
				}
				if ($line =~ /^Bytes: (\d+)\s+Bytes: (\d+)$/) {
					$traf->{$idx}->{'txbytes'} = $1;
					$traf->{$idx}->{'rxbytes'} = $2;
				}
				if ($line =~ /Transmit Errors: (\d+)\s+Receive Errors: (\d+)$/) {
					$traf->{$idx}->{'txerrors'} = $1;
					$traf->{$idx}->{'rxerrors'} = $2;
				}
				if ($line =~ /Packets Dropped: (\d+)\s+Packets Dropped: (\d+)$/) {
					$traf->{$idx}->{'txdrops'} = $1;
					$traf->{$idx}->{'rxdrops'} = $2;
				}
				if ($line =~ /^Current S\/W\+H\/W Transmit Queue Length: (\d+)/) {
					$traf->{$idx}->{'txqueuelen'} = $1;
				}
			}
		}
		if ($cmderror) {
			$summary->{'error'} = $cmderror_str;
		} else {
			$localsummary->{'traffic'} = $scantime;
		}
	}
	dbg_dump('TRAFFIC',$traf);

	dbg('completed collection');

	##
	# finish validation, if running
	##

	if ($VALIDATE) {
		## roll through logged commands
		$validator->log("<table>\n",0);
		foreach my $cmd (@{$ssh->{'validator_commands'}}) {
			my $command	= $cmd->{'command'};
			my $result	= $cmd->{'result'};
			$validator->log("<tr><td class='validation-command'>$command</td><td class='$result'>$result</td></tr>\n",1);
		}
		$validator->log("</table>\n",0);
		## prepare failure results, if any
		if (($ssh->{'validator_errors'}) and (scalar @{$ssh->{'validator_errors'}} > 0)) {
			my $failure_condition;
			foreach my $fail (@{$ssh->{'validator_errors'}}) {
				my $result = $fail->{'class'};
				$failure_condition .=<<END;
<p><table>
	<tr><td class='with-border'>Reason</td><td class='$result'>Command Failure</td></tr>
	<tr><td class='with-border'>Result</td><td class='$result'>$result</td></tr>
	<tr><td class='with-border'>Command</td><td class='validation-command'><pre>$fail->{'command'}</pre></td></tr>
	<tr><td class='with-border'>Exit Code</td><td><pre>$fail->{'code'}</pre></td></tr>
	<tr><td class='with-border'>Standard Output</td><td class='validation-command'><pre>$fail->{'out'}</pre></td></tr>
	<tr><td class='with-border'>Standard Error</td><td class='validation-command'><pre>$fail->{'err'}</pre></td></tr>
</table></p>
END
			}
			print STDOUT "$failure_condition";
		}
		$validator->exit();
	}

	##
	# data insertion
	##

	if ($noinsert) {
		dbg("skipping insertion");
		$mysql->disconnect();
		exit(0);
	}

	## disable local alarm, so we don't self destruct during insert
	dbg('removing local alarm');
	alarm 0;

	dbg('preparing insert statements');

	my $insertcpu = $mysql->prepare("INSERT INTO gensrvperfcpu (deviceid,cpuindex,cpunames,cpuload,cpuerrorflag,cpuerrormsg,scantime) VALUES (?,?,?,?,?,?,?)");
	my $insertmem = $mysql->prepare("INSERT INTO gensrvperfmem (deviceid,totalswap,availswap,totalreal,availreal,minimumswap,memshared,membuffer,memcached,memswaperror,memswaperrormsg,scantime) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
	my $insertdisk = $mysql->prepare("INSERT INTO gensrvperfdisk (deviceid,storageindex,storagesize,storageused,scantime) VALUES (?,?,?,?,?)");
	my $insertdiskio = $mysql->prepare("INSERT INTO gensrvperfdiskio (deviceid,scantime,diskindex,diskiodevice,diskiobytesread,diskiobyteswrite,diskioreads,diskiowrites) VALUES (?,?,?,?,?,?,?,?)");
	my $insertdiskiops = $mysql->prepare("INSERT INTO gensrvperfdiskio_persecond (deviceid,scantime,diskindex,diskiodevice,diskiotps,diskiorps,diskiowps,diskiobytesps,diskiobytesrps,diskiobyteswps) VALUES (?,?,?,?,?,?,?,?,?,?)");
	my $insertconn = $mysql->prepare("INSERT INTO windowsconnection (deviceid,scantime,protocol,laddr,lport,faddr,fport,state,pid) VALUES (?,?,?,?,?,?,?,?,?)");
	my $insertproc = $mysql->prepare("INSERT INTO gensrvprocesses (deviceid,swrunindex,swrunname,swrunid,swrunpath,swrunparameters,swruntype,swrunstatus,swrunperfcpu,swrunperfmem,scantime) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
	my $inserttraf = $mysql->prepare("INSERT INTO traffic_raw (deviceid,intindex,bytesin,bytesout,packetsin,packetsout,discardsin,discardsout,errorsin,errorsout,outqlength,status,adminstatus,sysuptime,scantime,valuetype)
						VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'absolute')");

	dbg('inserting cpu');
	##NOTE we insert 2 as the cpuindex, as cloudCalc expects it (holdover from previous collection of load average)
	$insertcpu->execute($deviceid,2,undef,$cpu->{'busy'},undef,undef,$scantime);
	$summary->{'cpu'} = $localsummary->{'cpu'};
	$insertcpu->finish();

	dbg('inserting mem');
	$insertmem->execute($deviceid,$mem->{'swaptotal'},$mem->{'swapfree'},$mem->{'total'},$mem->{'free'},$mem->{'swapmin'},$mem->{'shared'},$mem->{'buffer'},$mem->{'cache'},$mem->{'swaperr'},$mem->{'swaperrmsg'},$scantime);
	$summary->{'mem'} = $localsummary->{'mem'};
	$insertmem->finish();

	dbg('inserting diskutil');
	foreach my $mp (keys %{$diskutil}) {
		$insertdisk->execute($deviceid,$diskutil->{$mp}->{'index'},$diskutil->{$mp}->{'size'},$diskutil->{$mp}->{'used'},$scantime);
	}
	$summary->{'diskutil'} = $localsummary->{'diskutil'};
	$insertdisk->finish();

	dbg('inserting diskio');
	my $diskindex = 0; ## this is arbitrary, as it doesn't seem to map to anything in SNMP
	foreach my $dsk (sort keys %{$diskio}) {
		$insertdiskio->execute($deviceid,$scantime,$diskindex++,$dsk,$diskio->{$dsk}->{'readbytes'},$diskio->{$dsk}->{'writebytes'},$diskio->{$dsk}->{'reads'},$diskio->{$dsk}->{'writes'});
	}
	$insertdiskio->finish();

	## insert persecond disk IO if populated (ie, AIX)
	## also insert a record into the gensrvperfdiskio with invalid values (-1) to indicate to agg that it needs to check the persecond table for values
	dbg('inserting diskio-persecond');
	$diskindex = 0;
	foreach my $dsk3 (sort keys %{$diskiops}) {
		$insertdiskio->execute($deviceid,$scantime,$diskindex,$dsk3,-1,-1,-1,-1);
		$insertdiskiops->execute($deviceid,$scantime,$diskindex++,$dsk3,$diskiops->{$dsk3}->{'tps'},$diskiops->{$dsk3}->{'rps'},$diskiops->{$dsk3}->{'wps'},$diskiops->{$dsk3}->{'bytesps'},$diskiops->{$dsk3}->{'bytesrps'},$diskiops->{$dsk3}->{'byteswps'});
	}
	$insertdiskiops->finish();
	$summary->{'diskio'} = $localsummary->{'diskio'};

	dbg('inserting processes');
	foreach my $p (keys %{$proc}) {
		$insertproc->execute($deviceid,$proc->{$p}->{'pid'},$proc->{$p}->{'name'},0,$proc->{$p}->{'path'},$proc->{$p}->{'args'},$proc->{$p}->{'runtype'},$proc->{$p}->{'runstatus'},$proc->{$p}->{'perfcpu'},$proc->{$p}->{'perfmem'},$scantime);
	}
	$summary->{'processes'} = $localsummary->{'processes'};
	$insertproc->finish();

	dbg('inserting netstat');
	foreach my $c (@connections) {
		$insertconn->execute($deviceid,$scantime,$c->{'proto'},$c->{'laddr'},$c->{'lport'},$c->{'faddr'},$c->{'fport'},$c->{'state'},$c->{'pid'});
	}
	$summary->{'netstat'} = $localsummary->{'netstat'};
	$summary->{'rfc4022'} = $localsummary->{'rfc4022'};
	$insertconn->finish();

	dbg('inserting traffic');
	foreach my $i (keys %{$traf}) {
		$inserttraf->execute($deviceid,
					$i,
					$traf->{$i}->{'rxbytes'},
					$traf->{$i}->{'txbytes'},
					$traf->{$i}->{'rxpackets'},
					$traf->{$i}->{'txpackets'},
					$traf->{$i}->{'rxdrops'},
					$traf->{$i}->{'txdrops'},
					$traf->{$i}->{'rxerrors'},
					$traf->{$i}->{'txerrors'},
					$traf->{$i}->{'txqueuelen'},
					$traf->{$i}->{'operstatus'},
					$traf->{$i}->{'adminstatus'},
					$uptime,
					$scantime
				);
	}
	$summary->{'traffic'} = $localsummary->{'traffic'};

	RISC::Collect::PerfSummary::set($mysql,$summary);

	## look in the running process data for interesting services
	## store these as quirks for potential configuration file collection
	dbg('detecting services for quirks');
	my %services;
	my $services = detect_services(
		$os,
		[ map {
			join(' ', $proc->{$_}->{'path'}, $proc->{$_}->{'args'})
		} (keys %{ $proc }) ]
	);

	if ($services) {
		my $quirks = RISC::Collect::Quirks->new({ db => $mysql });
		my $q = $quirks->get($deviceid);
		$quirks->post($deviceid, {
			($q) ? %{ $q } : ( ),
			%{ $services }
		});
	}

	dbg('complete');

}; if ($@) {	## end major collection block eval
	## here, we have encountered an exception during collection or insert
	## we need to ensure that we commit our perfsummary record,
	##  with an appropriate error message
	dbg('entering major exception block');
	my $is_timeout = 0;
	my $is_command = 0;
	chomp(my $failure = $@);
	if ($failure =~ /RISCTIMEOUT/) {	## local timeout
		out('local timeout');
		$failure = 'local timeout';
		$is_timeout = 1;
	} elsif ($@ =~ /SIGTERM/) {		## admin script killed us on timeout
		out('batch timeout');
		$failure = 'batch timeout';
		$is_timeout = 1;
	} elsif ($@ =~ /^command abort/) {	## command failed and abrt() called
		out('command abort');
		$is_command = 1;
	} else {
		out("exception: $failure");	## runtime fault
	}
	if ($VALIDATE) {
		$validator->log("<table>\n",0);
		foreach my $cmd (@{$ssh->{'validator_commands'}}) {
			my $command	= $cmd->{'command'};
			my $result	= $cmd->{'result'};
			$validator->log("<tr><td class='validation-command'>$command</td><td class='$result'>$result</td></tr>\n",1);
		}
		$validator->log("</table>\n",0);
		$validator->finish();
		## prepare failure results, if any
		if ($is_timeout) {
			$validator->report_timeout_failure();
			$validator->cmdstatus('fail');
		} else {
			$validator->report_exception_failure();
			$validator->cmdstatus('fail');
		}
		if (($ssh->{'validator_errors'}) and (scalar @{$ssh->{'validator_errors'}} > 0)) {
			my $failure_condition;
			foreach my $fail (@{$ssh->{'validator_errors'}}) {
				my $result = $fail->{'class'};
				$failure_condition .=<<END;
<p><table>
	<tr><td class='with-border'>Reason</td><td class='$result'>Command Failure</td></tr>
	<tr><td class='with-border'>Command Class</td><td class='$result'>$result</td></tr>
	<tr><td class='with-border'>Command</td><td class='validation-command'><pre>$fail->{'command'}</pre></td></tr>
	<tr><td class='with-border'>Exit Code</td><td><pre>$fail->{'code'}</pre></td></tr>
	<tr><td class='with-border'>Standard Output</td><td class='validation-command'><pre>$fail->{'out'}</pre></td></tr>
	<tr><td class='with-border'>Standard Error</td><td class='validation-command'><pre>$fail->{'err'}</pre></td></tr>
</table></p>
END
			}
			print STDOUT "$failure_condition";
		}
		$validator->exit();
	} else {
		$summary->{'error'} = $failure;
		RISC::Collect::PerfSummary::set($mysql,$summary);
	}
	dbg('exiting with failure');
	exit(1);
}

dbg('exiting with success');
exit(0);

## finish

## utility subs ##
sub abrt {
	my ($str) = @_;
	chomp($str);
	my $last = $ssh->lastcmd();
	print STDERR "$0::main::${target}::ABORT: $str\n";
	$ssh->print_error();
	die "command abort: '$last->{'command'}'\n";
}

sub out {
	my ($str) = @_;
	return if ($VALIDATE);
	chomp($str);
	print "$0::main::${target}::INFO: $str\n";
}

sub dbg {
	my ($str) = @_;
	return if ($VALIDATE);
	return unless ($debugging);
	chomp($str);
	print STDERR "$0::main::${target}::DEBUG: $str\n";
}

sub dbg_dump {
	my ($header,$data) = @_;
	return unless ($debugging >= 2);
	print STDERR "$0::main::${target}::DUMP: $header: " . Dumper($data);
}

## returns true if the provided disk device is one we care about
sub check_diskio_device {
	my $dev = shift;

	## check first for virtual devices
	if (($dev =~ /ram/) or ($dev =~ /^loop/) or ($dev =~ /^pass/) or ($dev =~ /^dm-/)) {
		return 0;
	## now check for non-disk storage devices, ie floppy/optical drives
	} elsif (($dev =~ /^fd/) or ($dev =~ /^cd/) or ($dev =~ /^sr/)) {
		return 0;
	## now check for valid normal disk names
	} elsif (($dev =~ /^(h|s|v|xv)d[a-z]+$/) or ($dev =~ /^(a|)da\d+$/) or ($dev =~ /^xbd\d+$/) or ($dev =~ /^sd\d+$/)) {
		return 1;
	## now check for devices under RAID controllers
	} elsif (($dev =~ /cciss\/c\d+d\d+$/)) {
		return 1;
	## everything else
	} else {
		return 0;
	}
}

sub si_to_base_b10 {
	my ($value) = @_;
	if ($value =~ /(.*)K$/) {
		return $1 * 1000;
	} elsif ($value =~ /(.*)M$/) {
		return $1 * 1000 * 1000;
	} elsif ($value =~ /(.*)G$/) {
		return $1 * 1000 * 1000 * 1000;
	} elsif ($value =~ /(.*)T$/) {
		return $1 * 1000 * 1000 * 1000 * 1000;
	}
	return $value;
}
