#!/usr/bin/perl
use strict;
use Data::Dumper;
use SOAP::Lite;
use RISC::riscUtility;
use RISC::riscWebservice;
$|++;

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;

my $sanitary_output = 'unknown';

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

#database connect
my $mysql  = riscUtility::getDBH('RISC_Discovery', 1);
my $mysql2 = riscUtility::getDBH('risc_discovery', 1);

#Is this the first time running...
my $objects = "select object from assessmentstatus";
my $sth2    = $mysql->prepare($objects);
$sth2->execute();
my $numberobjects = $sth2->rows();

my $ctx = riscUtility::getApplianceAuth($mysql2);
die("failed to obtain context") if (!defined($ctx));
dbg('got context: '.Dumper($ctx));

#initialize table
dbg('initializing assessmentstatus table');
if ($numberobjects == 0) {
	#num devices
	my $devices = "insert into assessmentstatus set object='numdevices', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth3    = $mysql->prepare($devices);
	$sth3->execute();

	#subnets scanned
	my $subnets = "insert into assessmentstatus set object='subnetsscanned', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth4    = $mysql->prepare($subnets);
	$sth4->execute();

	#number SNMP accessible
	my $numsnmp = "insert into assessmentstatus set object='numsnmp', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth5    = $mysql->prepare($numsnmp);
	$sth5->execute();

	#Discos running
	my $discos = "insert into assessmentstatus set object='discos', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth6   = $mysql->prepare($discos);
	$sth6->execute();

	#num Cisco devices expected
	my $numciscoexpect = "insert into assessmentstatus set object='numciscoexpected', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth7           = $mysql->prepare($numciscoexpect);
	$sth7->execute();

	#win inventory active
	my $wininvactive = "insert into assessmentstatus set object='wininvactive', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth8         = $mysql->prepare($wininvactive);
	$sth8->execute();

	#num net device info
	my $netdeviceinfo = "insert into assessmentstatus set object='netdeviceinfo', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth9          = $mysql->prepare($netdeviceinfo);
	$sth9->execute();

	#num windows devices
	my $numwindevices = "insert into assessmentstatus set object='numwindevices', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth10         = $mysql->prepare($numwindevices);
	$sth10->execute();

	#num windows servers
	my $numwinservers = "insert into assessmentstatus set object='numwinservers', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth11         = $mysql->prepare($numwinservers);
	$sth11->execute();

	#num ccm devices
	my $numccmdevices = "insert into assessmentstatus set object='numccmdevices', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth12         = $mysql->prepare($numccmdevices);
	$sth12->execute();

	#num numplan devices
	my $numnumplan = "insert into assessmentstatus set object='numnumplan', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth13      = $mysql->prepare($numnumplan);
	$sth13->execute();

	#num traffic
	my $numtraffic = "insert into assessmentstatus set object='numtraffic', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth14      = $mysql->prepare($numtraffic);
	$sth14->execute();

	#num device perf
	my $numdevperf = "insert into assessmentstatus set object='numdevperf', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth15      = $mysql->prepare($numdevperf);
	$sth15->execute();

	#num win perf
	my $numwinperf = "insert into assessmentstatus set object='numwinperf', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth16      = $mysql->prepare($numwinperf);
	$sth16->execute();

	#num ccm perf
	my $numccmperf = "insert into assessmentstatus set object='numccmperf', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth17      = $mysql->prepare($numccmperf);
	$sth17->execute();

	#num rttstats
	my $numrttstats = "insert into assessmentstatus set object='numrttstats', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth18       = $mysql->prepare($numrttstats);
	$sth18->execute();

	#num rttstatsfail
	my $numrttstatsfail = "insert into assessmentstatus set object='numrttstatsfail', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth19           = $mysql->prepare($numrttstatsfail);
	$sth19->execute();

	#num devices in perf
	my $numinperf = "insert into assessmentstatus set object='numinperf', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth20     = $mysql->prepare($numinperf);
	$sth20->execute();

	#num for wininventory;
	my $numforwininv = "insert into assessmentstatus set object='numforwininv', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth21        = $mysql->prepare($numforwininv);
	$sth21->execute();

	#num for winevent devices;
	my $numforwinevent = "insert into assessmentstatus set object='numwinevent', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth22          = $mysql->prepare($numforwinevent);
	$sth22->execute();

	#num for vmware hosts
	my $numforvmhosts = "insert into assessmentstatus set object='vmwarehost', currentvalue=0, lastvalue=0, currentscantime=0, lastscantime=0";
	my $sth23         = $mysql->prepare($numforvmhosts);
	$sth23->execute();

	#num for vmware guests
	my $numforvmguests = "insert into assessmentstatus set object='vmwareguest',currentvalue=0,lastvalue=0,currentscantime=0,lastscantime=0";
	my $sth24          = $mysql->prepare($numforvmguests);
	$sth24->execute();

	#num for vmware host performance
	my $numforvmhost_perf = "insert into assessmentstatus set object='vmhostperf',currentvalue=0,lastvalue=0,currentscantime=0,lastscantime=0";
	my $sth25             = $mysql->prepare($numforvmhost_perf);
	$sth25->execute();

	#num for vmware guest performance
	my $numforvmguest_perf = "insert into assessmentstatus set object='vmguestperf',currentvalue=0,lastvalue=0,currentscantime=0,lastscantime=0";
	my $sth26              = $mysql->prepare($numforvmguest_perf);
	$sth26->execute();
}

