#!/usr/bin/perl
#
##
use strict;
use Data::Dumper;
use RISC::riscUtility;
use RISC::riscWebservice;
use RISC::Collect::Logger;
use RISC::Event qw( collector_alarm );

my $logger = RISC::Collect::Logger->new('licensing::update');
if ($ENV{'DEBUG'}) {
	$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
}

print "||&||\n";	## begin FDP delimiter

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

$logger->debug('getting appliance authentication parameters');
my $auth = riscUtility::getApplianceAuth($mysql);
unless ($auth) {
	abrt('failed to get appliance authentication parameters');
}

## determine whether licensing should be enforced
## if not, we expect the `licensed` table to contain a single record,
##   where the `ip` field is the string `no enforcement`

$logger->debug('determining enforcement policy');
my $retries = 0;
my $enforcement;
while ((not defined $enforcement->{'returnStatus'}) && $retries < 5) {
	$logger->warn(sprintf('determining enforcement retry %d', $retries)) if ($retries);
	$enforcement = riscWebservice::checkLicenseEnforcement($auth->{'assesscode'},$auth->{'mac'});
	sleep 10 unless (defined($enforcement->{'returnStatus'}));
	$retries++;
}

if ($retries == 5) {
	## unable to determine enforcement -- don't modify current license cache
	my $message = 'unable to determine enforcement, using existing cache';
	$logger->error($message);
	abrt($message);
} elsif ($enforcement->{'returnStatus'} ne 'success') {
	my $message = sprintf(
		'error checking enforcement: %s',
		$enforcement->{'returnStatusDetail'}
	);
	$logger->error($message);
	abrt($message);
} elsif ($enforcement->{'num'} eq 0) {
	## not enforcing licensing
	$logger->info('not enforcing');
	$mysql->do("truncate table licensed");
	$mysql->do("insert into licensed (ip) select 'no enforcement'");
	exit(0);
}

## pull the cache of licensed devices, each represented as md5 digest of its deviceid
## these need to be resolved back to deviceid-ip pairs
## if a single record is returned with a hash of 'none', then we have no licensed devices
##   and the cache should be truncated

$retries = 0;
my $licenses;
while ((not defined $licenses->{'returnStatus'}) && $retries < 5) {
	$logger->warn(sprintf('pulling licensing retry %d', $retries)) if ($retries);
	$licenses = pullLicenses($auth);
	if (defined($licenses->{'returnStatus'}) and ($licenses->{'returnStatus'} eq 'success')) {
		last;
	} else {
		undef $licenses;
		sleep 10;
		$retries++;
	}
}

if ($retries == 5) {
	## failed to get data back from api
	my $message;
	if (defined($licenses)) {
		$message = sprintf(
			'error fetching licensing list: %s',
			$licenses->{'returnStatus'}
		);
	} else {
		$message = 'no response from licensing call';
	}
	abrt($message);
} elsif ((ref($licenses->{'licenses'}) eq 'ARRAY') && ($licenses->{'licenses'}[0]->{'devHash'} eq 'none')) {
	## enforceing licensing, but no devices are licensed
	$mysql->do("truncate table licensed");
	$logger->info('nothing licensed');
	exit(0);
}

## resolve device digests back to deviceid-ip pairs

