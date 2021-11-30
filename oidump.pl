#!/usr/bin/perl
#
## oidump.pl -- query and emit SNMP data by OID using snmpwalk

use strict;
use Data::Dumper;
use Getopt::Std;
use RISC::riscUtility;
use RISC::riscCreds;

## USAGE
##  oidump.pl OPTIONS OID
## OPTIONS
## -d    specify deviceid, mutex with -i
## -i    specify an ip address, mutex with -d
## -c    specify credential id, required with -i
## -n    use numeric OIDs (don't translate)
##
## perl oidump.pl -d 99991234567 1.3.6.1.2.1.6.19
## perl oidump.pl -i 192.168.1.5 1.3.6.1.2.1.25.3

my $db = riscUtility::getDBH('RISC_Discovery',1);

my %opts;
getopt('d:c:i:',\%opts);

my $oid = shift;

if (($opts{'d'} and $opts{'i'}) or (!$opts{'d'} and !$opts{'i'})) {
	die "invalid usage: must supply exactly one of deviceid or ip address\n";
}

my $ip;
my $deviceid;

if ($opts{'i'}) {
	$ip = $opts{'i'};
	die "invalid usage: must supply a credid with -c when -i is given\n" unless ($opts{'c'});
} else {
	$deviceid = $opts{'d'};
	my $v = $db->selectrow_hashref("select ip from visiodevices where deviceid = $deviceid and scoped = 1");
	if ($v) {
		$ip = $v->{'ip'};
	} else {
		die "unable to determine ip address for deviceid $deviceid\n";
	}
}

my $credid;
if ($opts{'c'}) {
	$credid = $opts{'c'};
} else {
	my $v = $db->selectrow_hashref("select credentialid from credentials where deviceid = $deviceid and technology='snmp'");
	$credid = $v->{'credentialid'} if ($v);
}

unless (defined($ip) and defined($credid) and defined($oid)) {
	die "assertion failed: must have an ip address, a credid, and an oid to proceed\n";
}

my $credobj = riscCreds->new();
my $cred = $credobj->getSNMP($credid);
die "no such credential or not an SNMP credential\n" unless ($cred);

my $walkopts = "";
if ($opts{'n'}) {
	$walkopts .= "-On"
}

my $walk;
if ($cred->{'Version'} != 3) {
	$walk = join(" ","snmpwalk",$walkopts,"-v",$cred->{'Version'},"-c",$cred->{'Community'},$ip,$oid);
} else {
	$walk = join(" ","snmpwalk",$walkopts,"-v",$cred->{'Version'},"-l",$cred->{'SecLevel'},"-u",$cred->{'SecName'});
	$walk = join(" ",$walk,"-a",$cred->{'AuthProto'},"-A",$cred->{'AuthPass'}) if ($cred->{'AuthProto'});
	$walk = join(" ",$walk,"-x",$cred->{'PrivProto'},"-X",$cred->{'PrivPass'}) if ($cred->{'PrivProto'});
	$walk = join(" ",$walk,"-n",$cred->{'Context'}) if ($cred->{'Context'});
	$walk = join(" ",$walk,$ip,$oid);
}

system($walk);
