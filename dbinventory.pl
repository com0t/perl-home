#!/usr/bin/perl -w
use DBI;
use RISC::riscUtility;
use RISC::riscCreds;
use Socket; 
use Time::Local;
use Data::Dumper;
use POSIX;
use RISC::Collect::Audit;
use RISC::Collect::Logger;
$|++;

# VERSION 2.1. Deals with the godawful chance that multiple oracle sid's are on one port
# 		dboids for oracle databases are appended with '0..0$credid' (enough 0s to fill bigint)
# VERSION 2.0. Handles re-inventory well.
my $logger = RISC::Collect::Logger->new('database-inventory');

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

my $credobj = riscCreds->new();
my @dbcreds = @{$credobj->getAllDB()};

my $riscdevice = $mysql->prepare("INSERT IGNORE INTO riscdevice (deviceid, ipaddress, macaddr, sysdescription) VALUES (?, ?, ?, ?)");

my $dbinventory = $mysql->prepare("INSERT INTO db_inventory
	(dboid, credid, hostdevice, can_acc, dbtype, version, hostname, hostip, hostport, initialdbs, initialconns, extracol1)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

my $oracleSID = $mysql->prepare("UPDATE db_inventory SET oraclesid = ? WHERE dboid = ?");

my $credadd = $mysql->prepare("INSERT IGNORE INTO credentials (deviceid, credentialid, technology, uniqueid, level) VALUES (?, ?, ?, ?, ?)");

# delete statements (only call where needed)
#my $creddrop = $mysql->prepare("DELETE FROM credentials WHERE deviceid = ?"); # not used
my $rddrop = $mysql->prepare("DELETE FROM riscdevice WHERE deviceid = ?");
#my $invdrop = $mysql->prepare("DELETE FROM db_inventory WHERE dboid = ?"); # not used

# queries required to tell if the device has been previously inventoried, accessed, and/or homed:
my $isnew = $mysql->prepare("SELECT COUNT(*) FROM db_inventory WHERE dboid = ?"); # will return 0 or 1
my $isacc = $mysql->prepare("SELECT can_acc, initialconns, hostdevice FROM db_inventory WHERE dboid = ?");

my $mssql_full_version_check = $mysql->prepare("SELECT IF(extracol1 IS NULL, 'no', 'yes') AS has_full_version FROM db_inventory WHERE dboid = ?");

#my $ishomed = $mysql->prepare("SELECT COUNT(*) FROM db_inventory WHERE hostdevice = ?"); #not used
# explanation of ishomed: if the database was not homed to an existing win or snmp device,\
# then the hostdevice field would have been set to the dboid

# queries to update/change riscdevice and db_inventory
# for db_i, shouldn't need to change dboid, ip, port, credid. I guess the user could have changed dbtype.
# hostdevice will change in a different query.
my $updb = $mysql->prepare("UPDATE db_inventory SET dbtype = ?, can_acc = ?, version = ?, hostname = ?, initialdbs = ?, initialconns = ?, extracol1 = ? WHERE dboid = ?");
my $updbhost = $mysql->prepare("UPDATE db_inventory SET hostdevice = ? WHERE dboid = ?");

# query to check if the database is already in riscdevice
# my $rdcheck = $mysql->prepare("SELECT COUNT(*) c FROM riscdevice WHERE deviceid = ?");

# CLOUD-7054 - if we remove creds, we don't remove the mapping. We need to, because it's a valid case 
# that a user might add a cred and later delete it in favor of a different one.
removeStaleDbCredMappings();

while (my $conn = shift(@dbcreds)){
	my $dbtype = $conn->{'type'};
	my $serverip = $conn->{'target'};
	my $cport = $conn->{'port'};
	my $username = $conn->{'username'};
	my $pw = $conn->{'password'};
	my $orsid = $conn->{'orsid'} if $dbtype eq 'oracle';

	# generate the dboid: integer ip cat port
	my $dboid = unpack("N", inet_aton($serverip)) . $cport;
	if ($dbtype eq 'oracle'){
		# because multiple oracle sid's could share ip/port, we must add credid
		# to reduce the likelihood of collisions, pad the ip/port/cred number out to 19 digits
		# $dboid .= $conn->{'credid'}; # don't be lazy.
		my $dplaces = ceil(log($dboid+1)/log(10))+ceil(log($conn->{'credid'}+1)/log(10));
		my $padding = "0"x(19-$dplaces);
		$dboid .= $padding . $conn->{'credid'};
	}
	my $accessible = 1;
	my $initialNumSchemas = 0;
	my $initialNumConns = 0;
	my $hostname;
	my $version;
	my $full_version = undef;	# MCM-231: created to store the full MSSQL version (stored in extracol1)

	# is this a new database?
	$isnew->execute($dboid);
	my ($new) = 1-$isnew->fetchrow_array;

	# is this database previously unaccessible, or was the number of connections suspicious?
	$isacc->execute($dboid);
	my $someinfo = $isacc->fetchrow_hashref;
	my $acc = $someinfo->{'can_acc'};
	my $conflag = $someinfo->{'initialconns'};
	my $hostdevice = $someinfo->{'hostdevice'};
	# was the database unable to be homed to a discovered network device?
	my $homed;
	if (defined($hostdevice)){
		$homed = !($hostdevice eq $dboid);
	}else{
		$homed = 0;
	}
	#$ishomed->execute($dboid);
	#my ($homed) = $ishomed->fetchrow_array;
	
	my $has_no_mssql_version = 0;
	if($dbtype eq "mssql") {
		$mssql_full_version_check_answer = $mysql->selectrow_hashref("SELECT IF(extracol1 IS NULL, 'no', 'yes') AS has_full_version FROM db_inventory WHERE dboid = $dboid");
		$has_no_mssql_version = $mssql_full_version_check_answer->{'has_full_version'} eq 'no';
	}

	# if this is a rerun and everything is already good with the test probe, you don't need this part:
	if ($new || !$acc || ($conflag<2) || $has_no_mssql_version){
		my %audit = (
			protocol => $dbtype,
			ip => $serverip,
			port => $cport,
			direction => 'out',
			credential => $conn->{'credid'},
		);

		# get into the database and get the inventory info. Details depend on dbtype.
		if ($dbtype eq "mysql"){
			my $dbstr = ("DBI\:mysql\:\:host=$serverip;port=$cport");
			my $dbh;
			eval {
				($dbh, $accessible) = connect_with_timeout($dbstr,$username,$pw, $conn->{'credid'});
			}; if ($@) {
				$accessible = 0;
				$logger->warn("cred $conn->{'credid'} did not succeed: $@");
			}
			if ($accessible){
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);
				my $infoquery = $dbh->prepare("SELECT \@\@hostname h, \@\@version v");
				$infoquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $infoquery->{Statement}, status => 0);
				my $instanceinfo = $infoquery->fetchrow_hashref;
				$hostname = $instanceinfo->{'h'};
				$version = $instanceinfo->{'v'};
				# ALSO HERE run a sample show dbs and a sample connection query
				# record the number of results, this will alert us if the permissions are wrong.
				my $schemasquery = $dbh->prepare("SELECT SCHEMA_NAME FROM information_schema.schemata");
				$schemasquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);
				$initialNumSchemas = 0; # $schemasquery->rows;
				while ($schemasquery->fetchrow_hashref){
					$initialNumSchemas++;
				}
				my $connquery = $dbh->prepare("SELECT host, db, command, state, time FROM information_schema.processlist");
				$connquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $connquery->{Statement}, status => 0);
				$initialNumConns = 0; #$connquery->rows;
				while ($connquery->fetchrow_hashref){
					$initialNumConns++;
				}
			} # if accessible
			else {
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
			}
		}elsif($dbtype eq "mssql"){
			
			$logger->info("inventory mssql db");
			
			# first thing, we need to write to the damn config file if it is not already done.
			# colvin may symlink to a different location, does that affect writing to it?
			# if so, just change the name/location of the file right here:
			my $conffile = '/etc/freetds/freetds.conf';
			my $configname = "$serverip\:$cport";
			my $appears = 0;
			open(my $fh, "<", $conffile) or die("failed opening tds config file\n");
			while(my $line=$fh->getline()){
				if($line=~$configname){
					print "Found existing tds configuration!\n";
					$appears = 1;
					last;
				}
			} # end search config
			close($fh);
			if(!$appears){
				open($fh, '>>', $conffile);
				say $fh '['.$configname .']';
				say $fh "\thost = $serverip";
				say $fh "\tport = $cport";
				say $fh "\ttds version = 7.1";
				say $fh "\tuse ntlmv2 = yes";
				say $fh "\tencryption = request";
				say $fh '';
				close($fh);
			} # end write to config file
			
			$logger->info("Connecting to SQL Server");
			
			# okay, christ, that's done with.
			# finally now, connect to the SQL Server.
			my $dbstr = 'DBI:Sybase:server=' . $configname;
			my $dbh;
			eval {
				($dbh, $accessible) = connect_with_timeout($dbstr,$username,$pw, $conn->{'credid'});
			}; if ($@) {
				$accessible = 0;
				$logger->warn("cred $conn->{'credid'} did not succeed: $@");
			}
			if($accessible){
				
				$logger->info("DB is Accessible");
								
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);
				# requires View Server State permission
				my $infoquery = $dbh->prepare("select CAST(SERVERPROPERTY ('ProductVersion') AS VARCHAR) v, CAST(SERVERPROPERTY ('MachineName') AS VARCHAR) h");
				$infoquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $infoquery->{Statement}, status => 0);
				my $instanceinfo = $infoquery->fetchrow_hashref;
				$hostname = $instanceinfo->{'h'};
				$version = $instanceinfo->{'v'};

				$logger->info("Found $hostname $version");
								
				# collect the full version information
				my $full_version_query = $dbh->prepare("SELECT
				  CASE
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '8%' THEN 'MS SQL Server 2000'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '9%' THEN 'MS SQL Server 2005'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.0%' THEN 'MS SQL Server 2008'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.5%' THEN 'MS SQL Server 2008 R2'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '11%' THEN 'MS SQL Server 2012'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '12%' THEN 'MS SQL Server 2014'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '13%' THEN 'MS SQL Server 2016'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '14%' THEN 'MS SQL Server 2017'
					 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '15%' THEN 'MS SQL Server 2019'
					 ELSE 'unknown'
				  END AS MajorVersion,
				  CAST( SERVERPROPERTY('ProductLevel') AS VARCHAR) AS ProductLevel,
				  CAST( SERVERPROPERTY('Edition') AS VARCHAR) AS Edition");
				$full_version_query->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $full_version_query->{Statement}, status => 0);
				my $full_version_info = $full_version_query->fetchrow_hashref;
				$full_version = "$full_version_info->{'MajorVersion'} $full_version_info->{'ProductLevel'} $full_version_info->{'Edition'}";

				$logger->info("MS SQL Full Version: $full_version");

				my ($verN) = $version =~ /^(\d*)./;
				# ALSO HERE run a sample show dbs and a sample connection query
				# record the number of results, this will hopefully alert us if the permissions are wrong.
				# requires VIEW ANY DATABASE permission...?
				my $schemasquery = $dbh->prepare("SELECT name, database_id, create_date FROM sys.databases");
				$schemasquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);
				while ($schemasquery->fetchrow_hashref){
					$initialNumSchemas++;
				}
				my $msbigq = 'SELECT conn.client_net_address, '.
					'conn.client_tcp_port, '.
					'sess.status, '.
					'sess.last_request_start_time, '.
					'DB_NAME(sess.database_id) AS db ' .
					'FROM sys.dm_exec_sessions sess '.
					'LEFT JOIN sys.dm_exec_connections conn '.
					'ON sess.session_id=conn.session_id '.
					'WHERE sess.is_user_process=1;';
				$msbigq = 'SELECT conn.client_net_address, conn.client_tcp_port, sess.status, sess.last_request_start_time,
					dat.name as db from sys.dm_exec_sessions sess inner join sys.dm_exec_connections conn
					on sess.session_id = conn.session_id
					inner join master.dbo.sysprocesses pro on sess.session_id = pro.spid
					inner join sys.databases dat on pro.dbid = dat.database_id
					where sess.is_user_process=1' if $verN==10;
				my $connquery = $dbh->prepare($msbigq);
				$connquery->execute();
				audit(%audit, timestamp => time(), type => 'query', resource => $connquery->{Statement}, status => 0);
				while ($connquery->fetchrow_hashref){
					$initialNumConns++;
				}
			} #if accessible
			else {
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
			}
		}elsif($dbtype eq "oracle"){
			eval{system('bash /srv/httpd/htdocs/shell/hosts_update.sh');};
			my $dbstr = "dbi:Oracle:host=$serverip;port=$cport;sid=$orsid";
			my $dbh;
			eval {
				($dbh, $accessible) = connect_with_timeout($dbstr,$username,$pw, $conn->{'credid'});
			}; if ($@) {
				$accessible = 0;
				$logger->warn("cred $conn->{'credid'} did not succeed: $@");
			}
			if ($accessible) {
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);
				eval {
					my $infoquery = $dbh->prepare('SELECT HOST_NAME H, VERSION V FROM V$INSTANCE');
					# note that multiple servers can mount an oracle database, so GV$INSTANCE may return
					# several rows. Would this be desirable?
					# NOTE THIS BULLSHIT: ALIASES WILL BE CAPITALIZED NO MATTER IF YOU GIVE THEM LOWERCASE OR WHAT.
					# also note that select sys_context('USERENV','SERVER_HOST') h from dual
					# also returns the server host name without requiring $ permissions, but we
					# need those anyway.
					$infoquery->execute();
					audit(%audit, timestamp => time(), type => 'query', resource => $infoquery->{Statement}, status => 0);
					my $instanceinfo = $infoquery->fetchrow_hashref();
					$hostname = $instanceinfo->{'H'};
					$version = $instanceinfo->{'V'};
					# initial number of schemas with objects attached:
					my $schemasquery = $dbh->prepare("SELECT username FROM dba_users u WHERE EXISTS (SELECT 1 FROM dba_objects o WHERE o.owner = u.username)");
					$schemasquery->execute();
					audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);
					while ($schemasquery->fetchrow_hashref){
						$initialNumSchemas++;
					}
					my $orbigq = "SELECT MACHINE, PORT, SCHEMANAME, STATUS, COMMAND, LAST_CALL_ET FROM v\$session WHERE username IS NOT NULL";
					my $connquery = $dbh->prepare($orbigq);
					$connquery->execute();
					audit(%audit, timestamp => time(), type => 'query', resource => $connquery->{Statement}, status => 0);
					while ($connquery->fetchrow_hashref){
						$initialNumConns++;
					}
				};
				$accessible = 0 if $@;
			} # if accessible
			else {
				audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
			}
		} else {
			die("invalid database type, how did this even happen???");
		} # end of dbtype switch
	} # end of the statement so this bit only runs if something was wrong with it or it's new

	# need to find out if the database is on an already discovered device, or if we need to make a new deviceid for it.
	# again, we can skip this step if the database was already homed on an inventoried network device
	#my $hostdevice;
	if ($new || !$homed){

		# $serverip is provided and unique within this loop iteration, so let's search for it
		my $deviceknown = 0;

		my $windowsdevices = $mysql->prepare("
			SELECT
				deviceid,
				ipaddress
			FROM
				windowsnetwork
			WHERE
				ipaddress is NOT NULL
				and
				ipaddress != 'NULL'");
		$windowsdevices->execute();
		while (my $wins = $windowsdevices->fetchrow_hashref){
			if ($wins->{'ipaddress'} =~ /[\(,]\Q$serverip\E[\),]/){
				$deviceknown = 1;
				$hostdevice = $wins->{'deviceid'};
				last;
			}
		} # windows device loop

		if ($deviceknown == 0){
			my $snmpdevices = $mysql->prepare("SELECT deviceid, ip FROM gensrvserver INNER JOIN iptables USING (deviceid);");
			# this inner join serves the purpose of eliminating switches and the like from iptables
			$snmpdevices->execute();
			while (my $snmps = $snmpdevices->fetchrow_hashref){
				if ($snmps->{'ip'} eq $serverip){
					$deviceknown = 1;
					$hostdevice = $snmps->{'deviceid'};
					last;
				}
			} # snmp device loop
		}

		if ($deviceknown == 0){
			my $vmdevices = $mysql->prepare("
				SELECT rvm.deviceid, vgs.ipaddress
				FROM riscvmwarematrix rvm
				INNER JOIN vmware_guestsummaryconfig vgs
				ON rvm.vcenterid = vgs.deviceid and rvm.uuid = vgs.uuid
				");
			$vmdevices->execute();
			while (my $vms = $vmdevices->fetchrow_hashref){
				if ($vms->{'ipaddress'} eq $serverip) {
					$deviceknown = 1;
					$hostdevice = $vms->{'deviceid'};
					last;
				}
			}
		}
		# if device is STILL unknown, then it is not on a discovered device.
		if ($deviceknown == 0){
			# we will need to add the device into riscdevice. do that here.
			$riscdevice->execute($dboid,$serverip,$dboid,"DB_NOI");

			# also, still want hostdevice to be defined:
			$hostdevice = $dboid;
		}
	}
	
	# OKAY. so we know the host device, or have concluded it is unknowable.
	# Now we just need to put everything into the db_inventory database
	# UNLESS THIS IS NOT THE FIRST TIME WE INVENTORIED THIS DATABASE. in which case
	if ($new){
		#(dboid, credid, hostdevice, accessible, dbtype, version, hostname, hostip, hostport, initialdbs, initialconns, extracol1)
		$dbinventory->execute($dboid, $conn->{'credid'}, $hostdevice, $accessible, $dbtype, $version, $hostname, $serverip, $cport,$initialNumSchemas, $initialNumConns, $full_version);
		if ($dbtype eq 'oracle'){
			#my $oracleSID = $mysql->prepare("UPDATE db_inventory SET oraclesid = ? WHERE dboid = ?");
			$oracleSID->execute($orsid,$dboid);
		}
		# and finally, we need to update RISC_Discovery.credentials to link dboid to credential.
		# (deviceid, credentialid, technology, uniqueid, level)
		$credadd->execute($dboid, $conn->{'credid'}, 'db', "$dboid-db", $dbtype);
		# make sure adding to big RISC.creds doesn't break anything.
	}elsif((!$acc && $accessible) || (($conflag<2) && ($initialNumConns>=2)) || $has_no_mssql_version){

		$logger->info("updating database $hostname with $full_version");

		# ^ indicate that there was a connectivity issue which is now resolved
		# then we need to update the db_inventory
		# Joel says that best practices are to update, not drop and replace.
		#my $updb = $mysql->prepare("UPDATE db_inventory SET dbtype = ?, can_acc = ?, version = ?, hostname = ?, initialdbs = ?, initialconns = ? WHERE dboid = ?");
		#my $updbhost = $mysql->prepare("UPDATE db_inventory SET hostdevice = ? WHERE dboid = ?");
		$updb->execute($dbtype, $accessible, $version, $hostname, $initialNumSchemas, $initialNumConns, $full_version, $dboid);
	}
	# adding homeless databases to riscdevice was already handled above. Here, we need to deal with the case where
	# the host device was previously not discovered, but now it is.
	if (!$new && !$homed && !($dboid eq $hostdevice)){
		# first we need to drop the DB_NOI device from riscdevice:
		# syntax: my $rddrop = $mysql->prepare("DELETE FROM riscdevice WHERE deviceid = ?");
		$rddrop->execute($dboid);
		# then we update the host
		# syntax: my $updbhost = $mysql->prepare("UPDATE db_inventory SET hostdevice = ? WHERE dboid = ?");
		$updbhost->execute($hostdevice,$dboid);
	}
} # while dbcreds

# delete records from db_inventory that aren't associated with active credentials.
# also delete a subset of those which are inaccessible from riscdevice.
# otherwise, these hang around and continue to (re)populate visiodevices on subsequent inventories.
# this includes both deleted and edited credentials.
sub removeStaleDbCredMappings {
	$logger->info("Deleting riscdevice and db_inventory records that are mapped to stale records in credentials.");

	# remove inaccessible databases not tied to active creds from riscdevice, and subsequently visiodevices
	my $stale_riscdevice = $mysql->prepare("
		DELETE FROM `RISC_Discovery`.`riscdevice` WHERE deviceid IN
		(
			SELECT dboid FROM `RISC_Discovery`.`db_inventory`
			WHERE dboid NOT IN
			(
				SELECT IF(
					(`risc_discovery`.cred_decrypt(context) = 'oracle'),
					CONCAT(INET_ATON(FROM_BASE64(testip)), port, LPAD(credid, (19 - LENGTH(CONCAT(INET_ATON(FROM_BASE64(testip)), port))), 0)),
					CONCAT(INET_ATON(FROM_BASE64(testip)), port)
				) AS dboid
				FROM `risc_discovery`.`credentials`
				WHERE technology = 'db' AND removed = 0
			)
			AND can_acc = 0
		)
	");
	$stale_riscdevice->execute();
	$logger->info('removed ' . $stale_riscdevice->rows . ' rows from riscdevice');

	# dboid is numeric ip concatenated w/port for non-oracle. oracle is further appended with the credid left-padded with zeroes for a total dboid length of 19 digits.
	my $stale_db_inventory = $mysql->prepare("
		DELETE FROM `RISC_Discovery`.`db_inventory` WHERE dboid NOT IN
		(
			SELECT IF(
				(`risc_discovery`.cred_decrypt(context) = 'oracle'),
				CONCAT(INET_ATON(FROM_BASE64(testip)), port, LPAD(credid, (19 - LENGTH(CONCAT(INET_ATON(FROM_BASE64(testip)), port))), 0)),
				CONCAT(INET_ATON(FROM_BASE64(testip)), port)
			) AS dboid
			FROM `risc_discovery`.`credentials`
			WHERE technology = 'db' AND removed = 0
		)
	");
	$stale_db_inventory->execute();
	$logger->info('removed ' . $stale_db_inventory->rows . ' rows from db_inventory');
}


sub connect_with_timeout {
        my $db_str = shift;
        my $user_name = shift;
        my $p_w = shift;
        my $cred_id = shift;

        my $dbh;
        my $accessible = 1;

        my $mask = POSIX::SigSet->new( SIGALRM );
        my $action = POSIX::SigAction->new(
                sub { die "connect timeout" },
                $mask,
        );
        my $oldaction = POSIX::SigAction->new();
        my $failed;
        sigaction( SIGALRM, $action, $oldaction);
        eval {
                eval {
                        alarm(70); 
                        $dbh = DBI->connect($db_str, $user_name, $p_w,{LongTruncOk => 1,PrintError=>0,RaiseError=>0})
                                or $accessible = 0;
                        1;
                } or $failed=1;
                alarm(0);
                die "$@\n" if $failed;
                1;
        } or $failed = 1;
        sigaction( SIGALRM, $oldaction );
        if ( $failed ) {
                $accessible = 0;
                $logger->warn("db cred $cred_id failed timeout test: $@");
        }
        return $dbh, $accessible;
}
