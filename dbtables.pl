#!/usr/bin/perl
use Data::Dumper;
use DBI();
use warnings;
use Socket;
use Time::Local;
use lib 'lib'; # ?
use RISC::riscUtility;
use RISC::Collect::Audit;
$|++;

# CALL SYNTAX: ./dbuseprobe.pl [dbtype] [host-or-ip] [user] [password] [port] [sid_if_oracle]

# This script should be called about once a day or so. It will record the all the tables in the database,
# including information about their size and affiliated schemas. Note: for MySQL, MS SQL and Oracle the fields
# primary_schema and secondary_schema mean different things. In MySQL secondary schema is always "def". In MS SQL
# secondary_schema refers to definable secondary schema, while primary_schema is the database referred to when
# you type "use databasename". In Oracle, primary_schema is the owner of the table, which is the oracle equivalent
# of a primary schema. Secondary schemas are configurable in oracle but I'm not sure if anyone uses them.

my $mysql = riscUtility::getDBH('RISC_Discovery',1);

# mebbe I will hand in dboid instead of credid, remains to be seen. OR BOTH WOW WHAT A WORLD WE LIVE IN
my $dboid = shift;
my $credid = shift;

my $credobj = riscCreds->new();
my $creddata = $credobj->getDB($credid);
our $dbtype = $creddata->{'type'};
my $serverip = $creddata->{'target'};
my $cport = $creddata->{'port'};
my $username = $creddata->{'username'};
my $pw = $creddata->{'password'};
my $orsid = $creddata->{'orsid'} if $dbtype eq 'oracle';

# Make and prepare the insert string for the somewhat normalized data
my $outstr = "INSERT INTO db_tables SET
 	dboid = ?,
	scantime = ?,
	schema_primary = ?,
	schema_secondary = ?,
	table_name = ?,
	engine = ?,
	version = ?,
	row_format = ?,
	num_rows = ?,
	data_kb = ?,
	index_kb = ?,
	created = ?,
	updated = ?,
	analyzed = ?
";
my $outsth = $mysql->prepare($outstr);
# clear mysql of strict_trans_tables so that long sql queries won't break the insert (will just truncate)
$mysql->do("SET SESSION sql_mode='';");