$logger->debug('building local device digests');
my $devMap = $mysql->selectall_hashref("
	SELECT deviceid,CAST(MD5(deviceid) AS CHAR) AS hash,GROUP_CONCAT(ip) AS allips
		FROM visiodevices
		GROUP BY deviceid
	UNION
	SELECT windowsosid AS deviceid,CAST(MD5(windowsosid) AS CHAR) AS hash, GROUP_CONCAT(ip) AS allips
		FROM riscvmwarematrix
		INNER JOIN visiodevices USING (deviceid)
		GROUP BY deviceid
","hash");

## create an insert stub
my $insertStub = "insert into tmp_licensed (deviceid,ip,expires,flow) values ";
my $insertStatement = $insertStub;

$logger->debug('resolving digests to deviceid/ip');
my $total_digests = 0;
my @invalid_digests;	## device hashes that cannot be resolved to a device
foreach my $devHash (@{$licenses->{'licenses'}}) {
	$total_digests++;
	my $devMapping = $devMap->{$devHash->{'devHash'}};
	unless (defined($devMapping)) {
		## this digest does not resolve to a device
		## keep track of any of these, so we can alarm on them later
		$logger->warn("failed to resolve digest: $devHash->{'devHash'}");
		push(@invalid_digests, $devHash->{'devHash'});
		next;
	}
	my $deviceid	= $devMapping->{'deviceid'};
	my $expires	= $devHash->{'expires'};
	my $flow	= $devHash->{'flow'};
	my @ips		= split(',', $devMapping->{'allips'});
	foreach my $ip (@ips) {
		$insertStatement .= "($deviceid,'$ip',$expires,$flow),";
	}
}
$logger->debug(sprintf('processed %d digests', $total_digests));

## if the built insert matches the stub, than no devices were resolved
if ($insertStatement eq $insertStub) {
	if (@invalid_digests) {
		$mysql->do('truncate table licensed');
		alarm_on_map_failures();
		abrt('failed to resolve all devices, truncated licensing list');
	} else {
		## this should not be reached:
		##	we are enforcing
		##	we successfully returned from the call
		##	we did not receive the 'none' condition,
		##	we did not fail to resolve any devices
		## so... the return is just plain empty
		abrt('invalid context: enforcing licensing, successful API return, no failed resolutions, did not match none condition');
	}
}
alarm_on_map_failures();

chop($insertStatement);

## insert into temporary table, then flip them

$logger->debug('inserting to tmp_licensed');
$mysql->do("drop table if exists tmp_licensed");
$mysql->do("create table tmp_licensed like licensed");
$mysql->do($insertStatement);

$logger->debug('rolling licensed --> licensed_backup, tmp_licensed --> licensed');
$mysql->do("drop table if exists licensed_backup");
$mysql->do("alter table licensed rename licensed_backup");
$mysql->do("alter table tmp_licensed rename licensed");

$logger->info('success');
print "||&||\n";	## end FDP delimiter
exit(0);


sub pullLicenses {
	my $auth = shift;
	$logger->debug('pulling licensing list');
	my $res;
	if ($auth->{'onprem'}) {
		$res = riscWebservice::consumptionUpdateLicenses($auth->{'mac'},$auth->{'assesscode'},$auth->{'consumption'});
		unless (($res) and ($res->{'returnStatus'} eq 'success')) {
			return $res;
		}
		## pack device hash into an array ref if not already, ie, only one device licensed
		unless (ref $res->{'licenses'} eq 'ARRAY') {
			my @l = ($res->{'licenses'});
			$res->{'licenses'} = \@l;
		}
		return $res;
	} else {
		$res = riscWebservice::updateLicenses($auth->{'assesscode'},$auth->{'mac'});
		unless (($res) and ($res->{'returnStatus'} eq 'success')) {
			return $res;
		}
		## pack device hash into an array ref if not already, ie, only one device licensed
		unless (ref $res->{'licenses'} eq 'ARRAY') {
			$logger->debug('response not an array: forcing into an array');
			my @l = ($res->{'licenses'});
			$res->{'licenses'} = \@l;
		}
		return $res;
	}
}

sub alarm_on_map_failures {
	my $invalid = scalar @invalid_digests;
	return unless ($invalid);
	eval {
		collector_alarm(
			'licensing',
			$0,
			sprintf(
				'%d of %d digests could not be resolved: %s',
				$invalid,
				$total_digests,
				join(',', @invalid_digests)
			)
		);
	};
}

sub abrt {
	my ($err) = @_;
	chomp($err);
	collector_alarm('licensing', $0, $err);
	print "||&||\n";
	exit(1);
}
