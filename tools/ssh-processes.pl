#!/usr/bin/perl
#
##
use strict;
use RISC::riscCreds;
use RISC::riscUtility;
use RISC::riscSSH;
use Data::Dumper;

my $target	= shift;

unless ($target =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
	print "!!!! target is not an ip address\n";
	exit(1);
}

my $db = riscUtility::getDBH('RISC_Discovery',1);

my $device = $db->selectrow_hashref("
	SELECT deviceid,ipaddress,credentialid
	FROM riscdevice
	INNER JOIN credentials using (deviceid)
	WHERE ipaddress = '$target'
");

my $credid;
if (defined($device) and (defined($device->{'credentialid'}))) {
	$credid = $device->{'credentialid'};
	print "====> dumping gensrvprocesses collection for $device->{'deviceid'}, $target, $credid\n";
} else {
	print "!!!! failed to determine credentialid for $target\n";
	exit(1);
}

$db->disconnect();

my $credobj = riscCreds->new($target);
my $cred = $credobj->getGenSrvSSH($credid);
unless ($cred) {
	$credobj->print_error();
	print "!!!! failed to get credential data for credid $credid\n";
	exit(1);
}
$credobj->disconnect();

my $ssh = RISC::riscSSH->new({ 'debug' => 1 });
$ssh->connect($target,$cred);
unless($ssh->{'connected'}) {
	$ssh->print_error();
	exit(1);
}

my $proc;
if ($ssh->{'os'} eq 'Linux') {
	my $psraw = $ssh->cmd("ps axwww --no-headers -o pid,cputime,rsz,command");
	if ($psraw) {
		my @lines = split(/\n/,$psraw);
		foreach my $line (@lines) {
			if ($line =~ /(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)\s+(.*)/) {
				my $pid = $1;
				$proc->{$pid}->{'pid'} = $pid;
				my $hours = $2;
				my $minutes = $3;
				my $seconds = $4;
				my $cputime = (($hours * (60*60)) + ($minutes * 60) + $seconds) * 100; ## convert to centi-seconds per SNMP format
				$proc->{$pid}->{'perfcpu'} = $cputime;
				$proc->{$pid}->{'perfmem'} = $5;
				my $process = $6;
				if ($process =~ /(\S+)(\s(.*)|)/) {
					$proc->{$pid}->{'path'} = $1;
					$proc->{$pid}->{'args'} = $2;
					$proc->{$pid}->{'name'} = $proc->{$pid}->{'path'};
					if ($proc->{$pid}->{'path'} =~ /^\//) {
						$proc->{$pid}->{'name'} =~ s/^.*[\/\\]//;
					}

				}
				$proc->{$pid}->{'runid'} = 0;
				if ($proc->{$pid}->{'perfmem'} == 0) {		## kernel threads won't use user memory, flag these as type OS
					$proc->{$pid}->{'runtype'} = 'operatingSystem';
				} else {
					$proc->{$pid}->{'runtype'} = 'application';
				}
				$proc->{$pid}->{'runstatus'} = 'running';
			} else {
				print "!!!! failed to parse the entry {\n\t$line\n}\n";
			}
		}
	}
} elsif ($ssh->{'os'} eq 'AIX') {
	my $psraw = $ssh->cmd("ps -e -o pid,cputime,rssize,args");
	if ($psraw) {
		my @psraw = split(/\n/,$psraw);
		shift @psraw; ## header
		foreach my $line (@psraw) {
			my ($pid,$cpu,$rss,$cmd) = $line =~ /(\d+)\s+(\S+)\s+(\d+)\s+(.*)$/;
			$proc->{$pid}->{'pid'} = $pid;
			$proc->{$pid}->{'perfmem'} = $rss;
			my ($hour,$min,$sec) = split(/:/,$cpu);
			$proc->{$pid}->{'perfcpu'} = (($hour*(60*60)) + ($min*60) + $sec) * 100; ## centi-seconds
			my @proc = split(/\s+/,$cmd);
			my $name = $proc[0];
			$proc->{$pid}->{'path'} = $name;
			$name =~ s/^.*[\/\\]//;
			$proc->{$pid}->{'name'} = $name;
			shift @proc;
			$proc->{$pid}->{'args'} = join(" ",@proc);
			## static snmp stuff
			$proc->{$pid}->{'runid'} = 0;
			$proc->{$pid}->{'runstatus'} = 'running';
			$proc->{$pid}->{'runtype'} = 'application'; ## we requested only applications (not kernel stuff) in the ps commmand
		}
	}
}

print Dumper($proc);

