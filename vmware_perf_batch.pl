#!/usr/bin/perl -w
#
# Copyright (c) 2007 VMware, Inc.  All rights reserved.
#
# Prints utilization report for host or vm managed entity.


#use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use Data::Dumper;
use Switch;
use Time::Local;
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
#$Util::script_version = "1.0";
use DBI();
use RISC::riscUtility;
use RISC::Collect::PerfSummary;
use RISC::Collect::Logger;
use lib 'lib';
$|++;

###
#Take arguments from outside script
##
my $devip = shift;
my $credid=shift;
my $entityScope = shift;
#my $devname=shift;
my $limit1 = shift;
my $limit2 = shift;
#print "I am risc_vmware_performance and I was passed: $devip -- $credid -- $entityScope -- $name\n";

my $logger = RISC::Collect::Logger->new(
	join('::', qw( perf vmware core ), $devip, $entityScope, $limit1, $limit2)
);
$logger->info('begin');

#database connect
my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

## remove proxy environment variables if they exist
$logger->debug('disabling proxy');
riscUtility::proxy_disable();

my $lookupuserinfo = $mysql2->prepare("
	SELECT	credid,
		productkey,
		technology,
		status,
		accepted,
		version,
		level,
		testip,
		cred_decrypt(passphrase) as passphrase,
		cred_decrypt(context) as context,
		cred_decrypt(securitylevel) as securitylevel,
		cred_decrypt(securityname) as securityname,
		cred_decrypt(authtype) as authtype,
		cred_decrypt(authpassphrase) as authpassphrase,
		cred_decrypt(privtype) as privtype,
		cred_decrypt(privusername) as privusername,
		cred_decrypt(privpassphrase) as privpassphrase,
		cred_decrypt(domain) as domain,
		port,
		cred_decrypt(userid) as userid,
		cred_decrypt(username) as username,
		scantime,
		eu,
		ap,
		removed
	FROM credentials
	WHERE credid = ?
");

$lookupuserinfo->execute($credid);
my $userinfo = $lookupuserinfo->fetchrow_hashref();
my $vmUser = escape(riscUtility::decode($userinfo->{'username'}));
my $vmPass = escape(riscUtility::decode($userinfo->{'passphrase'}));
$vmUser =~ s/\\\\/\\/g;	#Added 2015-07-07 JLB to change pairs of \ in username to singles as they should not be escaped when passed this way

my $hostdiskperf = $mysql->prepare_cached("insert into vmwarephysdiskperf (deviceid,scantime,instance,minsample,maxsample,diskdevicelatencymillisecondaveragemin,diskdevicelatencymillisecondaveragemax,diskdevicelatencymillisecondaverageavg,diskdevicereadlatencymillisecondaveragemin,diskdevicereadlatencymillisecondaveragemax,diskdevicereadlatencymillisecondaverageavg,diskdevicewritelatencymillisecondaveragemin,diskdevicewritelatencymillisecondaveragemax,diskdevicewritelatencymillisecondaverageavg,diskkernellatencymillisecondaveragemin,diskkernellatencymillisecondaveragemax,diskkernellatencymillisecondaverageavg,diskkernelreadlatencymillisecondaveragemin,diskkernelreadlatencymillisecondaveragemax,diskkernelreadlatencymillisecondaverageavg,diskkernelwritelatencymillisecondaveragemin,diskkernelwritelatencymillisecondaveragemax,diskkernelwritelatencymillisecondaverageavg,diskqueuelatencymillisecondaveragemin,diskqueuelatencymillisecondaveragemax,diskqueuelatencymillisecondaverageavg,diskqueuereadlatencymillisecondaveragemin,diskqueuereadlatencymillisecondaveragemax,diskqueuereadlatencymillisecondaverageavg,diskqueuewritelatencymillisecondaveragemin,diskqueuewritelatencymillisecondaveragemax,diskqueuewritelatencymillisecondaverageavg,diskreadkilobytespersecondaveragemin,diskreadkilobytespersecondaveragemax,diskreadkilobytespersecondaverageavg,disktotallatencymillisecondaveragemin,disktotallatencymillisecondaveragemax,disktotallatencymillisecondaverageavg,disktotalreadlatencymillisecondaveragemin,disktotalreadlatencymillisecondaveragemax,disktotalreadlatencymillisecondaverageavg,disktotalwritelatencymillisecondaveragemin,disktotalwritelatencymillisecondaveragemax,disktotalwritelatencymillisecondaverageavg,diskwritekilobytespersecondaveragemin,diskwritekilobytespersecondaveragemax,diskwritekilobytespersecondaverageavg,esxhost) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $totalperf_cpu= $mysql->prepare_cached("insert into vmwareperf_cpu (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
my $totalperf2_cpu= $mysql->prepare_cached("insert into vmwareperf_cpu (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?)");
my $totalperf_disk = $mysql->prepare_cached("insert into vmwareperf_disk (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
my $totalperf2_disk = $mysql->prepare_cached("insert into vmwareperf_disk (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?)");
my $totalperf_mem = $mysql->prepare_cached("insert into vmwareperf_mem (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
my $totalperf2_mem = $mysql->prepare_cached("insert into vmwareperf_mem (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?)");
my $totalperf_net = $mysql->prepare_cached("insert into vmwareperf_net (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
my $totalperf2_net = $mysql->prepare_cached("insert into vmwareperf_net (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?)");
my $totalperf_sys = $mysql->prepare_cached("insert into vmwareperf_sys (deviceid,scantime,entity,entityname,instance,value,counterid,countername,groupinfo) values (?,?,?,?,?,?,?,?,?)");
my $totalperf2_sys = $mysql->prepare_cached("insert into vmwareperf_sys (deviceid,scantime,entity,entityname,instance,value,counterid,countername,groupinfo,uuid,allvalues,starttime,endtime,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?)");

my $getDevID = $mysql->prepare("select max(deviceid) as deviceid from riscdevice where ipaddress=?");
my $devType = $mysql->prepare("select level from credentials where deviceid=? and technology=\'vmware\'");

my %opts = (
	countertype => {
		type => "=s",
		help => "Counter type [cpu | mem | net | disk | sys | all]",
		default => 'all',
		required => 0,
	},
	date => {
		type => "=s",
		help => "Date in yyyy-mm-dd format\n		If no date is provided, default to current date.",
		required => 0,
	},
	entity => {
		type => "=s",
		help => "Managed entity type [VirtualMachine | HostSystem]",
		default => $entityScope,
		required => 0,
	},
	freq => {
		type => "=s",
		help => "Frequency [daily | weekly | monthly]\n	The start date for the report will be computed from the frequency.\n	If the frequency is
daily, the start date will be one day less the 'date' value specified.\n	For weekly frequencies, the start date will be seven days less the 'date'
value specified. ",
		required => 0,
	},
	name => {
		type => "=s",
		help => "Name of the host or virtual machine\n		If name is not specified, the utilization report will contain all host/vm data.",
		required => 0,
	}
);


Opts::add_options(%opts);

# Parse connection options and connect to the server
Opts::set_option('username',$vmUser);
Opts::set_option('password',$vmPass);
Opts::set_option('server',$devip);
#Opts::set_option('name',$devname);

## CLOUD-6625 avoid renaming the process to "Hiding the command line arguments",
## which Opts::parse() does automatically.
my $original_name = $0;
Opts::parse();
$0 = $original_name;

Opts::validate();

my $servername = Opts::get_option('server');
$getDevID->execute($servername);

#Connect to the host or vc server
Util::connect();

# set the locale to en_US so we get parseable counter info
my $session_manager = Vim::get_view( mo_ref => Vim::get_service_content()->sessionManager );
$session_manager->SetLocale(locale => 'en_US');

my $deviceid = $getDevID->fetchrow_hashref()->{'deviceid'};
$devType->execute($deviceid);
my $scantime = time();
my $hostperformance;
$perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
my $all_counters;
my $cpu_counters;
my $memory_counters;
my $disk_counters;
my $system_counters;
my $net_counters;
my $st_date;
my $entity_type = Opts::get_option('entity');
my $counter_type = Opts::get_option('countertype');
my $frequency = Opts::get_option('freq');
my $name = Opts::get_option('name');
my $end_date = Opts::get_option('date');
my $hostperf;

#build list of entities based on type and limits from arguments

$deviceid =~ /\d\d\d\d(\d+)/;
my $smallDevid = $1;

my $entityQuery;
if ($entity_type eq 'HostSystem') {
	if (riscUtility::checkLicenseEnforcement()) {
		$entityQuery = $mysql->prepare("
			select	objectid,
				riscvmwarematrix.uuid,
				vmware_hostsystem.name,
				'HostSystem' as type,
				riscvmwarematrix.vcenterid as vcenterid
			from vmware_hostsystem
			inner join credentials on credentials.deviceid=vmware_hostsystem.deviceid
			inner join riscdevice on vmware_hostsystem.deviceid=riscdevice.deviceid
			inner join riscvmwarematrix on vmware_hostsystem.uuid = riscvmwarematrix.uuid
			inner join (
				select distinct deviceid from licensed where expires > unix_timestamp(now())
			) as lic on lic.deviceid = riscvmwarematrix.deviceid
			where credentials.credentialid = $credid
			limit $limit1,$limit2
		");
	} else {
		$entityQuery = $mysql->prepare("
			select	objectid,
				riscvmwarematrix.uuid,
				vmware_hostsystem.name,
				'HostSystem' as type,
				riscvmwarematrix.vcenterid as vcenterid
			from vmware_hostsystem
			inner join credentials on credentials.deviceid=vmware_hostsystem.deviceid
			inner join riscdevice on vmware_hostsystem.deviceid=riscdevice.deviceid
			inner join riscvmwarematrix on vmware_hostsystem.uuid = riscvmwarematrix.uuid
			where credentials.credentialid = $credid
			limit $limit1,$limit2
		");
	}
} else {

	my $entityNames = buildGuestList($mysql,$deviceid,$smallDevid,$limit1,$limit2);

	$entityQuery = $mysql->prepare("
		select	objectid,
			riscvmwarematrix.uuid,
			vmware_guestsummaryconfig.name,
			'VirtualMachine' as type,
			riscvmwarematrix.vcenterid as vcenterid
		from vmware_guestsummaryconfig
		inner join credentials on vmware_guestsummaryconfig.deviceid=credentials.deviceid
		inner join riscdevice on vmware_guestsummaryconfig.deviceid=riscdevice.deviceid
		inner join riscvmwarematrix on vmware_guestsummaryconfig.uuid = riscvmwarematrix.uuid
			and vmware_guestsummaryconfig.deviceid = riscvmwarematrix.vcenterid
		where credentials.credentialid = $credid
		and vmware_guestsummaryconfig.name in ($entityNames)
	");
}

$entityQuery->execute();

my @queries;
my $devHash;
my $counters = getVMCounters($mysql,$deviceid,$smallDevid);
my $counterString = join(',',@{$counters});
my $devCounterHash = buildDevCounterHash($mysql,$counterString);

my @summarydevices;
while (my $line = $entityQuery->fetchrow_hashref()) {
	push(@summarydevices,$line->{'uuid'});
	#build a list of metrics
	populatePerfCounters($line->{'name'},$mysql,$counterString,$devCounterHash) unless $devCounterHash->{$deviceid}->{$line->{'name'}};#if $mysql->selectrow_hashref("select count(*) as num from vmwareperf_counterinfo where entityname = ? and deviceid = ? and counterid in ($counterString)")->{'num'} == 0;


	my $getMetrics = $mysql->prepare("select * from vmwareperf_counterinfo where entityname = ? and deviceid in (?,?) and counterid in ($counterString)");
	$getMetrics->execute($line->{'name'},$deviceid,$smallDevid);
	my @metrics;
	$all_counters = $getMetrics->fetchall_hashref('counterid');
	foreach my $id (keys %{$all_counters}) {
		my $metid = PerfMetricId->new(
			counterId=>$id,
			instance=>'*'
		);
		push @metrics,$metid;
	}

	my $perf_metric_ids = \@metrics;
	my $objectid = $line->{'objectid'};
	my $dev->{'type'} = $line->{'type'};
	$dev->{'value'} = $objectid;
	bless($dev,'ManagedObjectReference');
	my $perfQuerySpec = PerfQuerySpec->new(entity => $dev,
		metricId => $perf_metric_ids,
		format => 'csv',
		#startTime => $st_date,
		#endTime => $end_date
		intervalId=>20,
		maxSample=>180
	);
	push(@queries,$perfQuerySpec);
	$devHash->{$objectid}->{'name'} = $line->{'name'};
	$devHash->{$objectid}->{'uuid'} = $line->{'uuid'};
	$devHash->{$objectid}->{'type'} = $line->{'type'};
	$devHash->{$objectid}->{'vcenterid'} = $line->{'vcenterid'};
	$devHash->{$objectid}->{'counters'} = $all_counters;

	chomp(my $clean_name = $line->{'name'});
	$logger->info(sprintf('name: %s, uuid: %s, type: %s, vcenterid: %s',
		$clean_name, $line->{'uuid'}, $line->{'type'}, $line->{'vcenterid'}
	));
}


if (!defined ($counter_type)) {
	$counter_type='all'
}



$hostperformance=undef;
my $entityList;

#  my $getMetrics = $mysql->prepare_cached("select * from vmwareperf_counterinfo where deviceid=? and entityname=? and (groupinfo='cpu' or groupinfo='disk' or groupinfo='mem' or groupinfo='net' or groupinfo='datastore' or groupinfo regexp 'storage' or groupinfo='vmop')");


# get performance data
#	my $perf_data = $perfmgr_view->QueryPerf(querySpec => $perf_query_spec);
my $perf_data = $perfmgr_view->QueryPerf(querySpec => \@queries);
if (!defined ($perf_data) || !@$perf_data) {
	print "\n---------------------------------------------------------------------------------\n";
	print "no stats available for the given date range.  Try different dates.\n" ;
	print "---------------------------------------------------------------------------------\n\n";
	next;
}

my $mysqlForInsert = riscUtility::getDBH('RISC_Discovery',1);

my $udlookup = $mysqlForInsert->selectall_hashref("select deviceid, vcenterid, uuid from riscvmwarematrix",["uuid","vcenterid"]);

if ($entity_type eq 'HostSystem'){
	$hostperf = $mysqlForInsert->prepare_cached("
		insert into vmware_hostperformance
		(
			deviceid,
			scantime,
			samples,
			minsample,
			maxsample,
			avgmemorygranted,
			minmemorygranted,
			maxmemorygranted,
			avgcpuutil,
			mincpuutil,
			maxcpuutil,
			avgcpumhz,
			mincpumhz,
			maxcpumhz,
			avgdiskkbytespersec,
			mindiskkbytespersec,
			maxdiskkbytespersec,
			avgkbytememactive,
			minkbytememactive,
			maxkbytememactive,
			avgmemutil,
			minmemutil,
			maxmemutil,
			avgnetkbyte,
			minnetkbyte,
			maxnetkbyte,
			esxhost
		)
		values
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
} else {
	$hostperf = $mysqlForInsert->prepare_cached("
		insert into vmware_guestperformance
		(
			deviceid,
			scantime,
			samples,
			minsample,
			maxsample,
			avgmemorygranted,
			minmemorygranted,
			maxmemorygranted,
			avgcpuutil,
			mincpuutil,
			maxcpuutil,
			avgcpumhz,
			mincpumhz,
			maxcpumhz,
			avgdiskkbytespersec,
			mindiskkbytespersec,
			maxdiskkbytespersec,
			avgkbytememactive,
			minkbytememactive,
			maxkbytememactive,
			avgmemutil,
			minmemutil,
			maxmemutil,
			avgnetkbyte,
			minnetkbyte,
			maxnetkbyte,
			name
		)
		values
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
}


$mysqlForInsert->begin_work();
foreach (@$perf_data) {
	my $objectid = $_->{'entity'}->value;
	my $entityname = $devHash->{$objectid}->{'name'};
	my $entitytype = $devHash->{$objectid}->{'type'};
	my $uuid = $devHash->{$objectid}->{'uuid'};
	my $vcenterid = $devHash->{$objectid}->{'vcenterid'};
	my $riscdevid = $udlookup->{$uuid}->{$vcenterid}->{'deviceid'};
	my $valuehash = {};
	my $diskhash = {};
	my $esxhost = $entityname;
#	$uuid = $entity->config->uuid unless $entity_type eq "HostSystem";
#	$uuid = $entity->{'hardware'}->{'systemInfo'}->{'uuid'} if $entity_type eq "HostSystem";
#	$uuid='none' unless defined $uuid;
#	print "\n---------------------------------------------\n";
#	print "'" . $entityname . "'\n";
#	print "---------------------------------------------\n";

	my $time_stamps = $_->sampleInfoCSV;
	my $values = $_->value;
	my @ts = split(/,/,$time_stamps);
	my $ts_size = @ts;
	my $start_timestamp = $ts[1];#
	$start_timestamp =~ s/(.*)T(.*)/$1\ $2/;
	my $end_timestamp = $ts[$ts_size-1];
	$end_timestamp =~ s/(.*)T(.*)/$1\ $2/;
	$ts_size=$ts_size/2; #Have to divide by 2 because vmware returns the sample period with the timestamps
#	print " $deviceid Start-$start_timestamp---------End-$end_timestamp\n";
#	print "Number of samples : $ts_size \n\n";

	my $savedValues;
	foreach (@$values) {
		$savedValues = logPerf(
			$mysqlForInsert,
			$objectid,
			$esxhost,
			$uuid,
			$start_timestamp,
			$end_timestamp,
			$savedValues,
			$_
		);
		# each @values is a string of comma-separated values representing a given counter at a given timestamp.
		# I'm making sure I understand the timestamp csv; it looks like there is extra stuff
		# okay: the timestamp csv is of the format t1-t0,t1,t2-t1,t2,etc. deltat,t,deltat,t,you get me.
		if ($riscdevid) {
			logNewPerf($mysqlForInsert,$riscdevid,$time_stamps,$_);
		} else {
			$logger->error('no deviceid, skipping logNewPerf()');
		}
	}

	$hostperf->execute(
		$deviceid,
		$scantime,
		$ts_size,
		$start_timestamp,
		$end_timestamp,
		$hostperformance->{'memgranted'}->{'average'},
		$hostperformance->{'memgranted'}->{'minimum'},
		$hostperformance->{'memgranted'}->{'maximum'},
		$hostperformance->{'cpuusage'}->{'average'},
		$hostperformance->{'cpuusage'}->{'minimum'},
		$hostperformance->{'cpuusage'}->{'maximum'},
		$hostperformance->{'cpuusagemhz'}->{'average'},
		$hostperformance->{'cpuusagemhz'}->{'minimum'},
		$hostperformance->{'cpuusagemhz'}->{'maximum'},
		$hostperformance->{'diskkbytespersec'}->{'average'},
		$hostperformance->{'diskkbytespersec'}->{'minimum'},
		$hostperformance->{'diskkbytespersec'}->{'maximum'},
		$hostperformance->{'memkbyteactive'}->{'average'},
		$hostperformance->{'memkbyteactive'}->{'minimum'},
		$hostperformance->{'memkbyteactive'}->{'maximum'},
		$hostperformance->{'memutil'}->{'average'},
		$hostperformance->{'memutil'}->{'minimum'},
		$hostperformance->{'memutil'}->{'maximum'},
		$hostperformance->{'netkbytespersec'}->{'average'},
		$hostperformance->{'netkbytespersec'}->{'minimum'},
		$hostperformance->{'netkbytespersec'}->{'maximum'},
		$esxhost
	);
}
$mysqlForInsert->commit();
#}

## for perf summary, accounting as we go is troublesome, and we don't want to
## check during perf processing, as this will only get us devices that did report,
## not all devices we're attempting to get
## so, we get the list of licensed devices that we are attempting to collect and check
## whether we have data populated in the tables
foreach my $sumuuid (@summarydevices) {
	## get the little deviceid based on the uuid
	my $devid = $mysqlForInsert->selectrow_hashref("select deviceid from riscvmwarematrix where uuid = '$sumuuid'")->{'deviceid'};
	my $summary = RISC::Collect::PerfSummary::get($mysqlForInsert,$devid,'vmware');
	$summary->{'attempt'} = $scantime;

	my @nodata;

	## check cpu
	my $cpucount = $mysqlForInsert->selectrow_hashref("select count(*) as numcpu from vmwareperf_cpu where uuid = '$sumuuid'")->{'numcpu'};
	if ($cpucount) {
		$summary->{'cpu'} = $scantime;
	} else {
		push(@nodata, 'cpu');
	}

	## check mem
	my $memcount = $mysqlForInsert->selectrow_hashref("select count(*) as nummem from vmwareperf_mem where uuid = '$sumuuid'")->{'nummem'};
	if ($memcount) {
		$summary->{'mem'} = $scantime;
	} else {
		push(@nodata, 'mem');
	}

	## check diskutil and diskio (should get both if we have anything for disk)
	my $diskcount = $mysqlForInsert->selectrow_hashref("select count(*) as numdisk from vmwareperf_disk where uuid = '$sumuuid'")->{'numdisk'};
	if ($diskcount) {
		$summary->{'diskutil'} = $scantime;
		$summary->{'diskio'} = $scantime;
	} else {
		push(@nodata, 'diskutil', 'diskio');
	}

	## check traffic
	my $trafcount = $mysqlForInsert->selectrow_hashref("select count(*) as numtraf from vmwareperf_net where uuid = '$sumuuid'")->{'numtraf'};
	if ($trafcount) {
		$summary->{'traffic'} = $scantime;
	} else {
		push(@nodata, 'traffic');
	}

	if (@nodata) {
		$summary->{'error'} = sprintf('nodata:%s', join(',', @nodata));
	}

	RISC::Collect::PerfSummary::set($mysqlForInsert, $summary);
}

$logger->debug('disconnecting');
Util::disconnect();

$logger->info('complete');
exit(0);


####ESX SERVERS
sub minimum {
	my @arr = @_;
	my $n = @arr;

	if ($n == 0) {
		die "The array has no elements \n";
	}

	my $i = 0;
	my $min;

	for ($i = 0; $i < $n; $i++) {
		if ($arr[$i] != -1) {
			$min = $arr[$i];
			last;
		}
	}

	for (; $i < $n; $i++) {
		if (($arr[$i] < $min) && ($arr[$i] != -1)) {
			$min = $arr[$i];
		}
	}
	$min = 0 unless $min;
	return $min;
}

sub maximum {
	my @arr = @_;
	my $n= @arr;
	if ($n == 0) {
		die "The array has no elements.\n";
	}

	my $i=0;
	my $max;

	for ($i = 0; $i < $n; $i++) {
		if ($arr[$i] != -1) {
			$max = $arr[$i];
			last;
		}
	}

	for (; $i < $n; $i++) {
		if ($arr[$i] > $max) {
			$max = $arr[$i];
		}
	}

	return $max;
}

sub sum {
	my @arr = @_;
	my $n=0;
	my $sum = 0;
	if (@arr ==0 ) {
		return $sum;
	}
	for (my $i=0; $i < @arr; $i++) {
		$sum=$sum+$arr[$i];
	}
	return $sum;
}

sub average {
	my @arr = @_;
	my $n = 0;
	my $avg = 0;

	if (@arr == 0) {
		die "The array has no elements.\n";
	}

	for (my $i = 0; $i < @arr; $i++) {
		if ($arr[$i] != -1) {
			$avg = $avg + $arr[$i];
			$n++;
		}
	}
	if ($n<1) {
		return 0;
	} else {
		return $avg/$n;
	}
}

sub stddev {
	my(@data) = @_;
	if(@data == 1) {
		return 0;
	}
	my $average = &average(@data);
	my $sqtotal = 0;
	foreach(@data) {
		$sqtotal += ($average-$_) ** 2;
	}
	my $std = ($sqtotal / (@data-1)) ** 0.5;
	return $std;
}

sub get_perf_interval {
	my $entity = shift;
	my $provider_summary = $perfmgr_view->QueryPerfProviderSummary(entity => $entity);
	my $interval = $provider_summary->refreshRate;
	return $interval;
}


sub populatePerfCounters {
	my $esx = shift;
	my $mysql = shift;
	my $counterString = shift;
	my $devCounterHash = shift;
	$perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
	## changed from selectrow_hashref() to prepare() to handle single-quotes in guest names
	my $testpopQ = $mysql->prepare("select count(*) as totrows from vmwareperf_counterinfo where entityname=? and deviceid=?");
	$testpopQ->execute($esx,$deviceid);
	my $testpop = $testpopQ->fetchrow_hashref();
	if ($testpop->{'totrows'} < 1) {
		my $counterpop = $mysql->prepare_cached("insert into vmwareperf_counterinfo(deviceid,scantime,entityname,counterid,rolluptype,statstype,unitinfo,groupinfo,summary,label,category) values (?,?,?,?,?,?,?,?,?,?,?)");
		my $perfCounterInfo = $perfmgr_view->perfCounter;
		foreach my $counter (@$perfCounterInfo) {
			my $rolltype = $counter->rollupType->val;
			my $statstype = $counter->statsType->val;
			my $unit = $counter->unitInfo->key;
			my $group = $counter->groupInfo->key;
			my $summ = $counter->nameInfo->summary;
			my $label = $counter->nameInfo->label;
			my $category = $counter->nameInfo->key;
			my $counterid = $counter->key;
			$counterpop->execute($deviceid,$scantime,$esx,$counterid,$rolltype,$statstype,$unit,$group,$summ,$label,$category);
			$devCounterHash->{$deviceid}->{$esx}->{$counterid}++;
		}
	}
	return $devCounterHash;
}

sub logPerf {
	my $mysql = shift;
	my $objectid = shift;
	my $esx=shift;
	my $uuid=shift;
	my $starttime=shift;
	my $endtime=shift;
	my $saveValues=shift;
	my $counter = shift;
	my @values = split(',',$counter->value);
	my $allvalues=join(':',@values);
	my $max=maximum(@values);
	my $avg=average(@values);
	my $sum=sum(@values);
	my $min = minimum(@values);
	my $stddev=stddev(@values);
	my $counterid=$counter->id->counterId;
	my $instance = $counter->id->instance;
	my $totalperf_cpu= $mysql->prepare("insert into vmwareperf_cpu (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
	my $totalperf2_cpu= $mysql->prepare("insert into vmwareperf_cpu (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmin,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?,?)");
	my $totalperf_disk = $mysql->prepare("insert into vmwareperf_disk (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
	my $totalperf2_disk = $mysql->prepare("insert into vmwareperf_disk (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmin,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?,?)");
	my $totalperf_mem = $mysql->prepare("insert into vmwareperf_mem (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
	my $totalperf2_mem = $mysql->prepare("insert into vmwareperf_mem (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmin,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?,?)");
	my $totalperf_net = $mysql->prepare("insert into vmwareperf_net (deviceid,scantime,entity,entityname,instance,value,counterid,countername) values (?,?,?,?,?,?,?,?)");
	my $totalperf2_net = $mysql->prepare("insert into vmwareperf_net (deviceid,scantime,entity,entityname,instance,value,counterid,countername,uuid,allvalues,starttime,endtime,rmin,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?,?)");
	my $totalperf_sys = $mysql->prepare("insert into vmwareperf_sys (deviceid,scantime,entity,entityname,instance,value,counterid,countername,groupinfo) values (?,?,?,?,?,?,?,?,?)");
	my $totalperf2_sys = $mysql->prepare("insert into vmwareperf_sys (deviceid,scantime,entity,entityname,instance,value,counterid,countername,groupinfo,uuid,allvalues,starttime,endtime,rmin,rmax,ravg,rsum,rstddev) values (?,?,?,?,?,?,?,?,?,?,?,unix_timestamp(?),unix_timestamp(?),?,?,?,?,?)");
	my $type = $devHash->{$objectid}->{'counters'}->{$counterid}->{'rolluptype'};
	my $category = $devHash->{$objectid}->{'counters'}->{$counterid}->{'groupinfo'};
	my $name = $devHash->{$objectid}->{'counters'}->{$counterid}->{'category'};
	my $summary = $devHash->{$objectid}->{'counters'}->{$counterid}->{'summary'};
	my $unit = $devHash->{$objectid}->{'counters'}->{$counterid}->{'unitinfo'};
	my $label = $devHash->{$objectid}->{'counters'}->{$counterid}->{'label'};
	my $perfvalue=undef;
	if ($type eq 'average') {
		$perfvalue=average(@values);
	} elsif ($type eq 'maximum') {
		$perfvalue=maximum(@values);
	} elsif ($type eq 'minimum') {
		$perfvalue=minimum(@values);
	} elsif ($type eq 'summation') {
		$perfvalue=sum(@values);
	} else {
		$perfvalue=$values[0];
	}
	if ($unit eq 'percent') {
		#Divide by 100 for all percent values
		$perfvalue=$perfvalue/100;
		$min/=100;
		$max/=100;
		$avg/=100;
		$sum/=100;
		$stddev/=100;
	}
	#Now do vmware_hostperformance columns - these will go away as we re-write the reports to go off the tables below:
	if ($category eq 'cpu' && $instance eq '' && $unit eq 'percent' && $label eq 'Usage' && $type ne 'none') {
		$hostperformance->{'cpuusage'}->{$type}=$perfvalue;
	} elsif ($category eq 'cpu' && $instance eq '' && $unit eq 'megaHertz' && $label eq 'Usage in MHz' && $type ne 'none') {
		$hostperformance->{'cpuusagemhz'}->{$type}=$perfvalue;
	} elsif ($category eq 'mem' && $instance eq '' && $unit eq 'percent' && $label eq 'Usage' && $type ne 'none') {
		$hostperformance->{'memutil'}->{$type}=$perfvalue;
	} elsif ($category eq 'mem' && $instance eq '' && $unit eq 'kiloBytes' && $label eq 'Granted' && $type ne 'none') {
		$hostperformance->{'memgranted'}->{$type}=$perfvalue;
	} elsif ($category eq 'mem' && $instance eq '' && $unit eq 'kiloBytes' && $label eq 'Active' && $type ne 'none') {
		$hostperformance->{'memkbyteactive'}->{$type}=$perfvalue;
	} elsif ($category eq 'disk' && $instance eq '' && $unit eq 'kiloBytesPerSecond' && $label eq 'Usage' && $type ne 'none') {
		$hostperformance->{'diskkbytespersec'}->{$type}=$perfvalue;
	} elsif ($category eq 'net' && $instance eq '' && $unit eq 'kiloBytesPerSecond' && $label eq 'Usage' && $type ne 'none') {
		$hostperformance->{'netkbytespersec'}->{$type}=$perfvalue;
	}
	#print "Counterid=$counterid Instance=$instance Type=$type\n";
	if ($category eq 'net') {
		eval {$totalperf2_net->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$uuid,$allvalues,$starttime,$endtime,$min,$max,$avg,$sum,$stddev);};
			if ($@) {
				$totalperf_net->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name);
			}
	} elsif ($category =~ /disk/i || $category eq 'datastore' || $category =~ /storage/i) {
		eval {
			$totalperf2_disk->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$uuid,$allvalues,$starttime,$endtime,$min,$max,$avg,$sum,$stddev);
		}; if ($@) {
			$totalperf_disk->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name);
		}
		#cook avg disk write size
		if ($label eq 'Write rate') {
			if (defined($savedValues->{'avgRequests'}->{$instance}) || $avg==0) {
				my $writeSizeAvg;
				if ($avg==0 || $savedValues->{'avgRequests'}->{$instance}==0 || not defined($savedValues->{'avgRequests'}->{$instance})) {
					$writeSizeAvg=0;
				} else {
					$writeSizeAvg=$avg/$savedValues->{'avgRequests'}->{$instance};
				}
				my $writeSizeMax=-1;
				my $writeSizeSum=-1;
				my $writeSizeStdDev=-1;
				my $writeSizeCounterid=3000;
				my $writeSizeName='writeSizeAveraged';
				$totalperf2_disk->execute($deviceid,$scantime,$entity_type,$esx,$instance,$writeSizeAvg,$writeSizeCounterid,$writeSizeName,$uuid,'N/A',$starttime,$endtime,-1,$writeSizeMax,$writeSizeAvg,$writeSizeSum,$writeSizeStdDev);
			} else {
				$savedValues->{'writeRate'}->{$instance}=$avg;
			}
		}
		if ($label eq 'Average write requests per second') {
			if (defined($savedValues->{'writeRate'}->{$instance}) || $avg==0) {
				my $writeSizeAvg;
				if ($avg==0) {
					$writeSizeAvg=0;
				} else {
					$writeSizeAvg=$savedValues->{'writeRate'}->{$instance}/$avg;
				}
				my $writeSizeMax=-1;
				my $writeSizeSum=-1;
				my $writeSizeStdDev=-1;
				my $writeSizeCounterid=3000;
				my $writeSizeName='writeSizeAveraged';
				$totalperf2_disk->execute($deviceid,$scantime,$entity_type,$esx,$instance,$writeSizeAvg,$writeSizeCounterid,$writeSizeName,$uuid,'N/A',$starttime,$endtime,-1,$writeSizeMax,$writeSizeAvg,$writeSizeSum,$writeSizeStdDev);
			} else {
				$savedValues->{'avgRequests'}->{$instance}=$avg;
			}
		}
	} elsif ($category eq 'cpu'){
		eval {$totalperf2_cpu->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$uuid,$allvalues,$starttime,$endtime,$min,$max,$avg,$sum,$stddev);};
			if ($@) {
				$totalperf_cpu->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name);
			}
	} elsif ($category eq 'mem'){
		eval {$totalperf2_mem->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$uuid,$allvalues,$starttime,$endtime,$min,$max,$avg,$sum,$stddev);};
			if ($@) {
				$totalperf_mem->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name);
			}
	} else {
		eval {$totalperf2_sys->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$category,$uuid,$allvalues,$starttime,$endtime,$min,$max,$avg,$sum,$stddev);};
			if ($@) {
				$totalperf_sys->execute($deviceid,$scantime,$entity_type,$esx,$instance,$perfvalue,$counterid,$name,$category);
			}
	}
	#(deviceid,scantime,entity,entityname,instance,value,counterid,countermetric,countername,countertype,$category)
	#print "Counter: ".Dumper($counter);
	return $savedValues;
}

sub escape {
	my $string=shift;
#	$string=~s/([\/\$\%\^\@\&\*\{\}\[\]\<\>\=\\])/\\$1/g;
#	$string=~ s/([\\\/\\\$\#\%\^\@\!\&\*\(\)\{\}\[\]\<\>\=])/\\$1/g;
	return $string;
}

sub getVMCounters {
	my $mysql = shift;
	my $vcenterid = shift;
	my $smallDevid = shift;
	my $return;
	my @counters;

	#cpu counter
	my $cpuQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where groupinfo='cpu'
												and label='Usage in MHz'
												and rolluptype='maximum'
												and deviceid in ($vcenterid,$smallDevid)
												group by deviceid,counterid");

	push @counters,$cpuQuery->{'counterid'} if $cpuQuery->{'counterid'};

	#mem counter
	my $memQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where groupinfo='mem'
												and label='usage'
												and rolluptype='average'
												and deviceid in ($vcenterid,$smallDevid)
												group by deviceid,counterid");
	push @counters,$memQuery->{'counterid'} if $memQuery->{'counterid'};

	my $memGrantedQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where groupinfo='mem'
												and label='Granted'
												and rolluptype='average'
												and unitinfo = 'kiloBytes'
												and deviceid in ($vcenterid,$smallDevid)
												group by deviceid,counterid");
	push @counters,$memGrantedQuery->{'counterid'} if $memGrantedQuery->{'counterid'};

	my $memActiveQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where groupinfo='mem'
												and label='Active'
												and rolluptype='average'
												and unitinfo = 'kiloBytes'
												and deviceid in ($vcenterid,$smallDevid)
												group by deviceid,counterid");
	push @counters,$memActiveQuery->{'counterid'} if $memActiveQuery->{'counterid'};

	#net io in counter
	my $netinQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where deviceid in ($vcenterid,$smallDevid)
												and vmwareperf_counterinfo.groupinfo='net'
												and vmwareperf_counterinfo.statstype='rate'
												and vmwareperf_counterinfo.unitinfo='kilobytespersecond'
												and vmwareperf_counterinfo.rolluptype='average'
												and vmwareperf_counterinfo.category like '%received%' limit 1");
	push @counters,$netinQuery->{'counterid'} if $netinQuery->{'counterid'};

	#net io out counter
	my $netoutQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
												where deviceid in ($vcenterid,$smallDevid)
												and vmwareperf_counterinfo.groupinfo='net'
												and vmwareperf_counterinfo.statstype='rate'
												and vmwareperf_counterinfo.unitinfo='kilobytespersecond'
												and vmwareperf_counterinfo.rolluptype='average'
												and vmwareperf_counterinfo.category like '%transmitted%' limit 1");
	push @counters,$netoutQuery->{'counterid'} if $netoutQuery->{'counterid'};

	#physdisk io read counter
#	my $physDiskReadQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and vmwareperf_counterinfo.groupinfo='disk'
#														and vmwareperf_counterinfo.statstype='delta'
#														and vmwareperf_counterinfo.unitinfo='number'
#														and vmwareperf_counterinfo.rolluptype='summation'
#														and vmwareperf_counterinfo.category like '%number%'
#														and vmwareperf_counterinfo.category like '%read%'
#														limit 1");
#	push @counters,$physDiskReadQuery->{'counterid'} if $physDiskReadQuery->{'counterid'};

	#physdisk io write counter
#	my $physDiskWriteQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and vmwareperf_counterinfo.groupinfo='disk'
#														and vmwareperf_counterinfo.statstype='delta'
#														and vmwareperf_counterinfo.unitinfo='number'
#														and vmwareperf_counterinfo.rolluptype='summation'
#														and vmwareperf_counterinfo.category like '%number%'
#														and vmwareperf_counterinfo.category like '%write%'
#														limit 1");
#	push @counters,$physDiskWriteQuery->{'counterid'} if $physDiskWriteQuery->{'counterid'};

	#virtdisk io read counter
#	my $virtDiskReadQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and vmwareperf_counterinfo.groupinfo='virtualdisk'
#														and vmwareperf_counterinfo.statstype='rate'
#														and vmwareperf_counterinfo.unitinfo='number'
#														and vmwareperf_counterinfo.rolluptype='average'
#														and vmwareperf_counterinfo.category like '%number%'
#														and vmwareperf_counterinfo.category like '%read%'
#														limit 1");
#	push @counters,$virtDiskReadQuery->{'counterid'} if $virtDiskReadQuery->{'counterid'};
	#virtdisk io write counter
#	my $virtDiskWriteQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and vmwareperf_counterinfo.groupinfo='virtualdisk'
#														and vmwareperf_counterinfo.statstype='rate'
#														and vmwareperf_counterinfo.unitinfo='number'
#														and vmwareperf_counterinfo.rolluptype='average'
#														and vmwareperf_counterinfo.category like '%number%'
#														and vmwareperf_counterinfo.category like '%write%'
#														limit 1");
#	push @counters,$virtDiskWriteQuery->{'counterid'} if $virtDiskWriteQuery->{'counterid'};

#	my $diskBytesIOQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and vmwareperf_counterinfo.groupinfo='disk'
#														and vmwareperf_counterinfo.statstype='rate'
#														and vmwareperf_counterinfo.unitinfo='kiloBytesPerSecond'
#														and vmwareperf_counterinfo.rolluptype='average'
#														limit 1");
#	push @counters,$diskBytesIOQuery->{'counterid'} if $diskBytesIOQuery->{'counterid'};

	################################################	UCEL Counters	##################################################

	#cpu ready time for check 56
	my $cpuReadyQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and vmwareperf_counterinfo.rolluptype='summation'
													and vmwareperf_counterinfo.category='ready'
													and vmwareperf_counterinfo.unitinfo='millisecond'
													limit 1");
	push @counters,$cpuReadyQuery->{'counterid'} if $cpuReadyQuery->{'counterid'};

	#hypervisor memory oversubscrption for check 85
	my $memOverQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and vmwareperf_counterinfo.statstype='rate'
													and vmwareperf_counterinfo.groupinfo='mem'
													and (vmwareperf_counterinfo.category regexp 'swapin')
													and vmwareperf_counterinfo.label not regexp 'cache'
													limit 1");
	push @counters,$memOverQuery->{'counterid'} if $memOverQuery->{'counterid'};

	my $memOverQuery2 = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and vmwareperf_counterinfo.statstype='rate'
													and vmwareperf_counterinfo.groupinfo='mem'
													and (vmwareperf_counterinfo.category regexp 'swapout')
													and vmwareperf_counterinfo.label not regexp 'cache'
													limit 1");
	push @counters,$memOverQuery2->{'counterid'} if $memOverQuery2->{'counterid'};

	#guest cpu wait time for check 86
	my $cpuWaitQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and vmwareperf_counterinfo.groupinfo='cpu'
													and vmwareperf_counterinfo.statstype='delta'
													and vmwareperf_counterinfo.unitinfo='millisecond'
													and vmwareperf_counterinfo.label REGEXP 'swap'
													and vmwareperf_counterinfo.label REGEXP 'wait'
													limit 1");
	push @counters,$cpuWaitQuery->{'counterid'} if $cpuWaitQuery->{'counterid'};

	#hypervisor disk aborts for check 87
#	my $diskAbortsQuery  = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#														where deviceid in ($vcenterid,$smallDevid)
#														and groupinfo='disk'
#														and statstype='delta'
#														and unitinfo='number'
#														and category REGEXP 'command'
#														and category REGEXP 'aborted'
#														limit 1");
#	push @counters,$diskAbortsQuery->{'counterid'} if $diskAbortsQuery->{'counterid'};

	#vswitch input packet loss for check 88
	my $inputLossQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and groupinfo='net'
													and statstype='delta'
													and unitinfo='number'
													and category REGEXP 'drop'
													and category REGEXP 'rx'
													limit 1");
	push @counters,$inputLossQuery->{'counterid'} if $inputLossQuery->{'counterid'};

	#vswitch output packet loss for check 88
	my $outputLossQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
													where deviceid in ($vcenterid,$smallDevid)
													and groupinfo='net'
													and statstype='delta'
													and unitinfo='number'
													and category REGEXP 'drop'
													and category REGEXP 'tx'
													limit 1");
	push @counters,$outputLossQuery->{'counterid'} if $outputLossQuery->{'counterid'};

	#I/O latency for problem 90
#	my $ioLatencyQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#													where deviceid in ($vcenterid,$smallDevid)
#													and groupinfo='disk'
#													and statstype='absolute'
#													and unitinfo='millisecond'
#													and rolluptype='average'
#													and category REGEXP 'device'
#													and (category REGEXP 'read' OR category REGEXP 'write')
#													limit 1");
#	push @counters,$ioLatencyQuery->{'counterid'} if $ioLatencyQuery->{'counterid'};

	#cpu utilization for checks 93 & 89
	my $hostCPUQuery=$mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
										where deviceid in ($vcenterid,$smallDevid)
										and vmwareperf_counterinfo.groupinfo='cpu'
										and vmwareperf_counterinfo.statstype='rate'
										and vmwareperf_counterinfo.unitinfo='percent'
										and vmwareperf_counterinfo.rolluptype='average'
										and vmwareperf_counterinfo.label REGEXP 'usage'
										and vmwareperf_counterinfo.category REGEXP 'usage'
										limit 1");
	push @counters,$hostCPUQuery->{'counterid'} if $hostCPUQuery->{'counterid'};

	#virtual disk latency for check 95
#	my $diskLatencyQuery=$mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#										where deviceid in ($vcenterid,$smallDevid)
#										and vmwareperf_counterinfo.groupinfo='virtualdisk'
#										and vmwareperf_counterinfo.statstype='absolute'
#										and vmwareperf_counterinfo.unitinfo='millisecond'
#										and vmwareperf_counterinfo.rolluptype='average'
#										and (vmwareperf_counterinfo.label REGEXP 'read latency' or vmwareperf_counterinfo.label REGEXP 'write latency')
#										and (vmwareperf_counterinfo.category REGEXP 'totalreadlatency' or vmwareperf_counterinfo.category REGEXP 'totalwritelatency')
#										limit 1");
#	push @counters,$diskLatencyQuery->{'counterid'} if $diskLatencyQuery->{'counterid'};

	#command latency for check 96
#	my $comLatencyQuery=$mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
#										where deviceid in ($vcenterid,$smallDevid)
#										and vmwareperf_counterinfo.groupinfo='disk'
#										and vmwareperf_counterinfo.statstype='absolute'
#										and vmwareperf_counterinfo.unitinfo='millisecond'
#										and vmwareperf_counterinfo.rolluptype='average'
#										and vmwareperf_counterinfo.label REGEXP 'queue command latency'
#										and vmwareperf_counterinfo.category REGEXP 'queuelatency'
#										limit 1");
#	push @counters,$comLatencyQuery->{'counterid'} if $comLatencyQuery->{'counterid'};

	#CKit - active memory compression for Check108
	my $memCompressionQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
											where deviceid in ($vcenterid,$smallDevid)
											and vmwareperf_counterinfo.groupinfo='mem'
											and vmwareperf_counterinfo.rolluptype = 'average'
											and vmwareperf_counterinfo.statstype='rate'
											and vmwareperf_counterinfo.unitinfo='kilobytespersecond'
											and vmwareperf_counterinfo.label REGEXP 'compression rate'
											and vmwareperf_counterinfo.category REGEXP 'compressionrate'
											limit 1");
	push @counters,$memCompressionQuery->{'counterid'} if $memCompressionQuery->{'counterid'};

	#CKit - active memory decompression for Check108
	my $memDecompressionQuery = $mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
											where deviceid in ($vcenterid,$smallDevid)
											and vmwareperf_counterinfo.groupinfo='mem'
											and vmwareperf_counterinfo.rolluptype = 'average'
											and vmwareperf_counterinfo.statstype='rate'
											and vmwareperf_counterinfo.unitinfo='kilobytespersecond'
											and vmwareperf_counterinfo.label REGEXP 'decompression rate'
											and vmwareperf_counterinfo.category REGEXP 'decompressionrate'
											limit 1");
	push @counters,$memDecompressionQuery->{'counterid'} if $memDecompressionQuery->{'counterid'};

	# memory percentage by request
	# NOTE: this metric was previously identified by the lable 'Usage',
	# however on many VMware deployments this metric bears the label
	# "Host consumed %". As a result, the label filter has been removed,
	# but we must be careful that the remaining criteria properly identifies
	# the single counter. This relates to agg-side counterid 23.
	my $memPercentQuery = $mysql->selectrow_hashref("
		SELECT counterid
		FROM vmwareperf_counterinfo
		WHERE deviceid IN ($vcenterid,$smallDevid)
		AND vmwareperf_counterinfo.groupinfo = 'mem'
		AND vmwareperf_counterinfo.statstype = 'absolute'
		AND vmwareperf_counterinfo.unitinfo = 'percent'
		AND vmwareperf_counterinfo.rolluptype = 'none'
		AND vmwareperf_counterinfo.category = 'usage'
		LIMIT 1
	");
	push @counters,$memPercentQuery->{'counterid'} if $memPercentQuery->{'counterid'};

	#actively used mem by request
	my $memActiveUsedQuery=$mysql->selectrow_hashref("select counterid from vmwareperf_counterinfo
										where deviceid in ($vcenterid,$smallDevid)
										and vmwareperf_counterinfo.groupinfo='mem'
										and vmwareperf_counterinfo.statstype='absolute'
										and vmwareperf_counterinfo.unitinfo='kiloBytes'
										and vmwareperf_counterinfo.rolluptype='none'
										and vmwareperf_counterinfo.label = 'Active'
										and vmwareperf_counterinfo.category = 'active'
										limit 1");
	push @counters,$memActiveUsedQuery->{'counterid'} if $memActiveUsedQuery->{'counterid'};

	my $alldiskcounter = $mysql->selectall_hashref("select counterid from vmwareperf_counterinfo where groupinfo='disk' group by summary",'counterid');
	push @counters,$_ foreach (keys %$alldiskcounter);
	my $allvirtualdiskcounter = $mysql->selectall_hashref("select counterid from vmwareperf_counterinfo where groupinfo='virtualdisk' group by summary",'counterid');
	push @counters,$_ foreach (keys %$allvirtualdiskcounter);

	return \@counters;

}

sub buildGuestList {
	my $mysql = shift;
	my $vcenterid = shift;
	my $smallDevid = shift;
	my $limit1 = shift;
	my $limit2 = shift;
	my $return;
	#first we iterate each vcenter and build a hash of arrays of guests per host per vcenter
	my $vmHash;

	my $maxNumGuests;
	my $totalGuestCount;
	my $hosts;

	if (riscUtility::checkLicenseEnforcement()) {
		$maxNumGuests = $mysql->selectrow_hashref("
			select count(*) as num
			from vmware_guestsummaryconfig vm
			inner join riscvmwarematrix mat using(uuid)
			inner join licensed on licensed.deviceid = mat.deviceid and licensed.expires > unix_timestamp(now())
			where vm.deviceid = $vcenterid
			group by vm.deviceid,esxhost
			order by count(*) desc
		")->{'num'};

		$totalGuestCount = $mysql->selectrow_hashref("
			select count(*) as num
			from vmware_guestsummaryconfig vm
			inner join riscvmwarematrix mat using(uuid)
			inner join licensed on licensed.deviceid = mat.deviceid and licensed.expires > unix_timestamp(now())
			where vm.deviceid = $vcenterid
		")->{'num'};

		$hosts = $mysql->prepare("
			select distinct vm.deviceid,esxhost
			from vmware_guestsummaryconfig vm
			inner join riscvmwarematrix mat using(uuid)
			inner join licensed on licensed.deviceid = mat.deviceid and licensed.expires > unix_timestamp(now())
			where vm.deviceid = $vcenterid
		");
		$hosts->execute();

		while (my $line = $hosts->fetchrow_hashref()) {
			my $devid = $line->{'deviceid'};
			my $esxhost = $line->{'esxhost'};
			$vmHash->{$devid}->{$esxhost} = $mysql->selectall_arrayref("
				select distinct name
				from vmware_guestsummaryconfig vm
				inner join riscvmwarematrix mat using (uuid)
				inner join licensed on licensed.deviceid = mat.deviceid and licensed.expires > unix_timestamp(now())
				where vm.deviceid = $devid
				and esxhost = '$esxhost'
			");
		}
	} else {
		$maxNumGuests = $mysql->selectrow_hashref("
			select count(*) as num
			from vmware_guestsummaryconfig
			where deviceid in ($vcenterid,$smallDevid)
			group by deviceid,esxhost
			order by count(*) desc
		")->{'num'};

		$totalGuestCount = $mysql->selectrow_hashref("
			select count(*) as num
			from vmware_guestsummaryconfig
			where deviceid in ($vcenterid,$smallDevid)
		")->{'num'};

		$hosts = $mysql->prepare("
			select deviceid,esxhost
			from vmware_guestsummaryconfig
			where deviceid in ($vcenterid,$smallDevid)
			group by deviceid,esxhost
		");
		$hosts->execute();

		while (my $line = $hosts->fetchrow_hashref()) {
			my $devid = $line->{'deviceid'};
			my $esxhost = $line->{'esxhost'};
			$vmHash->{$devid}->{$esxhost} = $mysql->selectall_arrayref("
				select name
				from vmware_guestsummaryconfig
				where deviceid = $devid
				and esxhost = '$esxhost'
			");
		}
	}

	#next build an array of guests for each vcenter collected by esxhost
	my $arrayHash;
	my $i = 0;
	foreach my $vcenter (keys %{$vmHash}) {
		my @tmp_array;
		for (my $i = 0; $i < $maxNumGuests; $i++) {
			foreach my $esx (keys %{$vmHash->{$vcenter}}) {
				next unless $vmHash->{$vcenter}->{$esx}[$i][0];
				push (@tmp_array,$vmHash->{$vcenter}->{$esx}[$i][0]);
			}
			$arrayHash->{$vcenter} = \@tmp_array;
		}
	}

	my @finalArray;
	for (my $i = 0; $i < $totalGuestCount; $i++) {
		foreach my $vcenter (keys %{$arrayHash}) {
			next unless $arrayHash->{$vcenter}[$i];
			push (@finalArray,$arrayHash->{$vcenter}[$i])
		}
	}

	$limit2 = $#finalArray - $limit1 if $#finalArray - $limit1 < $limit2;

	foreach my $name (@finalArray[$limit1..($limit1 + $limit2)]) {
		$name =~ s/\'/\\\'/g;	## compensate for single-quotes in guest names
		$return .= "\'".$name."\',";
	}

	chop $return;
	return $return;
}

sub buildDevCounterHash {
	my $mysql = shift;
	my $counterString = shift;
	my $return;

	my $counterQuery = $mysql->prepare("select * from vmwareperf_counterinfo where counterid in ($counterString)");
	eval {
		$counterQuery->execute();
		while (my $line = $counterQuery->fetchrow_hashref()) {
			$return->{$line->{'deviceid'}}->{$line->{'entityname'}}->{$line->{'counterid'}}++;
		}
	};

	return $return;
}

sub logNewPerf{
	# this will do a 5-minute rollup of min, max, avg, as well as recording an instantaneous value, for the counter time series that is passed.
	my $mysql = shift;
	my $devid = shift;
	my $timeInfo = shift;
	my $value = shift; # this is the hash with value(csv) and id(hash)

	unless ($devid) {
		$logger->error('no deviceid, skipping');
		next;
	}

	my @ts = split(/,/,$timeInfo);
	my @vals = split(/,/,$value->{'value'});

	my $count = 0;
	my $cumtime = 0;
	my $sum = 0;
	my $max = -1;
	my $min = 999999999999999;
	my $abstime;

	my $insstr = "insert into vmware_perf_5min (deviceid, instancename, counter, avg, max, min, instantaneous, scantime) values ";

	while (defined(my $val = shift(@vals))) {
		$count++;
		$cumtime+=shift(@ts);
		$abstime = shift(@ts);
		$sum+=$val;
		$max = $val if $val>$max;
		$min = $val if $val<$min;

		if ($cumtime>=300){
			my $avg = $sum/$count;
			$abstime =~ s/(.*)T(.*)Z/$1\ $2/;
			$insstr.= "($devid,'$value->{'id'}->{'instance'}',$value->{'id'}->{'counterId'},$avg,$max,$min,$val,unix_timestamp('$abstime')),";

			# reset the 5-minute data holders:
			$count = 0;
			$cumtime = 0;
			$sum = 0;
			$max = -1;
			$min = 999999999999999;

			# then deal with the string becoming too big, as usual:

			if (length($insstr)>10000000){
				chop($insstr);
				#print "$insstr\n";
				eval {
					$mysql->do($insstr);
				}; if ($@) {
					$logger->error(sprintf('failed insert: %s { %s }', $@, $insstr));
				}
				$insstr = "insert into vmware_perf_5min (deviceid, instancename, counter, avg, max, min, instantaneous, scantime) values ";
			}

		}

	}

	unless ($insstr eq "insert into vmware_perf_5min (deviceid, instancename, counter, avg, max, min, instantaneous, scantime) values "){
		chop($insstr);
		#print "$insstr\n";
		eval {
			$mysql->do($insstr);
		}; if ($@) {
			$logger->error(sprintf('failed insert: %s { %s }', $@, $insstr));
		}
	}

}
