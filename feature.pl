#!/usr/bin/perl
#
## feature.pl -- turn an optional feature on or off using risc_discovery.features

use strict;
use RISC::riscUtility;

my $operation = shift;
my $feature = shift;
my $status = shift;	## optional, only for the 'add' or 'set' operations

unless (defined($feature) and defined($operation)) {
	usage();
	exit(1);
}

my $db = riscUtility::getDBH('risc_discovery',1);

if ($operation eq 'enable') {
	if (feature_exists()) {
		$db->do("update features set val=1 where name='$feature'");
		print "$feature has been enabled\n";
	} else {
		print "$feature does not exist\n";
	}
} elsif ($operation eq 'disable') {
	if (feature_exists()) {
		$db->do("update features set val=0 where name='$feature'");
		print "$feature has been disabled\n";
	} else {
		print "$feature does not exist\n";
	}
} elsif ($operation eq 'set') {
	unless (defined($status)) {
		usage();
		exit(1);
	}
	$status = 1 if ($status =~ /^on$/i);
	$status = 0 if ($status =~ /^off$/i);
	if (feature_exists()) {
		$db->do("update features set val='$status' where name='$feature'");
		print "$feature has been set to $status\n";
	} else {
		print "$feature does not exist\n";
	}
} elsif ($operation eq 'add') {
	$status = 1 unless (defined($status));
	$status = 1 if ($status =~ /^on$/i);
	$status = 0 if ($status =~ /^off$/i);
	if (feature_exists()) {
		my $currentstate = $db->selectrow_hashref("select val from features where name = '$feature'")->{'val'};
		print "$feature already exists with state $currentstate\n";
	} else {
		$db->do("insert into features (name,val) values ('$feature','$status')");
		print "$feature has been added with state $status\n";
	}
} elsif ($operation eq 'remove') {
	if (feature_exists()) {
		$db->do("delete from features where name = '$feature'");
		print "$feature has been removed\n";
	} else {
		print "$feature does not exist\n";
	}
} elsif ($operation eq 'status') {
	if (feature_exists()) {
		my $currentstate = riscUtility::checkfeature($feature);
		$currentstate = '(undefined)' if (!defined($currentstate));
		print "$feature status is $currentstate\n";
	} else {
		print "$feature does not exist\n";
	}
} else {
	usage();
	exit(1);
}

sub feature_exists {
	my $exists = $db->selectrow_hashref("select count(*) as e from features where name = '$feature'")->{'e'};
	return 1 if $exists;
	return 0;
}

sub usage {
	print "usage: perl feature.pl <operation> <feature> [<status>]\n";
	print "       perl feature.pl enable foo      sets value of 'foo' to 1 (on)\n";
	print "       perl feature.pl disable foo     sets value of 'foo' to 0 (off)\n";
	print "       perl feature.pl set foo bar     sets value of 'foo' to 'bar'\n";
	print "       perl feature.pl add foo         creates feature 'foo' with value 1\n";
	print "       perl feature.pl add foo 1       creates feature 'foo' with value 1\n";
	print "       perl feature.pl add foo on      creates feature 'foo' with value 1\n";
	print "       perl feature.pl add foo off     creates feature 'foo' with value 0\n";
	print "       perl feature.pl remove foo      removes feature 'foo'\n";
	print "       perl feature.pl status foo      prints status of feature 'foo'\n";
}

