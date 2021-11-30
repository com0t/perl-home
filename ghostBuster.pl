#!/usr/bin/perl
#
## ghostBuster.pl - keep the headend informed about script progress
#
##
use strict;
use RISC::riscWebservice;
use RISC::riscUtility;
use RISC::Collect::Logger;
use Data::Dumper;
use File::Slurp;

## this script runs from cron, currently every 10 minutes
## it calls ccGhostRequest on orchestrationAPI to pull a list of jobs that are marked as picked up (1) but not completed (2)
## it then checks to see if the process implicated in that job is running
##    if not, it calls ccResult on orchestrationAPI to mark the job complete
##    if so, it takes no action
## ghostBuster currently only operates on perl jobs, and then only on platform_discovery.pl (and children) and platform_inventory.pl 

## colvin 2015

my $logger = RISC::Collect::Logger->new('ghostBuster');

$logger->info("ghostBuster: begin: " . time());

my $mysql = riscUtility::getDBH('risc_discovery',0);

my $assessCodeQuery = $mysql->selectrow_hashref("select productkey from credentials where technology = 'appliance'");
my $assessCode = $assessCodeQuery->{'productkey'};

chomp(my $psk = read_file("/etc/riscappliancekey"));

## pull jobs from headend
my $jobCall = riscWebservice::ccGhostRequest($psk,$assessCode);
if ($jobCall->{'returnStatus'} eq 'success') {
	sleep(5);	## avoid possible race-condition if ghostBuster fires off at the same time as a valid job
	if (ref $jobCall->{'ghostJobs'} eq 'ARRAY') {
## array of jos returned ##
		foreach my $ghost (@{$jobCall->{'ghostJobs'}}) {
			if ($ghost->{'execfile'} =~ /perl/) {
				if ($ghost->{'arg1'} =~ /platform_discovery/) {
					chomp(my $running = `ps aux | grep -e 'platform_discovery.pl' -e 'disco.pl' -e 'credentials.pl' | grep -v grep | wc -l`);
					if ($running < 1) {
						## job is not running, inform headend
						$logger->info("operating: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
						riscWebservice::ccResult($ghost->{'commandid'},$psk,"verified complete by ghostBuster",time);
					} else {
						## do nothing, we're still running
						$logger->info("still running: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
						next;
					}
				} elsif ($ghost->{'arg1'} =~ /platform_inventory/) {
					chomp(my $running = `ps aux | grep 'platform_inventory.pl' | grep -v grep | wc -l`);
					if ($running < 1) {
						## job is not running, inform headend
						$logger->info("operating: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
						riscWebservice::ccResult($ghost->{'commandid'},$psk,"verified complete by ghostBuster",time);
					} else {
						## do nothing, we're still running
						$logger->info("still running: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
						next;
					}
				} else {
					## not a perl script we care about
					$logger->info("ignoring: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
					next;
				}
			} else {
				## not a perl script
				$logger->info("ignoring non-perl job: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
				next;
			}
		}
	} else {
## single job returned ##
		my $ghost = $jobCall->{'ghostJobs'};
		unless (defined($ghost->{'execfile'})) {
			$logger->info("no jobs found - exiting");
			exit(0);
		}
		if ($ghost->{'execfile'} =~ /perl/) {
			if ($ghost->{'arg1'} =~ /platform_discovery/) {
				chomp(my $running = `ps aux | grep -e 'platform_discovery.pl' -e 'disco.pl' -e 'credentials.pl' | grep -v grep | wc -l`);
				if ($running < 1) {
					## job is not running, inform headend
					$logger->info("operating: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
					riscWebservice::ccResult($ghost->{'commandid'},$psk,"verified complete by ghostBuster",time);
				} else {
					## do nothing, we're still running
					$logger->info("still running: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
				}
			} elsif ($ghost->{'arg1'} =~ /platform_inventory/) {
				chomp(my $running = `ps aux | grep 'platform_inventory.pl' | grep -v grep | wc -l`);
				if ($running < 1) {
					## job is not running, inform headend
					$logger->info("operating: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
					riscWebservice::ccResult($ghost->{'commandid'},$psk,"verified complete by ghostBuster",time);
				} else {
					## do nothing, we're still running
					$logger->info("still running: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
				}
			} else {
				## not a perl script we care about
				$logger->info("ignoring: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
			}
		} else {
			## not a perl script
			$logger->info("ignoring non-perl job: " . $ghost->{'commandid'} . "\t" . $ghost->{'execfile'} . " " . $ghost->{'arg1'});
		}
	}
} else {
	## ccGhostRequest call failure
	$logger->error_die("ccGhostRequest call failed with return: " . Dumper($jobCall));
}
