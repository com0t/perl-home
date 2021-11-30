#!/usr/bin/perl
#
## inventory-detail-gensrv.pl -- generic server (unix/linux) inventory script using SNMP

use strict;
use Data::Dumper;
use RISC::riscUtility;
use RISC::riscCreds;
use RISC::riscSNMP;
use RISC::Collect::Logger;
use RISC::Collect::Constants qw( :status :bool :userlog );
use RISC::Collect::UserLog;

$|++;

my $deviceid	= shift;
my $target	= shift;
my $credid	= shift;

my $logger = RISC::Collect::Logger->new("inventory::gensrvsnmp::$target");
$logger->info('begin');

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});

my $do_inventory_processes	= 1;	## collect running processes, default option
my $no_process_args_indicator	= '(RN150: process argument collection opted out)';

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} = 1;

my $ul = RISC::Collect::UserLog
	->new({ db => $mysql, logger => $logger })
	->context('inventory')
	->collection_id($deviceid);

$logger->debug('get inventory log');
my $invlog = riscUtility::getInventoryLog($mysql,$deviceid,$target);
my $invlogtime = time();
$invlog->{'ipaddress'} = $target;
$invlog->{'attempt'} = $invlogtime;

$logger->debug('fetching credential');
my $credobj = riscCreds->new();
my $cred = $credobj->getSNMP($credid);
unless ($cred) {
	$logger->error(sprintf('failed to fetch credential: %s', $credobj->get_error()));
	$ul->critical('Failed to fetch credential', 'runtime-error');
	riscUtility::updateInventoryLog($mysql,$invlog);
	exit(1);
}
$credobj->disconnect();

$logger->debug('connecting');
my $snmp_opts = {};
$snmp_opts->{'Debug'} = 1 if ($debugging > 1);
my $info = riscSNMP::connect($cred,$target,$snmp_opts,'name');
unless ($info) {
	$logger->error('failed to connect, setting decom to 1');
	$invlog->{'decom'} = 1;
	$ul->error('Failed SNMP connection', 'not-accessible');
	riscUtility::updateInventoryLog($mysql,$invlog);
	exit(1);
}
$logger->debug('connected');

$logger->debug('setting decom to 0');
$invlog->{'decom'} = 0;

###
#	get global info that is used in more than one place
##
my (
	$name,
	$intindex,
	$description,
	$type,
	$speed,
	$mac,
	$operstatus,
	$adminstatus,
	$ipr_dest,
	$ipr_ifindex,
	$ipr_1,
	$ipr_2,
	$ipr_3,
	$ipr_4,
	$ipr_5,
	$ipr_nexthop,
	$ipr_type,
	$ipr_proto,
	$ipr_age,
	$ipr_mask
);
eval {
	$name		= $info->interfaces();
	$intindex	= $info->i_index();
	$description	= $info->i_description();
	$type		= $info->i_type();
	$speed		= $info->i_speed();
	$mac		= $info->i_mac();
	$operstatus	= $info->i_up();
	$adminstatus	= $info->i_up_admin();
	$ipr_dest	= $info->ipr_route();
	$ipr_ifindex	= $info->ipr_if();
	$ipr_1		= $info->ipr_1();
	$ipr_2		= $info->ipr_2();
	$ipr_3		= $info->ipr_3();
	$ipr_4		= $info->ipr_4();
	$ipr_5		= $info->ipr_5();
	$ipr_nexthop	= $info->ipr_dest();
	$ipr_type	= $info->ipr_type();
	$ipr_proto	= $info->ipr_proto();
	$ipr_age	= $info->ipr_age();
	$ipr_mask	= $info->ipr_mask();
}; if ($@) {
	$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'global', $@));
}

$logger->debug('creating temporary tables');
$mysql->do("CREATE TEMPORARY TABLE tmp_snmpsysinfo LIKE snmpsysinfo");
$mysql->do("CREATE TEMPORARY TABLE tmp_interfaces LIKE interfaces");
$mysql->do("CREATE TEMPORARY TABLE tmp_iptables LIKE iptables");
$mysql->do("CREATE TEMPORARY TABLE tmp_iproutes LIKE iproutes");
$mysql->do("CREATE TEMPORARY TABLE tmp_deviceentity LIKE deviceentity");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvdevice LIKE gensrvdevice");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvstorage LIKE gensrvstorage");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvserver LIKE gensrvserver");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvpartition LIKE gensrvpartition");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvfilesystem LIKE gensrvfilesystem");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvapplications LIKE gensrvapplications");
$mysql->do("CREATE TEMPORARY TABLE tmp_gensrvprocesses LIKE gensrvprocesses");

