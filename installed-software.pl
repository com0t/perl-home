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

use RISC::Collect::Constants qw( :status );
use RISC::Collect::Logger;

my $logger = RISC::Collect::Logger->new('installed-software');

my @ORDER = qw(
	windows
	gensrvssh
);

my %SCRIPTS = (
	windows		=> 'perl /home/risc/winfiles/winperf-installed-software.pl',
	gensrvssh	=> 'perl /home/risc/gensrvssh-installed-software.pl'
);

foreach my $p (@ORDER) {
	$logger->info(sprintf('running for %s: %s', $p, $SCRIPTS{$p}));
	system($SCRIPTS{$p});
	$logger->error(sprintf('failed: %s: %d', $p, $? >> 8)) if ($?);
}

$logger->info('performing installedsoftware data upload');
exec('perl /home/risc/dataupload_modular_admin.pl installedsoftware');

__END__

=head1 NAME

C<installed-software.pl>

=head1 SYNOPSIS

	perl /home/risc/installed-software.pl

=head1 DESCRIPTION

C<installed-software.pl> is the parent process that runs the protocol specific
processes for collecting installed software data. This is the callable
entrypoint for the C<installedsoftware::all> performance class.

Each protocol is run serially, in order to reduce the number of concurrent
processes and to avoid potential conflicts with forked processes in the
child processes, who use C<Parallel::ForkManager>.

Rather than scheduling each protocol's collection processes separately, this
acts as a parent to all of them. This is done so that the data upload of the
C<installedsoftware> upload type contains all collected data for all protocols,
and cannot attempt to upload while a protocol's collection processes are
running.

Upon completion, this process will C<exec()> the C<dataupload_modular_admin.pl>
script to perform the C<installedsoftware> upload.

=cut
