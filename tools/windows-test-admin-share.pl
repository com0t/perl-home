#!/usr/bin/env perl
#
##
use strict;
use Data::Dumper;
use RISC::riscUtility;
use RISC::riscCreds;

use Getopt::Long qw(
	:config
	require_order
	bundling
	no_ignore_case
);

my $client_script	= 'smbclient.py';
my $command_file	= '/home/risc/tools/smb_test_commands';

my $clean_output;

my (
	$target,
	$expl_cmd_file,
	$cred_id,
	$interactive
);

GetOptions(
	't=s'		=> \$target,
	'f=s'		=> \$expl_cmd_file,
	'c=i'		=> \$cred_id,
	'i'		=> \$interactive
);

abrt("usage: $0 <target-ip> [command-file]") unless ($target);
abrt("ERROR: no such test script: $client_script") unless (-x $client_script);

$command_file = $expl_cmd_file if ($expl_cmd_file);
abrt("ERROR: no such command file: $command_file") unless (-e $command_file);

my ($deviceid,$scoped_ip);
unless ($cred_id) {
	my $db = riscUtility::getDBH('RISC_Discovery');

	my $devQ = $db->selectrow_hashref("
		SELECT deviceid,ipaddress,credentialid
		FROM visiodevices v
		INNER JOIN riscdevice r USING (deviceid)
		INNER JOIN credentials c USING (deviceid)
		WHERE v.ip = ?
	",undef,$target);
	unless (($devQ) and ($devQ->{'credentialid'})) {
		abrt('ERROR: unknown device, perhaps try again with -c <cred_id>');
	}

	$cred_id	= $devQ->{'credentialid'};
	$deviceid	= $devQ->{'deviceid'};
	$scoped_ip	= $devQ->{'ipaddress'};
}

my $credobj = riscCreds->new($target);
my $cred = $credobj->getWin($cred_id);
unless ($cred) {
	abrt("ERROR: unable to provision credential: $credobj->{'error'}");
}

clean_output("----> using command file: $command_file");
clean_output("----> using credentialid: $cred_id");
clean_output("----> device is $deviceid with scoped ip $scoped_ip");

my $command = sprintf("%s%s %s '%s:%s@%s'",
	$client_script,
	($ENV{'DEBUG'}) ? ' -debug' : '',
	($interactive) ? '' : join(' ','-file',$command_file),
	$cred->{'user'},
	$cred->{'password'},
	$target
);

if ($interactive) {
	exec($command);
	exit(0); ## unreachable
}

my $resp = `$command`;
clean_output(sprintf("----> {\n%s\n}\n",$resp));
print_clean_output();
exit(0);

sub clean_output {
	my ($message) = @_;
	$clean_output = join("\n",$clean_output,$message);
}

sub print_clean_output {
	my $explicit_output = shift;
	$clean_output = $explicit_output if ($explicit_output);
	$clean_output = 'no output' unless ($clean_output);
	printf("||&||%s||&||\n",$clean_output);
}

sub abrt {
	my $message = shift;
	print_clean_output($message);
	exit(1);
}

__END__

=head1 NAME

windows-test-admin-share.pl

=head1 SYNOPSIS

perl windows-test-admin-share.pl -t <target-ip> [-i] [-f <command-file>] [-c <cred-id>]

=head1 DESCRIPTION

Uses the C<smbclient.py> utility as part of the C<impacket> distribution to connect
to a Windows device over SMB and test access to the C<ADMIN$> share.

By default, the script will use the file C</home/risc/tools/smb_test_commands> which
contains a sequence of C<smbclient.py> commands to test access, where it will A) list
the shares that are available, B) attempt to connect to the C<ADMIN$> share, then C)
disconnect.

If the C<ADMIN$> share is not listed in the output, then it is unavailable. If it is
listed, but the attempt to connect to it (C<use ADMIN$>) is followed by an error
message (C<NT_STATUS_*>), then there is a permissions and/or configuration issue
preventing collection processes from accessing the share.

Unless run with the C<-i> option (which should not be used through command-and-control),
the results will be printed on STDOUT, within the delimiter characters that allow
the output to pass back through command-and-control channel in an FDP deployment
scenario.

By default, unless the C<-c> option is provided, the correct credential to use is
looked up by determining the C<deviceid> corresponding to the IP address, then
looking up the cred mapping for that C<deviceid>. This allows testing to a device
using an IP address other than the scoped IP, without needing to look up which
credential a device is associated with.

For particular testing scenarios, a specific credential can be specified by id
using C<-c>, but care should be taken when using this.

=head1 OPTIONS

=over

=item -t <target-ip>

the IP address of the target device, required

=item -i

run in interactive mode, use with caution

=item -f <command-file>

override the default command file

=item -c <cred-id>

use a specific credential by id, rather than looking up the correct one based on discovery

=back

=cut
