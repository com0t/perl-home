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

use RISC::Collect::Constants qw(
	:status
	:schema
);
use RISC::Collect::DB;
use RISC::Collect::Logger;

use RISC::riscCreds;
use RISC::riscWindows;

my $logger = RISC::Collect::Logger->new('windows::dns');

my (
	$collection_id,
	$target,
	$credentialid,
	$debugging
);

GetOptions(
	'id=i'		=> \$collection_id,
	'target=s'	=> \$target,
	'credential=s'	=> \$credentialid,
	'verbose'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
		$debugging = 1;
	},
	'help'		=> sub { pod2usage(EXIT_SUCCESS) }
);

unless (($collection_id) and ($target) and ($credentialid)) {
	$logger->error('bad usage: must supply --id, --target, and --credential');
	exit(EXIT_FAILURE);
}

my $cred_driver = riscCreds->new($target);
my $credential = $cred_driver->getWin($credentialid);
unless ($credential) {
	$logger->error(sprintf('unable to load credential: %s', $cred_driver->err()));
	exit(EXIT_FAILURE);
}

my $db = RISC::Collect::DB->new(COLLECTION_SCHEMA);
if (my $error = $db->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

my $wmi_config = {
	collection_id => $collection_id,
	user		=> $credential->{'user'},
	password	=> $credential->{'password'},
	domain		=> $credential->{'domain'},
	credid		=> $credential->{'credid'},
	host		=> $target,
	db			=> $db,
	debug		=> $debugging
};

my $wmi = RISC::riscWindows->new($wmi_config);

my $records = $wmi->dns();

$logger->info(sprintf('collected %d dns records', $records));

$logger->info('complete');
exit(EXIT_SUCCESS);

__END__

=head1 NAME

C<winperf-dns.pl>

=head1 SYNOPSIS

	perl winperf-dns.pl --id ID --target IP --credential ID

	perl winperf-dns.pl --help
	perldoc winperf-dns.pl

=head1 DESCRIPTION

C<winperf-dns.pl> executes WMI queries against the collection source located at
the address specified by C<--target>, using the credential specified as an ID
by C<--credential>, for DNS lookup data and stores the data attributed to the
C<collection_id> specified by C<--id>.

If this process is successful, C<winperf-dns.pl> will return C<EXIT_SUCCESS>,
otherwise it will return C<EXIT_FAILURE>. It will log the number of DNS records
seen during the collection process.

This script is typically called by C<winperf-dns-admin.pl>, which determines
what collection sources to run against.

=head1 OPTIONS

=head3 --id ID

Required; the C<collection_id> of the source to which to attribute the data.

=head3 --target IP

Required; the IP address of the source.

=head3 --credential ID

Required; the C<credential_id> of the credential to authenticate with.

=head3 --verbose

Set the logger level to C<DEBUG>.

=head3 --help

Print this help and exit with C<EXIT_SUCCESS>.

=head1 SEE ALSO

=over

=item C<RISC::riscWindows>

=item C<RISC::riscCreds>

=item C<RISC::Collect::Constants>

=item C<winperf-dns-admin.pl>

=back

=cut
