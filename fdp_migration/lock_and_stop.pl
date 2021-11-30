#!/usr/bin/perl
use strict;
use warnings;
use RISC::Collect::Logger;
use RISC::riscUtility;

BEGIN { print "||&||\n"; }
END { print "||&||\n"; }

my $logger = RISC::Collect::Logger->new('lock_and_stop');
my $stdout_appender =  Log::Log4perl::Appender->new("Log::Log4perl::Appender::Screen", name => "screenlog", stderr => 0);
$logger->add_appender($stdout_appender);
$logger->info("begin lock_and_stop with pid $$");

if (!riscUtility::checkOnPrem()) {
    $logger->error_die("no reason to lock this non-fdp rn150");
}

$logger->info("creating lockfile");

my $filename = "/home/risc/fdp_migration/fdp_migration_lock";
my $time = time();

if (-e $filename) {
    $logger->warn("fdp migration lock is already in place; timestamp will be updated");
}

open(my $fh, ">", $filename) 
    or $logger->error_die("failed to open $filename");
print $fh "$time\n"
    or $logger->error_die("failed to write to $filename");
close $fh;

$logger->info("stopping all perf");
system("/usr/bin/perl /home/risc/stopAllPerf.pl") == 0
    or $logger->error_die("failed to stop all perf");

$logger->info("locked and stopped");
