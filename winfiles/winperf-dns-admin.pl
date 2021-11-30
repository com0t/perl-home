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
use RISC::Collect::Quirks;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $spec = {
	perftype	=> 'winperf-dns',
	detail		=> '/home/risc/winfiles/winperf-dns.pl',
	totaltime	=> 14400,	## 4 hours
	warntime	=> 10800,	## 3 hours
	detailtime	=> 2100,	## 35 minutes
	itertime	=> 5,
	concurrent	=> 1
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

my $rawdnsdevs;
if ($adm->licensed()) {
	$rawdnsdevs = $db->selectall_arrayref("
		SELECT riscdevice.deviceid,ipaddress,wmi,credentialid from riscdevice
			INNER JOIN credentials using(deviceid)
			INNER JOIN windowsos using(deviceid)
			INNER JOIN (
				SELECT distinct deviceid FROM licensed WHERE expires > unix_timestamp(now())
			) as lic using(deviceid)
		WHERE credentials.technology='windows'
			AND caption regexp 'server'
			AND credentials.level = 'dns'
		GROUP BY deviceid
	",{ Slice => {} });
} else {
	$rawdnsdevs = $db->selectall_arrayref("
		SELECT riscdevice.deviceid,ipaddress,wmi,credentialid from riscdevice
			INNER JOIN credentials using(deviceid)
			INNER JOIN windowsos using(deviceid)
		WHERE credentials.technology='windows'
			AND caption regexp 'server'
			AND credentials.level = 'dns'
		GROUP BY deviceid
	",{ Slice => {} });
}

my $dnsdevcount = scalar @{$rawdnsdevs};

if ($dnsdevcount) {
	my $quirks = RISC::Collect::Quirks->new({ db => $db });

	my @dnsdevs;
	foreach my $dev (@{$rawdnsdevs}) {
		## ensure the device has the 'dns' quirk stored
		my $q = $quirks->get($dev->{'deviceid'});
		$quirks->post($dev->{'deviceid'}, {
			($q) ? %{ $q } : ( ),
			dns	=> 1
		});

		push(@dnsdevs,
			join(' ',
				'--id',
				$dev->{'deviceid'},
				'--target',
				$dev->{'ipaddress'},
				'--credential',
				$dev->{'credentialid'},
				($debugging) ? '--verbose' : undef
			)
		);
	}

	$adm->intv_start($dnsdevcount);
	eval {
		$adm->loop(\@dnsdevs);
	}; if ($@) {
		collector_alarm(
			'perf-admin-fault',
			$0,
			sprintf('exception in loop: %s', $@)
		) unless ($@ =~ /TOTALTIME/);
	}
	$adm->intv_complete();
} else {
	$adm->logger->info('no dns devices');
}

$adm->finish();
exit(0);
