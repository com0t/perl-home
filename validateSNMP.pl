#!/usr/bin/perl
#
## validateSNMP.pl
## test SNMP access to generic servers and produce a report
##  on successful connection and data pull

use strict;
use MIME::Base64;
use SNMP::Info;
use Data::Dumper;
use RISC::riscUtility;
$|++;

### DOCUMENTATION
#
## This script produces a report on SNMP data accessibility for generic servers.
## There are three modes the script can be issued under, one that is issued prior to inventory for
### consumption by the user on the frontend, and one for validation after inventory for troubleshooting, and one
### that can be used at any time through CC.
#
## The first argument to the script determines what mode it runs, and determines how following arguments
### are processed. The mode keywords are:
#	raw:		frontend mode, an IP and a raw credential is passed in
#	deviceid:	post-inventory, validates the configuration of a device for which an SNMP cred has been mapped
#	credid:		pre-inventory, accepts an IP and a credid
#
## Arguments are expected to be contained entirely in single-quotes, and take the following forms:
#
## 'deviceid <deviceid>'
## 'raw <IP> [1|2] <community>'
## 'raw <IP> 3 <SecLevel> <SecName> <Context> <AuthProto> <AuthPass> <PrivProto> <PrivPass>'
## 'credid <credid> <IP>'
#
## In 'raw' mode, all arguments except the 'raw' keyword are expected to be in base64 encoded format


# knobs
########
my $debugging		= 0;	## print debugging info to STDERR
my $snmp_debug		= 0;	## pass the Debug option to SNMP::Info
my $do_ping_check	= 1;	## check ICMP access as well as SNMP access ('existing' mode disables this)
my $ping_count		= 2;	## number of ICMP echo requests to send during ICMP validation
my $ping_threshold	= 50;	## percentage of successful pings we must meet to avoid warning the user

## set this environment variable to override the default debugging knob
## eg: shell$ env RISC_DEBUG_VALIDATOR=1 perl validateSNMP.pl '<args>'
if ($ENV{'DEBUG'}) {
	$debugging = 1;
}


my $args = shift;
$args =~/^\'(.+)\'$/;
@ARGV = split(/\s/, $args);

my $target;
my $version;
my $cred;