my (
	$cpu_description,
	$cpu_logical
);

$logger->debug('collecting data');
GatherIPTables();
GetEntity();
GetInterfaces();
#GetRoutes();
GetSysDescription();
getGenericServerInfo();

## remove the existing record
## if this is a net-new via an additive scan, this is a no-op
## if this is an updating inventory, then we have to do this
## otherwise, this is good anyway to avoid duplicate entries
$logger->debug('removing existing device entries if any');
$mysql->do("call remove_gensrv_device($deviceid)");

## remove autoincrements from the tmp tables that have them before rolling into permanent
$logger->debug('removing autoincrements from tmp tables');
$mysql->do("ALTER TABLE tmp_interfaces CHANGE interfaceid interfaceid bigint(40) DEFAULT NULL, DROP PRIMARY KEY");

$mysql->do("UPDATE tmp_interfaces SET interfaceid = NULL");

$logger->debug('inserting into permanent tables from tmp');
$mysql->do("INSERT INTO snmpsysinfo SELECT * FROM tmp_snmpsysinfo");
$mysql->do("INSERT INTO interfaces SELECT * FROM tmp_interfaces");
$mysql->do("INSERT INTO iptables SELECT * FROM tmp_iptables");
$mysql->do("INSERT INTO iproutes SELECT * FROM tmp_iproutes");
$mysql->do("INSERT INTO deviceentity SELECT * FROM tmp_deviceentity");
$mysql->do("INSERT INTO gensrvdevice SELECT * FROM tmp_gensrvdevice");
$mysql->do("INSERT INTO gensrvstorage SELECT * FROM tmp_gensrvstorage");
$mysql->do("INSERT INTO gensrvserver SELECT * FROM tmp_gensrvserver");
$mysql->do("INSERT INTO gensrvpartition SELECT * FROM tmp_gensrvpartition");
$mysql->do("INSERT INTO gensrvfilesystem SELECT * FROM tmp_gensrvfilesystem");
$mysql->do("INSERT INTO gensrvapplications SELECT * FROM tmp_gensrvapplications");
$mysql->do("INSERT INTO gensrvprocesses SELECT * FROM tmp_gensrvprocesses");

## update our inventorylog
## if we already have an inventory timestamp, then this must be an updating run
if ($invlog->{'inventory'}) {
	$invlog->{'updated'} = $invlogtime;
} else {
	$invlog->{'inventory'} = $invlogtime;
}
$logger->debug('committing inventory log');
riscUtility::updateInventoryLog($mysql,$invlog);

$logger->info('complete');
$mysql->disconnect();
exit(0);

#######################################

sub GetSysDescription {
	eval {
		my $insert_snmpsysinfo = $mysql->prepare("
			INSERT INTO tmp_snmpsysinfo
			(deviceid,sysdescription,sysuptime,syscontact,sysname,syslocation,sysservices,sysoid)
			VALUES
			(?,?,?,?,?,?,?,?)
		");
		my $snmpsysdescription	= $info->description();
		my $snmpsysuptime	= $info->uptime();
		my $snmpsyscontact	= $info->contact();
		my $snmpsyslocation	= $info->location();
		my $snmpsyslayers	= $info->layers();
		my $snmpsysname		= $info->name();
		my $sysoid		= $info->id();
		my $snmpsysservices;	## unused
		$insert_snmpsysinfo->execute(
			$deviceid,
			$snmpsysdescription,
			$snmpsysuptime,
			$snmpsyscontact,
			$snmpsysname,
			$snmpsyslocation,
			$snmpsysservices,
			$sysoid
		);
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'system', $@));
	}
}

sub GetInterfaces {
	eval {
		my $insert_interfaces = $mysql->prepare("
			INSERT INTO tmp_interfaces
			(deviceid,name,description,type,speed,intindex,mac,adminstatus,operstatus)
			VALUES
			(?,?,?,?,?,?,?,?,?)
		");
		foreach my $instance (keys %$intindex) {
			my $iname		= $name->{$instance};
			my $iintindex		= $intindex->{$instance};
			my $idescription	= $description->{$instance};
			my $itype		= $type->{$instance};
			my $ispeed		= $speed->{$instance};
			my $imac		= $mac->{$instance};
			my $ioperstatus		= $operstatus->{$instance};
			my $iadminstatus	= $adminstatus->{$instance};
			$insert_interfaces->execute(
				$deviceid,
				$iname,
				$idescription,
				$itype,
				$ispeed,
				$iintindex,
				$imac,
				$iadminstatus,
				$ioperstatus
			);
		}
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'interfaces', $@));
	}
}

