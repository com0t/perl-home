#!/usr/bin/env perl
#
##
use strict;
use warnings;

use Data::Dumper;

use RISC::riscDataUpload;
use RISC::riscUtility;
use RISC::riscWebservice;
use RISC::Collect::Logger;
use RISC::Event qw( collector_alarm );
use RISC::Collect::PerfScheduler;

my $logger = RISC::Collect::Logger->new('data-upload-modular');

# make sure we are not locked for FDP migration:
if (-e '/home/risc/fdp_migration/fdp_migration_lock') {
	$logger->warn("cannot run dataup while rn150 is in fdp_migration_lock state");
	printf("||&||aborted due to fdp_migration_lock||&||\n");
	exit(1);
}

## this is the script return that can be safely returned to RISC (dataplane separation)
##  this will be modified during execution if something needs to be returned
my $sanitary_output;

my $successbit = 1;

## the interval we should sleep before retrying a failed upload
my $retry_sleep = 10;

## certain local storage metrics determine various behaviors of the process
my $disk_util_threshold = 40;  ## local storage utilization threshold, multiple uses
my $disk_alarm_threshold = 80; ## local storage utilization threshold for alarming to headend

my $runtime	= time();

## cron initiated runs will not provide an argument, triggering automated determination of all types that need to upload
## otherwise, an argument is treated as an explicit single type to upload
my $explicit_type = shift;

#make sure we're cron'd up
addToCron();

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

