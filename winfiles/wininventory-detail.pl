#!/usr/bin/perl -w
#
## winfiles/wininventory-detail.pl -- inventory for Windows machines using WMI
use strict;
use RISC::riscWindows;
use RISC::riscUtility;
use RISC::riscCreds;
use RISC::CollectionValidation;
use LWP::Simple qw($ua get head);
use Data::Dumper;
use Carp qw/longmess/;    # twice-as-longmess
use RISC::Collect::Logger;
use RISC::Collect::Quirks;
use RISC::Collect::UserLog;
use RISC::Collect::DatasetLog;
use RISC::Collect::Constants qw( :status :bool :userlog );

no warnings qw( uninitialized );

my ($deviceid, $target, $credid);

# use environment to avoid logging any sensitive strings - this is called with creds rather than credid by validation
if (my $risc_credentials = riscUtility::risc_credentials()) {
	($deviceid, $target, $credid) = map {
		$risc_credentials->{$_}
	} qw(deviceid target credid);
# the old fashioned way
} else {
	($deviceid, $target, $credid) = (shift, shift, shift);
}

## NOTE: no logging statements prior to the $ENV{'VALIDATE'} block
my $logger = RISC::Collect::Logger->new("inventory::windows::$target");

my $cyberark_wmi = (-f "/etc/risc-feature/cyberark-wmi" && -f "/home/risc/conf/cyberark_config.json");

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});

my $do_inventory_processes = 1;    ## collect running processes, default setting
my $no_process_args_indicator = '(RN150: process argument collection opted out)';

my $mysql = riscUtility::getDBH('RISC_Discovery', 1);
$mysql->{mysql_auto_reconnect} = 1;

my $ul = RISC::Collect::UserLog
	->new({ db => $mysql, logger => $logger })
	->context('inventory')
	->collection_id($deviceid);

my ($validator, $VALIDATE, $vsuccess, $vexplore, $vfallback, $vincomplete, $vfail);

if ($ENV{'VALIDATE'}) {
	$validator = RISC::CollectionValidation->new({
		logfile => $ENV{'VALIDATE'},
		debug   => $debugging
	});

	if (my $verror = $validator->err()) {
		print STDOUT 'Internal error: contact help@riscnetworks.com with error code CV01';
		print STDERR "$0::ERROR: $verror\n";
		$validator->exit('fail');
	}
	$VALIDATE = 1;

	## disable logging in validation mode, to avoid polluting the report
	$logger->level($RISC::Collect::Logger::LOG_LEVEL{'OFF'});

	$vsuccess    = $validator->cmdstatus_name('success');
	$vexplore    = $validator->cmdstatus_name('explore');
	$vfallback   = $validator->cmdstatus_name('fallback');
	$vincomplete = $validator->cmdstatus_name('incomplete');
	$vfail       = $validator->cmdstatus_name('fail');
}

$logger->info('begin');

my $invlog;
my $invlogtime = time();
unless ($VALIDATE) {
	$logger->debug('fetching inventory log');
	$invlog = riscUtility::getInventoryLog($mysql, $deviceid, $target);
	$invlog->{'ipaddress'} = $target;
	$invlog->{'attempt'}   = $invlogtime;
}

my $dl;
unless ($VALIDATE) {
	$logger->debug('fetching dataset_log');
	$dl = {
		inventory => RISC::Collect::DatasetLog->new(
			$deviceid,
			'inventory',
			{ db => $mysql, logger => $logger }
		),
		installedsoftware => RISC::Collect::DatasetLog->new(
			$deviceid,
			'installedsoftware',
			{ db => $mysql, logger => $logger }
		)
	};
}

my $cred;
my $credobj = riscCreds->new($target);
if ($VALIDATE) {
	my ($user, $pass, $netstat) = split(/\s+/, $credid);
	## Get creds if using CyberArk
	if ($cyberark_wmi) {
		my $credSet = $credobj->getWinCyberArkQueryString($pass);
		unless ($credSet) {
			my $errmsg = 'Failed to fetch credential: '. $credobj->get_error();
			$logger->error($errmsg);

			$validator->log("<h3>INVENTORY</h3>\n", 0);
			$validator->log("<table>\n",            0);
			$validator->log("<tr><td>Connect</td>", 1);
			$validator->log("<td class='$vfail'>$vfail</td></tr>\n",0);
			$validator->log("</table>\n",0);
			$validator->report_connection_failure($errmsg);
			$validator->finish();
			$validator->exit('fail');
		}
		$user = $credSet->{'username'};
		$pass = $credSet->{'passphrase'};
		my $domain = $credSet->{'domain'};
		$cred = $credobj->prepWin({
			'username'   => $user,
			'passphrase' => $pass,
			'context'    => $netstat,
			'domain'     => $domain
		});
	} else {
		$cred = $credobj->prepWin({
			'username'   => $user,     ## user contains domain, as appropriate
			'passphrase' => $pass,
			'context'    => $netstat
		});
	}
} else {
	$logger->debug('fetching credential');
	$cred = $credobj->getWin($credid);
	unless ($cred) {
		$logger->error(sprintf('failed to fetch credential: %s', $credobj->get_error()));
		$ul->critical('Failed to fetch credential', 'runtime-error');
		riscUtility::updateInventoryLog($mysql, $invlog);
		exit(EXIT_FAILURE);
	}
}

