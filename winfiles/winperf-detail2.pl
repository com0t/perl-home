#!/usr/bin/env perl

use strict;
use Data::Dumper;

use RISC::riscUtility;
use RISC::riscCreds;
use RISC::riscWindows;
use RISC::CollectionValidation;
use RISC::Collect::PerfSummary;
use RISC::Collect::Logger;
use RISC::Collect::Quirks;
use RISC::Collect::ServiceConfig qw( detect_services );

## set the maximum runtime of this per-device collector
## take the feature flag setting, or use the hard default
## 30 minutes, based on the max amount of time a valid poll could potentially complete in
my $MAX_RUNTIME		= riscUtility::checkfeature('winperf-device-max-runtime');
$MAX_RUNTIME		= 1800 unless ($MAX_RUNTIME);

my $POLL_SLEEP_INTERVAL	= 5;		## seconds between first and second data poll


my ($deviceid, $target, $credid, $dns);

# use environment to avoid logging any sensitive strings - this is called with creds rather than credid by validation
if (my $risc_credentials = riscUtility::risc_credentials()) {
	($deviceid, $target, $credid, $dns) = map {
		$risc_credentials->{$_}
	} qw(deviceid target credid dns);
# the old fashioned way
} else {
	($deviceid, $target, $credid, $dns) = (shift, shift, shift, shift);
}

my $logger = RISC::Collect::Logger->new(
	join('::', qw( perf windows core ), $deviceid, $target)
);

my $cyberark_wmi = (-f "/etc/risc-feature/cyberark-wmi" && -f "/home/risc/conf/cyberark_config.json");

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $no_process_args_indicator = '(RN150: process argument collection opted out)';

my (
	$validator,
	$VALIDATE,
	$vsuccess,
	$vexplore,
	$vfallback,
	$vincomplete,
	$vfail
);

if ($ENV{'VALIDATE'}) {
	# If running in validation mode, rename the process so it isn't killed by
	# other cleanup operations.
	$0 = 'winperf-validation';
	$validator = RISC::CollectionValidation->new({
		logfile		=> $ENV{'VALIDATE'},
		debug		=> $debugging
	});
	if (my $verror = $validator->err()) {
		print STDOUT 'Internal error: contact help@riscnetworks.com with error code CV01';
		print STDERR "$0::ERROR: $verror\n";
		$validator->exit('fail');
	}
	$VALIDATE	= 1;

	$vsuccess	= $validator->cmdstatus_name('success');
	$vexplore	= $validator->cmdstatus_name('explore');
	$vfallback	= $validator->cmdstatus_name('fallback');
	$vincomplete	= $validator->cmdstatus_name('incomplete');
	$vfail		= $validator->cmdstatus_name('fail');

	##NOTE: since we don't know whether DNS is available or not, skip it for now
	$dns = 0;
}

my $mysql  = riscUtility::getDBH('RISC_Discovery', 1);

my $scantime = time();

## perf summary
my $summary;
unless ($VALIDATE) {
	$summary = RISC::Collect::PerfSummary::get($mysql, $deviceid, 'winperf');
	$summary->{'attempt'} = $scantime;
}

## scope global variables
my (
	$wmi,
	$colRunningProcs,
	$colMemPerf,
	$colProcessorPerf,
	$colProcessorPerf2,
	$col2008Disk,
	$col2008Disk2,
	$colDiskPerf,
	$colDiskPerf2,
	$colDiskPerfPhysDisk,
	$colDiskPerfPhysDisk2,
	$colNetPerf,
	$colNetPerf2
);

## begin the top level eval
## any condition within the collection that results in an error, timeout, exceptions, etc, will trigger a die that is caught by this eval
## the primary purpose is to ensure that we commit the perfsummary record to db regardless of our failure condition

