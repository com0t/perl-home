#!/usr/bin/env perl
#
##
use strict;

use Data::Dumper;
$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;

use RISC::Collect::Constants qw( :status );

use RISC::Collect::Logger;
use RISC::Collect::PerfScheduler;
use RISC::riscUtility;

my $max_utilization = 70; # 70% usage on /

my $logger = RISC::Collect::Logger->new('localcc');

if ((my $percentage = riscUtility::disk_utilization()) > $max_utilization) {
	# we run once per minute - only generate a log message every 5 minutes
	$logger->error("disk utilization $percentage > $max_utilization, abort") if ((localtime(time))[1] % 5 == 0);
	exit(1); # don't generate a cron e-mail (i.e. die()) if we can help it
}

my $sched = RISC::Collect::PerfScheduler->new();

my $to_run = $sched->tick('all');

unless ($to_run) {
	$logger->info('no commands');
	exit(EXIT_SUCCESS);
}

foreach my $entry (@{ $to_run }) {
	my ($perf_class) = keys %{ $entry };
	my $cmd = $entry->{$perf_class};
	my $pid = fork();
	next if $pid;
	$logger->info(sprintf('running for %s: %s', $perf_class, $cmd));
	exec($cmd);
	exit(EXIT_FAILURE); ## unreachable
}

exit(EXIT_SUCCESS);
