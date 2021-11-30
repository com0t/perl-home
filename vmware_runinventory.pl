#!/usr/bin/perl
use strict;
use Data::Dumper;
use RISC::riscUtility;
use RISC::Collect::Logger;
$|++;

my $logger = RISC::Collect::Logger->new('vmware_runinventory');
$logger->info("vmware inventory begin");

my $assessid = shift;

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} = 1;
my $mysql2 = riscUtility::getDBH('risc_discovery',1);
$mysql2->{mysql_auto_reconnect} = 1;

## remove proxy configuration if exists
riscUtility::proxy_disable();

#first, pull out all vmware inventory data
## avoid removing AWS EC2 data by avoiding entries of type 'ec2'
## NOTE: if additional AWS objects are added to the table, they will also need to be excluded
my $vcenterids = $mysql->selectall_hashref("
	SELECT DISTINCT vcenterid
	FROM riscvmwarematrix
	WHERE type NOT IN ('ec2')
	",'vcenterid');

foreach my $vcenterid (keys %{$vcenterids}) {
	removeVMwareInventoryInfo($vcenterid);
}

#now, pull vcenter creds and iterate
eval {
	my $getVMwareInfo;
	if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$getVMwareInfo = $mysql2->prepare_cached("select * from credentials where technology='vmware' and removed = 0");
	} else {
		$getVMwareInfo = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
			cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
			cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
			cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
			port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
			scantime,eu,ap,removed
			from credentials where technology='vmware' and removed = 0");
	}

	my $inputCredential = $mysql->prepare("insert into credentials (deviceid,credentialid,technology,uniqueid) values (?,?,?,?)");
	$getVMwareInfo->execute();
	while (my $vmip = $getVMwareInfo->fetchrow_hashref()){
		my $credid = $vmip->{'credid'};
		my $ipaddr = stringEscape(riscUtility::decode($vmip->{'domain'}));
		my $userid = stringEscape2(riscUtility::decode($vmip->{'username'}));
		my $password = stringEscape(riscUtility::decode($vmip->{'passphrase'}));
		my $deviceid = vmwareGetDeviceID($ipaddr,$assessid);
		my $level = getServerType($ipaddr,$userid,$password);
		$logger->debug("running against credid='$credid', ip='$ipaddr', type='$level'");
		next unless defined $level && defined $deviceid;

		eval {
			my $uniqueid = $deviceid."-vmware";
			$logger->debug("adding to credentials: deviceid='$deviceid', uniqueid='$uniqueid'");
			$inputCredential->execute($deviceid,$credid,'vmware',$uniqueid) if defined $deviceid
		};

		my $hostInvOutput	= runHostInventory($deviceid,$ipaddr,$userid,$password,$assessid, $credid);
		my $guestInvOutput	= runVMInventory($deviceid,$ipaddr,$userid,$password,$assessid, $credid);
		my $datastoreInvOutput	= runDSInventory($deviceid,$ipaddr,$userid,$password);
	}
}; if ($@) {
	print "$@\n";
}

