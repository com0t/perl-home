#!/usr/bin/perl -w
#use SOAP::Lite +trace=>"debug";
use SOAP::Lite;
use XML::Simple;
use Data::Dumper;
use Switch;
use Expect;
use DBI();
use RISC::riscWebservice;
use RISC::riscUtility;
use File::Slurp;

my $dbbackup="/home/risc/dbbackup";
my $key;
my $mysql;
my $onprem = 1;	## store a bit for onprem assessments for output censoring, defaults to ON
my $bstrap = 0; ## store a bit to determine whether to use new bootstrap mechanism (bstrap) or classic
eval {
	$mysql = riscUtility::getDBH('risc_discovery',1);

	my $assessKey = $mysql->prepare("select productkey from credentials where technology='appliance'");
	$assessKey->execute();
	$key = $assessKey->fetchrow_hashref()->{'productkey'};

	if ($mysql->selectrow_hashref("select testip from credentials where technology='flexpod'")->{'testip'} eq 'none') {
		$onprem = 0;
	}

	eval {
		my $_bstrap = $mysql->selectrow_hashref("select val from features where name = 'bstrap'")->{'val'};
		$bstrap  = $_bstrap if (defined($_bstrap));
	};
}; if ($@ || !defined($key)) {
	if (-e $dbbackup) {
		$key=`cat $dbbackup`;
		chomp($key);
	} else {
		warn "Error accessing the db and backup file not found: $@\n";
	}
}

if (defined $key) {
	unless (-e $dbbackup) {
		open (MYOUTFILE,">",$dbbackup);
		print MYOUTFILE $key."\n";
		close (MYOUTFILE);
	}
}
#riscWebservice::ccRequest("Assessment ID", "Appliance ID", "Serial Number")
#ccResult("CommandID", "Assessment ID", "Appliance ID", "Serial Number", "Command Result", "Time")
#
## Get either the assessment code+mac (CentOS) or PSK for auth
my $psk;
if (-e '/etc/debian_version') {
	chomp($psk = read_file("/etc/riscappliancekey"));
} else {
	my $rec = `ifconfig eth0 | grep -e "HWaddr" -e "ether"`;
	if ($rec =~ /(HWaddr|ether) (\S+)/) {
		$psk = uc($2);
	}
	$psk = join('',$key,$psk);
}

my $result = riscWebservice::ccRequest($psk);
die "SOAP Unauthorized\n" if ($result->result eq 'Unauthorized');

my @commandarray=$result->valueof('//ccqueryReturn/');

