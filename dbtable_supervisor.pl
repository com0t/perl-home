#!/usr/bin/perl -w
use Data::Dumper;
use DBI;
use RISC::riscUtility;

die if (checkDupProcess()>1);

# connect to the databases. Little risc stores credentials and stuff, big RISC stores data to be pushed out.
my $mysql = riscUtility::getDBH('RISC_Discovery',1);

# grab database entries and credentials
# these will be stored in risc_discovery under some rather impressionistic columns.
# dbtype (mysql, mssql, oracle) in context, ip in domain, port in port
# user in username, password in passphrase, and sid (oracle only) in securityname (...)
# But this is irrelevant now, as we are querying big RISC about what databases there even are.
# for this investigation, credentials:databases is 1:1

my $dbsget;
if (riscUtility::checkLicenseEnforcement()) {
	$dbsget = $mysql->prepare("select cred.deviceid, credentialid, can_acc from credentials cred 
		inner join db_inventory dbi 
		on (cred.credentialid=dbi.credid) 
		inner join (select distinct deviceid from licensed where expires > unix_timestamp(now())) as lic 
		on (lic.deviceid=dbi.hostdevice)");
}else{
	$dbsget = $mysql->prepare("select deviceid, credentialid, can_acc from credentials cred inner join db_inventory dbi where cred.credentialid=dbi.credid");
	# note that here the "device id" is actually the dboid
}
# maybe join this to the database table and then where accessible = 1;
$dbsget->execute();

## polling interval
my $numdevices = $dbsget->rows();
my $scantime = time();
eval {
	if ($numdevices > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'dbperf-tables',$numdevices)");
		print "dbtable_supervisor: running against $numdevices devices\n";
	} else {
		print "dbtable_supervisor: no devices or nothing licensed\n";
	}
};

my $numPerfs = 0;
while (my $ref = $dbsget->fetchrow_hashref) {
	if ($ref->{'can_acc'}){
		my $totalsleep=36; # if nobody finishes within 6 min something has gone wrong.
		while (riscUtility::checkProcess("dbtables") > 15) {
		    sleep 10;
		    $totalsleep--;
		    die if $totalsleep==0;
		}
		$numPerfs++;
		my $pid = fork;
		next if $pid==0;
		die "fork failed: $!" unless defined $pid;
		# have to make sure these guys end up in the right directory
		my $devid = $ref->{'deviceid'};
		my $credid = $ref->{'credentialid'};
		my $execstring = "/usr/bin/perl /home/risc/dbtables.pl $devid $credid";
		exec($execstring);
		exit(0);
	}
}

# cleanup. Need to think if there are other processes that should be killed here as well.
my $killDetails = "pkill -f dbtables";
my $maxSleep = 120;
while (checkDbtables() > 0 && $maxSleep > 0) {
	sleep 10;
	$maxSleep--;
}

`$killDetails`;

if ($numPerfs) {
	my $dbtablesrows = $mysql->selectrow_hashref("select count(*) rowcount from db_tables");
	my $uploadCmd = "/usr/bin/perl /home/risc/dataupload_modular_admin.pl dbtableperf";
	system($uploadCmd) if $dbtablesrows->{'rowcount'};
}



###############################SUBS##################################################################

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
sub checkDbtables {
	my @proclist = `pgrep -f dbtables`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}

		


