#!c:\perl\bin\perl -w
#################
#####Usage
#####perl win-event.pl USERNAME PASSWORD DATE
#####Date format should be yyyymmdd  So, June 20, 2009 is 20090620
#########
##########
use DBI();
#use Win32::OLE qw( in );
#use Win32::OLE::Variant;
use XML::Simple;
use Net::FTP;
use Data::Dumper;
use RISC::riscWindows;
use RISC::riscUtility;
#use constant HKEY_LOCAL_MACHINE => 0x80000002;
#use constant wbemFlagReturnImmediately => 0x10;
#use constant wbemFlagForwardOnly => 0x20;
#use Win32::NetResource qw/GetUNCName AddConnection CancelConnection/;
#use Win32API::File qw/ CopyFile MoveFileEx fileLastError /;

my $mysql = riscUtility::getDBH('RISC_Discovery',1);
my $mysql2 = riscUtility::getDBH('risc_discovery',1);

$winsth = $mysql->prepare_cached("select windowsos.deviceid,riscdevice.ipaddress,credentials.credentialid from `RISC_Discovery`.`windowsos` inner join riscdevice on windowsos.deviceid=riscdevice.deviceid inner join credentials on riscdevice.deviceid=credentials.deviceid where windowsos.caption regexp 'server' and riscdevice.deviceid not in (select deviceid from windowseventlog)");
$winsth14 = $mysql->prepare_cached("INSERT INTO windowseventlog (deviceid,category,categorystring,computername,eventcode,eventid,eventtype,logfile,message,recordnumber,sourcename,timegenerated,timewritten,type,user) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $getcred;
if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$getcred = $mysql2->prepare_cached("select * from credentials where credid=? limit 1");
} else {
	$getcred = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
											cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
											cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
											cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
											port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
											scantime,eu,ap,removed
										from credentials where credid = ? limit 1");
}

my $startdate = $ARGV[2].'000000.000000-300';
$winsth->execute();
$numberrows = $winsth->rows;

my $scantime = time();

## polling interval
eval {
	if ($numberrows > 0) {
		$mysql->do("INSERT INTO pollinginterval (scantime,perftype,numdevices) VALUES ($scantime,'win-event',$numberrows)");
		print "win-event: running against $numberrows devices\n";
	} else {
		print "win-event: no devices or nothing licensed\n";
	}
};

my @devices;
 while (my $ref = $winsth->fetchrow_hashref) {
        push @devices, $ref;
}

for ($i=0;$i<$numberrows;$i++){
	   sleep(60);
       eval {
       my  $winmachine=$devices[$i]->{'ipaddress'};
       my  $deviceid=$devices[$i]->{'deviceid'};
       my  $credid=$devices[$i]->{'credentialid'};
       $getcred->execute($credid);
	   my $credential = $getcred->fetchrow_hashref();
       my $user = riscUtility::decode($credential->{'username'});
       my $pass = riscUtility::decode($credential->{'passphrase'});
       my $domain = riscUtility::decode($credential->{'domain'});
       #$domain=escape_spaces($domain);
	   #$pass = escape_spaces($pass);
	   #$user = escape_spaces($user);
	   my $objWMI = RISC::riscWindows->old({user=>$user,password=>$pass,domain=>$domain,host=>$winmachine});
	   if ($objWMI->{'status'} eq 'error') {
        print "Authentication failed: " . $objWMI->{'error'}. "\n";
        my $error = $objWMI->{'error'};
        my $errorscantime = time;
        #$mysql->do("update riscdevice set wmi=5 where deviceid=$deviceid");
        #$winsth20->execute($deviceid,$winmachine,$user,$error,$errorscantime);
        next;
        } else {
        #$winsth21->execute($deviceid,$user,$pass);
        }
	print "$deviceid - $winmachine\n";
$colEventLogFileSystem = $objWMI->ExecQuery("SELECT * FROM Win32_NTEventlogFile");
foreach my $logfile(@$colEventLogFileSystem) {
	my $logfileName = $logfile->{LogfileName};
	my $maxRecord = $logfile->{NumberOfRecords};
	my $baseRecord = 1;
	if ($maxRecord >= 200) {
		$baseRecord = $maxRecord-200;
		}
		
	print "SELECT * FROM Win32_NTLogEvent WHERE LogFile=\"$logfileName\" and RecordNumber > $baseRecord\n";
	#my $colEventLog = $objWMI->ExecQuery("SELECT * FROM Win32_NTLogEvent WHERE LogFile=\"$logfileName\" and RecordNumber > $baseRecord");
	if ($logfileName !~ 'Security') {
	$colEventLog = $objWMI->ExecQueryWithNewline("SELECT * FROM Win32_NTLogEvent WHERE LogFile=\'$logfileName\' and TimeGenerated > \'$startdate\' and EventType \!= 4 and Type\!=\'Information\'");
	#print Dumper($colEventLog);
	#------------------Event Logs---------------------
	foreach my $event(@$colEventLog) {
		my $category = $event->{Category};
		my $categorystring = $event->{CategoryString};
		my $computername = $event->{ComputerName};
		my $eventcode = $event->{EventCode};
		my $eventid = $event->{EventIdentifier};
		my $eventtype = $event->{EventType};
		my $logfile = $event->{Logfile};
		my $message = $event->{Message};
		my $recordnumber = $event->{RecordNumber};
		my $sourcename = $event->{SourceName};
		my $timegenerated = $event->{TimeGenerated};
		my $timewritten = $event->{TimeWritten};
		my $type = $event->{Type};
		my $user = $event->{User};
		$winsth14->execute($deviceid,$category,$categorystring,$computername,$eventcode,$eventid,$eventtype,$logfile,$message,$recordnumber,$sourcename,WMIDate($timegenerated),WMIDate($timewritten),$type,$user);
		#print "$recordnumber -- $logfile\n";
	}}
}
	}; if ($@) { print "Error:$@\n";}
       }

sub WMIDate{
my $value=shift;
chomp $value;
my $datetimestring=substr($value,0,4)."-".substr($value,4,2)."-".substr($value,6,2)." ".substr($value,8,2).":".substr($value,10,2).":".substr($value,12,2);
return $datetimestring;
}
sub escape_spaces {
        my $input=shift;
        #print "Input into Subroutine is: $input\n";
        #$input =~ s/^\s+|\s+$//g;
        if ($input=~m/\s/){
                $input="\"".$input."\"";
        }
        else {
        $input=$input;
        }
     #print "Output from Subroutine is: $input\n";
return $input;
}
