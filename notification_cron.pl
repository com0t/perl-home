#!usr/bin/perl
#use SOAP::Lite +trace=>"debug";
use SOAP::Lite;
use DBI();
use IO::Socket;
use lib 'lib';
use MIME::Base64;
use RISC::riscUtility;
use RISC::riscWebservice;
$|++;

my $problem=testRISCWebsite();
unless (defined($problem)) {
	my $mysql2 = riscUtility::getDBH('risc_discovery',0);
	my $queuedNotifsQuery=$mysql2->prepare("select * from platform_notification_queue where sent=0");
	$queuedNotifsQuery->execute();
	while (my $line=$queuedNotifsQuery->fetchrow_hashref()) {
		my $queueid=$line->{'idplatform_notification_queue'};
		my $user=$line->{'user'};
		my $pass=$line->{'pass'};
		my $assessmentkey=$line->{'assessmentkey'};
		my $noteType=$line->{'notetype'};
		my $noteDetail=$line->{'notedetail'};
		my $desc=$line->{'description'};
		my $time=$line->{'timestamp'};
		my $status=notificationupload($user,$pass,$assessmentkey,$noteType,$noteDetail,$desc.":".$time);
		unless (!defined($status->{'notifyResponse'}->{'notifyReturn'}->{'outputmessage'}) || $status->{'notifyResponse'}->{'notifyReturn'}->{'outputmessage'} eq 'fail') {
			$mysql2->do("update platform_notification_queue set sent=1 where idplatform_notification_queue=$queueid");
		} else {next;}
	}
}

sub notificationupload {
       ##########
       ##Manually Create SOAP::Lite Service
       ##########
        my $proxy = "https://platform.myitassessment.com/services/Platform";
        my $uri = "http://DefaultNamespace";
        my $apprequest=SOAP::Lite
        ->uri($uri)
        ->proxy($proxy,timeout=>180);
        my $soapData1 = SOAP::Data->name('authuser')->value($_[0])->type('string');
        my $soapData2 = SOAP::Data->name('authpass')->value($_[1])->type('string');
        my $soapData3 = SOAP::Data->name('assessment_code')->value($_[2])->type('string');
        my $soapData4 = SOAP::Data->name('notification_type')->value($_[3])->type('string');
        my $soapData5 = SOAP::Data->name('notification_detail')->value($_[4])->type('string');
        my $soapData6 = SOAP::Data->name('description')->value($_[5])->type('string');
        my $result=undef;
        eval {
              $result=$apprequest->notify($soapData1,$soapData2,$soapData3,$soapData4,$soapData5,$soapData6);
        }; if ($@ || not defined $result || $som->fault) {$fault->{'Fault'}->{'detail'}=""; $fault->{'Fault'}->{'faultcode'}="APPFAULT";$fault->{'Fault'}->{'faultstring'}="CHECK LOG FILE"; return $fault;}
        return $result->body;
}

sub testRISCWebsite {
      my $timeoutProblem=undef;
      {
        my $timeout=0;
        my $sock=undef;
        $SIG{ALRM} = sub {$timeout=1;die};
        eval {
                alarm (2);
                $sock = new IO::Socket::INET (PeerAddr => 'platform.myitassessment.com', PeerPort => 443,);
                alarm(0);
        }; $timeoutProblem="Can't open connection: We timed out reaching https://platform.myitassessment.com" if ($timeout or !$sock);
        #print "I would print to the socket noew, if I know what I was connected to\n" unless $timeoutProblem;
        close ($sock) if $sock;
            }
      return $timeoutProblem;
}