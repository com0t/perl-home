#!/usr/bin/perl
# The simpleclient.pl script outputs a list of all the entities of the specified managed-entity
# type (ClusterComputeResource, ComputeResource, Datacenter, Datastore, Folder, HostSystem,
# Network, ResourcePool, VirtualMachine, or VirtualService) found on the target vCenter Server or
# ESX system. Script users must provide logon credentials and the managed entity type. The script
# leverages the Util::trace() subroutine to display the found entities of the specified type.

use strict;

use VMware::VIRuntime;
use Socket;
use RISC::riscUtility;
use RISC::Collect::Logger;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
$|++;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my $logger = RISC::Collect::Logger->new('risc_vmware_guestinventory');
$logger->info("vmware guest inventory begin");

my $assessid	= shift;
my $credid	= shift;

my %opts = (
	entity => {
		type		=> "=s",
		variable	=> "VI_ENTITY",
		help		=> "ManagedEntity type: HostSystem, etc",
		required	=> 1,
	},
);
Opts::add_options(%opts);

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} =1;

## remove proxy configuration if exists
riscUtility::proxy_disable();

## CLOUD-6625 avoid renaming the process to "Hiding the command line arguments",
## which Opts::parse() does automatically.
my $original_name = $0;
Opts::parse();
$0 = $original_name;

Opts::validate();

my $deviceInteger;
my $generatedIDQuery = $mysql->selectrow_hashref("select * from riscdevice where deviceid>=4294917295 and deviceid<4294967296 order by deviceid desc limit 1");
if (defined $generatedIDQuery->{'deviceid'}) {
	$deviceInteger = $generatedIDQuery->{'deviceid'}+1;
} else {
	$deviceInteger = 4294917295;
}
$logger->debug("using deviceInteger: '$deviceInteger'");

my $servername = Opts::get_option('server');
$logger->debug("server is '$servername'");

my $deviceid = getDeviceID($servername);
$logger->debug("got deviceid '$deviceid'");