my $qtime = time();
my $i = 0;
#print "$dbtype$credid--$qtime\n";

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

	my $query = $dbh->prepare("SELECT *, unix_timestamp(create_time) ct, unix_timestamp(update_time) ut, unix_timestamp(check_time) cht FROM INFORMATION_SCHEMA.TABLES");
	$query->execute;
	audit(%audit, timestamp => time(), type => 'query', resource => $query->{Statement}, status => 0);
	while(my $row = $query->fetchrow_hashref){
		$i++;
		#print Dumper($row);

		# store create_time, update_time, check_time as unixtime

		# dboid scantime schema_primary schema_secondary table_name engine version row_format num_rows data_kb index_kb created updated analyzed
		$outsth->execute($dboid,$qtime,$row->{'TABLE_SCHEMA'},$row->{'TABLE_CATALOG'},$row->{'TABLE_NAME'},$row->{'ENGINE'},$row->{'VERSION'},$row->{'ROW_FORMAT'},$row->{'TABLE_ROWS'}, $row->{'DATA_LENGTH'}/1024,$row->{'INDEX_LENGTH'}/1024,$row->{'ct'},$row->{'ut'},$row->{'cht'});
		# note that update_ and check_time tend to be null for innodb
	}


}elsif($dbtype eq "mssql"){
	my $dsn = "DBI\:Sybase\:server=$serverip\:$cport";
	my $dbh = DBI->connect($dsn, $username, $pw) or do {
		audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
		die("unable to connect to server $DBI::errstr");
	};
	audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);

	# for mssql, we have to query each schema separately t(-.-t)
	# start by getting the list of schemas:
	my $schemasquery = $dbh->prepare("SELECT name FROM sys.databases");
	$schemasquery->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $schemasquery->{Statement}, status => 0);
	#$dbh->do("use master");
	my @schemarray;
	while(my $sch = $schemasquery->fetchrow_hashref){
		push @schemarray, $sch->{'name'};
	}
	#print Dumper(@schemarray);
	$schemasquery->finish;

	while(my $schema = shift(@schemarray)){
		my $tq = "select
			t.name as tableName,
			s.name as secondarySchema,
			datediff(s, '1970-01-01 00:00:00', max(t.create_date)) as createDate,
			datediff(s, '1970-01-01 00:00:00', max(t.modify_date)) as updateDate,
			max(p.rows) as RowCounts,
			sum(a.total_pages*8) as totalSpaceKB,
			sum(a.used_pages*8) as usedSpaceKB,
			sum(case when i.index_id < 2 then a.data_pages*8 else 0 end) as dataSpaceKB,
			sum(a.used_pages*8)-sum(case when i.index_id < 2 then a.data_pages*8 else 0 end) as indexSpaceKB
		from $schema.sys.tables t
			inner join $schema.sys.indexes i on t.object_id = i.object_id
			inner join $schema.sys.partitions p on i.object_id = p.object_id and i.index_id = p.index_id
			inner join $schema.sys.allocation_units a on p.partition_id = a.container_id
			inner join $schema.sys.schemas s on t.schema_id=s.schema_id
		group by t.name,s.name;";

		my $tables = $dbh->prepare($tq);
		$tables->execute() or next;
		audit(%audit, timestamp => time(), type => 'query', resource => $tables->{Statement}, status => 0);
		while(my $table = $tables->fetchrow_hashref){
			# dboid scantime schema_primary schema_secondary table_name engine version row_format num_rows data_kb index_kb created updated analyzed
			$outsth->execute($dboid, $qtime, $schema, $table->{'secondarySchema'},$table->{'tableName'},'MS SQL Server','','',$table->{'RowCounts'},$table->{'usedSpaceKB'},$table->{'indexSpaceKB'},$table->{'createDate'},$table->{'updateDate'},'');
		}
	}

}elsif($dbtype eq "oracle"){
	eval{system('bash /srv/httpd/htdocs/shell/hosts_update.sh');};
	my $dbstr = "dbi:Oracle:host=$serverip;port=$cport;sid=$orsid";
	my $dbh = DBI->connect($dbstr, $username, $pw,{LongTruncOk => 1}) or do {
		audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 1);
		die("Couldn't connect, Oracle edition.\n");
	};
	audit(%audit, timestamp => time(), type => 'connect', resource => 'auth', status => 0);

	my $rowsq = "select
		table_name, owner, sum(decode(type,'table',bytes))/1024 tableKB,
		sum(decode(type,'index',bytes))/1024 indexKB, sum(decode(type,'lob',bytes))/1024 lobKB,
		sum(bytes)/1024 totalKB, sum(num_rows) numRows, max(last_anal) last_anal,
		max(created) created, max(updated) updated, max(tbs) tablespace,
		sum(decode(type,'table',bytes,'lob',bytes))/1024 totalDataKB,
		sum(decode(type,'index',bytes,'lobidx',bytes))/1024 totalIdxKB
	from (
		select t.table_name table_name, 'table' type, t.owner, s.bytes, t.num_rows,
			t.last_analyzed last_anal, o.created created, o.last_ddl_time updated, t.tablespace_name tbs
		from dba_tables t left join dba_segments s
			on s.segment_name=t.table_name and s.owner=t.owner
			left join dba_objects o on t.table_name=o.object_name and t.owner=o.owner
		where s.segment_type in ('TABLE','TABLE PARTITION','TABLE SUBPARTITION') or s.segment_type is null
		union all select i.table_name table_name, 'index' type, i.owner, s.bytes, 0 num_rows,
			null last_anal, null created, null updated, null tbs
		from dba_segments s inner join dba_indexes i
			on i.index_name = s.segment_name and s.owner = i.owner
		where s.segment_type in ('INDEX','INDEX PARTITION','INDEX SUBPARTITION')
		union all select l.table_name, 'lob' type, l.owner, s.bytes, 0 num_rows, null last_anal,
			null created, null updated, null tbs
		from dba_lobs l inner join dba_segments s on l.segment_name = s.segment_name and l.owner = s.owner
		where s.segment_type in ('LOBSEGMENT','LOB PARTITION')
		union all select l.table_name, 'lobidx' type, l.owner, s.bytes, 0 num_rows, null last_anal,
			null created, null updated, null tbs
		from dba_lobs l inner join dba_segments s on l.index_name = s.segment_name and s.owner = l.owner
		where s.segment_type = 'LOBINDEX' )
	group by table_name, owner";
#where owner not in ('SYS','SYSTEM','XDB','CTXSYS')
	my $query = $dbh->prepare($rowsq);
	$query->execute();
	audit(%audit, timestamp => time(), type => 'query', resource => $query->{Statement}, status => 0);

	my $numresults = 0;
	my $uptodate = 0;
	my $anal_gap = 7*24*3600; #for housekeeping, we will keep track of how many were analyzed in the last week
	while (my $row = $query->fetchrow_hashref){
		#print Dumper($row);
		my $unixCreated = oraToUnixDate($row->{'CREATED'});
		my $unixUpdated = oraToUnixDate($row->{'UPDATED'});
		my $uLastAnal = oraToUnixDate($row->{'LAST_ANAL'});
		my $rowFormat = 'no lob';
		$rowFormat = 'lob' if $row->{'LOBKB'};
		$numresults++;
		$uptodate++ if defined($uLastAnal)&&($qtime-$uLastAnal)<$anal_gap;
		# dboid scantime schema_primary schema_secondary table_name engine version row_format num_rows data_kb index_kb created updated analyzed
		$outsth->execute($dboid, $qtime, $row->{'OWNER'}, $row->{'TABLESPACE'},$row->{'TABLE_NAME'},'OracleDB','',$rowFormat,$row->{'NUMROWS'},$row->{'TOTALDATAKB'},$row->{'TOTALIDXKB'},$unixCreated,$unixUpdated,$uLastAnal);
	}
}




sub oraToUnixDate{
	return if !defined($_[0]);
	# this takes the oracle date string, and makes it into a unix time. the time of day is set to be 00:00:00
	my ($day, $mon, $yr) = split('-',shift);
	my $mon_num = 0;
	my @mon_arr = ("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC");
	# ^ slightly inefficient as I'm defining this array each time the function is called.
	++$mon_num until $mon_arr[$mon_num] eq $mon;
	$udate = timegm(0, 0, 0, $day, $mon_num, $yr);
	return $udate;
}
