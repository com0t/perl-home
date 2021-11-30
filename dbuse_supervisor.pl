#!/usr/bin/perl -w
use Data::Dumper;
use DBI;
use RISC::riscUtility;


# stop if the process hasn't finished from last call yet:
die if (checkDupProcess()>1);

# I don't know that there needs to be an analog of `pkill -f winexe` but it may turn out that there is.

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
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'dbperf-use',$numdevices)");
		print "dbuse_supervisor: running against $numdevices devices\n";
	} else {
		print "dbuse_supervisor: no devices or nothing licensed\n";
	}
};

# step through the credentials
while (my $ref = $dbsget->fetchrow_hashref) {
	if ($ref->{'can_acc'}){
		my $totalsleep=36; # if nobody finishes within 6 min something has gone wrong.
		while (riscUtility::checkProcess("dbprobe") > 15) {
		    sleep 10;
		    $totalsleep--;
		    die if $totalsleep==0;
		}
		my $pid = fork;
		next if $pid==0;
		die "fork failed: $!" unless defined $pid;
		# have to make sure these guys end up in the right directory
		my $devid = $ref->{'deviceid'};
		my $credid = $ref->{'credentialid'};
		my $execstring = "/usr/bin/perl /home/risc/dbprobe.pl $devid $credid";
		exec($execstring);
		exit(0);
	}
}

# cleanup. Need to think if there are other processes that should be killed here as well.
my $killDetails = "pkill -f dbprobe";
my $maxSleep = 24;
while (checkDbprobe() > 0 && $maxSleep > 0) {
	sleep 10;
	$maxSleep--;
}

`$killDetails`;


###############################SUBS##################################################################

sub checkDupProcess {
	my @proclist = `pgrep -f $0`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
sub checkDbprobe {
	my @proclist = `pgrep -f dbprobe`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
