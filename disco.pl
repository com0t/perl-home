#!/usr/bin/perl
#
## disco.pl -- scan subnets for devices and determine protocol support

use strict;
use Data::Dumper;
use Nmap::Scanner;

use RISC::riscUtility;
use RISC::CollectionValidation;
use RISC::Collect::Logger;

## collection validation mode
## this mode produces a discovery report for an IP
## it does not store any state, and does not call credentials.pl
my $VALIDATE = 0;
$VALIDATE = $ENV{'VALIDATE'} if (defined($ENV{'VALIDATE'}));

$SIG{CHLD} = "IGNORE";

my $concurrent	= 11;		## number of concurrent credentials.pl
my $prefix	= '/tmp';	## nmap output file directory prefix
my $quiet	= 0;		## turn off nmap output to stdout

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});


my $assessmentid	= shift;	## ignored in VALIDATE mode
my $subnet		= shift;	## must be /32 in VALIDATE mode

my $logger = RISC::Collect::Logger->new("discovery::disco::$subnet");
$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'}) if ($debugging);

$logger->info('begin');

my ($validator,$vsuccess,$vfail);
if ($VALIDATE) {
	$logger->info('running in validation mode');
	$validator = RISC::CollectionValidation->new({
		'logfile'	=> $ENV{'VALIDATE'},
		'debug'		=> $debugging
	});
	if (my $verr = $validator->err()) {
		print STDOUT 'Internal error: contact help@riscnetworks.com with error code CV01';
		$logger->error($verr);
		$validator->exit('fail');
	}
	my ($target) = $subnet =~ /(.*)\/32$/;	## reduce to IP, ensuring we were passed a /32
	unless (defined($target)) {
		print STDOUT 'Internal error: contact help@riscnetworks.com with error code CV01';
		$logger->error("subnet must be /32, provided '$subnet'");
		$validator->exit('fail');
	}
	$vsuccess	= $validator->cmdstatus_name('success');
	$vfail		= $validator->cmdstatus_name('fail');
}

my ($db,$DB);
$db = riscUtility::getDBH('risc_discovery',1);
$db->{mysql_auto_reconnect} = 1;
unless ($VALIDATE) {
	$DB = riscUtility::getDBH('RISC_Discovery',1);
	$DB->{mysql_auto_reconnect} = 1;
}
$validator->log("<h3>DISCOVERY</h3>\n") if ($VALIDATE);

## set up a scanner object and output filepath
my $scanner = new Nmap::Scanner;
my $scanfile = "$prefix/".int(rand(100000)).".xml";
$logger->debug("set output file: $scanfile");

