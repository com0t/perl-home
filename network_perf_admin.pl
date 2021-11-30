#!usr/bin/perl -w
use Data::Dumper;
use RISC::riscUtility;
$SIG{CHLD}="IGNORE";

die if (checkProcess()>1);

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

#Get Devices
my $snmpQuery;
if (riscUtility::checkLicenseEnforcement()) {
	$snmpQuery = $mysql->prepare("select deviceid,ipaddress,credentialid,technology,vendor,level
									from credentials
									inner join riscdevice using(deviceid)
									inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic using(deviceid)
									inner join networkdeviceinfo using(deviceid)
									where technology = 'snmp'");
} else {
	$snmpQuery = $mysql->prepare("select deviceid,ipaddress,credentialid,technology,vendor,level
									from credentials
									inner join riscdevice using(deviceid)
									inner join networkdeviceinfo using(deviceid)
									where technology = 'snmp'");
}
$snmpQuery->execute();
my $numdevices = $snmpQuery->rows();

## polling interval
my $scantime = time();
eval {
	if ($numdevices > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'netperf',$numdevices)");
	} else {
		print "network_perf_admin: no devices or nothing licensed\n";
	}
};

my @devices;
while (my $ref = $snmpQuery->fetchrow_hashref) {
	push @devices, $ref;
}


foreach my $dev (@devices) {
	my $totalsleep=150;
	while (riscUtility::checkProcess("traffic2") > 10) {
		sleep 3;
		$totalsleep--;
		if ($totalsleep == 0) {
			die "Timed out process waiting for traffic scripts to finish" if $totalsleep==0;
		}
	}
	my $devIP=$dev->{'ipaddress'};
	my $devID=$dev->{'deviceid'};
	my $credID = $dev->{'credentialid'};
	my $devVendor = $dev->{'vendor'};
	$devVendor = 'none' if (!(defined($devVendor)) || $devVendor eq '');
	my $credLevel = $dev->{'level'};
	$credLevel = '32bit' unless defined $credLevel;
	next if $credLevel eq '32bit';
	next if $pid = fork;
	die "fork failed: $!" unless defined $pid;
	$execstring = "/usr/bin/perl /home/risc/traffic2.pl $devID $devIP $credID $devVendor $credLevel\n";
	print $execstring;   
	exec($execstring);
	exit(0);
}

$snmpQuery->finish();
$mysql->disconnect();


sub checkProcess {
	my $process = shift;
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result=@proclist;
	return $result;	
}