my $inserthost = $mysql->prepare_cached("INSERT into vmware_guestsummaryconfig (deviceid,scantime,annotation,cpureservation,guestfullname,guestid,memoryreservation,memorysizemb,name,numcpu,numethernetcards,numvirtualdisks,uuid,vmpathname,ipaddress,toolsstatus,overallstatus,boottime,maxcpuusage,maxmemoryusage,memoryoverhead,nummksconnections,powerstate,suspendinterval,suspendtime,esxhost) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $guest_infoInsert = $mysql->prepare("insert into vmware_guest_info (deviceid,name,uuid,cpulimit,diskcapacitymb) values (?,?,?,?,?)");

my $scantime = time();

Util::connect();

# Obtain all inventory objects of the specified type
my $entity_type = Opts::get_option('entity');
my $entity_views = Vim::find_entity_views(view_type => $entity_type, properties => ["summary.config","summary.vm","guest.ipAddress","runtime","guest","config"]);
# Get a list of explicitly excluded IPs
my $ips_excluded = riscUtility::get_ip_exclusion_list($mysql);
# Process the findings and output to the console
foreach my $entity_view (@$entity_views) {
	eval {
		my $e_name = $entity_view->{'summary.config'}->{'name'};
		my $e_id = $entity_view->{'summary.vm'};
		$logger->debug("====> processing guest: name='$e_name', id='$e_id'");

		addVMwareMatrix($e_id,$e_name,$scantime,$deviceid);

		$logger->debug("$e_name: gathering data");
		my $annotation = $entity_view->{'summary.config'}->{'annotation'};
		my $cpureservation= $entity_view->{'summary.config'}->{'cpuReservation'};
		my $guestfullname = $entity_view->{'summary.config'}->{'guestFullName'};
		my $guestid = $entity_view->{'summary.config'}->{'guestId'};
		my $memreservation = $entity_view->{'summary.config'}->{'memoryReservation'};
		my $memsizemb = $entity_view->{'summary.config'}->{'memorySizeMB'};
		my $name = $entity_view->{'summary.config'}->{'name'};
		my $numcpu = $entity_view->{'summary.config'}->{'numCpu'};
		my $numethernetcards = $entity_view->{'summary.config'}->numEthernetCards;
		my $numvirtualdisks = $entity_view->{'summary.config'}->{'numVirtualDisks'};
		my $uuid = $entity_view->{'summary.config'}->{'uuid'};
		$logger->debug("$e_name: uuid is '$uuid'");
		my $vmpathname = $entity_view->{'summary.config'}->{'vmPathName'};
		my $toolsstatus = $entity_view->{'guest'}->{'toolsStatus'}->{'val'};
		#my $overallstatus = $entity_view->summary->overallStatus->val;
		my $overallstatus; ## since the above is commented for some reason, at least define the variable
		my $boottime=$entity_view->runtime->bootTime;
		my $maxcpu = $entity_view->runtime->maxCpuUsage;
		my $maxmem = $entity_view->runtime->maxMemoryUsage;
		my $memoverhead = $entity_view->runtime->memoryOverhead;
		my $nummksconnections = $entity_view->runtime->numMksConnections;
		my $powerstate = $entity_view->runtime->powerState->val;
		my $suspendint = $entity_view->runtime->suspendInterval;
		my $suspendtime = $entity_view->runtime->suspendTime;
		my $hostview = $entity_view->runtime->host;
		my $cpulimit = -1;
		eval {
			$cpulimit = $entity_view->{'config'}->{'cpuAllocation'}->limit;
		};
		my $devref=$entity_view->{'config'}->{'hardware'}->{'device'};
		my $disk;
		foreach my $dev (@$devref) {
			if (ref($dev) eq 'VirtualDisk') {
				$disk += $dev->capacityInKB;
			}
		}
		if (defined($disk)) {
			$disk = int($disk/1000);
		} else {
			$disk = 0;
		}

		my $host = getESXName($hostview,$deviceid);
		$logger->debug("$e_name: got host '$host'");

		eval {
			$logger->debug("getNicInfo()");
			getNicInfo($mysql,$deviceid,$uuid,$scantime,$entity_view);
		};

		my $identity_ip = $entity_view->{'guest.ipAddress'};
		if ($ips_excluded->{$identity_ip}) {
			$logger->info("skipping ip $identity_ip due to its presence in risc_discovery.ip_exclusion_list");
			next;
		}

		#handle deviceid-ing including adding to riscdevice and riscvmwarematrix
		#	also return the chosen ip address to add to the vmware_guestsummaryconfig table
		$logger->debug("$e_name: generating deviceid");
		my $identity = generateDeviceid($mysql,$entity_view,$uuid,$name);
		$logger->debug(sprintf("%s: generateDeviceid() returned ip: '%s'",$e_name,$identity->{'ip'}));

		$logger->debug("$e_name: inserting to vmware_guestsummaryconfig");
		$inserthost->execute(
			$deviceid,
			$scantime,
			$annotation,
			$cpureservation,
			$guestfullname,
			$guestid,
			$memreservation,
			$memsizemb,
			$name,
			$numcpu,
			$numethernetcards,
			$numvirtualdisks,
			$uuid,
			$vmpathname,
			$identity->{'ip'},
			$toolsstatus,
			$overallstatus,
			$boottime,
			$maxcpu,
			$maxmem,
			$memoverhead,
			$nummksconnections,
			$powerstate,
			$suspendint,
			$suspendtime,
			$host
		);
		$logger->debug("$e_name: inserting to vmware_guest_info");
		$guest_infoInsert->execute($deviceid,$name,$uuid,$cpulimit,$disk);
	}; if ($@) {
		$logger->error("failure in major guest block: $@");
	}
}

# Disconnect from the server
$logger->debug("disconnecting");
Util::disconnect();

$logger->info("vmware guest inventory complete");
exit(0);

sub getESXName {
	my $hv = shift;
	my $deviceid = shift;
	my $id = $hv->{'value'};
	my $type = $hv->{'type'};
	my $getesxhost = $mysql->prepare_cached("select name from vmware_hostmatrix where deviceid=? and id=? and type=? limit 1");
	$getesxhost->execute($deviceid,$id,$type);
	my $host = $getesxhost->fetchrow_hashref();
	if (defined $host->{'name'}) {
		$getesxhost->finish();
		return $host->{'name'};
	} else {
		return $id;
	}
}

sub addVMwareMatrix {
	my $id = shift;
	my $name = shift;
	my $scantime = shift;
	my $deviceid=shift;
	my $inserthostmatrix = $mysql->prepare_cached("INSERT into vmware_hostmatrix (deviceid,scantime,name,id,type) values (?,?,?,?,?)");
	my $removehostmatrix = $mysql->prepare_cached("delete from vmware_hostmatrix where id=? and name=? and type=?");
	my $hostid = $id->{'value'};
	my $hosttype = $id->{'type'};
	$logger->debug("removing guest from vmware_hostmatrix: id='$hostid', name='$name', type='$hosttype'");
	$removehostmatrix->execute($hostid,$name,$hosttype);
	$logger->debug("inserting into vmware_hostmatrix: deviceid='$deviceid', name='$name', id='$hostid', type='$hosttype'");
	$inserthostmatrix->execute($deviceid,$scantime,$name,$hostid,$hosttype);
}

sub generateDeviceid {
	my $mysql = shift;
	my $entity_view = shift;
	my $uuid = shift;
	my $name = shift;

	my $married = 0;	#this indicates whether or not we have married the vm to a directly connected entity

	my $ipaddr = $entity_view->{'guest.ipAddress'};
	$logger->debug("$name: ipaddr: '$ipaddr'");

	## we want to try and marry this device back to a physical counterpart
	## first, the queries here will attempt to match the device by MAC
	## we set the physical (windowsosid) id if we find it here
	## then, addVMwareDevice() determines the vm-deviceid and adds it to riscdevice
	## doing so, it attempts to match a physical device via riscdevice, so if it does, we return it as the physical id
	## so, the physical windowsosid is resolved as, in descending priority:
	##	first, result of MAC match
	##	second, the result of the IP match in addVMwareDevice()
	##	last, the vm-deviceid concatted to the assessmentid

	$logger->debug("$name: trying windows mac match");
	my $macToIPQuery = $mysql->selectrow_hashref("SELECT windowsnetwork.deviceid,riscdevice.ipaddress,mac
		FROM vmware_hostvswitchport_vm
		left join windowsnetwork on mac = macaddr
		left join riscdevice on windowsnetwork.deviceid = riscdevice.deviceid
		where vmuuid = \'$uuid\'
		limit 1");
	my $ipaddr2 = $macToIPQuery->{'ipaddress'};
	my $mac = $macToIPQuery->{'mac'};
	my $windowsosid = $macToIPQuery->{'deviceid'};

	$married = 1 if defined($ipaddr2);

	$logger->debug("$name: following windows mac block: married='$married', ipaddr2='$ipaddr2', mac='$mac', windowsosid='$windowsosid'");

	unless (defined($ipaddr2)) {
		$logger->debug("$name: trying gensrv mac match");
		my $gensrvMacQuery = $mysql->selectrow_hashref("
			select riscdevice.deviceid,ipaddress,mac
			from vmware_hostvswitchport_vm
			left join interfaces using(mac)
			left join riscdevice on interfaces.deviceid = riscdevice.deviceid
			where vmuuid = \'$uuid\'
			limit 1
			");
		if ($gensrvMacQuery) {
			$ipaddr2 = $gensrvMacQuery->{'ipaddress'};
			$mac = $gensrvMacQuery->{'mac'};
			$windowsosid = $gensrvMacQuery->{'deviceid'};
			$married = 1 if ($ipaddr2);
		}
	}

	$logger->debug("$name: following gensrv mac block: married='$married', ipaddr2='$ipaddr2', mac='$mac', windowsosid='$windowsosid'");

	unless (defined($ipaddr2)) {
		$ipaddr2 = $ipaddr;
		$ipaddr2 = 'unknown' unless defined($ipaddr2);
	}
	$mac = 'unknown' unless $mac;

	$logger->debug("$name: calling addVMwareDevice(): name='$name', ipaddr2='$ipaddr2', mac='$mac', married='$married', windowsosid='$windowsosid'");
	my ($devID,$_windowsosid) = addVMwareDevice($name,$ipaddr2,$mac,$married,$windowsosid);
	$logger->debug("$name: addVMwareDevice() returned: devID='$devID', _windowsosid='$_windowsosid'");

	my $objectid = $entity_view->{'summary.vm'}->value;
	$logger->debug("$name: objectid: '$objectid'");

	## we first attempted a MAC-based match to the physical counterpart above
	## if that failed, then addVMwareDevice() may have found one by IP
	## if neither succeeded, then build by concating the assessid to the vm deviceid
	if (!defined($windowsosid)) {
		if (!defined($_windowsosid) or ($_windowsosid == $devID)) {
			$windowsosid = join('',$assessid,$devID);
		} else {
			$windowsosid = $_windowsosid;
		}
	}

	$logger->info("$name: deviceid $devID windowsosid $windowsosid vcenterid $deviceid");
	eval {
		$logger->debug("calling riscUtility::riscvmwarematrix_insert(): devID='$devID', deviceid='$deviceid', windowsosid='$windowsosid', uuid='$uuid', objectid='$objectid'");
		riscUtility::riscvmwarematrix_insert($mysql,$devID,$deviceid,$windowsosid,$uuid,'guest',$objectid);
	}; if ($@) {
		$logger->debug("failed riscUtility::riscvmwarematrix_insert(): $@");
		my $riscVMwareMatrixInsert = $mysql->prepare_cached("insert into riscvmwarematrix (deviceid,vcenterid,uuid,type,windowsosid,objectid) values (?,?,?,'guest',?,?)");
		$riscVMwareMatrixInsert->execute($devID,$deviceid,$uuid,$windowsosid,$objectid);
	}

	## return all of our identity context to the caller
	return {
		ip			=> $ipaddr2,
		vm_deviceid		=> $devID,
		physical_deviceid	=> $windowsosid,
		vcenter_deviceid	=> $deviceid,
		mo_ref			=> $entity_view->{'summary.vm'}
	};
}

sub addVMwareDevice {
	my $hostName = shift;
	my $ipaddr = shift;
	my $mac = shift;
	my $married = shift;
	my $physid = shift;

	my $vmid;

	unless ($married) {
		$logger->debug("$hostName: not married");
		$logger->debug("$hostName: trying windows ip match");
		#first determine if we are a windows device, if so, ensure that the ip marries up
		my $winQuery = $mysql->prepare("
			select deviceid,windowsnetwork.ipaddress as iplist,riscdevice.ipaddress
			from windowsnetwork
			inner join riscdevice using(deviceid)
			where windowsnetwork.ipaddress like \'%$ipaddr%\'
				and if(\'$mac\' = 'unknown',1,windowsnetwork.macaddr = \'$mac\')
			group by deviceid
			");
		$winQuery->execute();
		my $isawin = 0;
		if ($winQuery->rows() > 0) {
			$logger->debug("$hostName: matched windows");
			while (my $line = $winQuery->fetchrow_hashref()) {
				$line->{'iplist'} =~ /\((.+)\)/;
				my $iplist = $1;
				my @ips = split(/,/,$iplist);
				if ($ipaddr ~~ @ips) {
					#now we need to make sure that the ip matches this device in riscdevice so the deviceids line up
					$ipaddr = $line->{'ipaddress'};
					$physid = $line->{'deviceid'};
					$isawin = 1;
					$married = 1;
					$logger->debug("$hostName: windows resulted in: ipaddr='$ipaddr', physid='$physid', isawin='$isawin', married='$married'");
					last;
				}
			}
		} elsif ($isawin < 1) {
			my $gensrvip;
			eval {
				$logger->debug("$hostName: trying gensrv ip match");
				$gensrvip = $mysql->selectrow_hashref("
					select rd.deviceid,ipaddress
					from riscdevice rd
					inner join iptables ipt using(deviceid)
					where ipt.ip = \'$ipaddr\'
						and if(\'$mac\' = 'unknown',1,rd.macaddr = \'$mac\')
					");
			};
			if (defined($gensrvip) and defined($gensrvip->{'ipaddress'})) {
				$ipaddr = $gensrvip->{'ipaddress'};
				$physid = $gensrvip->{'deviceid'};
				$married = 1;
				$logger->debug("$hostName: matched gensrv: ipaddr='$ipaddr', physid='$physid', married='$married'");
			}
		}
		$winQuery->finish();
	}

	#now we decide on the deviceid to use
	if ($married) {
		$vmid = $physid;
		$vmid =~ s/^$assessid//;
		$logger->debug("$hostName: is married, got vmid='$vmid' from physid='$physid'");
	} else {
		if (defined($ipaddr) && $ipaddr !~ /unknown/ && $ipaddr ne '0' && $ipaddr !~ /:/) {
			$vmid = unpack("N",inet_aton($ipaddr));
			$logger->debug("$hostName: got vmid='$vmid' by processing ipaddr='$ipaddr'");
		} else {
			$vmid = $deviceInteger;
			$logger->debug("$hostName: got vmid='$vmid' as deviceInteger");
			$deviceInteger++;
		}
	}

	#Here we have two different ways to enter the device into the table
	eval {
		$logger->debug("$hostName: inserting to riscdevice with deviceid='$vmid', ipaddress='$ipaddr', mac='$vmid', sysdescription='$hostName'");
		my $riscdevice_insert = $mysql->prepare_cached("insert into riscdevice (
			deviceid,
			sysdescription,
			ipaddress,
			macaddr,
			snmpstring,
			layer1,
			layer2,
			layer3,
			layer4,
			layer5,
			layer6,
			layer7,
			wmi
			) values (?,?,?,?,'',0,0,0,0,0,0,0,0)"
		);
		$riscdevice_insert->execute($vmid,$hostName,$ipaddr,$vmid);
	}; if ($@) {
		$logger->error("$hostName: failed riscdevice insert: $@");
	}

	## unless we find a physical deviceid for this device,
	## return the vmware deviceid as the physical
	## a legitimate physical will have the assessmentid portion already,
	## but the caller will need to concat the assessmentid if the physical matches the vm
	unless ($physid) {
		$physid = $vmid;
	}

	return ($vmid,$physid);
}

sub getDeviceID {
	my $ip = shift;
	my $deviceid;
	my $existingdevQuery = $mysql->selectrow_hashref("select distinct(vcenterid) as devid from riscvmwarematrix where vcenterid regexp inet_aton(\'$ip\') limit 1");
	if (defined($existingdevQuery->{'devid'})) {
		$deviceid = $existingdevQuery->{'devid'};
		return $deviceid;
	} else {
		my $devlookup = $mysql->prepare("select deviceid from riscdevice where ipaddress=? order by length(deviceid) desc limit 1");
		$devlookup->execute($ip);
		if ($devlookup->rows() < 1) {
			#Run disco on that ip and get the device into the database.
			my $devidcreate = $mysql->prepare("select concat($assessid,inet_aton(?)) as deviceid");
			$devidcreate->execute($ip);
			print "Some failure with IP to Deviceid conversion...." unless $devidcreate->rows() > 0;
			$deviceid = $devidcreate->fetchrow_hashref->{'deviceid'};
			eval {
				$mysql->do("insert into riscdevice (deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) values($deviceid,'unknown','$ip',$deviceid,'',0,0,0,0,0,0,0,0)");
			};
			return $deviceid;
		}
		$deviceid=$devlookup->fetchrow_hashref->{'deviceid'};
		return $deviceid;
	}
}

sub getNicInfo {
	my $mysql = shift;
	my $deviceid = shift;
	my $uuid = shift;
	my $scantime = shift;
	my $entity_view = shift;

	my $insertNicInfo = $mysql->prepare("insert into vmware_guestnicinfo (uuid,deviceid,connected,mac,network,scantime)
		values (?,?,?,?,?,?)");
	my @nics = $entity_view->{'guest'}->{'net'};
	foreach my $nic2 (@nics) {
		foreach my $nic (@$nic2) {
			my $connected = $nic->connected;
			my $mac = $nic->macAddress;
			my $network = $nic->network;
			$logger->debug("$uuid: got nic: mac='$mac', network='$network', connected='$connected'");
			eval {
				$insertNicInfo->execute($uuid,$deviceid,$connected,$mac,$network,$scantime);
			}; if ($@) {
				$logger->error("failed insert to vmware_guestnicinfo: $@");
			}
		}
	}
}
