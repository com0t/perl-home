#!/usr/bin/perl -w
use XML::Simple;
use SOAP::Lite +trace=>"debug";
use XMLRPC::Lite;
use CCMDeserial;
use Data::Dumper;
use Socket;
use MIME::Base64;
use RISC::riscUtility;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';

## define supported AXL versions and the order in which we try them
my @axlver = ('8.0','9.0');
my $num_axlvers = @axlver;

my $mysql2 = riscUtility::getDBH('risc_discovery',1);
$mysql2->{mysql_auto_reconnect} = 1;

my $credentiallookup;
if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$credentiallookup = $mysql2->prepare_cached("select * from credentials where technology='cm' and removed=0 order by credid");
} else {
	$credentiallookup = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
											cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
											cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
											cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
											port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
											scantime,eu,ap,removed
										from credentials where technology='cm' and removed=0 order by credid");
}

my $soap;

$credentiallookup->execute();
my $cmcluster = 0;
while (my $cmid = $credentiallookup->fetchrow_hashref()) {
	$credid = $cmid->{'credid'};
	$ccmIP = decode_base64($cmid->{'domain'});
	$ccmUser = decode_base64($cmid->{'username'});
	$ccmPass = decode_base64($cmid->{'passphrase'});

	if ($cmcluster==0){
		$dbname='RISC_Discovery';
	} else {
		$dbname="RISC_Discovery_$cmcluster";
	}

	#added to prevent dups
	eval {
		my $dbCheck = $mysql2->prepare("show table status from $dbname like 'processnode'");
		$dbCheck->execute();
		if ($dbCheck->rows() > 0) {
			$cmcluster++;
			next;
		}
	};

	my $createschema = "mysql -e 'create schema if not exists $dbname'";
	system($createschema);

	#Define WSDL URLs 
	#AXL service WSDL:
	my $axlwsdl = "https://$ccmIP:8443/axl\?wsdl";
	#Perfmon service WSDL:
	my $perfmonwsdl = "https://$ccmIP:8443/perfmonservice/services/PerfmonPort\?wsdl";
	#Real-time information service WSDL:
	my $risportwsdl = "https://$ccmIP:8443/realtimeservice/services/RisPort\?wsdl";
	#Log collection service WSDL:
	my $logwsdl = "https://$ccmIP:8443/logcollectionservice/services/LogCollectionPort\?wsdl";
	# DIME get file service WSDL:
	my $dimewsdl = "https://$ccmIP:8443/logcollectionservice/services/DimeGetFileService\?wsdl";
	#Control Center services WSDL:
	my $controlcenterwsdl = "https://$ccmIP:8443/controlcenterservice/services/ControlCenterServicesPort\?wsdl";
	#SOAP Monitor WSDL:
	my $soapmonitorwsdl = "https://$ccmIP:8443/realtimeservice/services/SOAPMonitorService\?wsdl";
	#CDR on demand WSDL:
	my $cdrwsdl = "https://$ccmIP:8443/CDRonDemandService/services/CDRonDemand\?wsdl";
	##########################
	##########################
	$SQLQueryMethod = SOAP::Data->name('axl:executeSQLQuery')->attr({
							#xmlns=>'http://www.cisco.com/AXL/API/8.0', 
							sequence=>1,
							#'xmlns:axlapi'=>"http://www.cisco.com/AXL/API/8.0",
							#'xmlns:axl'=>"http://www.cisco.com/AXL/API/8.0",
							#'xmlns:xsi'=>"http://www.w3.org/2001/XMLSchema-instance",
							#'xsi:schemaLocation'=>"http://www.cisco.com/AXL/API/8.0 axlsoap.xsd"
							});
	
	my $tables;

	## loop through supported AXL versions if we have an error
	my $ver = 0;
	while ($ver < $num_axlvers) {
		eval {
			#Create the CUCM Connection
			$ACTION = "\"UCM:DB ver=$axlver[$ver]\"";

			$soap = SOAP::Lite
				->proxy("https://$ccmIP/axl/")
				#->proxy("http://$host/soap/astsvc.dll")
				#->uri('http://schemas.cisco.com/ast/soap/action/#perfmonCollectCounterData#PerfmonCollectCounterData')
				#->uri('http://schemas.cisco.com/ast/soap/action/#PerfmonPort')
				#->uri('http://schemas.cisco.com/ast/soap/')
				->ns('http://www.cisco.com/AXL/API/'.$axlver[$ver],'axl')
				->uri('http://www.cisco.com/AXL/API/'.$axlver[$ver])
				->on_action(sub { return $ACTION; } )
				#->readable(1)
				#->deserializer(CCMDeserial->new())
				#->service($)
			;
			sub SOAP::Transport::HTTP::Client::get_basic_credentials {return $ccmUser => $ccmPass};

			#Step 1, get the list of tables in the CUCM DB
			$tables = getTableList();

		}; if ($@ or !ref($tables)) {
			if ($tables == 599) {
				print "wrong AXL version -- trying next\n";
				$ver++;
				next;
			} elsif ($tables == 401) {
				print "authentication error\n";
				undef $tables;
				last;
			} else {
				print "unknown error\n";
				undef $tables;
				last;
			}
		} else {
			last;
		}
	}

	if (!defined($tables)) {
		print "failed to pull table list\n";
		next; ## try next cluster
	}

	#Step 2, create and populate the tables in our DB based on columns from CUCM
	foreach my $table (@$tables) {
		next if $table->{'tabname'}=~/.*cdr.*/; #Skip if the table is a CDR table.
		next if $table->{'tabid'}<99; #Skip if the tableid is less than 99 - an Informix system table
		print "Working on table $table->{'tabname'}\n";
		createTable ($dbname,$table);
	}

	$cmcluster++;
	sleep (120);
	createCCMDevIDandGetRealtimeInfo($dbname,$ccmIP);
}

