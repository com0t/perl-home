#!/usr/bin/env perl
#
##
use strict;
use Data::Dumper

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;
$|++;

use RISC::PerfAdm;
use RISC::Event qw( collector_alarm );

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $spec = {
	perftype	=> 'gensrvperf-snmp',
	detail		=> '/home/risc/genericserverperf.pl',
	totaltime	=> 14400,	## 4 hours
	warntime	=> 10800,	## 3 hours
	detailtime	=> 300,		## 5 minutes
	itertime	=> 5,
	concurrent	=> 20
};

## replace the default kill() routine with one that sends a SIGKILL
##  instead of a SIGTERM, as a stalled SNMP process may be otherwise
##  unable to receive the signal (eg, blocking I/O)
sub RISC::PerfAdm::kill {
	my ($self,$process) = @_;
	my $kill = "pkill -9 -f '$process'";
	$self->logger->warn($kill);
	system($kill);
}

my $adm = RISC::PerfAdm->new($spec,{ 'debug' => $debugging });
if ($adm->err()) {
	$adm->fault();
}

if ($adm->running("perl $0")) {
	$adm->logger->info('previous iteration still running');
	exit(0);
}

## kill any stalled processes
$adm->kill($spec->{'detail'});

my $db = $adm->db();

my $rawdevs;
if ($adm->licensed()) {
	$rawdevs = $db->selectall_arrayref("
		SELECT
			deviceid,
			ipaddress,
			credentialid
		FROM riscdevice
			INNER JOIN gensrvserver USING (deviceid)
			INNER JOIN credentials USING (deviceid)
			INNER JOIN (
				SELECT DISTINCT deviceid
				FROM licensed
				WHERE expires > UNIX_TIMESTAMP()
			) AS lic USING (deviceid)
		WHERE technology = 'snmp'
	",{ Slice => {} });
} else {
	$rawdevs = $db->selectall_arrayref("
		SELECT
			deviceid,
			ipaddress,
			credentialid
		FROM riscdevice
			INNER JOIN gensrvserver USING (deviceid)
			INNER JOIN credentials USING (deviceid)
		WHERE technology = 'snmp'
	",{ Slice => {} });
}

my $devcount = scalar @{$rawdevs};

if ($devcount) {
	my @devs;
	foreach my $dev (@{$rawdevs}) {
		push(@devs,join(' ',
			$dev->{'deviceid'},
			$dev->{'ipaddress'},
			$dev->{'credentialid'}
		));
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

## kill any stalled processes
$adm->kill($spec->{'detail'});

$adm->finish();
exit(0);

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 OPTIONS

=cut

