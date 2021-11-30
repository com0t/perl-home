#!/usr/bin/perl
use strict;
use Switch;
use RISC::riscUtility;
use RISC::Collect::Logger;
use RISC::Collect::PerfScheduler;

$SIG{CHLD} = "IGNORE";

my $mysql = riscUtility::getDBH('risc_discovery',1);
$mysql->{mysql_auto_reconnect} = 1;
my $mysql2 = riscUtility::getDBH('RISC_Discovery',1);
$mysql2->{mysql_auto_reconnect} = 1;

my $logger = RISC::Collect::Logger->new('discovery');

my $dup_sleep_wait		= 300;	## wait interval between checking for previous copy of this script to complete
my $dup_sleep_iterations	= 36;	## number of $dup_sleep_waits to perform before giving up
my $concurrency_wait		= 10;	## wait interval between checking concurrency slots

my $assessmentid	= shift;
my $directive		= shift;
my $concurrents		= shift;

$concurrents		= 6 unless $concurrents;

## this is the script return that can be safely returned to RISC (dataplane separation)
##  this will be modified during execution if something other than 'complete' needs to be returned
my $riscreturn = 'complete';

$logger->info("begin discovery with concurrency of $concurrents");

#We need to kill perf first

#Pause Performance
$logger->debug('pausing performance');
RISC::Collect::PerfScheduler->new->pause('all', { kill => 1 });

## handle removed credential mappings
$logger->debug('backing up and removing device-cred mappings for removed credentials');
$mysql2->do("create table if not exists credentials_removed like credentials");
$mysql2->do("create temporary table credentials_removed_temp like credentials");
my $deleted_count = $mysql2->do("insert into credentials_removed_temp select C.* from `RISC_Discovery`.credentials C inner join `risc_discovery`.credentials c on c.credid = C.credentialid where c.removed = 1");
if ($deleted_count) {
	$mysql2->do("insert into credentials_removed select * from credentials_removed_temp");
	$mysql2->do("delete credentials.* from credentials inner join credentials_removed_temp using (credentialid)");
	$logger->debug("found $deleted_count removed credential mappings");
}
$mysql2->do("drop temporary table credentials_removed_temp");

#Check to see if discovery is running already (though shepherd should protec against this).  If so, sleep for 5 minutes - but never more than 1 hour
$logger->debug('ensuring that another platform_discovery.pl is not running');
while (riscUtility::checkProcess("platform_discovery") > 1) {
	$logger->debug("sleeping $dup_sleep_wait seconds for previous platform_discovery.pl to complete");
	sleep $dup_sleep_wait;
	$dup_sleep_iterations--;
	if ($dup_sleep_iterations == 0) {
		my $waited = $dup_sleep_iterations * $dup_sleep_wait;
		$logger->warn("stopping after waiting $waited seconds for previous platform_discovery.pl to complete");
		exit(1);
	}
}