my $runtype = shift;
if ($runtype eq 'raw') {
	$target	= decode_base64(shift);
	$version = decode_base64(shift);
	if ($version == 3) {
		$cred->{'seclevel'}	= decode_base64(shift);
		$cred->{'secname'}	= decode_base64(shift);
		$cred->{'context'}	= decode_base64(shift);
		$cred->{'authtype'}	= decode_base64(shift);
		$cred->{'authpass'}	= decode_base64(shift);
		$cred->{'privtype'}	= decode_base64(shift);
		$cred->{'privpass'}	= decode_base64(shift);
	} else {
		$cred->{'community'}	= decode_base64(shift);
	}
} elsif ($runtype eq 'deviceid') {
	my $deviceid = shift;
	$do_ping_check = 0; ## don't test ICMP when testing existing devices
	my $DB = riscUtility::getDBH('RISC_Discovery',1);
	my $db = riscUtility::getDBH('risc_discovery',1);
	my $credid;
	eval {
		$credid = $DB->selectrow_hashref("select credentialid,ipaddress
						from credentials
						inner join riscdevice using (deviceid)
						where deviceid = $deviceid");
	}; if ($@) {
		print "error determining credentials for $deviceid: $@\n";
		exit(1);
	}
	if ($credid) {
		$target = $credid->{'ipaddress'};
		$credid = $credid->{'credentialid'};
	} else {
		print "no credentialid for deviceid $deviceid\n";
		exit(1);
	}
	$DB->disconnect();
	my $rawcred;
	if ($db->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$rawcred = $db->selectrow_hashref("select * from credentials where technology = 'snmp' and credid = $credid");
	} else {
		$rawcred = $db->selectrow_hashref("select version,
							cred_decrypt(passphrase) as passphrase,
							cred_decrypt(securitylevel) as securitylevel,
							cred_decrypt(securityname) as securityname,
							cred_decrypt(context) as context,
							cred_decrypt(authtype) as authtype,
							cred_decrypt(authpassphrase) as authpassphrase,
							cred_decrypt(privtype) as privtype,
							cred_decrypt(privpassphrase) as privpassphrase
							from credentials
							where technology = 'snmp' and credid = $credid");
	}
	$db->disconnect();
	$version = $rawcred->{'version'};
	if ($version == 3) {
		$cred->{'seclevel'}	= decode_base64($rawcred->{'securitylevel'});
		$cred->{'secname'}	= decode_base64($rawcred->{'securityname'});
		$cred->{'context'}	= decode_base64($rawcred->{'context'});
		$cred->{'authtype'}	= decode_base64($rawcred->{'authtype'});
		$cred->{'authpass'}	= decode_base64($rawcred->{'authpassphrase'});
		$cred->{'privtype'}	= decode_base64($rawcred->{'privtype'});
		$cred->{'privpass'}	= decode_base64($rawcred->{'privpassphrase'});
	} else {
		$cred->{'community'} = decode_base64($rawcred->{'passphrase'});
	}
} elsif ($runtype eq 'credid') {
	my $credid = shift;
	$target = shift;
	my $db = riscUtility::getDBH('risc_discovery',1);
	my $rawcred;
	if ($db->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$rawcred = $db->selectrow_hashref("select * from credentials where technology = 'snmp' and credid = $credid");
	} else {
		$rawcred = $db->selectrow_hashref("select version,
							cred_decrypt(passphrase) as passphrase,
							cred_decrypt(securitylevel) as securitylevel,
							cred_decrypt(securityname) as securityname,
							cred_decrypt(context) as context,
							cred_decrypt(authtype) as authtype,
							cred_decrypt(authpassphrase) as authpassphrase,
							cred_decrypt(privtype) as privtype,
							cred_decrypt(privpassphrase) as privpassphrase
							from credentials
							where technology = 'snmp' and credid = $credid");
	}
	$db->disconnect();
	unless ($rawcred) {
		print "credid $credid does not exist or is not an SNMP cred\n";
		exit(1);
	}
	$version = $rawcred->{'version'};
	if ($version == 3) {
		$cred->{'seclevel'}	= decode_base64($rawcred->{'securitylevel'});
		$cred->{'secname'}	= decode_base64($rawcred->{'securityname'});
		$cred->{'context'}	= decode_base64($rawcred->{'context'});
		$cred->{'authtype'}	= decode_base64($rawcred->{'authtype'});
		$cred->{'authpass'}	= decode_base64($rawcred->{'authpassphrase'});
		$cred->{'privtype'}	= decode_base64($rawcred->{'privtype'});
		$cred->{'privpass'}	= decode_base64($rawcred->{'privpassphrase'});
	} else {
		$cred->{'community'} = decode_base64($rawcred->{'passphrase'});
	}
} else {
	print "error: invalid usage\n";
	exit(1);
}

foreach my $key (keys %{$cred}) {
	if ($cred->{$key} eq 'null') {
		$cred->{$key} = undef;
	}
}

my $info;
my $sections;
my $data;

$sections->{'overall'} = "success";

## first, check ICMP access
if ($do_ping_check) {
	debug("ICMP access ... ");
	my $icmp_cmd = "ping -c $ping_count $target";
	my $icmp_out = `$icmp_cmd`;
	if ($icmp_out =~ /(\d+) packets transmitted, (\d+) received, (\d{1,3})% packet loss, time (\d+)ms/) {
		if ($3 < 100) {
			if ($3 > $ping_threshold) {
				my $icmp_str = "warning: more than $ping_threshold% of attempts were lost ($2 of $1 received)";
				debug($icmp_str."\n");
				$sections->{'icmp'} = $icmp_str;
			} else {
				debug("success\n");
				$sections->{'icmp'} = 'success';
			}
		} else {
			debug("FAIL\n");
			$sections->{'icmp'} = 'FAIL';
			$sections->{'overall'} = 'FAIL';
		}
	} elsif (($icmp_out =~ /destination host unreachable/i) or ($icmp_out =~ /unknown host/i) or ($icmp_out =~ /Host is down/i) or ($icmp_out =~ /error/i)) {
		debug("FAIL\n");
		$sections->{'icmp'} = 'FAIL';
		$sections->{'overall'} = 'FAIL';
	} else {
		debug("[!]: FAILED parsing ping output: $icmp_out\n");
		exit(1);
	}
} else {
	$sections->{'icmp'} = 'skipped';
}

## initiate SNMP connection
debug("SNMP access ... ");
eval {
	if ($version == 3) {
		$info = new SNMP::Info(
			'AutoSpecify'	=> 1,
			'Debug'		=> $snmp_debug,
			'Version'	=> 3,
			'DestHost'	=> $target,
			'SecLevel'	=> $cred->{'seclevel'},
			'SecName'	=> $cred->{'secname'},
			'Context'	=> $cred->{'context'},
			'AuthProto'	=> $cred->{'authtype'},
			'AuthPass'	=> $cred->{'authpass'},
			'PrivProto'	=> $cred->{'privtype'},
			'PrivPass'	=> $cred->{'privpass'}
		);

	} else {
		$version = 2;
		$info = new SNMP::Info(
			'AutoSpecify'	=> 1,
			'Debug'		=> $snmp_debug,
			'Version'	=> 2,
			'DestHost'	=> $target,
			'Community'	=> $cred->{'community'}
		);
		unless(defined($info) and defined($info->description())) {
			$version = 1;
			$info = new SNMP::Info(
				'AutoSpecify'	=> 1,
				'Debug'		=> $snmp_debug,
				'Version'	=> 1,
				'DestHost'	=> $target,
				'Community'	=> $cred->{'community'}
			);
		}

	}

}; if ($@) {
	debug("got error during SNMP connection attempt: $@\n");
	exit(1);
}

if (defined($info)) {
	$data->{'sysDescr'} = $info->description();
	if (defined($data->{'sysDescr'})) {
		debug("success\n");
		$sections->{'snmp'} = "success";
		$sections->{'mib2'} = "success";
	} else {
		debug("FAIL\n");
		$sections->{'snmp'} = "FAIL";
		$sections->{'overall'} = 'FAIL';
	}
} else {
	debug("FAIL\n");
	$sections->{'snmp'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
	print_report($data,$sections);
	exit(1);
}

## MIB-II
#( we already have sysDescr from above )
$data->{'sysUptime'} = $info->uptime();
$data->{'sysLocation'} = $info->location();
$data->{'sysContact'} = $info->contact();
$data->{'sysName'} = $info->name();

## IF-MIB
debug("IF-MIB ... ");
$data->{'intfIndex'} = $info->i_index();
$data->{'intfDescr'} = $info->i_description();
if (defined($data->{'intfIndex'}) and defined($data->{'intfDescr'})) {
	debug("success\n");
	$sections->{'ifmib'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'ifmib'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## IP-MIB
debug("IP-MIB ... ");
$data->{'ipNetmask'} = $info->ip_netmask();
if (defined($data->{'ipNetmask'})) {
	debug("success\n");
	$sections->{'ipmib'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'ipmib'} = "WARNING: unavailable";
	if ($sections->{'overall'} eq 'success') { ## avoid FAIL --> WARNING based on this
		$sections->{'overall'} = "WARNING";
	}
}

## HOST-RESOURCES::System
debug("HOST-RESOURCES (system) ... ");
$data->{'hrUptime'} = $info->hr_systemUptime();
$data->{'hrProcesses'} = $info->hr_systemProcesses();
$data->{'hrMemSize'} = $info->hr_memorySize();
if (defined($data->{'hrUptime'}) and defined($data->{'hrProcesses'}) and defined($data->{'hrMemSize'})) {
	debug("success\n");
	$sections->{'hr_system'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_system'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Devices
debug("HOST-RESOURCES (devices) ... ");
$data->{'devIndex'} = $info->hr_deviceIndex();
$data->{'devType'} = $info->hr_deviceType();
$data->{'devDescr'} = $info->hr_deviceDescription();
if (defined($data->{'devIndex'}) and defined($data->{'devType'}) and defined($data->{'devDescr'})) {
	debug("success\n");
	$sections->{'hr_devices'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_devices'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::CPU Utilization
debug("HOST-RESOURCES (cpu util) ... ");
$data->{'cpuUtil'} = $info->hr_processorLoad();
if (defined($data->{'cpuUtil'})) {
	debug("success\n");
	$sections->{'hr_cpu'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_cpu'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Storage
debug("HOST-RESOURCES (storage) ... ");
$data->{'stIndex'} = $info->hr_storageIndex();
$data->{'stType'} = $info->hr_storageType();
$data->{'stDescr'} = $info->hr_storageDescription();
if (defined($data->{'stIndex'}) and defined($data->{'stType'}) and defined($data->{'stDescr'})) {
	debug("success\n");
	$sections->{'hr_storage'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_storage'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Partition
debug("HOST-RESOURCES (partition) ... ");
$data->{'partIndex'} = $info->hr_partitionIndex();
$data->{'partLabel'} = $info->hr_partitionLabel();
if (defined($data->{'partIndex'}) and defined($data->{'partLabel'})) {
	debug("success\n");
	$sections->{'hr_partition'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_partition'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Filesystem
debug("HOST-RESOURCES (filesystem) ... ");
$data->{'fsIndex'} = $info->hr_fsIndex();
$data->{'fsMount'} = $info->hr_fsMountPoint();
if (defined($data->{'fsIndex'}) and defined($data->{'fsMount'})) {
	debug("success\n");
	$sections->{'hr_filesystem'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_filesystem'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Software
debug("HOST-RESOURCES (software) ... ");
$data->{'swIndex'} = $info->hr_swInstalledIndex();
$data->{'swName'} = $info->hr_swInstalledName();
if (defined($data->{'swIndex'}) and defined($data->{'swName'})) {
	debug("success\n");
	$sections->{'hr_software'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_software'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## HOST-RESOURCES::Processes
debug("HOST-RESOURCES (processes) ... ");
$data->{'procIndex'} = $info->hr_swRunIndex();
$data->{'procName'} = $info->hr_swRunName();
$data->{'procID'} = $info->hr_swRunID();
if (defined($data->{'procIndex'}) and defined($data->{'procName'}) and defined($data->{'procID'})) {
	debug("success\n");
	$sections->{'hr_processes'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'hr_processes'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## UCD::Memory
debug("UC-DAVIS (memory) ... ");
$data->{'ucdMemTotal'} = $info->linux_memTotalReal();
$data->{'ucdMemAvail'} = $info->linux_memAvailReal();
if (defined($data->{'ucdMemTotal'}) and defined($data->{'ucdMemAvail'})) {
	debug("success\n");
	$sections->{'ucd_memory'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'ucd_memory'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## UCD-DISKIO
debug("UCD-DISKIO ... ");
$data->{'ucddiskIndex'} = $info->ucd_io_index();
$data->{'ucddiskIORead'} = $info->ucd_io_reads();
if (defined($data->{'ucddiskIndex'}) and defined($data->{'ucddiskIORead'})) {
	debug("success\n");
	$sections->{'ucd_diskio'} = "success";
} else {
	debug("FAIL\n");
	$sections->{'ucd_diskio'} = "FAIL";
	$sections->{'overall'} = 'FAIL';
}

## TCP-MIB (netstat)
eval {	## because AIX may break this
	my $rfc4022 = 0;
	debug("TCP-MIB ... ");
	$data->{'tcpConnection'} = $info->getNetworkStats();
	if (defined($data->{'tcpConnection'})) {
		## to determine if we hit tcpConnectionTable (RFC4022) we count the number
		## of period-delimited fields in the connection index for the first connection
		## this will be 14 for RFC 4022, 10 for the older implementation
		my @index = split(/\./,$data->{'tcpConnection'}->{1}->{'index'});
		my $count = @index;
		if ($count > 10) {
			$rfc4022++;
		}
		foreach my $conn (keys %{$data->{'tcpConnection'}}) {
			if ($data->{'tcpConnection'}->{$conn}->{'processid'} > 0) {
				$rfc4022++;
				last;
			}
		}
		if ($rfc4022) {
			if ($rfc4022 > 1) {
				debug("success\n");
				$sections->{'tcp'} = "success";
			} else {
				debug("WARNING: RFC 4022 available but no PIDs provided");
				$sections->{'tcp'} = "WARNING: RFC 4022 available but no PIDs provided";
				if ($sections->{'overall'} eq 'success') {
					$sections->{'overall'} = "WARNING";
				}
			}
		} else {
			debug("WARNING: no RFC 4022 extensions\n");
			$sections->{'tcp'} = "WARNING: no RFC 4022 extensions";
			if ($sections->{'overall'} eq 'success') {
				$sections->{'overall'} = "WARNING";
			}
		}
	} else {
		debug("FAIL\n");
		$sections->{'tcp'} = "FAIL";
		$sections->{'overall'} = 'FAIL';
	}
}; if ($@) {
	debug("ERROR: $@\n");
	$sections->{'tcp'} = 'ERROR';
	$sections->{'overall'} = 'FAIL';
}

#print STDERR Dumper($sections);
#print STDERR Dumper($data);

debug("\n");
print_report($data,$sections);

## output
sub print_report
{
	my $data = shift;
	my $sections = shift;

	print "## report for $target\n";
	print "\nOverall Status: ".$sections->{'overall'}."\n\n";
	if ($sections->{'mib2'} eq 'success') {
		print "sysName:        ".$data->{'sysName'}."\n";
		print "sysDescr:       ".$data->{'sysDescr'}."\n";
		print "sysUptime:      ".$data->{'sysUptime'}."\n";
		print "sysLocation:    ".$data->{'sysLocation'}."\n";
		print "sysContact:     ".$data->{'sysContact'}."\n";
		print "\n";
	}
	print "ICMP Access:    ".$sections->{'icmp'}."\n";
	print "SNMP Access:    ".$sections->{'snmp'}."\n";
	if ($sections->{'snmp'} =~ /success/) {
		print "MIB-II:         ".$sections->{'mib2'}."\n";
		print "IF-MIB:         ".$sections->{'ifmib'}."\n";
		print "IP-MIB:         ".$sections->{'ipmib'}."\n";
		print "HOST-RESOURCES\n";
		print "    System:     ".$sections->{'hr_system'}."\n";
		print "    Devices:    ".$sections->{'hr_devices'}."\n";
		print "    CPU Util:   ".$sections->{'hr_cpu'}."\n";
		print "    Storage:    ".$sections->{'hr_storage'}."\n";
		print "    Partition:  ".$sections->{'hr_partition'}."\n";
		print "    Filesystem: ".$sections->{'hr_filesystem'}."\n";
		print "    Software:   ".$sections->{'hr_software'}."\n";
		print "    Processes:  ".$sections->{'hr_processes'}."\n";
		print "UC-DAVIS:       ".$sections->{'ucd_memory'}."\n";
		print "UCD-DISKIO:     ".$sections->{'ucd_diskio'}."\n";
		print "TCP-MIB:        ".$sections->{'tcp'}."\n";
	}
}

sub debug
{
	my $msg = shift;
	if ($debugging) {
		print STDERR $msg;
	}
}