## subroutines-->

sub getTableList {
	
	my $INFO = SOAP::Data
		->name('sql')
		->attr({'xsi:type'=>undef})
		#->value("select tabid,tabname from systables where tabid>99");
		->value("select tabid,tabname from systables");
		#->value("select t.tabname, c.colname from systables as t inner join syscolumns as c on c.tabid=t.tabid order by t.tabname");
		#->value("select * from $ccmcount");
	my $response = $soap->call($SQLQueryMethod=>$INFO);
	
	## check for an error
	my $err = $soap->transport->status;
	if ($err =~ /599/) {
		## wrong AXL version
		return 599;
	} elsif ($err =~ /401/) {
		## authentication error
		return 401;
	}

	my $r1 = $response->result->{'row'};
	#print Dumper($r1);
	foreach my $table (@{$r1}) {
		#print "$table->{'tabname'}\n";
		push (@tableList,$table);
	}
	return \@tableList;
}

sub createTable {
	my $dbname = shift;
	my $tablename = shift;
	my $INFO = SOAP::Data
        ->name('sql')
        ->attr({'xsi:type'=>undef})
        ->value("select colname from syscolumns where tabid=$tablename->{'tabid'}");
	my $response = $soap->call($SQLQueryMethod=>$INFO)->result()->{'row'};
	#Loop over keys to get column names
	#First create the main create statement
	my $createStatement = "Create Table \`$tablename->{'tabname'}\` (";
	#For each key, append it to the table create statement
	my $colcount=0;
	my $colinsert;
	if (ref($response) eq 'ARRAY') {
		foreach my $column (@{$response}) {
			$createStatement=$createStatement."$column->{'colname'} varchar(255),";
		}
	} else {
		$createStatement=$createStatement."$response->{'colname'} varchar(255),";
	}
	chop($createStatement);
	$createStatement=$createStatement.")";
	print "Going to run $createStatement\n";
	#Create the DB Connection
	my $mysql = riscUtility::getDBH($dbname,0);
	$mysql->do("drop table if exists \`$tablename->{'tabname'}\`");
	$mysql->do($createStatement);
	#Now do the data population
	my $INFO2 = SOAP::Data
		->name('sql')
		->value("select * from $tablename->{'tabname'}");

	#Check for an error in the soap call
	my $response2 = $soap->call($SQLQueryMethod=>$INFO2);
	if ($response2->fault() && $response2->faultstring() =~ /too\ large/i) {
		my $INFO3 = SOAP::Data->name('sql')->value("select count(*) from $tablename->{'tabname'}");
		my $response3 = $soap->call($SQLQueryMethod=>$INFO3);
		my $rowcount = $response3->result()->{'row'}->{'count'};
		my $iterations = ($rowcount/500)+1;
		for (my $loops=0; $loops < $iterations; $loops++) {
			sleep 10;
			my $startRow = $loops*500;
			my $INFO4 = SOAP::Data->name('sql')->value("select skip $startRow limit 500 * from $tablename->{'tabname'} order by rowid");
			my $newResponse = $soap->call($SQLQueryMethod=>$INFO4)->result()->{'row'};
			foreach my $insertRow (@{$newResponse}) {
				my $insertStatement = "Insert into \`$tablename->{'tabname'}\` set ";
				foreach my $columnkey (keys %$insertRow) {
					$insertStatement=$insertStatement."$columnkey=\'$insertRow->{$columnkey}\'," if $insertRow->{$columnkey};
				}
				chop($insertStatement);
				print "RUnning: $insertStatement\n";
				$mysql->do($insertStatement);
			}
		}
	} elsif ($response2->fault()) {
		return;
	} else {
		my $resultLoop = $response2->result()->{'row'};
		return unless $resultLoop;
		if (ref($resultLoop) eq 'ARRAY') {
			foreach my $insertRow (@{$resultLoop}) {
				my $insertStatement = "Insert into \`$tablename->{'tabname'}\` set ";
				foreach my $columnkey (keys %$insertRow) {
					$insertStatement=$insertStatement."$columnkey=\'$insertRow->{$columnkey}\'," if $insertRow->{$columnkey};
				}
				chop($insertStatement);
				print "RUnning: $insertStatement\n";
				$mysql->do($insertStatement);
			}
		} else {
			my $insertStatement = "Insert into \`$tablename->{'tabname'}\` set ";
			foreach my $columnkey (keys %$resultLoop) {
				$insertStatement=$insertStatement."$columnkey=\'$resultLoop->{$columnkey}\'," if $resultLoop->{$columnkey};
			}
			chop($insertStatement);
			print "RUnning: $insertStatement\n";
			$mysql->do($insertStatement);
		}
	}
}

