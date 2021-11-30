#!/usr/bin/perl
#
##
use strict;
use RISC::riscCreds;
use RISC::riscSSH;
use Data::Dumper;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));


my $target	= shift;
my $credid	= shift;


my $credobj = riscCreds->new($target);
my $cred = $credobj->getGenSrvSSH($credid);
if ($cred->{'error'}) {
	abrt("failed to get credential: $cred->{'error'}");
}

my $ssh = RISC::riscSSH->new({
	debug		=> $debugging,
	specify_skip_db	=> 0
});
$ssh->connect($target,$cred);
unless($ssh->{'connected'}) {
	abrt($ssh->get_error());
}

unless ($ssh->supported_os()) {
	abrt("unsupported os: $ssh->{'os'}");
}

unless ($ssh->privtest()) {
	abrt("failed privilege elevation: ".$ssh->get_error());
}

####



####

sub abrt {
	my ($err) = @_;
	chomp($err);
	print "$0::ABORT: $err\n";
	exit(1);
}
