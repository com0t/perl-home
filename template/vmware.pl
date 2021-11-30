#!/usr/bin/env perl
#
##
use strict;
use Data::Dumper;
use RISC::riscCreds;
use VMware::VIRuntime;

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';

my $cred_id	= shift;
my $cred = riscCreds->new->getVMware($cred_id);
unless ($cred) {
	printf(STDERR "failed to retreive the credential\n");
	exit(1);
}

my %opts = (
	server		=> { type => '=s', required => 1 },
	username	=> { type => '=s', required => 1 },
	password	=> { type => '=s', required => 1 },
);
Opts::add_options(%opts);
map { Opts::set_option($_, $cred->{$_}) } keys %opts;
Opts::validate();

Util::connect();

####



####

Util::disconnect();
exit(0);

sub get_hosts {
	return Vim::find_entity_views(
		view_type	=> 'HostSystem',
		properties	=> [ ]
	);
}

sub get_vms {
	return Vim::find_entity_views(
		view_type	=> 'VirtualMachine',
		properties	=> [ ]
	);
}
