#!/usr/bin/env perl
#
##
use strict;
use Data::Dumper

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;

use Pod::Usage;
use Getopt::Long qw(
	:config
	require_order
	bundling
	no_ignore_case
);

use JSON;
use Parallel::ForkManager;

use RISC::Collect::Constants qw(
	:status
	:schema
);

use RISC::Collect::Logger;
use RISC::Collect::DB;
use RISC::Collect::Quirks;
use RISC::Collect::ServiceConfig qw( list_supported_services );

use RISC::riscUtility;

my %TYPES = (
	'gensrvssh' => {
		child	=> '/home/risc/gensrvssh-perf-serviceconfig.pl',
		from	=> 'ssh_inv_detail'
	},
	'windows' => {
		child	=> '/home/risc/winfiles/winperf-serviceconfig.pl',
		from	=> 'windowsos'
	}
);

my $json = JSON->new->utf8();

my $DEFAULT_MAX_CHILDREN = 5;

my $logger = RISC::Collect::Logger->new('serviceconfig-admin');

my %flags;
GetOptions(\%flags,
	'type=s',
	'max=i',
	'noop',
	'q|quiet'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'ERROR'});
	},
	'v|verbose'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
	},
	'h|help'	=> sub { pod2usage(EXIT_SUCCESS) }
);

unless ($TYPES{ $flags{'type'} }) {
	$logger->error(sprintf('bad type: %s', $flags{'type'}));
	exit(EXIT_FAILURE);
}

my $type = $flags{'type'};

unless (riscUtility::checkfeature('service-config')) {
	$logger->info(sprintf(
		'service-config not enabled: refusing to run for %s',
		$type
	));
	exit(EXIT_SUCCESS);
}

my $db = RISC::Collect::DB->new(COLLECTION_SCHEMA);
if (my $error = $db->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

my $licensed = $db->selectcol_arrayref(sprintf("
	SELECT deviceid
	FROM %s
	INNER JOIN credentials USING (deviceid)
	INNER JOIN licensed USING (deviceid)
	GROUP BY deviceid
", $TYPES{$type}->{'from'}));

unless (scalar @{ $licensed }) {
	$logger->info(sprintf('no licensed %s devices', $type));
	exit(EXIT_SUCCESS);
}

my @plan;

my $quirks = RISC::Collect::Quirks->new({ db => $db });
if (my $error = $quirks->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

$db->disconnect();

my $services = list_supported_services();

foreach my $collection_id (@{ $licensed }) {
	my $q = $quirks->get($collection_id);

	my $have;
	map { $have->{$_} = $q->{$_} } grep { $q->{$_} } @{ $services };
	next unless ($have);

	push(@plan, sprintf(q(perl %s %s '%s'),
		$TYPES{$type}->{'child'},
		$collection_id,
		$json->encode($have)
	));
}

if ($flags{'noop'}) {
	map { $logger->info(sprintf('noop: %s', $_)) } @plan;
	exit(EXIT_SUCCESS);
}

my $MAX_CHILDREN = ($flags{'max'} or $DEFAULT_MAX_CHILDREN);

my $forker = Parallel::ForkManager->new($MAX_CHILDREN);

my $poll_start = time();

foreach my $child (@plan) {
	$forker->start() and next;
	$logger->info($child);
	system($child);
	$forker->finish();
}

$forker->wait_all_children();

$db = RISC::Collect::DB->new(COLLECTION_SCHEMA);
if (my $error = $db->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

$db->do("
	INSERT INTO pollinginterval
	(scantime, perftype, numdevices)
	VALUES
	(?, ?, ?)
", undef,
	$poll_start,
	join('-', 'serviceconfig', $type),
	scalar @plan
);

exit(EXIT_SUCCESS);

__END__

=head1 NAME

C<service-config-admin.pl>

=head1 SYNOPSIS

	perl service-config-admin.pl --type TYPE [--max INT] [--noop] [-qv]

	perl service-config-admin.pl --help
	perldoc service-config-admin.pl

=head1 DESCRIPTION

C<service-config-admin.pl> manages executing service configuration data
collection for eligible devices.

It operates on a single device type at a time, indicated by the required
C<--type> argument. It then queries for a list of licensed devices of that
type, and for each device it inspects the C<quirks> data to see what, if any,
services are available on that device. For each eligible device, it executes
the device-level collection process for the relevant protocol, passing it the
C<collection_id> and a list of available services.

This script parallelizes the per-device processes using
L<Parallel::ForkManager>. The default number of concurrent processes is defined
in the C<$DEFAULT_MAX_CHILDREN> variable, which can be overridden by the
C<--max> command line flag.

=head1 OPTIONS

=head3 --type TYPE

Required. Indicates the device type (and thus collection protocol) to operate
on, such as C<gensrv> or C<windows>.

=head3 --max INT

Optional. Overrides the default concurrent processing limit.

=head3 --noop

Optional. Causes the program to print the list of child processes it would
spawn instead of running them, and then exit successfully.

=head3 -q, --quiet

Optional. Sets the logger level to C<ERROR>.

=head3 -v, --verbose

Optional. Sets the logger level to C<DEBUG>.

=head3 -h, --help

Display this help. C<perldoc> may also be used for more detailed documentation.

=head1 SEE ALSO

=over

=item C<RISC::Collect::ServiceConfig>

=item C<RISC::Collect::Quirks>

=item L<Parallel::ForkManager>

=back

=cut
