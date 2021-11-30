#!/usr/bin/perl
#
##
use strict;
use Data::Dumper;

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;
$|++;

use RISC::PerfAdm;
use RISC::Event qw( collector_alarm );

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $spec = {
	perftype	=> 'gensrvperf-ssh',
	detail		=> '/home/risc/gensrvssh-perf.pl',
	totaltime	=> 14400,	## 4 hours
	warntime	=> 10800,	## 3 hours
	detailtime	=> 600,		## 10 minutes
	itertime	=> 5,
	concurrent	=> 50
};

my $adm = RISC::PerfAdm->new($spec,{ 'debug' => $debugging });
if ($adm->err()) {
	$adm->fault();
}

if ($adm->running("perl $0")) {
	$adm->logger->info('previous iteration still running');
	exit(0);
}

my $db = $adm->db();

my $rawdevs;
if ($adm->licensed()) {
	$rawdevs = $db->selectall_arrayref("
		SELECT deviceid,ipaddress,credentialid
		FROM riscdevice
		INNER JOIN gensrvserver USING (deviceid)
		INNER JOIN credentials USING (deviceid)
		INNER JOIN (
			SELECT distinct(deviceid)
			FROM licensed
			WHERE expires > unix_timestamp()
		) lic USING (deviceid)
		WHERE technology = 'gensrvssh'
		GROUP BY deviceid
	",{ Slice => {} });
} else {
	$rawdevs = $db->selectall_arrayref("
		SELECT deviceid,ipaddress,credentialid
		FROM riscdevice
		INNER JOIN gensrvserver USING (deviceid)
		INNER JOIN credentials USING (deviceid)
		WHERE technology = 'gensrvssh'
		GROUP BY deviceid
	",{ Slice => {} });
}

my $devcount = scalar @{$rawdevs};

if ($devcount) {
	my @devs;
	foreach my $dev (@{$rawdevs}) {
		push(@devs,join(' ',$dev->{'deviceid'},$dev->{'ipaddress'},$dev->{'credentialid'}));
	}
	$adm->intv_start($devcount);
	eval {
		$adm->loop(\@devs);
	}; if ($@) {
		collector_alarm(
			'perf-admin-fault',
			$0,
			sprintf('exception in loop: %s', $@)
		) unless ($@ =~ /TOTALTIME/);
	}
	$adm->intv_complete();
} else {
	$adm->logger->info('no devices');
}

$adm->finish();
exit(0);