sub createCCMDevIDandGetRealtimeInfo {
	eval {
		#Now, put in deviceids with credentials for each server.
		#This query creates the deviceid to put into the credentials table to match back up later.  It checks to make sure it isn't already there for multi cluster environments
		#Also, it puts the CUCM into riscdevice if it isn't there - and updates the IP
		my $dbname=shift;
		my $ipaddress1 = shift;

		my $mysql = riscUtility::getDBH($dbname,0);
		$mysql->{mysql_auto_reconnect} = 1;

		my $ccmdevcreate = $mysql->prepare("select name,version from processnode inner join componentversion on processnode.pkid=componentversion.fkprocessnode where processnode.name not regexp 'enterprise' and (softwarecomponent='ccm.exe' or softwarecomponent='cm-ccm' or softwarecomponent='cm-ver')");
		$ccmdevcreate->execute();
		my $ccmtest = $mysql->prepare("select * from riscdevice where ipaddress=?");
		my $ccmnameupdate = $mysql->prepare("update processnode set name=? where name=?");	## if we have hostnames instead of IPs, update the records to the IP
		my $ccmnodeinsert = $mysql->prepare("insert into ccmmap (deviceid,processnode) values (?,?)");
		my $ccmcredinsert = $mysql->prepare("insert into credentials (deviceid,credentialid,technology,uniqueid) values (?,?,'ccm',?)");
		while (my $ccmdev = $ccmdevcreate->fetchrow_hashref()){
			#Test to see if it is an ipaddress or name...
			my $ccmname=$ccmdev->{'name'};
			my $ccmversion=$ccmdev->{'version'};
			
			if ($ccmname =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\$/) {
				system("/usr/bin/perl /home/risc/disco.pl $assessmentid $ccmname");
				sleep 300;
				$ccmtest->execute($ccmname);
				my $devid=$ccmtest->fetchrow_hashref()->{'deviceid'};
				$ccmnodeinsert->execute($devid,$ccmname,$version);
				$ccmcredinsert->execute($devid,$credid,$devid."-ccm");
				getRealTime($ccmname);
			} else {
				$ipaddr=$ipaddress1;
				my $host = gethostbyname($ccmname);
				if (defined $host) {
					$ipaddr=join('.',unpack('C4',$host));
					$ccmnameupdate->execute($ipaddr,$ccmname);
				} else {
					$ipaddr=$ipaddress1;
				}
				my $scanip = $ipaddr."/32";
				system("/usr/bin/perl /home/risc/disco.pl $assessmentid $scanip");
				sleep 300;
				$ccmtest->execute($ipaddr);
				my $devid = $ccmtest->fetchrow_hashref()->{'deviceid'};
				$ccmnodeinsert->execute($devid,$ccmname,$version);
				$ccmcredinsert->execute($devid,$credid,$devid."-ccm");
				getRealTime($ipaddr);
			}
		}
	}; if ($@) {
		print "Error creating deviceid : $@\n";
	}
}

