#!/usr/bin/perl
#
## bstrap.pl -- download and deploy distribution archives

use strict;
use File::Slurp;
$|++;

## BEGIN

## arguments
my $auth = shift;	## authentication code, arg10 from commandandcontrol
my $assesscode = shift;
my $type = shift;

abort("no authentication code") unless ($auth);
abort("no assessment code") unless ($assesscode);

$type = 'scripts' unless ($type);

# Only perform an update/install if type is scripts.
unless($type eq 'scripts') {
	print STDOUT ("skipping type '$type'\n");
	exit(0);
}

# TODO -  MON-406: Create Freeze Mechanism
$ENV{DEBIAN_FRONTEND} = 'noninteractive';
my $cmd = 'apt-get -q update 2>&1 && apt-get -q -y install rn150-base rn150-scripts-common rn150-scripts-contrib rn150-web rn150-scripts 2>&1';
my $authConfig = '/etc/apt/auth.conf.d/risc.conf';

chomp(my $psk = read_file("/etc/riscappliancekey"));
if(!length($psk)) {
	abort("Could not get PSK\n");
}

open(my $file, '>' . $authConfig)
	or abort("bstrap failed on authentication: Could not write to $authConfig: $!\n");

print $file ("machine initial.riscnetworks.com login $assesscode password $psk\n");

close($file);

if(!system($cmd)) {
	print STDOUT ("bstrap successful\n");
	exit(0);
} else {
	abort("bstrap failed\n");
}

## FINISH
#
## subs --->

## produce an error message on stdout (return to caller)
## exit with error status (1)
sub abort {
	my $msg = shift;
	print STDOUT "FAILED: $msg\n";
	exit(1);
}
