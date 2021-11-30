#!/usr/bin/perl
#
##
use strict;
use RISC::riscWindows;
use RISC::riscCreds;
use Data::Dumper;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));


my $target	= shift;
my $cred_id	= shift;


my $credobj = riscCreds->new($target);
my $cred = $credobj->getWin($cred_id);
unless ($cred) {
	$credobj->print_error();
	abrt('failed to fetch credential');
}

dbg('connecting');
my $wmi = RISC::riscWindows->new({
		user		=> $cred->{'user'},
		password	=> $cred->{'password'},
		domain		=> $cred->{'domain'},
		credid		=> $cred->{'credid'},
		host		=> $target,
		debug		=> $debugging
	});
unless ($wmi->connected()) {
	abrt("failed to connect: ".$wmi->err());
}

dbg('connected');
dbg('begin collection');
####



####

dbg('finished');
exit(0);


sub dbg {
	my ($str) = @_;
	return unless ($debugging);
	chomp($str);
	print STDERR "$0::${target}::DEBUG: $str\n";
}

sub dbg_dump {
	my ($data,$header) = @_;
	$header = 'DUMP' unless (defined($header));
	print STDERR "$0::${target}::$header: ".Dumper($data);
}

sub abrt {
	my ($str) = @_;
	chomp($str);
	print STDERR "$0::${target}::ABORT: $str\n";
	exit(1);
}

