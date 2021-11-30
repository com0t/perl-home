#!/usr/bin/perl -w
use DBI;
use RISC::riscUtility;
use RISC::Collect::Audit;
use Socket; # instead let's try the thing that is already on?:
#use IO::Socket::INET;
use Time::Local;
use Data::Dumper;
$|++;

# connect the database:
our $mysql = riscUtility::getDBH('RISC_Discovery',1);

# mebbe I will hand in dboid instead of credid, remains to be seen. OR BOTH WOW WHAT A WORLD WE LIVE IN
our $dboid = shift;
my $credid = shift;

my $credobj = riscCreds->new();
my $creddata = $credobj->getDB($credid);
our $dbtype = $creddata->{'type'};
my $serverip = $creddata->{'target'};
my $cport = $creddata->{'port'};
my $username = $creddata->{'username'};
my $pw = $creddata->{'password'};
my $orsid = $creddata->{'orsid'} if $dbtype eq 'oracle';


##############################OUTPUT SETUP#################################################
# will have to have the dbprobe output db set up obvi
our $outputh = $mysql->prepare("INSERT INTO db_probe (dboid, scantime, srcaddr, srcport, db, command, state, runtime) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
# clear mysql of strict_trans_tables so that long sql queries won't break the insert (will just truncate)
# not sure if this is necessary
my $schins = $mysql->prepare("INSERT INTO db_schemalist (dboid, scantime, db) VALUES (?, ?, ?)");
$mysql->do("SET SESSION sql_mode='';");
#############################END OUTPUT SETUP################################################



our $qtime = time();
my $i = 0;
my @rowHashrefs;
my $distinctUsersBySchema;
print "$dbtype$credid--$qtime\n"; # does this go somewhere useful? copying it anyway.

my %audit = (
	protocol => $dbtype,
	ip => $serverip,
	port => $cport,
	direction => 'out',
	credential => $credid,
);

if($dbtype eq "mysql"){
	my $dbstr = ("DBI\:mysql\:\:host=$serverip;port=$cport");
	my $dbh = DBI->connect(
		$dbstr, $username,$pw,
		{'RaiseError' =>1}
	) or do {
		audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
		die("Couldn't connect to server.");
	};
	audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);

	# show databases first
	my $schemasquery = $dbh->prepare("SELECT SCHEMA_NAME s FROM information_schema.schemata");
	$schemasquery->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);

	while (my $sch=$schemasquery->fetchrow_hashref) {
		$schins->execute($dboid, $qtime, $sch->{'s'});
	}
	my $query = $dbh->prepare("SELECT host, db, command, state, time FROM information_schema.processlist");
	$qtime = time(); # measure the time again in case the show tables step took nontrivially long
	$query->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $query->{Statement}, status => 0);
	while (my $conn = $query->fetchrow_hashref){
		$i++;
		#print Dumper($conn);
		my ($ip,$port) = split(':',$conn->{'host'});

		# for mysql, the processing is minimal. we must split the host name and port apart and resolve the hostname to ip
		if ($ip =~/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/){
 			$ip=$1;
  		}elsif (my ($a,$b,$c,$d) = $ip=~/(\d{1,3})\-(\d{1,3})\-(\d{1,3})\-(\d{1,3})/){
  			$ip = "$a.$b.$c.$d";
  		}else{
  			#Here we don't have a host so we have to pull out the IP
			eval{$ip = inet_ntoa(inet_aton($ip))}; # this may not work with IPv6 so I should revisit...? Or see how others do it.
  		}

  		# order: dboid, scantime, srcaddr, srcport, user, db, command, state, runtime
  		#$outputh->execute($dboid,$qtime,$ip,$port,$conn->{'db'},$conn->{'command'},$conn->{'state'},$conn->{'time'});
  		my $temphash->{'dbtype'}=$dbtype;
  		$temphash->{'dboid'}=$dboid;
  		$temphash->{'scantime'}=$qtime;
  		$temphash->{'srcaddr'}=$ip;
  		$temphash->{'srcport'}=$port;
  		$temphash->{'db'}=$conn->{'db'};
  		$temphash->{'command'}=$conn->{'command'};
  		$temphash->{'state'}=$conn->{'state'};
  		$temphash->{'runtime'}=$conn->{'time'};
  		push @rowHashrefs,$temphash;
	}

	# finally let's get a distinct username query; actually two, one for by-schema and one for the whole instance
	$distinctUsersBySchema = $dbh->selectall_hashref("select db, count(distinct(user)) userCount from information_schema.processlist group by db",'db');
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	my $distinctUsersWholeInstance = $dbh->selectall_arrayref("select count(distinct(user)) userCount from information_schema.processlist");
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	$distinctUsersBySchema->{'whole_db_RNRNRN'}->{'userCount'}=$distinctUsersWholeInstance->[0]->[0];
	#print Dumper($distinctUsersWholeInstance);

}elsif($dbtype eq "mssql"){
	# I think it is safe to assume that the config file was properly written during discovery phase.
	# therefore we will simply use it.
	# note that the config file must contain an entry like [$serverip:$cport]
	my $dsn = "DBI\:Sybase\:server=$serverip\:$cport";
	my $dbh = DBI->connect($dsn, $username, $pw) or do {
		audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
		die("unable to connect to server $DBI::errstr");
	};
	audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);

	my $schemasquery = $dbh->prepare("SELECT name s FROM sys.databases");
	$schemasquery->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);

	while (my $sch=$schemasquery->fetchrow_hashref) {
		$schins->execute($dboid, $qtime, $sch->{'s'});
	}
	my $verQ = $dbh->selectrow_hashref("select CAST(SERVERPROPERTY ('ProductVersion') AS VARCHAR) v");
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	my ($verN) = $verQ->{'v'} =~ /^(\d*)./;

	my $msbigq = 'SELECT conn.client_net_address, '.
		'conn.client_tcp_port, '.
		'sess.status, '.
		'datediff(second,sess.last_request_start_time,getdate()) as runsec, '.
		'DB_NAME(sess.database_id) AS db ' .
		'FROM sys.dm_exec_sessions sess '.
		'LEFT JOIN sys.dm_exec_connections conn '.
		'ON sess.session_id=conn.session_id '.
		#'LEFT JOIN sys.dm_exec_requests req '.
		#'ON sess.session_id=req.session_id '.
		# 'OUTER APPLY sys.dm_exec_sql_text(req.sql_handle) '. #;';
		'WHERE sess.is_user_process=1;';
	$msbigq = 'SELECT conn.client_net_address, conn.client_tcp_port, sess.status, datediff(second,sess.last_request_start_time,getdate()) as runsec,
					dat.name as db from sys.dm_exec_sessions sess inner join sys.dm_exec_connections conn
					on sess.session_id = conn.session_id
					inner join master.dbo.sysprocesses pro on sess.session_id = pro.spid
					inner join sys.databases dat on pro.dbid = dat.database_id
					where sess.is_user_process=1' if $verN==10;
	# if we are willing to sacrifice "command" (which is roughly analogous to mysql state) we can just not call req, better for security.
	my $query = $dbh->prepare($msbigq);
	$qtime = time(); # in case show databases step took longer than I think it will
	$query->execute;
	audit(%audit, timestamp => time(), type => 'query', resource => $query->{Statement}, status => 0);

	while (my $conn = $query->fetchrow_hashref){
		$i++;
		# note that, unlike in mysql, idle connections will have a long "run"time
		# only the time value will only be meaningful where command/status = 'running'.
		#my $mstime = $qtime-wintounixtime($conn->{'last_request_start_time'});
		#$mstime = 0 if $mstime == -1; # I want to find out if the runtime is SUPER negative,
		my $mstime = $conn->{'runsec'};
		# order: dboid, scantime, srcaddr, srcport, db, command, state, runtime; don't use $conn->{'login_name'},sess.login_name,
		#$outputh->execute($dboid,$qtime,$conn->{'client_net_address'},$conn->{'client_tcp_port'},$conn->{'db'},$conn->{'status'},$conn->{'command'},$mstime);
		my $temphash->{'dbtype'}=$dbtype;
  		$temphash->{'dboid'}=$dboid;
  		$temphash->{'scantime'}=$qtime;
  		$temphash->{'srcaddr'}=$conn->{'client_net_address'};
  		$temphash->{'srcport'}=$conn->{'client_tcp_port'};
  		$temphash->{'db'}=$conn->{'db'};
  		$temphash->{'command'}=$conn->{'status'};
  		$temphash->{'state'}=$conn->{'command'};
  		$temphash->{'runtime'}=$mstime;
  		push @rowHashrefs,$temphash;
	}
	my $schemaq = "select DB_NAME(database_id) as db, count(distinct(login_name)) userCount from sys.dm_exec_sessions group by DB_NAME(database_id)";
	$schemaq = "select dat.name as db, count(distinct(loginame)) userCount from master.dbo.sysprocesses pro inner join sys.databases dat on pro.dbid = dat.database_id inner join sys.dm_exec_sessions sess on sess.session_id = pro.spid group by dat.name" if $verN==10;
	$distinctUsersBySchema = $dbh->selectall_hashref($schemaq,'db');
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	my $distinctUsersWholeInstance = $dbh->selectall_arrayref("select count(distinct(login_name)) userCount from sys.dm_exec_sessions");
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	$distinctUsersBySchema->{'whole_db_RNRNRN'}->{'userCount'}=$distinctUsersWholeInstance->[0]->[0];

}elsif($dbtype eq "oracle"){
	eval{system('bash /srv/httpd/htdocs/shell/hosts_update.sh');};
	my $dbstr = "dbi:Oracle:host=$serverip;port=$cport;sid=$orsid";
	my $dbh = DBI->connect($dbstr, $username, $pw,{LongTruncOk => 1}) or do {
		audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
		die("Couldn't connect, Oracle edition.\n");
	};
	audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);

	# in Oracle, schemas are defined as user-owned spaces. I am selecting schemas where an object exists to avoid a huge list of usernames... maybe.
	my $schemasquery = $dbh->prepare("SELECT username S FROM dba_users u WHERE EXISTS (SELECT 1 FROM dba_objects o WHERE o.owner = u.username)");
	$schemasquery->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);

	while (my $sch=$schemasquery->fetchrow_hashref) {
		$schins->execute($dboid, $qtime, $sch->{'S'});
	}


	my $orbigq = "SELECT MACHINE, PORT, SCHEMANAME, STATUS, COMMAND, LAST_CALL_ET FROM v\$session WHERE username IS NOT NULL";
	# command here is not that meaningful. status is the one that corresponds to mysql's command field.
	# cut:  USERNAME,$conn->{'USERNAME'},
	my $query = $dbh->prepare($orbigq);
	$qtime = time();
	$query->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $query->{Statement}, status => 0);

	while (my $conn = $query->fetchrow_hashref){
		$i++;
		# as far as processing... let's go ahead and try to resolve the hostname to an ip address here.
		# first chop off everything in the machine name prior to, and including, the last \
		my ($sourcemachine) = $conn->{'MACHINE'} =~ /([^\\]*)$/;
		my $machinequery = $mysql->prepare("SELECT ip FROM visiodevices WHERE description = ? AND scoped = 1");
		$machinequery->execute($sourcemachine);
		if (my $machineip = $machinequery->fetchrow_hashref){
			$sourcemachine = $machineip->{'ip'};
		}

		# so now $sourcemachine holds the ip if we could find it, otherwise it still has the oracle machine name.
		# POTENTIAL IMPROVEMENT! sometimes I see a connection like "ip-172-191-32-40" which could also be parsed into an ip
		# Haven't done it yet because I don't know how often that happens.
		# ip-xxx-etc turns out also to be the hostname of the instance. I speculate that it's probably more of an aws thing and nothing to really worry about.
		#$outputh->execute($dboid,$qtime,$sourcemachine,$conn->{'PORT'},$conn->{'SCHEMANAME'},$conn->{'STATUS'},$conn->{'COMMAND'},$conn->{'LAST_CALL_ET'});
		my $temphash->{'dbtype'}=$dbtype;
  		$temphash->{'dboid'}=$dboid;
  		$temphash->{'scantime'}=$qtime;
  		$temphash->{'srcaddr'}=$sourcemachine;
  		$temphash->{'srcport'}=$conn->{'PORT'};
  		$temphash->{'db'}=$conn->{'SCHEMANAME'};
  		$temphash->{'command'}=$conn->{'STATUS'};
  		$temphash->{'state'}=$conn->{'COMMAND'};
  		$temphash->{'runtime'}=$conn->{'LAST_CALL_ET'};
  		push @rowHashrefs,$temphash;
	}
	$distinctUsersBySchema = $dbh->selectall_hashref("select schemaname DB, count(distinct(user)) USERCOUNT from v\$session group by schemaname",'DB'); # MOTHERFUCK ORACLE THO
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	# explanation of the above nonsense: oracle returns every column name in all caps. Thus I went ahead and named the two in all caps so that in case other versions
	# of oracle are less obnoxious than this one, it will still work, and now I have to re-key the fucking db field of the hash so that it will work with the
	# function that handles the others.
	foreach my $oracleRow (keys %{ $distinctUsersBySchema }){
		$distinctUsersBySchema->{$oracleRow}->{'userCount'} = $distinctUsersBySchema->{$oracleRow}->{'USERCOUNT'}; # ARE YOU SEEING THIS BULLSHIT
	}
	my $distinctUsersWholeInstance = $dbh->selectall_arrayref("select count(distinct(user)) userCount from v\$session");
	audit(%audit, timestamp => time(), type => 'query', resource => $dbh->{Statement}, status => 0);
	$distinctUsersBySchema->{'whole_db_RNRNRN'}->{'userCount'}=$distinctUsersWholeInstance->[0]->[0];
}


