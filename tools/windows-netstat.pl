#!/usr/bin/perl
#
##
use strict;
use RISC::riscUtility;
use RISC::riscCreds;
use RISC::riscWindows;
use Data::Dumper;

my $report;

my $target	= shift;
my $cmdmethod	= shift;

$cmdmethod = 'new' unless ($cmdmethod);
if ($cmdmethod =~ /new|wmiexec/) {
	$cmdmethod = 'wmiexec';
} elsif ($cmdmethod =~ /legacy|winexe/) {
	$cmdmethod = 'winexe';
} else {
	report("invalid netstat method, use one of ('new'/'wmiexec'),('legacy'/'winexe')");
	exit(1);
}

my ($db,$credobj,$cred);

eval {
	$db = riscUtility::getDBH('RISC_Discovery',1);

	my $credid = $db->selectrow_hashref("
		SELECT credentialid
		FROM riscdevice
		INNER JOIN credentials USING (deviceid)
		WHERE ipaddress = '$target'
	");

	unless (($credid) and ($credid->{'credentialid'})) {
		report("no credential for the ip");
		exit(1);
	}

	$credobj = riscCreds->new($target);
	$cred = $credobj->getWin($credid->{'credentialid'});

}; if ($@) {
	chomp(my $err = $@);
	report("exception during setup: $err");
	exit(1);
}

my $wmi = RISC::riscWindows->new({
		user		=> $cred->{'user'},
		password	=> $cred->{'password'},
		domain		=> $cred->{'domain'},
		credid		=> $cred->{'credid'},
		host		=> $target,
		db			=> $db,
		wincmd_method	=> $cmdmethod,
		debug		=> 1
	});
unless ($wmi->connected()) {
	report("failed to connect: ".$wmi->err());
	exit(1);
}

###########

my $netstat = gatherNetstat($wmi);
report("result:($cmdmethod) " . Dumper($netstat));
exit(0);

###########

sub gatherNetstat {
	my ($wmi) = @_;
	my $return = {
		'status' => 0,
		'detail' => 'no response from netstat attempt'
	};
	my $netstatRet = $wmi->wincmd('netstat -anop TCP');
	return $return unless ($netstatRet);
	if ($netstatRet->{'stdout'}) {
		my $c = 0;                                            ## connection insert count
		my @lines = split(/\r\n/, $netstatRet->{'stdout'});
		shift @lines;                                         ## trash header line (empty line)
		shift @lines;                                         ## trash header line ("Active Connections")
		shift @lines;                                         ## trash header line (empty line)
		shift @lines;                                         ## trash header line (column headers)
		foreach my $rec (@lines) {
			next if (($rec eq '') or ($rec =~ /^\s+$/));      ## skip empty lines
			$rec =~ s/^\s+//g;                                ## strip leading whitespace
			my ($proto, $local, $remote, $state, $pid) = split(/\s+/, $rec);
			my ($laddr, $lport) = split(/:/, $local);
			my ($faddr, $fport) = split(/:/, $remote);
			$c++;
		}
		if ($c > 0) {
			$return->{'status'} = 1;
			$return->{'detail'} = "parsed $c connections";
		} else {
			if ($netstatRet->{'stdout'}) {
				$return->{'detail'} = $netstatRet->{'stdout'};
			} else {
				$return->{'detail'} = "parsed 0 netstat records";
			}
		}
	} else {
		if ($netstatRet->{'stdout'}) {
			$return->{'detail'} = $netstatRet->{'stdout'};
		} else {
			$return->{'detail'} = 'unknown error from netstat attempt';
		}
	}
	return $return;
}

###########

sub report {
	my ($msg) = @_;
	$msg = $report unless (defined($msg));
	chomp($msg);
	print STDOUT '||&||'. $msg . '||&||';
}