## deal with the subnet in the database
my $previous_state;
my $updatetime = time();
unless ($VALIDATE) {
	$logger->debug('updating discoverystats');

	## store the current state of the subnet, assuming it is either 0 or 2
	## this is used to restore the state of the subnet if we fail to complete the scan
	my $current_states = $db->selectall_hashref("
		SELECT DISTINCT(status)
		FROM discoverystats
		WHERE iprange = ?
			AND status IN (0,2)
	",'status',undef,$subnet);
	if (($current_states) and (scalar keys %{$current_states})) {
		if ($current_states->{'2'}) {
			$previous_state = 2;
		} else {
			$previous_state = 0;
		}
	}

	$db->do("UPDATE discoverystats SET status=3 WHERE iprange = ? and status = 0",  undef, $subnet);
	$db->do("INSERT INTO discoverystats (iprange,filename,status,devices,updatetime) VALUES (?,?,1,0,?)", undef, $subnet, $scanfile, $updatetime);
	$DB->do("INSERT INTO discoverystats (iprange,filename,status,devices,updatetime) VALUES (?,?,1,0,?)", undef, $subnet, $scanfile, $updatetime);
}

## this END block handles the condition where nmap failed to complete
## if the $nmap_failure bit is set, then our scan failed ungracefully, and
##   we need to restore the subnet status to its previous state, so we don't
##   lock out future scans
my $nmap_failure;
END {
	if ($nmap_failure) {
		$logger->debug("resetting risc_discovery.discoverystats.status back to original status of '$previous_state'");
		$db->do("
			UPDATE discoverystats
			SET status = ?
			WHERE iprange = ?
				AND status != 3
		", undef, $previous_state, $subnet);
	}
};

##
#	build our nmap command
##

## deal with custom SSH ports
my @custom_ssh;
## get our custom port limit
my $custom_ssh_limit = 0; ## deny any custom ports if we can't determine our limit
my $custom_ssh_limit_q = riscUtility::checkfeature('ssh-custom-port-limit');
$custom_ssh_limit = $custom_ssh_limit_q if ($custom_ssh_limit_q);
$logger->debug("enforcing an ssh custom port limit of $custom_ssh_limit");
## fetch our custom ports
my $custom_ssh_ports = $db->prepare("SELECT distinct port FROM credentials WHERE technology = 'gensrvssh' and port not in (22,80,443,161,135,62078) and removed = 0 limit $custom_ssh_limit");
$custom_ssh_ports->execute();
while (my $row = $custom_ssh_ports->fetchrow_hashref()) {
	## validate that the port is numeric, and in-bounds
	unless (($row->{'port'} =~ /\d+/) and ($row->{'port'} > 0) and ($row->{'port'} < 65536)) {
		$logger->warn("skipping bad custom port: '$row->{'port'}'");
		next;
	}
	push(@custom_ssh,$row->{'port'});
}

## build our port specifications
my @tcp = (
	22,	## SSH
	80,	## HTTP
	135,	## WMI
	62078	## iPhone
);
foreach my $cp (@custom_ssh) {
	push(@tcp,$cp);
}
my $tcp = join(',',@tcp);
my @udp = (
	161	## SNMP
);
my $udp = join(',',@udp);
my $ports = "T:$tcp,U:$udp";

# if explicitly enabled by support, skip icmp during discovery.
my $ping_disabled = riscUtility::checkfeature('disco-pingless');
my $up_method = $ping_disabled ? 'ONLINE' : 'ICMP'; # just used for validation text

my $nmap = join(' ',
		'nmap',
		($ping_disabled ? "-PS$tcp -PU$udp" : '-PE'),	## (TCP|UDP) || (ICMP)
		'-n',			## no DNS resolution
		'-sU',			## UDP scan
		'-sT',			## TCP scan
		'-p',$ports,		## port specification
		$subnet,		## scan network range
		'-oX',$scanfile		## output
	);
$nmap = join(' ',$nmap,'>/dev/null') if ($quiet);	## turn off stdout scan results if quiet is set

##
#	run the scan
##

$logger->debug($nmap);
system($nmap);

##
#	parse the results, fork credentials.pl child for each IP
##

## parse the results
$logger->debug('parsing results');

my $results;
eval {
	$results = $scanner->scan_from_file($scanfile);
}; if ($@) {
	$logger->error("failed to load scan results: $@");
	$nmap_failure = 1;
	if ($VALIDATE) {
		my $runtime_error = 'Runtime Error -- please contact support';
		$validator->log("<table>\n");
		$validator->log("<tr><td>ICMP</td><td class='$vfail'>$runtime_error</td></tr>\n",1);
		$validator->log("</table>\n");
		$validator->exit('fail');
	}
	RISC::Collect::Logger::alarm('disco failure', 'nmap scan did not complete successfully');
	exit(1);
}

my $totalhosts = $results->nmap_run()->run_stats()->hosts()->up();
$logger->debug("removing $scanfile");
system("rm -f $scanfile");

## loop the respondent hosts
## determine which protocols are supported and fork a credentials.pl
$logger->debug('beginning loop');
my $validator_seen = 0;
my @children;
my $host_list = $results->get_host_list();

# if any IPs have been manually excluded, list that:
my $ips_excluded = riscUtility::get_ip_exclusion_list($db);

while (my $host = $host_list->get_next()) {

	my $status = $host->status();
	if ($VALIDATE) {
		$validator_seen = 1;
		$validator->log("<table>\n");
		if ($status eq 'up') {
			$validator->log("<tr><td>$up_method</td><td class='$vsuccess'>$vsuccess</td></tr>\n",1);
		} else {
			$validator->log("<tr><td>$up_method</td><td class='$vfail'>$vfail</td></tr>\n",1);
			$validator->log("</table>\n");
			$validator->exit('fail');
		}
	} else {
		next unless $status eq 'up';
	}

	unless ($VALIDATE) {
		while (riscUtility::checkProcess('credentials') >= $concurrent) {
			my $concurrency_wait =  int(rand(20));	## does a  random sleep here help?
			$logger->debug("waiting $concurrency_wait seconds for a credentials.pl concurrency slot");
			sleep $concurrency_wait;
		}
	}

	my $ports = $host->get_port_list();
	my @addrs = $host->addresses();
	my $address = $addrs[0]->addr();
	$logger->info("found: $address");

	## this creates a bit field that is passed to credentials.pl, defining the supported protocols
	my $wmi		= 0;
	my $snmp	= 0;
	my $iphone	= 0;
	my $ssh		= 0;
	my $ssh_port	= 22;

	while (my $p = $ports->get_next()) {
		my $port = $p->portid();
		my $state = $p->state();
		#$logger->debug("$address: got port: $port with state: $state");
		if ($state =~ /open/) {
			if ($port == 135) {
				$wmi = 1;
			} elsif ($port == 161) {
				$snmp = 1;
			} elsif ($port == 62078) {
				$iphone = 50;	## not sure why this is 50
			} elsif ($port == 22) {
				$ssh = 1;
			} else {
				foreach my $cp (@custom_ssh) {
					if ($port == $cp) {
						$logger->debug("$address: ssh ---> on");
						$ssh_port = $port;
						$ssh = 1;
						last;
					}
				}
			}
		}
	}

	if ($VALIDATE) {
		$validator->log("<tr><td>Protocols</td><td></td></tr>\n",1);
		$validator->log("<tr><td></td><td>WMI (TCP 135)</td></tr>\n",1) if ($wmi);
		$validator->log("<tr><td></td><td>SSH (TCP $ssh_port)</td></tr>\n",1) if ($ssh);
		$validator->log("<tr><td></td><td>SNMP (UDP 161)</td></tr>\n",1) if ($snmp);
		$validator->log("</table>\n");
	} else {
		if ($ips_excluded->{$address}) {
			$logger->info("skipping ip $address due to its presence in risc_discovery.ip_exclusion_list");
		} else {
			my $pid = fork();
			unless (defined($pid)) {
				$logger->error("fork failed: $!");
				die "fork failed: $!\n";
			}

			## child
			unless ($pid) {
				my $credentials = join(' ','perl',
					'/home/risc/credentials.pl',
					$assessmentid,
					$address,
					$wmi,
					$snmp,
					$iphone,
					$ssh);
				$logger->debug($credentials);
				exec($credentials);
			}

			## parent
			push(@children,$pid);
		}
	}
}
$logger->debug('all children forked');

if ($VALIDATE) {
	unless ($validator_seen) {
		$validator->log("<table>\n");
		$validator->log("<tr><td>$up_method</td><td class='$vfail'>$vfail</td></tr>\n",1);
		$validator->log("</table>\n");
		$validator->exit('fail');
	}
	$validator->finish();
	$validator->exit('success');
}

##
#	deal with our children
##

## wait a maximum of an hour for them to complete
my $totalsleep2;
for ($totalsleep2 = 3600; $totalsleep2 > 0; $totalsleep2 -= 10) {
	my $mustwait = 0;
	my @allrunning = riscUtility::pidList('credentials.pl');
	foreach my $child (@children) {
		$mustwait = 1 if (grep /^$child$/, @allrunning);
	}
	last unless ($mustwait);
	$logger->debug("waiting for children ... ");
	sleep 10;
}
## if we waited the whole hour, kill the problem children (if they are still our children)
if ($totalsleep2 == 0) {
	$logger->info('killing children');
	foreach my $child (@children) {
		my $ps = `ps -o pid,args --no-headers -p $child`;
		if ($ps =~ /credentials\.pl/) {
			$logger->info("killing child pid $child");
			system("kill $child");
		}
	}
}

##
#	finish
##

## mark subnets completed
$updatetime = time();
$db->do("UPDATE discoverystats SET status=2, updatetime=?, devices=? WHERE iprange = ? and status = 1", undef, $updatetime, $totalhosts, $subnet);
$DB->do("UPDATE discoverystats SET status=2, updatetime=?, devices=? WHERE iprange = ? and status = 1", undef, $updatetime, $totalhosts, $subnet);

$db->disconnect();
$DB->disconnect();
$logger->info('complete');
exit(0);
