#!/usr/bin/env perl
use strict;
use Data::Dumper;
use MIME::Base64;

use RISC::Collect::Logger;
use RISC::riscUtility;
$|++;

my $logger = RISC::Collect::Logger->new('checkbootstrap');

my $mysql;

# this along with moving checkbootstrap.pl to rn150-scripts-common should reduce the chances of a new appliance getting stuck in 'Initial'.
# waiting for the package to be installed ensures that things like disco.pl etc. are installed before returning success, which would then try to begin a scan.
my ($scripts_pkg, $attempt, $max_attempts, $attempt_delay) = ('rn150-scripts', 0, 30, 60); # 30 * 60 = 30m

# ensure rn150-scripts is fully installed (^ii) or installed but held (^hi), and therefore that postinstall has successfully run.
while (system("dpkg-query -l '$scripts_pkg' 2>/dev/null | egrep -q '^ii|^hi'")) {
	$attempt++;

	if ($attempt > $max_attempts) {
		open(STDERR, '>&STDOUT'); # hack to make die() messages go to stdout so they're captured by cc.pl
		$logger->error_die("gave up waiting for $scripts_pkg to be installed");
	}

	$logger->info("$scripts_pkg is not installed yet, sleeping for $attempt_delay seconds (attempt $attempt of $max_attempts)");

	sleep($attempt_delay);
}

eval {
	$logger->info('building credential metadata for internal site');

	my $type        = "";
	my $windows     = "";
	my $specialchar = "No Spec Char";
	my $LAN0        = "";
	my $LAN1        = "";

	$mysql = riscUtility::getDBH('risc_discovery', 1);

	#set variables for upload
	my $validate = $mysql->prepare("select technology,status,count(*) as num from credentials where removed!=1 group by technology,status");
	$validate->execute();
	my $validHash;
	my $windowsTotal = 0;
	my $windowsValid = 0;
	my $windowsOther = 0;
	my $snmpTotal    = 0;
	my $snmpValid    = 0;
	my $snmpOther    = 0;
	my $ccmTotal     = 0;
	my $ccmValid     = 0;
	my $ccmOther     = 0;
	my $vmwareTotal  = 0;
	my $vmwareValid  = 0;
	my $vmwareOther  = 0;
	while (my $val = $validate->fetchrow_hashref()) {
		my $tech   = $val->{'technology'};
		my $count  = $val->{'num'};
		my $status = $val->{'status'};
		$validHash->{$tech}->{$status} = $count;
	}
	$windowsValid = $validHash->{'windows'}->{'1'} if defined $validHash->{'windows'}->{'1'};
	$windowsOther = $validHash->{'windows'}->{'0'} if defined $validHash->{'windows'}->{'0'};
	$windowsTotal = $windowsValid + $windowsOther;
	$snmpValid    = $validHash->{'snmp'}->{'1'}    if defined $validHash->{'snmp'}->{'1'};
	$snmpOther    = $validHash->{'snmp'}->{'0'}    if defined $validHash->{'snmp'}->{'0'};
	$snmpTotal    = $snmpValid + $snmpOther;
	$ccmValid     = $validHash->{'cm'}->{'1'}      if defined $validHash->{'cm'}->{'1'};
	$ccmOther     = $validHash->{'cm'}->{'0'}      if defined $validHash->{'cm'}->{'0'};
	$ccmTotal     = $ccmValid + $ccmOther;
	$vmwareValid  = $validHash->{'vmware'}->{'1'}  if defined $validHash->{'vmware'}->{'1'};
	$vmwareOther  = $validHash->{'vmware'}->{'0'}  if defined $validHash->{'vmware'}->{'0'};
	$vmwareTotal  = $vmwareValid + $vmwareOther;

	#Check for Special Characters
	my $getAllPasswords;
	if ($mysql->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$getAllPasswords = $mysql->prepare("select passphrase from credentials where technology!='appliance' and removed !=1");
	} else {
		$getAllPasswords = $mysql->prepare("select cred_decrypt(passphrase) as passphrase from credentials where technology!='appliance' and removed !=1");
	}
	$getAllPasswords->execute();
	while (my $pass = $getAllPasswords->fetchrow_hashref()) {
		if (decode_base64($pass->{'passphrase'}) =~ m/[^a-zA-Z0-9]/) {
			$specialchar = "Yes Spec Char";
			last;
		}
	}

	$type = 'RN150';

	#Check for Windows Creds
	if ($windowsTotal == 0) {
		$windows = "No Windows";
	} else {
		$windows = "Yes Windows";
	}

	#Get IPs
	my @lines = `ifconfig eth0`;
	for (@lines) {
		if (/\s*inet (?:addr:)?([\d.]+)/) {
			$LAN0 = $1;
		}
	}

	if (length($LAN0) == 0) {
		$LAN0 = "NA";
	}
	$LAN1 = "NA";	## no eth1 interface

	printf("%s\n",'||&||');
	print "$type \n$windows \n$specialchar \n$LAN0 \n$LAN1 \n";
	print "WINDOWS:$windowsTotal:$windowsValid:$windowsOther\n";
	print "SNMP:$snmpTotal:$snmpValid:$snmpOther\n";
	print "CCM:$ccmTotal:$ccmValid:$ccmOther\n";
	print "VMWARE:$vmwareTotal:$vmwareValid:$vmwareOther\n";

	my $applianceVersion = `head -n 2 /etc/riscrevision`;

	$applianceVersion =~ s/\n/ /;
	print "VER:$applianceVersion\n";
	printf("%s\n",'||&||');

	#Temporary Needs for RN150 until LZM Sync is complete
	#Remove 5.10 SNMP::Info
	system("rm -f -r /usr/lib/perl5/site_perl/5.10.0/SNMP");

}; if ($@) {
	$logger->error("failure in credential metadata block: $@");
	print "ERROR: $@\n";
}