connInsert(@rowHashrefs);
my $perfHash = buildPerfStats(@rowHashrefs);
$perfHash = addDistinctUsers($perfHash,$distinctUsersBySchema);
insertPerfStats($perfHash);
# do I need to finish/disconnect the dbi objects? I don't think so.



#######################SUBS#######################SUBS#################SUBS##############################
sub wintounixtime{
	# this assumes a pretty specific output format such as I got from the test mssql server
	# if this is not constant across mssql implementations then I will DESTROY THE WORLD IN VENGANCE
	# I mean I will cross that bridge when I come to it.
	my ($mon, $day, $yr, $time) = split(' ',shift);
	my $mon_num = 0;
	my @mon_arr = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	# ^ slightly inefficient as I'm defining this array each time the function is called.
	++$mon_num until $mon_arr[$mon_num] eq $mon;
	my ($hr, $min, $sec, $ms) = split(':',$time);
	chop($ms);
	my $aorp = chop($ms);
	if($aorp eq 'P'){
		$hr+=12;
	}
	my $utime = timegm($sec, $min, $hr, $day, $mon_num, $yr);
	return $utime;
}
sub connInsert{
	# we will build the queries to insert into an array of hashrefs. Each element of the array is a line to be inserted, basically.
	# then we just execute it as so:
	# INSERT INTO db_probe (dboid, scantime, srcaddr, srcport, NOT ANYMOREusrname, db, command, state, runtime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	while (my $row = shift) {
		$outputh->execute($row->{'dboid'},$row->{'scantime'},$row->{'srcaddr'},$row->{'srcport'},$row->{'db'},$row->{'command'},$row->{'state'},$row->{'runtime'});
	}
}

