#!/usr/bin/perl
#
##
use strict;
use RISC::riscUtility;
use RISC::riscWindows;
use RISC::riscCreds;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));


my $target	= shift;	## IP
my $class	= shift;	## WMI class name
my $mode	= shift;	## output mode

$mode = 'stat' unless ($mode);

unless ($target =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
	abrt('target not an ip address');
}
unless ($class) {
	abrt('must supply a WMI class');
}

my $db = riscUtility::getDBH('RISC_Discovery');

my $credq = $db->selectrow_hashref("
	SELECT credentialid
	FROM credentials
	INNER JOIN riscdevice USING (deviceid)
	WHERE ipaddress = '$target'
");
unless (($credq) and ($credq->{'credentialid'})) {
	abrt('no credential for target');
}
my $credid = $credq->{'credentialid'};

my $credobj = riscCreds->new($target);
my $cred = $credobj->getWin($credid);
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
		db			=> $db
	});
unless ($wmi->connected()) {
	abrt("failed to connect: ".$wmi->err());
}

dbg('connected');
dbg('begin collection');
####

my $data = $wmi->rawObj($class);

unless ($data) {
	print STDOUT "no result\n";
	exit(0);
}

if ($data->{'code'} == 0) {
	print STDOUT "||&|| SUCCESS ||&||\n";
} else {
	if ($data->{'stdout'} =~ /NTSTATUS/) {
		## standard WMI error string
		print STDOUT "||&|| FAILURE: $data->{'stdout'} ||&||\n";
	} else {
		## error is not understood, may contain customer data
		print STDOUT "||&|| FAILURE without NTSTATUS ||&||\n";
	}
}

if ($mode eq 'dump') {
	## no FDP delimiter here
	print "DATA: ".Dumper($data);
}

exit(0);

####

dbg('finished');
exit(0);


sub dbg {
	my ($str) = @_;
	return unless ($debugging);
	chomp($str);
	print STDOUT "$0::${target}::DEBUG: $str\n";
}

sub dbg_dump {
	my ($data,$header) = @_;
	$header = 'DUMP' unless (defined($header));
	print STDOUT "$0::${target}::$header: ".Dumper($data);
}

sub err {
	my ($str) = @_;
	chomp($str);
	print STDOUT "$0::${target}::ERROR: $str\n";
}

sub abrt {
	my ($str) = @_;
	chomp($str);
	print STDOUT "$0::${target}::ABORT: $str\n";
	exit(1);
}