my $inventoryerrors = $mysql->prepare("
	INSERT INTO inventoryerrors
	(deviceid,deviceip,domain,winerror,scantime)
	VALUES
	(?,?,?,?,?)
");

if ($VALIDATE) {
	$validator->log("<h3>INVENTORY</h3>\n", 0);
	$validator->log("<table>\n",            0);
	$validator->log("<tr><td>Connect</td>", 1);
}

my $wmi = RISC::riscWindows->new({
	collection_id => $deviceid,
	user      => $cred->{'user'},
	password  => $cred->{'password'},
	domain    => $cred->{'domain'},
	credid    => ($VALIDATE ? 0 : $cred->{'credid'}),
	host      => $target,
	db        => $mysql,
	logger    => $logger,
	validator => $validator
});

unless ($wmi->connected()) {
	my $error = $wmi->err();

	if ($VALIDATE) {
		$validator->log("<td class='$vfail'>$vfail</td></tr>\n", 0);
		$validator->log("</table>\n",                            0);
		$validator->report_connection_failure($wmi->err());
		$validator->finish();
		$validator->exit('fail');
	} else {
		$logger->error(sprintf('failed access test: %s', $error));

		## any WMI error other than ACCESS_DENIED results in flagging it decommissioned
		$invlog->{'decom'} = 1 if ($error !~ /ACCESS_DENIED/i);
		riscUtility::updateInventoryLog($mysql, $invlog);

		## no idea what 5 is, or why we do this
		$mysql->do("
			UPDATE riscdevice
			SET wmi = 5
			WHERE deviceid = $deviceid
		");

		$inventoryerrors->execute($deviceid, $target, $cred->{'user'}, $error, time());
		$ul->error(sprintf('failed WMI connection: %s', $error), 'not-accessible');

		exit(EXIT_FAILURE);
	}
}

if ($VALIDATE) {
	$validator->log("<td class='$vsuccess'>$vsuccess</td></tr>\n", 0);
	$validator->log("</table>\n",                                  0);
}

$logger->debug('setting decom state to 0');
$invlog->{'decom'} = 0;

my @TABLES = qw(
	windowsos
	computerhardware
	computersystem
	windowsnetwork
	windowsprocessor
	win_cpu_info
	windowsdisks
	windowsphysicaldisk
	windowsshares
	windowsservices
	windowsapplications
	windowsapplicationregistry
	windowsprocess
	windowshba
	windowshbaport
	http_get_inventory
);

unless ($VALIDATE) {
	$logger->debug('creating temporary tables');
	map {
		$mysql->do(sprintf('CREATE TEMPORARY TABLE tmp_%s LIKE %s', $_, $_))
	} @TABLES;
}

##
# prepare insert statements
##

my (
	$insert_computerhardware,
	$insert_computersystem,
	$insert_windowsnetwork,
	$insert_windows_ip,
	$insert_windowsos,
	$insert_windowsprocessor,
	$insert_windowsservices,
	$insert_windowsshares,
	$insert_windowsphysicaldisk,
	$insert_windowsprocess,
	$insert_windowshba,
	$insert_windowshbaport,
	$insert_win_cpu_info,
	$insert_windowsdisks_old,
	$insert_windowsdisks,
	$insert_http_get_inventory
);

unless ($VALIDATE) {
	$logger->debug('preparing insert statements');

	$insert_computerhardware = $mysql->prepare("
		INSERT INTO tmp_computerhardware
		(deviceid,identifyingnumber,name,skunumber,uuid,vendor,version)
		VALUES
		(?,?,?,?,?,?,?)
	");
	$insert_computersystem = $mysql->prepare("
		INSERT INTO tmp_computersystem
		(deviceid,domain,domainrole,enabledaylightsavingstime,manufacturer,model,name,numberofprocessors,partofdomain,totalphysicalmemory)
		VALUES
		(?,?,?,?,?,?,?,?,?,?)
	");
	$insert_windowsnetwork = $mysql->prepare("
		INSERT INTO tmp_windowsnetwork
		(deviceid,adaptertype,description,intindex,macaddr,manufacturer,name,netconnectionid,defaulttos,dhcpenabled,dhcpleaseobtained,dhcpleaseexpires,dhcpserver,dnsdomain,dnshostname,ipenabled,ipxenabled,ipaddress,subnetmask,ipxaddress,ipxnet,ipxvirtualnet)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
	$insert_windows_ip = $mysql->prepare("
		INSERT INTO windows_ip
		(deviceid,intindex,ip)
		VALUES
		(?,?,?)
	");
	$insert_windowsos = $mysql->prepare("
		INSERT INTO tmp_windowsos
		(deviceid,caption,csdversion,csname,freephysicalmemory,installdate,manufacturer,name,serialnumber,servicepackmajornumber,servicepackminornumber,version)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?)
	");
	$insert_windowsprocessor = $mysql->prepare("
		INSERT INTO tmp_windowsprocessor
		(deviceid,caption,cpustatus,description,cpudeviceid,extclock,loadpercentage,maxclockspeed,name)
		VALUES
		(?,?,?,?,?,?,?,?,?)
	");
	$insert_windowsservices = $mysql->prepare("
		INSERT INTO tmp_windowsservices
		(deviceid,name,startmode,state,status,pathname,pid)
		VALUES
		(?,?,?,?,?,?,?)
	");
	$insert_windowsshares = $mysql->prepare("
		INSERT INTO tmp_windowsshares
		(deviceid,name,path)
		VALUES
		(?,?,?)
	");
	$insert_windowsphysicaldisk = $mysql->prepare("
		INSERT INTO tmp_windowsphysicaldisk
		(deviceid,bytespersector,caption,compressionmethod,description,diskdeviceid,dindex,interfacetype,mediatype,model,name,partitions,scsibus,scsilogicalunit,scsiport,scsitargetid,sectorspertrack,size,status,totalcylinders,totalheads,totalsectors,totaltracks,trackspercylinder)
		VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
	$insert_windowsprocess = $mysql->prepare("
		INSERT INTO tmp_windowsprocess
		(scantime,deviceid,pid,description,name,execpath,commandline)
		VALUES
		(?,?,?,?,?,?,?)
	");
	$insert_windowshba = $mysql->prepare("
		INSERT INTO tmp_windowshba
		(deviceid,scantime,adapterid,hbastatus,nodewwn,vendorspecificid,numberofport,manufacturer,serialnumber,model,modeldescription,nodesymbolicname,hardwareversion,driverversion,optionromversion,firmwareversion,drivername,mfgdomain,instancename)
		values
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
	$insert_windowshbaport = $mysql->prepare("
		INSERT INTO tmp_windowshbaport
		(deviceid,scantime,portid,hbastatus,nodewwn,portwwn,fcid,porttype,portstate,portsupportspeed,portspeed,portmaxfs,portfabname,portnumdisc,instancename)
		values
		(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	");
	$insert_win_cpu_info = $mysql->prepare("
		INSERT INTO tmp_win_cpu_info
		(deviceid,cpuid,cores,logicalprocessors)
		values
		(?,?,?,?)
	");
	## old windowsdisks format
	$insert_windowsdisks_old = $mysql->prepare_cached("
		INSERT INTO tmp_windowsdisks
		(deviceid,description,diskdeviceid,freespace,size)
		VALUES
		(?,?,?,?,?)
	");
	## new windowsdisks format (with drivetype)
	$insert_windowsdisks = $mysql->prepare_cached("
		INSERT INTO tmp_windowsdisks
		(deviceid,drivetype,description,label,diskdeviceid,freespace,size)
		VALUES
		(?,?,?,?,?,?,?)
	");
	$insert_http_get_inventory = $mysql->prepare("
		INSERT INTO tmp_http_get_inventory
		(deviceid,protocol,content_type,webserver,content)
		VALUES
		(?,?,?,?,?)
	");
}

##
# collect WMI objects
##

$logger->debug("collecting WMI objects");

my (
	$win32_operatingsystem,
	$win32_computersystem,
	$win32_computersystemproduct,
	$win32_systemenclosure,
	$win32_bios,
	$win32_processor,
	$win32_diskdrive,
	$win32_volume,
	$win32_share,
	$win32_networkadapter,
	$win32_networkadapterconfiguration,
	$win32_service,
	$win32_process,
	$msfc_fcadapterhbaattributes,
	$msfc_fibreporthbaattributes,
	$app_registry_data,
	$headers,
	$content,
	$get_proto
);

eval {
	$win32_operatingsystem = $wmi->wmic('Win32_OperatingSystem', {
		fields => join(',', qw(
			Caption
			CSDVersion
			CSName
			FreePhysicalMemory
			InstallDate
			Manufacturer
			Name
			SerialNumber
			ServicePackMajorVersion
			ServicePackMinorVersion
			Version
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_operatingsystem)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_OperatingSystem', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_OperatingSystem');
	}

	$win32_computersystem = $wmi->wmic('Win32_ComputerSystem', {
		fields => join(',', qw(
			Domain
			DomainRole
			EnableDaylightSavingsTime
			Manufacturer
			Model
			Name
			NumberOfProcessors
			PartOfDomain
			TotalPhysicalMemory
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_computersystem)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_ComputerSystem', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_ComputerSystem');
	}

	$win32_computersystemproduct = $wmi->wmic('Win32_ComputerSystemProduct', {
		fields => join(',', qw(
			Name
			SKUNumber
			UUID
			Vendor
			Version
		)),
		vclass => 'incomplete'
	});

	$win32_bios = $wmi->wmic('Win32_Bios', {
		fields => 'SerialNumber',
		vclass => 'fallback'
	});

	$win32_systemenclosure = $wmi->wmic('Win32_SystemEnclosure', {
		fields => 'SerialNumber',
		vclass => 'incomplete'
	});

	## fields NOT enumerated, due to field incompatibility between <=2003 and >2003
	$win32_processor = $wmi->wmic('Win32_Processor', { vclass => 'fail' });
	unless (riscUtility::check_return($win32_processor)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_Processor', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_Processor');
	}

	$win32_diskdrive = $wmi->wmic('Win32_DiskDrive', {
		fields => join(',', qw(
			BytesPerSector
			Caption
			CompressionMethod
			Description
			DeviceID
			Index
			InterfaceType
			MediaType
			Model
			Name
			Partitions
			SCSIBus
			SCSILogicalUnit
			SCSIPort
			SCSITargetID
			SectorsPerTrack
			Size
			Status
			TotalCylinders
			TotalHeads
			TotalSectors
			TotalTracks
			TracksPerCylinder
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_diskdrive)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_DiskDrive', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_DiskDrive');
	}

	$win32_volume = $wmi->wmic('Win32_Volume', {
		fields => join(',', qw(
			DriveLetter
			Caption
			FreeSpace
			Capacity
			DriveType
			Label
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_volume)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_Volume', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_Volume');
	}

	$win32_share = $wmi->wmic('Win32_Share', {
		fields => join(',', qw(
			Name
			Path
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_share)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_Share', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_Share');
	}

	$win32_networkadapter = $wmi->wmic('Win32_NetworkAdapter', {
		fields => join(',', qw(
			AdapterType
			Description
			Index
			MACAddress
			Manufacturer
			Name
			NetConnectionID
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_networkadapter)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_NetworkAdapter', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_NetworkAdapter');
	}

	$win32_networkadapterconfiguration = $wmi->wmic('Win32_NetworkAdapterConfiguration', {
		fields => join(',', qw(
			Index
			DefaultTOS
			DHCPEnabled
			DHCPLeaseObtained
			DHCPLeaseExpires
			DHCPServer
			DNSDomain
			DNSHostName
			IPEnabled
			IPAddress
			IPXEnabled
			IPSubnet
			IPXAddress
			IPXNetworkNumber
			IPXVirtualNetNumber
		)),
		vclass => 'fail'
	});
	unless (riscUtility::check_return($win32_networkadapterconfiguration)) {
		$ul->error(
			sprintf(q(Failed to query WMI object '%s': %s), 'Win32_NetworkAdapterConfiguration', $wmi->err()),
			'query-failure'
		);
		query_failure_abort('Win32_NetworkAdapterConfiguration');
	}

	$win32_service = $wmi->wmic('Win32_Service', {
		fields => join(',', qw(
			Name
			StartMode
			State
			Status
			PathName
			ProcessId
		)),
		vclass => 'incomplete'
	});

	## running processes are peformance data, but we can do a poll here
	##   in order to seed the data for the device should it be licensed
	## the 'inventory-process-collection' feature flag enables or disables
	##   the collection of these data, if true it is collected
	## when collecting it, we can optionally omit process arguments from
	##   the collected data in order to mitigate the possibility of
	##   collecting passwords or other sensitive data in the command line
	## the 'no-process-args' feature flag controls whether this is
	##   collected

	my $feature_do_inventory_processes = riscUtility::checkfeature('inventory-process-collection');
	if (defined($feature_do_inventory_processes)) {
		$do_inventory_processes = $feature_do_inventory_processes;
	}

	if ($do_inventory_processes) {
		my $process_fields = join(',', 'ProcessId', 'Name', 'Description', 'ExecutablePath');

		unless (riscUtility::checkfeature('no-process-args')) {
			$process_fields = join(',', $process_fields, 'CommandLine');
		}

		$win32_process = $wmi->wmic('Win32_Process', {
			fields => $process_fields,
			vclass => 'fail'
		});
		unless (riscUtility::check_return($win32_process)) {
			$ul->error(
				sprintf(q(Failed to query WMI object '%s': %s), 'Win32_Process', $wmi->err()),
				'query-failure'
			);
			query_failure_abort('Win32_Process');
		}
	}

	$app_registry_data = $wmi->registry_applications();

	## this inserts into a perf table, but even if perf is disabled and/or a
	## device is unlicensed, the tables will be uploaded if they have any
	## content. the agg script(s) will then be triggered as they normally would.
	my $displaydns_retval = eval { $wmi->displaydns() };
	if($@) {
		$ul->error('displaydns died: ' . $@);
	}
	elsif(!$displaydns_retval->{status}) {
		$ul->error('displaydns failed: ' .  $displaydns_retval->{detail});
	}

	$msfc_fcadapterhbaattributes = $wmi->wmic('MSFC_FCAdapterHBAAttributes', {
		options => [ q( --namespace='root\wmi' ) ],
		vclass  => 'explore'
	});

	$msfc_fibreporthbaattributes = $wmi->wmic('MSFC_FibrePortHBAAttributes', {
		options => [ q( --namespace='root\wmi' ) ],
		vclass  => 'explore'
	});

	#try to query a webserver
	$logger->debug('HTTP GET');
	$ua->timeout(5);
	$get_proto = 'http';
	my $url = $get_proto . '://' . $target;

	my @head_res = head $url;
	$headers->{'content_type'}    = $head_res[0];
	$headers->{'document_length'} = $head_res[1];
	$headers->{'modified_time'}   = $head_res[2];
	$headers->{'expires'}         = $head_res[3];
	$headers->{'server'}          = $head_res[4];

	($content = get $url) || ($content = 'timed out or did not respond');

	if ($VALIDATE) {
		if ($content eq 'timed out or did not respond') {
			push(@{ $wmi->{'validator_commands'} }, {
				type    => 'HTTP',
				command => 'HTTP GET /',
				result  => $wmi->{'validator'}->cmdstatus_name('explore')
			});
		} else {
			push(@{ $wmi->{'validator_commands'} }, {
				type    => 'HTTP',
				command => 'HTTP GET /',
				result  => $wmi->{'validator'}->cmdstatus_name('success')
			});
		}
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault collecting WMI objects: %s', $@));
}

if ($VALIDATE) {
	$validator->log("<h4>INVENTORY COMMANDS</h4>\n", 0);
	$validator->log("<table>\n",                     0);
	foreach my $cmd (@{ $wmi->{'validator_commands'} }) {
		$validator->log(
			"<tr><td>$cmd->{'type'}</td><td class='validation-command'>$cmd->{'command'}</td><td class='$cmd->{'result'}'>$cmd->{'result'}</td></tr>\n",
			1
		);
	}
	if (($wmi->{'validator_errors'}) and (scalar @{ $wmi->{'validator_errors'} } > 0)) {
		my $failure_condition;
		foreach my $failure (@{ $wmi->{'validator_errors'} }) {
			my $result = $failure->{'class'};
			$failure_condition .= <<END;
<p><table>
	<tr><td class='with-border'>Reason</td><td class='$result'>Command Failure</td></tr>
	<tr><td class='with-border'>Result</td><td class='$result'>$result</td></tr>
	<tr><td class='with-border'>Type</td><td>$failure->{'type'}</td></tr>
	<tr><td class='with-border'>Command</td><td class='validation-command'>$failure->{'command'}</td></tr>
	<tr><td class='with-border'>Output</td><td class='validation-command'>$failure->{'error'}</td></tr>
</table></p>
END
		}
		print STDOUT "$failure_condition";
	}
	$validator->log("</table>\n", 0);
	$validator->finish();
	$validator->exit();
}

##
# parse and insert objects
##

$logger->debug('parsing and inserting WMI data');

## Win32_OperatingSystem (windowsos)
eval {
	foreach my $os (@{$win32_operatingsystem}) {
		$insert_windowsos->execute(
			$deviceid,
			$os->{'Caption'},
			$os->{'CSDVersion'},
			$os->{'CSName'},
			$os->{'FreePhysicalMemory'},
			$os->{'InstallDate'},
			$os->{'Manufacturer'},
			$os->{'Name'},
			$os->{'SerialNumber'},
			$os->{'ServicePackMajorVersion'},
			$os->{'ServicePackMinorVersion'},
			$os->{'Version'});
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_OperatingSystem', $@));
}

## Win32_ComputerSystemProduct (computerhardware)
eval {
	foreach my $hard (@{$win32_computersystemproduct}) {
		#it seems that the win32_bios object is more reliable for serial number, so we'll try that and fall back to sys enclosure if it is empty
		#my $hardidentifyingnumber = $hard->{identifyingnumber};
		my $hardidentifyingnumber = @$win32_bios[0]->{'SerialNumber'};
		if ((not defined $hardidentifyingnumber) || $hardidentifyingnumber eq '') {
			$hardidentifyingnumber = @$win32_systemenclosure[0]->{'SerialNumber'};
		}

		$insert_computerhardware->execute(
			$deviceid,
			riscUtility::strip_cntrl_characters($hardidentifyingnumber),
			riscUtility::strip_cntrl_characters($hard->{'Name'}),
			riscUtility::strip_cntrl_characters($hard->{'SKUNumber'}),
			riscUtility::strip_cntrl_characters($hard->{'UUID'}),
			riscUtility::strip_cntrl_characters($hard->{'Vendor'}),
			riscUtility::strip_cntrl_characters($hard->{'Version'})
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_ComputerSystemProduct', $@));
}

## Win32_ComputerSystem (computersystem)
eval {
	foreach my $comp (@{$win32_computersystem}) {
		$insert_computersystem->execute(
			$deviceid,
			$comp->{'Domain'},
			$comp->{'DomainRole'},
			$comp->{'EnableDaylightSavingsTime'},
			riscUtility::strip_cntrl_characters($comp->{'Manufacturer'}),	## targeted sanitization for now
			riscUtility::strip_cntrl_characters($comp->{'Model'}),
			$comp->{'Name'},
			$comp->{'NumberOfProcessors'},
			$comp->{'PartOfDomain'},
			$comp->{'TotalPhysicalMemory'});
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_ComputerSystem', $@));
}

## Win32_NetworkAdapter (windowsnetwork)
eval {
	foreach my $nic (@{$win32_networkadapter}) {
		my $netadaptertype   = $nic->{'AdapterType'};
		my $netdescription   = $nic->{'Description'};
		my $netindex         = $nic->{'Index'};
		my $netmacaddress    = $nic->{'MACAddress'};
		my $netmanufacturer  = $nic->{'Manufacturer'};
		my $netname          = $nic->{'Name'};
		my $netconnectionid  = $nic->{'NetConnectionID'};
		my $defaulttos       = '';
		my $dhcpenabled      = '';
		my $dhcpleaseobtain  = '';
		my $dhcpleaseexpires = '';
		my $dhcpserver       = '';
		my $dnsdomain        = '';
		my $dnshostname      = '';
		my $ipenabled        = '';
		my $ipxenabled       = '';
		my $ipaddress        = '';
		my $subnetmask       = '';
		my $ipxaddress       = '';
		my $ipxnet           = '';
		my $ipxvirtualnet    = '';
		foreach my $netsetup (@{$win32_networkadapterconfiguration}) {

			if ($netindex == $netsetup->{'Index'}) {
				$defaulttos       = $netsetup->{'DefaultTOS'};
				$dhcpenabled      = $netsetup->{'DHCPEnabled'};
				$dhcpleaseobtain  = WMIDate($netsetup->{'DHCPLeaseObtained'});
				$dhcpleaseexpires = WMIDate($netsetup->{'DHCPLeaseExpires'});
				$dhcpserver       = $netsetup->{'DHCPServer'};
				$dnsdomain        = $netsetup->{'DNSDomain'};
				$dnshostname      = $netsetup->{'DNSHostName'};
				$ipenabled        = $netsetup->{'IPEnabled'};
				$ipaddress        = $netsetup->{'IPAddress'};
				$ipxenabled       = $netsetup->{'IPXEnabled'};
				$subnetmask       = $netsetup->{'IPSubnet'};
				$ipxaddress       = $netsetup->{'IPXAddress'};
				$ipxnet           = $netsetup->{'IPXNetworkNumber'};
				$ipxvirtualnet    = $netsetup->{'IPXVirtualNetNumber'};
			} else {
				next;
			}
			$insert_windowsnetwork->execute(
				$deviceid,
				$netadaptertype,
				$netdescription,
				$netindex,
				$netmacaddress,
				$netmanufacturer,
				$netname,
				$netconnectionid,
				$defaulttos,
				$dhcpenabled,
				$dhcpleaseobtain,
				$dhcpleaseexpires,
				$dhcpserver,
				$dnsdomain,
				$dnshostname,
				$ipenabled,
				$ipxenabled,
				$ipaddress,
				$subnetmask,
				$ipxaddress,
				$ipxnet,
				$ipxvirtualnet
			);
			pop_windows_ip($deviceid, $netindex, $ipaddress) if $ipaddress;
		}
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_NetworkAdapter', $@));
}

## Win32_Processor (windowsprocessor, win_cpu_info)
## NOTE on Server 2003 (and earlier?)
## https://support.microsoft.com/en-us/help/932370/the-number-of-physical-hyperthreading-enabled-processors-or-the-number
## the Win32_ComputerSystem and Win32_Processor objects behave differently on <=2003 vs >2003
## the Win32_ComputerSystem.NumberOfProcessors value in 2003 is a count of logical, post 2003 it is a count of physical
## the Win32_Processor object contains an instance for each logical in 2003, post 2003 contains one for each physical package
## the Win32_Processor instance in 2003 does not contain the NumberOfCores or NumberOfLogicalProcessors values
## the logic is this:
##	if the NumberOfLogicalProcessors value is not present in the data, then we have a <=2003 logical processor object
##	if the NumberOfLogicalProcessors value is present, then we have a >2003 physical package object
##	if the $numofcores or $numoflogicals values are undefined, we set them to 1
## this results in <=2003 systems representing each logical processor as a package containing a single core and thread
## downstream should be able to continue the behavior of calculating total logical count as `sum(win_cpu_info.logicalprocessors) where deviceid = x`
eval {
	foreach my $proc (@{$win32_processor}) {
		$insert_windowsprocessor->execute(
			$deviceid,
			$proc->{'Caption'},
			$proc->{'CPUStatus'},
			$proc->{'Description'},
			$proc->{'DeviceID'},
			$proc->{'ExtClock'},
			$proc->{'LoadPercentage'},
			$proc->{'MaxClockSpeed'},
			$proc->{'Name'});
		$insert_win_cpu_info->execute(
			$deviceid, $proc->{'DeviceID'},
			(defined($proc->{'NumberOfCores'}))             ? $proc->{'NumberOfCores'}             : 1,
			(defined($proc->{'NumberOfLogicalProcessors'})) ? $proc->{'NumberOfLogicalProcessors'} : 1
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_Processor', $@));
}

## Win32_Service (windowsservices)
eval {
	foreach my $serv (@{$win32_service}) {
		## output may contain additional CLASS headers for subclasses and column headers
		next if ($serv->{'Name'} =~ /^CLASS: Win32/);
		next if ($serv->{'StartMode'} eq 'StartMode');
		$insert_windowsservices->execute(
			$deviceid,
			$serv->{'Name'},
			$serv->{'StartMode'},
			$serv->{'State'},
			$serv->{'Status'},
			$serv->{'PathName'},
			$serv->{'ProcessId'}
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_Service', $@));
}

## Win32_Volume (windowsdisks)
my $driveTypeMap = {
	0 => 'Uknown',
	1 => 'No Root Directory',
	2 => 'Removable Disk',
	3 => 'Local Disk',
	4 => 'Network Drive',
	5 => 'Compact Disk',
	6 => 'RAM Disk'
};

eval {
	foreach my $disk (@{$win32_volume}) {
		my $diskdescription = $driveTypeMap->{ $disk->{'DriveType'} };
		my $diskdeviceid    = $disk->{'DriveLetter'};
		$diskdeviceid = $disk->{'Caption'} if $diskdeviceid eq '(null)';

		eval {
			$insert_windowsdisks->execute(
				$deviceid,
				$disk->{'DriveType'},
				$diskdescription,
				$disk->{'Label'},
				$diskdeviceid,
				$disk->{'FreeSpace'},
				$disk->{'Capacity'}
			);
		}; if ($@) {
			my $win32_logicaldisk = $wmi->wmic('Win32_LogicalDisk');
			foreach my $disk (@{$win32_logicaldisk}) {
				$insert_windowsdisks_old->execute(
					$deviceid,
					$disk->{'Description'},
					$disk->{'DeviceID'},
					$disk->{'FreeSpace'},
					$disk->{'Size'}
				);
			}
			last;
		}
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_Volume/Win32_LogicalDisk', $@));
}

## Win32_DiskDrive (windowsphysicaldisk)
eval {
	foreach my $physdisk (@{$win32_diskdrive}) {
		$insert_windowsphysicaldisk->execute(
			$deviceid,
			$physdisk->{'BytesPerSector'},
			$physdisk->{'Caption'},
			$physdisk->{'CompressionMethod'},
			$physdisk->{'Description'},
			$physdisk->{'DeviceID'},
			$physdisk->{'Index'},
			$physdisk->{'InterfaceType'},
			$physdisk->{'MediaType'},
			$physdisk->{'Model'},
			$physdisk->{'Name'},
			$physdisk->{'Partitions'},
			$physdisk->{'SCSIBus'},
			$physdisk->{'SCSILogicalUnit'},
			$physdisk->{'SCSIPort'},
			$physdisk->{'SCSITargetID'},
			$physdisk->{'SectorsPerTrack'},
			$physdisk->{'Size'},
			$physdisk->{'Status'},
			$physdisk->{'TotalCylinders'},
			$physdisk->{'TotalHeads'},
			$physdisk->{'TotalSectors'},
			$physdisk->{'TotalTracks'},
			$physdisk->{'TracksPerCylinder'});
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_DiskDrive', $@));
}

## Win32_Share (windowsshares)
eval {
	foreach my $share (@{$win32_share}) {
		$insert_windowsshares->execute(
			$deviceid,
			$share->{'Name'},
			$share->{'Path'}
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_Share', $@));
}

## Win32_Process (windowsprocess)
eval {
	if ($do_inventory_processes) {
		foreach my $process (@{$win32_process}) {
			my $scantime = time();
			my $command_line;
			if (riscUtility::checkfeature('no-process-args')) {
				$command_line = join(' ', $process->{'ExecutablePath'}, $no_process_args_indicator);
			} else {
				$command_line = $process->{'CommandLine'};
			}
			$insert_windowsprocess->execute(
				$scantime, $deviceid, $process->{'ProcessId'},
				$process->{'Name'},
				$process->{'Description'},
				$process->{'ExecutablePath'},
				$command_line
			);
		}
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'Win32_Process', $@));
}

## MSFC_FCAdapterHBAAttributes (windowshba)
eval {
	foreach my $hba (@{$msfc_fcadapterhbaattributes}) {
		my $scantime = time();
		my $man      = $hba->{'Manufacturer'};
		my $ser      = $hba->{'SerialNumber'};
		my $mod      = $hba->{'Model'};
		my $moddesc  = $hba->{'ModelDescription'};
		my $nodewwn  = convertWWN($hba->{'NodeWWN'});
		my $id       = $hba->{'UniqueAdapterId'};
		my $nodesn   = $hba->{'NodeSymbolicName'};
		my $hardv    = $hba->{'HardwareVersion'};
		my $dver     = $hba->{'DriverVersion'};
		my $fver     = $hba->{'FirmwareVersion'};
		my $vsid     = $hba->{'VendorSpecificID'};
		my $nop      = $hba->{'NumberOfPorts'};
		my $dname    = $hba->{'DriverName'};
		my $mfgd     = $hba->{'MfgDomain'};
		my $status   = $hba->{'HBAStatus'};
		my $instance = $hba->{'InstanceName'};
		$insert_windowshba->execute(
			$deviceid,
			$scantime,
			$id,
			$status,
			$nodewwn,
			$vsid,
			$nop,
			$man,
			$ser,
			$mod,
			$moddesc,
			$nodesn,
			$hardv,
			$dver,
			'',
			$fver,
			$dname,
			$mfgd,
			$instance
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'MSFC_FCAdapterHBAAttributes', $@));
}

## MSFC_FibrePortHBAAttributes (windowshbaport)
eval {
	foreach my $port (@{$msfc_fibreporthbaattributes}) {
		my $scantime = time();
		my $pid      = $port->{'UniquePortId'};
		my $status   = $port->{'HBAStatus'};
		my $attr     = $port->{'Attributes'};
		my (
			$nodeWWN,
			$portWWN,
			$fcid,
			$porttype,
			$portstate,
			$portcos,
			$portfc4,
			$portactivefc4,
			$portsupportspeed,
			$portspeed,
			$portmaxfs,
			$portfabname,
			$portnumdisc
		);
		if (ref($attr) eq 'HASH') {
			$nodeWWN          = convertWWN($attr->{'NodeWWN'});
			$portWWN          = convertWWN($attr->{'PortWWN'});
			$fcid             = convertFCID($attr->{'PortFcId'});
			$porttype         = $attr->{'PortType'};
			$portstate        = $attr->{'PortState'};
			$portcos          = $attr->{'PortSupportedClassofService'};
			$portfc4          = $attr->{'PortSupportedFc4Types'};
			$portactivefc4    = $attr->{'PortActiveFc4Types'};
			$portsupportspeed = $attr->{'PortSupportedSpeed'};
			$portspeed        = $attr->{'PortSpeed'};
			$portmaxfs        = $attr->{'PortMaxFrameSize'};
			$portfabname      = convertWWN($attr->{'FabricName'});
			$portnumdisc      = $attr->{'NumberofDiscoveredPorts'};
		} else {
			$logger->warn('port does not support attributes');
		}
		my $instance = $port->{'InstanceName'};
		$insert_windowshbaport->execute(
			$deviceid,
			$scantime,
			$pid,
			$status,
			$nodeWWN,
			$portWWN,
			$fcid,
			$porttype,
			$portstate,
			$portsupportspeed,
			$portspeed,
			$portmaxfs,
			$portfabname,
			$portnumdisc,
			$instance
		);
	}
}; if ($@) {
	$logger->error(sprintf('swallowed fault processing %s: %s', 'MSFC_FibrePortHBAAttributes', $@));
}

eval {
	my $ins_registry = $mysql->prepare("
		INSERT INTO tmp_windowsapplicationregistry
		(deviceid,appkey,regkey,regvalue)
		VALUES
		(?,?,?,?)
	");

	## populate the legacy table for compatibility
	my $ins_windowsapplications = $mysql->prepare("
		INSERT INTO tmp_windowsapplications
		(deviceid,application,version,appkey)
		VALUES
		(?,?,?,?)
	");

	my %windowsapplications;
	foreach my $app (@{ $app_registry_data }) {
		my ($key, $attr, $val) = @{ $app };

		unless (defined($key) and defined($attr) and defined($val)) {
			$logger->warn(sprintf(
				'skipping bad application entry: %s',
				Dumper($app),
			));
			next;
		}

		eval {
			$ins_registry->execute(
				$deviceid,
				$key,
				$attr,
				$val,
			);
		}; if ($@) {
			$logger->error(sprintf(
				'swallowed fault inserting application entry (%s, %s, %s): %s',
				$key,
				$attr,
				$val,
				$@,
			));
			next;
		}

		if ($attr eq 'DisplayName') {
			$windowsapplications{$key}->{'application'} = $val;
		} elsif ($attr eq 'DisplayVersion') {
			$windowsapplications{$key}->{'version'} = $val;
		}
	}

	foreach my $key (keys %windowsapplications) {
		unless (($windowsapplications{$key}->{'application'})
			and ($windowsapplications{$key}->{'version'}))
		{
			$logger->error(sprintf(
				'skipping bad windowsapplications entry: %s %s',
				$key,
				Dumper($windowsapplications{$key}),
			));
			next;
		}

		eval {
			$ins_windowsapplications->execute(
				$deviceid,
				$windowsapplications{$key}->{'application'},
				$windowsapplications{$key}->{'version'},
				$key,
			);
		}; if ($@) {
			$logger->error(sprintf(
				'swallowed fault inserting windowsapplications entry (%s, %s, %s): %s',
				$key,
				$windowsapplications{$key}->{'application'},
				$windowsapplications{$key}->{'version'},
				$@,
			));
			next;
		}
	}
}; if ($@) {
	$logger->error(sprintf(
		'swallowed fault processing %s: %s',
		'registry applications',
		$@,
	));
}

$insert_http_get_inventory->execute($deviceid, $get_proto, $headers->{'content_type'}, $headers->{'server'}, $content);

$logger->debug('removing any existing device records');
$mysql->do("call remove_win_device($deviceid)");

$logger->debug('removing autoincrements from tmp tables');
$mysql->do("ALTER TABLE tmp_win_cpu_info MODIFY COLUMN idwin_cpu_info INT(11)");
$mysql->do("ALTER TABLE tmp_win_cpu_info DROP PRIMARY KEY");
$mysql->do("UPDATE tmp_win_cpu_info SET idwin_cpu_info = NULL");

$logger->debug('inserting from tmp tables to permanent');
map {
	eval {
		$mysql->do(sprintf('INSERT INTO %s SELECT * FROM tmp_%s', $_, $_));
	}; if ($@) {
		$logger->error(sprintf('failed to roll %s from tmp: %s', $_, $@));
	}
} @TABLES;

## update our inventory log
## if we already have an inventory timestamp, then this must be an updating run
if ($invlog->{'inventory'}) {
	$invlog->{'updated'} = $invlogtime;
} else {
	$invlog->{'inventory'} = $invlogtime;
}

$logger->debug('committing inventory log');
riscUtility::updateInventoryLog($mysql, $invlog);

## update dataset_log
$logger->debug('updating dataset_log with success');
map { $dl->{$_}->success() } (keys %{ $dl });

## finish
$logger->info('complete');
$mysql->disconnect();
exit(EXIT_SUCCESS);

sub WMIDate {
	my $value = shift;
	return "0" if ($value eq '(null)');
	chomp $value;
	my $datetimestring =
	    substr($value, 0, 4) . "-"
	  . substr($value, 4,  2) . "-"
	  . substr($value, 6,  2) . " "
	  . substr($value, 8,  2) . ":"
	  . substr($value, 10, 2) . ":"
	  . substr($value, 12, 2);
	return $datetimestring;
}

sub convertWWN {
	my $nameArray  = shift;
	my $namereturn = '';
	if ($nameArray =~ /\(|\)/) {
		$nameArray =~ s/\(|\)//g;
		my @nameArray = split(',', $nameArray);
		$nameArray = \@nameArray;
	}
	foreach my $name (@{$nameArray}) {
		if ($name > 10) {
			$namereturn = $namereturn . sprintf("%x", $name) . ":";
		} else {
			$namereturn = $namereturn . "0" . sprintf("%x", $name) . ":";
		}
	}
	return $namereturn;
}

sub convertFCID {
	my $input = shift;
	my $return = sprintf("%x", $input);
	return $return;
}

sub pop_windows_ip {
	my $deviceid = shift;
	my $intindex = shift;
	my $ipString = shift;

	$ipString =~ s/[\(\)]//g;
	my @ips = split(/,/, $ipString);
	foreach my $ip (@ips) {
		$insert_windows_ip->execute(
			$deviceid,
			$intindex,
			$ip
		);
	}
}

## Aborts the program if a WMI query has failed to return data.
## If the data is populated, or if we are in validation mode, returns without
## doing anything.
## This is intended to prevent a partially-formed record from being created,
## or replacing an existing record with partial information
## When this occurs, we log to syslog, the inventoryerrors table, create a
## couple collection_user_log entries, and update the inventorylog table.
sub query_failure_abort {
	my ($wmi_class) = @_;
	my $error = sprintf(
		'aborting due to failed query to %s: %s',
		$wmi_class,
		($wmi->err()) ? $wmi->err() : 'unknown error'
	);
	$logger->error($error);
	$inventoryerrors->execute($deviceid, $target, $cred->{'user'}, $error, time());
	$ul->error(COLLECTION_ABORT_MSG, 'not-eligible');
	riscUtility::updateInventoryLog($mysql, $invlog);
	exit(EXIT_FAILURE);
}