sub GetRoutes {
	eval {
		my $insert_iproutes = $mysql->prepare("
			INSERT INTO tmp_iproutes
			(deviceid,ipRouteDest,ipRouteIfIndex,ipRouteMetric1,ipRouteMetric2,ipRouteMetric3,ipRouteMetric4,ipRouteNextHop,ipRouteType,ipRouteProto,ipRouteAge,ipRouteMask,ipRouteMetric5)
			VALUES
			(?,?,?,?,?,?,?,?,?,?,?,?,?)
		");
		foreach my $rrid (keys %$ipr_dest) {
			my $route_dest	= $ipr_dest->{$rrid};
			my $route_int	= $ipr_ifindex->{$rrid};
			my $route_1	= $ipr_1->{$rrid};
			my $route_2	= $ipr_2->{$rrid};
			my $route_3	= $ipr_3->{$rrid};
			my $route_4	= $ipr_4->{$rrid};
			my $route_5	= $ipr_5->{$rrid};
			my $route_nh	= $ipr_nexthop->{$rrid};
			my $route_type	= $ipr_type->{$rrid};
			my $route_proto	= $ipr_proto->{$rrid};
			my $route_age	= $ipr_age->{$rrid};
			my $route_mask	= $ipr_mask->{$rrid};
			$insert_iproutes->execute(
				$deviceid,
				$route_dest,
				$route_int,
				$route_1,
				$route_2,
				$route_3,
				$route_4,
				$route_nh,
				$route_type,
				$route_proto,
				$route_age,
				$route_mask,$route_5
			);
		}
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'routes', $@));
	}
}

sub GetEntity {
	eval {
		my $insert_deviceentity = $mysql->prepare("
			INSERT INTO tmp_deviceentity
			(deviceid,class,description,fwver,hwver,map_id,model,name,parent,serial,swver,type,physindex,manufacturer)
			VALUES
			(?,?,?,?,?,?,?,?,?,?,?,?,?,?)
		");
		my $e_class		= $info->e_class();
		my $e_description	= $info->e_descr();
		my $e_fwver		= $info->e_fwver();
		my $e_hwver		= $info->e_hwver();
		my $e_map_id		= $info->e_pos();
		my $e_model		= $info->e_model();
		my $e_name		= $info->e_name();
		my $e_parent		= $info->e_parent();
		my $e_serial		= $info->e_serial();
		my $e_swver		= $info->e_swver();
		my $e_type		= $info->e_type();
		my $e_vendor		= $info->e_vendor();
		my $e_index		= $info->e_index();
		foreach my $indices (keys %$e_class) {
			my $cl		= $e_class->{$indices};
			my $des		= $e_description->{$indices};
			my $fw		= $e_fwver->{$indices};
			my $hw		= $e_hwver->{$indices};
			my $map		= $e_map_id->{indices}; #filling this with Position now - JL 12/09
			my $mo		= $e_model->{$indices};
			my $na		= $e_name->{$indices};
			my $pa		= $e_parent->{$indices};
			my $sw		= $e_swver->{$indices};
			my $ty		= $e_type->{$indices};
			my $ser		= $e_serial->{$indices};
			my $indx	= $e_index->{$indices};
			my $vend	= $e_vendor->{$indices};
			$insert_deviceentity->execute(
				$deviceid,
				$cl,
				$des,
				$fw,
				$hw,
				$map,
				$mo,
				$na,
				$pa,
				$ser,
				$sw,
				$ty,
				$indices,
				$vend
			);
		}
		$insert_deviceentity->finish();
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'entity', $@));
	}
}

sub GatherIPTables {
	eval {
		my $insert_iptables = $mysql->prepare("
			INSERT INTO tmp_iptables
			(deviceid,ip,netmask,intindex)
			VALUES
			(?,?,?,?)
		");
		my $ipindex = $info->ip_index();
		my $iptable = $info->ip_table();
		my $ipnetmask = $info->ip_netmask();
		foreach my $x (keys %$ipnetmask) {
			my $ipintindex = $ipindex->{$x};
			my $ipnetmaskvalue = $ipnetmask->{$x};
			$insert_iptables->execute($deviceid, $x, $ipnetmaskvalue,$ipintindex);
		}
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'ip-addresses', $@));
	}
}

