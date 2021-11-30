#!/usr/bin/perl
# The simpleclient.pl script outputs a list of all the entities of the specified managed-entity
# type (ClusterComputeResource, ComputeResource, Datacenter, Datastore, Folder, HostSystem,
# Network, ResourcePool, VirtualMachine, or VirtualService) found on the target vCenter Server or
# ESX system. Script users must provide logon credentials and the managed entity type. The script
# leverages the Util::trace() subroutine to display the found entities of the specified type.
#use strict;
use warnings;
use VMware::VIRuntime;
# Defining attributes for a required option named 'entity' that
# accepts a string.
#
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
use DBI();
use RISC::riscUtility;
use lib 'lib';
$|++;
my %opts = (
	entity => {
		type => "=s",
		variable => "VI_ENTITY",
		help => "ManagedEntity type: HostSystem, etc",
		required => 1,
	},
);
Opts::add_options(%opts);
# Parse all connection options (both built-in and custom), and then
# connect to the server
my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnonect} = 1;

## disable proxy configuration if exists
riscUtility::proxy_disable();

## CLOUD-6625 avoid renaming the process to "Hiding the command line arguments",
## which Opts::parse() does automatically.
my $original_name = $0;
Opts::parse();
$0 = $original_name;

Opts::validate();

my $getDevID = $mysql->prepare("select deviceid from riscdevice where ipaddress=?");
my $devType = $mysql->prepare("select level from credentials where deviceid=? and technology=\'vmware\'");
my $servername = Opts::get_option('server');
#$getDevID->execute($servername);
my $deviceid = getDeviceID($servername);
$devType->execute($deviceid);
my $deviceType = $devType->fetchrow_hashref()->{'level'};
my $inserthost = $mysql->prepare_cached("INSERT into vmware_hostsystem (deviceid,scantime,name,cpuhz,cpucores,cpupackages,biosversion,releasedate,model,uuid,vendor,apitype,apiversion,build,fullname,localebuild,localeversion,vmname,ostype,productlineid,vmvendor,version,totalmem) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $hostcaps = $mysql->prepare_cached("INSERT into vmware_hostcapability (esxhost,deviceid,scantime,backgroundsnapshotssupported,clonefromsnampshotsupported,cpumemoryresourceconfigurationsupported,datastoreprincipalsupported,deltadiskbackingssupported,ftsupported,highguestmemsupported,ipmisupported,iscsisupported,localswapdatastoresupported,loginbysslthumbprintsupported,maintenancemodesupported,maxsupportedvcpus,maxrunningvms,maxsupportedvms,nfssupported,nicteamingsupported,pervmnetworktrafficshapingsupported,pervmswapfiles,preassignedpciunitnumberssupported,rebootsupported,recordreplaysupported,recursiveresourcepoolssupported,replayunsuportedreason,restrictedsnampshotrelocatesupported,sansupported,screenshotsupported,shutdownsupported,standbysupported,storagevmotionsupported,suspendedrelocatesupported,tpmsupported,unsharedswapvmotionsupported,virtualexecusagesupported,vlantaggingsupported,vmotionsupported,vmotionwithstoragevmotionsupported) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostnetcaps = $mysql->prepare_cached("INSERT into vmware_hostnetworkcapability (esxhost,deviceid,scantime,cansetphysicalnicspeed,dhcponvnicsupported,dnsconfigsupported,iprouteconfigsuported,ipv6supported,maxportgroupsperswitch,nicteamingpolicy,supportsnetworkints,supportsnicteaming,supportsvlan,usesserviceconsolenic,vnicconfigsupported,vswitchconfigsupported) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,)");
my $hostphysnic = $mysql->prepare_cached("INSERT into vmware_hostphysicalnic (esxhost,deviceid,scantime,device,driver,key,speedmb,duplex,mac,pci,ipaddress) values (?,?,?,?,?,?,?,?,?,?,?)");
my $hosthba = $mysql->prepare_cached("INSERT into vmware_hosthba (esxhost,deviceid,scantime,device,driver,key,model,status,bus,pci) values (?,?,?,?,?,?,?,?,?,?)");
my $hostmultipath = $mysql->prepare_cached("INSERT into vmware_hostmultipath (esxhost,deviceid,scantime,id,key,lun,adapter,isworkingpath,pathkey,pathlun,pathname,pathstate) values (?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostscsilun = $mysql->prepare_cached("INSERT into vmware_hostscsilun (esxhost,deviceid,scantime,canonicalname,updateddisplaynamesupported,id,quality,displayname,key,model,luntype,operationalstate,queuedepth,revision,scsilevel,serialnumber,uuid,vendor) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $hostscsitop = $mysql->prepare_cached("INSERT into vmware_hostscsitopology (esxhost,deviceid,scantime,device,driver,key,model,status,bus,pci) values (?,?,?,?,?,?,?,?,?,?)");

my $scantime=time();
Util::connect();
# Obtain all inventory objects of the specified type
#Get DataStore Information
my $ds1 = $mysql->prepare_cached("INSERT INTO vmware_dssummary (deviceid,scantime,name,location,filesystem,maxcapacity,availablespace,timestamp,multiplehostaccess,uncommitted,directoryhierarchysupported,perfilethinprvisioningsupported,rawdiskmappingsupported,storageiormsupported,congestionthreshold,enabled) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $ds2 = $mysql->prepare_cached("INSERT INTO vmware_dshost(deviceid,scantime,name,host) values (?,?,?,?)");
my $ds3 = $mysql->prepare_cached("INSERT INTO vmware_dsguest(deviceid,scantime,name,guest) values (?,?,?,?)");
my $ds4 = $mysql->prepare_cached("INSERT INTO vmware_dstemplate(deviceid,scantime,name,template) values (?,?,?,?)");
my $ds5 = $mysql->prepare_cached("INSERT INTO vmware_dsfiles (deviceid,scantime,name,path,file) values (?,?,?,?,?)");
#Get Summary info first
#dropTables();
#createTables();
clearTables();

my $dc_global = $mysql->prepare_cached("INSERT INTO vmware_datacenter (deviceid,name,datastorefolder,hostfolder,networkfolder,scantime) VALUES (?,?,?,?,?,?)");
my $dc_datastore = $mysql->prepare_cached("INSERT INTO vmware_datacenter_datastore (deviceid,name,datastore,type,scantime,dc) VALUES (?,?,?,?,?,?)");
my $dc_host = $mysql->prepare_cached("INSERT INTO vmware_datacenter_host (deviceid,name,hostuid,type,scantime,dc,parent) VALUES (?,?,?,?,?,?,?)");
my $dc_vm = $mysql->prepare_cached("INSERT INTO vmware_datacenter_vm (deviceid,name,vmuid,type,scantime,dc,parent) VALUES (?,?,?,?,?,?,?)");
my $dc_network = $mysql->prepare_cached("INSERT INTO vmware_datacenter_network (deviceid,name,network,type,scantime,dc) VALUES (?,?,?,?,?,?)");
my $compute_summary = $mysql->prepare_cached("INSERT INTO vmware_compute_resource_summary (deviceid,name,iscluster,effectivecpu,effectivememory,numcpucores,numcputhreads,numeffectivehosts,numhosts,overallstatus,totalcpu,totalmemory,defaulthardwareversionkey,spbmenabled,vmswapplacement,resourcepool,dasConfig_admissionControlEnabled,dasConfig_defaultVmSettings_isolationResponse,dasConfig_defaultVmSettings_restartPriority,dasConfig_enabled,dasConfig_failoverLevel,dasConfig_option,drsConfig_defaultVmBehavior,drsConfig_enabled,drsConfig_option,drsConfig_vmotionRate,scantime,dc) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $compute_host = $mysql->prepare_cached("INSERT INTO vmware_compute_resource_host (deviceid,name,hostid,dc,scantime) VALUES (?,?,?,?,?)");
my $compute_vm = $mysql->prepare_cached("INSERT INTO vmware_compute_resource_vm (deviceid,name,vmid,dc,scantime) VALUES (?,?,?,?,?)");
my $compute_net = $mysql->prepare_cached("INSERT INTO vmware_compute_resource_network (deviceid,name,network,dc,scantime) VALUES (?,?,?,?,?)");
my $compute_ds = $mysql->prepare_cached("INSERT INTO vmware_compute_resource_datastore (deviceid,name,datastore,dc,scantime) VALUES (?,?,?,?,?)");
my $heir = $mysql->prepare_cached("INSERT INTO vmware_heirarchy (deviceid,name,id,type,scantime,dc,parent) VALUES (?,?,?,?,?,?,?)");


#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_clusterinfo (deviceid,key,name,scantime) VALUES (?,?,?,?)");
#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_cluster_das_vmconfig (deviceid,name,dasSettings_isolationResponse,dasSettings_restartPriority,vmKey,powerOffOnIsolation,restartPriority,scantime) VALUES (?,?,?,?,?,?,?,?)");
#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_cluster_drs_vmconfig (deviceid,behavior,name,enabled,vm_key,scantime) VALUES (?,?,?,?,?,?)");
#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_clusterrule (deviceid,enabled,clustername,key,name,status,scantime) VALUES (?,?,?,?,?,?,?)")
my $cluster_action_history = $mysql->prepare_cached("INSERT INTO vmware_cluster_action_history (deviceid,target,clustername,type,actiontime,dc,scantime) VALUES (?,?,?,?,?,?,?)");
my $drs_recommendation = $mysql->prepare_cached("INSERT INTO vmware_drs_recommendation (deviceid,key,clustername,rating,reason,reasonText,scantime,dc) VALUES (?,?,?,?,?,?,?,?)");
#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_drs_migration_list (deviceid,key,clustername,cpuload,destination,destinationcpuload,destinationmemoryload,memoryload,source,sourcecpuload,sourcememoryload,time,vm) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_drs_clusterrecommendation (deviceid,key,clustername,target,type,prerequisite,rating,reason,reasontext,time) VALUES (?,?,?,?,?,?,?,?,?,?)");
#
my $datacenters = get_datacenters();
getDCMappings($datacenters);
discover_datacenters($datacenters);
find_datastores($datacenters);

# Disconnect from the server
Util::disconnect();
sub get_datacenters {
	#print "Getting Datacenter views\n";
	#Define procedures for inserting datacenter information
	my $dc = Vim::find_entity_views(view_type => 'Datacenter');
	#print "Got Datacenter views\n";
	return $dc;
}
sub getDCMappings {
	my $dc=shift;
	my @host_array = ();
	my @guest_array = ();
	my @net_array = ();
	$dc_name='';
	foreach (@$dc) {
		#print "Getting globals\n";
		$dc_name=$_->name;
		my $dc_status=$_->overallStatus;
		$dc_global->execute($deviceid,$dc_name,$_->datastoreFolder->value,$_->hostFolder->value,$_->networkFolder->value,$scantime);
		#print "Getting mapping lookups for $dc_name\n";

		#We are going to loop over every folder and just do a traversal where possible.
		#We will create a subroutine for each major object type and when we have one, we will push it there for insertion




		#Get DataCenter to Network Mappings
		if (defined $_->networkFolder){
			#print "Getting Network INfo\n";
			my $folder = Vim::get_view(mo_ref=>$_->networkFolder);
			my $childEntities = Vim::get_views(mo_ref_array => $folder->childEntity);
			foreach my $child (@$childEntities) {
				if (ref($child) eq 'Folder') {
					my $name=$child->name;
					my $parent=$child->parent->value;
					my $id=$child->{'mo_ref'}->value;
					my $type=ref($child);
					$dc_network->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
					discoverFolder($child);
					#print "Network is $name and its value is $id and its type is $type\n";
				}
				if (ref($child) ne 'Folder') {
					my $name=$child->summary->name;
					my $type=ref($child);
					my $id;
					$id=$child->summary->network->value unless $type eq 'VmwareDistributedVirtualSwitch';
					$id = 'N/A' if $type eq 'VmwareDistributedVirtualSwitch';
					$dc_network->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
					#print "Network is $name and its value is $id and its type is $type\n";
				}
			}
		}
		#Get DataCenter to Datastore Mappings
		if (defined $_->datastoreFolder){
			#print "Getting Datastore Info\n";
			my $folder = Vim::get_view(mo_ref=>$_->datastoreFolder);
			my $childEntities = Vim::get_views(mo_ref_array => $folder->childEntity);
			#print Dumper($folder);
			foreach my $child (@$childEntities) {
				if (ref($child) eq 'Folder') {
					my $name=$child->name;
					my $parent=$child->parent->value;
					my $id=$child->{'mo_ref'}->value;
					my $type=ref($child);;
					$dc_datastore->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
					#print "Datastore is $name and its value is $id and its type is $type\n";
				}
				if (ref($child) ne 'Folder') {
					my $name=$child->summary->name;
					my $id=$child->summary->datastore->value;
					my $type=$child->summary->datastore->type;
					$dc_datastore->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
					#print "Datastore is $name and its value is $id and its type is $type\n";
				}
			}
		}
		#Get DataCenter to VM Mappings
		if (defined $_->vmFolder){
			#print "Getting VM Info\n";
			my $folder = Vim::get_view(mo_ref=>$_->vmFolder);
			my $childEntities = $folder->childEntity;
			#my $childEntities = Vim::get_views(mo_ref_array => $folder->childEntity);
			#print Dumper($childEntities);
			foreach my $childEntity (@$childEntities) {
				my $child=Vim::get_view(mo_ref=>$childEntity);
				if (ref($child) eq 'Folder') {
					my $name=$child->name;
					my $parent=$child->parent->value;
					my $id=$child->{'mo_ref'}->value;
					my $type=ref($child);
					#print "VM is $name and its value is $id and its type is $type\n";
					$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
					discoverFolder($child);
				}

				if (ref($child) ne 'Folder'){
					#print Dumper($child);
					my $name=$child->name;
					my $id=$child->summary->vm->value;
					my $type=$child->summary->vm->type;
					my $parent = $child->parent->value;
					$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
					#print "VM is $name and its value is $id and its type is $type\n";
				}
#     
			}
		}

		#Get DataCenter to Host Mappings
		if (defined $_->hostFolder){
			#print "Getting Host Info\n";
			my $folder = Vim::get_view(mo_ref=>$_->hostFolder);
			my $childEntities = Vim::get_views(mo_ref_array => $folder->childEntity);
			foreach my $child (@$childEntities) {
				#print Dumper($child);
				my $name=$child->name;
				my $objType=ref($child);
				#print "Checking on $name of type $objType\n";
				if ($objType eq 'ClusterComputeResource') {
					#Get the cluster specific information otherwise just get the compute resource information
					getComputeInfoCluster($child);
					#getComputeInfo2($child);
					#discoverComputeFolder($child);
					#getClusterInfo($child);

				} else {
					#discoverComputeFolder($child);
					getComputeInfo($child);
					getComputeInfo2($child);
				}
			}
		}
		#Get DataCenter to VM Mappings
	}
}
sub discoverFolder {
	my $obj = shift; 
	#print "CHecking on a folder .....\n";
	if ($obj->childEntity) {
		my $objArray=$obj->childEntity;
		#print "Has a child\n";
		foreach my $childobj (@$objArray) {
			my $child = Vim::get_view(mo_ref => $childobj);
			#print "Checking a child\n";
			my $type=ref($child);
			my $name=$child->name;
			if ($type eq 'Folder') {
				my $id=$child->value;
				my $parent=$child->parent->value;
				$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
				#print "Object name $name and its value is $id and its type is $type\n";
				discoverFolder($child);
			}
			if ($type ne 'Folder'){
				my $id=$child->{'mo_ref'}->value;
				my $parent=$child->parent->value;
				#$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
				#print "Object name $name and its value is $id and its type is $type\n";
				$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
			}


		}

	} else {
		#print "Didn't have a child entity\n";
		my $name=$obj->name;
		my $id=$obj->{'mo_ref'}->value;
		my $type=ref($obj);
		my $parent = $obj->parent->value;
		$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
	}
}











sub getClusterInfo {
	my $cluster=shift;
	#print "Getting cluster info...\n";
	#Getting Action History
	my $actionHistory = $cluster->actionHistory;
	foreach my $action (@$actionHistory) {
		#print Dumper($action);
		my $target = $action->action->target->value;
		my $actiontype=$action->action->type;
		my $actiontime=$action->time;
		#print "Action 1: T: $target TYPE: $actiontype\n";
		$cluster_action_history->execute($deviceid,$target,$cluster->name,$actiontype,$actiontime,$dc_name,$scantime);
#                my $vm = Vim::get_view(mo_ref => $action->action->target);

	}
	#Get the DRS Recommendations
	my $drsRecommendation = $cluster->drsRecommendation;
	foreach my $recommendation (@$drsRecommendation) {
		#print Dumper($action);
		my $key=$recommendation->key;
		my $rating = $recommendation->rating;
		my $reason = $recommendation->reason;
		my $reasontext = $recommendation->reasonText;
		$drs_recommendation->execute($deviceid,$key,$cluster->name,$rating,$reason,$reasontext,$scantime,$dc_name);	
	}
	#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_cluster_das_vmconfig (deviceid,name,dasSettings_isolationResponse,dasSettings_restartPriority,vmKey,powerOffOnIsolation,restartPriority,scantime) VALUES (?,?,?,?,?,?,?,?)");
	#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_cluster_drs_vmconfig (deviceid,behavior,name,enabled,vm_key,scantime) VALUES (?,?,?,?,?,?)");
	#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_clusterrule (deviceid,enabled,clustername,key,name,status,scantime) VALUES (?,?,?,?,?,?,?)")
	#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_drs_migration_list (deviceid,key,clustername,cpuload,destination,destinationcpuload,destinationmemoryload,memoryload,source,sourcecpuload,sourcememoryload,time,vm) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
	#my $insertinfo = $mysql->prepare_cached("INSERT INTO vmware_drs_clusterrecommendation (deviceid,key,clustername,target,type,prerequisite,rating,reason,reasontext,time) VALUES (?,?,?,?,?,?,?,?,?,?)");
	#
	#Get 

}
sub getComputeInfoCluster {
	my $computeview=shift;
	#Get the generic compute information
	#my $computeview = Vim::get_view(mo_ref=>$compute);
	my $effcpu = $computeview->summary->effectiveCpu;
	my $effmem = $computeview->summary->effectiveMemory;
	my $numcpucores = $computeview->summary->numCpuCores;
	my $numcputhreads = $computeview->summary->numCpuThreads;
	my $numeffhosts = $computeview->summary->numEffectiveHosts;
	my $numhosts = $computeview->summary->numHosts;
	my $status = $computeview->summary->overallStatus;
	my $totalcpu = $computeview->summary->totalCpu;
	my $totalmem = $computeview->summary->totalMemory;
	my $name = $computeview->name;
	#my $dhkv = $computeview->configurationEx->defaultHardwareVersionKey;
	#my $sbpm = $computeview->configurationEx->spbmEnabled;
	#my $vmswap = $computeview->configurationEx->vmSwapPlacement;
	my $rpool = $computeview->resourcePool->value;
	#Now get cluster information
	my $dasConfig_admissionControlEnabled = $computeview->configuration->dasConfig->admissionControlEnabled;
	my $dasConfig_defaultVmSettings_isolationResponse = $computeview->configuration->dasConfig->defaultVmSettings->isolationResponse;
	my $dasConfig_defaultVmSettings_restartPriority = $computeview->configuration->dasConfig->defaultVmSettings->restartPriority;
	my $dasConfig_enabled = $computeview->configuration->dasConfig->enabled;
	my $dasConfig_failoverLevel = $computeview->configuration->dasConfig->failoverLevel;
	my $dasConfig_option = '';
	my $drsConfig_defaultVmBehavior = $computeview->configuration->drsConfig->defaultVmBehavior->val;
	my $drsConfig_enabled = $computeview->configuration->drsConfig->enabled;
	my $drsConfig_option = '';
	my $drsConfig_vmotionRate = $computeview->configuration->drsConfig->vmotionRate;
	$compute_summary->execute($deviceid,$name,1,$effcpu,$effmem,$numcpucores,$numcputhreads,$numeffhosts,$numhosts,$status,$totalcpu,$totalmem,$dhkv,$sbpm,$vmswap,$rpool,$dasConfig_admissionControlEnabled,$dasConfig_defaultVmSettings_isolationResponse,$dasConfig_defaultVmSettings_restartPriority,$dasConfig_enabled, $dasConfig_failoverLevel,$dasConfig_option,$drsConfig_defaultVmBehavior,$drsConfig_enabled,$drsConfig_option,$drsConfig_vmotionRate,$scantime,$dc_name);
#	INSERT INTO vmware_compute_resource_summary (deviceid,name,iscluster,effectivecpu,effectivememory,numcpucores,numcputhreads,numeffectivehosts,
#	numhosts,overallstatus,totalcpu,totalmemory,
#	defaulthardwareversionkey,spbmenabled,vmswapplacement,
#	resourcepool,
#	
#	dasConfig_admissionControlEnabled,dasConfig_defaultVmSettings_isolationResponse,dasConfig_defaultVmSettings_restartPriority,dasConfig_enabled, dasConfig_failoverLevel,dasConfig_option,drsConfig_defaultVmBehavior,drsConfig_enabled,drsConfig_option,drsConfig_vmotionRate,scantime,dc

}
sub getComputeInfo {
	#print "Getting Compute Info\n";

	my $computeview=shift;
	my $type=ref($computeview);
	my $name=$computeview->name;
	if ($type eq 'Folder') {
		my $id=$computeview->{'mo_ref'}->value;
		my $parent=$computeview->parent->value;
		$dc_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
		discoverComputeFolder($computeview);
	} else {
		#Get the generic compute information
		#my $computeview = Vim::get_view(mo_ref=>$compute);
		my $effcpu = $computeview->summary->effectiveCpu;
		my $effmem = $computeview->summary->effectiveMemory;
		my $numcpucores = $computeview->summary->numCpuCores;
		my $numcputhreads = $computeview->summary->numCpuThreads;
		my $numeffhosts = $computeview->summary->numEffectiveHosts;
		my $numhosts = $computeview->summary->numHosts;
		my $status = $computeview->summary->overallStatus;
		my $totalcpu = $computeview->summary->totalCpu;
		my $totalmem = $computeview->summary->totalMemory;
		my $name = $computeview->name;
		#my $dhkv = $computeview->configurationEx->defaultHardwareVersionKey;
		#my $sbpm = $computeview->configurationEx->spbmEnabled;
		#my $vmswap = $computeview->configurationEx->vmSwapPlacement;
		my $rpool = $computeview->resourcePool->value;

		$compute_summary->execute($deviceid,$name,0,$effcpu,$effmem,$numcpucores,$numcputhreads,$numeffhosts,$numhosts,$status,$totalcpu,$totalmem,$dhkv,$sbpm,$vmswap,$rpool,'','','','','','','','','','',$scantime,$dc_name);
	}
}
sub getComputeInfo2 {
	my $computeview=shift;
	my $type=ref($computeview);
	my $name=$computeview->name;
	if ($type eq 'Folder') {
		my $id=$computeview->{'mo_ref'}->value;
		my $parent=$computeview->parent->value;
		$dc_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
		$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
		discoverComputeFolder($computeview);
	} else {
		#print "Getting Compute Info 2\n";
		#Get the generic compute information
		#my $computeview = Vim::get_view(mo_ref=>$compute);
		my $c_h_hostid=$computeview->host;
		my $c_h_netid=$computeview->network;
		my $c_h_dsid=$computeview->datastore;
		my $cname=$computeview->name;
		foreach my $hostid (@$c_h_hostid){
			my $cid = $hostid->value;
			my $pid = $computeview->{'mo_ref'}->value;
			my $checkref = ref($hostid);
			my $child=$hostid;
			if ($checkref eq 'ManagedObjectReference') {
				$child = Vim::get_view(mo_ref => $hostid);
			}
			my $stype=ref($child);
			my $hname=$child->name;
			$compute_host->execute($deviceid,$cname,$cid,$dc_name,$scantime);
			$heir->execute($deviceid,$hname,$cid,$stype,$scantime,$dc_name,$pid);	
		}
		foreach my $netid (@$c_h_netid){

			my $cid = $netid->value;
			my $pid = $computeview->{'mo_ref'}->value;
			my $checkref = ref($netid);
			my $child=$hostid;
			if ($checkref eq 'ManagedObjectReference') {
				$child = Vim::get_view(mo_ref => $netid);
			}
			my $stype=ref($child);
			my $hname=$child->name;
			$compute_net->execute($deviceid,$cname,$netid->value,$dc_name,$scantime);
			$heir->execute($deviceid,$hname,$cid,$stype,$scantime,$dc_name,$pid);
		}
		foreach my $dsid (@$c_h_dsid){
			my $cid = $dsid->value;
			my $pid = $computeview->{'mo_ref'}->value;
			my $checkref = ref($dsid);
			my $child=$hostid;
			if ($checkref eq 'ManagedObjectReference') {
				$child = Vim::get_view(mo_ref => $dsid);
			}
			my $hname=$child->name;
			my $stype=ref($child);
			$compute_ds->execute($deviceid,$cname,$dsid->value,$dc_name,$scantime);
			$heir->execute($deviceid,$hname,$cid,$stype,$scantime,$dc_name,$pid);	
		}
	}
}
sub find_datastores {
	my $dc=shift;
	my @ds_array = ();
	foreach(@$dc) {
		#print "getting Datastore property for each Datacenter\n";
		if(defined $_->datastore) {
			@ds_array = (@ds_array, @{$_->datastore});
		}
	}
	#print "getting more views here?\n";
	my $datastores = Vim::get_views(mo_ref_array => \@ds_array);
	#print "Returning array\n";
	foreach my $view1 (@$datastores) {
		eval {
			my $d1 = $view1->info->name;
			my $d2 = $view1->capability->directoryHierarchySupported;
			my $d3 = $view1->capability->perFileThinProvisioningSupported;
			my $d4 = $view1->capability->rawDiskMappingsSupported;
			my $d5 = $view1->capability->storageIORMSupported;
			my $d6 = $view1->info->freeSpace;
			my $d7 = $view1->info->timestamp;
			my $d8 = $view1->info->url;
			my $d9 = $view1->summary->capacity;
			my $d10 = $view1->summary->multipleHostAccess;
			my $d11 = $view1->summary->type;
			my $d12 = $view1->summary->uncommitted;
			#my $d13 = $view1->iormConfiguration->congestionThreshold;
			#my $d14 = $view1->iormConfiguration->enabled;
			my $d13 = 0;
			my $d14 ='';
			$ds1->execute($deviceid,$scantime,$d1,$d8,$d11,$d9,$d6,$d7,$d10,$d12,$d2,$d3,$d4,$d5,$d13,$d14);
			##Now get the host information for each one also
			my $hostArray = $view1->host;
			foreach my $host (@$hostArray) {
				my $hostkey = $host->key;
				my $hostname = getESXName($hostkey,$deviceid);
				$ds2->execute($deviceid,$scantime,$d1,$hostname);
			}
			##Now get the VM information for each one also
			my $vmArray = $view1->vm;
			foreach my $vm (@$vmArray) {
				my $vmname = getESXName($vm,$deviceid);
				$ds3->execute($deviceid,$scantime,$d1,$vmname);
			}
			##Here, eventually, you will get the template info
			##Here, eventually, you will get the filename info
		}; if ($@) {print "Error with Datastore: $@\n";}
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
	$removehostmatrix->execute($hostid,$name,$hosttype);
	$inserthostmatrix->execute($deviceid,$scantime,$name,$hostid,$hosttype);
}

sub getESXName {
	my $hv = shift;
	my $deviceid = shift;
	my $id = $hv->{'value'};
	my $type = $hv->{'type'};
	my $getesxhost = $mysql->prepare("select name from vmware_hostmatrix where deviceid=? and id=? and type=? limit 1");
	$getesxhost->execute($deviceid,$id,$type);
	my $host = $getesxhost->fetchrow_hashref();
	if (defined $host->{'name'}) {
		return $host->{'name'};
	} else {
		return $id;
	}
}

sub getDeviceID {
	my $ip=shift;
#	my $assessid=shift;
	my $deviceid;
#	my $devlookup = $mysql->prepare("select deviceid from riscdevice where ipaddress=? and deviceid in (select vcenterid from riscvmwarematrix) limit 1");
#	my $existingdevQuery=$mysql->selectrow_hashref("select distinct(vcenterid) as devid from riscvmwarematrix where vcenterid=inet_aton(\'$ip\') or vcenterid=concat($assessid,inet_aton(\'$ip\')) limit 1");
	my $existingdevQuery=$mysql->selectrow_hashref("select distinct(vcenterid) as devid from riscvmwarematrix where vcenterid regexp inet_aton(\'$ip\') limit 1");
	if (defined($existingdevQuery->{'devid'})) {
		$deviceid=$existingdevQuery->{'devid'};
		return $deviceid;
	} else {
		my $devlookup = $mysql->prepare("select deviceid from riscdevice where ipaddress=? order by length(deviceid) desc limit 1");
		$devlookup->execute($ip);
		if ($devlookup->rows() <1) {
			#Run disco on that ip and get the device into the database.
			my $devidcreate=$mysql->prepare("select concat($assessid,inet_aton(?)) as deviceid");
			$devidcreate->execute($ip);
			#print "Some failure with IP to Deviceid conversion...." unless $devidcreate->rows() > 0;
			$deviceid=$devidcreate->fetchrow_hashref->{'deviceid'};
			eval{$mysql->do("insert into riscdevice(deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) values($deviceid,'unknown','$ip',$deviceid,'',0,0,0,0,0,0,0,0)");};
			return $deviceid;
		}
		$deviceid=$devlookup->fetchrow_hashref->{'deviceid'};
		#$devupdate->execute($deviceid,$ip);
		return $deviceid;
	}
}
sub createTables {
	$createTable400 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_clusterinfo` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`key` varchar(255),
		`name` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable401 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_datacenter` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`name` varchar(255),
		`datastorefolder` varchar(255),
		`hostfolder` varchar(255),
		`networkfolder` varchar(255),
		`scantime` int,
		`overallstatus` varchar(50)
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable402 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_datacenter_datastore` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`type` varchar(255),
		`datastore` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable403 = $mysql->prepare("
	CREATE TABLE `RISC_Discovery`.`vmware_datacenter_host` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`hostuid` varchar(255),
		`type` varchar(255),
		`parent` varchar(255),
		`scantime` int
	) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable404 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_datacenter_vm` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`vmuid` varchar(255),
		`type` varchar(255),
		`parent` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable405 = $mysql->prepare("
	CREATE TABLE `RISC_Discovery`.`vmware_datacenter_network` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`network` varchar(255),
		`type` varchar(255),
		`parent` varchar(255),
		`scantime` int
	) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable406 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_compute_resource_summary` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`iscluster` int,
		`effectivecpu` int,
		`effectivememory` bigint(40),
		`numcpucores` int,
		`numcputhreads` int,
		`numeffectivehosts` int,
		`numhosts` int,
		`overallstatus` varchar(255),
		`totalcpu` int,
		`totalmemory` bigint(40),
		`defaulthardwareversionkey` varchar(255),
		`spbmenabled` int,
		`vmswapplacement` varchar(255),
		`resourcepool` varchar(255),
		`dasConfig_admissionControlEnabled` int,
		`dasConfig_defaultVmSettings_isolationResponse` varchar(255),
		`dasConfig_defaultVmSettings_restartPriority` varchar(255),
		`dasConfig_enabled` int,
		`dasConfig_failoverLevel` int,
		`dasConfig_option` text(2000),
		`drsConfig_defaultVmBehavior` varchar(255),
		`drsConfig_enabled` int,
		`drsConfig_option` text(2000),
		`drsConfig_vmotionRate` int,
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable407 = $mysql->prepare("
	CREATE TABLE `RISC_Discovery`.`vmware_compute_resource_host` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`hostid` varchar(255),
		`parent` varchar(255),
		`scantime` int
	) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable408 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_compute_resource_vm` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`vmid` varchar(255),
		`parent` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable409 = $mysql->prepare("
	CREATE TABLE `RISC_Discovery`.`vmware_compute_resource_network` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`network` varchar(255),
		`parent` varchar(255),
		`scantime` int
	) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable410 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_compute_resource_datastore` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`datastore` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable411 = $mysql->prepare("
	CREATE TABLE `RISC_Discovery`.`vmware_cluster_das_vmconfig` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`dasSettings_isolationResponse` varchar(255),
		`dasSettings_restartPriority` varchar(255),
		`vmKey` varchar(255),
		`powerOffOnIsolation` int,
		`restartPriority` varchar(255),
		`scantime` int
	) ENGINE=MyISAM DEFAULT CHARSET=latin1");

	$createTable412 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_cluster_drs_vmconfig` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`behavior` varchar(255),
		`name` varchar(255),
		`enabled` int,
		`vm_key` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable413 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_clusterrule` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`enabled` int,
		`clustername` varchar(255),
		`key` varchar(255),
		`name` varchar(255),
		`status` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable414 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_cluster_action_history` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`target` varchar(255),
		`clustername` varchar(255),
		`type` varchar(255),
		`actiontime` datetime,
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable415 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_drs_recommendation` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`key` varchar(255),
		`clustername` varchar(255),
		`rating` int,
		`reason` varchar(255),
		`reasonText` text(2000),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable416 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_drs_migration_list` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`key` varchar(255),
		`clustername` varchar(255),
		`cpuload` int,
		`destination` varchar(255),
		`destinationcpuload` int,
		`destinationmemoryload` bigint(40),
		`memoryload` bigint(40),
		`source` varchar(255),
		`sourcecpuload` int,
		`sourcememoryload` bigint(40),
		`time` datetime,
		`vm` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable417 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_drs_clusterrecommendation` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`key` varchar(255),
		`clustername` varchar(255),
		`target` varchar(255),
		`type` varchar(255),
		`prerequisite` text(2000),
		`rating` int,
		`reason` varchar(255),
		`reasontext` text(2000),
		`time` datetime,
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable418 = $mysql->prepare("
		CREATE TABLE `RISC_Discovery`.`vmware_heirarchy` (
		`deviceid` bigint(40) unsigned NOT NULL,
		`dc` varchar(255),
		`name` varchar(255),
		`id` varchar(255),
		`parent` varchar(255),
		`type` varchar(255),
		`scantime` int
		) ENGINE=MyISAM DEFAULT CHARSET=latin1");
	$createTable400 -> execute();
	$createTable401 -> execute();
	$createTable402 -> execute();
	$createTable403 -> execute();
	$createTable404 -> execute();
	$createTable405 -> execute();
	$createTable406 -> execute();
	$createTable407 -> execute();
	$createTable408 -> execute();
	$createTable409 -> execute();
	$createTable410 -> execute();
	$createTable411 -> execute();
	$createTable412 -> execute();
	$createTable413 -> execute();
	$createTable414 -> execute();
	$createTable415 -> execute();
	$createTable416 -> execute();
	$createTable417 -> execute();
	$createTable418 -> execute();
}
sub dropTables {

	$mysql->do("drop table if exists vmware_clusterinfo");
	$mysql->do("drop table if exists vmware_datacenter");
	$mysql->do("drop table if exists vmware_datacenter_datastore");
	$mysql->do("drop table if exists vmware_datacenter_host");
	$mysql->do("drop table if exists vmware_datacenter_vm");
	$mysql->do("drop table if exists vmware_datacenter_network");
	$mysql->do("drop table if exists vmware_compute_resource_summary");
	$mysql->do("drop table if exists vmware_compute_resource_host");
	$mysql->do("drop table if exists vmware_compute_resource_vm");
	$mysql->do("drop table if exists vmware_compute_resource_network");
	$mysql->do("drop table if exists vmware_compute_resource_datastore");
	$mysql->do("drop table if exists vmware_cluster_das_vmconfig");
	$mysql->do("drop table if exists vmware_cluster_drs_vmconfig");
	$mysql->do("drop table if exists vmware_clusterrule");
	$mysql->do("drop table if exists vmware_cluster_action_history");
	$mysql->do("drop table if exists vmware_drs_recommendation");
	$mysql->do("drop table if exists vmware_drs_migration_list");
	$mysql->do("drop table if exists vmware_drs_clusterrecommendation");
	$mysql->do("drop table if exists vmware_heirarchy");
}
sub clearTables {
	$mysql->do("delete from vmware_clusterinfo where deviceid=$deviceid");
	$mysql->do("delete from vmware_datacenter where deviceid=$deviceid");
	$mysql->do("delete from vmware_datacenter_datastore where deviceid=$deviceid");
	$mysql->do("delete from vmware_datacenter_host where deviceid=$deviceid");
	$mysql->do("delete from vmware_datacenter_vm where deviceid=$deviceid");
	$mysql->do("delete from vmware_datacenter_network where deviceid=$deviceid");
	$mysql->do("delete from vmware_compute_resource_summary where deviceid=$deviceid");
	$mysql->do("delete from vmware_compute_resource_host where deviceid=$deviceid");
	$mysql->do("delete from vmware_compute_resource_vm where deviceid=$deviceid");
	$mysql->do("delete from vmware_compute_resource_network where deviceid=$deviceid");
	$mysql->do("delete from vmware_compute_resource_datastore where deviceid=$deviceid");
	$mysql->do("delete from vmware_cluster_das_vmconfig where deviceid=$deviceid");
	$mysql->do("delete from vmware_cluster_drs_vmconfig where deviceid=$deviceid");
	$mysql->do("delete from vmware_clusterrule where deviceid=$deviceid");
	$mysql->do("delete from vmware_cluster_action_history where deviceid=$deviceid");
	$mysql->do("delete from vmware_drs_recommendation where deviceid=$deviceid");
	$mysql->do("delete from vmware_drs_migration_list where deviceid=$deviceid");
	$mysql->do("delete from vmware_drs_clusterrecommendation where deviceid=$deviceid");
	$mysql->do("delete from vmware_heirarchy where deviceid=$deviceid");
}


sub discoverComputeFolder {
	my $obj = shift; 
	#print "CHecking on a folder .....\n";
	if ($obj->childEntity) {
		my $objArray=$obj->childEntity;
		#print "Has a child\n";
		foreach my $childobj (@$objArray) {
			my $child = Vim::get_view(mo_ref => $childobj);
			#print "Checking a child\n";
			my $type=ref($child);
			my $name=$child->name;
			if ($type eq 'Folder') {
				my $id=$child->value;
				my $parent=$child->parent->value;
				$dc_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
				#print "Object name $name and its value is $id and its type is $type\n";
				discoverComputeFolder($child);
			}
			if ($type ne 'Folder'){
				#print Dumper($child);
				my $id=$child->{'mo_ref'}->value;
				my $parent=$child->parent->value;
				#$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
				#print "Real Object name $name and its value is $id and its type is $type and its parent is $parent\n";
				$dc_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
				#getComputeInfo($child);	
				getComputeInfo2($child);
			}


		}

	} else {
		print "Didn't have a child entity\n";
		my $name=$obj->name;
		my $id=$obj->{'mo_ref'}->value;
		my $type=ref($obj);
		my $parent = $obj->parent->value;
		$dc_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		$compute_host->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
		if ($type eq 'Folder') {
			#getComputeInfo($obj);
		} else {
			getComputeInfo($obj);
			getComputeInfo2($obj);
		}

	}
}
sub discover_datacenters {
	my $dc=shift;
	$dc_name='';
	foreach (@$dc) {
		#print "Getting globals\n";
		$dc_name=$_->name;
		my $dc_status=$_->overallStatus;
		$dc_global->execute($deviceid,$dc_name,$_->datastoreFolder->value,$_->hostFolder->value,$_->networkFolder->value,$scantime);
		#print "Getting mapping lookups for $dc_name\n";
		#Get DataCenter to Network Mappings
		if (defined $_->networkFolder){
			discoverFolder2($_->networkFolder);
		}
		#Get DataCenter to datastore Mappings
		if (defined $_->datastoreFolder){
			discoverFolder2($_->datastoreFolder);
		}
		#Get DataCenter to vm Mappings
		if (defined $_->vmFolder){
			discoverFolder2($_->vmFolder);
		}
		#Get DataCenter to host Mappings
		if (defined $_->hostFolder){
			discoverFolder2($_->hostFolder);
		}
	}
}
sub discoverFolder2 {
	my $obj = shift; 
	#print "CHecking on a folder .....\n";
	my $checkfolder = ref($obj);
	my $folder=$obj;
	if ($checkfolder eq 'ManagedObjectReference') {
		$folder = Vim::get_view(mo_ref => $obj);
	}
	#print Dumper($folder);
	if ($folder->childEntity) {
		my $childEntities = $folder->childEntity; # REMOVED Vim::get_views(mo_ref_array => $folder->childEntity);
		#print "Has children\n";
		foreach my $childobj (@$childEntities) {
			my $checkref = ref($childobj);
			my $child=$childobj;
			if ($checkref eq 'ManagedObjectReference') {
				$child = Vim::get_view(mo_ref => $childobj);
			}

			my $type=ref($child);
			my $name=$child->name;
			my $parent=$child->parent->value;
			my $id=$child->{'mo_ref'}->value;
			#print "Checking child $id for parent $parent\n";
			if ($type eq 'Folder') {
				#my $id=$child->{'mo_ref'}->value;

				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
				#print "Object name $name and its value is $id and its type is $type - a folder that we will now check\n";
				discoverFolder2($child);
			}
			if ($type ne 'Folder'){
				#my $id=$child->{'mo_ref'}->value;
				#my $parent=$child->parent->value;
				#$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
				#print "Object name $name and its value is $id and its type is $type - not a folder, no need to recurse\n";
				discoverCluster($child) if $type eq 'ClusterComputeResource';
				getComputeInfo2($child) if $type eq 'ComputeResource';
				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
			}


		}

	} else {
		print "Didn't have a child entity - so we will enter it\n";
		my $name=$folder->name;
		my $id=$folder->{'mo_ref'}->value;
		my $type=ref($folder);
		my $parent = $folder->parent->value;
		$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
	}
}

sub discoverSubFolder {
	my $obj = shift; 
	#print "CHecking on a folder .....\n";
	my $checkfolder = ref($obj);
	my $folder=$obj;
	if ($checkfolder eq 'ManagedObjectReference') {
		$folder = Vim::get_view(mo_ref => $obj);
	}
	#print Dumper($folder);
	if ($folder->childEntity) {
		my $childEntities = $folder->childEntity; # REMOVED -- Vim::get_views(mo_ref_array => $folder->childEntity);
		#print "Has children\n";
		foreach my $childobj (@$childEntities) {
			my $checkref = ref($childobj);
			my $child=$childobj;
			if ($checkref eq 'ManagedObjectReference') {
				$child = Vim::get_view(mo_ref => $childobj);
			}

			my $type=ref($child);
			my $name=$child->name;
			my $parent=$child->parent->value;
			my $id=$child->{'mo_ref'}->value;
			#print "Checking child $id for parent $parent\n";
			if ($type eq 'Folder') {
				#my $id=$child->{'mo_ref'}->value;

				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
				#print "Object name $name and its value is $id and its type is $type - a folder that we will now check\n";
				discoverSubFolder($child);
			}
			if ($type ne 'Folder'){
				#my $id=$child->{'mo_ref'}->value;
				#my $parent=$child->parent->value;
				#$dc_vm->execute($deviceid,$name,$id,$type,$scantime,$dc_name);
				#print "Object name $name and its value is $id and its type is $type - not a folder, no need to recurse\n";
				discoverCluster($child) if $type eq 'ClusterComputeResource';
				$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);	
			}


		}

	} else {
		#print "Didn't have a child entity - so we will enter it\n";
		my $name=$folder->name;
		my $id=$folder->{'mo_ref'}->value;
		my $type=ref($folder);
		my $parent = $folder->parent->value;
		$heir->execute($deviceid,$name,$id,$type,$scantime,$dc_name,$parent);
		#print "Object name $name and its value is $id and its type is $type\n";
	}
}
sub discoverCluster {
	#print "Discoverying a Cluster Compute Resource\n";
	my $computeview=shift;
	#print Dumper($computeview);
	my $c_h_hostid=$computeview->host;
	my $c_h_netid=$computeview->network;
	my $c_h_dsid=$computeview->datastore;
	my $cname=$computeview->name;
	foreach my $hostid (@$c_h_hostid){
		my $cc = Vim::get_view(mo_ref => $hostid);
		$compute_host->execute($deviceid,$cname,$cc->{'mo_ref'}->value,$dc_name,$scantime);
		my $name= $cc->name;
		my $type=  ref($cc);
		my $parent=$cc->parent->value;
		$heir->execute($deviceid,$name,$cc->{'mo_ref'}->value,$type,$scantime,$dc_name,$parent);
	}
	foreach my $netid (@$c_h_netid){
		my $cc = Vim::get_view(mo_ref => $netid);
		$compute_net->execute($deviceid,$cname,$cc->{'mo_ref'}->value,$dc_name,$scantime);
		my $name= $cc->name;
		my $type=  ref($cc);
		my $parent=$cc->parent->value;
		$heir->execute($deviceid,$name,$cc->{'mo_ref'}->value,$type,$scantime,$dc_name,$parent);
	}
	foreach my $dsid (@$c_h_dsid){
		my $cc = Vim::get_view(mo_ref => $dsid);
		$compute_ds->execute($deviceid,$cname,$cc->{'mo_ref'}->value,$dc_name,$scantime);
		my $name= $cc->name;
		my $type=  ref($cc);
		my $parent=$cc->parent->value;
		$heir->execute($deviceid,$name,$cc->{'mo_ref'}->value,$type,$scantime,$dc_name,$parent);
	}
}
