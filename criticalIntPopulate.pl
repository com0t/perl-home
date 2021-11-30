use DBI();
use RISC::riscUtility;
use strict;

# generates the critical_interfaces table during inventory. The table should be roughly similar to that produced by the old NetAssess_CriticalInterfaces
# stored procedure, which sorts interfaces into "router", "infrastructure", "server", "shared uplink", and "not critical" (the latter was not actually
# included in the stored procedure output). We have added a column for the deviceid of the connected device, if available, and allowed multiple servers
# to map to the same critical interface, which will facilitate using the table to look up interfaces from connected devices in the future.

my $mysqlLocal = riscUtility::getDBH('RISC_Discovery', 0);

createTable($mysqlLocal);

populateAllInts($mysqlLocal);

my $critHash = populateType($mysqlLocal);

$critHash = populateCDP($mysqlLocal, $critHash);

$critHash = populateServer($mysqlLocal, $critHash);

$critHash = populateSharedUplinks($mysqlLocal, $critHash);

updateIPaddress($mysqlLocal);

sub populateAllInts {
	my $mysql     = shift;
	my $intInsert = $mysql->prepare(
		"insert into critical_interfaces (deviceid,intindex,portclass,intname,speed)
									values (?,?,?,?,?)"
	);
	my $intQuery = $mysql->prepare("select deviceid,intindex,name,ifSpeed(speed) as speed from interfaces");
	$intQuery->execute;

	while (my $line = $intQuery->fetchrow_hashref()) {
		my $deviceid = $line->{'deviceid'};
		my $intindex = $line->{'intindex'};
		my $name     = $line->{'name'};
		my $speed    = $line->{'speed'};
		$intInsert->execute($deviceid, $intindex, 'Not Critical', $name, $speed);
	}
}

sub populateType {
	my $mysql = shift;
	my $critHash;
	my $intInsert = $mysql->prepare(
		"insert into critical_interfaces (deviceid,intindex,portclass,intname,speed)
									values (?,?,?,?,?)"
	);
	my $intUpdate = $mysql->prepare("update critical_interfaces set portclass=? where deviceid=? and intindex=?");
	my $intQuery  = $mysql->prepare(
		"select deviceid, intindex, name, ifSpeed(speed) as speed from interfaces
	inner join networkdeviceinfo using (deviceid)
	where deviceid not in (select distinct(deviceid) from l2forward)
									and deviceid not in (select deviceid from visiodevices where devicetype='AP')
									and adminstatus='up' and operstatus='up'
									and type != '103' and type !='other' and type != '81'
									and type != '104' and type != '102' and type != '101'
									and type not regexp 'loop'"
	);
	$intQuery->execute();

	while (my $line = $intQuery->fetchrow_hashref()) {
		my $deviceid = $line->{'deviceid'};
		my $intindex = $line->{'intindex'};
		my $name     = $line->{'name'};
		my $speed    = $line->{'speed'};

		# this is the first one that runs so we don't need to check critHash
		$critHash->{$deviceid}->{$intindex} = 1;

		#		$intInsert->execute($deviceid,$intindex,'Router',$name,$speed);
		$intUpdate->execute('Router', $deviceid, $intindex);
	}
	return $critHash;
}