sub getGenericServerInfo {
	eval {
		my $insert_gensrvdevice = $mysql->prepare("
			INSERT INTO tmp_gensrvdevice
			(deviceid,devtype,devdescription,devid,devstatus,deverrors)
			VALUES
			(?,?,?,?,?,?)
		");
		my $insert_gensrvstorage = $mysql->prepare("
			INSERT INTO tmp_gensrvstorage
			(deviceid,storageindex,storagetype,storagedescription,storageallocationUnits,storagesize,storageused)
			VALUE
			(?,?,?,?,?,?,?)
		");
		my $insert_gensrvserver_legacy = $mysql->prepare("
			INSERT INTO tmp_gensrvserver
			(deviceid,uptime,processes,memorysize,numberofusers)
			VALUES
			(?,?,?,?,?)
		");
		my $insert_gensrvserver = $mysql->prepare("
			INSERT INTO tmp_gensrvserver
			(deviceid,uptime,processes,memorysize,numberofusers,numcpus,numcores,freq)
			VALUES
			(?,?,?,?,?,?,?,?)
		");
		my $insert_gensrvpartition = $mysql->prepare("
			INSERT INTO tmp_gensrvpartition
			(deviceid,partitionindex,partitionlabel,partitionid,partitionsize,partitionfsindex)
			VALUES
			(?,?,?,?,?,?)
		");
		my $insert_gensrvfilesystem = $mysql->prepare("
			INSERT INTO tmp_gensrvfilesystem
			(deviceid,fsindex,fsmountpoint,fsremotemountpoint,fstype,fsaccess,fsbootable,fsstorageindex,lastfullbackupdate,lastpartialbackupdate)
			VALUES
			(?,?,?,?,?,?,?,?,?,?)
		");
		my $insert_gensrvapplications = $mysql->prepare("
			INSERT INTO tmp_gensrvapplications
			(deviceid,swinstalledindex,swinstalledname,swinstalledid,swinstalledtype,swinstalleddate)
			VALUES
			(?,?,?,?,?,?)
		");
		my $insert_gensrvprocesses = $mysql->prepare("
			INSERT INTO tmp_gensrvprocesses
			(deviceid,swrunindex,swrunname,swrunid,swrunpath,swrunparameters,swruntype,swrunstatus,swrunperfcpu,swrunperfmem,scantime)
			VALUES
			(?,?,?,?,?,?,?,?,?,?,?)
		");

		## hrDeviceTable
		eval {
			my $devindex	= $info->hr_deviceIndex();
			my $devtype	= $info->hr_deviceType();
			my $devdescr	= $info->hr_deviceDescription();
			my $devid	= $info->hr_deviceID();
			my $devstatus	= $info->hr_deviceStatus();
			my $deverrors	= $info->hr_deviceErrors();
			foreach my $iid (keys %$devindex) {
				my $val_devtype		= '';
				my $val_devdescr	= '';
				my $val_devid		= '';
				my $val_devstatus	= '';
				my $val_deverrors	= '';
				$val_devtype		= $devtype->{$iid};
				$val_devdescr		= $devdescr->{$iid};
				## for gensrvserver cpu data, if this device is a cpu:
				##	increment the count of logical cpus
				##	record the description string (once)
				if ($val_devtype eq '.1.3.6.1.2.1.25.3.1.3') {
					$cpu_logical++;
					$cpu_description = $val_devdescr unless (defined($cpu_description));
				}
				$val_devid	= $devid->{$iid};
				$val_devstatus	= $devstatus->{$iid};
				$val_deverrors	= $deverrors->{$iid};
				$insert_gensrvdevice->execute(
					$deviceid,
					$val_devtype,
					$val_devdescr,
					$val_devid,
					$val_devstatus,
					$val_deverrors
				);
			}
		}; if ($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrDevice', $@));
		}

		## hrStorageTable (filesystem sizing)
		eval {
			my $storindex		= $info->hr_storageIndex();
			my $stortype		= $info->hr_storageType();
			my $stordescription	= $info->hr_storageDescription();
			my $storallocunits	= $info->hr_storageAllocationUnits();
			my $storsize		= $info->hr_storageSize();
			my $storused		= $info->hr_storageUsed();
			foreach my $iid (keys %$storindex) {
				my $val_storindex	= '';
				my $val_stortype	= '';
				my $val_stordescription	= '';
				my $val_storallocunits	= '';
				my $val_storsize	= '';
				my $val_storused	= '';
				$val_storindex		= $storindex->{$iid};
				$val_stortype		= $stortype->{$iid};
				$val_stordescription	= $stordescription->{$iid};
				$val_storallocunits	= $storallocunits->{$iid};
				$val_storsize		= $storsize->{$iid} * $storallocunits->{$iid};
				$val_storused		= $storused->{$iid} * $storallocunits->{$iid};
				$insert_gensrvstorage->execute(
					$deviceid,
					$val_storindex,
					$val_stortype,
					$val_stordescription,
					$val_storallocunits,
					$val_storsize,
					$val_storused
				);
			}
		}; if ($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrStorage', $@));
		}

		## MIB-II system (gensrvserver)
		eval {
			my $srvuptime		= $info->hr_systemUptime();
			my $srvprocesses	= $info->hr_systemProcesses();
			my $srvmemorysize	= $info->hr_memorySize();
			my $srvnumberofusers	= $info->hr_systemNumUsers();
			my $cpuInfo		= getCPUInfo();
			eval {
				$insert_gensrvserver->execute(
					$deviceid,
					$srvuptime,
					$srvprocesses,
					$srvmemorysize,
					$srvnumberofusers,
					$cpuInfo->{'numcpus'},
					$cpuInfo->{'numcores'},
					$cpuInfo->{'freq'}
				);
			}; if ($@) {
				$insert_gensrvserver_legacy->execute(
					$deviceid,
					$srvuptime,
					$srvprocesses,
					$srvmemorysize,
					$srvnumberofusers
				);
			}
		}; if ($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'core', $@));
		}

		## hrPartitionTable (disk partitions)
		eval {
			my $partindex	= $info->hr_partitionIndex();
			my $partlabel	= $info->hr_partitionLabel();
			my $partid	= $info->hr_partitionID();
			my $partsize	= $info->hr_partitionSize();
			my $partfsindex	= $info->hr_partitionFSIndex();
			foreach my $iid (keys %$partindex) {
				my $val_partindex	= '';
				my $val_partlabel	= '';
				my $val_partid		= '';
				my $val_partsize	= '';
				my $val_partfsindex	= '';
				$val_partindex		= $partindex->{$iid};
				$val_partlabel		= $partlabel->{$iid};
				$val_partid		= $partid->{$iid};
				$val_partsize		= $partsize->{$iid};
				$val_partfsindex	= $partfsindex->{$iid};
				$insert_gensrvpartition->execute(
					$deviceid,
					$val_partindex,
					$val_partlabel,
					$val_partid,
					$val_partsize,
					$val_partfsindex
				);
			}
		}; if($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrPartition', $@));
		}

		## hrFSTable (filesystems)
		eval {
			my $fsindex		= $info->hr_fsIndex();
			my $fsmp		= $info->hr_fsMountPoint();
			my $fsrmp		= $info->hr_fsRemoteMountPoint();
			my $fstype		= $info->hr_fsType();
			my $fsaccess		= $info->hr_fsAccess();
			my $fsboot		= $info->hr_fsBootable();
			my $fsstorageindex	= $info->hr_fsStorageIndex();
			my $fslastfullbackup	= $info->hr_fsLastFullBackupDate();
			my $fslastpartbackup	= $info->hr_fsLastPartialBackupDate();
			foreach my $iid (keys %$fsindex) {
				my $val_fsindex			= '';
				my $val_fsmp			= '';
				my $val_fsrmp			= '';
				my $val_fstype			= '';
				my $val_fsaccess		= '';
				my $val_fsboot			= '';
				my $val_fsstorageindex		= '';
				my $val_fslastfullbackup	=  '';
				my $val_fslastpartbackup	=  '';
				$val_fsindex			= $fsindex->{$iid};
				$val_fsmp			= $fsmp->{$iid};
				$val_fsrmp			= $fsrmp->{$iid};
				$val_fstype			= $fstype->{$iid};
				$val_fsaccess			= $fsaccess->{$iid};
				$val_fsboot			= $fsboot->{$iid};
				$val_fsstorageindex		= $fsstorageindex->{$iid};
				$val_fslastfullbackup		= $fslastfullbackup->{$iid};	## SNMP returns garbage for this
				$val_fslastpartbackup		= $fslastpartbackup->{$iid};	## SNMP returns garbage for this
				$insert_gensrvfilesystem->execute(
					$deviceid,
					$val_fsindex,
					$val_fsmp,
					$val_fsrmp,
					$val_fstype,
					$val_fsaccess,
					$val_fsboot,
					$val_fsstorageindex,
					$val_fslastfullbackup,
					$val_fslastpartbackup
				);
			}
		}; if ($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrFS', $@));
		}

		## hrSWInstalledTable (installed software)
		eval {
			my $swinstindex	= $info->hr_swInstalledIndex();
			my $swinstname	= $info->hr_swInstalledName();
			my $swinstid	= $info->hr_swInstalledID();
			my $swinsttype	= $info->hr_InstalledType();
			my $swinstdate	= $info->hr_InstalledDate();
			foreach my $iid (keys %$swinstindex) {
				my $val_swinstindex	= '';
				my $val_swinstname	= '';
				my $val_swinstid	= '';
				my $val_swinsttyp	= '';
				my $val_swinstdate	= '';
				my $val_swinsttype	= '';
				$val_swinstindex	= $swinstindex->{$iid};
				$val_swinstname		= $swinstname->{$iid};
				$val_swinstid		= $swinstid->{$iid};
				$val_swinsttype		= $swinsttype->{$iid};
				$val_swinstdate		= $swinstdate->{$iid};
				$insert_gensrvapplications->execute(
					$deviceid,
					$val_swinstindex,
					$val_swinstname,
					$val_swinstid,
					$val_swinsttype,
					$val_swinstdate
				);
			}
		}; if($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrSWInstalled', $@));
		}

		## hrSWRunTable (processes)
		eval {
			my $feature_do_inventory_processes = riscUtility::checkfeature('inventory-process-collection');
			if (defined($feature_do_inventory_processes)) {
				$do_inventory_processes = $feature_do_inventory_processes;
			}
			if ($do_inventory_processes) {
				my $scantime		= time();
				my $swrunindex		= $info->hr_swRunIndex();
				my $swrunname		= $info->hr_swRunName();
				my $swrunid		= $info->hr_swRunID();
				my $swrunpath		= $info->hr_swRunPath();
				my $swrunparameters	= $info->hr_swRunParameters();
				my $swruntype		= $info->hr_swRunType();
				my $swrunstatus		= $info->hr_swRunStatus();
				my $swrunperfcpu	= $info->hr_swRunPerfCPU();
				my $swrunperfmem	= $info->hr_swRunPerfMem();
				foreach my $iid (keys %$swrunindex) {
					my $val_swrunindex	= '';
					my $val_swrunname	= '';
					my $val_swrunid		= '';
					my $val_swrunpath	= '';
					my $val_swrunparameters	= '';
					my $val_swruntype	= '';
					my $val_swrunstatus	= '';
					my $val_swrunperfcpu	= '';
					my $val_swrunperfmem	= '';
					$val_swrunindex		= $swrunindex->{$iid};
					$val_swrunname		= $swrunname->{$iid};
					$val_swrunid		= $swrunid->{$iid};
					$val_swrunpath		= $swrunpath->{$iid};
					if ((riscUtility::checkfeature('no-process-args'))
						and ($swrunparameters->{$iid}))
					{
						$val_swrunparameters	= $no_process_args_indicator;
					} else {
						$val_swrunparameters	= $swrunparameters->{$iid};
					}
					$val_swruntype		= $swruntype->{$iid};
					$val_swrunstatus	= $swrunstatus->{$iid};
					$val_swrunperfcpu	= $swrunperfcpu->{$iid};
					$val_swrunperfmem	= $swrunperfmem->{$iid};
					$insert_gensrvprocesses->execute(
						$deviceid,
						$val_swrunindex,
						$val_swrunname,
						$val_swrunid,
						$val_swrunpath,
						$val_swrunparameters,
						$val_swruntype,
						$val_swrunstatus,
						$val_swrunperfcpu,
						$val_swrunperfmem,
						$scantime
					);
				}
			}
		}; if ($@) {
			$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'hrSWRun', $@));
		}
	}; if ($@) {
		$logger->error(sprintf(q(swallowed fault collecting '%s': %s), 'gensrv-data', $@));
	}
}

sub getCPUInfo {
	unless (defined($cpu_description) and ($cpu_logical > 0)) {
		return {
			'numcpus'	=> 0,
			'numcores'	=> 0,
			'freq'		=> 0
		};
	}

	my $return = {
		'numcores'	=> $cpu_logical,
		'numcpus'	=> 1,	## static value, SNMP does not provide physical packages
		'freq'		=> 0
	};

	my $desc = $cpu_description;

	## try and determine the clock frequency based on the model

	## attempt to parse the frequency out of the model string
	## will probably only work on Intel
	if ($desc =~ /(\d+\.\d+)GHz/) {
		$return->{'freq'} = $1*1000;
		return $return;
	}

	if ($desc =~ /AuthenticAMD/) {
		## AMD Processors
		if ($desc =~ /.+AMD.+\s(\d\d..?)/) {
			if ($1 eq '62xx') {
				$return->{'freq'} = 3300; ## worst case
			} elsif ($1 eq '63xx') {
				$return->{'freq'} = 3500; ## worst case, was previously set to 2300
			} elsif ($1 eq '250') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '252') {
				$return->{'freq'} = 2600;
			} elsif ($1 eq '270') {
				$return->{'freq'} = 2000;
			} elsif ($1 eq '275') {
				$return->{'freq'} = 2200;
			} elsif ($1 eq '280') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '880 ') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '2216') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '2218') {
				$return->{'freq'} = 2600;
			} elsif ($1 eq '2220') {
				$return->{'freq'} = 3000;
			} elsif ($1 eq '2222') {
				$return->{'freq'} = 3000;
			} elsif ($1 eq '2346') {
				$return->{'freq'} = 1800;
			} elsif ($1 eq '2347') {
				$return->{'freq'} = 1900;
			} elsif ($1 eq '2356') {
				$return->{'freq'} = 2300;
			} elsif ($1 eq '2376') {
				$return->{'freq'} = 2300;
			} elsif ($1 eq '2378') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '2425') {
				$return->{'freq'} = 2100;
			} elsif ($1 eq '2427') {
				$return->{'freq'} = 2200;
			} elsif ($1 eq '2435') {
				$return->{'freq'} = 2600;
			} elsif ($1 eq '4122') {
				$return->{'freq'} = 2200;
			} elsif ($1 eq '4180') {
				$return->{'freq'} = 2600;
			} elsif ($1 eq '4226') {
				$return->{'freq'} = 2700;
			} elsif ($1 eq '4284') {
				$return->{'freq'} = 3000;
			} elsif ($1 eq '4334') {
				$return->{'freq'} = 3100;
			} elsif ($1 eq '6132') {
				$return->{'freq'} = 2200;
			} elsif ($1 eq '6136') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '6174') {
				$return->{'freq'} = 2200;
			} elsif ($1 eq '6176') {
				$return->{'freq'} = 2300;
			} elsif ($1 eq '6180') {
				## this is likely '6180 SE'
				$return->{'freq'} = 2500;
			} elsif ($1 eq '6272') {
				$return->{'freq'} = 2100;
			} elsif ($1 eq '6328') {
				$return->{'freq'} = 3200;
			} elsif ($1 eq '6376') {
				$return->{'freq'} = 2300;
			} elsif ($1 eq '6380') {
				$return->{'freq'} = 2500;
			} elsif ($1 eq '8356') {
				$return->{'freq'} = 2300;
			} elsif ($1 eq '8379') {
				$return->{'freq'} = 2400;
			} elsif ($1 eq '8425') {
				$return->{'freq'} = 2100;
			}
		}
	} elsif ($desc =~ /GenuineIntel/) {
		## Intel Processors
		if ($desc =~ /Pentium.+\s4/) {
			## Pentium 4
			$return->{'freq'} = 3400;
		} elsif ($desc =~ /Pentium.+\sIII.+\s(\d+)MHz/) {
			## Pentium III
			$return->{'freq'} = $1;
		} elsif ($desc =~ /Xeon/) {
			## Xeon
			if ($desc =~ /E5-2430/) {
				$return->{'freq'} = 2200;
			} elsif ($desc =~ /E5-2620 0/) {
				$return->{'freq'} = 2000;
			} elsif ($desc =~ /E5-2620 v2/) {
				$return->{'freq'} = 2100;
			} elsif ($desc =~ /E5-2620 v3/) {
				$return->{'freq'} = 2400;
			} elsif ($desc =~ /E5-2630/) {
				$return->{'freq'} = 2300;
			} elsif ($desc =~ /E5-2640 0/) {
				$return->{'freq'} = 2500;
			} elsif ($desc =~ /E5-2640 v2/) {
				$return->{'freq'} = 2000;
			} elsif ($desc =~ /E5-2640 v3/) {
				$return->{'freq'} = 2600;
			} elsif ($desc =~ /E5-2643/) {
				$return->{'freq'} = 3300;
			} elsif ($desc =~ /E5-2650 0/) {
				$return->{'freq'} = 2000;
			} elsif ($desc =~ /E5-2660/) {
				$return->{'freq'} = 2200;
			} elsif ($desc =~ /E5-2670 0/) {
				$return->{'freq'} = 2600;
			} elsif ($desc =~ /E5-2680/) {
				$return->{'freq'} = 2700;
			} elsif ($desc =~ /E5-2690/) {
				$return->{'freq'} = 2900;
			} elsif ($desc =~ /E7- 4860/) { ## space is intentional
				$return->{'freq'} = 2270;
			} elsif ($desc =~ /E7-4860/) { ## without the space
				$return->{'freq'} = 2270;
			} elsif ($desc =~ /5140/) {
				$return->{'freq'} = 2333;
			} elsif ($desc =~ /5150/) {
				$return->{'freq'} = 2660;
			} elsif ($desc =~ /5160/) {
				$return->{'freq'} = 3000;
			} elsif ($desc =~ /E5320/) {
				$return->{'freq'} = 1860;
			} elsif ($desc =~ /E5345/) {
				$return->{'freq'} = 2333;
			} elsif ($desc =~ /E5410/) {
				$return->{'freq'} = 2333;
			} elsif ($desc =~ /E5420/) {
				$return->{'freq'} = 2500;
			} elsif ($desc =~ /E5430/) {
				$return->{'freq'} = 2667;
			} elsif ($desc =~ /E5450/) {
				$return->{'freq'} = 3000;
			} elsif ($desc =~ /E5502/) {
				$return->{'freq'} = 1867;
			} elsif ($desc =~ /E5520/) {
				$return->{'freq'} = 2267;
			} elsif ($desc =~ /E5530/) {
				$return->{'freq'} = 2400;
			} elsif ($desc =~ /E5540/) {
				$return->{'freq'} = 2267;
			} elsif ($desc =~ /E5620/) {
				$return->{'freq'} = 2400;
			} elsif ($desc =~ /E5630/) {
				$return->{'freq'} = 2533;
			} elsif ($desc =~ /E5645/) {
				$return->{'freq'} = 2400;
			} elsif ($desc =~ /E5649/) {
				$return->{'freq'} = 2530;
			} elsif ($desc =~ /E7420/) {
				$return->{'freq'} = 2130;
			} elsif ($desc =~ /L5420/) {
				$return->{'freq'} = 2500;
			} elsif ($desc =~ /L5640/) {
				$return->{'freq'} = 2267;
			} elsif ($desc =~ /X5260/) {
				$return->{'freq'} = 3333;
			} elsif ($desc =~ /X5355/) {
				$return->{'freq'} = 2660;
			} elsif ($desc =~ /X5450/) {
				$return->{'freq'} = 3000;
			} elsif ($desc =~ /X5570/) {
				$return->{'freq'} = 2933;
			} elsif ($desc =~ /X5650/) {
				$return->{'freq'} = 2670;
			} elsif ($desc =~ /X5670/) {
				$return->{'freq'} = 2930;
			} elsif ($desc =~ /X5672/) {
				$return->{'freq'} = 3200;
			} elsif ($desc =~ /X5675/) {
				$return->{'freq'} = 3070;
			} elsif ($desc =~ /X5680/) {
				$return->{'freq'} = 3330;
			} elsif ($desc =~ /Xeon\(TM\) MP CPU 3\.16GHz/) {
				$return->{'freq'} = 3160;
			} elsif ($desc =~ /Xeon\(TM\) MP CPU 3\.66GHz/) {
				$return->{'freq'} = 3660;
			} elsif ($desc =~ /Xeon\(TM\) CPU 2\.40GHz/) {
				$return->{'freq'} = 2400;
			} elsif ($desc =~ /Xeon\(TM\) CPU 2\.66GHz/) {
				$return->{'freq'} = 2660;
			} elsif ($desc =~ /Xeon\(TM\) CPU 2\.80GHz/) {
				$return->{'freq'} = 2800;
			} elsif ($desc =~ /Xeon\(TM\) CPU 3\.00GHz/) {
				$return->{'freq'} = 3000;
			} elsif ($desc =~ /Xeon\(TM\) CPU 3\.06GHz/) {
				$return->{'freq'} = 3060;
			} elsif ($desc =~ /Xeon\(TM\) CPU 3\.20GHz/) {
				$return->{'freq'} = 3200;
			} elsif ($desc =~ /Xeon\(TM\) CPU 3\.40GHz/) {
				$return->{'freq'} = 3400;
			} elsif ($desc =~ /Xeon\(TM\) CPU 3\.60GHz/) {
				$return->{'freq'} = 3600;
			}
		}
	}

	return $return;
}