sub getRealTime {
	my $ACTION2 = "http://schemas.cisco.com/ast/soap/action/#RisPort#SelectCmDevice";
		$soap= SOAP::Lite
		->proxy("https://$ccmIP:8443/realtimeservice/services/RisPort")
		#->proxy("http://$host/soap/astsvc.dll")
		#->uri('http://schemas.cisco.com/ast/soap/action/#perfmonCollectCounterData#PerfmonCollectCounterData')
		#->uri('http://schemas.cisco.com/ast/soap/action/#PerfmonPort')
		->uri('http://schemas.cisco.com/ast/soap/')
		->on_action(sub { return $ACTION2; } )
		#->readable(1)
		->deserializer(CCMDeserial->new())
	;
	#sub SOAP::Transport::HTTP::Client::get_basic_credentials {return $ccmUser => $ccmPass};
	#Get all the devices to run against
	my $mysql = riscUtility::getDBH($dbname,0);

	my $devicelist = $mysql->prepare("select * from device");
	$devicelist->execute();
	#Create the major SOAP elements at this level
	my $header1 =  SOAP::Header
		->name('SessionId')
		->value('')
		->type('xsd:unsignedInt');
	my $class =  SOAP::Data
		->name('Class')
		->value('Any');
	my $model =  SOAP::Data
		->name('Model')
		->value(255)
		->type('xsd:unsignedInt');
	my $status =  SOAP::Data
		->name('Status')
		->value('Any');
	my $nodename =  SOAP::Data
		->name('NodeName')
		->value('');
	my $selectby =  SOAP::Data
		->name('SelectBy')
		->value('Name');
	my $maxReturnedDevices =  SOAP::Data
		->name('MaxReturnedDevices')
		->value(200)
		->type('xsd:unsignedInt');
	my $StateInfo = SOAP::Data
		->name('StateInfo')
		->value('');

	my $counterLoop=0;
	my $totalloops=$devicelist->rows();
	my $totalLoop=1;
	while (my $device = $devicelist->fetchrow_hashref()){
		if ($counterLoop==200 || $totalLoop==$totalloops){
			my $item1 =  SOAP::Data
				->name('item')
				->value($device->{'name'});
			push (@itemArray,$item1);
			my $selectitems =  SOAP::Data
				->name('SelectItems')
				->value(@itemArray);
			my $selectitems2 = SOAP::Data
				->name('SelectItems')
				->value(\$selectitems);
			my $CmSelectionCriteria = SOAP::Data
				->name('CmSelectionCriteria')
				->value($maxReturnedDevices,$class,$model,$status,$nodename,$selectby,$selectitems2);
			my $CmSelectionCriteria1 = SOAP::Data
				->name('CmSelectionCriteria')
				->value(\$CmSelectionCriteria);
			my $response= $soap->SelectCmDevice($StateInfo,$CmSelectionCriteria1);
			$xml = XML::Simple
				->new();
			$data = $xml->XMLin($response);
			processData($data);
			@itemArray=[];
			$counterLoop=0;
			$totalLoop++;
		}
		my $item1 =  SOAP::Data
			->name('item')
			->value($device->{'name'});
		push (@itemArray,$item1);
		$counterLoop++;
		$totalLoop++;
	}
}

sub processData {
	my $data=shift;
	print Dumper($data);
}
