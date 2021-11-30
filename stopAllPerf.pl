#!/usr/bin/env perl
#
##
use strict;
use RISC::Collect::Constants qw( :status );
use RISC::Collect::PerfScheduler;

my $sched = RISC::Collect::PerfScheduler->new();
if ($sched->stop('all', { kill => 1 })) {
	printf("||&|| %s: successfully stopped all perf classes ||&||\n", $0);
	exit(EXIT_SUCCESS);
} else {
	printf("||&|| %s: failed to stop all perf classes: %s ||&||\n", $0, $sched->err());
	## stop failed, attempt a pause
	if ($sched->pause('all', { kill => 1 })) {
		printf("||&|| %s: successfully paused perf as a fallback attempt ||&||\n", $0);
	} else {
		printf("||&|| %s: failed to pause perf as a fallback attempt: %s ||&||\n", $0, $sched->err());
	}
	exit(EXIT_FAILURE);
}
