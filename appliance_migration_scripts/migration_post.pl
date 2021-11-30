#!/usr/bin/perl

use RISC::Collect::Logger;
use Data::Dumper;

use strict;
use warnings;

my ($auth, $assesscode, $type) = @ARGV;

my $logger = RISC::Collect::Logger->new('migration_post');

logprint($0 . ': got argv: ' . join(',', @ARGV));

my @post_cmds = ();

if ($type eq 'fdp') {
	push(@post_cmds, '/usr/bin/perl /home/risc/appliance_migration_scripts/migration_check_pod.pl');
}

push(@post_cmds, '/usr/bin/perl /home/risc/appliance_migration_scripts/migration_new_cleanup.pl');

push(@post_cmds, '/usr/bin/perl /home/risc/startAllPerf.pl');

foreach my $cmd (@post_cmds) {
	logprint('running cmd: ' . $cmd);

	my $output = qx($cmd 2>&1);
	logprint('output was: ' . $output);
	($?) and do {
		logprint('non-zero return status from "' . $cmd . '": ' . $?);
		exit(1);
	}
}

sub logprint {
	print(@_, "\n");
	$logger->info(@_);
}
