#!usr/bin/perl -w
use Data::Dumper;
use RISC::riscUtility;
$SIG{CHLD}="IGNORE";

die if (checkDupProcess()>1);
my $instantPerf = shift;

#database connect
my $mysql = riscUtility::getDBH('RISC_Discovery',1);

#Get Devices
my $snmpQuery;
if ($instantPerf eq 'instant') {
	if (riscUtility::checkLicenseEnforcement()) {
		$snmpQuery = $mysql->prepare("select deviceid,ipaddress,credentialid,technology,ifnull(vendor,'none') as vendor,level
										from credentials
										inner join riscdevice using(deviceid)
										inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic using(deviceid)
										inner join networkdeviceinfo using(deviceid)
										where technology = 'snmp'
										and (credentials.level = '32bit' or credentials.level is null)");
	} else {
		$snmpQuery = $mysql->prepare("select deviceid,ipaddress,credentialid,technology,ifnull(vendor,'none') as vendor,level
										from credentials
										inner join riscdevice using(deviceid)
										inner join networkdeviceinfo using(deviceid)
										where technology = 'snmp'
										and (credentials.level = '32bit' or credentials.level is null)");
	}
} else {
	if (riscUtility::checkLicenseEnforcement()) {
		$snmpQuery = $mysql->prepare("select networkdeviceinfo.deviceid,riscdevice.ipaddress,credentialid,technology,vendor
										from networkdeviceinfo
										inner join credentials using(deviceid)
										inner join riscdevice using(deviceid)
										inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic using(deviceid)");
	} else {
		$snmpQuery = $mysql->prepare("select networkdeviceinfo.deviceid,riscdevice.ipaddress,credentialid,technology,vendor
										from networkdeviceinfo
										inner join credentials using(deviceid)
										inner join riscdevice using(deviceid)");
	}
}

$snmpQuery->execute();
$numberrows = $snmpQuery->rows;

## polling interval
my $scantime = time();
eval {
	if ($numberrows > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'netperf-instant',$numberrows)");
		print "risc5MinPerf: running against $numberrows devices\n";
	} else {
		print "risc5MinPerf: no devices or nothing licensed\n";
	}
};

my @devices;
while (my $ref = $snmpQuery->fetchrow_hashref) {
	push @devices, $ref;
}

for ($i=0;$i<$numberrows;$i++){
	my $totalsleep=45;
	while (riscUtility::checkProcess("traffic") > 10) {
		sleep 10;
		$totalsleep--;
		die "Timed out process waiting for traffic scripts to finish" if $totalsleep==0;
	}
	my $devIP=$devices[$i]->{'ipaddress'};
	my $devID=$devices[$i]->{'deviceid'};
	my $credID = $devices[$i]->{'credentialid'};
	my $devVendor = $devices[$i]->{'vendor'};
	next if $pid = fork;
	
	die "fork failed: $!" unless defined $pid;
	my $execstring;
	$execstring = "/usr/bin/perl /home/risc/traffic2.pl $devID $devIP $credID $devVendor 32bit\n" if ($instantPerf eq 'instant');
	$execstring = "/usr/bin/perl /home/risc/traffic.pl $devID $devIP $credID $devVendor 32bit\n" unless ($instantPerf eq 'instant');
	print $execstring;   
	exec($execstring);
	exit(0);
}

$snmpQuery->finish();
$mysql->disconnect();

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result=@proclist;
	return $result;	
}