#--------------UPDATE VALUES----------------
dbg('updating assessmentstatus values');
#Update numdevices
my $numdevices =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from riscdevice), currentscantime=unix_timestamp(now()) where object='numdevices'";
my $update1 = $mysql->prepare($numdevices);
$update1->execute();

#Update subnets scanned
my $numsubnets =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(distinct(iprange)) from discoverystats where status=2), currentscantime=unix_timestamp(now()) where object='subnetsscanned'";
my $update2 = $mysql->prepare($numsubnets);
$update2->execute();

#Update number of SNMP accessible devices
my $numsnmpaccess =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from riscdevice where macaddr regexp ':'), currentscantime=unix_timestamp(now()) where object='numsnmp'";
my $update3 = $mysql->prepare($numsnmpaccess);
$update3->execute();

#Update number of discos running
my $discocount = checkProcess("disco");
my $numdiscos =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=$discocount, currentscantime=unix_timestamp(now()) where object='discos'";
my $update4 = $mysql->prepare($numdiscos);
$update4->execute();

#Update number of Cisco devices expected
my $numciscoexpect =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(SELECT count(*) FROM riscdevice where ((layer2=1 and layer1=0) OR (sysdescription regexp 'cisco' and sysdescription not regexp 'mac manufacturer') or (sysdescription regexp 'sonic' and sysdescription not regexp 'mac manufacturer') or (sysdescription regexp '3com' and sysdescription not regexp 'mac manufacturer') or (sysdescription regexp 'Cabletron' and sysdescription not regexp 'mac manufacturer') or (sysdescription regexp 'Enterasys' and sysdescription not regexp 'mac manufacturer') or (sysdescription regexp 'Force10' and sysdescription not regexp 'mac manufacturer')) AND (deviceid not in (select deviceid from windowsos)) AND (macaddr regexp ':')), currentscantime=unix_timestamp(now()) where object='numciscoexpected'";
my $update5 = $mysql->prepare($numciscoexpect);
$update5->execute();

#Update Net Device Info
my $networkdeviceinfo =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from networkdeviceinfo), currentscantime=unix_timestamp(now()) where object='netdeviceinfo'";
my $update7 = $mysql->prepare($networkdeviceinfo);
$update7->execute();