eval {

	## first we set up an alarm to provide a total runtime timeout
	## we want to make sure we don't crap out the whole batch if this system takes too long, so we will abort this process
	## the abort will trigger a die that will be caught by the top-level eval, where we will commit our perfsummary record and exit
	## given about 25 queries to the target with a wmic/winexe timeout of 60 seconds, a total valid runtime could potentially take about 30 minutes
	local $SIG{ALRM} = sub { die "RISCTIMEOUT\n"; };
	alarm $MAX_RUNTIME;

	## we also need to handle SIGTERM, in case the admin script determines we should die
	local $SIG{TERM} = sub { my $sig = shift; die "SIG$sig\n"; };

	my $credobj = riscCreds->new($target);
	my $cred;
	if ($VALIDATE) {
		my ($user,$pass,$netstat) = split(/\s+/,$credid);
		if ($cyberark_wmi) {
			my $credSet = $credobj->getWinCyberArkQueryString($pass);
			unless ($credSet) {
				my $errmsg = 'Failed credential allocation: ' . $credobj->{'error'};

				$logger->error($errmsg);

				$validator->log("<h3>PERFORMANCE</h3>\n",0);
				$validator->log("<table>\n",0);
				$validator->log("<tr><td>Connect</td>",1);
				$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
				$validator->log("</table>\n",0);
				$validator->report_connection_failure($errmsg);
				$validator->finish();
				$validator->exit('fail');
			}

			$user = $credSet->{'username'};
			$pass = $credSet->{'passphrase'};
			my $domain = $credSet->{'domain'};
			$cred = $credobj->prepWin({
				'username'   => $user,
				'passphrase' => $pass,
				'context'    => $netstat,
				'domain'     => $domain
			});
		} else {
			$cred = $credobj->prepWin({
				'username'   => $user,     ## user contains domain, as appropriate
				'passphrase' => $pass,
				'context'    => $netstat
			});
		}
	} else {
		$cred = $credobj->getWin($credid);
		unless ($cred) {
			$logger->error(sprintf(
				'failed credential allocation: %s',
				$credobj->{'error'}
			));
			$summary->{'error'} = 'no available credential';
			RISC::Collect::PerfSummary::set($mysql, $summary);
			die "failed to pull credential: $credobj->{'error'}\n";
		}
	}

	if ($VALIDATE) {
		$validator->log("<h3>PERFORMANCE</h3>\n",0);
		$validator->log("<table>\n",0);
		$validator->log("<tr><td>Connect</td>",1);
	}

	my $wmi_config = {
		collection_id	=> $deviceid,
		user		=> $cred->{'user'},
		password	=> $cred->{'password'},
		domain		=> $cred->{'domain'},
		credid		=> ($VALIDATE ? 0 : $cred->{'credid'}),
		host		=> $target,
		scantime	=> $scantime,
		db			=> $mysql,
		debug		=> $debugging,
		logger		=> $logger,
		validator	=> $validator
	};

	$wmi = RISC::riscWindows->new($wmi_config);
	unless ($wmi->connected()) {
		my $error = $wmi->err();
		if ($VALIDATE) {
			$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
			$validator->log("</table>\n",0);
			$validator->report_connection_failure($wmi->err());
			$validator->finish();
			$validator->exit('fail');
		} else {
			$logger->error(sprintf(
				'failed connection: %s',
				$error
			));
			$summary->{'error'} = $error;
			RISC::Collect::PerfSummary::set($mysql,$summary);
			die "failed connection test: $error\n";
		}
	}

	if ($VALIDATE) {
		$validator->log("<td class='$vsuccess'>$vsuccess</td></tr>\n",0);
		$validator->log("</table>\n",0);
	}

	$logger->debug('begin collection');

	if ($cred->{'netstat'} =~ /netstat/) {
		$logger->debug('netstat');
		eval {
			my $netstatstatus = $wmi->netstat();
			chomp($netstatstatus->{'detail'});
			if ($netstatstatus->{'status'}) {
				$summary->{'netstat'} = $scantime;
				$summary->{'rfc4022'} = 1;
			} else {
				$logger->error(sprintf(
					'netstat failure: %s',
					$netstatstatus->{'detail'}
				)) unless ($VALIDATE);
				$summary->{'error'}   = "netstat: $netstatstatus->{'detail'}";
				$summary->{'rfc4022'} = 0;
			}
		};
	}

	my $dnscache_feature = riscUtility::checkfeature('windows-dnscache');
	$logger->debug('dnscache: ' . ($dnscache_feature ? 'enabled' : 'disabled'));
	if ($dnscache_feature) {
		eval {
			my $displaydnsstatus = $wmi->displaydns();
			if (!$displaydnsstatus->{'status'}) {
				$summary->{'error'} = sprintf('displaydns: %s', $displaydnsstatus->{'detail'});
				$logger->error($summary->{'error'});
			}
		};
		if ($@) {
			$summary->{'error'} = sprintf('displaydns: displaydns() died for deviceid=%s: %s', $deviceid, $@);
			$logger->error($summary->{'error'});
		}
	}
	else {
		$logger->debug(sprintf('skipping windows dnscache collection due to feature being %s', (defined($dnscache_feature) ? $dnscache_feature : 'undef')));
	}

	## we allow the collection of process arguments to be turned off,
	##   to mitigate against collecting passwords in command lines

	my $process_fields = join(',',
		'ProcessId',
		'Name',
		'Description',
		'ExecutablePath'
	);

	unless (riscUtility::checkfeature('no-process-args')) {
		$process_fields = join(',',
			$process_fields,
			'CommandLine'
		);
	}

	$colRunningProcs = $wmi->wmic('Win32_Process',{
		fields	=> $process_fields,
		vclass	=> 'fail',
		vmetric	=> 'processes'
	});

	$colMemPerf = $wmi->wmic('Win32_OperatingSystem',{
		fields	=> join(',',
				'FreePhysicalMemory',
				'TotalVisibleMemorySize'
			),
		vclass	=> 'fail',
		vmetric	=> 'mem'
	});

	##
	#	counter collection
	#	first poll
	##

	$logger->debug('counter objects first pass');

	$colProcessorPerf = $wmi->wmic('Win32_PerfRawData_PerfOS_Processor',{
		fields	=> join(',',
				'Name',
				'Timestamp_Sys100NS',
				'PercentProcessorTime'
			),
		vclass	=> 'fail',
		vmetric	=> 'cpu'
	});

	$col2008Disk = $wmi->wmic('Win32_LogicalDisk',{
		fields	=> join(',',
				'Name',
				'Size'
			),
		vclass	=> 'fail',
		vmetric	=> 'diskutil'
	});

	## Server 2008 pre-R2 does not support all of the enumerated fields
	## in this case, we get back an error from the poll and the arrayref has zero elements
	## we then fall back to doing the legacy InstancesOf() poll
	$colDiskPerf = $wmi->wmic('Win32_PerfRawData_PerfDisk_LogicalDisk',{
		fields	=> join(',',
				'Name',
				'PercentFreeSpace',
				'PercentFreeSpace_Base',
				'FreeMegabytes',
				'CurrentDiskQueueLength',
				'AvgDiskBytesPerRead',
				'AvgDiskBytesPerRead_Base',
				'AvgDiskBytesPerTransfer',
				'AvgDiskBytesPerTransfer_Base',
				'AvgDiskBytesPerWrite',
				'AvgDiskBytesPerWrite_Base',
				'AvgDiskQueueLength',
				'AvgDiskReadQueueLength',
				'AvgDiskWriteQueueLength',
				'AvgDisksecPerRead',
				'AvgDisksecPerTransfer',
				'AvgDisksecPerWrite',
				'AvgDisksecPerRead_Base',
				'AvgDisksecPerTransfer_Base',
				'AvgDisksecPerWrite_Base',
				'DiskBytesPersec',
				'DiskReadBytesPersec',
				'DiskReadsPersec',
				'DiskTransfersPersec',
				'DiskWriteBytesPersec',
				'DiskWritesPersec',
				'Frequency_Object',
				'Timestamp_Sys100NS',
				'Frequency_Sys100NS',
				'PercentDiskReadTime',
				'PercentDiskReadTime_Base',
				'PercentDiskTime',
				'PercentDiskTime_Base',
				'PercentDiskWriteTime',
				'PercentDiskWriteTime_Base',
				'PercentIdleTime',
				'PercentIdleTime_Base',
				'SplitIOPerSec',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Frequency_PerfTime'
			),
		vclass	=> 'fallback',
		vmetric	=> 'diskutil/diskio'
	});
	unless (($colDiskPerf) and (scalar @{$colDiskPerf})) {
		$logger->warn("falling back to legacy poll for Win32_PerfRawData_PerfDisk_LogicalDisk");
		$colDiskPerf = $wmi->wmic('Win32_PerfRawData_PerfDisk_LogicalDisk',{
			vclass	=> 'fail',
			vmetric	=> 'diskutil/diskio'
		});
	}

	$colDiskPerfPhysDisk = $wmi->wmic('Win32_PerfRawData_PerfDisk_PhysicalDisk',{
		fields	=> join(',',
				'Name',
				'CurrentDiskQueueLength',
				'AvgDiskBytesPerRead',
				'AvgDiskBytesPerRead_Base',
				'AvgDiskBytesPerTransfer',
				'AvgDiskBytesPerTransfer_Base',
				'AvgDiskBytesPerWrite',
				'AvgDiskBytesPerWrite_Base',
				'AvgDiskQueueLength',
				'AvgDiskReadQueueLength',
				'AvgDiskWriteQueueLength',
				'AvgDisksecPerRead',
				'AvgDisksecPerTransfer',
				'AvgDisksecPerWrite',
				'AvgDisksecPerRead_Base',
				'AvgDisksecPerTransfer_Base',
				'AvgDisksecPerWrite_Base',
				'DiskBytesPersec',
				'DiskReadBytesPersec',
				'DiskReadsPersec',
				'DiskTransfersPersec',
				'DiskWriteBytesPersec',
				'DiskWritesPersec',
				'Frequency_Object',
				'Timestamp_Sys100NS',
				'Frequency_Sys100NS',
				'PercentDiskReadTime',
				'PercentDiskReadTime_Base',
				'PercentDiskTime',
				'PercentDiskTime_Base',
				'PercentDiskWriteTime',
				'PercentDiskWriteTime_Base',
				'PercentIdleTime',
				'PercentIdleTime_Base',
				'SplitIOPerSec',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Frequency_PerfTime'
			),
		vclass	=> 'fallback',
		vmetric	=> 'diskutil/diskio'
	});
	unless (($colDiskPerfPhysDisk) and (scalar @{$colDiskPerfPhysDisk})) {
		$logger->warn("falling back to legacy poll for Win32_PerfRawData_PerfDisk_PhysicalDisk");
		$colDiskPerfPhysDisk = $wmi->wmic('Win32_PerfRawData_PerfDisk_PhysicalDisk',{
			vclass	=> 'fail',
			vmetric	=> 'diskutil/diskio'
		});
	}

	$colNetPerf = $wmi->wmic('Win32_PerfRawData_Tcpip_NetworkInterface',{
		fields	=> join(',',
				'Name',
				'BytesReceivedPersec',
				'BytesSentPersec',
				'PacketsOutboundDiscarded',
				'PacketsOutboundErrors',
				'PacketsReceivedDiscarded',
				'PacketsReceivedErrors',
				'PacketsReceivedPersec',
				'PacketsSentPersec',
				'Frequency_PerfTime',
				'Timestamp_PerfTime'
			),
		vclass	=> 'fail',
		vmetric	=> 'traffic'
	});

	sleep $POLL_SLEEP_INTERVAL;

	##
	#	counter collection
	#	second poll
	##

	$logger->debug('counter objects second pass');

	$colProcessorPerf2 = $wmi->wmic('Win32_PerfRawData_PerfOS_Processor',{
		fields	=> join(',',
				'Name',
				'Timestamp_Sys100NS',
				'PercentProcessorTime'
			),
		vclass	=> 'fail',
		vmetric	=> 'cpu'
	});

	$col2008Disk2 = $wmi->wmic('Win32_LogicalDisk',{
		fields	=> join(',',
				'Name',
				'Size'
			),
		vclass	=> 'fail',
		vmetric	=> 'diskutil'
	});

	$colDiskPerf2 = $wmi->wmic('Win32_PerfRawData_PerfDisk_LogicalDisk',{
		fields	=> join(',',
				'Name',
				'PercentFreeSpace',
				'PercentFreeSpace_Base',
				'FreeMegabytes',
				'CurrentDiskQueueLength',
				'AvgDiskBytesPerRead',
				'AvgDiskBytesPerRead_Base',
				'AvgDiskBytesPerTransfer',
				'AvgDiskBytesPerTransfer_Base',
				'AvgDiskBytesPerWrite',
				'AvgDiskBytesPerWrite_Base',
				'AvgDiskQueueLength',
				'AvgDiskReadQueueLength',
				'AvgDiskWriteQueueLength',
				'AvgDisksecPerRead',
				'AvgDisksecPerTransfer',
				'AvgDisksecPerWrite',
				'AvgDisksecPerRead_Base',
				'AvgDisksecPerTransfer_Base',
				'AvgDisksecPerWrite_Base',
				'DiskBytesPersec',
				'DiskReadBytesPersec',
				'DiskReadsPersec',
				'DiskTransfersPersec',
				'DiskWriteBytesPersec',
				'DiskWritesPersec',
				'Frequency_Object',
				'Timestamp_Sys100NS',
				'Frequency_Sys100NS',
				'PercentDiskReadTime',
				'PercentDiskReadTime_Base',
				'PercentDiskTime',
				'PercentDiskTime_Base',
				'PercentDiskWriteTime',
				'PercentDiskWriteTime_Base',
				'PercentIdleTime',
				'PercentIdleTime_Base',
				'SplitIOPerSec',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Frequency_PerfTime'
			),
		vclass	=> 'fallback',
		vmetric	=> 'diskutil/diskio'
	});
	unless (($colDiskPerf2) and (scalar @{$colDiskPerf2})) {
		$colDiskPerf2 = $wmi->wmic('Win32_PerfRawData_PerfDisk_LogicalDisk',{
			vclass	=> 'fail',
			vmetric	=> 'diskutil/diskio'
		});
	}

	$colDiskPerfPhysDisk2 = $wmi->wmic('Win32_PerfRawData_PerfDisk_PhysicalDisk',{
		fields	=> join(',',
				'Name',
				'CurrentDiskQueueLength',
				'AvgDiskBytesPerRead',
				'AvgDiskBytesPerRead_Base',
				'AvgDiskBytesPerTransfer',
				'AvgDiskBytesPerTransfer_Base',
				'AvgDiskBytesPerWrite',
				'AvgDiskBytesPerWrite_Base',
				'AvgDiskQueueLength',
				'AvgDiskReadQueueLength',
				'AvgDiskWriteQueueLength',
				'AvgDisksecPerRead',
				'AvgDisksecPerTransfer',
				'AvgDisksecPerWrite',
				'AvgDisksecPerRead_Base',
				'AvgDisksecPerTransfer_Base',
				'AvgDisksecPerWrite_Base',
				'DiskBytesPersec',
				'DiskReadBytesPersec',
				'DiskReadsPersec',
				'DiskTransfersPersec',
				'DiskWriteBytesPersec',
				'DiskWritesPersec',
				'Frequency_Object',
				'Timestamp_Sys100NS',
				'Frequency_Sys100NS',
				'PercentDiskReadTime',
				'PercentDiskReadTime_Base',
				'PercentDiskTime',
				'PercentDiskTime_Base',
				'PercentDiskWriteTime',
				'PercentDiskWriteTime_Base',
				'PercentIdleTime',
				'PercentIdleTime_Base',
				'SplitIOPerSec',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Frequency_PerfTime'
			),
		vclass	=> 'fallback',
		vmetric	=> 'diskutil/diskio'
	});
	unless (($colDiskPerfPhysDisk2) and (scalar @{$colDiskPerfPhysDisk2})) {
		$colDiskPerfPhysDisk2 = $wmi->wmic('Win32_PerfRawData_PerfDisk_PhysicalDisk',{
			vclass	=> 'fail',
			vmetric	=> 'diskutil/diskio'
		});
	}

	$colNetPerf2 = $wmi->wmic('Win32_PerfRawData_Tcpip_NetworkInterface',{
		fields	=> join(',',
				'Name',
				'BytesReceivedPersec',
				'BytesSentPersec',
				'PacketsOutboundDiscarded',
				'PacketsOutboundErrors',
				'PacketsReceivedDiscarded',
				'PacketsReceivedErrors',
				'PacketsReceivedPersec',
				'PacketsSentPersec',
				'Frequency_PerfTime',
				'Timestamp_PerfTime'
			),
		vclass	=> 'fail',
		vmetric	=> 'traffic'
	});

	if ($VALIDATE) {
		$validator->log("<h4>PERFORMANCE COMMANDS</h4>\n",0);
		$validator->log("<table>\n",0);
		foreach my $cmd (@{$wmi->{'validator_commands'}}) {
			$validator->log("<tr><td>$cmd->{'type'}</td><td class='validation-command'>$cmd->{'command'}</td><td class='$cmd->{'result'}'>$cmd->{'result'}</td></tr>\n",1);
		}
		$validator->log("</table>\n",0);
		if (($wmi->{'validator_errors'}) and (scalar @{$wmi->{'validator_errors'}} > 0)) {
			my $failure_condition;
			foreach my $failure (@{$wmi->{'validator_errors'}}) {
				my $result = $failure->{'class'};
				$failure_condition .=<<END;
<p><table>
	<tr><td class='with-border'>Reason</td><td class='$result'>Command Failure</td></tr>
	<tr><td class='with-border'>Result</td><td class='$result'>$result</td></tr>
	<tr><td class='with-border'>Type</td><td>$failure->{'type'}</td></tr>
	<tr><td class='with-border'>Command</td><td class='validation-command'>$failure->{'command'}</td></tr>
	<tr><td class='with-border'>Output</td><td class='validation-command'>$failure->{'error'}</td></tr>
</table></p>
END
			}
			print STDOUT "$failure_condition";
		}
		$validator->finish();
		$validator->exit();
	}

	$logger->debug('processing collected data');

	eval {
		$logger->debug('----> running processes');
		process_procs();
	}; if ($@) {
		$logger->error(sprintf('fault in running processes: %s', $@));
	}

	eval {
		$logger->debug('----> cpu');
		process_cpu();
	}; if ($@) {
		$logger->error("failed to pull cpu: $@");
		$logger->error(sprintf('fault in cpu: %s', $@));
	}

	eval {
		$logger->debug('----> memory');
		process_mem();
	}; if ($@) {
		$logger->error(sprintf('fault in mem: %s', $@));
	}

	eval {
		$logger->debug('----> network');
		process_network();
	}; if ($@) {
		$logger->error(sprintf('fault in traffic: %s', $@));
	}

	eval {
		$logger->debug('----> disk');
		process_disk();
	}; if ($@) {
		$logger->error(sprintf('fault in disk: %s', $@));
	}

	## we have reached the end of collection, so reset our alarm timer
	alarm 0;

	$logger->debug('complete');

	RISC::Collect::PerfSummary::set($mysql, $summary);

}; if ($@) {
	## catch the top-level eval
	## here our goal is to commit our perfsummary record to db and exit
	$logger->debug('entering major exception block');
	my $is_timeout = 0;
	chomp(my $failure = $@);
	if ($failure =~ /RISCTIMEOUT/) {
		$logger->error('local timeout');
		$failure = 'local timeout';
		$is_timeout = 1;
	} elsif ($@ =~ /SIGTERM/) {
		$logger->error('SIGTERM: batch timeout');
		$failure = 'batch timeout';
		$is_timeout = 1;
	} else {
		$logger->error(sprintf('major exception: %s', $failure));
	}
	if ($VALIDATE) {
		$validator->log("<h4>PERFORMANCE COMMANDS</h4>\n",0);
		$validator->log("<table>\n",0);
		foreach my $cmd (@{$wmi->{'validator_commands'}}) {
			$validator->log("<tr><td>$cmd->{'type'}</td><td>$cmd->{'command'}</td><td class='$cmd->{'result'}'>$cmd->{'result'}</td></tr>\n",1);
		}
		$validator->log("</table>\n",0);
		$validator->finish();
		if ($is_timeout) {
			$validator->report_timeout_failure();
			$validator->cmdstatus('fail');
		} else {
			$validator->report_exception_failure();
			$validator->cmdstatus('fail');
		}
		if (($wmi->{'validator_errors'}) and (scalar @{$wmi->{'validator_errors'}} > 0)) {
			my $failure_condition;
			foreach my $failure (@{$wmi->{'validator_errors'}}) {
				my $result = $failure->{'class'};
				$failure_condition .=<<END;
<p><table>
	<tr><td class='with-border'>Reason</td><td class='$result'>Command Failure</td></tr>
	<tr><td class='with-border'>Result</td><td class='$result'>$result</td></tr>
	<tr><td class='with-border'>Type</td><td>$failure->{'type'}</td></tr>
	<tr><td class='with-border'>Command</td><td>$failure->{'command'}</td></tr>
	<tr><td class='with-border'>Output</td><td>$failure->{'error'}</td></tr>
</table></p>
END
			}
			print STDOUT "$failure_condition";
		}
		$validator->exit();
	}
	$summary->{'error'} = $failure;
	RISC::Collect::PerfSummary::set($mysql, $summary);
	exit(1);
}