#Assume now that no other discovery processes are running.  Check the directive
#	based on the directive, choose subnets and populate a table of start/end ip ints for use my inventory
my @allsubs;
switch ($directive) {
	case "ALL" {
		$logger->info('running ALL');
		$mysql2->do("drop table if exists ipranges");
		$mysql2->do("create table ipranges
			select id,inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10) as startipint,
			(inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10)) + pow(2,32 - substring_index(iprange,'/',-1)) - 1 as endipint
			from risc_discovery.discoverystats
			where status not in (1,6,3)
			group by iprange");
		#We are going to get ALL subnets from the subnets table regardless of their selection by RISC or the end customer
		my $subs = $mysql->prepare("select distinct(iprange) from discoverystats where status != 1 and status!=6 and status !=3");
		$subs->execute();
		while (my $sub2 = $subs->fetchrow_hashref()) {
			push (@allsubs,$sub2->{'iprange'});
		}
		scanSubnets(\@allsubs);
	}
	case "SELECTED" {
		$logger->info('running SELECTED');
		$mysql2->do("drop table if exists ipranges");
		$mysql2->do("create table ipranges
			select id,inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10) as startipint,
			(inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10)) + pow(2,32 - substring_index(iprange,'/',-1)) - 1 as endipint
			from risc_discovery.discoverystats
			where status in (0)
			group by iprange");
		#Now, get only subnets that were selected - this may be unnecessary but we will add this case in for use later
		my $subs = $mysql->prepare("select distinct(iprange) from discoverystats where status = 0");
		$subs->execute();
		while (my $sub2 = $subs->fetchrow_hashref()) {
			push (@allsubs,$sub2->{'iprange'});
		}
		scanSubnets(\@allsubs);
	}
	case "UNSCANNED" {
		$logger->info('running UNSCANNED');
		$mysql2->do("drop table if exists ipranges");
		$mysql2->do("create table ipranges
			select id,inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10) as startipint,
			(inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10)) + pow(2,32 - substring_index(iprange,'/',-1)) - 1 as endipint
			from risc_discovery.discoverystats
			where status not in (1,2,6,3)
			group by iprange");
		my $subs = $mysql->prepare("select distinct(iprange) from discoverystats where status != 1 and status !=2 and status!=6 and status !=3");
		$subs->execute();
		while (my $sub2 = $subs->fetchrow_hashref()) {
			push (@allsubs,$sub2->{'iprange'});
		}
		scanSubnets(\@allsubs);
	}
	case "RESCAN"{
		$logger->info('running RESCAN');
		$mysql2->do("drop table if exists ipranges");
		$mysql2->do("create table ipranges
			select id,inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10) as startipint,
			(inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10)) + pow(2,32 - substring_index(iprange,'/',-1)) - 1 as endipint
			from risc_discovery.discoverystats
			where status in (2)
			group by iprange");
		my $subs = $mysql->prepare("select distinct(iprange) from discoverystats where status =2");
		$subs->execute();
		while (my $sub2 = $subs->fetchrow_hashref()) {
			push (@allsubs,$sub2->{'iprange'});
		}
		scanSubnets(\@allsubs);
	}
	case "FULL"{
		$logger->info('running FULL');
		$mysql2->do("drop table if exists ipranges");
		$mysql2->do("create table ipranges
			select id,inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10) as startipint,
			(inet_aton(substring_index(iprange,'/',1)) & CONV(CONCAT(REPEAT(1,substring_index(iprange,'/',-1)), REPEAT(0, 32 - substring_index(iprange,'/',-1))), 2, 10)) + pow(2,32 - substring_index(iprange,'/',-1)) - 1 as endipint
			from risc_discovery.discoverystats
			where status in (0,2)
			group by iprange");
		my $subs = $mysql->prepare("select distinct(iprange) from discoverystats where status =2 or status=0");
		$subs->execute();
		while (my $sub2 = $subs->fetchrow_hashref()) {
			push (@allsubs,$sub2->{'iprange'});
		}
		scanSubnets(\@allsubs);
	} else {
		$logger->info("running against '$directive'");
		push (@allsubs,$directive);
		scanSubnets(\@allsubs);
	}
}

sub credDeviceidMapping {
        $mysql2->do("drop table if exists deviceid_credtag_mapping");
		$mysql2->do(riscUtility::schema_read('/home/risc/sql/RISC_Discovery/TABLE.deviceid_credtag_mapping.sql'));
        my $insert = "insert into RISC_Discovery.deviceid_credtag_mapping(deviceid, credtag) SELECT RISC_Discovery.credentials.deviceid as deviceid, risc_discovery.credentials.credtag as credtag FROM risc_discovery.credentials INNER JOIN RISC_Discovery.credentials on risc_discovery.credentials.credid = RISC_Discovery.credentials.credentialid";
		$mysql2->do($insert);
}

credDeviceidMapping();

$logger->info('complete');
print '||&||' . $riscreturn . '||&||';
$mysql->disconnect();
$mysql2->disconnect();
exit(0);

sub scanSubnets {
	my $populateAssessmentProgress = $mysql2->prepare("insert into assessmentprogress (phase,status,val1,val2,updatetime) values (?,?,?,?,?)");
	my $subs = shift;
	my $time = time();
	my $totalsubs = @$subs;
	$populateAssessmentProgress->execute("Discovery",1,$totalsubs,0,$time);
	foreach my $sub (@$subs) {
		sleep $concurrency_wait;
		while (riscUtility::checkProcess('nmap') >= 4 || riscUtility::checkProcess('disco.pl') >= $concurrents) {
			$logger->debug("sleeping $concurrency_wait for concurrency slot");
			sleep $concurrency_wait;
		}
		my $pid = fork();
		unless (defined($pid)) {
			$logger->error("fork failed: $!");
			exit(1);
		}
		if ($pid == 0) {
			## child
			my $disco_cmd = "/usr/bin/perl /home/risc/disco.pl $assessmentid $sub";
			$logger->debug($disco_cmd);
			exec($disco_cmd);
			exit(0); ## unreachable
		}
		## parent
	}
	$populateAssessmentProgress->execute("Inventory",0,0,0,$time);
	$populateAssessmentProgress->execute("WinInventory",0,0,0,$time);
	$populateAssessmentProgress->execute("slaDeploy",0,0,0,$time);
	$populateAssessmentProgress->execute("Performance",0,0,0,$time);
	$populateAssessmentProgress->execute("iPull",0,0,0,$time);
	$populateAssessmentProgress->execute("pPull",0,0,0,$time);
}
