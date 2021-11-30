#!usr/bin/perl -w
use Data::Dumper;
use RISC::riscUtility;
use RISC::riscWebservice;
use RISC::Collect::Logger;

$SIG{CHLD}="IGNORE";
$|++;

my $logger = RISC::Collect::Logger->new(
	join('::', qw( perf vmware admin ))
);

$logger->info('begin');

if (checkProcess() > 1) {
	$logger->info('blocked on another instance, exiting');
	exit(0);
}

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

unless (vmwareCreds($mysql) > 0) {
	$logger->info('no vmware credentials, exiting');
	exit(0);
}

#specify the number of devices (hosts/guests) to process at a time
my $guestBatchSize = 300;
my $hostBatchSize = 150;
#Get vCenters
my $vCenterQuery=$mysql->prepare("select distinct(vcenterid) as devid from riscvmwarematrix");
$vCenterQuery->execute();

while (my $line = $vCenterQuery->fetchrow_hashref()) {

	$mysql = riscUtility::getDBH('RISC_Discovery',1);

	my $devid = $line->{'devid'};

	my $infoQuery = $mysql->selectrow_hashref("
		select	ipaddress,
				credentialid
		from riscdevice
		inner join credentials using (deviceid)
		where (deviceid=$devid or deviceid = cast(substr($devid,5) as signed))
		and technology = 'vmware'
	");

	my $hostCountQuery;
	my $guestCountQuery;

	if (riscUtility::checkLicenseEnforcement()) {
		$hostCountQuery = $mysql->selectrow_hashref("
			select count(*) as numhosts
			from vmware_hostsystem host
			inner join riscvmwarematrix mat using(uuid)
			inner join (
				select distinct deviceid from licensed where expires > unix_timestamp(now())
			) lic on lic.deviceid = mat.deviceid
			where (host.deviceid=$devid or host.deviceid = cast(substr($devid,5) as signed))
		");

		$guestCountQuery = $mysql->selectrow_hashref("
			select count(*) as numguests
			from vmware_guestsummaryconfig vm
			inner join riscvmwarematrix mat using(uuid)
			inner join (
				select distinct deviceid from licensed where expires > unix_timestamp(now())
			) lic on lic.deviceid = mat.deviceid
			where (vm.deviceid=$devid or vm.deviceid = cast(substr($devid,5) as signed))
		");
	} else {
		$hostCountQuery = $mysql->selectrow_hashref("
			select count(*) as numhosts
			from vmware_hostsystem
			where (deviceid=$devid or deviceid = cast(substr($devid,5) as signed))
		");

		$guestCountQuery = $mysql->selectrow_hashref("
			select count(*) as numguests
			from vmware_guestsummaryconfig
			where (deviceid=$devid or deviceid = cast(substr($devid,5) as signed))
		");
	}

	my $ip = $infoQuery->{'ipaddress'};
	my $credid = $infoQuery->{'credentialid'};
	my $numHosts = $hostCountQuery->{'numhosts'};
	my $numGuests = $guestCountQuery->{'numguests'};

	## polling interval
	my $scantime = time();
	eval {
		my $numdevices = $numHosts + $numGuests;
		if ($numdevices > 0) {
			$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'vmwareperf',$numdevices)");
			$logger->info(sprintf("%d hosts and %d guests", $numHosts, $numGuests));
		} else {
			$logger->info("no devices or nothing licensed");
		}
	};

	#first do all hosts for this vcenter
	for (my $i = 0; $i < $numHosts; $i += $hostBatchSize) {
		my $totalsleep=450;
		while (riscUtility::checkProcess("vmware_perf_batch") > 0 || riscUtility::checkProcess("Hiding") > 0) {
			$logger->info(sprintf('host: waiting for concurrency slot: %d', $totalsleep));
			sleep 5;
			$totalsleep--;
			if ($totalsleep == 0) {
				`pkill -f Hiding`;
				`pkill -f vmware_perf_batch`;
				$logger->error('host: timeout waiting for concurrency slot');
				exit(1); # XXX should this exit here?
			}
		}
		next if $pid = fork;
		die "fork failed: $!" unless defined $pid;
		$execstring = "/usr/bin/perl /home/risc/vmware_perf_batch.pl $ip $credid HostSystem $i $hostBatchSize\n";
		$logger->info(sprintf('running: %s', $execstring));
		exec($execstring);
		exit(0);
	}

	#now all guests
	for (my $i = 0; $i < $numGuests; $i += $guestBatchSize) {
		my $totalsleep=450;
		while (riscUtility::checkProcess("vmware_perf_batch") > 0 || riscUtility::checkProcess("Hiding") > 0) {
			$logger->info(sprintf('guest: waiting for a cucurrency slot: %d', $totalsleep));
			sleep 5;
			$totalsleep--;
			if ($totalsleep == 0) {
				`pkill -f Hiding`;
				`pkill -f vmware_perf_batch`;
				$logger->error('guest: timeout waiting for a concurrency slot');
				exit(1); # XXX should this exit here?
			}
		}
		next if $pid = fork;
		die "fork failed: $!" unless defined $pid;
		$execstring = "/usr/bin/perl /home/risc/vmware_perf_batch.pl $ip $credid VirtualMachine $i $guestBatchSize\n";
		$logger->info(sprintf('running: %s', $execstring));
		exec($execstring);
		exit(0);
	}
}
$vCenterQuery->finish();

#now we wait for children to finish and clean up (run data upload)
my $totalsleep=180;
while (riscUtility::checkProcess("vmware_perf_batch") > 0 || riscUtility::checkProcess("Hiding") > 0) {
	$logger->info(sprintf('waiting for remaining processes to complete: %d', $totalsleep));
	sleep 5;
	$totalsleep--;
	if ($totalsleep == 0) {
		`pkill -f Hiding`;
		`pkill -f vmware_perf_batch`;
	}
}

if (checkData()) {
	my $uploadCmd = "/usr/bin/perl /home/risc/dataupload_modular_admin.pl vmwareperf";
	$logger->info(sprintf('performing vmwareperf upload', $uploadCmd));
	system($uploadCmd);
} else {
	$logger->info('no data to upload');
}

$mysql->disconnect();

$logger->info('complete');
exit(0);

sub checkProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result = @proclist;
	return $result;
}

sub vmwareCreds {
	my $mysql = shift;
	my $vmwareQuery = $mysql->selectrow_hashref("select count(*) as num from credentials where technology = 'vmware'");
	return $vmwareQuery->{'num'};
}

sub checkData {
	my $total = 0;
	my $tableHash = riscWebservice::getUploadTablesByType('dGFibGVzdHJpbmdhdXRo','vmwareperf');
	unless ($tableHash) {
		return 1;	## if we can't determine this, we'll just do the upload
	}
	foreach my $tbl (@{$tableHash->{'tables'}}) {
		next if ($tbl->{'tablename'} eq 'vmwareperf_counterinfo'); ## otherwise, we'll always upload
		my $tblcount;
		eval {
			$tblcount = $mysql->selectrow_hashref("select count(*) as numrecords from ".$tbl->{'tablename'})->{'numrecords'};
		}; if ($@) {
			$tblcount = 0;
		}
		$total += $tblcount;
	}

	return $total;
};