#Update Windows Devices
my $numberwindowsdevices =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from windowsos), currentscantime=unix_timestamp(now()) where object='numwindevices'";
my $update8 = $mysql->prepare($numberwindowsdevices);
$update8->execute();

#Update Windows Servers
my $numberwindowsservers =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from windowsos where caption regexp 'server'), currentscantime=unix_timestamp(now()) where object='numwinservers'";
my $update9 = $mysql->prepare($numberwindowsservers);
$update9->execute();

#Update Num CCM Devices
my $deviceexist = "select * from information_schema.tables where table_schema = 'RISC_Discovery' and table_name = 'device'";
my $check2      = $mysql->prepare($deviceexist);
$check2->execute();
my $devicetableexist = $check2->rows;
my $numberccmdevices;
if ($devicetableexist == 0) {
	$numberccmdevices =
	  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue='NA', currentscantime=unix_timestamp(now()) where object='numccmdevices'";
} else {
	$numberccmdevices =
	  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from device), currentscantime=unix_timestamp(now()) where object='numccmdevices'";
}
my $update10 = $mysql->prepare($numberccmdevices);
$update10->execute();

#Update Num CCM numplan
my $numplanexist = "select * from information_schema.tables where table_schema = 'RISC_Discovery' and table_name = 'numplan'";
my $check1       = $mysql->prepare($numplanexist);
$check1->execute();
my $numplantableexist = $check1->rows;

my $numberccmnumplan;
if ($numplantableexist == 0) {
	$numberccmnumplan =
	  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue='NA', currentscantime=unix_timestamp(now()) where object='numnumplan'";
} else {
	$numberccmnumplan =
	  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from numplan), currentscantime=unix_timestamp(now()) where object='numnumplan'";
}

my $update11 = $mysql->prepare($numberccmnumplan);
$update11->execute();

#Update number traffic
my $numbertraffic =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(deviceid) from traffic) + (select count(deviceid) from traffic_raw) + (select count(deviceid) from traffic_inst), currentscantime=unix_timestamp(now()) where object='numtraffic'";
my $update12 = $mysql->prepare($numbertraffic);
$update12->execute();

# Update number device perf
my $numberdeviceperf =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(deviceid) from deviceperformance), currentscantime=unix_timestamp(now()) where object='numdevperf'";
my $update13 = $mysql->prepare($numberdeviceperf);
$update13->execute();

# Update number win perf
my $numberwinperf =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(deviceid) from winperfmem), currentscantime=unix_timestamp(now()) where object='numwinperf'";
my $update14 = $mysql->prepare($numberwinperf);
$update14->execute();

# Update number ccm perf
my $numberccmperf =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(ipaddress) from ccm), currentscantime=unix_timestamp(now()) where object='numccmperf'";
my $update15 = $mysql->prepare($numberccmperf);
$update15->execute();

# Update number rtt perf
my $numberrttperf =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from rttstats), currentscantime=unix_timestamp(now()) where object='numrttstats'";
my $update16 = $mysql->prepare($numberrttperf);
$update16->execute();

# Update number rtt perf fails
my $numberrttperffail =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from rttstats where opersense not regexp 'ok'), currentscantime=unix_timestamp(now()) where object='numrttstatsfail'";
my $update17 = $mysql->prepare($numberrttperffail);
$update17->execute();

# Update number devices in perf
my $numberdevinperf =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(distinct(deviceid)) from deviceperformance where scantime>unix_timestamp(now())-3600), currentscantime=unix_timestamp(now()) where object='numinperf'";
my $update18 = $mysql->prepare($numberdevinperf);
$update18->execute();

# Update number devices needing wininvetory
my $numberofwininventory =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(*) from `RISC_Discovery`.`credentials` where technology='windows'), currentscantime=unix_timestamp(now()) where object='numforwininv'";
my $update19 = $mysql->prepare($numberofwininventory);
$update19->execute();