sub process_procs {
	my $processIns1 = $mysql->prepare("
		INSERT INTO windowsprocess
		(scantime,deviceid,pid,description,name,execpath,commandline)
		VALUES
		(?,?,?,?,?,?,?)
	");

	foreach my $process (@{$colRunningProcs}) {
		my $pid                = $process->{ProcessId};
		my $processName        = $process->{Name};
		my $processDescription = $process->{Description};
		my $execpath           = $process->{ExecutablePath};
		my $com                = $process->{CommandLine};
		if (riscUtility::checkfeature('no-process-args')) {
			$com = join(' ',
				$execpath,
				$no_process_args_indicator
			);
		}
		eval {
			$processIns1->execute($scantime,
				$deviceid,
				$pid,
				$processName,
				$processDescription,
				$execpath,
				$com
			);
		};
	}
	$processIns1->finish();
	$summary->{'processes'} = $scantime if (scalar @{$colRunningProcs} > 0);

	## Detect services supported by service configuration collection
	## and store as quirks
	eval {
		my $services = detect_services('Windows', [
			map { $_->{'CommandLine'} } @{ $colRunningProcs }
		]) if ($colRunningProcs);

		if ($services) {
			my $quirks = RISC::Collect::Quirks->new({ db => $mysql });
			my $q = $quirks->get($deviceid);
			$quirks->post($deviceid, {
				($q) ? %{ $q } : ( ),
				%{ $services }
			});
		}
	}; if ($@) {
		$logger->error(sprintf('fault detecting services for serviceconfig: %s', $@));
	}
}

sub process_cpu {
	my $winsth2 = $mysql->prepare("
		INSERT INTO winperfcpu
		(deviceid,cpuid,percentprocessortime,scantime)
		VALUES
		(?,?,?,?)
	");

	## if we didn't successfully get data for both CPU polls, flag as error and die
	unless (($colProcessorPerf && scalar @{$colProcessorPerf} > 0) and
			($colProcessorPerf2 && scalar @{$colProcessorPerf2} > 0)) {
		my $errmsg = 'missing one or both of the Win32_PerfRawData_PerfOS_Processor polls';
		$summary->{'error'} = $errmsg;
		die "$errmsg\n";
	}

	foreach my $proc1 (@{$colProcessorPerf}) {
		next if $proc1->{'Name'} =~ /Total/;

		my $procutil;
		my $proc1name  = "CPU" . $proc1->{'Name'};
		my $proc1stamp = $proc1->{'Timestamp_Sys100NS'};
		my $proc1util  = $proc1->{'PercentProcessorTime'};

		foreach my $proc2 (@{$colProcessorPerf2}) {
			my $proc2name = "CPU" . $proc2->{'Name'};
			next unless $proc1name eq $proc2name;
			my $proc2util  = $proc2->{'PercentProcessorTime'};
			my $proc2stamp = $proc2->{'Timestamp_Sys100NS'};
			$procutil = (1 - (($proc2util - $proc1util) / ($proc2stamp - $proc1stamp))) * 100;
			$procutil = 0 if (($procutil < 0) and ($procutil > -2));    ## account for rounding error on almost completely idle
		}

		## if we get crap data (such as second poll less than first), flag it as out of bounds, set the summary error, and die
		if (($procutil > 100) or ($procutil < 0)) {
			my $errmsg = "out of bounds CPU value: $procutil";
			$summary->{'error'} = $errmsg;
			die "$errmsg\n";
		}

		$winsth2->execute(
			$deviceid,
			$proc1name,
			$procutil,
			$scantime
		) if defined $procutil;
	}
	$summary->{'cpu'}  = $scantime;
	$colProcessorPerf  = undef;
	$colProcessorPerf2 = undef;
}

sub process_mem {
	my $winsth3 = $mysql->prepare("
		INSERT INTO winperfmem
		(deviceid,availablebytes,committedbytes,availablembytes,percentcommittedbytesinuse,poolnonpagedbytes,poolpagedbytes,scantime)
		VALUES
		(?,?,?,?,?,?,?,?)
	");

	foreach my $mem (@{$colMemPerf}) {
		my $freePhysMem               = $mem->{FreePhysicalMemory};
		my $memavailbytes             = int($freePhysMem * 1000);
		my $memavailMbytes            = int($freePhysMem / 1000);
		my $totalPhysMem              = $mem->{TotalVisibleMemorySize};
		my $memcommitbytes            = ($totalPhysMem - $freePhysMem) * 1000;
		my $mempercentcommitbyteinuse = int(($memcommitbytes / ($totalPhysMem * 1000)) * 100);

		my $mempoolnonpage = 0;
		my $mempoolpage    = 0;

		$winsth3->execute(
			$deviceid,
			$memavailbytes,
			$memcommitbytes,
			$memavailMbytes,
			$mempercentcommitbyteinuse,
			$mempoolnonpage,
			$mempoolpage,
			$scantime
		);
	}
	$summary->{'mem'} = $scantime if (scalar @{$colMemPerf} > 0);
	$colMemPerf = undef;
}

sub process_network {
	my $winsthNet = $mysql->prepare("
		INSERT INTO winperfnet
		(deviceid,instance,bytesreceivedpersec,bytessentpersec,packetsoutbounddiscarded,packetsoutbounderrors,packetsreceiveddiscarded,packetsreceivederrors,packetsreceivedpersec,packetssentpersec,scantime)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?)
	");

	#network perf
	foreach my $nic1 (@{$colNetPerf}) {
		my $nic1name       = $nic1->{Name};
		my $nic1bytesin    = $nic1->{BytesReceivedPersec};
		my $nic1bytesout   = $nic1->{BytesSentPersec};
		my $nic1dout       = $nic1->{PacketsOutboundDiscarded};    #no cooking
		my $nic1eout       = $nic1->{PacketsOutboundErrors};       #no cooking
		my $nic1din        = $nic1->{PacketsReceivedDiscarded};    #no cooking
		my $nic1ein        = $nic1->{PacketsReceivedErrors};       #no cooking
		my $nic1packetsin  = $nic1->{PacketsReceivedPersec};
		my $nic1packetsout = $nic1->{PacketsSentPersec};
		my $nic1base       = $nic1->{Frequency_PerfTime};
		my $nic1stamp      = $nic1->{Timestamp_PerfTime};
		foreach my $nic2 (@{$colNetPerf2}) {
			next unless $nic2->{Name} eq $nic1name;
			my $nic2bytesin    = $nic2->{BytesReceivedPersec};
			my $nic2bytesout   = $nic2->{BytesSentPersec};
			my $nic2dout       = $nic2->{PacketsOutboundDiscarded};    #no cooking
			my $nic2eout       = $nic2->{PacketsOutboundErrors};       #no cooking
			my $nic2din        = $nic2->{PacketsReceivedDiscarded};    #no cooking
			my $nic2ein        = $nic2->{PacketsReceivedErrors};       #no cooking
			my $nic2packetsin  = $nic2->{PacketsReceivedPersec};
			my $nic2packetsout = $nic2->{PacketsSentPersec};
			my $nic2base       = $nic2->{Frequency_PerfTime};
			my $nic2stamp      = $nic2->{Timestamp_PerfTime};
			my $bytesin    = perf_counter_counter($nic1bytesin, $nic2bytesin, $nic1base, $nic1stamp, $nic2stamp);
			my $bytesout   = perf_counter_counter($nic1bytesout, $nic2bytesout, $nic1base, $nic1stamp, $nic2stamp);
			my $packetsin  = perf_counter_counter($nic1packetsin, $nic2packetsin, $nic1base, $nic1stamp, $nic2stamp);
			my $packetsout = perf_counter_counter($nic1packetsout, $nic2packetsout, $nic1base, $nic1stamp, $nic2stamp);
			my $dout       = $nic2dout - $nic1dout;
			my $eout       = $nic2eout - $nic1eout;
			my $din        = $nic2din - $nic1din;
			my $ein        = $nic2ein - $nic1ein;

			$winsthNet->execute(
				$deviceid,
				$nic1name,
				$bytesin,
				$bytesout,
				$dout,
				$eout,
				$din,
				$ein,
				$packetsin,
				$packetsout,
				$scantime
			);
			last;
		}
	}
	$summary->{'traffic'} = $scantime if (scalar @{$colNetPerf} > 0);
	$colNetPerf           = undef;
	$colNetPerf2          = undef;
}

sub process_disk {
	my $winsth4 = $mysql->prepare("
		INSERT INTO winperfdisk
		(deviceid,diskname,percentfreespace,freemb,currentdiskqueuelength,scantime,avgdiskbytesperread,avgdiskbytespertransfer,avgdiskbytesperwrite,avgdiskqueuelength,avgdiskreadqueuelength,avgdiskwritequeuelength,avgdisksecperread,avgdisksecpertransfer,avgdisksecperwrite,diskbytespersec,diskreadbytespersec,diskreadspersec,disktransferspersec,diskwritebytespersec,diskwritespersec,frequencyobject,frequencyperftime,frequencysys100ns,percentdiskreadtime,percentdisktime,percentdiskwritetime,percentidletime,splitiopersec,timestampobject,timestampperftime,timestampsys100ns,cooked_avgdiskbytesperread,cooked_avgdiskbytespertransfer,cooked_avgdiskbytesperwrite,cooked_avgdiskqueuelength,cooked_avgdiskreadqueuelength,cooked_avgdiskwritequeuelength,cooked_disksecperread,cooked_disksecperwrite,cooked_disksecpertransfer,cooked_diskbytespersec,cooked_diskreadbytespersec,cooked_diskwritebytespersec,cooked_disktransferspersec,cooked_diskwritespersec,cooked_diskreadspersec,cooked_percentdisktime,cooked_percentdiskreadtime,cooked_percentdiskwritetime,cooked_percentidletime,avgdiskbytesperreadbase,avgdiskbytespertransferbase,avgdiskbytesperwritebase,percentdiskreadtimebase,percentdisktimebase,percentdiskwritetimebase,percentidletimebase)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");

	my $winsth5 = $mysql->prepare("
		INSERT INTO winperfphysdisk
		(deviceid,diskname,percentfreespace,freemb,currentdiskqueuelength,scantime,avgdiskbytesperread,avgdiskbytespertransfer,avgdiskbytesperwrite,avgdiskqueuelength,avgdiskreadqueuelength,avgdiskwritequeuelength,avgdisksecperread,avgdisksecpertransfer,avgdisksecperwrite,diskbytespersec,diskreadbytespersec,diskreadspersec,disktransferspersec,diskwritebytespersec,diskwritespersec,frequencyobject,frequencyperftime,frequencysys100ns,percentdiskreadtime,percentdisktime,percentdiskwritetime,percentidletime,splitiopersec,timestampobject,timestampperftime,timestampsys100ns,cooked_avgdiskbytesperread,cooked_avgdiskbytespertransfer,cooked_avgdiskbytesperwrite,cooked_avgdiskqueuelength,cooked_avgdiskreadqueuelength,cooked_avgdiskwritequeuelength,cooked_disksecperread,cooked_disksecperwrite,cooked_disksecpertransfer,cooked_diskbytespersec,cooked_diskreadbytespersec,cooked_diskwritebytespersec,cooked_disktransferspersec,cooked_diskwritespersec,cooked_diskreadspersec,cooked_percentdisktime,cooked_percentdiskreadtime,cooked_percentdiskwritetime,cooked_percentidletime,avgdiskbytesperreadbase,avgdiskbytespertransferbase,avgdiskbytesperwritebase,percentdiskreadtimebase,percentdisktimebase,percentdiskwritetimebase,percentidletimebase)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");

	my $winperfdisk_rawdata_insert = $mysql->prepare("
		INSERT INTO winperfdisk_rawdata
		(deviceid,diskname,scantime,freemegabytes,percentfreespace_numer,percentfreespace_denom)
		VALUES
		(?,?,?,?,?,?)
	");

	my $captionQuery = $mysql->selectrow_hashref("
		SELECT caption
		FROM windowsos
		WHERE deviceid = $deviceid
	");

	my $caption = 'none';
	if ($captionQuery) {
		$caption = $captionQuery->{'caption'};
	}

	###First, try and get PerfFormattedData from the Server, if successful insert it into the DB.
	##Pull Logical Disk Performance Information
	foreach my $disk (@{$colDiskPerf}) {
		my $log_diskpercentfree      = $disk->{PercentFreeSpace};
		my $log_percentfreespacebase = $disk->{PercentFreeSpace_Base};
		my $log_diskname             = $disk->{Name};
		my $percentfreespace         = 100 * ($log_diskpercentfree / $log_percentfreespacebase) unless $log_percentfreespacebase == 0;
		my $log_diskfreemb           = $disk->{FreeMegabytes};
		if ($caption =~ /2008/) {
			foreach my $disk2 (@{$col2008Disk}) {
				if ($log_diskname eq $disk2->{'Name'}) {
					$percentfreespace = 100 * ($log_diskfreemb / ($disk2->{'Size'} / 1048576));
				}
			}
		}

		my $log_diskqueuelength             = $disk->{CurrentDiskQueueLength};
		my $log_avgdiskbytesperread         = $disk->{AvgDiskBytesPerRead};
		my $log_avgdiskbytesperreadbase     = $disk->{AvgDiskBytesPerRead_Base};
		my $log_avgdiskbytespertransfer     = $disk->{AvgDiskBytesPerTransfer};
		my $log_avgdiskbytespertransferbase = $disk->{AvgDiskBytesPerTransfer_Base};
		my $log_avgdiskbytesperwrite        = $disk->{AvgDiskBytesPerWrite};
		my $log_avgdiskbytesperwritebase    = $disk->{AvgDiskBytesPerWrite_Base};
		my $log_avgdiskqueuelength          = $disk->{AvgDiskQueueLength};
		my $log_avgdiskreadqueuelength      = $disk->{AvgDiskReadQueueLength};
		my $log_avgdiskwritequeuelength     = $disk->{AvgDiskWriteQueueLength};
		my $log_avgdisksecperread           = $disk->{AvgDisksecPerRead};
		my $log_avgdisksecpertransfer       = $disk->{AvgDisksecPerTransfer};
		my $log_avgdisksecperwrite          = $disk->{AvgDisksecPerWrite};
		my $log_avgdisksecperread_base      = $disk->{AvgDisksecPerRead_Base};
		my $log_avgdisksecpertransfer_base  = $disk->{AvgDisksecPerTransfer_Base};
		my $log_avgdisksecperwrite_base     = $disk->{AvgDisksecPerWrite_Base};
		my $log_diskbytespersec             = $disk->{DiskBytesPersec};
		my $log_diskreadbytespersec         = $disk->{DiskReadBytesPersec};
		my $log_diskreadspersec             = $disk->{DiskReadsPersec};
		my $log_disktransferspersec         = $disk->{DiskTransfersPersec};
		my $log_diskwritebytespersec        = $disk->{DiskWriteBytesPersec};
		my $log_diskwritespersec            = $disk->{DiskWritesPersec};
		my $log_frequencyobject             = $disk->{Frequency_Object};
		my $log_timestampsys100ns           = $disk->{Timestamp_Sys100NS};
		my $log_frequencysys100ns           = $disk->{Frequency_Sys100NS};
		my $log_percentdiskreadtime         = $disk->{PercentDiskReadTime};
		my $log_percentdiskreadtimebase     = $disk->{PercentDiskReadTime_Base};
		my $log_percentdisktime             = $disk->{PercentDiskTime};
		my $log_percentdisktimebase         = $disk->{PercentDiskTime_Base};
		my $log_percentdiskwritetime        = $disk->{PercentDiskWriteTime};
		my $log_percentdiskwritetimebase    = $disk->{PercentDiskWriteTime_Base};
		my $log_percentidletime             = $disk->{PercentIdleTime};
		my $log_percentidletimebase         = $disk->{PercentIdleTime_Base};
		my $log_splitiopersec               = $disk->{SplitIOPerSec};
		my $log_timestampobject             = $disk->{Timestamp_Object};
		my $log_timestampperftime           = $disk->{Timestamp_PerfTime};
		my $log_frequencyperftime           = $disk->{Frequency_PerfTime};

		#Define the second run variables
		my $log2_diskname;
		my $log2_percentfreespace;
		my $log2_avgdiskbytesperread;
		my $log2_avgdiskbytesperreadbase;
		my $log2_avgdiskbytespertransfer;
		my $log2_avgdiskbytespertransferbase;
		my $log2_avgdiskbytesperwrite;
		my $log2_avgdiskbytesperwritebase;
		my $log2_avgdiskqueuelength;
		my $log2_avgdiskreadqueuelength;
		my $log2_avgdiskwritequeuelength;
		my $log2_avgdisksecperread;
		my $log2_avgdisksecpertransfer;
		my $log2_avgdisksecperwrite;
		my $log2_diskbytespersec;
		my $log2_diskreadbytespersec;
		my $log2_diskreadspersec;
		my $log2_disktransferspersec;
		my $log2_diskwritebytespersec;
		my $log2_diskwritespersec;
		my $log2_frequencyobject;
		my $log2_timestampsys100ns;
		my $log2_frequencysys100ns;
		my $log2_percentdiskreadtime;
		my $log2_percentdiskreadtimebase;
		my $log2_percentdisktime;
		my $log2_percentdisktimebase;
		my $log2_percentdiskwritetime;
		my $log2_percentdiskwritetimebase;
		my $log2_percentidletime;
		my $log2_percentidletimebase;
		my $log2_splitiopersec;
		my $log2_timestampobject;
		my $log2_timestampperftime;
		my $log2_frequencyperftime;
		my $log2_diskqueuelength;
		my $log2_avgdisksecperread_base;
		my $log2_avgdisksecpertransfer_base;
		my $log2_avgdisksecperwrite_base;

		foreach my $disk (@{$colDiskPerf2}) {
			my $log2_diskname = $disk->{Name};

			#Skip to next disk if this one is not the match for the first iteration
			next unless $log2_diskname eq $log_diskname;

			#If they do match, go forward
			$log2_diskqueuelength             = $disk->{CurrentDiskQueueLength};
			$log2_avgdiskbytesperread         = $disk->{AvgDiskBytesPerRead};
			$log2_avgdiskbytesperreadbase     = $disk->{AvgDiskBytesPerRead_Base};
			$log2_avgdiskbytespertransfer     = $disk->{AvgDiskBytesPerTransfer};
			$log2_avgdiskbytespertransferbase = $disk->{AvgDiskBytesPerTransfer_Base};
			$log2_avgdiskbytesperwrite        = $disk->{AvgDiskBytesPerWrite};
			$log2_avgdiskbytesperwritebase    = $disk->{AvgDiskBytesPerWrite_Base};
			$log2_avgdiskqueuelength          = $disk->{AvgDiskQueueLength};
			$log2_avgdiskreadqueuelength      = $disk->{AvgDiskReadQueueLength};
			$log2_avgdiskwritequeuelength     = $disk->{AvgDiskWriteQueueLength};
			$log2_avgdisksecperread           = $disk->{AvgDisksecPerRead};
			$log2_avgdisksecpertransfer       = $disk->{AvgDisksecPerTransfer};
			$log2_avgdisksecperwrite          = $disk->{AvgDisksecPerWrite};
			$log2_avgdisksecperread_base      = $disk->{AvgDisksecPerRead_Base};
			$log2_avgdisksecpertransfer_base  = $disk->{AvgDisksecPerTransfer_Base};
			$log2_avgdisksecperwrite_base     = $disk->{AvgDisksecPerWrite_Base};
			$log2_diskbytespersec             = $disk->{DiskBytesPersec};
			$log2_diskreadbytespersec         = $disk->{DiskReadBytesPersec};
			$log2_diskreadspersec             = $disk->{DiskReadsPersec};
			$log2_disktransferspersec         = $disk->{DiskTransfersPersec};
			$log2_diskwritebytespersec        = $disk->{DiskWriteBytesPersec};
			$log2_diskwritespersec            = $disk->{DiskWritesPersec};
			$log2_frequencyobject             = $disk->{Frequency_Object};
			$log2_timestampsys100ns           = $disk->{Timestamp_Sys100NS};
			$log2_frequencysys100ns           = $disk->{Frequency_Sys100NS};
			$log2_percentdiskreadtime         = $disk->{PercentDiskReadTime};
			$log2_percentdiskreadtimebase     = $disk->{PercentDiskReadTime_Base};
			$log2_percentdisktime             = $disk->{PercentDiskTime};
			$log2_percentdisktimebase         = $disk->{PercentDiskTime_Base};
			$log2_percentdiskwritetime        = $disk->{PercentDiskWriteTime};
			$log2_percentdiskwritetimebase    = $disk->{PercentDiskWriteTime_Base};
			$log2_percentidletime             = $disk->{PercentIdleTime};
			$log2_percentidletimebase         = $disk->{PercentIdleTime_Base};
			$log2_splitiopersec               = $disk->{SplitIOPerSec};
			$log2_timestampobject             = $disk->{Timestamp_Object};
			$log2_timestampperftime           = $disk->{Timestamp_PerfTime};
			$log2_frequencyperftime           = $disk->{Frequency_PerfTime};
		}

		#Here, we do an evail around all cooked values to make sure that they work
		#otherwise, we just insert null values
		#calculate % disk time
		my $percent_disk_time    = undef;
		my $percent_idle_time    = undef;
		my $percent_read_time    = undef;
		my $percent_write_time   = undef;
		my $avg_bytes_read       = undef;
		my $avg_bytes_write      = undef;
		my $avg_bytes_transfer   = undef;
		my $avg_que_length       = undef;
		my $avg_que_length_write = undef;
		my $avg_que_length_read  = undef;
		my $avg_sec_read         = undef;
		my $avg_sec_write        = undef;
		my $avg_sec_transfer     = undef;
		my $bytes_read_sec       = undef;
		my $bytes_write_sec      = undef;
		my $bytes_sec            = undef;
		my $disk_reads_sec       = undef;
		my $disk_writes_sec      = undef;
		my $disk_transfers_sec   = undef;
		my $split_io_sec         = undef;
		eval {
			$percent_disk_time = perf_precision_100ns_timer(
				$log_percentdisktime,
				$log2_percentdisktime,
				$log_percentdisktimebase,
				$log2_percentdisktimebase
			);
			$percent_idle_time = perf_precision_100ns_timer(
				$log_percentidletime,
				$log2_percentidletime,
				$log_percentidletimebase,
				$log2_percentidletimebase
			);
			$percent_read_time = perf_precision_100ns_timer(
				$log_percentdiskreadtime,
				$log2_percentdiskreadtime,
				$log_percentdiskreadtimebase,
				$log2_percentdiskreadtimebase
			);
			$percent_write_time = perf_precision_100ns_timer(
				$log_percentdiskwritetime,
				$log2_percentdiskwritetime,
				$log_percentdiskwritetimebase,
				$log2_percentdiskwritetimebase
			);

			#calculate averages for the disk transfers
			$avg_bytes_read = perf_avg_bulk(
				$log_avgdiskbytesperread,
				$log2_avgdiskbytesperread,
				$log_avgdiskbytesperreadbase,
				$log2_avgdiskbytesperreadbase
			);
			$avg_bytes_transfer = perf_avg_bulk(
				$log_avgdiskbytespertransfer,
				$log2_avgdiskbytespertransfer,
				$log_avgdiskbytespertransferbase,
				$log2_avgdiskbytespertransferbase
			);
			$avg_bytes_write = perf_avg_bulk(
				$log_avgdiskbytesperwrite,
				$log2_avgdiskbytesperwrite,
				$log_avgdiskbytesperwritebase,
				$log2_avgdiskbytesperwritebase
			);

			#calculate averages for time based readings
			$avg_que_length = perf_counter_100ns_queuelen_type(
				$log_avgdiskqueuelength,
				$log2_avgdiskqueuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_que_length_write = perf_counter_100ns_queuelen_type(
				$log_avgdiskwritequeuelength,
				$log2_avgdiskwritequeuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_que_length_read = perf_counter_100ns_queuelen_type(
				$log_avgdiskreadqueuelength,
				$log2_avgdiskreadqueuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_sec_read = 10000 * (
				perf_avg_timer(
					$log_avgdisksecperread,
					$log2_avgdisksecperread,
					$log2_frequencyperftime,
					$log_avgdisksecperread_base,
					$log2_avgdisksecperread_base
				));
			$avg_sec_write = 10000 * (
				perf_avg_timer(
					$log_avgdisksecperwrite,
					$log2_avgdisksecperwrite,
					$log2_frequencyperftime,
					$log_avgdisksecperwrite_base,
					$log2_avgdisksecperwrite_base
				));
			$avg_sec_transfer = 10000 * (
				perf_avg_timer(
					$log_avgdisksecpertransfer,
					$log2_avgdisksecpertransfer,
					$log2_frequencyperftime,
					$log_avgdisksecpertransfer_base,
					$log2_avgdisksecpertransfer_base
				));
			$bytes_read_sec = perf_counter_counter(
				$log_diskreadbytespersec,
				$log2_diskreadbytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$bytes_write_sec = perf_counter_counter(
				$log_diskwritebytespersec,
				$log2_diskwritebytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$bytes_sec = perf_counter_counter(
				$log_diskbytespersec,
				$log2_diskbytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_reads_sec = perf_counter_counter(
				$log_diskreadspersec,
				$log2_diskreadspersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_writes_sec = perf_counter_counter(
				$log_diskwritespersec,
				$log2_diskwritespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_transfers_sec = perf_counter_counter(
				$log_disktransferspersec,
				$log2_disktransferspersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$split_io_sec = perf_counter_counter(
				$log_splitiopersec,
				$log2_splitiopersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
		}; if ($@) {
			$logger->error(sprintf('caught fault in disk processing: %s', $@));
		}

		$winperfdisk_rawdata_insert->execute(
			$deviceid,
			$log_diskname,
			$scantime,
			$log_diskfreemb,
			$log_diskpercentfree,
			$log_percentfreespacebase
		);
		$winsth4->execute(
			$deviceid,
			$log_diskname,
			$percentfreespace,
			$log_diskfreemb,
			$log_diskqueuelength,
			$scantime,
			$log_avgdiskbytesperread,
			$log_avgdiskbytespertransfer,
			$log_avgdiskbytesperwrite,
			$log_avgdiskqueuelength,
			$log_avgdiskreadqueuelength,
			$log_avgdiskwritequeuelength,
			$log_avgdisksecperread,
			$log_avgdisksecpertransfer,
			$log_avgdisksecperwrite,
			$log_diskbytespersec,
			$log_diskreadbytespersec,
			$log_diskreadspersec,
			$log_disktransferspersec,
			$log_diskwritebytespersec,
			$log_diskwritespersec,
			$log_frequencyobject,
			$log_frequencyperftime,
			$log_frequencysys100ns,
			$log_percentdiskreadtime,
			$log_percentdisktime,
			$log_percentdiskwritetime,
			$log_percentidletime,
			$split_io_sec,
			$log_timestampobject,
			$log_timestampperftime,
			$log_timestampsys100ns,
			$avg_bytes_read,
			$avg_bytes_transfer,
			$avg_bytes_write,
			$avg_que_length,
			$avg_que_length_read,
			$avg_que_length_write,
			$avg_sec_read,
			$avg_sec_write,
			$avg_sec_transfer,
			$bytes_sec,
			$bytes_read_sec,
			$bytes_write_sec,
			$disk_transfers_sec,
			$disk_writes_sec,
			$disk_reads_sec,
			$percent_disk_time,
			$percent_read_time,
			$percent_write_time,
			$percent_idle_time,
			$log_avgdiskbytesperreadbase,
			$log_avgdiskbytespertransferbase,
			$log_avgdiskbytesperwritebase,
			$log_percentdiskreadtimebase,
			$log_percentdisktimebase,
			$log_percentdiskwritetimebase,
			$log_percentidletimebase
		);
	}
	$summary->{'diskutil'} = $scantime if (scalar @{$colDiskPerf} > 0);

	##Pull Physical Disk Performance Information
	foreach my $disk (@{$colDiskPerfPhysDisk}) {
		my $log_diskname		    = $disk->{Name};
		my $log_diskqueuelength             = $disk->{CurrentDiskQueueLength};
		my $log_avgdiskbytesperread         = $disk->{AvgDiskBytesPerRead};
		my $log_avgdiskbytesperreadbase     = $disk->{AvgDiskBytesPerRead_Base};
		my $log_avgdiskbytespertransfer     = $disk->{AvgDiskBytesPerTransfer};
		my $log_avgdiskbytespertransferbase = $disk->{AvgDiskBytesPerTransfer_Base};
		my $log_avgdiskbytesperwrite        = $disk->{AvgDiskBytesPerWrite};
		my $log_avgdiskbytesperwritebase    = $disk->{AvgDiskBytesPerWrite_Base};
		my $log_avgdiskqueuelength          = $disk->{AvgDiskQueueLength};
		my $log_avgdiskreadqueuelength      = $disk->{AvgDiskReadQueueLength};
		my $log_avgdiskwritequeuelength     = $disk->{AvgDiskWriteQueueLength};
		my $log_avgdisksecperread           = $disk->{AvgDisksecPerRead};
		my $log_avgdisksecpertransfer       = $disk->{AvgDisksecPerTransfer};
		my $log_avgdisksecperwrite          = $disk->{AvgDisksecPerWrite};
		my $log_avgdisksecperread_base      = $disk->{AvgDisksecPerRead_Base};
		my $log_avgdisksecpertransfer_base  = $disk->{AvgDisksecPerTransfer_Base};
		my $log_avgdisksecperwrite_base     = $disk->{AvgDisksecPerWrite_Base};
		my $log_diskbytespersec             = $disk->{DiskBytesPersec};
		my $log_diskreadbytespersec         = $disk->{DiskReadBytesPersec};
		my $log_diskreadspersec             = $disk->{DiskReadsPersec};
		my $log_disktransferspersec         = $disk->{DiskTransfersPersec};
		my $log_diskwritebytespersec        = $disk->{DiskWriteBytesPersec};
		my $log_diskwritespersec            = $disk->{DiskWritesPersec};
		my $log_frequencyobject             = $disk->{Frequency_Object};
		my $log_timestampsys100ns           = $disk->{Timestamp_Sys100NS};
		my $log_frequencysys100ns           = $disk->{Frequency_Sys100NS};
		my $log_percentdiskreadtime         = $disk->{PercentDiskReadTime};
		my $log_percentdiskreadtimebase     = $disk->{PercentDiskReadTime_Base};
		my $log_percentdisktime             = $disk->{PercentDiskTime};
		my $log_percentdisktimebase         = $disk->{PercentDiskTime_Base};
		my $log_percentdiskwritetime        = $disk->{PercentDiskWriteTime};
		my $log_percentdiskwritetimebase    = $disk->{PercentDiskWriteTime_Base};
		my $log_percentidletime             = $disk->{PercentIdleTime};
		my $log_percentidletimebase         = $disk->{PercentIdleTime_Base};
		my $log_splitiopersec               = $disk->{SplitIOPerSec};
		my $log_timestampobject             = $disk->{Timestamp_Object};
		my $log_timestampperftime           = $disk->{Timestamp_PerfTime};
		my $log_frequencyperftime           = $disk->{Frequency_PerfTime};
		##Define the second pass variables
		my $log2_avgdiskbytesperread;
		my $log2_avgdiskbytesperreadbase;
		my $log2_avgdiskbytespertransfer;
		my $log2_avgdiskbytespertransferbase;
		my $log2_avgdiskbytesperwrite;
		my $log2_avgdiskbytesperwritebase;
		my $log2_avgdiskqueuelength;
		my $log2_avgdiskreadqueuelength;
		my $log2_avgdiskwritequeuelength;
		my $log2_avgdisksecperread;
		my $log2_avgdisksecpertransfer;
		my $log2_avgdisksecperwrite;
		my $log2_diskbytespersec;
		my $log2_diskreadbytespersec;
		my $log2_diskreadspersec;
		my $log2_disktransferspersec;
		my $log2_diskwritebytespersec;
		my $log2_diskwritespersec;
		my $log2_frequencyobject;
		my $log2_timestampsys100ns;
		my $log2_frequencysys100ns;
		my $log2_percentdiskreadtime;
		my $log2_percentdiskreadtimebase;
		my $log2_percentdisktime;
		my $log2_percentdisktimebase;
		my $log2_percentdiskwritetime;
		my $log2_percentdiskwritetimebase;
		my $log2_percentidletime;
		my $log2_percentidletimebase;
		my $log2_splitiopersec;
		my $log2_timestampobject;
		my $log2_timestampperftime;
		my $log2_frequencyperftime;
		my $log2_diskname;
		my $log2_avgdisksecperread_base;
		my $log2_avgdisksecpertransfer_base;
		my $log2_avgdisksecperwrite_base;
		my $log2_diskqueuelength;

		#Iterate second pass to cook stats
		foreach my $resultset (@{$colDiskPerfPhysDisk2}) {
			$log2_diskname = $resultset->{Name};
			next unless $log2_diskname eq $log_diskname;
			$log2_diskqueuelength             = $resultset->{CurrentDiskQueueLength};
			$log2_avgdiskbytesperread         = $resultset->{AvgDiskBytesPerRead};
			$log2_avgdiskbytesperreadbase     = $resultset->{AvgDiskBytesPerRead_Base};
			$log2_avgdiskbytespertransfer     = $resultset->{AvgDiskBytesPerTransfer};
			$log2_avgdiskbytespertransferbase = $resultset->{AvgDiskBytesPerTransfer_Base};
			$log2_avgdiskbytesperwrite        = $resultset->{AvgDiskBytesPerWrite};
			$log2_avgdiskbytesperwritebase    = $resultset->{AvgDiskBytesPerWrite_Base};
			$log2_avgdiskqueuelength          = $resultset->{AvgDiskQueueLength};
			$log2_avgdiskreadqueuelength      = $resultset->{AvgDiskReadQueueLength};
			$log2_avgdiskwritequeuelength     = $resultset->{AvgDiskWriteQueueLength};
			$log2_avgdisksecperread           = $resultset->{AvgDisksecPerRead};
			$log2_avgdisksecpertransfer       = $resultset->{AvgDisksecPerTransfer};
			$log2_avgdisksecperwrite          = $resultset->{AvgDisksecPerWrite};
			$log2_avgdisksecperread_base      = $resultset->{AvgDisksecPerRead_Base};
			$log2_avgdisksecpertransfer_base  = $resultset->{AvgDisksecPerTransfer_Base};
			$log2_avgdisksecperwrite_base     = $resultset->{AvgDisksecPerWrite_Base};
			$log2_diskbytespersec             = $resultset->{DiskBytesPersec};
			$log2_diskreadbytespersec         = $resultset->{DiskReadBytesPersec};
			$log2_diskreadspersec             = $resultset->{DiskReadsPersec};
			$log2_disktransferspersec         = $resultset->{DiskTransfersPersec};
			$log2_diskwritebytespersec        = $resultset->{DiskWriteBytesPersec};
			$log2_diskwritespersec            = $resultset->{DiskWritesPersec};
			$log2_frequencyobject             = $resultset->{Frequency_Object};
			$log2_timestampsys100ns           = $resultset->{Timestamp_Sys100NS};
			$log2_frequencysys100ns           = $resultset->{Frequency_Sys100NS};
			$log2_percentdiskreadtime         = $resultset->{PercentDiskReadTime};
			$log2_percentdiskreadtimebase     = $resultset->{PercentDiskReadTime_Base};
			$log2_percentdisktime             = $resultset->{PercentDiskTime};
			$log2_percentdisktimebase         = $resultset->{PercentDiskTime_Base};
			$log2_percentdiskwritetime        = $resultset->{PercentDiskWriteTime};
			$log2_percentdiskwritetimebase    = $resultset->{PercentDiskWriteTime_Base};
			$log2_percentidletime             = $resultset->{PercentIdleTime};
			$log2_percentidletimebase         = $resultset->{PercentIdleTime_Base};
			$log2_splitiopersec               = $resultset->{SplitIOPerSec};
			$log2_timestampobject             = $resultset->{Timestamp_Object};
			$log2_timestampperftime           = $resultset->{Timestamp_PerfTime};
			$log2_frequencyperftime           = $resultset->{Frequency_PerfTime};
		}

		#Here, we do an evail around all cooked values to make sure that they work
		#otherwise, we just insert null values
		#calculate % disk time
		my $percent_disk_time    = undef;
		my $percent_idle_time    = undef;
		my $percent_read_time    = undef;
		my $percent_write_time   = undef;
		my $avg_bytes_read       = undef;
		my $avg_bytes_write      = undef;
		my $avg_bytes_transfer   = undef;
		my $avg_que_length       = undef;
		my $avg_que_length_write = undef;
		my $avg_que_length_read  = undef;
		my $avg_sec_read         = undef;
		my $avg_sec_write        = undef;
		my $avg_sec_transfer     = undef;
		my $bytes_read_sec       = undef;
		my $bytes_write_sec      = undef;
		my $bytes_sec            = undef;
		my $disk_reads_sec       = undef;
		my $disk_writes_sec      = undef;
		my $disk_transfers_sec   = undef;
		my $split_io_sec         = undef;
		eval {
			$percent_disk_time = perf_precision_100ns_timer(
				$log_percentdisktime,
				$log2_percentdisktime,
				$log_percentdisktimebase,
				$log2_percentdisktimebase
			);
			$percent_idle_time = perf_precision_100ns_timer(
				$log_percentidletime,
				$log2_percentidletime,
				$log_percentidletimebase,
				$log2_percentidletimebase
			);
			$percent_read_time = perf_precision_100ns_timer(
				$log_percentdiskreadtime,
				$log2_percentdiskreadtime,
				$log_percentdiskreadtimebase,
				$log2_percentdiskreadtimebase
			);
			$percent_write_time = perf_precision_100ns_timer(
				$log_percentdiskwritetime,
				$log2_percentdiskwritetime,
				$log_percentdiskwritetimebase,
				$log2_percentdiskwritetimebase
			);

			#calculate averages for the disk transfers
			$avg_bytes_read = perf_avg_bulk(
				$log_avgdiskbytesperwrite,
				$log2_avgdiskbytesperwrite,
				$log_avgdiskbytesperwritebase,
				$log2_avgdiskbytesperwritebase
			);
			$avg_bytes_transfer = perf_avg_bulk(
				$log_avgdiskbytespertransfer,
				$log2_avgdiskbytespertransfer,
				$log_avgdiskbytespertransferbase,
				$log2_avgdiskbytespertransferbase
			);
			$avg_bytes_write = perf_avg_bulk(
				$log_avgdiskbytesperwrite,
				$log2_avgdiskbytesperwrite,
				$log_avgdiskbytesperwritebase,
				$log2_avgdiskbytesperwritebase
			);

			#calculate averages for time based readings
			$avg_que_length = perf_counter_100ns_queuelen_type(
				$log_avgdiskqueuelength,
				$log2_avgdiskqueuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_que_length_write = perf_counter_100ns_queuelen_type(
				$log_avgdiskwritequeuelength,
				$log2_avgdiskwritequeuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_que_length_read = perf_counter_100ns_queuelen_type(
				$log_avgdiskreadqueuelength,
				$log2_avgdiskreadqueuelength,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$avg_sec_read = 10000 * (
				perf_avg_timer(
					$log_avgdisksecperread,
					$log2_avgdisksecperread,
					$log2_frequencyperftime,
					$log_avgdisksecperread_base,
					$log2_avgdisksecperread_base
				));
			$avg_sec_write = 10000 * (
				perf_avg_timer(
					$log_avgdisksecperwrite,
					$log2_avgdisksecperwrite,
					$log2_frequencyperftime,
					$log_avgdisksecperwrite_base,
					$log2_avgdisksecperwrite_base
				));
			$avg_sec_transfer = 10000 * (
				perf_avg_timer(
					$log_avgdisksecpertransfer,
					$log2_avgdisksecpertransfer,
					$log2_frequencyperftime,
					$log_avgdisksecpertransfer_base,
					$log2_avgdisksecpertransfer_base
				));
			$bytes_read_sec = perf_counter_counter(
				$log_diskreadbytespersec,
				$log2_diskreadbytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$bytes_write_sec = perf_counter_counter(
				$log_diskwritebytespersec,
				$log2_diskwritebytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$bytes_sec = perf_counter_counter(
				$log_diskbytespersec,
				$log2_diskbytespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_reads_sec = perf_counter_counter(
				$log_diskreadspersec,
				$log2_diskreadspersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_writes_sec = perf_counter_counter(
				$log_diskwritespersec,
				$log2_diskwritespersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$disk_transfers_sec = perf_counter_counter(
				$log_disktransferspersec,
				$log2_disktransferspersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
			$split_io_sec = perf_counter_counter(
				$log_splitiopersec,
				$log2_splitiopersec,
				$log2_frequencyperftime,
				$log_timestampperftime,
				$log2_timestampperftime
			);
		}; if ($@) {
			$logger->error(sprintf('caught fault in disk processing: %s', $@));
		}

		my $percentfreespace;
		my $log_diskfreemb;
		$winsth5->execute(
			$deviceid,
			$log_diskname,
			$percentfreespace,
			$log_diskfreemb,
			$log_diskqueuelength,
			$scantime,
			$log_avgdiskbytesperread,
			$log_avgdiskbytespertransfer,
			$log_avgdiskbytesperwrite,
			$log_avgdiskqueuelength,
			$log_avgdiskreadqueuelength,
			$log_avgdiskwritequeuelength,
			$log_avgdisksecperread,
			$log_avgdisksecpertransfer,
			$log_avgdisksecperwrite,
			$log_diskbytespersec,
			$log_diskreadbytespersec,
			$log_diskreadspersec,
			$log_disktransferspersec,
			$log_diskwritebytespersec,
			$log_diskwritespersec,
			$log_frequencyobject,
			$log_frequencyperftime,
			$log_frequencysys100ns,
			$log_percentdiskreadtime,
			$log_percentdisktime,
			$log_percentdiskwritetime,
			$log_percentidletime,
			$split_io_sec,
			$log_timestampobject,
			$log_timestampperftime,
			$log_timestampsys100ns,
			$avg_bytes_read,
			$avg_bytes_transfer,
			$avg_bytes_write,
			$avg_que_length,
			$avg_que_length_read,
			$avg_que_length_write,
			$avg_sec_read,
			$avg_sec_write,
			$avg_sec_transfer,
			$bytes_sec,
			$bytes_read_sec,
			$bytes_write_sec,
			$disk_transfers_sec,
			$disk_writes_sec,
			$disk_reads_sec,
			$percent_disk_time,
			$percent_read_time,
			$percent_write_time,
			$percent_idle_time,
			$log_avgdiskbytesperreadbase,
			$log_avgdiskbytespertransferbase,
			$log_avgdiskbytesperwritebase,
			$log_percentdiskreadtimebase,
			$log_percentdisktimebase,
			$log_percentdiskwritetimebase,
			$log_percentidletimebase
		);
	}
	$summary->{'diskio'} = $scantime if ((scalar @{$colDiskPerf} > 0) and (scalar @{$colDiskPerfPhysDisk} > 0));
	$col2008Disk         = undef;
	$col2008Disk2        = undef;
	$colDiskPerf         = undef;
	$colDiskPerf2        = undef;
}

sub perf_avg_timer {
	#This formula is as follows: ((Counter1-Counter0)/FreqPerfTime)/Base1-Base0)
	my $c0     = shift;
	my $c1     = shift;
	my $fpt    = shift;
	my $b0     = shift;
	my $b1     = shift;
	my $return = 0;

	if (defined $c0 && defined $c1 && defined $fpt && defined $b0 && defined $b1) {
		if ($b1 != $b0) {
			$return = ((abs($c1 - $c0) / $fpt) / (abs($b1 - $b0)));
		} else {
			$return = (abs($c1 - $c0) / $fpt);
		}
	}
	return $return;
}

sub perf_counter_100ns_queuelen_type {
	#This formula is as follows: (Counter2-Counter1) / (TimeValue2-TimeValue1)
	my $c0     = shift;
	my $c1     = shift;
	my $tb     = shift;
	my $b0     = shift;
	my $b1     = shift;
	my $return = 0;

	if (defined $c0 && defined $c1 && defined $tb && defined $b0 && defined $b1) {
		if ($b1 != $b0) {
			$return = (abs($c1 - $c0)) / abs($b1 - $b0);
		} else {
			$return = 0;
		}
	}
	return $return;
}

sub perf_counter_counter {
	#This formula is as follows: (CounterValue2 - CounterValue1) / ((TimeValue2 - TimeValue1) / TimeBase)
	my $c0     = shift;
	my $c1     = shift;
	my $tb     = shift;
	my $b0     = shift;
	my $b1     = shift;
	my $return = 0;

	if (defined $c0 && defined $c1 && defined $tb && defined $b0 && defined $b1) {
		if ($b1 != $b0) {
			$return = (abs($c1 - $c0) / (abs($b1 - $b0) / $tb));
		} else {
			$return = abs($c1 - $c0);
		}
	}
	return $return;
}

sub perf_precision_100ns_timer {
	#This formula is as follows (CounterValue2 - CounterValue1) / (BaseValue 2 - BaseValue1)
	my $c0     = shift;
	my $c1     = shift;
	my $b0     = shift;
	my $b1     = shift;
	my $return = 0;

	if (defined $c0 && defined $c1 && defined $b0 && defined $b1) {
		if ($b0 != $b1) {
			$return = (abs($c1 - $c0) / abs($b1 - $b0)) * 100;
		} else {
			$return = 0;
		}
	}
	return $return;
}

sub perf_avg_bulk {
	#This formula is as follows (CounterValue2 - CounterValue1) / (BaseValue 2 - BaseValue1)
	my $c0     = shift;
	my $c1     = shift;
	my $b0     = shift;
	my $b1     = shift;
	my $return = 0;

	if (defined $c0 && defined $c1 && defined $b0 && defined $b1) {
		if ($b0 != $b1) {
			$return = abs($c1 - $c0) / abs($b1 - $b0);
		} else {
			$return = 0;
		}
	}
	return $return;
}