sub buildPerfStats{
	# take the same array as connInsert, but build perf stats (#conns etc) and put them into the db_perf database
	# obligatory mumble to gripe about how this would be really slick to build in matlab
	# it would also be easier to make in mysql, but we don't want to do another call because the state of some connections may have changed
	# and it is preferable to have the perf data accurately reflect the connection/flow raw data that we have for this timestamp.

	my $perfHash;
	# so anyway. Our input is an array of hashrefs where each hashref refers to a line of the raw connection table
	# step through each line and add to the counts (or for average things, the running sum) per schema.
	# OMG DID YOU KNOW THAT ++ing an undefined key field results in 1! PERLLLLLL!!!!!!!

	while (my $row = shift) {
		$perfHash->{$row->{'db'}}->{'numConns'}++;
		if (grep $_ eq $row->{'command'}, ('Sleep','sleep','Sleeping','sleeping','INACTIVE')){
			$perfHash->{$row->{'db'}}->{'numSleeping'}++;
			$perfHash->{$row->{'db'}}->{'cumSleepTime'}+=$row->{'runtime'};
			$perfHash->{$row->{'db'}}->{'maxSleepTime'}=$row->{'runtime'} if ($perfHash->{$row->{'db'}}->{'numSleeping'}==1 || $row->{'runtime'}>$perfHash->{$row->{'db'}}->{'maxSleepTime'});
			$perfHash->{$row->{'db'}}->{'minSleepTime'}=$row->{'runtime'} if ($perfHash->{$row->{'db'}}->{'numSleeping'}==1 || $row->{'runtime'}<$perfHash->{$row->{'db'}}->{'minSleepTime'});
		} elsif (grep $_ eq $row->{'command'}, ('Query','Long Data','Prepare','Execute','Running','running','ACTIVE')){
			# Note: All but the last 3 are mysql options. I have not ever seen mysql's status be anything other than "Query" or "Sleep,
			# but I included a few others anyway. Web documentation has mssql's status as "Running", but it actually returns "running"
			$perfHash->{$row->{'db'}}->{'numRunning'}++;
			$perfHash->{$row->{'db'}}->{'cumRunTime'}+=$row->{'runtime'};
			$perfHash->{$row->{'db'}}->{'maxRunTime'}=$row->{'runtime'} if ($perfHash->{$row->{'db'}}->{'numRunning'}==1 || $row->{'runtime'}>$perfHash->{$row->{'db'}}->{'maxRunTime'});
			$perfHash->{$row->{'db'}}->{'minRunTime'}=$row->{'runtime'} if ($perfHash->{$row->{'db'}}->{'numRunning'}==1 || $row->{'runtime'}<$perfHash->{$row->{'db'}}->{'minRunTime'});
		}
		# Need to make a list of distinct ip's connected, so we can count them. Do this with a hash that we can count the keys of
		$perfHash->{$row->{'db'}}->{'distinctIPs'}->{$row->{'srcaddr'}}++;
		# MAKE SURE THIS IS HANDLED SEPARATELY
		$perfHash->{'whole_db_RNRNRN'}->{$row->{'srcaddr'}}++; # gave it an extremely unlikely name so it won't ever collide with an actual schema in the customer database
	}
	#print Dumper($perfHash);
	# Now that we've looped through the whole processlist, get the averages and number of distincts:
	foreach my $schema (keys %{ $perfHash }) {
		$perfHash->{$schema}->{'avSleepTime'}=$perfHash->{$schema}->{'cumSleepTime'}/$perfHash->{$schema}->{'numSleeping'} if defined($perfHash->{$schema}->{'numSleeping'});
		$perfHash->{$schema}->{'avRunTime'}=$perfHash->{$schema}->{'cumRunTime'}/$perfHash->{$schema}->{'numRunning'} if defined($perfHash->{$schema}->{'numRunning'});
		#$perfHash->{$schema}->{'countDistinctIPs'} = scalar keys $perfHash->{$schema}->{'distinctIPs'}; # test all this pleeeeaaaaaaase
		$perfHash->{$schema}->{'countDistinctIPs'} = scalar keys %{ $perfHash->{$schema}->{'distinctIPs'} } unless $schema eq 'whole_db_RNRNRN'; # test all this pleeeeaaaaaaase
	}
	$perfHash->{'whole_db_RNRNRN'}->{'count_of_distinct_ips'} = scalar keys %{ $perfHash->{'whole_db_RNRNRN'} }; # this will not self-count, cool
	#print Dumper($perfHash);

	# next let's get the number of distinct usernames. We need the
	return $perfHash;
}

