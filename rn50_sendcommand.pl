#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use MIME::Base64;
use IO::Socket;

my $DEFAULT_TIMEOUT	= 300; ## 5 minutes, to be super conservative

my $address	= shift;
my $command	= shift;
my $timeout	= shift;

my $result = send_command($address,$command);
if ($result) {
	print "Result is : $result\n";
} else {
	print "No result\n";
}

sub send_command {
	my $dest	= shift;
	my $command	= shift;
	my @return;

	my $sock = IO::Socket::INET->new(
		PeerAddr	=> $dest,
		PeerPort	=> 2500,
		Proto		=> 'tcp',
		Timeout		=> ($timeout) ? $timeout : $DEFAULT_TIMEOUT
	) or die("Error creating Socket: $!\n");

	$command = encode_base64($command,'');
	print $sock $command."\n";

	while (my $line = <$sock>) {
		if ($line =~ '0#0#0') {
			print $sock "0#0#0\n";
			last;
		}
		print $line;
		push(@return,$line);
	}

	close ($sock);
	my $len = @return;
	if ($len>2) {
		return @return;
	} else {
		return $return[0];
	}
}
