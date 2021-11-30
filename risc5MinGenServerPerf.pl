#!usr/bin/perl -w
use SNMP::Info;
use DBI();
use RISC::riscUtility;
use lib 'lib';
use Time::HiRes qw(sleep);
$SIG{CHLD}="IGNORE";
$|++;
use strict;

die if (checkDupProcess()>1);

#database connect
my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} =1;
 
#Get Devices
my $sth2;

if (riscUtility::checkLicenseEnforcement()) {
	$sth2 = $mysql->prepare("SELECT deviceid,ipaddress,credentialid FROM riscdevice
								inner join gensrvserver using(deviceid)
								inner join credentials using(deviceid)
								inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic using(deviceid)
								where technology = 'snmp' and level !='none'");
} else {
	$sth2 = $mysql->prepare("SELECT deviceid,ipaddress,credentialid FROM riscdevice
								inner join gensrvserver using(deviceid)
								inner join credentials using(deviceid)
								where technology = 'snmp' and level !='none'");
}

$sth2->execute();

my $numberrows = $sth2->rows;
print "$numberrows \n";

## polling inverval
my $scantime = time();
eval {
	if ($numberrows > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'gensrvperf-snmp',$numberrows)");
	} else {
		print "risc5MinGenServerPerf: no devices or nothing licensed\n";
	}
};

while (my $line = $sth2->fetchrow_hashref()) {
	my $pid;
	my $totalsleep=45;
	while (riscUtility::checkProcess("genericserverperf") > 10) {
		sleep 10;
		$totalsleep--;
		die "Timed out process waiting for server perf scripts to finish" if $totalsleep==0;
	}
	my $devIP=$line->{'ipaddress'};
	my $devID=$line->{'deviceid'};
	my $credid = $line->{'credentialid'};  
 	next if $pid = fork;
	die "fork failed: $!" unless defined $pid;
	my $execstring = "/usr/bin/perl /home/risc/genericserverperf.pl $devIP $credid $devID\n";
	print $execstring;   
	exec($execstring);
	exit(0);
}

$sth2->finish();
$mysql->disconnect();

#cleanup

my $killDetails = "pkill -f genericserverperf";
my $maxSleep = 24;
while (riscUtility::checkProcess("genericserverperf") > 0 && $maxSleep > 0) {
	sleep 10;
	$maxSleep--;
}

`$killDetails`;

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
