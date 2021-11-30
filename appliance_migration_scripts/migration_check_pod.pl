#!/usr/bin/env perl
use strict;
use warnings;
use JSON;

use RISC::riscUtility;
use RISC::riscConfigWeb;
use RISC::Collect::Logger;

my $logger = RISC::Collect::Logger->new('migration_check_pod');

print "checking pod\n";
$logger->info("checking pod");

if (riscUtility::checkOnPrem()) {
    # check that the dataup resolves to the flex deploy:
    my $mysql = riscUtility::getDBH('risc_discovery',1);
    my $auth = riscUtility::getApplianceAuth($mysql);
    if (!defined($auth)) {
        $logger->error_die("failed to obtain appliance auth");
    }
    my $pod_ip = $auth->{'consumption'};
    my $resolution_check = `grep -F dataup.riscnetworks.com /etc/hosts` =~ /$pod_ip/;
    
    riscUtility::proxy_disable();
    my $ul_check = `curl -ks https://$pod_ip/ul.php`;
    riscUtility::loadenv();
    if ($ul_check ne '"assessmentcode" not specified') {
        # then we couldn't hit the FDP. Report on the problem.
        my $user = 'rn150';
        my $noteType = 'FailedFDPCheck';
        # grab the 150's IP
        my $ip = `ip -4 address show dev eth0`;
        $ip =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
        my $ip_hash = {'fdp_ip'=>$pod_ip,'rn150_ip'=>$1};
        print "fdp_ip=$pod_ip, rn150_ip=$1\n";
        $logger->info("fdp_ip=$pod_ip, rn150_ip=$1");
        my $desc = "cannot connect to pod";
        my $status = riscConfigWeb::notify($user,$auth->{'mac'},$auth->{'assesscode'},$noteType,encode_json($ip_hash),$desc);
        print $desc, "\n";
        $logger->error_die($desc);
    } elsif (!$resolution_check) {
        print "database and /etc/hosts disagree on pod IP\n";
        $logger->warn("database and /etc/hosts disagree on pod IP");
    } else {
        print "pod check succeeded\n";
        $logger->info("pod check succeeded");
    }

} else {
    # what should be behavior be if we call this script on a non-FDP-associated 150?
    print "pod check called, but no flex deploy pod detected\n";
    $logger->error_die("pod check called, but no flex deploy pod detected"); # this would mean the stored procedure disagrees with the local db. abort.
}