sub populateCDP {
	my $mysql     = shift;
	my $critHash  = shift;
	my $intInsert = $mysql->prepare(
		"insert into critical_interfaces (deviceid,intindex,portclass,intname,connecteddevice,connecteddeviceid)
									values (?,?,?,?,?,?)"
	);
	my $intUpdate = $mysql->prepare(
		"update critical_interfaces set portclass=?,intname=?,connecteddevice=?,connecteddeviceid=? where deviceid=? and intindex=?"
	);
	my $cdpQuery = $mysql->prepare(
		"select cdp.deviceid deviceid,cdp.localport localport,'Infrastructure',cdp.neighborhostname neighborhostname, vd.deviceid neighbordeviceid,
									inf.intindex intindex from cdp left join visiodevices vd on cdp.neighborip = vd.ip
									inner join interfaces inf on (cdp.deviceid = inf.deviceid and cdp.localport = inf.name)
									where neighborplatform not like '%Phone%' and neighborplatform not like 'Polycom%' and cdp.deviceid"
	);
	$cdpQuery->execute();

	while (my $line = $cdpQuery->fetchrow_hashref()) {
		my $deviceid        = $line->{'deviceid'};
		my $intindex        = $line->{'intindex'};
		my $connectedDevice = $line->{'neighborhostname'};
		my $name            = $line->{'localport'};
		my $neighbordevid   = $line->{'neighbordeviceid'};
		if ($critHash->{$deviceid}->{$intindex}) {

			# if the non-critical row has already updated away, then insert another row
			$intInsert->execute($deviceid, $intindex, 'Infrastructure', $name, $connectedDevice, $neighbordevid);
		} else {

# if this is the first time the interface has been touched, just replace the non-critical with interface, and touch it in the critHash
			$intUpdate->execute('Infrastructure', $name, $connectedDevice, $neighbordevid, $deviceid, $intindex);
			$critHash->{$deviceid}->{$intindex} = 1;
		}
	}
	return $critHash;
}

sub populateSharedUplinks {
	my $mysql    = shift;
	my $critHash = shift;
	my $minmacs  = 3;
	my $intInsert =
	  $mysql->prepare("insert into critical_interfaces (deviceid,intindex,portclass,intname,speed) values (?,?,?,?,?)");
	my $intUpdate =
	  $mysql->prepare("update critical_interfaces set portclass = ?, intname = ? where deviceid = ? and intindex = ?");
	my $intQuery = $mysql->prepare(
		"select name,ifSpeed(speed) as speed from interfaces where deviceid=? and intindex=? group by deviceid,intindex"
	);
	my $sharedIntQuery = $mysql->prepare(
		"select deviceid,intindex,count(*) as num from l2forward
										where intindex is not null
										group by deviceid,intindex
										having num>=$minmacs"
	);
	$sharedIntQuery->execute();

	while (my $line = $sharedIntQuery->fetchrow_hashref()) {
		my $deviceid = $line->{'deviceid'};
		my $intindex = $line->{'intindex'};
		$intQuery->execute($deviceid, $intindex);
		my $intResult = $intQuery->fetchrow_hashref();
		my $name      = $intResult->{'name'};
		my $speed     = $intResult->{'speed'};
		if ($critHash->{$deviceid}->{$intindex}) {
			$intInsert->execute($deviceid, $intindex, 'Shared Uplink', $name, $speed);
		} else {

			# update and touch the crit
			$intUpdate->execute('Shared Uplink', $name, $deviceid, $intindex);
			$critHash->{$deviceid}->{$intindex} = 1;
		}
	}
}

sub insertUpdateInterface {
	my ($interface_lookup, $deviceReliability, $insertUpdater, $interface, $critHash) = @_;

	my ($finalDev, $finalInt, $reliability) =
	  ($deviceReliability->{'finalDev'}, $deviceReliability->{'finalInt'}, $deviceReliability->{'reliability'});

	my $intName =
	  $interface_lookup->{ $deviceReliability->{'finalDev'} }->{ $deviceReliability->{'finalInt'} }->{'name'};

	if ($critHash->{$finalDev}->{$finalInt}) {
		$insertUpdater->{'insert'}->execute($finalDev, $finalInt, $interface->{'name'}, $interface->{'serverdevid'},
			$reliability, 'Server', $intName);
	} elsif ($finalDev != 0) {
		$insertUpdater->{'update'}->execute($interface->{'name'}, $interface->{'serverdevid'},
			$reliability, 'Server', $intName, $finalDev, $finalInt);
		$critHash->{$finalDev}->{$finalInt} = 1;
	}
}

