#!/usr/bin/perl -w
use DBI();
use XML::Simple;
use Net::FTP;
use Data::Dumper;
use RISC::riscUtility;
use strict;

die if (checkDupProcess()>1);

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

my $winsth;
if (riscUtility::checkLicenseEnforcement()) {
	$winsth = $mysql->prepare_cached("select riscdevice.deviceid,ipaddress,wmi,credentialid from riscdevice
									inner join `RISC_Discovery`.credentials using(deviceid)
									inner join `risc_discovery`.credentials on `risc_discovery`.credentials.credid = `RISC_Discovery`.credentials.credentialid
									inner join windowsos using(deviceid)
									inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic using(deviceid)
									where credentials.technology='windows'
									and caption not regexp 'server'
									and `risc_discovery`.cred_decrypt(risc_discovery.credentials.context) = 'bmV0c3RhdA==' and `risc_discovery`.cred_decrypt(risc_discovery.credentials.securitylevel) = 'd29ya3N0YXRpb24='
									");
} else {
	$winsth = $mysql->prepare_cached("select riscdevice.deviceid,ipaddress,wmi,credentialid from `RISC_Discovery`.`riscdevice`
									inner join `RISC_Discovery`.credentials on riscdevice.deviceid = RISC_Discovery.credentials.deviceid
									inner join windowsos on riscdevice.deviceid = windowsos.deviceid
									inner join risc_discovery.credentials on risc_discovery.credentials.credid = RISC_Discovery.credentials.credentialid
									where RISC_Discovery.credentials.technology = 'windows'
									and caption not regexp 'server'
									and `risc_discovery`.cred_decrypt(risc_discovery.credentials.context) = 'bmV0c3RhdA==' and `risc_discovery`.cred_decrypt(risc_discovery.credentials.securitylevel) = 'd29ya3N0YXRpb24='
									");
}
$winsth->execute();
my $numberrows = $winsth->rows;

## polling interval
my $scantime = time();
eval {
	if ($numberrows > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'winworkperf',$numberrows)");
	} else {
		print "winworkperf: no devices or nothing licensed\n";
	}
};

my @devices;
while (my $ref = $winsth->fetchrow_hashref) {
        push(@devices,$ref);
}
for (my $i=0;$i<$numberrows;$i++){
       #my $pid;
       #print "$$\n";
       my $totalsleep=36;
	   while (riscUtility::checkProcess("winworkperf-detail") > 4) {
	    sleep 10;
	    $totalsleep--;
	    die if $totalsleep==0;
		}
       my  $devIP=$devices[$i]->{'ipaddress'};
       my  $devID=$devices[$i]->{'deviceid'};
       my  $credID = $devices[$i]->{'credentialid'};
       my $pid=fork;
       next if $pid == 0;
       die "fork failed: $!" unless defined $pid;
       my $execstring = "/usr/bin/perl /home/risc/winfiles/winworkperf-detail.pl $devID $devIP $credID";
        exec($execstring);
        exit(0);
}
$winsth->finish();

#cleanup

my $killDetails = "pkill -f winworkperf-detail";
my $maxSleep = 24;
while (checkDetails() > 0 && $maxSleep > 0) {
	sleep 10;
	$maxSleep--;
}

`$killDetails`;

$mysql->disconnect();

exit(0);

###################################################################################################################

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}

sub checkDetails {
	my @proclist = `pgrep -f winworkperf-detail`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