sub stringEscape{
	my $risc=shift;
	$risc=~ s/([\\\/\\\$\#\%\^\@\!\&\*\(\)\{\}\[\]\<\>\=\s\`\'\"\;\|\?])/\\$1/g;
	return $risc;
}

sub stringEscape2 {
	my $risc = shift;
	$risc =~ s/\\\\/\\/g;
	$risc =~ s/([\\\/\$\#\%\^\@\!\&\*\(\)\{\}\[\]\<\>\=\s\`\'\"\;\|\?])/\\$1/g;
	return $risc;
}

sub getServerType {
	my $server=shift;
	my $user=shift;
#	$user=stringEscape($user);
	my $pass=shift;
	my $level = `/usr/bin/perl /home/risc/viversion.pl --server $server --username $user --password $pass --aboutservice apiinfo`;
	return undef unless defined $level;
	chomp($level);
	return $level;
}

sub vmwareUpdateDeviceID {
	my $ip=shift;
	my $deviceid;
	my $devlookup = $mysql->prepare("select deviceid from riscdevice where ipaddress=? limit 1");
	$devlookup->execute($ip);
	if ($devlookup->rows() <1) {
		#Run disco on that ip and get the device into the database.
		system("/usr/bin/perl disco.pl $assessid $ip");
		$devlookup->execute($ip);
		print "Can't get the device to discover.." unless $devlookup->rows() > 0;
		$deviceid=$devlookup->fetchrow_hashref->{'deviceid'};
		return $deviceid;
	}
	$deviceid=$devlookup->fetchrow_hashref->{'deviceid'};
	return $deviceid;
}

sub vmwareGetDeviceID {
	my $ip=shift;
	my $assessid=shift;
	my $deviceid;
#	my $devlookup = $mysql->prepare("select deviceid from riscdevice where ipaddress=? and deviceid in (select vcenterid from riscvmwarematrix) limit 1");
	my $existingdevQuery=$mysql->selectrow_hashref("select distinct(vcenterid) as devid from riscvmwarematrix where vcenterid=inet_aton(\'$ip\') or vcenterid=concat($assessid,inet_aton(\'$ip\')) limit 1");
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
			print "Some failure with IP to Deviceid conversion...." unless $devidcreate->rows() > 0;
			$deviceid=$devidcreate->fetchrow_hashref->{'deviceid'};
			eval{$mysql->do("insert into riscdevice(deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) values($deviceid,'unknown','$ip',$deviceid,'',0,0,0,0,0,0,0,0)");};
			return $deviceid;
		}
		$deviceid=$devlookup->fetchrow_hashref->{'deviceid'};
		#$devupdate->execute($deviceid,$ip);
		return $deviceid;
	}
}

sub removeVMwareInventoryInfo {
	my $deviceid = shift;
	$logger->info("removing vmware inventory for vcenter '$deviceid'");
	$mysql->do("delete from vmware_hostsystem where deviceid=$deviceid");
	$mysql->do("delete from vmware_dssummary where deviceid=$deviceid");
	$mysql->do("delete from vmware_dshost where deviceid=$deviceid");
	$mysql->do("delete from vmware_dsfiles where deviceid=$deviceid");
	$mysql->do("delete from vmware_dsguest where deviceid=$deviceid");
	$mysql->do("delete from vmware_dstemplate where deviceid=$deviceid");
	$mysql->do("delete from vmware_guestsummaryconfig where deviceid=$deviceid");
	$mysql->do("delete from vmware_guestnetshaper where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostcapability where deviceid=$deviceid");
	$mysql->do("delete from vmware_hosthba where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostlogs where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostmultipath where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostnetworkcapability where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostphysicalnic where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostscsilun where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostscsitopology where deviceid=$deviceid");
	$mysql->do("delete from vmware_statisticslevel where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostvswitchport_vm where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostport_mac where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostportgroup_port where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostvirtualswitchbridge where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostvirtualswitchportgroup where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostvirtualswitchpnic where deviceid=$deviceid");
	$mysql->do("delete from vmware_hostpnic where deviceid=$deviceid");
	$mysql->do("delete from vmware_portgroup where deviceid=$deviceid");
	$mysql->do("delete from vmware_virtualnicconfig where deviceid=$deviceid");
	$mysql->do("delete from vmware_virtualswitchconfig where deviceid=$deviceid");
	$mysql->do("delete from riscdevice where deviceid in (select deviceid from riscvmwarematrix where vcenterid=$deviceid)");
	$mysql->do("delete from riscvmwarematrix where vcenterid=$deviceid");
	$mysql->do("delete from vmware_guest_info where deviceid=$deviceid");
	$mysql->do("delete from vmware_guestnicinfo where deviceid = $deviceid");
	$mysql->do("delete from vmware_heirarchy where deviceid = $deviceid");
	$mysql->do("delete from deviceid_fingerprint_map where deviceid in (select deviceid from riscvmwarematrix where vcenterid=$deviceid)");
}

sub runHostInventory {
	my $deviceid	= shift;
	my $ip		= shift;
	my $user	= shift;
	my $pass	= shift;
	my $assessid	= shift;
	my $credid	= shift;
	my $return	= "HostInventory:";
	$logger->info("running host inventory");
	eval {
		my $command = "/usr/bin/perl /home/risc/risc_vmware_hostinventory.pl $assessid $credid --server $ip --username $user --password $pass --entity HostSystem";
		$logger->debug($command);
		my $response = `$command`;
		$return = $return."commandreturn:".$response;
	}; if ($@) {
		$logger->error("failed host inventory: $@");
		$return = $return."ERROR: $@\n";
	}
	$logger->debug("host inventory returning: '$return'");
	return $return;
}

sub runVMInventory {
	my $deviceid	= shift;
	my $ip		= shift;
	my $user	= shift;
	my $pass	= shift;
	my $assessid	= shift;
	my $credid	= shift;
	my $return	= "VMInventory:";
	$logger->info("running guest inventory");
	eval {
		my $command = "/usr/bin/perl /home/risc/risc_vmware_guestinventory.pl $assessid $credid --server $ip --username $user --password $pass --entity VirtualMachine";
		$logger->debug($command);
		my $response = `$command`;
		$return = $return."commandreturn:".$response;
	}; if ($@) {
		$logger->error("failed guest inventory: $@");
		$return = $return."ERROR: $@\n";
	}
	$logger->debug("guest inventory returning: '$return'");
	return $return;
}

sub runDSInventory {
	my $deviceid	= shift;
	my $ip		= shift;
	my $user	= shift;
	my $pass	= shift;
	my $return	= "DSInventory:";
	$logger->info("running datastore inventory");
	eval {
		my $command = "/usr/bin/perl /home/risc/risc_vmware_datastoreinventory.pl --server $ip --username $user --password $pass --entity VirtualMachine";
		$logger->debug($command);
		my $response = `$command`;
		$return = $return."commandreturn:".$response;
	}; if ($@) {
		$logger->error("failed datastore inventory");
		$return = $return."ERROR: $@\n";
	}
	$logger->debug("datastore inventory returning: '$return'");
	return $return;
}