sub makeInterface {
	my ($line) = @_;
	return {
		"serverdevid" => $line->{'deviceid'},
		"mac"         => $line->{'macaddr'},
		"ip"          => $line->{'ipaddress'},
		"name"        => $line->{'name'},
		"intindex"    => $line->{'intindex'},
		"switchdevid" => $line->{'switchdevid'} };
}

sub makeDeviceReliability {
	return {
		'finalDev'    => 0,
		'finalInt'    => 0,
		'reliability' => 0,
	};
}

sub insert_servers {
	my ($db, $query, $insertUpdater, $l2forward_lookup, $interface_lookup, $critHash) = @_;
	my $serverQuery = $db->prepare($query);
	$serverQuery->execute();

	my $last_groupby_key  = undef;
	my $deviceReliability = makeDeviceReliability();
	my $interface         = undef;

	while (my $line = $serverQuery->fetchrow_hashref()) {
		unless (
			$last_groupby_key
			&& (   $last_groupby_key->{'deviceid'} eq $line->{'deviceid'}
				&& $last_groupby_key->{'macaddr'} eq $line->{'macaddr'}
				&& $last_groupby_key->{'ipaddress'} eq $line->{'ipaddress'}))
		{
			insertUpdateInterface($interface_lookup, $deviceReliability, $insertUpdater, $interface, $critHash)
			  if $last_groupby_key;
			$last_groupby_key->{'deviceid'}  = $line->{'deviceid'};
			$last_groupby_key->{'macaddr'}   = $line->{'macaddr'};
			$last_groupby_key->{'ipaddress'} = $line->{'ipaddress'};
			$deviceReliability               = makeDeviceReliability();
		}
		$interface = makeInterface($line);
		next unless defined($interface->{'intindex'}) && defined($interface->{'switchdevid'});
		my $macCount = $l2forward_lookup->{ $interface->{'switchdevid'} }->{ $interface->{'intindex'} }->{'macs'};
		if ($deviceReliability->{'reliability'} > $macCount || $deviceReliability->{'reliability'} < 1) {
			$deviceReliability->{'finalDev'}    = $interface->{'switchdevid'};
			$deviceReliability->{'finalInt'}    = $interface->{'intindex'};
			$deviceReliability->{'reliability'} = $macCount;
		}
	}
	insertUpdateInterface($interface_lookup, $deviceReliability, $insertUpdater, $interface, $critHash)
	  if $last_groupby_key;
}