sub addDistinctUsers{
	my $perfHash = shift;
	my $distinctUsersBySchema = shift;
	foreach my $userRow (keys %{ $distinctUsersBySchema }) {
		$perfHash->{$userRow}->{'distinctUserConns'}=$distinctUsersBySchema->{$userRow}->{'userCount'};
	}
	return $perfHash;
}

sub insertPerfStats{
	my $perfHash = shift;
	# okay, the hash is how we want it. Feed the rows into the mysql table (which will totally exist we swear).
	my $counterInsert = "insert into db_perf_counters (dboid, scantime, db, numConns, numRunning, avRunTime, maxRunTime, minRunTime, numSleeping, avSleepTime, maxSleepTime, minSleepTime, distinctIPs, distinctUsers) values ";
	foreach my $schemaRow (keys %{ $perfHash }) {
		#print "$schemaRow\n";
		if ($schemaRow eq 'whole_db_RNRNRN'){
			my $distinctIPs = $perfHash->{$schemaRow}->{'count_of_distinct_ips'};
			my $distinctUsers = $perfHash->{$schemaRow}->{'distinctUserConns'};
			$counterInsert.="($dboid,$qtime,'whole_instance_counter',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,$distinctIPs,$distinctUsers),";
		} else{
			# must handle the default values for when a counter is not defined, because of batch string insert
			my $numConns = $perfHash->{$schemaRow}->{'numConns'}; # this could be undefined if there was a connected schema for the "distinct users" query but not the main one.
				$numConns = 0 unless defined($numConns);
			my $numRunning = $perfHash->{$schemaRow}->{'numRunning'};
				$numRunning = 0 unless defined($numRunning);
			my $avRunTime = $perfHash->{$schemaRow}->{'avRunTime'};
				$avRunTime = 'NULL' unless defined($avRunTime);
			my $maxRunTime = $perfHash->{$schemaRow}->{'maxRunTime'};
				$maxRunTime = 'NULL' unless defined($maxRunTime);
			my $minRunTime = $perfHash->{$schemaRow}->{'minRunTime'};
				$minRunTime = 'NULL' unless defined($minRunTime);
			my $numSleeping = $perfHash->{$schemaRow}->{'numSleeping'};
				$numSleeping = 0 unless defined($numSleeping);
			my $avSleepTime = $perfHash->{$schemaRow}->{'avSleepTime'};
				$avSleepTime = 'NULL' unless defined($avSleepTime);
			my $maxSleepTime = $perfHash->{$schemaRow}->{'maxSleepTime'};
				$maxSleepTime = 'NULL' unless defined($maxSleepTime);
			my $minSleepTime = $perfHash->{$schemaRow}->{'minSleepTime'};
				$minSleepTime = 'NULL' unless defined($minSleepTime);
			my $distinctIPs = $perfHash->{$schemaRow}->{'countDistinctIPs'}; # similarly, this could be undef in the case of a difference between the two queries
				$distinctIPs = 0 unless defined($distinctIPs);
			my $distinctUsers = $perfHash->{$schemaRow}->{'distinctUserConns'};
				$distinctUsers = 'NULL' unless defined($distinctIPs);
			$counterInsert.="($dboid,$qtime,'$schemaRow',$numConns,$numRunning,$avRunTime,$maxRunTime,$minRunTime,$numSleeping,$avSleepTime,$maxSleepTime,$minSleepTime,$distinctIPs,$distinctUsers),";
		}
		if (length($counterInsert) > 10000000) {
			chop($counterInsert);
			$mysql->do($counterInsert);
			$counterInsert = "insert into db_perf_counters (dboid, scantime, db, numConns, numRunning, avRunTime, maxRunTime, minRunTime, numSleeping, avSleepTime, maxSleepTime, minSleepTime, distinctIPs, distinctUsers) values ";
		}
	}
	#print "$counterInsert\n";
	unless ($counterInsert eq "insert into db_perf_counters (dboid, scantime, db, numConns, numRunning, avRunTime, maxRunTime, minRunTime, numSleeping, avSleepTime, maxSleepTime, minSleepTime, distinctIPs, distinctUsers) values "){
		chop($counterInsert);
		$mysql->do($counterInsert);
	}
}
