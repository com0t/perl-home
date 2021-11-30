#!/usr/bin/perl
use strict;
use Data::Dumper;
use Net::IP;
use RISC::riscUtility;

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

$mysql2->do("
	DELETE FROM discoverystats
	WHERE (status = 5 OR status = 6)
		AND filename IS NULL
");

# retreive reported routes
my $routelookup = $mysql->prepare("
	SELECT
		ipRouteDest,
		ipRouteMask,
		inet_aton(ipRouteDest) AS bottomint,
		(inet_aton(ipRouteDest)+(inet_aton('255.255.255.255')-inet_aton(ipRouteMask))) AS topint
	FROM iproutes
	WHERE
		ipRouteDest != '0.0.0.0'
		AND inet_aton(ipRouteMask) >= 4294901760
		AND ipRouteMask IS NOT null
		AND ipRouteDest IS NOT null
	GROUP BY ipRouteDest,ipRouteMask
");
$routelookup->execute();

my $routes;
while (my $route = $routelookup->fetchrow_hashref()) {
	my $r = $route->{'ipRouteDest'};
	my $sm = $route->{'ipRouteMask'};
	my $topint = $route->{'topint'};
	my $bottomint = $route->{'bottomint'};
	$routes->{$r}->{'sm'} = $sm;
	$routes->{$r}->{'top'} = $topint;
	$routes->{$r}->{'bottom'} = $bottomint;
	$routes->{$r}->{'hosts'} = $topint-$bottomint;
}

# retrieve scanned subnets
my $scanlookup = $mysql2->prepare("
	SELECT
		substring_index(iprange,'/',1) AS route,
		inet_ntoa((4294967296 - (pow(2,(32-(substring_index(iprange,'/',-1))))))) AS sm,
		inet_aton(substring_index(iprange,'/',1)) AS bottomint,
		inet_aton(substring_index(iprange,'/',1))+(pow(2,(32-(substring_index(iprange,'/',-1)))))-1 AS topint
	FROM discoverystats
	WHERE
		status = 2
		OR status = 1
		OR status = 6
	");
$scanlookup->execute();

my $scans;
while (my $scan = $scanlookup->fetchrow_hashref()) {
	my $r = $scan->{'route'};
	my $sm = $scan->{'sm'};
	my $topint = $scan->{'topint'};
	my $bottomint = $scan->{'bottomint'};
	$scans->{$r}->{'sm'} = $sm;
	$scans->{$r}->{'top'} = $topint;
	$scans->{$r}->{'bottom'} = $bottomint;
	$scans->{$r}->{'hosts'} = $topint-$bottomint;
}

my $subnets;
foreach my $r (keys %{$routes}) {
	my $tl = $routes->{$r}->{'bottom'};
	my $tt = $routes->{$r}->{'top'};
	my $tn = $routes->{$r}->{'hosts'};
	my $tm = $routes->{$r}->{'sm'};
	foreach my $s (keys %{$scans}) {
		my $st = $scans->{$s}->{'top'};
		my $sl = $scans->{$s}->{'bottom'};
		my $sn = $scans->{$s}->{'hosts'};
		if (($sn == -1) || $sl >= $st) {
			$st = $st;
			$sl = $st;
			$sn = 1;
		}
		# determine if the route is equal to or wholy contained by a scanned subnet
		if (($tl == $sl && $tt == $st) || ($tl >= $sl && $tt <= $st)) {
			$subnets->{$r}->{'score'} = 0;
			last;
		}
		# determine if the route is outside of a scanned subnet
		if (($tl <= $sl && ($tt <= $st || $tt >= $st))
			|| (($tt > $st) && ($tl <= $st))
			|| ($tl < $sl && $tt < $tl)
			|| ($tt > $st && $tl > $st))
		{
			$subnets->{$r}->{'score'} = 1;
			$subnets->{$r}->{'sm'} = $tm;
			$subnets->{$r}->{'hosts'} = $tn;
		}
	}
}

# risc_discovery
my $insertSubnets = $mysql2->prepare_cached("
	INSERT INTO discoverystats
	(iprange,status)
	VALUES
	(?,?)
");

# RISC_Discovery
my $insertSubnets2 = $mysql->prepare_cached("
	INSERT INTO discoverystats
	(iprange,status)
	VALUES
	(?,?)
");

foreach my $key (keys %{$subnets}) {
	my $sumask = $subnets->{$key}->{'sm'};
	my $score = $subnets->{$key}->{'score'};
	my $hosts = $subnets->{$key}->{'hosts'};
	my $base = $hosts+1;
	my $log = log($base)/log(2);
	$log = 32-$log;
	print "$key/$sumask/$hosts/$log\n" unless $score == 0;
	my $insert = $key."/".$log;
	$insertSubnets->execute($insert,5) unless $score == 0;
	$insertSubnets2->execute($insert,5) unless $score == 0;
}
