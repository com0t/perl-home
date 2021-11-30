#!/usr/bin/perl
#
##
use strict;
use Data::Dumper;
use RISC::riscUtility;
use RISC::riscWindows;
use RISC::riscSSH;
use RISC::riscSNMP;
use RISC::CiscoCLI;
use RISC::riscCreds;
use RISC::Collect::Logger;
use RISC::Collect::UserLog;
use File::Temp qw(tempfile);
$|++;

use RISC::Collect::Constants qw(
	:status
	:userlog
);

## additional local constants used for the collection user log
use constant {
	PROTOCOL_SSH	=> 'SSH',
	PROTOCOL_WMI	=> 'WMI',
	PROTOCOL_SNMP	=> 'SNMP',
};

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ($ENV{'DEBUG'});

my $assessmentid	= shift;
my $address		= shift;
my $wmistatus		= shift;
my $snmpstatus		= shift;
my $wirelessdevice	= shift;
my $gensrvssh		= shift;

my $logger = RISC::Collect::Logger->new(join('::','credential-map',$address));
$logger->info('begin');

my $mysql = riscUtility::getDBH('risc_discovery',0);
my $mysql2 = riscUtility::getDBH('RISC_Discovery',1);

my $ul = RISC::Collect::UserLog
	->new({ db => $mysql2 })
	->context('discovery');

my @user_error_stack;

##
#	get our credentials
##
## we need to do this first, even if we're not doing an updating run, in case we need to do some
## manual overriding, as is the case with CLI creds

my $credobj = riscCreds->new($address);

my @cliCreds;