foreach $commandHash (@commandarray) {
	exit(0) if ($commandHash->{'execfile'} eq 'there are no commands for this assessment');

	#At this point, you have a hash called commandHash that you can access to get the info
	#on they different commands.  The column names from the DB query are the keys.  So, the first
	#thing we will do is a case to determine the type of command.  Then execute the command, then
	#prepare the response that will be sent back to the service to post the results.
	#
	#
	#So, first we get the command type
	#$comID = $commandHash->{'commandid'};
	$comType = $commandHash->{'commandtype'};
	switch ($comType) {
		case "exec" {
			my $execString="$commandHash->{'execfile'} $commandHash->{'arg1'} $commandHash->{'arg2'} $commandHash->{'arg3'} $commandHash->{'arg4'} $commandHash->{'arg5'} $commandHash->{'arg6'} $commandHash->{'arg7'} $commandHash->{'arg8'} $commandHash->{'arg9'} $commandHash->{'arg10'}";
			if (fork()==0) {
				riscWebservice::ccResult($commandHash->{'commandid'},$psk,"Ran EXEC - No Status Available PID=$$",time);
				$execString = comparse($execString);
				exec($execString);
				exit(0);
			}
		}
		
		case "system" {
			my $execString="$commandHash->{'execfile'} $commandHash->{'arg1'} $commandHash->{'arg2'} $commandHash->{'arg3'} $commandHash->{'arg4'} $commandHash->{'arg5'} $commandHash->{'arg6'} $commandHash->{'arg7'} $commandHash->{'arg8'} $commandHash->{'arg9'} $commandHash->{'arg10'}";
			$execString = comparse($execString);
			my $exitCode=system($execString);
			if ($? == -1) {
				riscWebservice::ccResult($commandHash->{'commandid'},$psk,"Failed to execute $!\n",time);
			} elsif ($? & 127) {
				riscWebservice::ccResult($commandHash->{'commandid'},$psk,"child died with signal %d, %s coredump\n",time);
			} else {
				riscWebservice::ccResult($commandHash->{'commandid'},$psk,"child exited with signal %d",time);
			}
		}
		
		case "return" {
		eval {
			my $execString="$commandHash->{'execfile'} $commandHash->{'arg1'} $commandHash->{'arg2'} $commandHash->{'arg3'} $commandHash->{'arg4'} $commandHash->{'arg5'} $commandHash->{'arg6'} $commandHash->{'arg7'} $commandHash->{'arg8'} $commandHash->{'arg9'} $commandHash->{'arg10'}";
			$execString = comparse($execString);
			print "$execString\n";
			my $comReturn = `$execString`;
			my $cleanReturn = "delimiter not found";

			if ($onprem) {
				## censor output for onprem assessments
				## if regexp fails, the default clean return is used
				if ($comReturn =~ /\|\|\&\|\|(.+)\|\|\&\|\|/s) {
					$cleanReturn = $1;
				}
			} else {
				$cleanReturn = $comReturn;
			}

			riscWebservice::ccResult($commandHash->{'commandid'},$psk,$cleanReturn,time);}; if ($@) {riscWebservice::ccResult($commandHash->{'commandid'},$psk,'error running command',time);}
		}

		case "expect" {
			my @execString=($commandHash->{'execfile'}, $commandHash->{'arg1'}, $commandHash->{'arg2'}, $commandHash->{'arg3'}, $commandHash->{'arg4'}, $commandHash->{'arg5'}, $commandHash->{'arg6'}, $commandHash->{'arg7'}, $commandHash->{'arg8'}, $commandHash->{'arg9'}, $commandHash->{'arg10'});
			my $exp = new Expect();
			#$exp->debug(3);
			$exp->spawn($commandHash->{'execfile'}) or die "Can't spawn $commandHash->{'execfile'}\n";
			#print "$commandHash->{'arg3'}\n";
			$exp->expect($commandHash->{'arg1'},
				['-re',$commandHash->{'arg2'},sub {my $fh = shift; print $fh "$commandHash->{'arg3'}\r\n";exp_continue;}],
				['-re',$commandHash->{'arg4'},sub {my $fh = shift; print $fh "$commandHash->{'arg5'}\r\n";exp_continue;}],
				['-re',$commandHash->{'arg6'},sub {my $fh = shift; print $fh "$commandHash->{'arg7'}\r\n";exp_continue;}],
				['-re',$commandHash->{'arg8'},sub {my $fh = shift; print $fh "$commandHash->{'arg9'}\r\n";exp_continue;}],
				'-re',$commandHash->{'arg10'});
		}
		case "initial" {
			my $comReturn;
			if ($bstrap) {
				print "cc: starting bstrap\n";
				my $auth = $commandHash->{'arg10'};
				my $type = $commandHash->{'arg1'};
				$comReturn = `/usr/bin/perl /home/risc/bstrap.pl $auth $key $type`; ## if type is not defined, bstrap will use 'scripts'
				print "cc: finished bstrap: $comReturn\n";
			} else {
				print "Communication Success: Initial Checkin\n";
				my $validString = $commandHash->{'arg10'};
				my $execstring="wget --no-check-certificate https://initial.riscnetworks.com/initial-150.php?validation=$validString";
				my $execstring2 = "mv /root/initial-150.php?validation=$validString /scripts.tar";
				my $execstring3 = "tar -xvf /scripts.tar -C /";
				system($execstring);
				system($execstring2);
				system($execstring3);
				$comReturn=`ls -al /home/risc`;
			}
			riscWebservice::ccResult($commandHash->{'commandid'},$psk,$comReturn,time);
		} else {
			print "Not an Exec Command\n";
		}
	}
}

sub comparse {
	my $command = shift;
	$command =~ s/&lt;/</g;
	$command =~ s/&gt;/>/g;
	$command =~ s/&quot;/"/g;
	return $command;
}
