#!/usr/bin/perl -w
use DBI();
use SOAP::Lite;
use XMLRPC::Lite;
use XML::Simple;
use CCMDeserial;
use XML::Simple;
use Data::Dumper;
use MIME::Base64;
use RISC::riscUtility;
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'Net::SSL';
eval {
$xml = XML::Simple
	->new()
;
$clusterdb=shift;
$clusterdb = '' unless defined $clusterdb;
die if (checkDupProcess($clusterdb)>1);
$clusterdb='RISC_Discovery' if $clusterdb eq '';


my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);
my $mysql3 = riscUtility::getDBH($clusterdb,1);

#Get Devices
$sth1 = $mysql->prepare_cached("INSERT INTO ccm (ipaddress,class,counter,value,scantime,instance) VALUES (?,?,?,?,?,?)");
$ccmdevices = "select distinct(RISC_Discovery.riscdevice.ipaddress) as ipaddress,credentialid,version from processnode
				inner join componentversion on processnode.pkid=componentversion.fkprocessnode
				inner join ccmmap on processnode.name=ccmmap.processnode
				inner join RISC_Discovery.riscdevice on ccmmap.deviceid=RISC_Discovery.riscdevice.deviceid
				inner join RISC_Discovery.credentials on RISC_Discovery.riscdevice.deviceid=RISC_Discovery.credentials.deviceid
				where name not regexp 'enterprise' and (softwarecomponent='ccm.exe' or softwarecomponent='cm-ccm' or softwarecomponent = 'cm-ver') and technology='ccm'";
$sth4 = $mysql3->prepare($ccmdevices);
$sth4->execute();

## polling interval
my $numdevices = $sth4->rows();
my $perftime = time();
eval {
	if ($numdevices > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($perftime,'ccmperf',$numdevices)");
	}
};

while (my $callmanager= $sth4->fetchrow_hashref()){
	my $ip = $callmanager->{'ipaddress'};
	my $credid=$callmanager->{'credentialid'};
	my $version=$callmanager->{'version'};
	my $getcreds;
	if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
		$getcreds = $mysql2->prepare_cached("select * from credentials where credid=?");
	} else {
		$getcreds = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
												cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
												cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
												cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
												port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
												scantime,eu,ap,removed
											from credentials where credid = ?");
	}

	$getcreds->execute($credid);
	my $getcredsresult=$getcreds->fetchrow_hashref();
		#print Dumper($getcredsresult);
	my $username=decode_base64($getcredsresult->{'username'});
	my $password=decode_base64($getcredsresult->{'passphrase'});
	sub SOAP::Transport::HTTP::Client::get_basic_credentials {return $username => $password}; 
	my $INFO = SOAP::Data
		->name('HOST')
		->value($ip);
	if ($version =~ m/^4./ || $version =~ m/^3./) {
			$counterlist="Cisco CallManager-Cisco Hunt Lists-Cisco H323-Cisco CallManager System Performance-Cisco MGCP Gateways-Cisco MOH Device-Cisco Locations-Cisco MTP Device-Cisco Transcode Device-Cisco SW Conference Bridge Device-Cisco HW Conference Bridge Device-Cisco CTI Manager-Memory-Processor-System";
			@counterArray=split('-',$counterlist);
			$ACTION = "\"http://schemas.cisco.com/ast/soap/action/#PerfmonPort#PerfmonCollectCounterData\"";
			$proxy="http://$ip/soap/astsvc.dll";
			$uri='http://schemas.cisco.com/ast/soap/';	
		} else {
			$counterlist="Cisco CallManager-Cisco Hunt Lists-Cisco H323-Cisco CallManager System Performance-Cisco MGCP Gateways-Cisco MOH Device-Cisco Locations-Cisco MTP Device-Cisco Transcode Device-Cisco SW Conference Bridge Device-Cisco HW Conference Bridge Device-Cisco CTI Manager-Memory-Processor-System";
			@counterArray=split('-',$counterlist);
			$uri='http://schemas.cisco.com/ast/soap/action/#perfmonCollectCounterData#PerfmonCollectCounterData';
			$proxy="https://$ip:8443/perfmonservice/services/PerfmonPort";
			#my $service = SOAP::Lite->service("https://$ip:8443/perfmonservice/services/PerfmonPort?wsdl");
			my $soapList = SOAP::Lite
                    ->proxy($proxy)
                    ->uri($uri)
                    ->deserializer(CCMDeserial->new())
                    ->on_action(sub{return $ACTION if defined $ACTION;});
            my $counterlistresult = $soapList->PerfmonListCounter($ip);
            $counterlistresult = $xml->XMLin($counterlistresult);
            foreach $t (@{$counterlistresult->{'soapenv:Body'}->{'ns1:PerfmonListCounterResponse'}->{'ArrayOfObjectInfo'}->{'item'}}){
            	print "Counter Name is: $t->{'Name'}->{'content'}\n";
            	push(@counterArray,$t->{'Name'}->{'content'});
            }
		}
		my $soap= SOAP::Lite
			->proxy($proxy)
			->uri($uri)
			->deserializer(CCMDeserial->new())
			->on_action(sub{return $ACTION if defined $ACTION;});
		
		foreach my $ccmcount2 (@counterArray){
			print "Getting stats for $ccmcount2\n";
			my $INFO2 = SOAP::Data->name('Object')->attr({xmlns=>'http://schemas.xmlsoap.org/soap/emore nvelope/'})->value($ccmcount2)->type('xsd:ObjectNameType');
			my $scantime2 = time;
			my $response = $soap->PerfmonCollectCounterData($INFO,$INFO2);
			# Removed by JL on 10/14/2013 as it prevented Cisco CallManager stats coming in # next if $response =~ /Error/ig;
			$data = $xml->XMLin($response);
			processResults($data,$ccmcount2,$scantime2,$ip,$version);
		}
}

