#!/usr/bin/env perl
use strict;
use Data::Dumper;
use MIME::Base64 qw( encode_base64 decode_base64 );

use RISC::visio;
use RISC::riscUtility;
use RISC::riscWebservice;
use RISC::Collect::Logger;
use RISC::Event qw( collector_alarm );
use RISC::Collect::PerfScheduler;

my $logger = RISC::Collect::Logger->new('inventory::admin');

my $assessmentid = shift;

$SIG{CHLD} = "IGNORE";

# Load a sample of up to 5 devices attached to each credential, and perform a
# connection test to each device. If a credential fails all of its tests,
# consider all devices attached to that credential inelligible and filter those
# devices from the query results. Only used during revision mode.
my $do_valid_cred_filter = 0; # Default off

# Automatically populate subnets based on device routing tables
my $add_routes_subnets = 0;

## this is the script return that can be safely returned to RISC (dataplane separation)
##  this will be modified during execution if something other than 'complete' needs to be returned
my $riscreturn = 'complete';

$logger->info('begin');

eval {
	my $totalsleepmain3 = 96;
	while (riscUtility::checkProcess("disco") > 1 && $totalsleepmain3 > 0) {
		$logger->debug("sleeping 300 seconds for 'disco' processes to finish");
		sleep 300;
		$totalsleepmain3--;
	}

	my $totalsleepmain = 144;
	while (riscUtility::checkProcess("inventory") > 1) {
		$logger->debug("sleeping 300 seconds for 'inventory' processes to finish");
		sleep 300;
		$totalsleepmain--;
		if ($totalsleepmain == 0) {
			$logger->error("timeout waiting for 'inventory' processes to finish");
			die "Timed out process waiting for inventory scripts to finish";
		}
	}

	my $mysql = riscUtility::getDBH('RISC_Discovery',1);

	# Load feature flags
	my $ldb = riscUtility::getDBH('risc_discovery');

	$do_valid_cred_filter = 1 if (riscUtility::checkfeature('inventory-credential-filter', $ldb)); # Must be the integer 1, cannot be any other true value
	$add_routes_subnets = 1 if (riscUtility::checkfeature('add-routes-subnets', $ldb));

	$ldb->disconnect();

	#whether or not this is an 'update' scan changes a few things, so we need to determine that first
	my $update = riscUtility::checkUpdatingInventory();
	if ($update) {
		$logger->info('running in revisioned mode');
		$update = 1;
	} else {
		$logger->info('running in standard mode');
		$update = 0;
		# We _must_ disable this as well. Otherwise, we will not build the credential
		# filtering list but will attempt to perform the filter in the queries below.
		# Then, if the credential filtering feature is on but we are not running in
		# revision mode, we will inadvertently skip all devices.
		$do_valid_cred_filter = 0;
	}


	#now we need to get a list of credentials to be used in this scan if we are updating
	my $credidString = 0;
	if ($update and $do_valid_cred_filter) {
		$logger->info('filtering to valid credentials due to inventory-credential-filter feature flag');
		$credidString = buildCredList($mysql);
		$logger->info("credids usable: $credidString");
	}

	$logger->info('pausing performance collection');
	my $perf_scheduler = RISC::Collect::PerfScheduler->new();
	$perf_scheduler->pause('all', { kill => 1 });

	my $snmpQuery = $mysql->prepare("
		select deviceid,riscdevice.ipaddress,credentialid,technology,'network' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'snmp'
			and (
				(layer2 = 1 and layer1 = 0)
				or (sysdescription like '%netvanta%')
				or (sysdescription like '%PIX%')
				or (sysdescription like '%DGS-%')
				or (sysdescription like '%adtran%')
				or (sysdescription like '%BayStack%')
				or (sysdescription like '%nortel%')
				or (sysdescription like '%netscreen%')
				or (sysdescription like '%juniper%')
				or (sysdescription like '%foundry%')
				or (sysdescription like '%allied%')
				or (sysdescription like '%asante%')
				or (sysdescription like '%aruba%')
				or (sysdescription like '%PowerConnect%')
				or (sysdescription like '%extreme%')
				or (sysdescription like '%cisco%')
				or (sysdescription like '%sonic%')
				or (sysdescription like '%3com%')
				or (sysdescription like '%Firewall%')
				or (sysdescription like '%Cabletron%')
				or (sysdescription like '%HPJ%')
				or (sysdescription like '%procurve%')
				or (sysdescription like '%Enterasys%')
				or (sysdescription like '%Ethernet Stackable Switching System%')
				or (sysdescription like '%Force10%')
				or (sysdescription like '%wndap%')
				or (sysdescription like '%meraki%')
				or (sysdescription like '%brocade%')
				or (sysdescription like '%Ethernet Routing Switch%')
				or (sysdescription like '%Netscaler%')
			)
			and if($update,1,deviceid not in (select deviceid from networkdeviceinfo))
			and if($update,1,deviceid not in (select deviceid from gensrvserver))
			and if($update,1,deviceid not in (select deviceid from windowsos))
			and (macaddr like '%:%')
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
		group by deviceid
	");
	$snmpQuery->execute();

	my $winQuery = $mysql->prepare_cached("
		select riscdevice.deviceid,ipaddress,wmi,credentialid,technology,'windows' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'windows'
			and if($update,1,riscdevice.deviceid not in (select deviceid from windowsos))
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
		group by deviceid
	");
	$winQuery->execute();

	my $genSRVSSHQuery = $mysql->prepare("
		select riscdevice.deviceid,riscdevice.ipaddress,credentialid,technology,'gensrvssh' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'gensrvssh'
			and if($update,1,deviceid not in (select deviceid from gensrvserver))
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
		group by deviceid
	");
	$genSRVSSHQuery->execute();

	my $genSRVSNMPQuery = $mysql->prepare_cached("
		select riscdevice.deviceid,riscdevice.ipaddress,credentialid,technology,'gensrvsnmp' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'snmp'
			and (
				sysdescription like '%sunOS%'
				or (
					sysdescription like '%linux%'
					and sysdescription not like '%cisco%'
					and sysdescription not like '%Dell Networking%'
				)
				or (sysdescription like '%HP3000%')
				or (sysdescription like '%FreeBSD%')
				or (sysdescription like '%OpenBSD%')
				or (sysdescription like '%HP-UX%')
				or (sysdescription like '%Operating System Runtime AIX%')
			)
			and if($update,1,deviceid not in (select deviceid from gensrvserver))
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
		group by deviceid
	");
	$genSRVSNMPQuery->execute();

	my $fcQuery = $mysql->prepare_cached("
		select riscdevice.deviceid,riscdevice.ipaddress,credentialid,technology,'fibrechannel' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'snmp'
			and (
				sysdescription like '%mds%'
				or sysdescription like '%fibre%'
				or sysdescription like '%connectrix%'
				or sysdescription like '%san-os%'
			)
			and if($update,1,deviceid not in (select distinct(deviceid) from fcfxporttable))
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
	");
	$fcQuery->execute();

	my $ciscoTPQuery = $mysql->prepare_cached("
		select deviceid,riscdevice.ipaddress,credentialid,technology,'telepresence' as category
		from riscdevice
		inner join credentials using(deviceid)
		left join ipranges on inet_aton(riscdevice.ipaddress) between startipint and endipint
		where credentials.technology = 'snmp'
			and sysdescription like '%telepresence%'
			and if($update,1,deviceid not in (select deviceid from tpethernetperipheralstatus))
			and if($do_valid_cred_filter,credentialid in ($credidString),1)
			and if($update,ipranges.id is not null,1)
	");
	$ciscoTPQuery->execute();

	## array of all devices to process; the processing plan
	my @devices;

	## hash keyed first on device class, then deviceid
	## used to enforce a device only existing in one device class
	my %device_class_lookup;

	## push all infrastructure devices into the processing plan
	while (my $ref = $snmpQuery->fetchrow_hashref()) {
		$device_class_lookup{'infrastructure'}{$ref->{'deviceid'}}++;
		push(@devices, $ref);
	}

	## push all windows devices into the processing plan
	while (my $ref = $winQuery->fetchrow_hashref()) {
		push(@devices, $ref);
	}

	## push all SSH-based generic servers into the processing plan
	while (my $ref = $genSRVSSHQuery->fetchrow_hashref()) {
		push(@devices, $ref);
	}

	## push all SNMP-based generic servers into the processing plan
	## exclude any devices that previously matched the infrastructure criteria
	while (my $ref = $genSRVSNMPQuery->fetchrow_hashref()) {
		if (exists($device_class_lookup{'infrastructure'}{$ref->{'deviceid'}})) {
			$logger->info(sprintf(
				'excluded deviceid %d from gensrv-snmp due to presence in infrastructure',
				$ref->{'deviceid'}
			));
		} else {
			push(@devices, $ref);
		}
	}

	## push all fibrechannel devices into the processing plan
	while (my $ref = $fcQuery->fetchrow_hashref()) {
		push(@devices, $ref);
	}

	## push all telepresence devices into the processing plan
	while (my $ref = $ciscoTPQuery->fetchrow_hashref()) {
		push(@devices, $ref);
	}

	my $totalrows = @devices;
	for (my $i = 0; $i < $totalrows; $i++) {
		my $totalsleep = 180;
		while (riscUtility::checkProcess("wininventory-detail") > 10 || riscUtility::checkProcess("inventory-detail") > 5 ) {
			$logger->debug('sleeping 10 seconds for a device collection slot ...');
			sleep 10;
			$totalsleep--;
			if ($totalsleep == 0) {
				$logger->error('killing all detail scripts due to timeout');
				`pkill -f detail`;
				collector_alarm(
					'inventory-admin-timeout',
					join('::', $0, 'main'),
					'timed out waiting on batch of detail scripts and killed them'
				);
			}
		}
		my $devIP	= $devices[$i]->{'ipaddress'};
		my $devID	= $devices[$i]->{'deviceid'};
		my $credID	= $devices[$i]->{'credentialid'};
		my $tech	= $devices[$i]->{'technology'};
		my $cat		= $devices[$i]->{'category'};
		my $pid		= fork();
		next unless $pid == 0;
		unless (defined($pid)) {
			$logger->error("fork failed: $!");
			die "fork failed: $!";
		}
		my $execstring	= '';
		$execstring	= "/usr/bin/perl /home/risc/winfiles/wininventory-detail.pl $devID $devIP $credID" if $tech eq 'windows';
		$execstring 	= "/usr/bin/perl /home/risc/inventory-detail.pl $devID $devIP $credID" if $tech eq 'snmp' && $cat eq 'network';
		$execstring 	= "/usr/bin/perl /home/risc/inventory-detail-gensrvssh.pl $devID $devIP $credID" if $tech eq 'gensrvssh' && $cat eq 'gensrvssh';
		$execstring 	= "/usr/bin/perl /home/risc/inventory-detail-gensrv.pl $devID $devIP $credID" if $tech eq 'snmp' && $cat eq 'gensrvsnmp';
		$execstring 	= "/usr/bin/perl /home/risc/inventory-detail-fc.pl $devID $devIP $credID" if $tech eq 'snmp' && $cat eq 'fibrechannel';
		$execstring 	= "/usr/bin/perl /home/risc/inventory-detail-tp.pl $devID $devIP $credID" if $tech eq 'snmp' && $cat eq 'telepresence';
		$logger->info($execstring);
		exec($execstring);
	}

	##Now, sleep to let everything finish.  Then clean out the windows duplicates
	##
	my $totalsleep2 = 360;
	while (riscUtility::checkProcess("wininventory-detail") >= 1 || riscUtility::checkProcess("inventory-detail") >= 1 ) {
		$logger->debug('sleeping for inventory processes to complete ...');
		sleep 10;
		$totalsleep2--;
		if ($totalsleep2 == 0) {
			riscUtility::killProcess("wininventory-detail");
			riscUtility::killProcess("inventory-detail");
			$logger->error('timed out waiting for details to complete and killed them');
			collector_alarm(
				'inventory-admin-timeout',
				join('::', $0, 'main'),
				'timed out waiting for all detail scripts to complete and killed them'
			);
		}
	}

	$mysql->disconnect();
	$mysql = riscUtility::getDBH('RISC_Discovery',1);

	#update inaccessibles that we have cdp data for
	$logger->info('updating reported network neighbors');
	$mysql->do("
		UPDATE riscdevice,cdp
		SET
			riscdevice.sysdescription = CONCAT('Inaccessible Device, Neighbor Description: ',cdp.neighborhostname,' Neighbor Described Platform:',cdp.neighborplatform)
		WHERE riscdevice.ipaddress=cdp.neighborip
			AND (
				riscdevice.sysdescription='unknown'
				OR riscdevice.sysdescription REGEXP 'Inaccessible Device'
			)
	");

	$logger->info('removing duplicate windows devices');
	removeWinDupes($mysql);

	$logger->info('updating mac manufacturers');
	system("mysql -urisc -prisc -e 'call RISC_Discovery.mac_manufacturer_update()'");

	$logger->info('removing duplicate snmp devices');
	removeSNMPDupes($mysql);

	$logger->info('running cli collection');
	eval {
		collectCLI($mysql);
	}; if ($@) {
		$logger->error("failure during cli collection: $@");
	}

	$logger->info('running vmware inventory');
	eval {
		my $vmwareInventoryCmd = "/usr/bin/perl /home/risc/vmware_runinventory.pl $assessmentid 0";
		$logger->debug($vmwareInventoryCmd);
		`$vmwareInventoryCmd`;
	}; if ($@) {
		$logger->error("failure during vmware collection: $@");
	}

	$logger->info('running callmanager inventory');
	eval {
		my $ccmInventoryCmd = "/usr/bin/perl /home/risc/ccm/RISCCCM_Documentation_JL.pl $assessmentid";
		$logger->debug($ccmInventoryCmd);
		system($ccmInventoryCmd);
	}; if ($@) {
		$logger->error("failure during callmanager collection: $@");
	}

	## TODO: replace this
	## this essentially queues win-event.pl to run once in one minute
	## the 'orig' interval is zero, meaning it will not be run again until the next inventory
	$logger->info('queueing windows event log collection');
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-172800);
	$year += 1900;
	$mon += 1;
	$mon < 10 and $mon = "0$mon";
	$mday < 10 and $mday = "0$mday";
	my $targetDate = $year.$mon.$mday;

	$perf_scheduler->restart('windows::event', {
		definition => {
			arguments	=> [ 1, 2, $targetDate ],
			counter		=> 1
		}
	});

	$logger->info('running database inventory');
	eval {
		my $dbinventorycmd = "/usr/bin/perl /home/risc/dbinventory.pl";
		$logger->debug($dbinventorycmd);
		`$dbinventorycmd`;
	}; if ($@) {
		$logger->error("failure during database collection: $@");
	}

	$logger->info('resetting scan mode to the default value');
	riscUtility::setUpdatingInventory();

	$mysql->disconnect();

	$logger->info('building visiodevices');
	visio::createVisioInfo();

	# now run NFS (must be after visio as it checks ips there to marry) and redo visio after
	$logger->info('processing nfs devices');
	my $run_nfs = "/usr/bin/perl /home/risc/buildNFSDevs.pl";
	$logger->debug($run_nfs);
	system($run_nfs);

	$logger->info('building visiodevices again');
	visio::createVisioInfo();


	$logger->info('building critical interfaces');
	my $critIntcmd = '/usr/bin/perl /home/risc/criticalIntPopulate.pl';
	eval {
		$logger->debug($critIntcmd);
		system($critIntcmd);
	}; if ($@) {
		$logger->error("failure during critical interfaces: $@");
	}

	$mysql = riscUtility::getDBH('RISC_Discovery',1);

	## Now run the subnets.pl script if enabled via its 'add-routes-subnets' feature flag
	if ($add_routes_subnets) {
		## only run if we have data in iproutes as it will delete any unscanned subnets from discoverystats and not replace them JB 03/04/2014
		my $routesQuery = $mysql->selectrow_hashref("select count(*) as totalc from iproutes");
		if ($routesQuery->{'totalc'} > 0) {
			$logger->info('running subnets');
			my $run_subnets = "/usr/bin/perl /home/risc/subnets.pl";
			$logger->debug($run_subnets);
			my $newsubs = `$run_subnets`;
		}
	}

	$logger->info('starting performance collection');
	$perf_scheduler->schedule('all');
	$perf_scheduler->resume('all');
}; if ($@) {
	$riscreturn = "failure during main block: $@";
	$logger->error($riscreturn);
}

$logger->info('complete');
print '||&||' . $riscreturn . '||&||';
exit(0);

sub removeWinDupes {
	my $mysql = shift;

	my $devidHash = $mysql->selectall_hashref("
		SELECT deviceid,decom
		FROM visiodevices
		LEFT JOIN inventorylog USING (deviceid)
	","deviceid");

	$mysql->do('DROP TABLE IF EXISTS winipmac');
	$mysql->do("
		CREATE TABLE winipmac (
			deviceid	bigint,
			host		varchar(255),
			mac		varchar(255),
			ip		varchar(255)
		)
	");

	$mysql->do("set session group_concat_max_len = 10000000000");
	my $ipmacInsert = $mysql->prepare("
		INSERT INTO winipmac
		(deviceid,host,mac,ip)
		VALUES
		(?,?,?,?)
	");

	# build a hash of ip to deviceids and array of deviceids

	my $devipQuery = $mysql->prepare("
		SELECT deviceid,csname,macaddr,ipaddress
		FROM windowsnetwork
			INNER JOIN windowsos USING (deviceid)
		WHERE ipaddress LIKE '(%'
		GROUP BY deviceid,csname,macaddr,ipaddress
	");
	$devipQuery->execute();

	while (my $line = $devipQuery->fetchrow_hashref()) {
		my $devid = $line->{'deviceid'};
		my $host = $line->{'csname'};
		my $mac = $line->{'macaddr'};
		my $ipString = $line->{'ipaddress'};
		$ipString =~ s/[\(\)]//g;
		my @ips = split(/,/,$ipString);
		foreach my $ip (@ips) {
			$ipmacInsert->execute($devid,$host,$mac,$ip);
		}
	}

	#we only care about ips that are in riscdevice
	$mysql->do("SET SESSION group_concat_max_len = 10000000000");
	my $riscipQuery = $mysql->selectrow_hashref("
		SELECT GROUP_CONCAT(DISTINCT CONCAT(\'\\'\',ipaddress,\'\\'\')) AS res
		FROM riscdevice
	");
	my $riscips = $riscipQuery->{'res'};

	$logger->debug("removing from winipmac where ip not in ($riscips)");
	$mysql->do("
		DELETE FROM winipmac
		WHERE ip NOT IN ($riscips)
	") if ($riscips);

	#build hashes of ips unique to a device and one of ips shared
	my $uniqueQuery = $mysql->prepare("
		SELECT
			ip,
			GROUP_CONCAT(deviceid) AS devids,
			GROUP_CONCAT(DISTINCT mac) AS macs,
			COUNT(DISTINCT mac) AS nummacs
		FROM winipmac
		GROUP BY ip
	");
	$uniqueQuery->execute();
	my $uniques;
	my $dupeHash;

	while (my $line = $uniqueQuery->fetchrow_hashref()) {
		my $ip = $line->{'ip'};
		if ($line->{'nummacs'} == 1) {
			foreach my $tmpdev (split(/,/,$line->{'devids'})) {
				$uniques->{$tmpdev}++;
			}
		} else {
			foreach my $mac (split(/,/,$line->{'macs'})) {
				$dupeHash->{$ip} = $line->{'devids'};
			}
		}
	}

	my $devsToRemove;

	#for each shared ip device, make sure we have a unique ip in scope
	foreach my $ip (keys %{$dupeHash}) {
		my $devids = $dupeHash->{$ip};
		my $allUnique = 1;

		foreach my $devid (split(/,/,$devids)) {
			$allUnique = 0 unless $uniques->{$devid};
		}

		if ($allUnique) {
			#we know that every device has a unique ip so we can add the deviceids associated to this shared ip to the burn list.
			my $remDevid = $mysql->selectrow_hashref("
				SELECT GROUP_CONCAT(DISTINCT deviceid) AS devids
				FROM riscdevice
				WHERE ipaddress = \'$ip\'
			");
			if ($remDevid->{'devids'}) {
				$devsToRemove .= $remDevid->{'devids'}.',';
			}
		}
	}

	chop $devsToRemove;

	#wipe all entries based on the list of deviceids
	foreach my $remove_deviceid (split(/,/,$devsToRemove)) {
		$logger->info("removing windows device (1) $remove_deviceid");
		$mysql->do("call remove_win_device($remove_deviceid)");
	}


	#reset the dev list and add duplicated devs due to multiple ips on a single machine to remove list
	$devsToRemove = '';
	my $dupesQuery = $mysql->prepare("
		SELECT
			GROUP_CONCAT(DISTINCT deviceid ORDER BY deviceid) AS devids,
			COUNT(DISTINCT deviceid) AS numdevs,
			mac
		FROM winipmac
		GROUP BY mac,host
		HAVING COUNT(DISTINCT deviceid) > 1
	");
	$dupesQuery->execute();

	while (my $line = $dupesQuery->fetchrow_hashref()) {
		my $startval = 0;
		my $existingid = 0;
		my @devids = split(/,/,$line->{'devids'});
		#to account for load balanced ips, we want to make sure we have at least one deviceid
		#	associated to a configured ip, then remove all that aren't

		my $devid_string = $line->{'devids'};
		my $configuredQuery = $mysql->selectrow_hashref("
			SELECT COUNT(*) AS num
			FROM winipmac
				INNER JOIN riscdevice ON riscdevice.deviceid = winipmac.deviceid AND riscdevice.ipaddress = winipmac.ip
			WHERE riscdevice.deviceid IN ($devid_string)
		");
		if ($configuredQuery && $configuredQuery->{'num'} > 0) {
			#we definitely have at least 1 configured ip represented, remove all that aren't from inventory and the list
			my $notConfigured = $mysql->selectrow_hashref("
				SELECT GROUP_CONCAT(DISTINCT riscdevice.deviceid) AS devs
				FROM riscdevice
					LEFT JOIN winipmac ON riscdevice.deviceid = winipmac.deviceid AND riscdevice.ipaddress = winipmac.ip
				WHERE riscdevice.deviceid IN ($devid_string)
					AND winipmac.ip IS NULL
			");
			if ($notConfigured) {
				my @newDevList = @devids;
				foreach my $remove_deviceid (split(/,/,$notConfigured->{'devs'})) {
					$logger->info("removed windows device (2) $remove_deviceid");
					$mysql->do("call remove_win_device_complete($remove_deviceid)");
					for (my $i = 0; $i < scalar(@devids); $i++) {
						splice(@newDevList,$i,1) if ($devids[$i] == $remove_deviceid);
					}
				}
				@devids = @newDevList;
			}
		}

		next if scalar(@devids) == 1;

		# here we want to prefer the current deviceid/scoped ip if we have one.
		# we do that by retaining the 'first' deviceid in the array if none exists in visiodevices
		# and removing all except the one that is in visiodevices, if one is

		# in order to handle the condition where a decommissioned device exists in visiodevices,
		#   but a new deviceid needs to enter the system that shares an IP with the decom'd device,
		#   we throw out any deviceid that is currently decom'd when doing the search for an existing device
		# the decom'd device will remain in visiodevices, but will not affect deduplication
		# once a non-decom'd deviceid is chosen, subsequent runs of this routine should resolve to that deviceid

		my @not_decom;
		foreach my $devid (@devids) {
			if ($devidHash->{$devid}) {
				next if ($devidHash->{$devid}->{'decom'});
				$existingid = $devid;
			}
			push(@not_decom,$devid);
		}
		@devids = @not_decom;

		$startval = 1 unless $existingid > 0;
		for (my $i = $startval; $i < scalar(@devids); $i++) {
			next if $existingid == $devids[$i];
			if (($devids[$i]) and ($devsToRemove !~ /$devids[$i]/)) {
				$devsToRemove .= $devids[$i].',';
			}
		}
	}
	chop $devsToRemove;

	## remove data associated with the duplicate entries
	foreach my $remove_deviceid (split(/,/,$devsToRemove)) {
		$logger->info("removed windows device (3) $remove_deviceid");
		$mysql->do("call remove_win_device_complete($remove_deviceid)");
	}

	$mysql->do("DROP TABLE winipmac");
}

sub removeSNMPDupes {
	my $mysql = shift;

	my $devList = $mysql->prepare("
		SELECT
			deviceid,
			ipaddress,
			GROUP_CONCAT(macaddr) AS macs,
			COUNT(*) AS num
		FROM riscdevice
		WHERE
			deviceid NOT IN (
				SELECT deviceid
				FROM windowsos
			)
			AND deviceid NOT IN (
				SELECT deviceid
				FROM riscvmwarematrix
				WHERE deviceid IS NOT NULL
			)
		GROUP BY ipaddress HAVING COUNT(*) > 1
	");
	$devList->execute();
	while (my $line = $devList->fetchrow_hashref()) {
		my $macs = $line->{'macs'};
		my $ip = $line->{'ipaddress'};
		if ($macs =~ /\:/) {
			#we have at least one valid mac...delete all without a valid mac
			$logger->info("deleting all riscdevice entries with out a valid mac and ip '$ip'");
			$mysql->do("
				DELETE riscdevice
				FROM riscdevice
				LEFT JOIN windowsos USING (deviceid)
				LEFT JOIN riscvmwarematrix USING (deviceid)
				LEFT JOIN ssh_inv_detail USING (deviceid)
				WHERE ipaddress = ?
				AND macaddr NOT LIKE '%:%'
				AND (
					windowsos.deviceid IS NULL
					AND riscvmwarematrix.deviceid IS NULL
					AND ssh_inv_detail.deviceid IS NULL
				)
			", undef, $ip);
		} else {
			my $kill_count = $line->{'num'} - 1;
			$logger->info("deleting $kill_count random devices with ip '$ip'");
			$mysql->do("
				DELETE riscdevice
				FROM riscdevice
				INNER JOIN (
					SELECT deviceid
					FROM riscdevice
					LEFT JOIN windowsos USING (deviceid)
					LEFT JOIN riscvmwarematrix USING (deviceid)
					LEFT JOIN ssh_inv_detail USING (deviceid)
					WHERE ipaddress = ?
					AND (
						windowsos.deviceid IS NULL
						AND riscvmwarematrix.deviceid IS NULL
						AND ssh_inv_detail.deviceid IS NULL
					)
					LIMIT $kill_count
				) a USING (deviceid)
				WHERE ipaddress = ?
			", undef, $ip, $ip);
		}
	}
}

sub collectCLI {
	my $mysql = shift;
	my $ciscoCLIQuery;
	if ($mysql->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$ciscoCLIQuery = $mysql->prepare_cached("
			select
				riscdevice.deviceid,
				riscdevice.ipaddress,
				credentialid,
				`risc_discovery`.credentials.*
			from riscdevice
				inner join `RISC_Discovery`.credentials on riscdevice.deviceid=`RISC_Discovery`.credentials.deviceid
				inner join risc_discovery.credentials on credentialid = credid
			where `RISC_Discovery`.credentials.technology='ssh'
				and macaddr regexp ':'
				and risc_discovery.credentials.removed = 0
		");
	} else {
		$ciscoCLIQuery = $mysql->prepare_cached("
			select
				riscdevice.deviceid,
				riscdevice.ipaddress,
				credentialid,
				`risc_discovery`.credentials.credid,
				`risc_discovery`.credentials.productkey,
				`risc_discovery`.credentials.technology,
				`risc_discovery`.credentials.status,
				`risc_discovery`.credentials.accepted,
				`risc_discovery`.credentials.version,
				`risc_discovery`.credentials.level,
				`risc_discovery`.credentials.testip,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.passphrase) as passphrase,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.context) as context,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.securitylevel) as securitylevel,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.securityname) as securityname,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.authtype) as authtype,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.authpassphrase) as authpassphrase,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.privtype) as privtype,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.privusername) as privusername,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.privpassphrase) as privpassphrase,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.domain) as domain,
				`risc_discovery`.credentials.port,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.userid) as userid,
				`risc_discovery`.cred_decrypt(`risc_discovery`.credentials.username) as username,
				`risc_discovery`.credentials.scantime,
				`risc_discovery`.credentials.eu,
				`risc_discovery`.credentials.ap,
				`risc_discovery`.credentials.removed
			from riscdevice
				inner join `RISC_Discovery`.credentials on riscdevice.deviceid=`RISC_Discovery`.credentials.deviceid
				inner join risc_discovery.credentials on credentialid = credid
			where `RISC_Discovery`.credentials.technology='ssh'
				and macaddr regexp ':'
				and risc_discovery.credentials.removed = 0
		");
	}
	$ciscoCLIQuery->execute();

	while (my $cli = $ciscoCLIQuery->fetchrow_hashref()) {
		my $totalsleep = 180;
		while (riscUtility::checkProcess("inventory-cisco-cli") > 5) {
			$logger->debug("sleeping 10 seconds for a slot");
			sleep 10;
			$totalsleep--;
			if ($totalsleep == 0) {
				$logger->error('killing running cli processes due to timeout');
				`pkill -f inventory-cisco-cli`;
				$totalsleep = 180;
			}
		}
		my $devIP = $cli->{'ipaddress'};
		my $devid = $cli->{'deviceid'};
		my $devTransport = $cli->{'context'};
		my $devUser = $cli->{'username'};
		$devUser = 'null' unless $devUser;
		my $devPass = $cli->{'passphrase'};
		my $devEnable = $cli->{'privpassphrase'};
		$devEnable = 'null' unless $devEnable;

		my $pid = fork();
		next unless $pid == 0;
		unless (defined($pid)) {
			$logger->error("fork failed: $!");
			die "fork failed: $!";
		}
		my $execstring = "/usr/bin/perl /home/risc/inventory-cisco-cli.pl $devIP $devid $devTransport $devUser $devPass $devEnable";
		$logger->debug($execstring);
		exec($execstring);
	}
	$ciscoCLIQuery->finish();
}

sub buildCredList {
	my $mysql		= shift;

	my $return = 0;

	## map internal protocol names to display names
	## XXX these should be constants
	my $technologies = {
		'snmp'		=> 'SNMP',
		'gensrvssh'	=> 'SSH',
		'windows'	=> 'Windows',
		'vmware'	=> 'VMware',
		'db'		=> 'Database',
		'ssh'		=> 'CLI'
	};

	#we need to get a list of creds that are associated to devices within the current scope
	#	then we need to test each of those creds against a handful of devices to see if they have become invalid
	my $numToCheck = 5;

	my @alarms;

	my $creds = $mysql->selectall_hashref("
		select
			credentialid,
			credtag,
			if(technology = 'windows',count(distinct win.deviceid),count(distinct deviceid)) as numdevs,
			substring_index(group_concat(distinct deviceid),',',if(if(technology = 'windows',count(distinct win.deviceid),count(distinct deviceid)) < 5,if(technology = 'windows',count(distinct win.deviceid),count(distinct deviceid)),5)) as devs,
			technology
		from credentials
			inner join (
				select credid,credtag from risc_discovery.credentials
			) ctag on (credid = credentialid)
			inner join riscdevice using(deviceid)
			inner join ipranges on inet_aton(ipaddress) between startipint and endipint
			left join (
				select distinct deviceid from windowsos where caption like '%server%'
			) win using(deviceid)
			left join (
				select
					credentialid,
					count(*) as cnt
				from credentials
					inner join windowsos using(deviceid)
					inner join riscdevice using(deviceid)
					inner join ipranges on inet_aton(ipaddress) between startipint and endipint
				where caption like '%server%'
				group by credentialid
			) srvcount using(credentialid)
		where
			if(technology = 'windows' and srvcount.cnt > 0,win.deviceid is not null,1)
			and technology not in ('vmware','cli','ssh')
		group by credentialid
	",'credentialid');

	# Just in case
	unless ($do_valid_cred_filter) {
		return join(',', keys %{ $creds });
	}

	foreach my $credid (keys %{$creds}) {
		if ($creds->{$credid}->{'numdevs'}) {
			my $devs = $creds->{$credid}->{'devs'};
			my $fails = 0;
			foreach my $deviceid (split(/,/,$devs)) {
				my $res = riscUtility::checkCred($credid,$deviceid);
				if ($res->{'status'}) {
					last;
				} else {
					## to reduce false-positives and to properly decomission devices,
					## only consider an access denied a failure in this context
					if (($res->{'detail'} =~ /denied/i) or ($res->{'detail'} =~ /invalid/i)) {
						$fails++;
					}
				}
			}
			#if all checks failed, send an alert
			if ($fails >= scalar(split(/,/,$devs))) {
				## headend parsing (notificationEmailer) expects each record to be colon delimited
				$logger->info(sprintf("credential is bad: %s %s %d",
					$technologies->{$creds->{$credid}->{'technology'}},
					$creds->{$credid}->{'credtag'},
					$creds->{$credid}->{'numdevs'}
				));
				push(@alarms,join(':',
						$creds->{$credid}->{'credtag'},
						$technologies->{$creds->{$credid}->{'technology'}},
						$creds->{$credid}->{'numdevs'}
				));
				next;
			}
		}

		#this cred is good, add it to the list
		if ($return eq '0') {
			$return = $credid.',';	## if this is the first, replace the 0
		} else {
			$return .= $credid.',';	## if this is not the first, append
		}
	}

	## build alarm and send, if necessary
	if (@alarms) {
		my $alarm_detail;
		## pack the details together
		## headend parsing expects newline delimiters between records
		foreach my $a (@alarms) {
			$alarm_detail .= "$a\n";
		}

		## we keep this for now to preserve the end-user notification
		riscWebservice::sendAlarm(
			encode_base64($0,''),
			5,
			encode_base64('Invalid credential found',''),
			encode_base64($alarm_detail,''),
			encode_base64('alarm','')
		);
	}

	chop $return unless ($return eq '0');
	return $return;
}
