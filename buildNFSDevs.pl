use strict;
use RISC::riscUtility;

my $mysql = riscUtility::getDBH('RISC_Discovery',0);

our $scantime = time();
our $deviceInteger;
my $generatedIDQuery = $mysql->selectrow_hashref("select * from riscdevice where deviceid>=4294917295 and deviceid<4294967296 order by deviceid desc limit 1");
if (defined $generatedIDQuery->{'deviceid'}) {
	$deviceInteger = $generatedIDQuery->{'deviceid'}+1;
} else {
	$deviceInteger = 4294917295;
}

our $dnsHash = $mysql->selectall_hashref("select * from win_dns group by result,lookup","lookup");
our $devInsert = $mysql->prepare("insert ignore into storage_device (deviceid,hostname,storage_type,scantime)
									values (?,?,?,?)");
our $pathInsert = $mysql->prepare("insert ignore into storage_device_path (deviceid,path,allocatedbytes,usedbytes,root,scantime)
									values (?,?,?,?,?,?)");
our $riscInsert = $mysql->prepare("insert into riscdevice (deviceid,sysdescription,ipaddress,macaddr)
									values (?,?,?,?)");


popNFS($mysql);







sub popNFS {
	my $mysql = shift;
	
	my $inventoriedHash = $mysql->selectall_hashref("select *,if(vis.deviceid is null,1,0) as married from storage_device
														inner join storage_device_path using(deviceid)
														left join (select distinct deviceid from visiodevices where devicetype = 'NFS') vis using(deviceid)
														where storage_type like '\%nfs\%'",["hostname","path"]);
	
	my $nfsStoreQuery = $mysql->selectall_arrayref("select fsremotemountpoint as mount,storagesize,max(storageused) as storageused from gensrvstorage gs
														inner join gensrvfilesystem gf on gs.deviceid = gf.deviceid and fsstorageindex=storageindex
														where fsremotemountpoint like '%:%'
														group by fsremotemountpoint,storagesize",{ Slice => {} });
	
	my $rootPath = 'this should never match';
	my $rootHost = 'this should never match';
	my $rootSize = -1;
	
	foreach my $line (@{$nfsStoreQuery}) {
		my ($rawhost,$path) = split(/:/,$line->{'mount'});

		## if we have an IP, continue with that
		## if we have an FQDN, reduce to just the hostname
		## if we have a hostname, continue with that
		my $host;
		if ($rawhost =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
			$host = $rawhost;			## use IP directly
		} elsif ($rawhost =~ /\./) {
			($host) = $rawhost =~ /^(.*?)\./;	## stingy match for hostname off of FQDN
		} else {
			$host = $rawhost;			## use hostname directly
		}

		my $size = $line->{'storagesize'};
		my $used = $line->{'storageused'};
		
		my $shouldRiscInsert = 0;
		my $riscIP = 'unknown';
		
		#first make sure this isn't a sub of the previous row
		if ($path =~ /^$rootPath.+/ && $size == $rootSize) {
			my $devidQuery = $mysql->selectrow_hashref("select deviceid from storage_device
															inner join storage_device_path using(deviceid)
															where hostname = \'$rootHost\' and path = \'$rootPath\' and allocatedbytes = $rootSize
															limit 1");
			my $devid = $devidQuery->{'deviceid'} if $devidQuery && $devidQuery->{'deviceid'};
			$pathInsert->execute($devid,$path,$size,$used,0,$scantime);
			next;
		}
		
		$rootHost = $host;
		$rootPath = $path;
		$rootSize = $size;
		
		#now check to see if we've inventoried this and try to marry it if we didn't before
		if ($inventoriedHash->{$host} &&
			!$inventoriedHash->{$host}->{$path}->{'married'} &&
			$inventoriedHash->{$host}->{$path}->{'path'} eq $path &&
			$inventoriedHash->{$host}->{$path}->{'allocatedbytes'} == $size) {
			#this nfs is already in the list, if it hasn't been married to an inventoried device, check to see if it can be
			my $devid = $inventoriedHash->{$host}->{$path}->{'deviceid'};
			my $riscdev = $mysql->selectrow_hashref("select * from riscdevice where deviceid = $devid");
			if ($riscdev->{'ipaddress'} eq 'unknown') {
				my $newDevid = marryNFSDev($mysql,$host);
				if ($newDevid > 0) {
					$mysql->do("delete from riscdevice where deviceid = $devid");
					$mysql->do("delete from visiodevices where deviceid = $devid");
					$mysql->do("update storage_device set deviceid = $newDevid where deviceid = $devid");
					$mysql->do("update storage_device_path set deviceid = $newDevid where deviceid = $devid");
				}
			}
			next;
		}
		
		#first see if we already have this host
		my $devid;
		my $devQuery = $mysql->selectrow_hashref("select deviceid from storage_device where hostname = \'$host\'");
		$devid = $devQuery->{'deviceid'} if $devQuery && $devQuery->{'deviceid'};
		
		#if this is a new one, try to marry it to an existing device
		$devid = marryNFSDev($mysql,$host) unless $devid > 0;
		
		if ($devid == 0) {
			#we weren't able to marry it so generate a deviceid -- based on the ip if we have one, and we'll need to insert to riscdevice
			$shouldRiscInsert = 1;
			if ($host =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
				$devid = unpack 'N', pack 'C4', split '\.', $1;
				$riscIP = $1;
			} else {
				$devid = $deviceInteger;
				$deviceInteger++;
			}
		}
		
		#add the device and path
		$devInsert->execute($devid,$host,'NFS',$scantime);
		$pathInsert->execute($devid,$path,$size,$used,1,$scantime);
		$riscInsert->execute($devid,$host.'-NFS',$riscIP,$devid) if $shouldRiscInsert;
	}
}

sub marryNFSDev {
	my $mysql = shift;
	my $host = shift;
	
	my $devid = 0;
	
	#first try based on ip if we have an ip
	if ($host =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
		my $ip = $1;
		my $devQuery = $mysql->selectrow_hashref("select * from visiodevices where ip = \'$ip\' order by deviceid desc limit 1");
		$devid = $devQuery->{'deviceid'} if ($devQuery && $devQuery->{'deviceid'});
	}
	
	#now try to match the hostname to name from snmp/wmi/vmware
	unless ($devid > 0) {
		my $snmp_devid = $mysql->selectrow_hashref("select deviceid from snmpsysinfo where sysname like \'\%$host\%\' or sysdescription like \'\%$host\%\'");
		if ($snmp_devid->{'deviceid'}) {
			return $snmp_devid->{'deviceid'};
		}

		my $win_devid = $mysql->selectrow_hashref("select deviceid from windowsos where name like \'\%$host\%\'");
		if ($win_devid->{'deviceid'}) {
			return $win_devid->{'deviceid'};
		}

		my $vm_devid = $mysql->selectrow_hashref("select riscvmwarematrix.deviceid from vmware_guestsummaryconfig inner join riscvmwarematrix using (uuid) where name like \'\%$host\%\'");
		if ($vm_devid->{'deviceid'}) {
			return $vm_devid->{'deviceid'};
		}
	}
	
	#finally, try dns
	unless ($devid == 0) {
		while ($dnsHash->{$host}) {
			$host = $dnsHash->{$host}->{'result'};
		}
		if ($host =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
			my $ip = $1;
			my $devQuery = $mysql->selectrow_hashref("select * from visiodevices where ip = \'$ip\' order by deviceid desc limit 1");
			$devid = $devQuery->{'deviceid'} if ($devQuery && $devQuery->{'deviceid'});
		}
	}
	
	return $devid;
}