my $riscdevice = $mysql2->prepare("INSERT INTO riscdevice (deviceid,sysdescription,ipaddress,macaddr,snmpstring,layer1,layer2,layer3,layer4,layer5,layer6,layer7,wmi) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $credentials = $mysql2->prepare("INSERT INTO credentials (deviceid,credentialid,technology,uniqueid,level) VALUES (?,?,?,concat(?,'-',?),?)");
my $inventoryerrors = $mysql2->prepare("INSERT INTO inventoryerrors (deviceid,deviceip,domain,winerror,scantime) VALUES (concat(?,inet_aton(?)),?,?,?,?)");
my $update_riscdevice = $mysql2->prepare("UPDATE riscdevice SET ipaddress=? WHERE macaddr=?");
my $update_riscdevice_decom = $mysql2->prepare("UPDATE riscdevice SET ipaddress = 'decommissioned', macaddr = ? WHERE deviceid = ?");
my $update_inventorylog = $mysql2->prepare("UPDATE inventorylog SET decom = 1 WHERE deviceid = ?");

my $getCreds;
if ($mysql->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$getCreds = $mysql->prepare_cached("select * from credentials where removed=0 or removed=2 order by privpassphrase desc");
} else {
	$getCreds = $mysql->prepare_cached("
		SELECT
			credid,
			productkey,
			technology,
			status,
			accepted,
			version,
			level,
			testip,
			cred_decrypt(passphrase) AS passphrase,
			cred_decrypt(context) AS context,
			cred_decrypt(securitylevel) AS securitylevel,
			cred_decrypt(securityname) AS securityname,
			cred_decrypt(authtype) AS authtype,
			cred_decrypt(authpassphrase) AS authpassphrase,
			cred_decrypt(privtype) AS privtype,
			cred_decrypt(privusername) AS privusername,
			cred_decrypt(privpassphrase) AS privpassphrase,
			cred_decrypt(domain) AS domain,
			port,
			cred_decrypt(userid) AS userid,
			cred_decrypt(username) AS username,
			scantime,
			eu,
			ap,
			removed
		FROM credentials
		WHERE
			removed = 0
			OR removed = 2
			AND technology IN ('ssh','cds','cli')
		ORDER BY privpassphrase DESC
	");
}

$getCreds->execute();
while (my $cred = $getCreds->fetchrow_hashref()) {
	push (@cliCreds,$cred);
}

my $windows_creds	= $credobj->getAllWin();
my $gensrvsshcreds	= $credobj->getAllGenSrvSSH();
my $snmpcreds		= $credobj->getAllSNMP();

##
#	resolve whether we are doing an updating run
##

## store whether we are performing an updating inventory
my $doing_update = riscUtility::checkUpdatingInventory();

## determine if we already know about this device
my $existing;
$logger->debug("checking for an existing visiodevices record");
my $existingdevid = $mysql2->selectrow_hashref("
	SELECT deviceid
	FROM visiodevices
	WHERE ip = ?
	AND devicetype NOT IN ('DB_NOI')
", undef, $address);
$existing->{'deviceid'} = $existingdevid->{'deviceid'} if (defined($existingdevid->{'deviceid'}));

## if the device exists, then we need to handle the situation, the manner of which depends on whether we're updating or not
if ($existing->{'deviceid'}) {
	$logger->info("matched existing deviceid: $existing->{'deviceid'}");
	## determine if we have it cred mapped
	$logger->debug("checking for credential mapping");
	my $existingcredid = $mysql2->selectrow_hashref("select credentialid from credentials where deviceid = ?", undef, $existing->{'deviceid'});
	$existing->{'credid'} = $existingcredid->{'credentialid'} if (defined($existingcredid->{'credentialid'}));

	if (($existing->{'credid'}) and (!$doing_update)) {
		## determine if this is an SNMP network device that needs CLI mapping
		map_cli_existing($existing->{'deviceid'});
		## this device is cred mapped and we are not updating, leave as-is
		$logger->info(sprintf(
			'device exists, has a credential mapping, and we are not revisioning mode; retaining existing configuration: { "ip": "%s", "deviceid": "%s", "credentialid": %s" }',
			$address,
			$existing->{'deviceid'},
			$existing->{'credid'}
		));
		exit(EXIT_SUCCESS);
	} elsif (($existing->{'credid'}) and ($doing_update)) {
		$logger->debug("matched existing credentialid: $existing->{'credid'}");
		$logger->debug("determining if previous identity is still valid");
		my $riscdevice_update = $mysql2->prepare("UPDATE riscdevice SET ipaddress=?, sysdescription=? WHERE deviceid=?");
		my $riscdevice_decom = $mysql2->prepare("UPDATE riscdevice SET ipaddress='decommissioned' where macaddr = ?");
		## this device is cred mapped and we're doing an update
		## we need to determine if the device at this IP is the device we think it is
		## we will do this by pulling a list of all IPs and all MACs, and comparing that to what riscdiscovery thinks
		## if this is the device we think it is, we update the scoped IP for the record in case our scoped IP became a new device
		## if this is not the device we think it is, we continue processing to create a new device entry
		$existing->{'cred'} = $credobj->getCredByID($existing->{'credid'}); ## this should exist, as platform_discovery removes credentials entries for removed creds
		my ($snmp,$ssh);
		$logger->debug("connecting to device via protocol: $existing->{'cred'}->{'technology'}");
		if ($existing->{'cred'}->{'technology'} eq 'snmp') {
			$snmp = riscSNMP::connect($existing->{'cred'},$address);
			unless ($snmp) {
				$logger->error("failed to connect to device, cannot determine identity");
				exit(EXIT_FAILURE)
			}
		} elsif ($existing->{'cred'}->{'technology'} eq 'gensrvssh') {
			$ssh = RISC::riscSSH->new({ 'debug' => $debugging });
			$ssh->connect($address,$existing->{'cred'});
			unless ($ssh->{'connected'}) {
				$logger->error("failed to connect to device, cannot determine identity");
				exit(EXIT_FAILURE);
			}
		}
		my ($macs,@macstr,$ips);
		## get an array of all MACs on the target
		$logger->debug('querying for mac addresses');
		if ($existing->{'cred'}->{'technology'} eq 'snmp') {
			$macs = riscSNMP::allmacs($snmp);
		} elsif ($existing->{'cred'}->{'technology'} eq 'gensrvssh') {
			$macs = $ssh->allmacs();
			if (my $error = $ssh->get_error()) {
				## if we failed to pull mac addresses, we have no hope of being correct beyond this point
				$logger->error("failed to get mac addresses, cannot continue: $error");
				exit(EXIT_FAILURE);
			}
		}
		push(@{$macs},$existing->{'deviceid'});	## include the deviceid as a potential MAC
		## build a list of normalized MACs
		foreach my $m (@{$macs}) {
			push(@macstr, $m);
			push(@macstr, uc($m)) unless ($m eq uc $m); ## include the upper case version if not already
		}
		## get an array of all IPs on the target
		$logger->debug('querying for ip addresses');
		if ($existing->{'cred'}->{'technology'} eq 'snmp') {
			$ips = riscSNMP::allips($snmp);
		} elsif ($existing->{'cred'}->{'technology'} eq 'gensrvssh') {
			$ips = $ssh->allips();
			if (my $error = $ssh->get_error()) {
				## if we failed to pull ip addresses, we have no hope of being correct beyond this point
				$logger->error("failed to get ip addresses, cannot continue: $error");
				exit(EXIT_FAILURE);
			}
		}
		## get all records from riscdevice that has a MAC matching one of the target's
		my $riscdevice_existing_entries = $mysql2->selectall_hashref('select deviceid,ipaddress,macaddr from riscdevice where macaddr in (' . join(',', ('?' x scalar(@macstr))) . ')', 'macaddr', undef, @macstr);
		foreach my $riscdevice_mac (keys %{$riscdevice_existing_entries}) {
			my $riscdevice_devid = $riscdevice_existing_entries->{$riscdevice_mac}->{'deviceid'};
			my $riscdevice_ip = $riscdevice_existing_entries->{$riscdevice_mac}->{'ipaddress'};
			$logger->debug("matched riscdevice entries: ".Dumper($riscdevice_existing_entries->{$riscdevice_mac}));
			## determine if the IP in riscdevice for one of our MACs is an IP currently held by the target
			$logger->debug("trying to match ip addresses");
			my $match = 0;
			foreach my $ip (@{$ips}) {
				$logger->debug("comparing $ip vs $riscdevice_ip");
				if ($ip eq $riscdevice_ip) {
					$match = 1;
					last;
				}
			}
			if ($match) {
				## this matched a known device
				## determine if the device we matched consumed this IP from another device
				$logger->debug('matched on ip, determining if ip was taken from a different device');
				my $existing_by_ip = $mysql2->selectrow_hashref("select deviceid,macaddr from riscdevice where ipaddress = ?", undef, $address);
				if ($existing_by_ip) {
					$logger->debug("matched devices: ".Dumper($existing_by_ip));
					## determine if the stored MAC for the IP matches one of the target's
					$logger->debug("tying to match macs");
					my $match2 = 0;
					foreach my $mac (@{$macs}) {
						$logger->debug(sprintf("comparing %s vs %s\n",uc($mac),uc($existing_by_ip->{'macaddr'})));
						if (uc $mac eq uc $existing_by_ip->{'macaddr'}) {
							$match2 = 1;
							last;
						}
					}
					unless ($match2) {
						$logger->info("decommissioning deviceid $existing_by_ip->{'deviceid'}, existing mac does not match");
						## the stored MAC doesn't match one of the target's MACs, decommission that record
						decommission_device($existing_by_ip->{'deviceid'});
					}
				}
				## update the existing record with our working IP if it is not the same
				if ($riscdevice_ip ne $address) {
					my $sysdescr = $snmp->description();
					$logger->info("updating $riscdevice_devid ipaddress to $address");
					$riscdevice_update->execute($address,$sysdescr,$riscdevice_devid);
				} else {
					## determine if this device is a network device that needs CLI mapping
					map_cli_existing($existing->{'deviceid'});
					## no other action
					$logger->info('made no changes');
				}
				$logger->info('complete');
				exit(EXIT_SUCCESS);
			} ## else the device with this MAC is no longer on the old IP
			#### we then continue to attempt to create a new device entry, clash on MAC, and update that record with the new IP
		}
		$logger->info("could not associate with an existing device, proceeding to create a new one");
	} ## else if the existing device is not cred mapped, continue to process as normal
}	## else this device does not exist, continue to process as normal

##
#	map credentials
##

$logger->info(sprintf(
	'begin mapping credentials: { "wmi": "%s", "ssh": "%s", "snmp": "%s" }',
	$wmistatus,
	$gensrvssh,
	$snmpstatus
));

## generate the deviceid based on the IP
## if this deviceid is already taken (ie, an existing device had its scoped IP move to another device), we generate a new derived deviceid like VMware does later on
my $deviceid = $mysql2->selectrow_hashref("SELECT CONCAT(?,INET_ATON(?)) AS deviceid", undef, $assessmentid, $address)->{'deviceid'};
$logger->debug("wanting to use ip-based deviceid $deviceid");

##
#  WMI
##
if (($wmistatus) and (($windows_creds) and (scalar @{ $windows_creds }))) {
	$logger->info('trying windows');
	# make sure we're using the right deviceid out the gate, because testWindows implicitly adds a credentials record
	# keep track of the proposed deviceid, but if we match windows creds we may need a different deviceid
	my $win_deviceid = avoid_win_gen_clash($deviceid,$address);
	my $cred = testWindows($address, $win_deviceid);
	if ($cred) {
		$logger->info('succeeded windows');
		eval {
			## insert with deviceid as MAC
			$riscdevice->execute($win_deviceid,'WindowsDevice',$address,$win_deviceid,"",undef,undef,undef,undef,$wirelessdevice,undef,undef,$wmistatus);
			$ul->collection_id($win_deviceid);
		}; if ($@ && $@ !~ /Duplicate/) {
			$logger->warn("insert of $win_deviceid failed: $@");
		}
		$logger->info("created via wmi as $win_deviceid");

		# if win_deviceid is not the same as deviceid AND creds were mapped in this step,
		# make sure that the old deviceid is decom'd to avoid IP conflict
		if ($win_deviceid != $deviceid) {
			# we should change the IP in riscdevice to "decom" for that device
			# if it's currently sitting on the IP we're inventorying the windows device on
			$logger->info("windows non-ip deviceid: $win_deviceid instead of $deviceid");
			eval {
				$update_riscdevice_decom->execute($deviceid, $deviceid);
				$update_inventorylog->execute($deviceid);
			}; if ($@) {
				$logger->warn("possibly decommissioning of former device $deviceid failed: $@");
			}
		}
		exit(EXIT_SUCCESS);
	} else {
		## We have WMI detected _and_ WMI credentials, yet we failed to map anything
		push(@user_error_stack, {
			type	=> FAILURE_CREDS_EXHAUSTED,
			proto	=> PROTOCOL_WMI
		});
	}
} elsif ($wmistatus) {
	## We have WMI detected, but no WMI credentials
	push(@user_error_stack, {
		type	=> FAILURE_NO_CREDENTIALS,
		proto	=> PROTOCOL_WMI
	});
}

##
#  SSH -- must have the riscSSH framework, flagged as supporting SSH, and either no existing cred entry or existing cred entry is type SSH
##
if (($gensrvssh) and (($gensrvsshcreds) and (scalar @{ $gensrvsshcreds }))) {
	$logger->info('trying ssh');
	my $unsupported_os = eval {
		foreach my $g (@{$gensrvsshcreds}) {
			$logger->debug("trying credential $g->{'credid'}");
			my $ssh = RISC::riscSSH->new({ 'debug' => 0 });
			$ssh->connect($address,$g);
			if ($ssh->{'connected'}) {
				$logger->info("succeeded ssh with credid $g->{'credid'}");
				## fail all the way out of SSH testing if the OS is not supported
				unless ($ssh->supported_os()) {
					$logger->info("operating system not supported by ssh: $ssh->{'os'}");
					return $ssh->{'os'}; ## return from eval indicates the operating system is not supported
				}
				## validate sudo access if we don't have the root account
				unless ($g->{'username'} eq 'root') {
					my $sudo = $ssh->privtest();
					unless ($sudo) {
						$logger->info('sudo validation failed');
						$inventoryerrors->execute(
							$assessmentid,
							$address,
							$address,
							undef,
							"sudo validation failed: ".$ssh->{'err'}->{'msg'},
							time()
						);
						push(@user_error_stack, {
							type	=> FAILURE_CONFIG,
							proto	=> PROTOCOL_SSH,
							cred	=> $g->{'credtag'},
							error	=> sprintf(
								'sudo validation failed: %s',
								$ssh->{'err'}->{'msg'}
							)
						});
						next;
					}
				}

				## derive a constant MAC
				## if we cannot get one, assume command access is bad and move on
				## there are no known cases where failing to pull a MAC here leads to correct operation
				## there are many known cases where failing to pull a MAC here leads to incorrect operation
				my $macaddr = $ssh->macaddr();
				unless ($macaddr) {
					$logger->error('failed to get mac addresses');
					$inventoryerrors->execute(
						$assessmentid,
						$address,
						$address,
						undef,
						"macaddr() failed: $ssh->{'err'}->{'msg'}",
						time()
					);
					push(@user_error_stack, {
						type	=> FAILURE_ELIGIBLE,
						proto	=> PROTOCOL_SSH,
						cred	=> $g->{'credtag'},
						error	=> sprintf(
							'Unable to collect MAC addresses: %s',
							$ssh->clean_ssh_error()
						)
					});
					next;
				}

				## attempt to insert into riscdevice
				my $sysdescr = $ssh->sysdescr();
				eval {
					$deviceid = ensure_unique_deviceid($deviceid);
					$riscdevice->execute($deviceid,$sysdescr,$address,$macaddr,"",undef,undef,undef,undef,$wirelessdevice,undef,undef,$wmistatus);
					$ul->collection_id($deviceid);
				}; if (($@) and ($@ =~ /duplicate/i)) {
					if ($doing_update) {
						## if we're here, then we clashed MACs working on an unknown IP
						## this would occur if an existing device changed IPs or added a new IP that was previously unknown
						## 2021-08-10 it can also occur when a credential was removed and a new one added without the device going decom in between 
						## in which case we need to make sure the new correct credential is inserted
						## in this case, update the riscdevice entry for the MAC to hold this IP
						eval {
							$logger->info("duplicate of riscdevice entry with mac '$macaddr', updating its ip to '$address'");
							$update_riscdevice->execute($address, $macaddr);
							my $dupe_is_credded = $mysql2->selectrow_hashref("select count(*) ct from credentials inner join riscdevice using (deviceid) where macaddr = ?", undef, $macaddr)->{'ct'};
							if (!$dupe_is_credded) {
								## note: this does not handle the case when the cred mapped to the current device is bad; that should have been caught above.
								$logger->info("existing device does not currently have a cred mapped, updating");
								$mysql2->do("insert into credentials (deviceid, credentialid, technology, level, uniqueid) 
											select deviceid, ?,'gensrvssh','none',concat(deviceid,'-','gensrvssh')
											from riscdevice where macaddr = ? limit 1", undef, $g->{'credid'}, $macaddr);
								$logger->info("created credentials record by macaddr: $macaddr:gensrvssh:$g->{'credid'}");
							}
						};
					} else {
						$logger->info("duplicate of riscdevice entry with mac '$macaddr'");
					}
					exit(EXIT_SUCCESS);
				} elsif ($@) {
					$logger->error("unknown exception: $@");
					exit(EXIT_FAILURE);
				}

				eval {
					$credentials->execute($deviceid,$g->{'credid'},'gensrvssh',$deviceid,'gensrvssh','none');
					$logger->info("created credentials record: $deviceid:gensrvssh:$g->{'credid'}");
				}; if ($@) {
					$logger->info('duplicate of existing credentials record');
				}


				$mysql2->disconnect();
				$logger->info("created via ssh as $deviceid");
				exit(EXIT_SUCCESS);
			} else {
				## failed to authenticate with this credential
				my $inverror = "SSH: ".$ssh->{'err'}->{'msg'};
				$inverror =~ s/$g->{'username'}/(redacted)/g;
				$inverror = "SSH: no matching cipher" if ($inverror =~ /no matching cipher found/i); ## avoid listing the ciphers we/they support
				$inventoryerrors->execute($assessmentid,$address,$address,undef,$inverror,time());
				my $user_log_error = $ssh->clean_ssh_error();
				push(@user_error_stack, {
					type		=> FAILURE_CREDENTIAL,
					proto		=> PROTOCOL_SSH,
					cred		=> $g->{'credtag'},
					category	=> $ssh->user_log_classify($user_log_error),
					error		=> $user_log_error
				});
			}
		}
	}; if ($@) {
		## runtime fault during processing
		chomp(my $inverror = $@);
		$logger->error("failure during ssh mapping: $inverror");
		out($inverror);
		$inventoryerrors->execute($assessmentid,$address,$address,undef,$inverror,time());
		push(@user_error_stack, {
			type	=> FAILURE_RUNTIME,
			proto	=> PROTOCOL_SSH,
			error	=> RUNTIME_ERROR_MSG,
			fault	=> $inverror
		});
	} else {
		## returned from the eval block indicating the operating system is not supported
		if ($unsupported_os) {
			push(@user_error_stack, {
				type	=> FAILURE_ELIGIBLE,
				proto	=> PROTOCOL_SSH,
				error	=> sprintf(
					'Operating system not supported for SSH collection: %s',
					$unsupported_os
				)
			});
		} else {
			## We have SSH detected _and_ SSH credentials, yet we failed to map anything.
			push(@user_error_stack, {
				type	=> FAILURE_CREDS_EXHAUSTED,
				proto	=> PROTOCOL_SSH
			});
		}
	}
} elsif ($gensrvssh) {
	## We have SSH detected, but no SSH credentials.
	push(@user_error_stack, {
		type	=> FAILURE_NO_CREDENTIALS,
		proto	=> PROTOCOL_SSH
	});
}

##
#  SNMP
##

my @BAD_SNMP_CLASSES = ( qw(
	SNMP::Info::Layer3::Microsoft
) );

if (($snmpstatus) and (($snmpcreds) and (scalar @{ $snmpcreds }))) {
	$logger->info('trying snmp');
	foreach my $snmpcred (@{$snmpcreds}) {
		$logger->debug("trying credid $snmpcred->{'credid'}");
		my $info = riscSNMP::connect($snmpcred,$address,{ 'AutoSpecify' => 0 });
		if ($info) {
			$logger->info("succeeded snmp with credid $snmpcred->{'credid'}");

			my $info_spec = $info->specify();

			## Prevent association with SNMP if we cannot specify(). Currently,
			## the only known condition under which we can create an SNMP session
			## and fail to specify() is when the MIB-II system table is unavailable.
			## I also suspect that corrupted or response with the wrong type may
			## also cause this. We only get a failure from specify() if it cannot
			## retrieve the data; it is not an error to have no class mapping. In
			## this case, we simply get an instance of the base class back.
			unless ($info_spec) {
				$logger->warn('refusing snmp based on failure to specify()');
				push(@user_error_stack, {
					type	=> FAILURE_ELIGIBLE,
					proto	=> PROTOCOL_SNMP,
					cred	=> $snmpcred->{'credtag'},
					error	=> sprintf('Cannot continue with SNMP due to unavailable system table or invalid/corrupt response')
				});
				last;
			}

			## Prevent association with SNMP if we specify() to a known-bad class.
			## This is primarily aimed at SNMP-enabled Windows devices.
			my $info_class = $info_spec->class();
			if (grep { $info_class eq $_ } @BAD_SNMP_CLASSES) {
				$logger->warn(sprintf('refusing snmp based on class: %s', $info_class));
				push(@user_error_stack, {
					type	=> FAILURE_ELIGIBLE,
					proto	=> PROTOCOL_SNMP,
					cred	=> $snmpcred->{'credtag'},
					error	=> sprintf('Refused to continue with this SNMP agent due to known issues')
				});
				last;
			}

			my $lvl = 'none';
			if (defined($info_spec)) {
				#my $inst = $info_spec->load_i_cisco_inbps();	## removed instantaneous traffic type
				my $lvl64 = $info_spec->load_i_octet_in64();
				my $lvl32 = $info_spec->load_i_octet_in();
				if (defined($lvl64)) {
					$lvl = '64bit';
				#} elsif (defined($inst)) {
				#	$lvl = 'instant';
				} elsif (defined($lvl32)) {
					$lvl = '32bit';
				}
			}
			$logger->debug("got interface counter size: '$lvl'");

			my $descr = $info->description();
			my $layer2 = $info->has_layer(2);
			my $layer1 = $info->has_layer(1);
			my $layer3 = $info->has_layer(3);
			my $layer4 = $info->has_layer(4);
			my $layer5 = $info->has_layer(5);
			my $layer6 = $info->has_layer(6);
			my $layer7 = $info->has_layer(7);

			## derive our constant MAC
			my $macaddr = riscSNMP::macaddr($info,$descr);
			$macaddr = $deviceid unless ($macaddr);
			$logger->debug("got mac address '$macaddr'");

			## attempt to insert the device to riscdevice
			## if we hit an error due to a unique constraint on MAC, and we're doing an updating run,
			##  then we need to determine if we're talking to the device we think we are
			eval {
				$deviceid = ensure_unique_deviceid($deviceid);
				$riscdevice->execute($deviceid,riscUtility::ascii($descr),$address,$macaddr,'',$layer1,$layer2,$layer3,$layer4,$wirelessdevice,$layer6,$layer7,$wmistatus);
				$ul->collection_id($deviceid);
			}; if (($@) and ($@ =~ /duplicate/i)) {
				if ($doing_update) {
					## if we're here, then we clashed MACs working on an unknown IP
					## this would occur if an existing device changed IPs or added a new IP that was previously unknown
					## in this case, update the riscdevice entry for the MAC to hold this IP
					eval {
						$logger->info("duplicate of riscdevice entry with mac '$macaddr', updating its ip to '$address'");
						$update_riscdevice->execute($address, $macaddr);
					};
				} else {
					$logger->info("duplicate of riscdevice entry with mac '$macaddr'");
				}
				exit(EXIT_SUCCESS);
			} elsif ($@) {
				$logger->error("unknown exception: $@");
				exit(EXIT_FAILURE);
			}

			eval {
				$credentials->execute($deviceid,$snmpcred->{'credid'},'snmp',$deviceid,'snmp',$lvl);
				$logger->info("created credentials record: $deviceid:snmp:$snmpcred->{'credid'}");
			}; if ($@) {
				$logger->info('duplicate of existing credentials record');
			}

			my $NX = 0;
			$NX = 1 if ($info->description() =~ /NX/);
			testCLI($deviceid,$NX) if (defined($info_spec) and ($info_spec->vendor() =~ /cisco/i));

			$logger->info("created via snmp as $deviceid");
			exit(EXIT_SUCCESS);
		} else {
			## no useful error messages from SNMP
			push(@user_error_stack, {
				type		=> FAILURE_CREDENTIAL,
				proto		=> PROTOCOL_SNMP,
				cred		=> $snmpcred->{'credtag'},
				category	=> 'bad-credential',
				error		=> SNMP_ERROR_MSG
			});
		}
	}
	## We have SNMP _and_ SNMP credentials, but failed to map anything.
	push(@user_error_stack, {
		type	=> FAILURE_CREDS_EXHAUSTED,
		proto	=> PROTOCOL_SNMP
	});
} elsif ($snmpstatus) {
	push(@user_error_stack, {
		type	=> FAILURE_NO_CREDENTIALS,
		proto	=> PROTOCOL_SNMP
	});
}

##
#  inaccessible
##
eval {
	## insert with deviceid as MAC
	$deviceid = ensure_unique_deviceid($deviceid);
	$riscdevice->execute(
		$deviceid,
		'unknown',
		$address,
		$deviceid,
		"",
		undef,
		undef,
		undef,
		undef,
		$wirelessdevice,
		undef,
		undef,
		$wmistatus
	);
	$logger->info("created inaccessible as $deviceid");
	$ul->collection_id($deviceid);
}; if ($@) {
	$logger->info("duplicates inaccessible with deviceid $deviceid");
	$ul->collection_id($deviceid);
}

## determine if there were no available protocols
my @have_protocols = grep { $_ } ( $wmistatus, $gensrvssh, $snmpstatus );

## determine if there were no available credentials
my @have_creds = grep {
	($_ and scalar(@{ $_ }))
} ( $windows_creds, $gensrvsshcreds, $snmpcreds );

## process failures and create the user log entries
unless (@have_protocols) {
	$ul->info('No collection protocols discovered', 'not-eligible');
}

unless (@have_creds) {
	$ul->warn('No credentials available', 'no-credential');
}

foreach my $ue (@user_error_stack) {
	if ($ue->{'type'} eq FAILURE_CREDS_EXHAUSTED) {
		$ul->warn(sprintf(
			'%s protocol detected, but all %s credentials unsuccessful',
			$ue->{'proto'},
			$ue->{'proto'}
		), 'bad-credential');
	} elsif ($ue->{'type'} eq FAILURE_NO_CREDENTIALS) {
		$ul->warn(sprintf(
			'%s protocol detected, but no %s credentials available',
			$ue->{'proto'},
			$ue->{'proto'}
		), 'no-credential');
	} elsif ($ue->{'type'} eq FAILURE_CREDENTIAL) {
		my $category = $ue->{'category'};
		$ul->error(sprintf(
			'%s credential %s unsuccessful: %s',
			$ue->{'proto'},
			$ue->{'cred'},	## cred tag
			$ue->{'error'}
		), $category);
	} elsif ($ue->{'type'} eq FAILURE_CONFIG) {
		$ul->error(sprintf(
			'System not properly configured for %s collection: %s',
			$ue->{'proto'},
			$ue->{'error'}
		), 'bad-configuration');
	} elsif ($ue->{'type'} eq FAILURE_ELIGIBLE) {
		$ul->error(sprintf(
			'Failed eligibility requirements for %s with credential %s: %s',
			$ue->{'proto'},
			$ue->{'cred'},
			$ue->{'error'}
		), 'not-eligible');
	} elsif ($ue->{'type'} eq FAILURE_RUNTIME) {
		$ul->error($ue->{'error'}, 'runtime-error');
	}
}

$logger->info('finish');
exit(EXIT_SUCCESS);



sub testCLI {
	my ($deviceid,$NX) = @_;
	$logger->info("trying cisco cli with NX bit $NX");
	foreach my $cli (@cliCreds) {
		$logger->debug("trying credid $cli->{'credid'}");
		my $cliCredid = $cli->{'credid'};
		my $transport = $cli->{'context'};
		my $username = $cli->{'username'};
		my $password = $cli->{'passphrase'};
		my $enable = $cli->{'privpassphrase'};
		my $logInsert = $mysql2->prepare_cached("INSERT INTO inventoryerrors (deviceid,deviceip,domain,winerror,scantime) values (concat(?,inet_aton(?)),?,?,?,unix_timestamp(now()))");
		$username = riscUtility::decode($username) if defined $username;
		$password = riscUtility::decode($password) if defined $password;
		$enable = riscUtility::decode($enable) if defined $enable;
		if ($NX) {
			$enable = 'null';
		}
		$username = 'null' unless defined $username;
		$password = 'null' unless defined $password;
		$enable = 'null' unless defined $enable;
		my $logfile = (tempfile(UNLINK => 1))[1];
		if ($transport =~ /telnet/i) {
			$logger->debug('connecting over telnet');
			my $cliResult = RISC::CiscoCLI::checkCLITelnet($address,$username,$password,$enable,$logfile);
			my ($status,$reason) = split(':',$cliResult);
			if ($status != 0) {
				$credentials->execute($deviceid,$cliCredid,'ssh',$deviceid,'ssh','N/A');
				$logger->info("succeeded cisco cli over telnet with credid $cliCredid");
				last;
			}
			my $log = RISC::CiscoCLI::parseCLILog($logfile, $username, $password);
			$logInsert->execute($assessmentid,$address,$address,'N/A',$log);
			if ($enable ne 'null') {
				$enable = 'null';
				$logger->debug('connecting over telnet without enable mode');
				$logfile = (tempfile(UNLINK => 1))[1];
				my $cliResult = RISC::CiscoCLI::checkCLITelnet($address,$username,$password,$enable,$logfile);
				my ($status,$reason) = split(':',$cliResult);
				if ($status != 0) {
					$credentials->execute($deviceid,$cliCredid,'ssh',$deviceid,'ssh','N/A');
					$logger->info("succeeded cisco cli over telnet with credid $cliCredid, without enable mode");
					last;
				}
				my $log = RISC::CiscoCLI::parseCLILog($logfile, $username, $password);
				$logInsert->execute($assessmentid,$address,$address,'N/A',$log);
			}
		} elsif ($transport =~ /ssh/i) {
			$logger->debug('connecting over ssh');
			my $cliResult = RISC::CiscoCLI::checkCLISSH($address,$username,$password,$enable,$logfile);
			my ($status,$reason) = split(':',$cliResult);
			if ($status != 0) {
				$credentials->execute($deviceid,$cliCredid,'ssh',$deviceid,'ssh','N/A');
				$logger->info("succeeded cisco cli over ssh with credid $cliCredid");
				last;
			}
			my $log = RISC::CiscoCLI::parseCLILog($logfile, $username, $password);
			$logInsert->execute($assessmentid,$address,$address,'N/A',$log);
			if ($enable ne 'null') {
				$enable = 'null';
				$logfile = (tempfile(UNLINK => 1))[1];
				my $cliResult = RISC::CiscoCLI::checkCLISSH($address,$username,$password,$enable,$logfile);
				my ($status,$reason) = split(':',$cliResult);
				if ($status != 0) {
					$credentials->execute($deviceid,$cliCredid,'ssh',$deviceid,'ssh','N/A');
					$logger->info("succeeded cisco cli over ssh with credid $cliCredid, without enable mode");
					last;
				}
				my $log = RISC::CiscoCLI::parseCLILog($logfile, $username, $password);
				$logInsert->execute($assessmentid,$address,$address,'N/A',$log);
			}
		}
	}
	return;
}

sub testWindows {
	my $host = shift;
	my $win_deviceid = shift; # make sure that we enter the cred under the appropriate deviceid
	foreach my $cred (@{ $windows_creds }) {
		$logger->debug(sprintf("trying wmi with credid %d",$cred->{'credid'}));

		my $wmi = RISC::riscWindows->new({
			host		=> $address,
			debug		=> $debugging,
			db			=> $mysql2,
			%{ $cred }
		});

		unless ($wmi->connected()) {
			$inventoryerrors->execute(
				$assessmentid,
				$host,
				$host,
				'',
				$wmi->err(),
				time()
			);
			push(@user_error_stack, {
				type		=> FAILURE_CREDENTIAL,
				proto		=> PROTOCOL_WMI,
				cred		=> $cred->{'credtag'},
				category	=> $wmi->user_log_classify($wmi->err()),
				error		=> $wmi->err()
			});
			next;
		}

		my $dns = (windows_check_dns($wmi)) ? 'dns' : undef;

		eval {
			$credentials->execute(
				$win_deviceid,
				$cred->{'credid'},
				'windows',
				$win_deviceid,
				'windows',
				$dns
			);
			$logger->info(sprintf(
				"created credentials record: %s:windows:%d",
				$win_deviceid,
				$cred->{'credid'}
			));
		}; if ($@) {
			$logger->info('duplicate of existing credentials record');
		}

		$logger->info(sprintf("succeeded wmi with credid %s",$cred->{'credid'}));

		return $cred;
	}
	return;
}

sub windows_check_dns {
	my $wmi = shift;
	my $return;

	$logger->info('trying dns');
	my $atypes = $wmi->dnsQuery('MicrosoftDNS_AType');
	if (scalar(@{$atypes}) > 0) {
		$return = 1;
		$logger->info('succeeded dns');
	} else {
		$return = 0;
	}

	return $return;
}

## avoid_win_gen_clash($deviceid, $address)
## this routine prevents the weird edge case that appears to occur when:
##   - a generic server (or snmp) device is inventoried on an ip
##   - the device's cred is removed
##   - a windows device is later inventoried on the same ip
## the current behavior in that case is for the same deviceid to be assigned to the
## windows server and the generic server. This causes a lot of confusion downstream.
## this fix will not prevent windows devices from replacing other windows devices if a
## similar exchange occurs, because windows identity is not well-handled by this system;
## however, fixing that larger problem is both harder and riskier than just applying a
## patch to this specific issue, especially since our inventory agg system appears to 
## handle that case well enough that no such issues have been reported.
sub avoid_win_gen_clash {
	my $deviceid = shift;
	my $address = shift;
	$logger->debug("avoiding win_gen_clash for proposed deviceid $deviceid");

	my $devid_is_nonwindows = $mysql2->selectrow_hashref("
		SELECT ipaddress, count(*) AS num
			FROM riscdevice
			WHERE deviceid = ?
			AND sysdescription not in (
				'unknown', 'WindowsDevice'
			)
	", undef, $deviceid);
	if ($devid_is_nonwindows->{'num'} > 0) {
		# if the proposed deviceid belongs to a gensrv, we can be sure that we can't use 
		# the proposed ID. We need to know whether there is also a windows device on this 
		# IP already, and if so, use that deviceid rather than keeping incrementing/duplicating.
		my $has_windows_ip = $mysql2->selectrow_hashref("
			SELECT deviceid, count(*) AS num
				FROM riscdevice 
				INNER JOIN credentials USING (deviceid)
				WHERE ipaddress = ?
				AND technology = 'windows'
		", undef, $address);
		if ($has_windows_ip->{'num'} > 0) {
			# unfortunately, we don't currently keep up with windows devices swapping
			# the best we can do is to not unnecessarily duplicate the device
			return $has_windows_ip->{'deviceid'};
		} else {
			return next_derived_deviceid();
		}

	} else {
		$logger->debug("giving requested deviceid $deviceid, deviceid not in use");
		return $deviceid;
	}

}


## next_derived_deviceid()
## I am breaking this out of ensure_unique_deviceid so that it can also be used by avoid_win_gen_clash.
## I am not thoroughly endorsing the procedure used here, but I want it to be the same in both places.
sub next_derived_deviceid {
	my $begin = $assessmentid . 4278190081;	## 255.0.0.1
	my $end = $assessmentid . 4294917295;	## beginning of the vmware range, 255.255.60.175, give us ~16m deviceids of headroom
	my $derived_devid = $mysql2->selectrow_hashref("
		SELECT max(deviceid)+1 AS nextdevid
		FROM riscdevice
		WHERE deviceid >= ? AND deviceid < ?
	", undef, $begin, $end);
	if (defined($derived_devid) and defined($derived_devid->{'nextdevid'})) {
		$logger->debug("giving derived deviceid $derived_devid->{'nextdevid'}");
		return $derived_devid->{'nextdevid'};
	} else {
		$logger->debug("giving beginning of derived deviceid range: $begin");
		return $begin;
	}
}
## ensure_unique_deviceid()
## this routine prevents deviceid duplication for the revisioning scan mode
##    if the ip-based deviceid is not currently held, then we return it
##    if the ip-based deviceid is held by a cred-mapped deviceid
##      if we are NOT revisioning mode, we return the ip-based deviceid, keeping legacy behavior
##      if we ARE revisioning mode, we return a derived-range deviceid
##    if the ip-based deviceid is held by a non-cred-mapped deviceid, we remove that current record and return the ip-based deviceid
## in this last case, a deviceid held by a non-cred-mapped device is either an inaccessible device, or the cred mapping was lost
sub ensure_unique_deviceid {
	my $std = shift;

	$logger->debug("determining deviceid with requested: $std");

	my $devid_exists = $mysql2->selectrow_hashref("
		SELECT count(*) AS num
			FROM riscdevice
			WHERE deviceid = $std
		")->{'num'};
	if ($devid_exists > 0) {
		my $credmapped = $mysql2->selectrow_hashref("
			SELECT count(*) AS num
			FROM credentials
			WHERE deviceid = $std
		")->{'num'};
		if ($credmapped) {
			return $std unless ($doing_update);	## return the ip-based deviceid if we are not revisioning
			return next_derived_deviceid();
		} else {
			$logger->info("removing riscdevice record with deviceid $std for incoming device to claim");
			$mysql2->do("DELETE FROM riscdevice WHERE deviceid = ?", undef, $std);
			$logger->debug("giving requested deviceid $std, current holder inferior");
			return $std;
		}
	} else {
		$logger->debug("giving requested deviceid $std, deviceid not in use");
		return $std;
	}
}

## remove a device from inventory, as it has been determined to no longer exist
## this is used when an IP address that was a distinct device is now an additional IP on another, existing, device
## we keep the riscdevice entry such that the deviceid does not get reused, as this may confuse downstream
sub decommission_device {
	my $deviceid = shift;
	$logger->info("decommissioning device with deviceid: $deviceid");
	eval {
		$update_riscdevice_decom->execute($deviceid, $deviceid);
		$mysql2->do("delete from credentials where deviceid = ?", undef, $deviceid);
		$update_inventorylog->execute($deviceid);
		riscUtility::removeDeviceByDeviceid($deviceid);
	};
	$logger->info("removed $deviceid from credentials, set inventorylog decom bit, set macaddr to deviceid, set ipaddress to 'decommissioned'");
}

sub map_cli_existing {
	my ($devid) = @_;
	$logger->debug("determining if $devid is a network device that needs cisco cli mapping");
	my $is_network = $mysql2->selectrow_hashref("select count(*) as num from networkdeviceinfo where deviceid = ?", undef, $devid)->{'num'};
	if ($is_network) {
		my $has_cli = $mysql2->selectrow_hashref("select count(*) as num from credentials where deviceid = ? and technology = 'ssh'", undef, $devid)->{'num'};
		if ($has_cli) {
			$logger->debug('cisco cli already mapped');
		} else {
			$logger->info("device $devid meets cisco cli requirements, attempting to map it");
			my $cli_eligible = $mysql2->selectrow_hashref("select vendor,sysdescription from networkdeviceinfo inner join snmpsysinfo using (deviceid) where deviceid = ?", undef, $devid);
			if ($cli_eligible->{'vendor'} =~ /cisco/i) {
				my $NX = 0;
				$NX = 1 if ($cli_eligible->{'sysdescription'} =~ /NX/);
				testCLI($existing->{'deviceid'},$NX);
			}
		}
	}
}