$sth1->finish();
$mysql->disconnect();
}; if ($@) {print "ERROR:$@\n";}
sub processResults{
my $data=shift;
my $ccmcount=shift;
my $scantime=shift;
my $host=shift;
my $version=shift;
eval {
if ($version =~ m/^4./ || $version =~ m/^3./ ) {
	foreach $t (@{$data->{'SOAP-ENV:Body'}->{'m:PerfmonCollectCounterDataResponse'}->{'ArrayOfCounterInfo'}->{'CounterInfo'}}) {
	my $counterName=$t->{Name};
	my $counterValue=$t->{Value};
	my $counterInstance=$counterName;
	if ($counterName=~m/.*\(.*\)/) {
			$counterInstance=~s/.*\((.*)\).*/$1/;
		}else{$counterInstance="none";}
	$counterName=~ s/\\\\$host\\.*\\//;
	print $counterName;
	print $counterInstance;
	#print "\"";	
	print ":";
	#print "\"";
	print $counterValue;
	#print "$t->{Value}->{content}";
	print "\n";
	$sth1->execute($host,$ccmcount,$counterName,$counterValue,$scantime,$counterInstance);
}
} else {
foreach $t (@{$data->{'soapenv:Body'}->{'ns1:PerfmonCollectCounterDataResponse'}->{ArrayOfCounterInfo}->{item}}) {
	my $counterName=$t->{Name}->{content};
	my $counterValue=$t->{Value}->{content};
	my $counterInstance=$counterName;
	if ($counterName=~m/.*\(.*\)/) {
			$counterInstance=~s/.*\((.*)\).*/$1/;
		}else{$counterInstance="none";}
	$counterName=~ s/\\\\$host\\.*\\//;
	print $counterName;
	print $counterInstance;
	print ":";
	print $counterValue;
	print "\n";
	$sth1->execute($host,$ccmcount,$counterName,$counterValue,$scantime,$counterInstance);
}
}
}; if ($@) {print "ERROR RUNNING PARSE: $@\n";}

};

sub checkDupProcess {
	my $clusterdb = shift;
	$clusterdb = ' '.$clusterdb unless $clusterdb eq '';
	my @proclist = `pgrep -f '$0$clusterdb'`;
	return 0 unless @proclist;
	my $result = scalar(@proclist);
	return $result;
}