# Update number devices winevent complete for
my $numberofwinevent =
  "update assessmentstatus set lastvalue=currentvalue, lastscantime=currentscantime, currentvalue=(select count(distinct(deviceid)) from `RISC_Discovery`.`windowseventlog`), currentscantime=unix_timestamp(now()) where object='numwinevent'";
my $update20 = $mysql->prepare($numberofwinevent);
$update20->execute();

# Update number of devices for vmware inventory - host
my $updateVMHost =
  "update assessmentstatus set lastvalue=currentvalue,lastscantime=currentscantime,currentvalue=(select count(distinct(name)) from vmware_hostsystem),currentscantime=unix_timestamp(now()) where object='vmwarehost'";
my $update21 = $mysql->prepare($updateVMHost);
$update21->execute();

# Update number of devices for vmware inventory - guest
my $updateVMGuest =
  "update assessmentstatus set lastvalue=currentvalue,lastscantime=currentscantime,currentvalue=(select count(distinct(name)) from vmware_guestsummaryconfig),currentscantime=unix_timestamp(now()) where object='vmwareguest'";
my $update22 = $mysql->prepare($updateVMGuest);
$update22->execute();

# Update number of records in vmware host performance
my $updateVMHostPerf =
  "update assessmentstatus set lastvalue=currentvalue,lastscantime=currentscantime,currentvalue=(select count(*) from vmware_hostperformance),currentscantime=unix_timestamp(now()) where object='vmhostperf'";
my $update23 = $mysql->prepare($updateVMHostPerf);
$update23->execute();

# Update number of records in vmware guest performance
my $updateVMGuestPerf =
  "update assessmentstatus set lastvalue=currentvalue,lastscantime=currentscantime,currentvalue=(select count(*) from vmware_guestperformance),currentscantime=unix_timestamp(now()) where object='vmguestperf'";
my $update24 = $mysql->prepare($updateVMGuestPerf);
$update24->execute();


my $statsQuery = $mysql->prepare("select * from assessmentstatus");
$statsQuery->execute();

dbg('building SOAP package');
my @stats;
while (my $line = $statsQuery->fetchrow_hashref()) {
	my $soapmacaddr         = SOAP::Data->name('macaddr')->value($ctx->{'mac'})->type("xsd:string");
	my $soapobject          = SOAP::Data->name('object')->value($line->{'object'})->type("xsd:string");
	my $soapcurrentvalue    = SOAP::Data->name('currentvalue')->value($line->{'currentvalue'})->type("xsd:string");
	my $soaplastvalue       = SOAP::Data->name('lastvalue')->value($line->{'lastvalue'})->type("xsd:string");
	my $soapcurrentscantime = SOAP::Data->name('currentscantime')->value($line->{'currentscantime'});
	my $soaplastscantime    = SOAP::Data->name('lastscantime')->value($line->{'lastscantime'});
	my $collection          = SOAP::Data->name('StatusUpdateInput')->value($soapmacaddr, $soapobject, $soapcurrentvalue, $soaplastvalue, $soapcurrentscantime, $soaplastscantime);
	my $finalLine           = SOAP::Data->name('StatusUpdateInput')->value(\$collection)->type("xsd:StatusUpdateInput");
	push(@stats, $finalLine);
}

dbg('calling API');
my $res = riscWebservice::statusUpdateAll($ctx->{'assesscode'}, @stats);
dbg('result: '.Dumper($res));
$sanitary_output = $res->{'returnStatus'} if (($res) and ($res->{'returnStatus'}));

printf("||&||%s||&||\n",$sanitary_output);
dbg('complete');
exit(0);

sub checkProcess {
	my $process  = shift;
	my @proclist = `pgrep -f $process`;
	return scalar @proclist;
}

sub dbg {
	my ($msg) = @_;
	return unless ($debugging);
	chomp($msg);
	print STDERR "$0::DEBUG: $msg\n";
}