sub populateServer {
	my $mysql    = shift;
	my $critHash = shift;

	my $insertUpdater = {
		"insert" => $mysql->prepare(
			"insert into critical_interfaces (
				deviceid,intindex,connecteddevice,
				connecteddeviceid,reliability,portclass,intname
			)
			values (?,?,?,?,?,?,?)"
		),
		"update" => $mysql->prepare(
			"update critical_interfaces
			set connecteddevice=?,connecteddeviceid=?,reliability=?,portclass=?,intname=?
			where deviceid=? and intindex=?"
		) };

	my $l2forward_lookup = $mysql->selectall_hashref(
		"select
			count(mac) as macs,
			deviceid,
			intindex
		from l2forward
		group by deviceid, intindex",
		[ "deviceid", "intindex" ]);
	my $interface_lookup = $mysql->selectall_hashref(
		"select
			name,
			deviceid,
			intindex
		from interfaces
		group by deviceid, intindex",
		[ "deviceid", "intindex" ]);

	my $serverQuery = "select
			windows_network_info.deviceid as deviceid,
			windows_network_info.macaddr as macaddr,
			windows_network_info.ipaddress as ipaddress,
			windows_network_info.csname as name,
			l2forward.deviceid as switchdevid,
			l2forward.intindex as intindex
		from (
			select
				windowsnetwork.deviceid as deviceid,
				windowsnetwork.macaddr as macaddr,
				riscdevice.ipaddress as ipaddress,
				windowsos.csname as csname
			from windowsnetwork
			inner join riscdevice on windowsnetwork.deviceid=riscdevice.deviceid
			inner join windowsos on windowsnetwork.deviceid=windowsos.deviceid
			where
				windowsnetwork.macaddr regexp ':'
				and windowsos.caption regexp 'server'
			group by
				windowsnetwork.deviceid,
				windowsnetwork.macaddr,
				riscdevice.ipaddress
		) windows_network_info
		inner join l2forward on l2forward.mac = windows_network_info.macaddr
		order by
			windows_network_info.deviceid,
			windows_network_info.macaddr,
			windows_network_info.ipaddress
		";

	my $genserverQuery = "select
			gensrv_network_info.deviceid as deviceid,
			gensrv_network_info.macaddr as macaddr,
			gensrv_network_info.ipaddress as ipaddress,
			gensrv_network_info.sysname as name,
			l2forward.deviceid as switchdevid,
			l2forward.intindex as intindex
		from (
			select
				gensrvserver.deviceid as deviceid,
				interfaces.mac as macaddr,
				riscdevice.ipaddress as ipaddress,
				max(snmpsysinfo.sysname) as sysname
			from gensrvserver
			inner join snmpsysinfo on gensrvserver.deviceid=snmpsysinfo.deviceid
			inner join interfaces on gensrvserver.deviceid=interfaces.deviceid
			inner join riscdevice on gensrvserver.deviceid=riscdevice.deviceid
			where
				memorysize is not null
				and mac is not null
			group by gensrvserver.deviceid,interfaces.mac,riscdevice.ipaddress
		) gensrv_network_info
		inner join l2forward on l2forward.mac = gensrv_network_info.macaddr
		order by
			gensrv_network_info.deviceid,
			gensrv_network_info.macaddr,
			gensrv_network_info.ipaddress
		";
	insert_servers($mysql, $serverQuery,    $insertUpdater, $l2forward_lookup, $interface_lookup, $critHash);
	insert_servers($mysql, $genserverQuery, $insertUpdater, $l2forward_lookup, $interface_lookup, $critHash);
	return $critHash;
}

sub updateIPaddress {
	my $mysql    = shift;
	my $updateIP = $mysql->prepare(
		"update critical_interfaces, riscdevice set critical_interfaces.ipaddress=riscdevice.ipaddress where critical_interfaces.deviceid=riscdevice.deviceid"
	);
	$updateIP->execute();
	my $updateSpeed = $mysql->prepare(
		"update critical_interfaces, interfaces set critical_interfaces.speed = interfaces.speed where
									critical_interfaces.deviceid = interfaces.deviceid and critical_interfaces.intindex = interfaces.intindex"
	);
}

sub createTable {
	my $mysql = shift;
	$mysql->do("drop table if exists critical_interfaces");
	$mysql->do(
		"create table critical_interfaces (
				  `deviceid` bigint,
				  `ipaddress` varchar(100),
				  `intindex` int,
				  `intname` varchar(100),
				  `connecteddevice` varchar(255),
				  `connecteddeviceid` bigint,
				  `portclass` varchar(100),
				  `ein` bigint default 0,
				  `eout` bigint default 0,
				  `din` bigint default 0,
				  `dout` bigint default 0,
				  `bwmaxbpso` bigint default 0,
				  `bwavgbpso` bigint default 0,
				  `bwstdbpso` bigint default 0,
				  `bwmaxbpsi` bigint default 0,
				  `bwavgbpsi` bigint default 0,
				  `bwstdbpsi` bigint default 0,
				  `speed` bigint default 0,
				  `reliability` int,
				  `maxutili` int,
				  `maxutilo` int,
				  `bwerror` int,
				  `totalerror` bigint,
				  KEY `Index_2` (`deviceid`),
				  KEY `Index_3` (`ipaddress`),
				  KEY `Index_4` (`intindex`)
				) ENGINE=MyISAM DEFAULT CHARSET=latin1"
	);
}
