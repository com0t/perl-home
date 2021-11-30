#!/usr/bin/perl
#
## licensingCron.pl -- refreshes the licensed device list daily

use strict;
use RISC::riscUtility;

my ($sec,$min,$hour) = localtime(time());
my $trigger = riscUtility::getTriggerHour();

if ($hour == $trigger) {
	print "licensingCron: issuing licenseUpdate.pl\n";
	`perl /home/risc/licenseUpdate.pl`;
}