my $assesscodeQuery = $mysql->selectrow_hashref("
	SELECT productkey AS assesscode
	FROM risc_discovery.credentials
	WHERE technology = 'appliance'
");
my $assesscode = $assesscodeQuery->{'assesscode'};

#first check if were are in perf
my $perftime;
my $attempts = 3;
sleep(10) while (!defined($perftime = riscWebservice::checkPerfStart($assesscode)) && --$attempts);

## check to see if the call failed
if (!defined($perftime)) {
	my $message = 'failure calling checkPerfStart';
	collector_alarm('upload-perf-start', $0, $message);
	$logger->error_die($message);
}

my $perf_scheduler = RISC::Collect::PerfScheduler->new();

## here, $perftime should be either 0 or a valid unix_timestamp
unless ($perftime || $explicit_type =~ /inventory/ || $explicit_type eq 'allperf') {
	$logger->warn(sprintf('matched not-in-perf-usage with perf time %s', $perftime));

	#pause perf if we're not in perf
	$perf_scheduler->stop('all', { kill => 1 });
	if (checkUsage('Not in perf usage') < $disk_util_threshold) {
		$logger->info('not in performance state and no explicit type, stopping');
		exit(0);
	} else {
		my $message = 'deleting flow, vmware data due to storage pressure outside of the performance state';
		$logger->warn($message);
		collector_alarm('deleting-data', $0, $message);
		#here we need to clear out some data as we aren't in perf and we're collecting
		$mysql->do("delete from netflowtoprn50");
		$mysql->do("delete from vmwareperf_cpu");
		$mysql->do("delete from vmwareperf_mem");
		$mysql->do("delete from vmwareperf_net");
		$mysql->do("delete from vmwareperf_disk");
		$mysql->do("delete from vmwareperf_sys");
		$mysql->do("delete from service_configuration");
		if (checkUsage('Not in perf 2 usage') > $disk_util_threshold) {
			#we're still too high -- get rid of winperf, netperf, and ccm
			$message = 'deleting traffic, windows, ccm data due to storage pressure outside of the performance state';
			$logger->warn($message);
			collector_alarm('deleting-data', $0, $message);
			$mysql->do("delete from deviceperformance");
			$mysql->do("delete from traffic");
			$mysql->do("delete from traffic_raw");
			$mysql->do("delete from traffic_inst");
			$mysql->do("delete from winperfdisk");
			$mysql->do("delete from winperfcpu");
			$mysql->do("delete from winperfmem");
			$mysql->do("delete from winperfnet");
			$mysql->do("delete from winperfphysdisk");
			$mysql->do("delete from winperfprocess");
			$mysql->do("delete from windowsconnection");
			$mysql->do("delete from windowsdnscache");
			$mysql->do("delete from windowsprocess");
			$mysql->do("delete from ccm");
		}
		$logger->info('not in performance state and no explicit type, stopping');
		exit(1);
	}
}


#if this is an outside call (shepherd or vmware perf) run the requested upload and die
if (defined($explicit_type) && grep(/^\Q$explicit_type\E$/, ('allperf', @RISC::riscDataUpload::ALL_UPLOAD_TYPES))) {
	#if there is a data upload running, sleep until it is done - timeout after 30min
	my $totalsleep = 360;
	while (checkDupProcess() > 1) {
		$logger->info('waiting on another instance');
		#check for hung uploads (running for over 60min)
		my @cmdData = `ps -eo pid,etime,command|grep "[d]ataupload_modular_admin\.pl"`;
		foreach my $cmdInfo (@cmdData) {
			$cmdInfo =~ /(\d+)\s(.+)\s(.+)$/;
			my $pid = $1;
			my $dur = $2;
			my $cmd = $3;
			if ($dur =~ /\:\d\d\:/ && $pid != $$) { ##XXX this is fragile
				#we know it has been running over 60min because there are two :'s
				$logger->warn(sprintf(
					'dataupload_modular_admin at pid %d running over an hour, killing it',
					$pid
				));
				`kill -TERM $pid`; # use TERM so the signal handler in riscDataUpload.pm can do its thing
			}
		}
		sleep 5;
		$totalsleep--;
		if ($totalsleep == 0) {
			my $message = sprintf(
				'timeout waiting on another instance while attempting explicit type %s',
				$explicit_type
			);
			$logger->error($message);
			collector_alarm('script-timeout', $0, $message);
			exit(1);
		}
	}
	my @types;
	my @skipList = ();
	if ($explicit_type eq 'inventory') {
		#check if this is the first inventory
		my $invQuery = $mysql->selectrow_hashref("
			SELECT count(*) AS invs
			FROM dataupload_modular_log
			WHERE type = 'firstinventory'
		");
		$explicit_type = 'firstinventory' if ($invQuery->{'invs'} == 0);
	}
	if ($explicit_type eq 'allperf') {
		@types = @RISC::riscDataUpload::PERF_TYPES;
		my $RISCDB = riscUtility::getDBH('RISC_Discovery',1);
		my $skipList = buildSkipList($RISCDB, @RISC::riscDataUpload::ALL_UPLOAD_TYPES);
		@skipList = @{ $skipList };
		$RISCDB->disconnect();
	} else {
		@types = ( $explicit_type );
	}
	foreach my $type (@types) {
		my $RISCDB = riscUtility::getDBH('RISC_Discovery',1);
		$perf_scheduler->pause($type);
		my $retries = 0;
		while ($retries < 3) {
			eval {
				RISC::riscDataUpload::upload($assesscode, $type) unless (grep(/^\Q$type\E$/, @skipList));
			}; if ($@) {
				$retries++;
				if ($retries <= 2) {
					$logger->warn(sprintf(
						'failed attempt %d: %s',
						$retries,
						$@
					));
					$logger->info(sprintf('sleeping %d seconds for retry', $retry_sleep));
					sleep $retry_sleep;
				} elsif ($retries > 2) {
					$successbit = 0;
					collector_alarm(
						'upload-failure',
						$0,
						sprintf('failed %d attempts for %s: %s', $retries, $type, $@)
					);
				}
			} else {
				$successbit = 1;
				$logger->info(sprintf('successfully uploaded %s', $type));
				last;
			}
		}
		$perf_scheduler->resume($type);
		$RISCDB->disconnect();
	}
	if ($successbit) {
		$logger->info('upload succeeded');
		$sanitary_output = 'success';
	} else {
		$logger->error('upload failed');
		$sanitary_output = 'failure';
	}
} else {
	#if there is a data upload running die, we'll run in a minute again anyway
	if (checkDupProcess() > 1) {
		my @cmdData = `ps -eo pid,etime,command|grep "[d]ataupload_modular_admin\.pl"`;
		foreach my $cmdInfo (@cmdData) {
			$cmdInfo =~ /(\d+)\s(.+)\s(.+)$/;
			my $pid = $1;
			my $dur = $2;
			my $cmd = $3;
			if ($dur =~ /\:\d\d\:/ && $pid != $$) {
				#we know it has been running over 60min because there are two :'s
				$logger->warn(sprintf(
					'dataupload_modular_admin at pid %d running over an hour, killing it',
					$pid
				));
				`kill -TERM $pid`; # use TERM so the signal handler in riscDataUpload.pm can do its thing
			}
		}
		$logger->warn('stopping due to another instance running');
		die;
	}
	#grab current hd usage and build prioritized lists of upload types based on current perf running and last upload time
	my $dataUploadInfo = gatherInfo($runtime, @RISC::riscDataUpload::ALL_UPLOAD_TYPES);

	#run dataups on primary types
	runDataUploads($dataUploadInfo, 'primary', $assesscode);

	#if there is still an hd issue then run secondary
	runDataUploads($dataUploadInfo, 'secondary', $assesscode) if (checkUsage('post-primary usage') > $disk_util_threshold);

	#run tertiaries if there is still a disk space issue
	runDataUploads($dataUploadInfo, 'tertiary', $assesscode) if (checkUsage('post-secondary usage') > $disk_util_threshold);

	checkUsage('post-tertiary usage');
	#run vmware if we're still in trouble
	runDataUploads($dataUploadInfo, 'vmware', $assesscode) if (checkUsage('final usage') > $disk_util_threshold);
}
print '||&||' . $sanitary_output . '||&||' if defined($sanitary_output);

exit(0);

################################################################################################

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return scalar @proclist;
}

sub gatherInfo {
	my $runtime	= shift;
	my $perftime	= shift;
	my @uploadTypes	= @_;

	my $return;
	my $RISCDB = riscUtility::getDBH('RISC_Discovery',1);
	#build skip list bsaed on no perf data
	my $skipTypes = buildSkipList($RISCDB, @uploadTypes);

	#get hd in use, free , percentage
	$return->{'initialUsage'} = checkUsage('pre-upload usage');

	#now check timing of all uploadtypes except vmware,inventory, and allperf
	my @primary;		#these are types that have gone > 6 hrs or > 2 hour and perf is not running
	my @secondary;		#these are types that have have gone > 4 hrs regardless of perf
	my @tertiary;		#these are type that have gone > 1hr regardless of perf
	my $times;

	foreach my $uploadType (@uploadTypes) {
		next if (grep(/^\Q$uploadType\E$/, @{ $skipTypes }));
		my $gap = $runtime - checkUpTime($uploadType, $RISCDB);
		#set gap to time perf has been running if there has not yet been an upload (checkUpTime returns 0)
		$gap = $runtime - $perftime if ($gap == $runtime);

		my $is_running = $perf_scheduler->check($uploadType);
		## primary upload if:
		##	gap is greater than 6 hours
		##	gap is greater than 2 hours and perf is not currently in the process of running for this type
		##	gap is greater than 3 hours and perf type is trafwatch or trafsim
		if ($gap > (6 * 3600)|| ($gap > (2 * 3600) && (not $is_running)) || ($gap > (3 * 3600) && $uploadType =~ /^traf/)) {
			push (@primary,$uploadType);
			next;
		} elsif ($gap > (4 * 3600)) {
			push (@secondary,$uploadType);
			next;
		} elsif ($gap > 3600) {
			push (@tertiary,$uploadType) unless ($uploadType eq 'trafwatch');
			next;
		}
	}

	$return->{'primary'}	= \@primary;
	$return->{'secondary'}	= \@secondary;
	$return->{'tertiary'}	= \@tertiary;
	$return->{'vmware'}	= 'vmware';

	$logger->debug(sprintf('upload types: %s', Dumper($return)));

	return $return;
}

sub checkUsage {
	my $log	= shift;

	my $utilization = riscUtility::disk_utilization();

	if ($utilization == -1) {
		## -1 is returned upon a non-zero exit status from df, or otherwise invalid/unparsable result
		collector_alarm(
			'upload-disk-configuration',
			$0,
			"failed to obtain disk utilization"
		);
		return 0;
	}

	collector_alarm(
		'upload-storage-utilization',
		$0,
		sprintf('storage utilization over threshold: %s', $utilization)
	) if (($utilization > $disk_alarm_threshold) and ($log =~ /final/));

	return $utilization;
}

sub checkUpTime {
	my $uploadType	= shift;
	my $mysql	= shift;

	my $lastRun = $mysql->selectrow_hashref("
		SELECT scantime
		FROM dataupload_modular_log
		WHERE type = '$uploadType'
		ORDER BY scantime DESC
		LIMIT 1
	");

	return $lastRun->{'scantime'} if (defined($lastRun->{'scantime'}));
	return 0;
}

sub runDataUploads {
	my $dataUploadInfo	= shift;
	my $batchName		= shift;
	my $assesscode		= shift;

	my $uploads = "@{$dataUploadInfo->{$batchName}}";
	if ($uploads eq '') {
		$logger->info(sprintf('no types for batch %s', $batchName));
	} else {
		$logger->debug('processing batch %s', $batchName);
	}

	foreach my $uploadType (@{$dataUploadInfo->{$batchName}}) {
		$logger->info(sprintf('attempting %s for batch %s', $uploadType, $batchName));
		my $RISCDB = riscUtility::getDBH('RISC_Discovery',1);
		$perf_scheduler->pause($uploadType);
		my $retries = 0;
		while ($retries < 3) {
			eval {
				RISC::riscDataUpload::upload($assesscode, $uploadType);
			}; if ($@) {
				$retries++;
				if ($retries <= 2) {
					$logger->warn(sprintf(
						'failed attempt %d for %s: %s',
						$retries,
						$uploadType,
						$@
					));
					$logger->info(sprintf('sleeping %d seconds for retry', $retry_sleep));
					sleep $retry_sleep;
				} elsif ($retries > 2) {
					collector_alarm(
						'upload-failure',
						$0,
						sprintf('failed %d attempts for %s: %s', $retries, $uploadType, $@)
					);
				}
			} else {
				$logger->info(sprintf('successfully uploaded %s', $uploadType));
				last;
			}
		}
		$perf_scheduler->resume($uploadType);
		$RISCDB->disconnect();
	}
}

sub buildSkipList {
	my $mysql	= shift;
	my @uploadTypes	= @_;

	my @list = @RISC::riscDataUpload::MANUAL_UPLOAD_TYPES;

	my $tables;
	$tables = RISC::riscDataUpload::getPerfTables($tables);

	foreach my $type (@uploadTypes) {
		next if (grep(/^\Q$type\E$/, @list));
		my $rowcount = 0;
		foreach my $table (@{$tables->{'perf'}->{$type}}) {
			eval {
				my $countQuery = $mysql->selectrow_hashref("
					SELECT count(*) AS num
					FROM $table
				");
				$rowcount += $countQuery->{'num'};
			}
		}
		push(@list, $type) unless ($rowcount > 0);
	}

	return \@list;
}

sub addToCron {
	unless (-e '/etc/cron.d/dataupload_modular_admin') {
		$logger->info('adding dataupload_modular_admin.pl to crontab /etc/cron.d/dataupload_modular_admin');
		my $addCmd = 'echo "*/15 * * * * root /usr/bin/perl /home/risc/dataupload_modular_admin.pl" > /etc/cron.d/dataupload_modular_admin';
		system($addCmd);
	}
}
