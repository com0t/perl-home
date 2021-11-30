#!/usr/bin/env perl
#
## winworkperf-detail.pl -- Windows Workstation performance collector

use strict;
use Data::Dumper;

use RISC::riscUtility;
use RISC::riscCreds;
use RISC::riscWindows;
use RISC::Collect::PerfSummary;
use RISC::Collect::Logger;
use RISC::Collect::Quirks;
use RISC::Collect::Constants qw( :status );

my $deviceid	= shift;
my $target	= shift;
my $credid	= shift;

my $logger = RISC::Collect::Logger->new(
	join('::', qw( perf windows workstation ), $deviceid, $target)
);
$logger->info('begin');

my $tstamp = time();

my $db = riscUtility::getDBH('RISC_Discovery');

my $summary = RISC::Collect::PerfSummary::get($db, $deviceid, 'winworkperf');
$summary->{'attempt'} = $tstamp;

my $credobj = riscCreds->new($target);
my $credential = $credobj->getWin($credid);
unless ($credential) {
	$summary->{'error'} = 'failed to retreive credential';
	RISC::Collect::PerfSummary::set($db, $summary);
	$logger->error($summary->{'error'});
	exit(EXIT_FAILURE);
}

my $wmi = RISC::riscWindows->new({
	collection_id	=> $deviceid,
	user		=> $credential->{'user'},
	password	=> $credential->{'password'},
	domain		=> $credential->{'domain'},
	credid		=> $credential->{'credid'},
	host		=> $target,
	scantime	=> $tstamp,
	db			=> $db,
	logger		=> $logger
});

unless ($wmi->connected()) {
	$summary->{'error'} = sprintf("failed to connect: %s",$wmi->err());
	RISC::Collect::PerfSummary::set($db, $summary);
	$logger->error(sprintf('failed to connect: %s', $wmi->err()));
	exit(EXIT_FAILURE);
}

####

$logger->debug('collecting processes');
my $windowsprocess = $db->prepare("
	INSERT INTO windowsprocess
	(scantime,deviceid,pid,description,name,execpath,commandline)
	VALUES
	(?,?,?,?,?,?,?)
");

my $win32_process = $wmi->wmic('Win32_Process');
if (my $process_records = scalar @{$win32_process}) {
	foreach my $p (@{$win32_process}) {
		$windowsprocess->execute(
			$tstamp,
			$deviceid,
			$p->{'ProcessId'},
			$p->{'Name'},
			$p->{'Description'},
			$p->{'ExecutablePath'},
			$p->{'CommandLine'}
		);
	}
	$logger->debug(sprintf('collected %d processes', $process_records));
	$summary->{'processes'} = $tstamp;
} else {
	$logger->warn('no process data collected');
	$summary->{'error'} = 'processes:nodata';
}

$logger->debug('collecting netstat');
if ($credential->{'netstat'} =~ /netstat/) {
	eval {
		my $netstatstatus = $wmi->netstat();
		chomp($netstatstatus->{'detail'});
		if ($netstatstatus->{'status'}) {
			$summary->{'netstat'} = $tstamp;
			$summary->{'rfc4022'} = 1;
		} else {
			$logger->error(sprintf('netstat: %s', $netstatstatus->{'detail'}));
			$summary->{'error'}   = "netstat: $netstatstatus->{'detail'}";
			$summary->{'rfc4022'} = 0;
		}
	};
}

$logger->debug('collecting windows dnscache');
my $dnscache_feature = riscUtility::checkfeature('windows-dnscache');
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

RISC::Collect::PerfSummary::set($db, $summary);
$logger->info('complete');
exit(EXIT_SUCCESS);
