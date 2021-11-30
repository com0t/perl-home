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
	perftype	=> 'winperf',
	detail		=> '/home/risc/winfiles/winperf-detail2.pl',
	totaltime	=> 14400,	## 4 hours
	warntime	=> 10800,	## 3 hours
	detailtime	=> 2100,	## 35 minutes
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

## if the previous iteration has completed, there should be no related processes left running
## kill any straggling detail scripts, or netstat collectors
$adm->kill($spec->{'detail'});
$adm->kill('winexe');
$adm->kill('wmiexec.py');

my $db = $adm->db();

## pull standard devices

my $rawdevs;
if ($adm->licensed()) {
	$rawdevs = $db->selectall_arrayref("
		SELECT riscdevice.deviceid,ipaddress,wmi,credentialid from riscdevice
			INNER JOIN credentials using(deviceid)
			INNER JOIN windowsos using(deviceid)
			INNER JOIN (
				SELECT distinct deviceid FROM licensed WHERE expires > unix_timestamp(now())
			) as lic using(deviceid)
		WHERE credentials.technology='windows'
			AND caption regexp 'server'
		GROUP BY deviceid
	",{ Slice => {} });
} else {
	$rawdevs = $db->selectall_arrayref("
		SELECT riscdevice.deviceid,ipaddress,wmi,credentialid from riscdevice
			INNER JOIN credentials using(deviceid)
			INNER JOIN windowsos using(deviceid)
		WHERE credentials.technology='windows'
			AND caption regexp 'server'
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
		$adm->alarm('exception in loop',$@) if ($@ !~ /TOTALTIME/);
	}
	$adm->intv_complete();
} else {
	$adm->logger->info('no devices');
}

$adm->finish();
exit(0);

