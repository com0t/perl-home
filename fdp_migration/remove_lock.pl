#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use RISC::Collect::Logger;
use RISC::riscUtility;
use RISC::riscConfigWeb;

$SIG{TERM} = sub { exit(1); };
BEGIN { print "||&||\n"; }
END { print "||&||\n"; }

my $restartPerf = shift;
my $fdp_ip = shift; 
# note: the presence of an ip-like string of numbers in the second input will trigger the
# IP update; if anything else is handed in, we will skip the step where we update the FDP
# IP under the assumption that this operation is being called in the context of a rollback.

my $logger = RISC::Collect::Logger->new('remove_lock');
my $stdout_appender =  Log::Log4perl::Appender->new("Log::Log4perl::Appender::Screen", name => "screenlog", stderr => 0);
$logger->add_appender($stdout_appender);
$logger->info("begin remove_lock with pid $$");

my $filename = "/home/risc/fdp_migration/fdp_migration_lock";
unless (-e $filename) {
    $logger->error_die("lockfile not found at $filename");
}

my $mysql = riscUtility::getDBH('risc_discovery',1)
    or $logger->error_die("couldn't connect to risc_discovery");

my $auth = riscUtility::getApplianceAuth($mysql);

if (!defined($auth)) {
    $logger->error_die("failed to obtain appliance auth");
}

if (!$auth->{'onprem'}) {
    $logger->error_die("non-fdp rn150; invalid operation");
}

if (!verify_ip($auth->{'consumption'})) {
	$logger->error_die("bad consumption ip: $auth->{'consumption'}");
}

# kill previous running processes
my $pending_unlocks = `pgrep -f '^/usr/bin/perl /home/risc/fdp_migration/remove_lock.pl'`;
$pending_unlocks =~ s/\n/ /g;
# remove ourself from the list:
$pending_unlocks =~ s/\b$$\b//;
if ($pending_unlocks =~ m/[0-9]/) {
    $logger->info("killing previous remove_lock iteration(s): $pending_unlocks");
    system("kill $pending_unlocks")==0
        or $logger->error_die("failed to kill pending unlocks");
}

my $previous_fdp_ip = $auth->{'consumption'};
$logger->info("previous fdp IP: $previous_fdp_ip");

if (verify_ip($fdp_ip)) {
    # technically this doesn't prevent an IP like 0.300.400.999 but if it were invalid the process would have failed much earlier
    $logger->info("updating FDP IP to $fdp_ip in database");
    $mysql->do("update credentials set testip = '$fdp_ip' where technology = 'flexpod'");
    $logger->info("updating FDP IP in /etc/hosts");
    system("sed -i 's/.*dataup\.riscnetworks\.com/$fdp_ip\tdataup.riscnetworks.com/g' /etc/hosts");
    $logger->info("testing connectivity to new IP: $fdp_ip");
} else {
    $logger->info("new IP not supplied; testing connectivity to $previous_fdp_ip");
    $fdp_ip = $previous_fdp_ip;
}

my $attempt_counter = 0;
riscUtility::proxy_disable();
my $ul_check = `curl -ks https://$fdp_ip/ul.php`;
while ($ul_check ne '"assessmentcode" not specified') {
    $logger->warn("failed to connect to fdp on attempt $attempt_counter");
    if ($attempt_counter%24 == 0 && $restartPerf) {
        # don't bother users about rn150s that are not active, I reckon
        $logger->warn("bothering users");
        bother_users(); 
    }
    sleep(3600);
    $ul_check = `curl -ks https://$fdp_ip/ul.php`;
    $attempt_counter++;
}
riscUtility::loadenv();

# if we have reached this point, we were able to hit the FDP at the expected IP
# so we are good to remove the lock and start all perf:
system("rm $filename") == 0 or $logger->error_die("unable to remove $filename");

if ($restartPerf) {
    $logger->info("restarting perf");
    system("/usr/bin/perl /home/risc/startAllPerf.pl") == 0 or $logger->error_die("startAllPerf did not succeed");
} else {
    $logger->info("not restarting perf because assessment is not in appropriate state");
}

$logger->info("success");

sub bother_users {
    riscUtility::loadenv();
    my $user = 'rn150';
    my $noteType = 'FailedFDPCheck';
    # grab the 150's IP
    my $ip = `ip -4 address show dev eth0`;
    $ip =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
    my $ip_hash = {'fdp_ip'=>$fdp_ip,'rn150_ip'=>$1};
    $logger->info("fdp_ip=$fdp_ip, rn150_ip=$1");
    my $desc = "fdp_migrated";
    my $status = riscConfigWeb::notify($user,$auth->{'mac'},$auth->{'assesscode'},$noteType,encode_json($ip_hash),$desc);
    riscUtility::proxy_disable();
}

sub verify_ip {
	my $ip = shift;
	return (defined($ip) && $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
}
