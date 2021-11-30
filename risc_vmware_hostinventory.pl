#!/usr/bin/perl
# The simpleclient.pl script outputs a list of all the entities of the specified managed-entity
# type (ClusterComputeResource, ComputeResource, Datacenter, Datastore, Folder, HostSystem,
# Network, ResourcePool, VirtualMachine, or VirtualService) found on the target vCenter Server or
# ESX system. Script users must provide logon credentials and the managed entity type. The script
# leverages the Util::trace() subroutine to display the found entities of the specified type.

use strict;
use VMware::VIRuntime;
use Digest::MD5 qw( md5 md5_hex md5_base64 );
use RISC::riscUtility;
use RISC::Collect::Logger;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
$|++;

my $logger = RISC::Collect::Logger->new('risc_vmware_hostinventory');

my $assessid	= shift;
my $credid	= shift;

$logger->info("host inventory begin");

my %opts = (
	entity => {
		type => "=s",
		variable => "VI_ENTITY",
		help => "ManagedEntity type: HostSystem, etc",
		required => 1,
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
my $generatedIDQuery = $mysql->selectrow_hashref("select * from riscdevice where deviceid>4294917295 and deviceid<4294967296 order by deviceid desc limit 1");
if (defined $generatedIDQuery->{'deviceid'}) {
	$deviceInteger = $generatedIDQuery->{'deviceid'} + 1;
} else {
	$deviceInteger = 4294917295;
}
$logger->debug("generated deviceInteger '$deviceInteger'");

my $insertlog = $mysql->prepare_cached("INSERT into vmware_hostlogs (deviceid,scantime,logdatetime,logfile,hostname,logentry) values (?,?,?,?,?,?)");

my $servername = Opts::get_option('server');
$logger->info("running against '$servername'");

my $deviceid = getDeviceID($servername);
$logger->debug("got deviceid (vcenterid) '$deviceid'");

$logger->debug("building insert statements");
my $inserthost = $mysql->prepare_cached("INSERT into vmware_hostsystem (deviceid,scantime,name,cpuhz,cpucores,cpupackages,biosversion,releasedate,model,uuid,vendor,apitype,apiversion,build,fullname,localebuild,localeversion,vmname,ostype,productlineid,vmvendor,version,totalmem,status) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $riscVMwareMatrixInsert=$mysql->prepare_cached("insert into riscvmwarematrix (deviceid,vcenterid,windowsosid,uuid,type,objectid) values (?,?,?,?,'host',?)");
my $riscVMwareMatrixInsertOld=$mysql->prepare_cached("insert into riscvmwarematrix (deviceid,vcenterid,uuid,type) values (?,?,?,'host')");

my $hostcaps = $mysql->prepare_cached("INSERT into vmware_hostcapability (deviceid,backgroundsnapshotssupported,clonefromsnampshotsupported,cpumemoryresourceconfigurationsupported,datastoreprincipalsupported,deltadiskbackingssupported,ftsupported,highguestmemsupported,ipmisupported,iscsisupported,localswapdatastoresupported,loginbysslthumbprintsupported,maintenancemodesupported,maxsupportedvcpus,maxrunningvms,maxsupportedvms,nfssupported,nicteamingsupported,pervmnetworktrafficshapingsupported,pervmswapfiles,preassignedpciunitnumberssupported,rebootsupported,recordreplaysupported,recursiveresourcepoolssupported,replayunsuportedreason,restrictedsnampshotrelocatesupported,sansupported,screenshotsupported,shutdownsupported,standbysupported,storagevmotionsupported,suspendedrelocatesupported,tpmsupported,unsharedswapvmotionsupported,virtualexecusagesupported,vlantaggingsupported,vmotionsupported,vmotionwithstoragevmotionsupported,esxhost,scantime) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hosthba = $mysql->prepare_cached("INSERT into vmware_hosthba (esxhost,deviceid,scantime,device,driver,key,model,status,bus,pci) values (?,?,?,?,?,?,?,?,?,?)");
my $hostmultipath = $mysql->prepare_cached("INSERT into vmware_hostmultipath (esxhost,deviceid,scantime,id,key,lun,adapter,isworkingpath,pathkey,pathlun,pathname,pathstate) values (?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostnat = $mysql->prepare_cached("insert into vmware_hostnat (deviceid, scantime, natkey, activeftp, allowanyoui, configport, ipgatewayaddress, udptimeout, virtualswitch, dnsautodetect, dnsnameserver, dnspolicy, dnsretries, dnstimeout, nbdstimeout, nbnsretires, nbnstimeout) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostnattable = $mysql->prepare_cached("insert into vmware_hostnattable (deviceid, scantime, natkey, virtualswitch, gustipaddress, guestport, hostport, name, type) values (?,?,?,?,?,?,?,?,?)");
my $hostnetcaps = $mysql->prepare_cached("INSERT into vmware_hostnetworkcapability (esxhost,deviceid,scantime,cansetphysicalnicspeed,dhcponvnicsupported,dnsconfigsupported,iprouteconfigsuported,ipv6supported,maxportgroupsperswitch,nicteamingpolicy,supportsnetworkints,supportsnicteaming,supportsvlan,usesserviceconsolenic,vnicconfigsupported,vswitchconfigsupported) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,)");
my $hostnetvm = $mysql->prepare_cached("insert into vmware_hostnetwork_vm (deviceid, scantime, name, vm) values (?,?,?,?)");
my $hostnetwork = $mysql->prepare_cached("insert into vmware_hostnetwork(deviceid,scantime,host,networkname) values (?,?,?,?)");
my $hostperflevel = $mysql->prepare_cached("insert into vmware_statisticslevel (deviceid,scantime,host,intervalname,length,samplingperiod,level,enabled,logkey) values (?,?,?,?,?,?,?,?,?)");
my $hostpgport = $mysql->prepare_cached("insert into vmware_hostportgroup_port(deviceid,scantime,host,portgroupname,portgroupkey,portkey,porttype) values (?,?,?,?,?,?,?)");
my $hostpgroup = $mysql->prepare_cached("insert into vmware_portgroup (deviceid, scantime, pgkey, name, vlanid, vswitchname, nicteam_failcheckbeacon, nicteam_failcheckduplex, nicteam_failcheckerrorpercent, nicteam_failcheckspeed, nicteam_failfullduplex, nicteam_failpercentage, nicteam_failspeed, notifyswitches, policy, reversepolicy, rollingorder, csumoffload, tcpsegmentation, zerocopyxmit, allowpromiscuous, forgedtransmits, macchanges, averagebandwidth, burstsize, enabled, peakbandwidth,host) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostphysnic = $mysql->prepare_cached("INSERT into vmware_hostphysicalnic (esxhost,deviceid,scantime,device,driver,key,speedmb,duplex,mac,pci,ipaddress) values (?,?,?,?,?,?,?,?,?,?,?)");
my $hostpnic = $mysql->prepare_cached("insert into vmware_hostpnic (deviceid, scantime, device, duplex, speedmb, dhcp, ipaddress, subnetmask,pci,resourcepoolschedulerallowed,vmdirectpathgen2supported,pnickey,autonegotiatesupported,wakeonlansupported,mac,driver,host) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostportmac = $mysql->prepare_cached("insert into vmware_hostport_mac(deviceid,scantime,host,portkey,mac) values (?,?,?,?,?)");
my $hostscsilun = $mysql->prepare_cached("INSERT into vmware_hostscsilun (esxhost,deviceid,scantime,canonicalname,updateddisplaynamesupported,id,quality,displayname,key,model,luntype,operationalstate,queuedepth,revision,scsilevel,serialnumber,uuid,vendor) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostscsitop = $mysql->prepare_cached("INSERT into vmware_hostscsitopology (esxhost,deviceid,scantime,device,driver,key,model,status,bus,pci) values (?,?,?,?,?,?,?,?,?,?)");
my $hostvnicconfig = $mysql->prepare_cached("insert into vmware_virtualnicconfig  (deviceid, scantime, device, portgroup, tsoenabled, mtu, mac, dhcp, ipaddress, subnetmask,host) values (?,?,?,?,?,?,?,?,?,?,?)");
my $hostvsbridge = $mysql->prepare_cached("insert into vmware_hostvirtualswitchbridge (deviceid, scantime, vswitchkey, name, nic, ldpoperation, ldpprotocol,host) values (?,?,?,?,?,?,?,?)");
my $hostvsconfig = $mysql->prepare_cached("insert into vmware_virtualswitchconfig (deviceid, scantime, name, nicteam_failcheckbeacon, nicteam_failcheckduplex, nicteam_failcheckerrorpercent, nicteam_failcheckspeed, nicteam_failfullduplex, nicteam_failpercentage, nicteam_failspeed, notifyswitches, policy, reversepolicy, rollingorder, csumoffload, tcpsegmentation, zerocopyxmit, allowpromiscuous, forgedtransmits, macchanges, averagebandwidth, burstsize, enabled, peakbandwidth, mtu, numports, numportsavailable, host,vswitchkey,vswitchtype) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostvsnics = $mysql->prepare_cached("insert into vmware_virtualswtich_nics (deviceid, name, nicid, status,) values (?,?,?,?)");
my $hostvspg = $mysql->prepare_cached("insert into vmware_hostvirtualswitchportgroup (deviceid, scantime, vswitchkey, name, portgroup,host) values (?,?,?,?,?,?)");
my $hostvspnic = $mysql->prepare_cached("insert into vmware_hostvirtualswitchpnic (deviceid, scantime, vswitchkey, name, pnic,host) values (?,?,?,?,?,?)");
my $hostvswitchport_vm = $mysql->prepare_cached("insert into vmware_hostvswitchport_vm (deviceid,scantime,host,vmname,vmuuid,mac,portgroup) values (?,?,?,?,?,?,?)");

my $scantime = time();

Util::connect();

# Obtain all inventory objects of the specified type
my $instance_type = Vim::get_service_content()->about->apiType;
my $entity_type = Opts::get_option('entity');
my $entity_views = Vim::find_entity_views(
	view_type => $entity_type,
	properties => [
		"name",
		"hardware.cpuInfo",
		"hardware.systemInfo",
		"hardware.memorySize",
		"summary.config.product",
		"capability",
		"configManager.storageSystem",
		"configStatus",
		"config.host",
		"config.network",
		"vm"
	]
);

# Here we go ahead and get the Diagnostic info also
my $diagmgr_view;
get_diagnosticManager();
$logger->debug(sprintf("%s: got %d entity_views",$deviceid,(scalar @{$entity_views})));

foreach my $entity_view (@$entity_views) {
	my $e_name = $entity_view->name;
	my $e_status = $entity_view->configStatus->val;
	my $e_id = $entity_view->{'config.host'};
	$logger->info("processing host '$e_name' with status '$e_status'");

	## apparently, we can get a host that has no config.host mo_ref
	my $objectid;
	eval {
		$objectid = $entity_view->{'config.host'}->value;
	}; if ($@) {
		$logger->error("SKIPPING HOST: no config.host mo_ref: vcenter='$servername', host='$e_name', status='$e_status'");
		next;
	}

	addVMwareMatrix($e_id,$e_name,$scantime,$deviceid);

	#next if $e_status eq 'gray';
	eval {
		#get Networking INformation
		$logger->debug("vSwitchConfig");
		getvSwitchConfig($entity_view);
	}; if ($@) {
		$logger->error("vSwitchConfig: $@");
	}
	eval {
		$logger->debug("vNICConfig");
		getvNICConfig($entity_view);
	}; if ($@) {
		$logger->error("vNICConfig: $@");
	}
	eval {
		$logger->debug("portGroupConfig");
		getPortGroupConfig($entity_view);
	}; if ($@) {
		$logger->error("portGroupConfig: $@");
	}
	eval {
		$logger->debug("pNICConfig");
		getpNICConfig($entity_view);
	}; if ($@) {
		$logger->error("pNICConfig: $@");
	}
	eval {
		$logger->debug("VMtoPG");
		getVMtoPG($entity_view);
	}; if ($@) {
		$logger->error("VMtoPG: $@");
	}
	eval {
		$logger->debug("StatsLevel");
		getStatsLevel();
	}; if ($@) {
		$logger->error("StatsLevel: $@");
	}

	#Put in the Host System information
	eval {
		my $name = $entity_view->name."\n";
		my $name2 = $name;
		chomp($name2);

		my $cpuhz = $entity_view->{'hardware.cpuInfo'}->hz;
		my $cpucore = $entity_view->{'hardware.cpuInfo'}->numCpuCores;
		my $cpupack = $entity_view->{'hardware.cpuInfo'}->numCpuPackages;
		my $cputhread = $entity_view->{'hardware.cpuInfo'}->numCpuThreads;
		#my $bios= $entity_view->hardware->biosInfo->biosVersion;
		my $bios; ## since the above is commented for some reason, at least define the variable
		#my $releasedate= $entity_view->hardware->biosInfo->releaseDate;
		my $releasedate; ## since the above is commented for some reason, at least define the variable
		my $model = $entity_view->{'hardware.systemInfo'}->model;
		my $uuid = $entity_view->{'hardware.systemInfo'}->uuid;
		my $vendor = $entity_view->{'hardware.systemInfo'}->vendor;
		my $apitype = $entity_view->{'summary.config.product'}->apiType;
		my $apiversion = $entity_view->{'summary.config.product'}->apiVersion;
		my $build = $entity_view->{'summary.config.product'}->build;
		my $fullname = $entity_view->{'summary.config.product'}->fullName;
		my $localebuild = $entity_view->{'summary.config.product'}->localeBuild;
		my $localeversion = $entity_view->{'summary.config.product'}->localeVersion;
		my $vmname = $entity_view->{'summary.config.product'}->name;
		my $ostype = $entity_view->{'summary.config.product'}->osType;
		my $productlineid = $entity_view->{'summary.config.product'}->productLineId;
		my $vmvendor = $entity_view->{'summary.config.product'}->vendor;
		my $version = $entity_view->{'summary.config.product'}->version;
		my $totalmem = $entity_view->{'hardware.memorySize'};

		my $ipQuery = $mysql->selectrow_hashref("select * from vmware_virtualnicconfig where deviceid=$deviceid and host=\'$name2\' limit 1");
		my $ipaddr = $ipQuery->{'ipaddress'};
		$ipaddr = 'unknown' unless defined($ipQuery->{'ipaddress'});
		$logger->debug("ip address: '$ipaddr'");

		my $devID = addVMwareDevice($name,$ipaddr);
		$logger->debug("got riscdevice deviceid: '$devID'");

		my $windowsosid = $assessid.$devID;
		$logger->debug("using windowsosid: '$windowsosid");

		eval {
			$logger->debug("calling riscUtility::riscvmwarematrix_insert(): devID='$devID', deviceid='$deviceid', windowsosid='$windowsosid', uuid='$uuid', objectid='$objectid'");
			riscUtility::riscvmwarematrix_insert($mysql,$devID,$deviceid,$windowsosid,$uuid,'host',$objectid);
		}; if ($@) {
			$logger->error("failed call to riscUtility::riscvmwarematrix_insert(): $@");
			$riscVMwareMatrixInsertOld->execute($devID,$deviceid,$uuid);
		}

		$logger->debug("inserting to vmware_hostsystem: deviceid='$deviceid', name='$name', uuid='$uuid'");
		$inserthost->execute(
			$deviceid,
			$scantime,
			$name,
			$cpuhz,
			$cpucore,
			$cpupack,
			$bios,
			$releasedate,
			$model,
			$uuid,
			$vendor,
			$apitype,
			$apiversion,
			$build,
			$fullname,
			$localebuild,
			$localeversion,
			$vmname,
			$ostype,
			$productlineid,
			$vmvendor,
			$version,
			$totalmem,
			$e_status
		);
	}; if ($@) {
		$logger->error("failed major host system block: $@");
	}

	#Put in the Host Capabilities
	eval {
		$logger->debug("processing host capabilities");
		my $hcap1 = $entity_view->capability->backgroundSnapshotsSupported;
		my $hcap2 = $entity_view->capability->cloneFromSnapshotSupported;
		my $hcap3 = $entity_view->capability->cpuMemoryResourceConfigurationSupported;
		my $hcap4 = $entity_view->capability->datastorePrincipalSupported;
		my $hcap5 = $entity_view->capability->deltaDiskBackingsSupported;
		my $hcap6 = $entity_view->capability->ftSupported;
		my $hcap7 = $entity_view->capability->highGuestMemSupported;
		my $hcap8 = $entity_view->capability->ipmiSupported;
		my $hcap9 = $entity_view->capability->iscsiSupported;
		my $hcap10 = $entity_view->capability->localSwapDatastoreSupported;
		my $hcap11 = $entity_view->capability->loginBySSLThumbprintSupported;
		my $hcap12 = $entity_view->capability->maintenanceModeSupported;
		my $hcap13 = $entity_view->capability->maxSupportedVcpus;
		my $hcap14 = $entity_view->capability->maxRunningVMs;
		my $hcap15 = $entity_view->capability->maxSupportedVMs;
		my $hcap16 = $entity_view->capability->nfsSupported;
		my $hcap17 = $entity_view->capability->nicTeamingSupported;
		my $hcap18 = $entity_view->capability->perVMNetworkTrafficShapingSupported;
		my $hcap19 = $entity_view->capability->perVmSwapFiles;
		my $hcap20 = $entity_view->capability->preAssignedPCIUnitNumbersSupported;
		my $hcap21 = $entity_view->capability->rebootSupported;
		my $hcap22 = $entity_view->capability->recordReplaySupported;
		my $hcap23 = $entity_view->capability->recursiveResourcePoolsSupported;
		my $hcap24 = $entity_view->capability->replayUnsupportedReason;
		my $hcap25 = $entity_view->capability->restrictedSnapshotRelocateSupported;
		my $hcap26 = $entity_view->capability->sanSupported;
		my $hcap27 = $entity_view->capability->screenshotSupported;
		my $hcap28 = $entity_view->capability->shutdownSupported;
		my $hcap29 = $entity_view->capability->standbySupported;
		my $hcap30 = $entity_view->capability->storageVMotionSupported;
		my $hcap31 = $entity_view->capability->suspendedRelocateSupported;
		my $hcap32 = $entity_view->capability->tpmSupported;
		my $hcap33 = $entity_view->capability->unsharedSwapVMotionSupported;
		my $hcap34 = $entity_view->capability->virtualExecUsageSupported;
		my $hcap35 = $entity_view->capability->vlanTaggingSupported;
		my $hcap36 = $entity_view->capability->vmotionSupported;
		my $hcap37 = $entity_view->capability->vmotionWithStorageVMotionSupported;
		$hostcaps->execute(
			$deviceid,
			$hcap1,
			$hcap2,
			$hcap3,
			$hcap4,
			$hcap5,
			$hcap6,
			$hcap7,
			$hcap8,
			$hcap9,
			$hcap10,
			$hcap11,
			$hcap12,
			$hcap13,
			$hcap14,
			$hcap15,
			$hcap16,
			$hcap17,
			$hcap18,
			$hcap19,
			$hcap20,
			$hcap21,
			$hcap22,
			$hcap23,
			$hcap24,
			$hcap25,
			$hcap26,
			$hcap27,
			$hcap28,
			$hcap29,
			$hcap30,
			$hcap31,
			$hcap32,
			$hcap33,
			$hcap34,
			$hcap35,
			$hcap36,
			$hcap37,
			$e_name,
			$scantime
		);
	}; if ($@) {
		$logger->error("failed during host capability block: $@");
	}

	#Get Host HBA Information
	my $hbainsert = $mysql->prepare_cached("INSERT into vmware_hosthba(deviceid,device,driver,hbakey,model,status,bus,pci,scantime,portwwn,nodewwn,speed,esxhost) values (?,?,?,?,?,?,?,?,?,hex(cast(? as unsigned)),hex(cast(? as unsigned)),?,?)");
	my $hbainsert2 = $mysql->prepare_cached("INSERT into vmware_hosthba(deviceid,device,driver,hbakey,model,status,bus,pci,scantime,portwwn,nodewwn,speed,esxhost) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
	my $test = $entity_view->{'configManager.storageSystem'};
	my $view1 = Vim::get_view(mo_ref=>$test) if defined $test;
	my $test2 = $view1->storageDeviceInfo->hostBusAdapter if defined $view1;
	foreach my $hba_view (@$test2){
		eval {
			$logger->debug("processing host HBA");
			my $hba_device = $hba_view->{'device'};
			my $hba_driver = $hba_view->{'driver'};
			my $hba_key = $hba_view->{'key'};
			my $hba_model = $hba_view->{'model'};
			my $hba_status = $hba_view->{'status'};
			my $hba_bus = $hba_view->{'bus'};
			my $hba_pci = $hba_view->{'pci'};
			my $hba_portwwn = $hba_view->{'portWorldWideName'};
			my $hba_nodewwn = $hba_view->{'nodeWorldWideName'};
			my $hba_speed = $hba_view->{'speed'};
			if (defined $hba_portwwn && defined $hba_nodewwn) {
				$hbainsert->execute($deviceid,$hba_device,$hba_driver,$hba_key,$hba_model,$hba_status,$hba_bus,$hba_pci,$scantime,$hba_portwwn,$hba_nodewwn,$hba_speed,$e_name);
			} else {
				$hbainsert2->execute($deviceid,$hba_device,$hba_driver,$hba_key,$hba_model,$hba_status,$hba_bus,$hba_pci,$scantime,$hba_portwwn,$hba_nodewwn,$hba_speed,$e_name);
			}
		}; if ($@) {
			$logger->error("failed during HBA: $@");
		}
	}

	#Get the Host Multipath information
	my $multiinsert = $mysql->prepare_cached("INSERT into vmware_hostmultipath(deviceid,scantime,id,multikey,lun,adapter,isworkingpath,pathkey,pathlun,pathname,pathstate,esxhost) values (?,?,?,?,?,?,?,?,?,?,?,?)");

	#Get the Host SCSI Lun Information
	my $scsiluninsert = $mysql->prepare_cached("INSERT into vmware_hostscsilun(deviceid,scantime,canonicalname,updatedisplaynamesupported,id,quality,displayname,scsikey,model,luntype,operationalstate,queuedepth,revision,scsilevel,serialnumber,uuid,vendor,esxhost) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	#This section will actually reference the view that we got in the Host HBA info above to save some code?
	my $scsiluns = $view1->storageDeviceInfo->scsiLun if defined $view1;
	foreach my $lun (@$scsiluns) {
		eval {
			$logger->debug("host SCSI LUN");
			my $scsi1 = $lun->canonicalName;
			#my $scsi2 = $lun->capabilities->updateDisplayNameSupported;
			my $scsi2; ## since the above is commented out for some reason, at least define the variable
			#my $scsi3 = $lun->descriptor->id;
			my $scsi3; ## since the above is commented out for some reason, at least define the variable
			#my $scsi4 = $lun->descriptor->quality;
			my $scsi4; ## since the above is commented out for some reason, at least define the variable
			my $scsi5 = $lun->displayName;
			my $scsi6 = $lun->key;
			my $scsi7 = $lun->model;
			my $scsi8 = $lun->lunType;
			my $scsi9 = $lun->operationalState;
			my $scsi10 = $lun->queueDepth;
			my $scsi11 = $lun->revision;
			my $scsi12 = $lun->scsiLevel;
			my $scsi13 = $lun->serialNumber;
			my $scsi14 = $lun->uuid;
			my $scsi15 = $lun->vendor;
			my $lunoperstate = @$scsi9[0];
			$scsiluninsert->execute($deviceid,$scantime,$scsi1,$scsi2,$scsi3,$scsi4,$scsi5,$scsi6,$scsi7,$scsi8,$lunoperstate,$scsi10,$scsi11,$scsi12,$scsi13,$scsi14,$scsi15,$e_name);
		}; if ($@) {
			$logger->error("failed during SCSI LUN block: $@");
		}
	}
}

# Disconnect from the server
$logger->debug("disconnecting");
Util::disconnect();

$logger->info("host inventory complete");
exit(0);

sub find_datastores {
	my $dc = Vim::find_entity_views(
		view_type	=> 'Datacenter'
	);
	my @ds_array = ();
	foreach (@$dc) {
		if (defined $_->datastore) {
			@ds_array = (@ds_array, @{$_->datastore});
		}
	}
	my $datastores = Vim::get_views(
		mo_ref_array	=> \@ds_array
	);
	return \@$datastores;
}

sub addVMwareMatrix {
	my $id = shift;
	my $name = shift;
	my $scantime = shift;
	my $deviceid = shift;
	my $inserthostmatrix = $mysql->prepare_cached("INSERT into vmware_hostmatrix (deviceid,scantime,name,id,type) values (?,?,?,?,?)");
	my $removehostmatrix = $mysql->prepare_cached("delete from vmware_hostmatrix where id=? and name=? and type=?");
	my $hostid = $id->{'value'};
	my $hosttype = $id->{'type'};
	$logger->debug("removing from vmware_hostmatrix where id='$hostid', name='$name', type='$hosttype'");
	$removehostmatrix->execute($hostid,$name,$hosttype);
	$logger->debug("inserting to vmware_hostmatrix deviceid='$deviceid', name='$name', id='$hostid', type='$hosttype'");
	$inserthostmatrix->execute($deviceid,$scantime,$name,$hostid,$hosttype);
}

sub getESXName {
	my $hv = shift;
	my $id = $hv->{'value'};
	my $type = $hv->{'type'};
	my $getesxhost = $mysql->prepare_cached("select name from vmware_hostmatrix where id=? and type=? limit 1");
	$getesxhost->execute($id,$type);
	my $host = $getesxhost->fetchrow_hashref();
	if (defined $host->{'name'}) {
		return $host->{'name'};
	}else {
		return $id;
	}
}
sub getvSwitchConfig {
	my ($host) = @_;
	#       print Dumper($host);
	my $vswitches = $host->{'config.network'}->vswitch;
	my $esx = $host->name;
	#       get network information first
	#               foreach my $net (@{$host->network}) {
	#               my $pg_view = Vim::get_view(mo_ref => $net->backing->network,properties => ['name']);
	#                my $pgname = $pg_view->{'name'};
	#               $hostnetwork->execute($deviceid,$scantime,$esx,$pgname);
	#               }
	foreach my $switch (@$vswitches) {
		my $vswitchtype = ref($switch);
		my $key = $switch->key;
		my $mtu = $switch->mtu;
		my $name = $switch->name;
		print "$esx -- $name\n";
		my $numPorts = $switch->numPorts;
		my $numPortsAvailable = $switch->numPortsAvailable;
		my $pnic = $switch->pnic;
		my $vswitchbridgenic='';
		if (defined $switch->spec->bridge){
			$vswitchbridgenic = $switch->spec->bridge->nicDevice;
		}
		my $portgroup = $switch->portgroup;
		my $nicteaming_top = $switch->spec->policy->nicTeaming if defined $switch->spec->policy;
		my $offload_top = $switch->spec->policy->offloadPolicy if defined $switch->spec->policy;
		my $security_top = $switch->spec->policy->security if defined $switch->spec->policy;
		my $shape_top = $switch->spec->policy->shapingPolicy if defined $switch->spec->policy;
		#Now we drill in to the spec portions to get more info
		#First Teaming

		my $team_rollorder = $nicteaming_top->rollingOrder if defined $nicteaming_top;
		my $team_reverse = $nicteaming_top->reversePolicy if defined $nicteaming_top;
		my $team_policy = $nicteaming_top->policy if defined $nicteaming_top;
		my $team_notify = $nicteaming_top->notifySwitches if defined $nicteaming_top;
		my $team_failSpeed = $nicteaming_top->failureCriteria->speed if defined $nicteaming_top;
		my $team_failPercent = $nicteaming_top->failureCriteria->percentage if defined $nicteaming_top;
		my $team_failDuplex= $nicteaming_top->failureCriteria->fullDuplex if defined $nicteaming_top;
		my $team_failCheckBeacon = $nicteaming_top->failureCriteria->checkBeacon if defined $nicteaming_top;
		my $team_failCheckDuplex = $nicteaming_top->failureCriteria->checkDuplex if defined $nicteaming_top;
		my $team_failCheckPercent = $nicteaming_top->failureCriteria->checkErrorPercent if defined $nicteaming_top;
		my $team_failCheckSpeed = $nicteaming_top->failureCriteria->checkSpeed if defined $nicteaming_top;
		#Now Offload Settings
		my $offload_cSumOffload = $offload_top->csumOffload if defined $offload_top;
		my $offload_tcpSeg = $offload_top->tcpSegmentation if defined $offload_top;
		my $offload_zero = $offload_top->zeroCopyXmit if defined $offload_top;
		#Now security
		my $security_allowPromiscuous= $security_top->allowPromiscuous if defined $security_top;
		my $security_forged = $security_top->forgedTransmits if defined $security_top;
		my $security_mac = $security_top->macChanges if defined $security_top;
		#Now Shaping
		my $shape_avgbw = $shape_top->averageBandwidth if defined $shape_top;
		my $shape_burst = $shape_top->burstSize if defined $shape_top;
		my $shape_enabled = $shape_top->enabled if defined $shape_top;
		my $shape_peakbw = $shape_top->peakBandwidth if defined $shape_top;
		#Now LLDP / Neighbor Protocol
		#my $lldpprot = $switch->spec->bridge->linkDiscoveryProtocolConfig->protocol if defined $switch->spec->bridge->linkDiscoveryProtocolConfig;
		my $lldpprot; ## since the above is commented out for some reason, at least define the variable
		#my $lldpoper = $switch->spec->bridge->linkDiscoveryProtocolConfig->operation if defined $switch->spec->bridge->linkDiscoveryProtocolConfig;
		my $lldpoper; ## since the above is commented out for some reason, at least define the variable
		#Insert config into the database:
		$hostvsconfig->execute($deviceid,$scantime,$name,$team_failCheckBeacon,$team_failCheckDuplex,$team_failCheckPercent,$team_failCheckSpeed,$team_failDuplex,$team_failPercent,$team_failSpeed,$team_notify,$team_policy,$team_reverse,$team_rollorder,$offload_cSumOffload,$offload_tcpSeg,$offload_zero,$security_allowPromiscuous,$security_forged,$security_mac,$shape_avgbw,$shape_burst,$shape_enabled,$shape_peakbw,$mtu,$numPorts,$numPortsAvailable,$esx,$key,$vswitchtype);
		#Now insert the physical NIC to vSwitch mappings
		foreach my $vspnic (@$pnic) {
			$hostvspnic->execute($deviceid,$scantime,$key,$name,$vspnic,$esx);
		}
		#Now insert the Port Group to vSwitch mappings
		foreach my $vspg (@$portgroup) {
			$hostvspg->execute($deviceid,$scantime,$key,$name,$vspg,$esx);
		}
		#Now insert the NIC Bridge Information
		foreach my $bnic (@$vswitchbridgenic) {
			$hostvsbridge->execute($deviceid,$scantime,$key,$name,$bnic,$lldpprot,$lldpoper,$esx);
		}
	}
}
sub getvNICConfig {
	my ($host) = @_;
	my $vnics = $host->{'config.network'}->vnic;
	foreach my $vnic (@$vnics) {
		my $host = $host->name;
		my $key = $vnic->key;
		my $device = $vnic->device;
		my $port = $vnic->port;
		my $portgroup = $vnic->portgroup;
		my $mac = $vnic->spec->mac;
		my $mtu = $vnic->spec->mtu;
		my $tsoEnabled = $vnic->spec->tsoEnabled;
		my $ip = $vnic->spec->ip->ipAddress;
		my $dhcp = $vnic->spec->ip->dhcp;
		my $sm = $vnic->spec->ip->subnetMask;
		$hostvnicconfig->execute($deviceid,$scantime,$device,$portgroup,$tsoEnabled,$mtu,$mac,$dhcp,$ip,$sm,$host)
	}
}

sub getPortGroupConfig {
	my ($host) = @_;
	my $portgroups = $host->{'config.network'}->portgroup;
	foreach my $pg (@$portgroups) {
		my $host = $host->name;
		my $key = $pg->key;
		my $vlanid = $pg->spec->vlanId;
		my $vswitchname = $pg->spec->vswitchName;
		my $name = $pg->spec->name;
		my $nt_failcheckbeacon = $pg->computedPolicy->nicTeaming->failureCriteria->checkBeacon if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failcheckduplex = $pg->computedPolicy->nicTeaming->failureCriteria->checkDuplex if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failcheckerrorpercent = $pg->computedPolicy->nicTeaming->failureCriteria->checkErrorPercent if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failcheckspeed = $pg->computedPolicy->nicTeaming->failureCriteria->checkSpeed if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failfullduplex = $pg->computedPolicy->nicTeaming->failureCriteria->fullDuplex if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failpercent = $pg->computedPolicy->nicTeaming->failureCriteria->percentage if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $nt_failspeed = $pg->computedPolicy->nicTeaming->failureCriteria->speed if defined $pg->computedPolicy->nicTeaming->failureCriteria;
		my $notify = $pg->computedPolicy->nicTeaming->notifySwitches if defined $pg->computedPolicy->nicTeaming;
		my $policy = $pg->computedPolicy->nicTeaming->policy if defined $pg->computedPolicy->nicTeaming ;
		my $reverse = $pg->computedPolicy->nicTeaming->reversePolicy if defined $pg->computedPolicy->nicTeaming;
		my $rollingorder = $pg->computedPolicy->nicTeaming->rollingOrder if defined $pg->computedPolicy->nicTeaming;
		my $csumoffload = $pg->computedPolicy->offloadPolicy->csumOffload if defined $pg->computedPolicy->offloadPolicy;
		my $tcpseg = $pg->computedPolicy->offloadPolicy->tcpSegmentation if defined $pg->computedPolicy->offloadPolicy;
		my $zero = $pg->computedPolicy->offloadPolicy->zeroCopyXmit if defined $pg->computedPolicy->offloadPolicy;
		my $forge = $pg->computedPolicy->security->forgedTransmits if defined $pg->computedPolicy->security;
		my $macchanges = $pg->computedPolicy->security->macChanges if defined $pg->computedPolicy->security;
		my $allowpromiscuous = $pg->computedPolicy->security->allowPromiscuous if defined $pg->computedPolicy->security;
		my $shapeenabled = $pg->computedPolicy->shapingPolicy->enabled if defined $pg->computedPolicy->shapingPolicy;
		my $shapeavgbw = undef;
		my $shapeburst=undef;
		my $shapepeakbw = undef;
		if ($shapeenabled != 0) {
			$shapeavgbw = $pg->computedPolicy->shapingPolicy->averageBandwidth;
			$shapepeakbw = $pg->computedPoicy->shapingPolicy->peakBandwidth;
			$shapeburst=$pg->computedPolicy->shapingPolicy->burstSize;
		}
		$hostpgroup->execute($deviceid,$scantime,$key,$name,$vlanid,$vswitchname,$nt_failcheckbeacon,$nt_failcheckduplex,$nt_failcheckerrorpercent,$nt_failcheckspeed,$nt_failfullduplex,$nt_failpercent,$nt_failspeed,$notify,$policy,$reverse,$rollingorder,$csumoffload,$tcpseg,$zero,$allowpromiscuous,$forge,$macchanges,$shapeavgbw,$shapeburst,$shapeenabled,$shapepeakbw,$host);
		#Now add PortGroup to Port mappings
		if (defined $pg->port) {
			foreach my $port (@{$pg->port}) {
				my $porttype = $port->type;
				my $portkey = $port->key;
				$hostpgport->execute($deviceid,$scantime,$host,$name,$key,$portkey,$porttype);
				#Now add MAC Address information
				foreach my $mac (@{$port->mac}) {
					$hostportmac->execute($deviceid,$scantime,$host,$portkey,$mac);
				}
			}
		}
	}
}

sub getpNICConfig {
	my ($host) = @_;
	my $name = $host->name;
	my $pnics = $host->{'config.network'}->pnic;
	foreach my $pnic (@$pnics) {
		my $device=$pnic->device;
		my $ip=$pnic->spec->ip->ipAddress if defined $pnic->spec->ip;
		my $sm = $pnic->spec->ip->subnetMask if defined $pnic->spec->ip;
		my $dhcp = $pnic->spec->ip->dhcp if defined $pnic->spec->ip;
		my $speed=0;
		my $duplex=4;
		if (defined $pnic->linkSpeed) {
			$speed = $pnic->linkSpeed->speedMb if defined $pnic->linkSpeed;
			$duplex= $pnic->linkSpeed->duplex if defined $pnic->linkSpeed;
		}
		my $pci = $pnic->pci;
		my $resource = $pnic->resourcePoolSchedulerAllowed;
		my $vmdirect = $pnic->vmDirectPathGen2Supported;
		my $key = $pnic->key;
		my $autonegotiate = $pnic->autoNegotiateSupported;
		my $wakeonlan =$pnic->wakeOnLanSupported;
		my $mac = $pnic->mac;
		my $driver = $pnic->driver;
		$hostpnic->execute($deviceid,$scantime,$device,$duplex,$speed,$dhcp,$ip,$sm,$pci,$resource,$vmdirect,$key,$autonegotiate,$wakeonlan,$mac,$driver,$name);
	}
}


sub getVMtoPG {
	my ($host) = @_;
	my $esx = $host->name;
	my $vms = Vim::get_views(
		mo_ref_array	=> $host->vm,
		properties	=> [
			"config.name",
			"config.uuid",
			"network",
			"config.hardware.device"
		]
	);
	foreach my $vm (@$vms) {
		my $vmuuid = $vm->{'config.uuid'};
		my $vmname = $vm->{'config.name'};
		my $pgname = '';
		my $devices = $vm->{'config.hardware.device'};
		foreach my $dev (@$devices) {
			if ($dev->isa("VirtualEthernetCard")) {
				my $macaddress = $dev->macAddress;
				if (($dev->backing->can('network')) and (defined($dev->backing->network))) {
					my $pg_view = Vim::get_view(
						mo_ref		=> $dev->backing->network,
						properties	=> [ 'name' ]
					);
					$pgname = $pg_view->{'name'};
					$hostvswitchport_vm->execute($deviceid,$scantime,$esx,$vmname,$vmuuid,$macaddress,$pgname);
				} else {
					$hostvswitchport_vm->execute($deviceid,$scantime,$esx,$vmname,$vmuuid,$macaddress,$pgname);
				}
			}
		}
	}

}

sub getStatsLevel {
	my $perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
	my $host = 'na';
	if (defined $perfmgr_view->historicalInterval) {
		foreach my $interval (@{$perfmgr_view->historicalInterval}) {
			my $enabled = $interval->enabled;
			my $key = $interval->key;
			my $length = $interval->length;
			my $level = $interval->level;
			my $name = $interval->name;
			my $sample = $interval->samplingPeriod;
			$hostperflevel->execute($deviceid,$scantime,$host,$name,$length,$sample,$level,$enabled,$key);
		}
	} else {
		$hostperflevel->execute($deviceid,$scantime,$host,'na',0,0,0,0,'');
	}
}

sub get_diagnosticManager {
	$diagmgr_view = Vim::get_view(
		mo_ref	=> Vim::get_service_content()->diagnosticManager
	);
	unless ($diagmgr_view) {
		Util::trace(0, "Diagnostic Manager not found.\n");
		$logger->error("diagnostic manager not found");
	}
}

sub addVMwareDevice {
	my $hostName = shift;
	my $ipaddr = shift;
	my $return;
	#Here we have two different ways to enter the device into the table
	eval {
		my $insertDev1 = $mysql->prepare_cached("insert into riscdevice (deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) select inet_aton(?),?,?,inet_aton(?),'',0,0,0,0,0,0,0,0");
		my $insertDev2 = $mysql->prepare_cached("insert into riscdevice (deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) select ?,?,?,?,'',0,0,0,0,0,0,0,0");
		if (defined($ipaddr) && $ipaddr !~ /unknown/ && $ipaddr ne '0') {
			$logger->debug("inserting to riscdevice with ipaddress='$ipaddr', sysdescription='$hostName'");
			#$mysql->do("delete from riscdevice where ipaddress=\'$ipaddr\'");
			eval {
				$insertDev1->execute($ipaddr,$hostName,$ipaddr,$ipaddr)
			}; if ($@) {
				$logger->error("failed inserting to riscdevice (ipaddress block): $@");
			}
			$logger->debug("querying deviceid back out of riscdevice");
			my $devidQuery = $mysql->selectrow_hashref("select * from riscdevice where sysdescription=\'$hostName\' and ipaddress=\'$ipaddr\'");
			$return = $devidQuery->{'deviceid'};
			unless (defined($return)) {
				$logger->debug("nothing returned from riscdevice deviceid query, trying fallback insert");
				eval {
					$insertDev2->execute($deviceInteger,$hostName,'unknown',$deviceInteger)
				}; if ($@) {
					$logger->error("failed fallback insert to riscdevice: $@");
				}
				$return = $deviceInteger;
				$deviceInteger++;
			}
		} else {
			$logger->debug("inserting to riscdevice with no ipaddress");
			eval {
				$insertDev2->execute($deviceInteger,$hostName,'unknown',$deviceInteger)
			}; if ($@) {
				$logger->error("failed to insert to riscdevice (no ipaddress block): $@");
			}
			$return = $deviceInteger;
			$deviceInteger++;
		}
	}; if ($@) {
		$logger->error("failed addVMwareDevice routine: $@");
	}
	return $return;
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
			eval{
				$mysql->do("insert into riscdevice(deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) values($deviceid,'unknown','$ip',$deviceid,'',0,0,0,0,0,0,0,0)");
			};
			return $deviceid;
		}
		$deviceid = $devlookup->fetchrow_hashref->{'deviceid'};
		return $deviceid;
	}
}
