#!/usr/bin/env perl
#
##
use strict;
use RISC::Collect::Constants qw( :status );
use RISC::Collect::PerfScheduler;
use RISC::Collect::Logger;

my $logger = RISC::Collect::Logger->new('startAllPerf');

if (-e '/home/risc/fdp_migration/fdp_migration_lock') {
	$logger->warn("cannot run startAllPerf while rn150 is in fdp_migration_lock state");
	printf("||&||aborted due to fdp_migration_lock||&||\n");
	exit(EXIT_FAILURE);
}

my $restart	= shift;

my $method = ($restart) ? 'restart' : 'schedule';
$logger->info("startingAllPerf in $method mode");

my $sched = RISC::Collect::PerfScheduler->new();

$sched->resume('all');
if ($sched->$method('all')) {
	$logger->info("successfully resumed perf");
	printf("||&|| %s: successfully ran 'resume' and '%s' for all perf classes ||&||\n", $0, $method);
	exit(EXIT_SUCCESS);
} else {
	$logger->error("failed to $method perf: " . $sched->err());
	printf("||&|| %s: failed to %s perf: %s ||&||\n", $0, $method, $sched->err());
	exit(EXIT_FAILURE);
}
