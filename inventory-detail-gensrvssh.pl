#!/usr/bin/perl
#
##
use strict;
use Data::Dumper;
use POSIX;
use Switch;
use Net::IP qw( ip_expand_address ip_is_ipv6 );
use RISC::Collect::Constants qw( :status :bool :userlog );
use RISC::riscCreds;
use RISC::riscUtility;
use RISC::riscSSH;
use RISC::CollectionValidation;
use RISC::Collect::Logger;
use RISC::Collect::UserLog;
use RISC::Collect::DatasetLog;
use LWP::Simple qw($ua get head);

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse	= 1;

my $cyberark_ssh = (-f "/etc/risc-feature/cyberark-ssh" && -f "/home/risc/conf/cyberark_config.json");

my $noinsert = 0;
$noinsert = $ENV{'NOINSERT'} if (defined($ENV{'NOINSERT'}));

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

## collection validation mode
## the value of the VALIDATE environment variable should be
##   the path to the log file we'll write our data to
## if using validation mode, the $credid argument will be
##   the single-quoted, space-separated list of credential
##   fields in base64, being the same that is passed to the
##   simple credential test facility via the web UI
my $VALIDATE = 0;
$VALIDATE = $ENV{'VALIDATE'} if ($ENV{'VALIDATE'});

## control whether inventory stops on a command failure abort
## the default is overridden by VALIDATE (sets to on)
## the DONTSTOP environment variable overrides all other settings
my $dontstop = 0;
$dontstop = 1 if ($VALIDATE);
$dontstop = $ENV{'DONTSTOP'} if (defined($ENV{'DONTSTOP'}));

my $do_inventory_processes = 1;	## collect running processes, default setting
my $no_process_args_indicator = '(RN150: process argument collection opted out)';

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

my $logger = RISC::Collect::Logger->new(join('::',
	'inventory',
	'gensrvssh',
	$deviceid,
	$target
));

if ($VALIDATE) {
	## disable SCREEN appender in validation mode, to avoid polluting the report
	## NOTE: no logging statements before this block
	Log::Log4perl->eradicate_appender('SCREEN');
}

$logger->info('begin');

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
my $vexplore	= $validator->cmdstatus_name('explore');

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

my $ul = RISC::Collect::UserLog
	->new({ db => $mysql, logger => $logger })
	->context('inventory')
	->collection_id($deviceid);

## inventory log
my $invlog;
my $invlogtime = time();
unless ($VALIDATE) {
	$logger->debug('fetching inventory log');
	$invlog = riscUtility::getInventoryLog($mysql,$deviceid,$target);
	$invlog->{'ipaddress'} = $target;
	$invlog->{'attempt'} = $invlogtime;
}

## dataset_log
my $dl;
unless ($VALIDATE) {
	$dl = {
		inventory => RISC::Collect::DatasetLog->new(
			$deviceid,
			'inventory',
			{ db => $mysql, logger => $logger }
		),
		installedsoftware => RISC::Collect::DatasetLog->new(
			$deviceid,
			'installedsoftware',
			{ db => $mysql, logger => $logger }
		)
	};
}

