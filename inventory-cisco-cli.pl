#!/usr/bin/env perl
#
##
use RISC::riscUtility;
use RISC::CiscoCLI;
use File::Temp qw(tempfile);
use Data::Dumper;


my $address   = shift;
my $clidevid  = shift;
my $transport = shift;
my $username  = shift;
my $password  = shift;
my $enable    = shift;

my $mysql = riscUtility::getDBH('RISC_Discovery', 1);

my $insertCLIInfo  = $mysql->prepare("
	INSERT INTO cdscli
	(deviceid,showversion,showdiag,showinventory,showmodule,showhardware,showidprom,showrun,showconfig,showmlsqos,showmlsqosint,showmlsqosintstats,showpolicyint,showlog,showinterface,showcallactivevoicebrief,showmlsqosmaps,showasicdrops,log,scantime)
	VALUES
	(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,unix_timestamp(now()))
");

my $insertCLIInfo2 = $mysql->prepare("
	INSERT INTO cdscli
	(deviceid,showversion,showdiag,showinventory,showmodule,showhardware,showidprom,showrun,showconfig,showmlsqos,showmlsqosint,showmlsqosintstats,showpolicyint,showlog,showinterface,showcallactivevoicebrief,showmlsqosmaps,showasicdrops,showWaasStatus,showLicense,showLicenseAll,showLicenseDetail,showLicenseFeature,showLicenseFile,showLicenseFeatureMapping,showLicenseRightUsage,showLicenseRightDetail,showLicenseRightSummary,showLicenseUsage_LAN_ENTERPRISE_SERVICES_PKG,showLicenseUsage_NETWORK_SERVICES_PKG,showLicenseUsage_LAN_ENTERPRISE_ADVANCED_PKG,showLicenseUsage_LAN_TRANSPORT_SERVICES_PKG,showLicenseUsage_ENHANCED_LAYER_PKG,showLicenseUsage_MPLS_PKG,showLicenseUsage_FCOE_F2,showLicenseUsage_STORAGE_ENT,showLicenseUsage_SCALABLE_SERVICES_PKG,showLicenseUsage_NEXUS1000V_LAN_SERVICES_PKG,log,scantime)
	VALUES
	(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,unix_timestamp(now()))
");

my $telnetResult	= 1;
my $returnHash		= '';

my $logfile	= (tempfile(UNLINK => 1))[1];

$telnetResult	= riscUtility::testTCPSocket($address, 23) if $transport =~ /telnet/i;
$telnetResult	= riscUtility::testTCPSocket($address, 22) if $transport =~ /ssh/i;

$username	= riscUtility::decode($username) if defined $username;
$password	= riscUtility::decode($password) if defined $password;
$enable		= riscUtility::decode($enable)   if defined $enable;

my $nxQuery = $mysql->selectrow_hashref("
	SELECT sysdescription
	FROM riscdevice
	WHERE deviceid=$clidevid
");

$enable		= 'null' if $nxQuery->{'sysdescription'} =~ /NX/;
$username	= 'null' unless defined $username;
$password	= 'null' unless defined $password;
$enable		= 'null' unless defined $enable;

$returnHash	= RISC::CiscoCLI::connectCLITelnet($address, $username, $password, $enable, $logfile) if $transport =~ /telnet/i && !defined $telnetResult;
$returnHash	= RISC::CiscoCLI::connectCLISSH($address, $username, $password, $enable, $logfile) if $transport =~ /ssh/i && !defined $telnetResult;
my $clilog	= RISC::CiscoCLI::parseCLILog($logfile);

if (ref($returnHash) eq 'HASH') {
	eval {
		$insertCLIInfo2->execute(
			$clidevid,
			$returnHash->{'version'},
			$returnHash->{'diag'},
			$returnHash->{'inventory'},
			$returnHash->{'module'},
			$returnHash->{'hardware'},
			$returnHash->{'idprom'},
			$returnHash->{'run'},
			$returnHash->{'config'},
			$returnHash->{'mlsqos'},
			$returnHash->{'mlsqosint'},
			$returnHash->{'mlsqosintstats'},
			$returnHash->{'policyint'},
			$returnHash->{'showlog'},
			$returnHash->{'showinterface'},
			$returnHash->{'showcallactivevoicebrief'},
			$returnHash->{'showmlsqosmaps'},
			$returnHash->{'showasicdrops'},
			$returnHash->{'showWaasStatus'},
			$returnHash->{'showLicense'},
			$returnHash->{'showLicenseAll'},
			$returnHash->{'showLicenseDetail'},
			$returnHash->{'showLicenseFeature'},
			$returnHash->{'showLicenseFile'},
			$returnHash->{'showLicenseFeatureMapping'},
			$returnHash->{'showLicenseRightUsage'},
			$returnHash->{'showLicenseRightDetail'},
			$returnHash->{'showLicenseRightSummary'},
			$returnHash->{'showLicenseUsage_LAN_ENTERPRISE_SERVICES_PKG'},
			$returnHash->{'showLicenseUsage_NETWORK_SERVICES_PKG'},
			$returnHash->{'showLicenseUsage_LAN_ENTERPRISE_ADVANCED_PKG'},
			$returnHash->{'showLicenseUsage_LAN_TRANSPORT_SERVICES_PKG'},
			$returnHash->{'showLicenseUsage_ENHANCED_LAYER_PKG'},
			$returnHash->{'showLicenseUsage_MPLS_PKG'},
			$returnHash->{'showLicenseUsage_FCOE_F2'},
			$returnHash->{'showLicenseUsage_STORAGE_ENT'},
			$returnHash->{'showLicenseUsage_SCALABLE_SERVICES_PKG'},
			$returnHash->{'showLicenseUsage_NEXUS1000V_LAN_SERVICES_PKG'},
			$clilog
		);
	};
	$insertCLIInfo->execute(
		$clidevid,
		$returnHash->{'version'},
		$returnHash->{'diag'},
		$returnHash->{'inventory'},
		$returnHash->{'module'},
		$returnHash->{'hardware'},
		$returnHash->{'idprom'},
		$returnHash->{'run'},
		$returnHash->{'config'},
		$returnHash->{'mlsqos'},
		$returnHash->{'mlsqosint'},
		$returnHash->{'mlsqosintstats'},
		$returnHash->{'policyint'},
		$returnHash->{'showlog'},
		$returnHash->{'showinterface'},
		$returnHash->{'showcallactivevoicebrief'},
		$returnHash->{'showmlsqosmaps'},
		$returnHash->{'showasicdrops'},
		$clilog
	) if ($@);
} else {
	$enable     = 'null';
	$returnHash = RISC::CiscoCLI::connectCLITelnet($address, $username, $password, $enable, $logfile) if $transport =~ /telnet/i && !defined $telnetResult;
	$returnHash = RISC::CiscoCLI::connectCLISSH($address, $username, $password, $enable, $logfile) if $transport =~ /ssh/i && !defined $telnetResult;
	my $clilog = RISC::CiscoCLI::parseCLILog($logfile);
	if (ref($returnHash) eq 'HASH') {
		eval {
			$insertCLIInfo2->execute(
				$clidevid,
				$returnHash->{'version'},
				$returnHash->{'diag'},
				$returnHash->{'inventory'},
				$returnHash->{'module'},
				$returnHash->{'hardware'},
				$returnHash->{'idprom'},
				$returnHash->{'run'},
				$returnHash->{'config'},
				$returnHash->{'mlsqos'},
				$returnHash->{'mlsqosint'},
				$returnHash->{'mlsqosintstats'},
				$returnHash->{'policyint'},
				$returnHash->{'showlog'},
				$returnHash->{'showinterface'},
				$returnHash->{'showcallactivevoicebrief'},
				$returnHash->{'showmlsqosmaps'},
				$returnHash->{'showasicdrops'},
				$returnHash->{'showWaasStatus'},
				$returnHash->{'showLicense'},
				$returnHash->{'showLicenseAll'},
				$returnHash->{'showLicenseDetail'},
				$returnHash->{'showLicenseFeature'},
				$returnHash->{'showLicenseFile'},
				$returnHash->{'showLicenseFeatureMapping'},
				$returnHash->{'showLicenseRightUsage'},
				$returnHash->{'showLicenseRightDetail'},
				$returnHash->{'showLicenseRightSummary'},
				$returnHash->{'showLicenseUsage_LAN_ENTERPRISE_SERVICES_PKG'},
				$returnHash->{'showLicenseUsage_NETWORK_SERVICES_PKG'},
				$returnHash->{'showLicenseUsage_LAN_ENTERPRISE_ADVANCED_PKG'},
				$returnHash->{'showLicenseUsage_LAN_TRANSPORT_SERVICES_PKG'},
				$returnHash->{'showLicenseUsage_ENHANCED_LAYER_PKG'},
				$returnHash->{'showLicenseUsage_MPLS_PKG'},
				$returnHash->{'showLicenseUsage_FCOE_F2'},
				$returnHash->{'showLicenseUsage_STORAGE_ENT'},
				$returnHash->{'showLicenseUsage_SCALABLE_SERVICES_PKG'},
				$returnHash->{'showLicenseUsage_NEXUS1000V_LAN_SERVICES_PKG'},
				$clilog
			);
		};
		$insertCLIInfo->execute(
			$clidevid,
			$returnHash->{'version'},
			$returnHash->{'diag'},
			$returnHash->{'inventory'},
			$returnHash->{'module'},
			$returnHash->{'hardware'},
			$returnHash->{'idprom'},
			$returnHash->{'run'},
			$returnHash->{'config'},
			$returnHash->{'mlsqos'},
			$returnHash->{'mlsqosint'},
			$returnHash->{'mlsqosintstats'},
			$returnHash->{'policyint'},
			$returnHash->{'showlog'},
			$returnHash->{'showinterface'},
			$returnHash->{'showcallactivevoicebrief'},
			$returnHash->{'showmlsqosmaps'},
			$returnHash->{'showasicdrops'},
			$clilog
		) if ($@);
	} else {
		my $errorInsert = $mysql->prepare("
			INSERT INTO inventoryerrors
			(deviceid,deviceip,domain,winerror,scantime)
			values
			(?,?,?,?,?)
		");
		$errorInsert->execute($clidevid, $address, 'N/A', $clilog, time());
	}
}

exit(0);