## provision credential
my $cred;
my $credobj = riscCreds->new($target);
if ($VALIDATE) {
	my ($username,$ctx,$auth,$port,$priv,$keypass) = split(/\s+/,$credid);
	## Get creds if using CyberArk
	if ($cyberark_ssh) {
		my $credSet = $credobj->getGenSrvSSHCyberArkQueryString($auth);
		unless ($credSet) {
			my $errmsg = 'Failed to fetch credential: '. $credobj->get_error();
			$logger->error($errmsg);

			$validator->log("<h3>INVENTORY</h3>\n", 0);
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
		$logger->error(sprintf(
			'failed to retreive credential: %s',
			$credobj->get_error()
		));
		$ul->critical('Failed to fetch credential', 'runtime-error');
		exit(EXIT_FAILURE);
	}
}
$credobj->disconnect();

## start validation log data
$validator->log("<h3>INVENTORY</h3>\n",0);
$validator->log("<table>\n",0);
$validator->log("<tr><td>Connect</td>",1);

## SSH connection
my $ssh = RISC::riscSSH->new({
	'debug'			=> $debugging,
	'specify_skip_db'	=> 1,
	'logger'		=> $logger,
	'validator'		=> $validator,
	'autospecify'	=> !$VALIDATE # disable this for validation
});
$ssh->connect($target,$cred);
unless($ssh->{'connected'}) {
	$logger->error('connect() failed: ' . $ssh->get_error());
	if ($VALIDATE) {
		$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
		$validator->log("</table>\n",0);
		$validator->report_connection_failure($ssh->get_error());
		$validator->finish();
		$validator->exit('fail');
	} else {
		$ul->error(
			sprintf('Failed SSH connection: %s', $ssh->clean_ssh_error()),
			'not-accessible'
		);
		$invlog->{'decom'} = 1;
		riscUtility::updateInventoryLog($mysql,$invlog);
		exit(EXIT_FAILURE);
	}
}
$validator->log("<td class='$vsuccess'>$vsuccess</td></tr>\n",0);
$validator->log("<tr><td>Supported OS</td>",1);

$invlog->{'decom'} = 0;

if($VALIDATE) {
	## run specify() manually so we can capture the error
	$ssh->specify();
	if($ssh->get_error()) {
		$logger->error('specify() failed: ' . $ssh->get_error());
		$validator->log("<td class='$vfail'>$vfail</td></tr>",0);
		$validator->log("</table>\n",0);
		$validator->finish();
		$validator->report_connection_failure($ssh->get_error());
		$validator->exit('fail');
	}
}

## abort if we are not running against a supported OS
unless ($ssh->supported_os()) {
	$logger->error(sprintf('supported_os() failed: unsupported os "%s"', $ssh->{'os'}));
	if ($VALIDATE) {
		$validator->log("<td class='$vfail'>$vfail</td></tr>",0);
		$validator->log("</table>\n",0);
		$validator->finish();
		$validator->report_supported_os_failure($ssh->{'os'});
		$validator->exit('fail');
	} else {
		## here we don't call abrt(), as it will try to finish queries we havent prepared yet
		$ul->error(sprintf('Unsupported operating system: %s', $ssh->{'os'}), 'not-eligible');
		riscUtility::updateInventoryLog($mysql,$invlog);
		exit(EXIT_FAILURE);
	}
}

$validator->log("<td class='$vsuccess'>$vsuccess ($ssh->{'os'})</td></tr>\n",0);
if ($ssh->{'os_dist'}) {
	$validator->log("<tr><td>Distribution</td><td class='$vsuccess'>$vsuccess ($ssh->{'os_dist'})</td></tr>\n",1);
} else {
	$validator->log("<tr><td>Distribution</td><td class='$vfail'>$vfail</td></tr>\n",1);
	$validator->exitstatus('incomplete');
}

unless ($ssh->privtest()) {
	my $last = $ssh->lastcmd();
	$logger->error(sprintf('privtest() failed cmd (%s): %s', $last->{'command'}, $ssh->get_error()));
	if ($VALIDATE) {
		$validator->log("<tr><td>Privileged Access</td><td class='$vfail'>$vfail</td></tr>\n",1);
		$validator->log("</table>\n",0);
		$validator->finish();
		$validator->report_privilege_failure($last->{'command'},$ssh->get_error());
		$validator->exit('fail');
	} else {
		$ul->error(
			sprintf('Failed privileged access test: %s', $ssh->clean_ssh_error()),
			'bad-configuration'
		);
		riscUtility::updateInventoryLog($mysql,$invlog);
		exit(EXIT_FAILURE);
	}
}

if ($ssh->priv_disable()) {
	$validator->log("<tr><td>Privileged Access</td><td class='$vexplore'>SKIPPED</td></tr>\n",1);
} else {
	$validator->log("<tr><td>Privileged Access</td><td class='$vsuccess'>$vsuccess</td></tr>\n",1);
}
$validator->log("</table>\n",0);

##
#TODO: consider using temporary tables and inserting as we go instead of holding everything in memory and inserting at the end
##

## existing table queries
my $gensrvserver = $mysql->prepare("INSERT INTO gensrvserver (deviceid,uptime,processes,memorysize,numberofusers,numcpus,numcores,freq) VALUES (?,?,?,?,?,?,?,?)");
my $snmpsysinfo = $mysql->prepare("INSERT INTO snmpsysinfo (deviceid,sysdescription,sysuptime,syscontact,sysname,syslocation,sysservices,sysoid) VALUES (?,?,?,?,?,?,?,?)");
my $ssh_inv_hardware = $mysql->prepare("INSERT INTO ssh_inv_hardware (deviceid,scantime,product_vendor,product_name,product_ver,product_serial,product_uuid,chassis_vendor,chassis_ver,chassis_serial,bios_vendor,bios_ver,bios_date)
						VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $gensrvdevice = $mysql->prepare("INSERT INTO gensrvdevice (deviceid,devtype,devdescription,devid,devstatus,deverrors) VALUES (?,?,?,?,?,?)");
my $gensrvstorage = $mysql->prepare("INSERT INTO gensrvstorage (deviceid,storageindex,storagetype,storagedescription,storageallocationUnits,storagesize,storageused) VALUES(?,?,?,?,?,?,?)");
my $gensrvpartition = $mysql->prepare("INSERT INTO gensrvpartition (deviceid,partitionindex,partitionlabel,partitionid,partitionsize,partitionfsindex) VALUES (?,?,?,?,?,?)");
my $gensrvfilesystem = $mysql->prepare("INSERT INTO gensrvfilesystem (deviceid,fsindex,fsmountpoint,fsremotemountpoint,fstype,fsaccess,fsbootable,fsstorageindex,lastfullbackupdate,lastpartialbackupdate) VALUES (?,?,?,?,?,?,?,?,?,?)");
my $gensrvprocesses = $mysql->prepare("INSERT INTO gensrvprocesses (deviceid,swrunindex,swrunname,swrunid,swrunpath,swrunparameters,swruntype,swrunstatus,swrunperfcpu,swrunperfmem,scantime) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
my $interfaces = $mysql->prepare("INSERT INTO interfaces (deviceid,name,description,type,speed,intindex,mac,adminstatus,operstatus) VALUES (?,?,?,?,?,?,?,?,?)");
my $iptables = $mysql->prepare("INSERT INTO iptables (deviceid,ip,netmask,intindex) VALUES (?,?,?,?)");
my $insert_http_get_inventory = $mysql->prepare("INSERT INTO http_get_inventory (deviceid,protocol,content_type,webserver,content) VALUES (?,?,?,?,?)");

## new table queries
my $insert_inv_detail = $mysql->prepare("INSERT INTO ssh_inv_detail (deviceid,ip,hostname,os,osversion,arch,dist_full,dist_tag,dist_version,profile,ssh_version,sysdescr,scantime)
						VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
						ON DUPLICATE KEY UPDATE
						hostname=?,os=?,osversion=?,arch=?,dist_full=?,dist_tag=?,dist_version=?,profile=?,ssh_version=?,sysdescr=?,scantime=?");

$validator->log("<h4>INVENTORY COMMANDS</h4>\n",0);

my $scantime = time();
my $storage_index = 1; ## this keeps a running index of our storage devices

## if we're running against AIX, go ahead and pull a couple of commands we'll refer to later and pack them in the object
if ($ssh->{'os'} eq 'AIX') {
	## lsdev -- gets us all logical devices
	my $rawlsdev = $ssh->cmd('env LC_ALL=C lsdev',{ 'vclass' => 'fail' });
	if ($rawlsdev) {
		my @rawlsdev = split(/\n/,$rawlsdev);
		foreach my $d (@rawlsdev) {
			my ($node,$status,$trash,$descr) = $d =~ /(\S+)\s+(\S+)\s+(\S+|)\s+(.*)$/;
			$ssh->{'lsdev'}->{$node}->{'dev'} = $node;
			$ssh->{'lsdev'}->{$node}->{'descr'} = $descr;
			if ($status eq 'Available') {
				$ssh->{'lsdev'}->{$node}->{'status'} = 1;
			} else {
				$ssh->{'lsdev'}->{$node}->{'status'} = 0;
			}
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'lsdev',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}

	## iostat, which has a surprising amount of good info
	my $iostat;
	my $raw = $ssh->cmd('env LC_ALL=C iostat');
	if ($raw) {
		($iostat->{'lcpu'}) = $raw =~ /lcpu=(\d+)/;
		($iostat->{'drives'}) = $raw =~ /drives=(\d+)/;
		($iostat->{'vdisks'}) = $raw =~ /vdisks=(\d+)/;
		my $i = 0;
		my @raw = split(/\n/,$raw);
		foreach my $line (@raw) {
			if ($line =~ /avg-cpu/) {
				my $d = $raw[$i + 1];
				my @d = split(/\s+/,$d);
				$iostat->{'cpu'}->{'user'} = $d[3];
				$iostat->{'cpu'}->{'sys'} = $d[4];
				$iostat->{'cpu'}->{'idle'} = $d[5];
				shift (@raw);
			}
			if ($line =~ /^Disks/) {
				my $d = $raw[$i + 1];
				my @d = split(/\s+/,$d);
				$iostat->{'disks'}->{$d[0]}->{'tm_acct'} = $d[1];
				$iostat->{'disks'}->{$d[0]}->{'Kbps'} = $d[2];
				$iostat->{'disks'}->{$d[0]}->{'tps'} = $d[3];
				$iostat->{'disks'}->{$d[0]}->{'Kb_read'} = $d[4];
				$iostat->{'disks'}->{$d[0]}->{'Kb_wrtn'} = $d[5];
				shift (@raw);
			}
			$i++;
		}
		$ssh->{'iostat'} = $iostat;
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'iostat',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}

## uptime
#
##
my $uptime;
if ($ssh->{'os'} eq 'Linux') {
	my $upraw = $ssh->cmd('cat /proc/uptime',{ 'vclass' => 'fail' });
	if ($upraw) {
		if ($upraw =~ /(\d+)\.(\d+)/) {
			$uptime = ceil("$1.$2");
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'cat /proc/uptime',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	## gets the elapsed time since init started
	## ostensibly, this was the boot time
	## the '=' trailing etime effectively disables the header
	my $upraw = $ssh->cmd('env LC_ALL=C ps -o etime= -p1',{ 'vclass' => 'fail' });
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
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'ps -o etim= -p1',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
dbg_dump(($uptime * 100),'UPTIME');

## hostname
#
##
my $hostname = $ssh->hostname();
unless ($hostname) {
	my $error = sprintf(
		q(Failed the command '%s': %s),
		'uname -n',
		$ssh->clean_ssh_error()
	);
	$ul->error($error, 'query-failure');
	abrt($error);
}
dbg_dump($hostname,'HOSTNAME');

## os type OID
my $sysoid = $ssh->map_os_oid($ssh->{'os'});
dbg_dump($sysoid,'SYSOID');

## logged in users
#
##
my $numusers;
my $logins = $ssh->cmd('w -h',{ 'vclass' => 'explore' });
if ($logins) {
	my @numusers = split(/\n/,$logins);
	$numusers = scalar(@numusers);
} else {
	$numusers = 0; ## on failure just set 0, this isn't important enough to abort
}
dbg_dump($numusers,'NUMUSERS');

## hardware
#
##
my $hardware = {};
# only x86, ia64, and some arm systems support DMI. ibm z and ibm power are likely to be encountered, so don't error out (or even attempt) there.
if ($ssh->{'os'} eq 'Linux' && $ssh->{'arch'} !~ /^(s390|ppc)/) {
	$hardware = $ssh->linux_hardware();
}
dbg_dump($hardware,'HARDWARE');

## memory
#
##
my $mem;
if ($ssh->{'os'} eq 'Linux') {
	my $memraw = $ssh->cmd('cat /proc/meminfo',{ 'vclass' => 'fail' });
	if ($memraw) {
		if ($memraw =~ /MemTotal:\s+(\d+)/) {
			$mem->{'real'} = $1;
		}
		if ($memraw =~ /MemFree:\s+(\d+)/) {
			$mem->{'free'} = $1;
			$mem->{'used'} = $mem->{'real'} - $mem->{'free'};
		}
		if ($memraw =~ /Cached:\s+(\d+)/) {
			$mem->{'cached'} = $1;
		}
		if ($memraw =~ /Buffers:\s+(\d+)/) {
			$mem->{'buf'} = $1;
		}
		if ($memraw =~ /Shmem:\s+(\d+)/) {
			$mem->{'shared'} = $1;
		}
		if ($memraw =~ /SwapTotal:\s+(\d+)/) {
			$mem->{'swaptotal'} = $1;
		}
		if ($memraw =~ /SwapCached:\s+(\d+)/) {
			$mem->{'swapused'} = $1;
		}
		$mem->{'virt'} = $mem->{'real'} + $mem->{'swaptotal'};
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'cat /proc/meminfo',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	## since for now we're only storing realmem and that's easy to get, don't bother with the rest for now
	## should return it to us in KiB
	my $memraw = $ssh->cmd('env LC_ALL=C lsattr -E -l sys0 -a realmem',{ 'vclass' => 'fail' });
	if ($memraw) {
		($mem->{'real'}) = $memraw =~ /realmem (\d+)/;
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'lsattr -E -l sys0 -a realmem',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
dbg_dump($mem,'MEMORY');

## processes
#
## the 'inventory-process-collection' feature flag controls whether we pull this data
## the 'no-process-args' feature flag controls whether we record process arguments, in
##   order to mitigate against collecting sensitive data such as passwords
my $proc;

my $feature_do_inventory_processes = riscUtility::checkfeature('inventory-process-collection');
if (defined($feature_do_inventory_processes)) {
	$do_inventory_processes = $feature_do_inventory_processes;
}

my $processcount;
if ($do_inventory_processes) {
	if ($ssh->{'os'} eq 'Linux') {
		my $psraw = $ssh->cmd('ps axwww --no-headers -o pid,cputime,rsz,command',{ 'vclass' => 'fail' });
		if ($psraw) {
			my @lines = split(/\n/,$psraw);
			foreach my $line (@lines) {
				if ($line =~ /(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)\s+(.*)/) {
					my $pid = $1;
					$proc->{$pid}->{'pid'} = $pid;
					my $hours = $2;
					my $minutes = $3;
					my $seconds = $4;
					my $cputime = (($hours * (60*60)) + ($minutes * 60) + $seconds) * 100; ## convert to centi-seconds per SNMP format
					$proc->{$pid}->{'perfcpu'} = $cputime;
					$proc->{$pid}->{'perfmem'} = $5;
					my $process = $6;
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
				}
			}
		} else {
			my $error = sprintf(
				q(Failed the command '%s': %s),
				'ps axwww --no-headers -o pid,cputime,rsz,command',
				$ssh->clean_ssh_error()
			);
			$ul->error($error, 'query-failure');
			abrt($error);
		}
	} elsif ($ssh->{'os'} eq 'AIX') {
		my $psraw = $ssh->cmd('env LC_ALL=C ps -e -o pid,cputime,rssize,args',{ 'vclass' => 'fail' });
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
		} else {
			my $error = sprintf(
				q(Failed the command '%s': %s),
				'ps -e -o pid,cputime,rssize,args',
				$ssh->clean_ssh_error()
			);
			$ul->error($error, 'query-failure');
			abrt($error);
		}
	}
	$processcount = keys %{$proc};
	dbg_dump($proc,'PROCESSES',2);
} else {
	$processcount = 0;
}
dbg_dump($processcount,'PROCESSCOUNT');

## CPU
#
## terminology:
###  packages:	physical chips that are plugged into sockets
###  physcores:	physical cores on a system
###  cores:	logical cores on a system (may be equal to cores, or twice if hyperthreaded)
my $cpu;
if ($ssh->{'os'} eq 'Linux') {
	my $out = $ssh->cmd('cat /proc/cpuinfo',{ 'vclass' => 'fail' });

	if (!defined($out) || !length($out)) {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'cat /proc/cpuinfo',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
	elsif ($out =~ /^vendor_id\s*:\s*IBM\/S390/s) {
		# taken from https://en.wikipedia.org/wiki/IBM_Z
		# mhz isn't a good measure but better than bogomips
		my %s390_models = (
			# model type => cpu mhz
			'8561' => 5200, # z15
			'3907' => 5200, # z14 ZR1
			'3906' => 5200, # z14
			'2965' => 5000, # z Systems z13s
			'2964' => 5000, # z Systems z13
			'2828' => 4200, # zEnterprise BC12
			'2827' => 5500, # zEnterprise EC12
			'2818' => 3800, # zEnterprise z114
			'2817' => 5200, # zEnterprise z196
			'2098' => 4400, # z10 Business Class
			'2097' => 4400, # z10 Enterprise Class
			#'2096' => ?, # z9 Business Class
			#'2094' => ?, # z9 Enterprise Class
		);
=pod
# cat /proc/cpuinfo
vendor_id : IBM/S390
processors : 2
bogomips per cpu: 309.00
features : esan3 zarch stfle msa ldisp eimm dfp etf3eh highgprs
processor 0: version = FF, identification = 012345, machine = 2818
processor 1: version = FF, identification = 112345, machine = 2818

# cat /proc/cpuinfo
vendor_id       : IBM/S390
# processors    : 4
bogomips per cpu: 3241.00
max thread id   : 0
features	: esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx vxd vxe gs vxe2 vxp sort dflt 
facilities      : 0 1 2 3 4 6 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 30 31 32 33 34 35 36 37 38 40 41 42 43 44 45 47 48 49 50 51 52 53 54 57 58 59 60 61 64 69 71 73 74 75 76 77 78 80 81 82 129 130 131 133 134 135 138 139 146 147 148 150 151 152 155 156
cache0          : level=1 type=Data scope=Private size=128K line_size=256 associativity=8
cache1          : level=1 type=Instruction scope=Private size=128K line_size=256 associativity=8
cache2          : level=2 type=Data scope=Private size=4096K line_size=256 associativity=8
cache3          : level=2 type=Instruction scope=Private size=4096K line_size=256 associativity=8
cache4          : level=3 type=Unified scope=Shared size=262144K line_size=256 associativity=32
cache5          : level=4 type=Unified scope=Shared size=983040K line_size=256 associativity=60
processor 0: version = FF,  identification = 0618E8,  machine = 8561
processor 1: version = FF,  identification = 0618E8,  machine = 8561
processor 2: version = FF,  identification = 0618E8,  machine = 8561
processor 3: version = FF,  identification = 0618E8,  machine = 8561
=cut
		if ($out =~ /\s*(# )?processors\s*:\s*(?<processors>\d+)\n.*?bogomips per cpu\s*:\s*(?<bogomips>[\d\.]+)\n.*?features\s*:\s*(?<features>.+?)\n.*?,\s*machine\s*=\s*(?<machine>\d+)/s) {
			$cpu->{cores} = $cpu->{packages} = $cpu->{physcores} = $+{processors};
			$cpu->{model} = 'IBM ' . $+{machine};
			$cpu->{freq} = exists($s390_models{ $+{machine} }) ? $s390_models{ $+{machine} } : 0;
			$cpu->{feat} = {};
		}
		else {
			$logger->error('unable to parse cpuinfo for s390. cpuinfo was: ' . $out);
		}
	}
	else {
		my $packages;
		my $cores = 0;
		my $siblings = 0;
		my @lines = split(/\n/,$out);
		foreach my $line (@lines) {
			## each logical processor will have a 'processor' record
			## the number of processor records == number of logical processors
			if ($line =~ /^processor\s+:\s(\d+)/) {
				$cpu->{'cores'}++;
			}
			## model string
			if ($line =~ /^model name\s+:\s(.*)/) {
				$cpu->{'model'} = $1;
			}
			## MHz clock frequency (float)
			if ($line =~ /^cpu MHz\s+:\s(.*)/) {
				$cpu->{'freq'} = $1;
			}
			## each physical CPU will have a unique physical id
			## each logical processor will report the physical id of the package on which it resides
			## physical ids are not guaranteed to be sequential, or listed in order
			if ($line =~ /^physical id\s+:\s(\d+)/) {
				$packages->{$1}++;
			}
			## Linux reports siblings as the number of execution units on a package
			## each logical processor will report the sibling count of the whole package
			## it will also report the physcore count of the package, reported by each logical processor
			## if we are hyperthreaded, the sibling count will be twice the physcore count
			## if we are NOT hyperthreaded, the sibling count will be equal to the physcore count
			if ($line =~ /^siblings\s+:\s(\d)/) {
				$siblings += $1;
			}
			if ($line =~ /^cpu cores\s+:\s(\d+)/) {
				$cores += $1;
			}

			## match some CPU features people might care about
			if ($line =~ /^flags\s+:\s(.*)/) {
				my @features = split(/ /,$1);
				foreach my $f (@features) {
					switch ($f) {
						case 'vmx'	{ $cpu->{'feat'}->{'virtualization'}++ } ## Intel VT-X
						case 'svm'	{ $cpu->{'feat'}->{'virtualization'}++ } ## AMD-V
						case 'ht'	{ $cpu->{'feat'}->{'hyperthreading'}++ } ## doesn't mean cpu IS hyperthreaded
						case 'lm'	{ $cpu->{'feat'}->{'64bit'}++ } ## long mode (64bit instructions)
						case 'aes'	{ $cpu->{'feat'}->{'aes'}++ } ## AES-NI crypto in hardware
						case 'aes-ni'	{ $cpu->{'feat'}->{'aes'}++ } ## AES-NI crypto in hardware
						case 'nx'	{ $cpu->{'feat'}->{'nx'}++ } ## Non-Executable memory
						case 'rdrand'	{ $cpu->{'feat'}->{'rdrand'}++ } ## hardware Random Number Generator
						case 'popcnt'	{ $cpu->{'feat'}->{'popcnt'}++ } ## Population Count (hamming weight)
						case 'smx'	{ $cpu->{'feat'}->{'tpm'}++ } ## Trusted Platform Module support
						case 'pae'	{ $cpu->{'feat'}->{'pae'}++ } ## Physical Address Extensions
					}
				}
			}
		}
		$cpu->{'packages'} = keys %{$packages};
		## some kernels won't have a physical_id field if there is only one package
		## but we have to have at least one package
		$cpu->{'packages'} = 1 unless ($cpu->{'packages'});
		if ($siblings == $cores) {
			$cpu->{'hyperthreading'} = 0;
			$cpu->{'physcores'} = $cpu->{'cores'};
		} elsif ($siblings == ($cores * 2)) {
			$cpu->{'hyperthreading'} = 1;
			$cpu->{'physcores'} = $cpu->{'cores'}/2;
		}
		## attempt to pull the CPU frequency from the model string, if somehow we
		## missed it above
		unless ($cpu->{'freq'}) {
			if ($cpu->{'model'} =~ /(\d+\.\d+)(\s|)GHz/i) {
				# FIXME: MHz should be * 1000, not * 1024
				$cpu->{'freq'} = $1 * 1024;
			} elsif ($cpu->{'model'} =~ /(\d+.\d+)(\s|)MHz/i) {
				$cpu->{'freq'} = $1;
			}
		}
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	## we should have 'iostat' cached, which will have our logical processor count
	$cpu->{'cores'} = $ssh->{'iostat'}->{'lcpu'};
	my $queryproc;
	foreach my $d (sort keys %{$ssh->{'lsdev'}}) {
		if ($d =~ /^proc/) {
			next unless ($ssh->{'lsdev'}->{$d}->{'status'});	## only count 'Available' processors
			$cpu->{'packages'}++;
			$queryproc = $d unless ($queryproc);
		}
	}
	my $rawcpu = $ssh->cmd("env LC_ALL=C lsattr -E -l $queryproc",{ 'vclass' => 'fail' });
	if ($rawcpu) {
		($cpu->{'freq'}) = $rawcpu =~ /frequency\s+(\d+)/; ## in Hz
		$cpu->{'freq'} /= 1000000; ## to MHz
		($cpu->{'model'}) = $rawcpu =~ /type\s+(.*)\s+Processor\s+type/;
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			"lsattr -E -l $queryproc",
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
if ($cpu) {
	## the current cpu logic is packages*cores, and cores is per-system, so here we get
	## cores per package so the above math works out
	if ($cpu->{'packages'} > 1) {
		$cpu->{'coresperpackage'} = $cpu->{'cores'}/$cpu->{'packages'};
	} else {
		$cpu->{'coresperpackage'} = $cpu->{'cores'};
	}
	$cpu->{'model'} =~ s/^\s+//;	## strip leading whitespace from model string
	$cpu->{'model'} =~ s/\s+$//;	## strip trailing whitespace from model string
	$cpu->{'freq'} = ceil($cpu->{'freq'});	## convert to integer if we got a float
	$cpu->{'capacity'} = $cpu->{'cores'} * $cpu->{'freq'};	## total MHz capacity of the system
}
dbg_dump($cpu,'CPU');

## collect network devices
#
##
my $intf;
my $max_index = 0; ## handle psuedo-devices that don't report an interface index
if ($ssh->{'os'} eq 'Linux') {
	my $did_sbin = 0;
	my $ifconfig = $ssh->cmd('LC_ALL=C ifconfig -a',{ 'priv' => 1, 'vclass' => 'fallback' });
	unless ($ifconfig) {
		## commands typically located in /sbin may have issues with PATH on modern systems
		## try it by absolute path before giving up
		$ifconfig = $ssh->cmd('LC_ALL=C /sbin/ifconfig -a',{ 'priv' => 1, 'vclass' => 'fail' });
		$did_sbin = 1;
	}
	if ($ifconfig) {
		my @interfaces = split(/\n\n/,$ifconfig);
		foreach my $interface (@interfaces) {
			my @lines = split(/\n/,$interface);
			my $first_line = $lines[0];
			my ($ifname) = $first_line =~ /^(\S+)\s/;
			$ifname =~ s/:$//;
			foreach my $line (@lines) {
				## interface type
				my $iftype = 'ethernet';
				my $snmpiftype = 'ethernet-csmacd';
				if ($line =~ /encap:(\S+)\s/) {
					$iftype = $1;
				}
				## match against known virtual interface types
				switch ($ifname) {
					case /^lo/	{ $iftype = 'loopback'; $snmpiftype = 'softwareLoopback' }
					case /^tap/	{ $iftype = 'pseudo-ethernet'; $snmpiftype = 'other' }
					case /^tun/	{ $iftype = 'pseudo-tunnel'; $snmpiftype = 'other' }
					case /^vpn/	{ $iftype = 'pseudo-tunnel'; $snmpiftype = 'other' }
					case /^sit/	{ $iftype = 'pseudo-tunnel'; $snmpiftype = 'other' }
					case /^ipiptun/	{ $iftype = 'pseudo-tunnel'; $snmpiftype = 'other' }
					case /^gre/	{ $iftype = 'pseudo-tunnel'; $snmpiftype = 'other' }
					case /^vlan/	{ $iftype = 'pseudo-vlan'; $snmpiftype = 'other' }
					case /^br/	{ $iftype = 'pseudo-bridge'; $snmpiftype = 'other' }
					case /^vmnet/	{ $iftype = 'pseudo-vmnet'; $snmpiftype = 'other' }
					case /^dummy/	{ $iftype = 'pseudo-dummy'; $snmpiftype = 'other' }
					case /^bond/	{ $iftype = 'pseudo-bond'; $snmpiftype = 'other' }
					case /^wlan/	{ $iftype = 'wireless' }
					case /^veth/	{ $iftype = 'virtual-ethernet' }
				}
				$intf->{$ifname}->{'type'} = $snmpiftype;	## basic typing as in SNMP
				$intf->{$ifname}->{'etype'} = $iftype;		## extended typing for new tables
				## mac address
				if ($line =~ /(HWaddr|ether) (\S+)/) {
					$intf->{$ifname}->{'mac'} = $2;
					## compensate for strange macs, ie on tun interfaces
					if (length $intf->{$ifname}->{'mac'} !=  17) {
						$intf->{$ifname}->{'mac'} = undef;
					}
				}
				## ipv4 address
				if ($line =~ /inet\s/) {
					if ($line =~ /inet (addr:|)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
						$intf->{$ifname}->{'ipaddr'} = $2;
					}
					if ($line =~ /(Mask:|netmask )(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
						$intf->{$ifname}->{'mask'} = $2;
					}
					if ($line =~ /(Bcast:|broadcast )(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
						$intf->{$ifname}->{'bcast'} = $2;
					}
				}
				## ipv6 address
				if ($line =~ /inet6/) {
					if ($line =~ /inet6 (addr: |)(\S+)(\/|\s+prefixlen\s+)(\d+)/) {
						$intf->{$ifname}->{'ip6addr'} = $2;
						$intf->{$ifname}->{'ip6mask'} = $4;
					}
					if ($line =~ /Scope:(\S+)/) {
						$intf->{$ifname}->{'ip6scope'} = $1;
					} elsif ($line =~ /scopeid\s+.*<(.*)>/) {
						$intf->{$ifname}->{'ip6scope'} = $1;
					}
				}
				if ($line =~ /MTU:\d+/) {
					if ($line =~ /\sUP\s/) {
						$intf->{$ifname}->{'adminstatus'} = 'up';
					} else {
						$intf->{$ifname}->{'adminstatus'} = 'down';
					}
				}
				## RHEL7 has a different flags format
				if ($line =~ /flags=.*<(.*)>/) {
					my @flags = split(/,/,$1);
					foreach my $fl (@flags) {
						if ($fl eq 'UP') {
							$intf->{$ifname}->{'adminstatus'} = 'up';
						}
					}
					$intf->{$ifname}->{'adminstatus'} = 'down' unless ($intf->{$ifname}->{'adminstatus'});
				}
			}
			$intf->{$ifname}->{'index'} = $ssh->cmd("cat /sys/class/net/$ifname/ifindex",{ 'vclass' => 'incomplete' });
			$max_index = $intf->{$ifname}->{'index'} if ($intf->{$ifname}->{'index'} > $max_index);
			$intf->{$ifname}->{'operstatus'} = $ssh->cmd("cat /sys/class/net/$ifname/operstate",{ 'vclass' => 'incomplete' });
			$intf->{$ifname}->{'operstatus'} = 'unknown' unless (defined($intf->{$ifname}->{'operstatus'}));
			if (($intf->{$ifname}->{'operstatus'}) and ($intf->{$ifname}->{'operstatus'} =~ /^up/i)) {
				$intf->{$ifname}->{'speed'} = $ssh->cmd("cat /sys/class/net/$ifname/speed",{ 'logerror' => FALSE, 'vclass' => 'explore' });
			}
			if (defined($intf->{$ifname}->{'speed'})) {
				$intf->{$ifname}->{'speed'} *= (1000000); ## Mbps to bps
			} else {
				$intf->{$ifname}->{'speed'} = 0;
			}
			$intf->{$ifname}->{'mtu'} = $ssh->cmd("cat /sys/class/net/$ifname/mtu",{ 'vclass' => 'explore' });
			unless ($ifname =~ /^lo/) {
				$intf->{$ifname}->{'driver'} = $ssh->cmd("readlink /sys/class/net/$ifname/device/driver/module",{ 'logerror' => FALSE, 'vclass' => 'explore' });
				$intf->{$ifname}->{'driver'} =~ s/^.*[\/\\]//; ## get last component of file path
			}
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			sprintf('%sifconfig -a', ($did_sbin ? '/sbin/' : '')),
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	my $ifconfig = $ssh->cmd('env LC_ALL=C ifconfig -a',{ 'vclass' => 'fail' });
	if ($ifconfig) {
		my @ifconfig = split(/\n\b/,$ifconfig);
		my $intindex = 0;
		foreach my $dev (@ifconfig) {
			my $netif;
			my ($name) = $dev =~ /^(\S+\d+):/;
			$netif->{'index'} = $intindex;
			$netif->{'name'} = $name;
			$netif->{'type'} = 'ethernet-csmacd';
			$netif->{'etype'} = 'ethernet';
			switch ($name) {
				## en and et are both ethernet
				case /^lo/	{ $netif->{'type'} = 'softwareLoopback'; $netif->{'etype'} = 'loopback' }
				case /^at/	{ $netif->{'type'} = 'atm'; $netif->{'etype'} = 'atm' }
				case /^tr/	{ $netif->{'type'} = 'iso88025TokenRing'; $netif->{'etype'} = 'tokenring' }
				case /^tap/	{ $netif->{'type'} = 'other'; $netif->{'etype'} = 'pseudo-ethernet' }
				case /^vi/	{ $netif->{'type'} = 'other'; $netif->{'etype'} = 'pseudo-ethernet' }
			}
			## AIX supports multiple IPs on a nic
			## gather all of these in an array, but use the one from lsattr as the primary
			## alias IPs must have the same mask, so we don't worry about that and use the mask of the primary via lsattr
			my @allips;
			my @iflines = split(/\n/,$dev);
			foreach my $l (@iflines) {
				if ($l =~ /inet\s+/) {
					my ($ip) = $l =~ /inet (\S+)\s+/;
					push(@allips,$ip) if ($ip);
				}
			}
			$netif->{'iplist'} = \@allips;
			$netif->{'operstatus'} = 'down';
			if ($ssh->{'lsdev'}->{$name}->{'status'}) {
				$netif->{'operstatus'} = 'up';
			}
			$netif->{'speed'} = 0;
			if ($netif->{'etype'} eq 'ethernet') {
				my $entstat = $ssh->cmd("env LC_ALL=C entstat $name",{ 'vclass' => 'fail' });
				if ($entstat) {
					($netif->{'mac'}) = $entstat =~ /Hardware Address: (\S+)/;
					if ($entstat =~ /Media Speed Running: (\d+) (\S+)/) {
						my $rate = $1;
						my $units = $2;
						if ($units =~ /Kbps/i) {
							$netif->{'speed'} = ($rate * 1000);
						} elsif ($units =~ /Mbps/i) {
							$netif->{'speed'} = ($rate * 1000000);
						} elsif ($units =~ /Gbps/i) {
							$netif->{'speed'} = ($rate * 1000000000);
						}
					}
				} else {
					my $error = sprintf(
						q(Failed the command '%s': %s),
						"entstat $name",
						$ssh->clean_ssh_error()
					);
					$ul->error($error, 'query-failure');
					abrt($error);
				}
			}

			my $lsattr = $ssh->cmd("env LC_ALL=C lsattr -E -l $name -a state,netaddr,netmask,netaddr6,mtu",{ 'vclass' => 'fail' });
			if ($lsattr) {
				($netif->{'adminstatus'}) = $lsattr =~ /^state\s+(\S+)/;
				($netif->{'ipaddr'}) = $lsattr =~ /netaddr\s+(\S+)\s+Internet/;
				($netif->{'mask'}) = $lsattr =~ /netmask\s+(\S+)\s+Subnet/;
				## handle loopback not reporting a netmask, the 127 network will always be /8 per RFC 1122
				$netif->{'mask'} = '255.0.0.0' if (($name =~ /^lo/) and (($netif->{'mask'} eq '') or (!defined($netif->{'mask'}))));
				($netif->{'ip6addr'}) = $lsattr =~ /netaddr6\s+(\S+)\s+IPv6/;
				$netif->{'ip6addr'} = ip_expand_address($netif->{'ip6addr'},6) if ($netif->{'ip6addr'});
				($netif->{'mtu'}) = $lsattr =~ /mtu\s+(\S+)\s+Maximum/;
			} else {
				my $error = sprintf(
					q(Failed the command '%s': %s),
					"lsattr $name",
					$ssh->clean_ssh_error()
				);
				$ul->error($error, 'query-failure');
				abrt($error);
			}

			$intf->{$name} = $netif;
			$intindex++;
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'ifconfig -a',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
foreach my $_intf (keys %{$intf}) {
	unless (defined($intf->{$_intf}->{'index'})) {
		$intf->{$_intf}->{'index'} = $max_index + 1;
		$max_index++;
	}
}
dbg_dump($intf,'INTERFACES');

## storage
#
##

## first, get the physical disks
my $rawdisks;
if ($ssh->{'os'} eq 'Linux') {
	if ($ssh->{'os_dist_sub'} eq 'SLES') { ## SLES doesn't support the same flags
		my $diskraw = $ssh->cmd('lsblk -dnb --output NAME,MAJ:MIN,SIZE,MODEL',{ 'vclass' => 'fallback' });
		my @diskraw = split(/\n/,$diskraw);
		foreach my $line (@diskraw) {
			if ($line =~ /(\S+)\s+(\S+)\s+(\d+)\s+(.*)/) {
				my $device = $1;
				next if (($device =~ /^fd/) or ($device =~ /^sr/)); ## skip floppy/optical drives
				$rawdisks->{$device}->{'bus'} = $2;
				$rawdisks->{$device}->{'size'} = $3/1024; ## bytes to KiB
				$rawdisks->{$device}->{'model'} = $4;
				$rawdisks->{$device}->{'model'} =~ s/\s+$//; ## strip trailing whitespace
			}
		}
	} else {
		my $diskraw = $ssh->cmd('lsblk -dnb --output NAME,MAJ:MIN,TYPE,SIZE,MODEL',{ 'vclass' => 'fallback' });
		my @diskraw = split(/\n/,$diskraw);
		foreach my $line (@diskraw) {
			if ($line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(.*)/) {
				my $device = $1;
				my $type = $3;
				next if ($device =~ /^fd(\d+)/); ## skip floppy drives
				next if ($type ne 'disk'); ## skip optical drives
				$rawdisks->{$device}->{'bus'} = $2;
				$rawdisks->{$device}->{'type'} = $type;
				$rawdisks->{$device}->{'size'} = $4/1024; ## bytes to KiB
				$rawdisks->{$device}->{'model'} = $5;
				$rawdisks->{$device}->{'model'} =~ s/\s+$//; ## strip trailing whitespace
			}
		}
	}
	unless ($rawdisks) {
		my $diskraw = $ssh->cmd('fdisk -l',{ 'priv' => 1, 'vclass' => 'fallback' });
		unless ($diskraw) {
			## commands typically located in /sbin may have issues with PATH on modern systems
			## try it by absolute path before giving up
			$diskraw = $ssh->cmd('/sbin/fdisk -l',{ 'priv' => 1, 'vclass' => 'fail' });
		}
		if ($diskraw) {
			my @diskraw = split(/\n/, $diskraw);
			foreach my $line (@diskraw) {
				if (($line =~ /^Disk\s+/)
					and ($line !~ /identifier/i)
					and ($line !~ /dm-/)
					and ($line !~ /md/)
					and ($line !~/ram\d+/))
				{
					my ($dev, $size) = $line =~ /^Disk\s+\/dev\/(\S+):.*\s(\d+)\s+bytes/;
					next unless (($dev) and ($size));
					$rawdisks->{$dev}->{'size'} = $size/1024; ## bytes to KiB
				}
			}
			foreach my $dev (keys %{$rawdisks}) {
				$rawdisks->{$dev}->{'model'} = $ssh->cmd("cat /sys/block/$dev/device/model",{  'logerror' => FALSE, 'vclass' => 'explore' });
			}
		} else {
			my $error = sprintf(
				q(Command '%s' not available and the backup command '%s' failed: %s),
				'lsblk',
				'fdisk -l',
				$ssh->clean_ssh_error()
			);
			$ul->error($error, 'query-failure');
			abrt($error);
		}
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	my @disks;
	foreach my $d (sort keys %{$ssh->{'lsdev'}}) {
		push (@disks,$d) if ($d =~ /^hdisk\d+/);
	}
	foreach my $d (@disks) {
		my $size = 0;
		$size = $ssh->cmd("env LC_ALL=C getconf DISK_SIZE /dev/$d",{ 'vclass' => 'fallback' });
		unless ($size) {
			## the disks may have access restrictions in some configurations that require privilege
			## try it with priv before giving up
			$size = $ssh->cmd("getconf DISK_SIZE /dev/$d",{ 'priv' => 1, 'vclass' => 'incomplete' });
		}
		if ($size) {
			$rawdisks->{$d}->{'size'} = $size*1024; ## MiB to KiB
		}
	}
}
dbg_dump($rawdisks,'DISKS');

## now get partitions
## AIX does not have partitions, only LVM volumes
##   because these are not really partitions and are troublesome to collect, skip them for now
my $partitions;
if ($ssh->{'os'} eq 'Linux') {
	my $procpart = $ssh->cmd('cat /proc/partitions', { 'vclass' => 'fail' });
	if ($procpart) {
		my @procpart = split(/\n/,$procpart);
		shift @procpart; ## throw away header line
		shift @procpart; ## throw away blank separator line
		my $partid = 0;
		foreach my $line (@procpart) {
			$line =~ s/^\s+//g;
			my ($busmaj,$busmin,$size,$dev) = split(/\s+/,$line);
			next if (($dev =~ /^fd/) or ($dev =~ /^ram/) or ($dev =~ /^sr/) or ($dev =~ /^dm/)); ## throw out floppy/optical/logical devices
			next if (defined($rawdisks->{$dev})); ## throw out our real disks from above
			$partitions->{$dev}->{'id'} = $partid;
			$partitions->{$dev}->{'size'} = $size; ## we get 1KiB blocks, but we want KiB to match SNMP hrPartitionTable
			$partid++;
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'cat /proc/partitions',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
dbg_dump($partitions,'PARTITIONS');

## now get filesystems, separate virtual filesystems from real filesystems
my $virtfs;
my $fs;
if ($ssh->{'os'} eq 'Linux') {
	my $all = $ssh->cmd('mount',{ 'vclass' => 'fallback' });
	unless ($all) {	## try it with priv before we give up
		$all = $ssh->cmd('mount',{ 'priv' => 1, 'vclass' => 'fail' });
	}
	if ($all) {
		my @all = split(/\n/,$all);
		foreach my $line (@all) {
			if ($line =~ /(.+) on (.+) type (.+) \((.*)\)/) {
				my $parent = $1;
				my $mp = $2;
				my $type = $3;
				my $opts = $4;
				my @opts = split(/,/,$opts);
				if ((($parent =~ /^\//) or ($type eq 'nfs') or ($type eq 'cifs')) and ($type !~ /proc/)) { ## real fs parent devices are filepaths, and begin with a slash (or remote hosts)
					$fs->{$mp}->{'index'} = $storage_index;
					$fs->{$mp}->{'parent'} = $parent;
					$fs->{$mp}->{'fs'} = $type;
					$fs->{$mp}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.4'; ## hrStorageFixedDisk
					$fs->{$mp}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.7' if ($type =~ /9660/); ## hrStorageCompactDisc
					$fs->{$mp}->{'remote'} = 0;
					$fs->{$mp}->{'remoteorigin'} = ''; ## upstream wants empty string, not NULL
					if ($type =~ /nfs/) {
						$fs->{$mp}->{'remote'} = 1;
						$fs->{$mp}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.10'; ## hrStorageNetworkDisk
						$fs->{$mp}->{'remoteorigin'} = $parent;
						if ($parent =~ /(.*):(.*)/) {
							$fs->{$mp}->{'remotehost'} = $1;
							$fs->{$mp}->{'remoteshare'} = $2;
						}
					}
					if ($type =~ /cifs/) { ## windows/samba file share
						$fs->{$mp}->{'remote'} = 1;
						$fs->{$mp}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.10'; ## hrStorageNetworkDisk
						$fs->{$mp}->{'remoteorigin'} = $parent;
						if ($parent =~ /\/\/(.*)\/(.*)/) {
							$fs->{$mp}->{'remotehost'} = $1;
							$fs->{$mp}->{'remoteshare'} = $2;
						}
					}
					$fs->{$mp}->{'opts'} = $opts;
					if (grep {$_ eq 'ro'} @opts) {
						$fs->{$mp}->{'access'} = 'readOnly';
					} else {
						$fs->{$mp}->{'access'} = 'readWrite';
					}
					$fs->{$mp}->{'fsoid'} = $ssh->map_fs_oid($type);
					$fs->{$mp}->{'allocunit'} = 0;
				} else { ## virtual fs
					$virtfs->{$mp}->{'index'} = $storage_index;
					$virtfs->{$mp}->{'parent'} = $parent;
					$virtfs->{$mp}->{'fs'} = $type;
					$virtfs->{$mp}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.1'; ## hrStorageOther
					$virtfs->{$mp}->{'opts'} = $opts;
					if (grep {$_ eq 'ro'} @opts) {
						$virtfs->{$mp}->{'access'} = 'readOnly';
					} else {
						$virtfs->{$mp}->{'access'} = 'readWrite';
					}
					$virtfs->{$mp}->{'fsoid'} = $ssh->map_fs_oid($type,1);
					$virtfs->{$mp}->{'allocunit'} = 0;
					$virtfs->{$mp}->{'remoteorigin'} = '';
				}
			}
			$storage_index++;
		}
		## filesystem sizes are in bytes, as SNMP returns a) size of allocation unit in bytes, b) number of allocation units, recorded as (unitsize * count)
		my $df_cmd = 'df -P';
		# ignore non-zero exit, e.g. if 'Stale file handle' is returned due to bad NFS mounts
		if (riscUtility::checkfeature('ignore-linux-df-errors', $mysql)) {
			$df_cmd .= ' || true';
		}
		my $df = $ssh->cmd($df_cmd,{ 'priv' => 1, 'vclass' => 'fail' });
		if ($df) {
			my @df = split(/\n/,$df);
			shift @df; ## strip header line
			foreach my $line (@df) {
				my @line = split(/\s+/,$line);
				my $mp = $line[5];
				if (defined($fs->{$mp})) {
					$fs->{$mp}->{'size'} = $line[1]*1024;
					$fs->{$mp}->{'used'} = $line[2]*1024;
				} elsif (defined($virtfs->{$mp})) {
					$virtfs->{$mp}->{'size'} = $line[1]*1024;
					$virtfs->{$mp}->{'used'} = $line[2]*1024;
				} else {
					$logger->warn(sprintf('orphaned filesystem in df output: %s', $line));
				}
			}
		} else {
			my $error = sprintf(
				q(Failed the command '%s': %s),
				'df -P',
				$ssh->clean_ssh_error()
			);
			$ul->error($error, 'query-failure');
			abrt($error);
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'mount',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	## normally, lsfs doesn't require priv, however, in some cases it seems it may
	## to avoid interfering with engagements where this is working and not configured for priv,
	## we first try without and then fall back to try with
	my $lsfs = $ssh->cmd('env LC_ALL=C lsfs',{ 'vclass' => 'fallback' });
	unless ($lsfs) {
		$lsfs = $ssh->cmd('lsfs',{ priv => 1, 'vclass' => 'fail' });
	}
	if ($lsfs) {
		my @lsfs = split(/\n/,$lsfs);
		shift @lsfs;	## header
		foreach my $line (@lsfs) {
			my ($dev,$remote,$mnt,$fstype,$blocks512,$opts,$auto,$acc) = split(/\s+/,$line);
			if ($fstype =~ /(jfs|nfs|cifs|sfs|cdrfs|udfs)/) {	## real fs
				$fs->{$mnt}->{'mountpoint'} = $mnt;
				$fs->{$mnt}->{'index'} = $storage_index;
				$fs->{$mnt}->{'parent'} = $dev;
				$fs->{$mnt}->{'fs'} = $fstype;
				$fs->{$mnt}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.4'; ## hrStorageFixedDisk
				$fs->{$mnt}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.7' if ($fstype =~ /(cdrfs|udfs)/); ## hrStorageCompactDisk
				$fs->{$mnt}->{'allocunit'} = 0;
				$fs->{$mnt}->{'remote'} = 0;
				$fs->{$mnt}->{'remoteorigin'} = '';
				if (($remote) and ($remote ne '--')) {
					$fs->{$mnt}->{'remote'} = 1;
					$fs->{$mnt}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.10'; ## hrStorageNetworkDisk
					my ($remotehost,$remotepath);
					if ($fstype =~ /nfs/) {
						$remotehost = $remote;
						$remotepath = $dev;
					} elsif ($fstype eq 'cifs') {
						#($remotehost,$remotepath) = $remote =~ /^(.*?)\/(.*)/;	#XXX no idea if this works
					}
					if (($remotehost) and ($remotehost !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)) {
						my $resolv = $ssh->cmd("env LC_ALL=C host $remotehost",{ 'vclass' => 'explore' });
						if ($resolv) {
							($remotehost) = $resolv =~ / is (.*)/;
						}
					}
					$fs->{$mnt}->{'remoteorigin'} = $remotehost;
					$fs->{$mnt}->{'remoteshare'} = $remotepath;
				}
				## gensrvfilesystem has the fsaccess field to show either readOnly or readWrite
				## we don't currently look at this field and I don't want to issue another
				## command just to get that, so leave it undef
				$fs->{$mnt}->{'access'} = undef;
				$fs->{$mnt}->{'fsoid'} = $ssh->map_fs_oid($fstype);
			} else {	## virtual fs
				$virtfs->{$mnt}->{'mountpoint'} = $mnt;
				$virtfs->{$mnt}->{'index'} = $storage_index;
				$virtfs->{$mnt}->{'fs'} = $fstype;
				$virtfs->{$mnt}->{'storeoid'} = '.1.3.6.1.2.1.25.2.1.1'; ## hrStorageOther
				$virtfs->{$mnt}->{'fsoid'} = $ssh->map_fs_oid($fstype,1);
				$virtfs->{$mnt}->{'allocunit'} = 0;
				$virtfs->{$mnt}->{'remoteorigin'} = '';
			}
			$storage_index++;
		}
		## now issue df to get sizing info
		## normally, df doesn't require priv,
		## but in some cases certain filesystems can't be listed without
		## so try it first without priv, then fall back to using priv if that returns a failure code
		my $df = $ssh->cmd('env LC_ALL=C df -Pk',{ 'vclass' => 'fallback' });
		unless ($df) {
			$df = $ssh->cmd('df -Pk',{ 'priv' => 1, 'vclass' => 'fail' });
		}
		if ($df) {
			my @df = split(/\n/,$df);
			shift @df; ## header
			foreach my $line (@df) {
				my ($dev,$total,$used,$avail,$cap,$mnt) = split(/\s+/,$line);
				$total = 0 if ($total =~ /-/);
				$used = 0 if ($used =~ /-/);
				$avail = 0 if ($avail =~ /-/);
				if (defined($fs->{$mnt})) {
					$fs->{$mnt}->{'size'} = $total*1024; ## KiB to bytes
					$fs->{$mnt}->{'used'} = $used*1024;
				} elsif (defined($virtfs->{$mnt})) {
					$virtfs->{$mnt}->{'size'} = $total*1024; ## KiB to bytes
					$virtfs->{$mnt}->{'used'} = $used*1024;
				} else {
					$logger->warn(sprintf('orphaned filesystem in df output: %s', $line));
				}
			}
		} else {
			my $error = sprintf(
				q(Failed the command '%s': %s),
				'df -Pk',
				$ssh->clean_ssh_error()
			);
			$ul->error($error, 'query-failure');
			abrt($error);
		}
	} else {
		my $error = sprintf(
			q(Failed the command '%s': %s),
			'lsfs',
			$ssh->clean_ssh_error()
		);
		$ul->error($error, 'query-failure');
		abrt($error);
	}
}
dbg_dump($fs,'FILESYSTEMS',2);
dbg_dump($virtfs,'VIRTFS',2);

## installed software packages
my $installed_opts;
$installed_opts->{'limit'} = 1 if ($VALIDATE);
my $installed_pkgs = $ssh->installed_packages($installed_opts);
dbg_dump($installed_pkgs, 'APPLICATIONS', 3);

# try to query a webserver

$logger->debug('HTTP GET');
$ua->timeout(10);
my $get_proto = 'http';
my $url = $get_proto.'://'.$target;

my @head_res = head $url;
my $headers->{'content_type'} = $head_res[0];
$headers->{'document_length'} = $head_res[1];
$headers->{'modified_time'} = $head_res[2];
$headers->{'expires'} = $head_res[3];
$headers->{'server'} = $head_res[4];

my $content;
($content = get $url) || ($content = 'timed out or did not respond');

if ($VALIDATE) {
	if ($content eq 'timed out or did not respond') {
		push(@{$ssh->{'validator_commands'}},{
			type	=> 'http',
			command	=> 'HTTP GET /',
			result	=> $ssh->{'validator'}->cmdstatus_name('explore')
		});
	} else {
		push(@{$ssh->{'validator_commands'}},{
			type	=> 'http',
			command	=> 'HTTP GET /',
			result	=> $ssh->{'validator'}->cmdstatus_name('success')
		});
	}
}

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
	$validator->finish();
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
# insert the data
##

## skip if we got the noinsert bit
if ($noinsert) {
	$logger->debug("skipping insertion");
	exit(EXIT_SUCCESS);
}

$logger->debug("inserting collected data");

## get the OIDs
my $cpuoid = $ssh->map_device_oid('hrDeviceProcessor');
my $netoid = $ssh->map_device_oid('hrDeviceNetwork');
my $dskoid = $ssh->map_device_oid('hrDeviceDiskStorage');

## remove the device from inventory before we begin inserting
## if this is a net-new device via an additive inventory, this is a no-op
## if we are doing an updating inventory, this must be done
## otherwise, it is good anyway to ensure we don't duplicate
$mysql->do("call remove_gensrv_device($deviceid)");

## ssh_inv_detail
$insert_inv_detail->execute($deviceid,$ssh->{'target'},$hostname,$ssh->{'os'},$ssh->{'os_version'},$ssh->{'arch'},$ssh->{'os_dist'},$ssh->{'os_dist_sub'},$ssh->{'os_dist_ver'},$ssh->{'profile'},$ssh->{'ssh'}->{'server_version_string'},$ssh->{'sysdescr'},time(),
							$hostname,$ssh->{'os'},$ssh->{'os_version'},$ssh->{'arch'},$ssh->{'os_dist'},$ssh->{'os_dist_sub'},$ssh->{'os_dist_ver'},$ssh->{'profile'},$ssh->{'ssh'}->{'server_version_string'},$ssh->{'sysdescr'},time());

## gensrvserver
## SNMP returns uptime in hundredths of seconds
$gensrvserver->execute($deviceid,($uptime*100),$processcount,$mem->{'real'},$numusers,$cpu->{'packages'},$cpu->{'coresperpackage'},$cpu->{'freq'});

## snmpsysinfo
$snmpsysinfo->execute($deviceid,$ssh->{'sysdescr'},$uptime,'unknown',$hostname,'unknown',undef,$sysoid);

## ssh_inv_hardware
$ssh_inv_hardware->execute($deviceid,$invlogtime,
				$hardware->{'product_vendor'},
				$hardware->{'product_name'},
				$hardware->{'product_ver'},
				$hardware->{'product_serial'},
				$hardware->{'product_uuid'},
				$hardware->{'chassis_vendor'},
				$hardware->{'chassis_ver'},
				$hardware->{'chassis_serial'},
				$hardware->{'bios_vendor'},
				$hardware->{'bios_ver'},
				$hardware->{'bios_date'});

## cpus in gensrvdevice
for (my $i = 0; $i < $cpu->{'cores'}; $i++) {
	$gensrvdevice->execute($deviceid,$cpuoid,$cpu->{'model'},0,'running',undef);
}

## gensrvprocess
foreach my $p (keys %{$proc}) {
	$gensrvprocesses->execute($deviceid,$proc->{$p}->{'pid'},$proc->{$p}->{'name'},0,$proc->{$p}->{'path'},$proc->{$p}->{'args'},$proc->{$p}->{'runtype'},$proc->{$p}->{'runstatus'},$proc->{$p}->{'perfcpu'},$proc->{$p}->{'perfmem'},$scantime);
}

## insert network interfaces into gensrvdevice, interfaces, and iptables
foreach my $i (keys %{$intf}) {
	$gensrvdevice->execute($deviceid,$netoid,"network interface $i",0,'running',undef);
	$interfaces->execute($deviceid,$intf->{$i}->{'index'},$i,$intf->{$i}->{'type'},$intf->{$i}->{'speed'},$intf->{$i}->{'index'},$intf->{$i}->{'mac'},$intf->{$i}->{'adminstatus'},$intf->{$i}->{'operstatus'});
	if (defined($intf->{$i}->{'ipaddr'})) {
		$iptables->execute($deviceid,$intf->{$i}->{'ipaddr'},$intf->{$i}->{'mask'},$intf->{$i}->{'index'});
	}
	## handle systems with multiple IPs on a single nic (AIX)
	if (defined($intf->{$i}->{'iplist'})) {
		foreach my $ip (@{$intf->{$i}->{'iplist'}}) {
			next if ($ip eq $intf->{$i}->{'ipaddr'});	## skip the primary
			$iptables->execute($deviceid,$ip,$intf->{$i}->{'mask'},$intf->{$i}->{'index'});
		}
	}
	## the iptables table does not support ipv6 addresses at this time (field length on the ip field)
	#if (defined($intf->{$i}->{'ip6addr'})) {
	#	$iptables->execute($deviceid,$intf->{$i}->{'ip6addr'},$intf->{$i}->{'ip6mask'},$intf->{$i}->{'index'});
	#}
}

## physical disks in gensrvdevice
foreach my $rd (keys %{$rawdisks}) {
	$gensrvdevice->execute($deviceid,$dskoid,"SCSI disk (/dev/$rd)",0,undef,undef);
}

## partitions in gensrvpartition
foreach my $partdev (keys %{$partitions}) {
	$gensrvpartition->execute($deviceid,0,"/dev/$partdev",$partitions->{$partdev}->{'id'},$partitions->{$partdev}->{'size'},0);
}

## gensrvfilesystem and gensrvstorage
## first, real filesystems in both tables
foreach my $mp (keys %{$fs}) {
	$gensrvfilesystem->execute($deviceid,$fs->{$mp}->{'index'},$mp,$fs->{$mp}->{'remoteorigin'},$fs->{$mp}->{'fsoid'},$fs->{$mp}->{'access'},'na',$fs->{$mp}->{'index'},undef,undef);
	$gensrvstorage->execute($deviceid,$fs->{$mp}->{'index'},$fs->{$mp}->{'storeoid'},$mp,$fs->{$mp}->{'allocunit'},$fs->{$mp}->{'size'},$fs->{$mp}->{'used'});
}
## virtual filesystems only go in gensrvfilesystems, as they contain metadata exposed as a filesystem, not block storage
foreach my $mp (keys %{$virtfs}) {
	$gensrvfilesystem->execute($deviceid,$virtfs->{$mp}->{'index'},$mp,$virtfs->{$mp}->{'remoteorigin'},$virtfs->{$mp}->{'fsoid'},$virtfs->{$mp}->{'access'},'na',$virtfs->{$mp}->{'index'},undef,undef);
}

if ($installed_pkgs) {
	unless ($ssh->insert_installed_packages(
		$deviceid,
		$installed_pkgs,
		$dl->{'installedsoftware'}->id(),
		$mysql,
		$logger,
		{ do_legacy => 1 }))
	{
		$logger->error(sprintf(
			'failed to insert installed packages: %s',
			$ssh->get_error()
		));
	}
}

$insert_http_get_inventory->execute($deviceid,$get_proto,$headers->{'content_type'},$headers->{'server'},$content);

$logger->info('complete');

## update our inventorylog
## if we already have an inventory timestamp, then this must be an updating run
if ($invlog->{'inventory'}) {
	$invlog->{'updated'} = $invlogtime;
} else {
	$invlog->{'inventory'} = $invlogtime;
}
riscUtility::updateInventoryLog($mysql,$invlog);

## update dataset_log
map { $dl->{$_}->success() } (keys %{ $dl });

$mysql->disconnect();
exit(EXIT_SUCCESS);

## FINISH

sub abrt {
	my $message = shift;
	return if ($dontstop);
	$logger->error(sprintf('aborting: %s', $message));
	$ul->error(COLLECTION_ABORT_MSG, 'not-eligible');
	riscUtility::updateInventoryLog($mysql,$invlog);
	exit(EXIT_FAILURE);
}

sub dbg_dump {
	my ($data, $header, $lvl) = @_;
	return if ($VALIDATE);
	return unless ($debugging);
	return if (($lvl) and ($debugging < $lvl));
	if (ref($data)) {
		$logger->debug(sprintf("%s: %s\n", $header, Dumper($data)));
	} else {
		$logger->debug(sprintf("%s: %s\n", $header, $data));
	}
}
