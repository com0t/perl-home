#begin exchange collection
eval {
#	WinPerfExchangeAssistantsPerAssistant("Win32_PerfRawData_MSExchangeAssistantsPerAssistant_MSExchangeAssistantsPerAssistant",$objWMI,$deviceid);
#	WinPerfExchangeAvailabilityService("Win32_PerfRawData_MSExchangeAvailabilityService_MSExchangeAvailabilityService",$objWMI,$deviceid);
#	WinPerfExchangeCallendarAttendant("Win32_PerfRawData_MSExchangeCalendarAttendant_MSExchangeCalendarAttendant",$objWMI,$deviceid);
#	WinPerfExchangeDatabase("Win32_PerfRawData_ESE_MSExchangeDatabase",$objWMI,$deviceid);
#	WinPerfExchangeDatabaseInstances("Win32_PerfRawData_ESE_MSExchangeDatabaseInstances",$objWMI,$deviceid);
#	WinPerfExchangeDomainCon("Win32_PerfRawData_MSExchangeADAccess_MSExchangeADAccessDomainControllers",$objWMI,$deviceid);
#	ExchangeExtensibilityAgents("Win32_PerfRawData_MSExchangeExtensibilityAgents_MSExchangeExtensibilityAgents",$objWMI,$deviceid);
#	WinPerfExchangeFDSOAB("Win32_PerfRawData_MSExchangeFDSOAB_MSExchangeFDSOAB",$objWMI,$deviceid);
#	WinPerfExchangeIS("Win32_PerfRawData_MSExchangeIS_MSExchangeIS",$objWMI,$deviceid);
#	WinPerfExchangeISClient("Win32_PerfRawData_MSExchangeIS_MSExchangeISClient",$objWMI,$deviceid);
#	WinPerfExchangeISMailbox("Win32_PerfRawData_MSExchangeIS_MSExchangeISMailbox",$objWMI,$deviceid);
#	WinPerfExchangeISPublic("Win32_PerfRawData_MSExchangeIS_MSExchangeISPublic",$objWMI,$deviceid);
#	WinPerfExchangeMailSubmission("Win32_PerfRawData_MSExchangeMailSubmission_MSExchangeMailSubmission",$objWMI,$deviceid);
#	WinPerfExchangeResourceBooking("Win32_PerfRawData_MSExchangeResourceBooking_MSExchangeResourceBooking",$objWMI,$deviceid);
#	WinPerfExchangeSearchIndices("Win32_PerfRawData_MSExchangeSearchIndices_MSExchangeSearchIndices",$objWMI,$deviceid);
#	WinPerfExchangeStoreInterface("Win32_PerfRawData_MSExchangeStoreInterface_MSExchangeStoreInterface",$objWMI,$deviceid);
#	WinPerfExchangeTransportQueues("Win32_PerfRawData_MSExchangeTransportQueues_MSExchangeTransportQueues",$objWMI,$deviceid);
#	WinPerfExchangeADAccessProcess("Win32_PerfRawData_MSExchangeADAccess_MSExchangeADAccessProcesses",$objWMI,$deviceid);
}; if ($@) {print "Problem with Exchange Collection on $deviceid\n";}

#begin SQL server collection
eval {
#	SQLAccMethods();
#	SQLBufferMana();
#	SQLGenStatis();
#	SQLLatches();
#	SQLLocks();
#	SQLMemMan();
#	SQLStatis();
#	SQLDatabase();
#	CatalogMeta();
#	SQLDatabasePerf();
#	SQLErrors();
}; if ($@) {print "Problem with SQL Server collection for $deviceid\n";}




####################################################################################################
####################################################################################################
########### Exchange Subs ##########################################################################
####################################################################################################

sub WinPerfExchangeAssistantsPerAssistant
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;
	
#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchassisperassis (
	deviceid
	,scantime
	,averageeventprocessingtimeinseconds
	,averageeventqueuetimeinseconds
	,caption
	,description
	,elapsedtimesincelasteventqueued
	,eventdispatchers
	,eventsinqueue
	,eventsprocessed
	,eventsprocessedpersec
	,failedeventdispatchers
	,handledexceptions
	,name
	,percentageofeventsdiscardedbymailboxfilter
	,percentageoffailedeventdispatchers
	,percentageofinterestingevents
	,percentageofqueuedeventsdiscardedbymailboxfilter
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $averageeventprocessingtimeinseconds = undef;
my $averageeventqueuetimeinseconds = undef;
my $caption = undef;
my $description = undef;
my $elapsedtimesincelasteventqueued = undef;
my $eventdispatchers = undef;
my $eventsinqueue = undef;
my $eventsprocessed = undef;
my $eventsprocessedpersec = undef;
my $failedeventdispatchers = undef;
my $handledexceptions = undef;
my $tablename = undef;
my $percentageofeventsdiscardedbymailboxfilter = undef;
my $percentageoffailedeventdispatchers = undef;
my $percentageofinterestingevents = undef;
my $percentageofqueuedeventsdiscardedbymailboxfilter = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'averageeventprocessingtimeinseconds'} = $process->{'AverageEventProcessingTimeInSeconds'};
	$risc->{$name}->{'1'}->{'averageeventprocessingtimeinseconds_base'} = $process->{'AverageEventProcessingTimeInSeconds_Base'};
	$risc->{$name}->{'1'}->{'averageeventqueuetimeinseconds'} = $process->{'AverageEventQueueTimeInSeconds'};
	$risc->{$name}->{'1'}->{'averageeventqueuetimeinseconds_base'} = $process->{'AverageEventQueueTimeInSeconds_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'elapsedtimesincelasteventqueued'} = $process->{'ElapsedTimeSinceLastEventQueued'};
	$risc->{$name}->{'1'}->{'eventdispatchers'} = $process->{'EventDispatchers'};
	$risc->{$name}->{'1'}->{'eventsinqueue'} = $process->{'EventsinQueue'};
	$risc->{$name}->{'1'}->{'eventsprocessed'} = $process->{'EventsProcessed'};
	$risc->{$name}->{'1'}->{'eventsprocessedpersec'} = $process->{'EventsProcessedPersec'};
	$risc->{$name}->{'1'}->{'failedeventdispatchers'} = $process->{'FailedEventDispatchers'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'handledexceptions'} = $process->{'HandledExceptions'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'percentageofeventsdiscardedbymailboxfilter'} = $process->{'PercentageOfEventsDiscardedByMailboxFilter'};
	$risc->{$name}->{'1'}->{'percentageofeventsdiscardedbymailboxfilter_base'} = $process->{'PercentageOfEventsDiscardedByMailboxFilter_Base'};
	$risc->{$name}->{'1'}->{'percentageoffailedeventdispatchers'} = $process->{'PercentageofFailedEventDispatchers'};
	$risc->{$name}->{'1'}->{'percentageoffailedeventdispatchers_base'} = $process->{'PercentageofFailedEventDispatchers_Base'};
	$risc->{$name}->{'1'}->{'percentageofinterestingevents'} = $process->{'PercentageofInterestingEvents'};
	$risc->{$name}->{'1'}->{'percentageofinterestingevents_base'} = $process->{'PercentageofInterestingEvents_Base'};
	$risc->{$name}->{'1'}->{'percentageofqueuedeventsdiscardedbymailboxfilter'} = $process->{'PercentageOfQueuedEventsDiscardedByMailboxFilter'};
	$risc->{$name}->{'1'}->{'percentageofqueuedeventsdiscardedbymailboxfilter_base'} = $process->{'PercentageOfQueuedEventsDiscardedByMailboxFilter_Base'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'averageeventprocessingtimeinseconds'} = $process->{'AverageEventProcessingTimeInSeconds'};
	$risc->{$name}->{'2'}->{'averageeventprocessingtimeinseconds_base'} = $process->{'AverageEventProcessingTimeInSeconds_Base'};
	$risc->{$name}->{'2'}->{'averageeventqueuetimeinseconds'} = $process->{'AverageEventQueueTimeInSeconds'};
	$risc->{$name}->{'2'}->{'averageeventqueuetimeinseconds_base'} = $process->{'AverageEventQueueTimeInSeconds_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'elapsedtimesincelasteventqueued'} = $process->{'ElapsedTimeSinceLastEventQueued'};
	$risc->{$name}->{'2'}->{'eventdispatchers'} = $process->{'EventDispatchers'};
	$risc->{$name}->{'2'}->{'eventsinqueue'} = $process->{'EventsinQueue'};
	$risc->{$name}->{'2'}->{'eventsprocessed'} = $process->{'EventsProcessed'};
	$risc->{$name}->{'2'}->{'eventsprocessedpersec'} = $process->{'EventsProcessedPersec'};
	$risc->{$name}->{'2'}->{'failedeventdispatchers'} = $process->{'FailedEventDispatchers'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'handledexceptions'} = $process->{'HandledExceptions'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'percentageofeventsdiscardedbymailboxfilter'} = $process->{'PercentageOfEventsDiscardedByMailboxFilter'};
	$risc->{$name}->{'2'}->{'percentageofeventsdiscardedbymailboxfilter_base'} = $process->{'PercentageOfEventsDiscardedByMailboxFilter_Base'};
	$risc->{$name}->{'2'}->{'percentageoffailedeventdispatchers'} = $process->{'PercentageofFailedEventDispatchers'};
	$risc->{$name}->{'2'}->{'percentageoffailedeventdispatchers_base'} = $process->{'PercentageofFailedEventDispatchers_Base'};
	$risc->{$name}->{'2'}->{'percentageofinterestingevents'} = $process->{'PercentageofInterestingEvents'};
	$risc->{$name}->{'2'}->{'percentageofinterestingevents_base'} = $process->{'PercentageofInterestingEvents_Base'};
	$risc->{$name}->{'2'}->{'percentageofqueuedeventsdiscardedbymailboxfilter'} = $process->{'PercentageOfQueuedEventsDiscardedByMailboxFilter'};
	$risc->{$name}->{'2'}->{'percentageofqueuedeventsdiscardedbymailboxfilter_base'} = $process->{'PercentageOfQueuedEventsDiscardedByMailboxFilter_Base'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find AverageEventProcessingTimeInSeconds---#	
	my $averageeventprocessingtimeinseconds1 = $risc->{$calname}->{'1'}->{'averageeventprocessingtimeinseconds'};	
#	print "averageeventprocessingtimeinseconds1: $averageeventprocessingtimeinseconds1\n";	
	my $averageeventprocessingtimeinseconds2 = $risc->{$calname}->{'2'}->{'averageeventprocessingtimeinseconds'};	
#	print "averageeventprocessingtimeinseconds2: $averageeventprocessingtimeinseconds2\n";	
	my $averageeventprocessingtimeinseconds_base1 = $risc->{$calname}->{'1'}->{'averageeventprocessingtimeinseconds_base'};	
#	print "averageeventprocessingtimeinseconds_base1: $averageeventprocessingtimeinseconds_base1\n";	
	my $averageeventprocessingtimeinseconds_base2 = $risc->{$calname}->{'2'}->{'averageeventprocessingtimeinseconds_base'};	
#	print "averageeventprocessingtimeinseconds_base2: $averageeventprocessingtimeinseconds_base2\n";	
	eval 	
	{	
	$averageeventprocessingtimeinseconds = PERF_AVERAGE_TIMER(	
		$averageeventprocessingtimeinseconds1 #counter value 1
		,$averageeventprocessingtimeinseconds2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$averageeventprocessingtimeinseconds_base1 #base counter value 1
		,$averageeventprocessingtimeinseconds_base2); #base counter value 2
	};	if ($@) {print "$@\n";}
#	print "averageeventprocessingtimeinseconds: $averageeventprocessingtimeinseconds \n";	


	#---find AverageEventQueueTimeInSeconds---#	
	my $averageeventqueuetimeinseconds1 = $risc->{$calname}->{'1'}->{'averageeventqueuetimeinseconds'};	
#	print "averageeventqueuetimeinseconds1: $averageeventqueuetimeinseconds1\n";	
	my $averageeventqueuetimeinseconds2 = $risc->{$calname}->{'2'}->{'averageeventqueuetimeinseconds'};	
#	print "averageeventqueuetimeinseconds2: $averageeventqueuetimeinseconds2\n";	
	my $averageeventqueuetimeinseconds_base1 = $risc->{$calname}->{'1'}->{'averageeventqueuetimeinseconds_base'};	
#	print "averageeventqueuetimeinseconds_base1: $averageeventqueuetimeinseconds_base1\n";	
	my $averageeventqueuetimeinseconds_base2 = $risc->{$calname}->{'2'}->{'averageeventqueuetimeinseconds_base'};	
#	print "averageeventqueuetimeinseconds_base2: $averageeventqueuetimeinseconds_base2\n";	
	eval 	
	{	
	$averageeventqueuetimeinseconds = PERF_AVERAGE_TIMER(	
		$averageeventqueuetimeinseconds1 #counter value 1
		,$averageeventqueuetimeinseconds2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$averageeventqueuetimeinseconds_base1 #base counter value 1
		,$averageeventqueuetimeinseconds_base2); #base counter value 2
	};	
#	print "averageeventqueuetimeinseconds: $averageeventqueuetimeinseconds \n";	


	#---find ElapsedTimeSinceLastEventQueued---#
	my $elapsedtimesincelasteventqueued2 = $risc->{$calname}->{'2'}->{'elapsedtimesincelasteventqueued'};
#	print "elapsedtimesincelasteventqueued2: $elapsedtimesincelasteventqueued2\n";		
	eval 		
	{		
	$elapsedtimesincelasteventqueued = PERF_ELAPSED_TIME(	
		$elapsedtimesincelasteventqueued2 #counter value 2
		,$timestamp_perftime2 #Perf time 2
		,$frequency_perftime2); #Perf freq 2
	};
#	print "ElapsedTimeSinceLastEventQueued: $elapsedtimesincelasteventqueued \n\n";


	#---find EventDispatchers---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$eventdispatchers = $risc->{$calname}->{'2'}->{'eventdispatchers'};
#	print "eventdispatchers: $eventdispatchers \n";


	#---find EventsinQueue---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$eventsinqueue = $risc->{$calname}->{'2'}->{'eventsinqueue'};
#	print "eventsinqueue: $eventsinqueue \n";


	#---find EventsProcessed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$eventsprocessed = $risc->{$calname}->{'2'}->{'eventsprocessed'};
#	print "eventsprocessed: $eventsprocessed \n";


	#---find EventsProcessedPersec---#	
	my $eventsprocessedpersec1 = $risc->{$calname}->{'1'}->{'eventsprocessedpersec'};	
#	print "eventsprocessedpersec1: $eventsprocessedpersec1 \n";	
	my $eventsprocessedpersec2 = $risc->{$calname}->{'2'}->{'eventsprocessedpersec'};	
#	print "eventsprocessedpersec2: $eventsprocessedpersec2 \n";	
	eval 	
	{	
	$eventsprocessedpersec = perf_counter_counter(	
		$eventsprocessedpersec1 #c1
		,$eventsprocessedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "eventsprocessedpersec: $eventsprocessedpersec \n";	


	#---find FailedEventDispatchers---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$failedeventdispatchers = $risc->{$calname}->{'2'}->{'failedeventdispatchers'};
#	print "failedeventdispatchers: $failedeventdispatchers \n";


	#---find HandledExceptions---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$handledexceptions = $risc->{$calname}->{'2'}->{'handledexceptions'};
#	print "handledexceptions: $handledexceptions \n";


	#---find PercentageOfEventsDiscardedByMailboxFilter---#	
	my $percentageofeventsdiscardedbymailboxfilter2 = $risc->{$calname}->{'2'}->{'percentageofeventsdiscardedbymailboxfilter'};	
#	print "percentageofeventsdiscardedbymailboxfilter2: $percentageofeventsdiscardedbymailboxfilter2 \n";	
	my $percentageofeventsdiscardedbymailboxfilter_base2 = $risc->{$calname}->{'2'}->{'percentageofeventsdiscardedbymailboxfilter_base'};	
#	print "percentageofeventsdiscardedbymailboxfilter_base2: $percentageofeventsdiscardedbymailboxfilter_base2\n";	
	eval 	
	{	
	$percentageofeventsdiscardedbymailboxfilter = PERF_RAW_FRACTION(	
		$percentageofeventsdiscardedbymailboxfilter2 #counter value 2
		,$percentageofeventsdiscardedbymailboxfilter_base2); #base counter value 2
	};	
#	print "percentageofeventsdiscardedbymailboxfilter: $percentageofeventsdiscardedbymailboxfilter \n";	


	#---find PercentageofFailedEventDispatchers---#	
	my $percentageoffailedeventdispatchers2 = $risc->{$calname}->{'2'}->{'percentageoffailedeventdispatchers'};	
#	print "percentageoffailedeventdispatchers2: $percentageoffailedeventdispatchers2 \n";	
	my $percentageoffailedeventdispatchers_base2 = $risc->{$calname}->{'2'}->{'percentageoffailedeventdispatchers_base'};	
#	print "percentageoffailedeventdispatchers_base2: $percentageoffailedeventdispatchers_base2\n";	
	eval 	
	{	
	$percentageoffailedeventdispatchers = PERF_RAW_FRACTION(	
		$percentageoffailedeventdispatchers2 #counter value 2
		,$percentageoffailedeventdispatchers_base2); #base counter value 2
	};	
#	print "percentageoffailedeventdispatchers: $percentageoffailedeventdispatchers \n";	


	#---find PercentageofInterestingEvents---#	
	my $percentageofinterestingevents2 = $risc->{$calname}->{'2'}->{'percentageofinterestingevents'};	
#	print "percentageofinterestingevents2: $percentageofinterestingevents2 \n";	
	my $percentageofinterestingevents_base2 = $risc->{$calname}->{'2'}->{'percentageofinterestingevents_base'};	
#	print "percentageofinterestingevents_base2: $percentageofinterestingevents_base2\n";	
	eval 	
	{	
	$percentageofinterestingevents = PERF_RAW_FRACTION(	
		$percentageofinterestingevents2 #counter value 2
		,$percentageofinterestingevents_base2); #base counter value 2
	};	
#	print "percentageofinterestingevents: $percentageofinterestingevents \n";	


	#---find PercentageOfQueuedEventsDiscardedByMailboxFilter---#	
	my $percentageofqueuedeventsdiscardedbymailboxfilter2 = $risc->{$calname}->{'2'}->{'percentageofqueuedeventsdiscardedbymailboxfilter'};	
#	print "percentageofqueuedeventsdiscardedbymailboxfilter2: $percentageofqueuedeventsdiscardedbymailboxfilter2 \n";	
	my $percentageofqueuedeventsdiscardedbymailboxfilter_base2 = $risc->{$calname}->{'2'}->{'percentageofqueuedeventsdiscardedbymailboxfilter_base'};	
#	print "percentageofqueuedeventsdiscardedbymailboxfilter_base2: $percentageofqueuedeventsdiscardedbymailboxfilter_base2\n";	
	eval 	
	{	
	$percentageofqueuedeventsdiscardedbymailboxfilter = PERF_RAW_FRACTION(	
		$percentageofqueuedeventsdiscardedbymailboxfilter2 #counter value 2
		,$percentageofqueuedeventsdiscardedbymailboxfilter_base2); #base counter value 2
	};	
#	print "percentageofqueuedeventsdiscardedbymailboxfilter: $percentageofqueuedeventsdiscardedbymailboxfilter \n";	

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$averageeventprocessingtimeinseconds
	,$averageeventqueuetimeinseconds
	,$caption
	,$description
	,$elapsedtimesincelasteventqueued
	,$eventdispatchers
	,$eventsinqueue
	,$eventsprocessed
	,$eventsprocessedpersec
	,$failedeventdispatchers
	,$handledexceptions
	,$tablename
	,$percentageofeventsdiscardedbymailboxfilter
	,$percentageoffailedeventdispatchers
	,$percentageofinterestingevents
	,$percentageofqueuedeventsdiscardedbymailboxfilter
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeAvailabilityService
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchavailservice (
	deviceid
	,scantime
	,availabilityrequestssec
	,averagenumberofmailboxesprocessedperrequest
	,averagetimetomapexternalcallertointernalidentity
	,averagetimetoprocessacrossforestfreebusyrequest
	,averagetimetoprocessacrosssitefreebusyrequest
	,averagetimetoprocessafederatedfreebusyrequest
	,averagetimetoprocessafreebusyrequest
	,averagetimetoprocessameetingsuggestionsrequest
	,averagetimetoprocessanintrasitefreebusyrequest
	,caption
	,clientreportedfailuresautodiscoverfailures
	,clientreportedfailuresconnectionfailures
	,clientreportedfailurespartialorotherfailures
	,clientreportedfailurestimeoutfailures
	,clientreportedfailurestotal
	,crossforestcalendarfailuressec
	,crossforestcalendarqueriessec
	,crosssitecalendarfailuressec
	,crosssitecalendarqueriessec
	,currentrequests
	,description
	,federatedfreebusycalendarqueriessec
	,federatedfreebusyfailuressec
	,foreignconnectorqueriessec
	,foreignconnectorrequestfailurerate
	,intrasitecalendarfailuressec
	,intrasitecalendarqueriessec
	,intrasiteproxyfreebusycalendarqueriessec
	,intrasiteproxyfreebusyfailuressec
	,name
	,publicfolderqueriessec
	,publicfolderrequestfailuressec
	,successfulclientreportedrequestslessthan10seconds
	,successfulclientreportedrequestslessthan20seconds
	,successfulclientreportedrequestslessthan5seconds
	,successfulclientreportedrequestsover20seconds
	,successfulclientreportedrequeststotal
	,suggestionsrequestssec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $availabilityrequestssec = undef;
my $averagenumberofmailboxesprocessedperrequest = undef;
my $averagetimetomapexternalcallertointernalidentity = undef;
my $averagetimetoprocessacrossforestfreebusyrequest = undef;
my $averagetimetoprocessacrosssitefreebusyrequest = undef;
my $averagetimetoprocessafederatedfreebusyrequest = undef;
my $averagetimetoprocessafreebusyrequest = undef;
my $averagetimetoprocessameetingsuggestionsrequest = undef;
my $averagetimetoprocessanintrasitefreebusyrequest = undef;
my $caption = undef;
my $clientreportedfailuresautodiscoverfailures = undef;
my $clientreportedfailuresconnectionfailures = undef;
my $clientreportedfailurespartialorotherfailures = undef;
my $clientreportedfailurestimeoutfailures = undef;
my $clientreportedfailurestotal = undef;
my $crossforestcalendarfailuressec = undef;
my $crossforestcalendarqueriessec = undef;
my $crosssitecalendarfailuressec = undef;
my $crosssitecalendarqueriessec = undef;
my $currentrequests = undef;
my $description = undef;
my $federatedfreebusycalendarqueriessec = undef;
my $federatedfreebusyfailuressec = undef;
my $foreignconnectorqueriessec = undef;
my $foreignconnectorrequestfailurerate = undef;
my $intrasitecalendarfailuressec = undef;
my $intrasitecalendarqueriessec = undef;
my $intrasiteproxyfreebusycalendarqueriessec = undef;
my $intrasiteproxyfreebusyfailuressec = undef;
my $tablename = undef;
my $publicfolderqueriessec = undef;
my $publicfolderrequestfailuressec = undef;
my $successfulclientreportedrequestslessthan10seconds = undef;
my $successfulclientreportedrequestslessthan20seconds = undef;
my $successfulclientreportedrequestslessthan5seconds = undef;
my $successfulclientreportedrequestsover20seconds = undef;
my $successfulclientreportedrequeststotal = undef;
my $suggestionsrequestssec = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'availabilityrequestssec'} = $process->{'AvailabilityRequestssec'};
	$risc->{$name}->{'1'}->{'averagenumberofmailboxesprocessedperrequest'} = $process->{'AverageNumberofMailboxesProcessedperRequest'};
	$risc->{$name}->{'1'}->{'averagenumberofmailboxesprocessedperrequest_base'} = $process->{'AverageNumberofMailboxesProcessedperRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetomapexternalcallertointernalidentity'} = $process->{'AverageTimetoMapExternalCallertoInternalIdentity'};
	$risc->{$name}->{'1'}->{'averagetimetomapexternalcallertointernalidentity_base'} = $process->{'AverageTimetoMapExternalCallertoInternalIdentity_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessacrossforestfreebusyrequest'} = $process->{'AverageTimetoProcessaCrossForestFreeBusyRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessacrossforestfreebusyrequest_base'} = $process->{'AverageTimetoProcessaCrossForestFreeBusyRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessacrosssitefreebusyrequest'} = $process->{'AverageTimetoProcessaCrossSiteFreeBusyRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessacrosssitefreebusyrequest_base'} = $process->{'AverageTimetoProcessaCrossSiteFreeBusyRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessafederatedfreebusyrequest'} = $process->{'AverageTimetoProcessaFederatedFreeBusyRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessafederatedfreebusyrequest_base'} = $process->{'AverageTimetoProcessaFederatedFreeBusyRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessafreebusyrequest'} = $process->{'AverageTimetoProcessaFreeBusyRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessafreebusyrequest_base'} = $process->{'AverageTimetoProcessaFreeBusyRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessameetingsuggestionsrequest'} = $process->{'AverageTimetoProcessaMeetingSuggestionsRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessameetingsuggestionsrequest_base'} = $process->{'AverageTimetoProcessaMeetingSuggestionsRequest_Base'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessanintrasitefreebusyrequest'} = $process->{'AverageTimetoProcessanIntraSiteFreeBusyRequest'};
	$risc->{$name}->{'1'}->{'averagetimetoprocessanintrasitefreebusyrequest_base'} = $process->{'AverageTimetoProcessanIntraSiteFreeBusyRequest_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'clientreportedfailuresautodiscoverfailures'} = $process->{'ClientReportedFailuresAutoDiscoverFailures'};
	$risc->{$name}->{'1'}->{'clientreportedfailuresconnectionfailures'} = $process->{'ClientReportedFailuresConnectionFailures'};
	$risc->{$name}->{'1'}->{'clientreportedfailurespartialorotherfailures'} = $process->{'ClientReportedFailuresPartialorOtherFailures'};
	$risc->{$name}->{'1'}->{'clientreportedfailurestimeoutfailures'} = $process->{'ClientReportedFailuresTimeoutFailures'};
	$risc->{$name}->{'1'}->{'clientreportedfailurestotal'} = $process->{'ClientReportedFailuresTotal'};
	$risc->{$name}->{'1'}->{'crossforestcalendarfailuressec'} = $process->{'CrossForestCalendarFailuressec'};
	$risc->{$name}->{'1'}->{'crossforestcalendarqueriessec'} = $process->{'CrossForestCalendarQueriessec'};
	$risc->{$name}->{'1'}->{'crosssitecalendarfailuressec'} = $process->{'CrossSiteCalendarFailuressec'};
	$risc->{$name}->{'1'}->{'crosssitecalendarqueriessec'} = $process->{'CrossSiteCalendarQueriessec'};
	$risc->{$name}->{'1'}->{'currentrequests'} = $process->{'CurrentRequests'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'federatedfreebusycalendarqueriessec'} = $process->{'FederatedFreeBusyCalendarQueriessec'};
	$risc->{$name}->{'1'}->{'federatedfreebusyfailuressec'} = $process->{'FederatedFreeBusyFailuressec'};
	$risc->{$name}->{'1'}->{'foreignconnectorqueriessec'} = $process->{'ForeignConnectorQueriessec'};
	$risc->{$name}->{'1'}->{'foreignconnectorrequestfailurerate'} = $process->{'ForeignConnectorRequestFailureRate'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'intrasitecalendarfailuressec'} = $process->{'IntraSiteCalendarFailuressec'};
	$risc->{$name}->{'1'}->{'intrasitecalendarqueriessec'} = $process->{'IntraSiteCalendarQueriessec'};
	$risc->{$name}->{'1'}->{'intrasiteproxyfreebusycalendarqueriessec'} = $process->{'IntraSiteProxyFreeBusyCalendarQueriessec'};
	$risc->{$name}->{'1'}->{'intrasiteproxyfreebusyfailuressec'} = $process->{'IntraSiteProxyFreeBusyFailuressec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'publicfolderqueriessec'} = $process->{'PublicFolderQueriessec'};
	$risc->{$name}->{'1'}->{'publicfolderrequestfailuressec'} = $process->{'PublicFolderRequestFailuressec'};
	$risc->{$name}->{'1'}->{'successfulclientreportedrequestslessthan10seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan10seconds'};
	$risc->{$name}->{'1'}->{'successfulclientreportedrequestslessthan20seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan20seconds'};
	$risc->{$name}->{'1'}->{'successfulclientreportedrequestslessthan5seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan5seconds'};
	$risc->{$name}->{'1'}->{'successfulclientreportedrequestsover20seconds'} = $process->{'SuccessfulClientReportedRequestsOver20seconds'};
	$risc->{$name}->{'1'}->{'successfulclientreportedrequeststotal'} = $process->{'SuccessfulClientReportedRequestsTotal'};
	$risc->{$name}->{'1'}->{'suggestionsrequestssec'} = $process->{'SuggestionsRequestssec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'availabilityrequestssec'} = $process->{'AvailabilityRequestssec'};
	$risc->{$name}->{'2'}->{'averagenumberofmailboxesprocessedperrequest'} = $process->{'AverageNumberofMailboxesProcessedperRequest'};
	$risc->{$name}->{'2'}->{'averagenumberofmailboxesprocessedperrequest_base'} = $process->{'AverageNumberofMailboxesProcessedperRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetomapexternalcallertointernalidentity'} = $process->{'AverageTimetoMapExternalCallertoInternalIdentity'};
	$risc->{$name}->{'2'}->{'averagetimetomapexternalcallertointernalidentity_base'} = $process->{'AverageTimetoMapExternalCallertoInternalIdentity_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessacrossforestfreebusyrequest'} = $process->{'AverageTimetoProcessaCrossForestFreeBusyRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessacrossforestfreebusyrequest_base'} = $process->{'AverageTimetoProcessaCrossForestFreeBusyRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessacrosssitefreebusyrequest'} = $process->{'AverageTimetoProcessaCrossSiteFreeBusyRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessacrosssitefreebusyrequest_base'} = $process->{'AverageTimetoProcessaCrossSiteFreeBusyRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessafederatedfreebusyrequest'} = $process->{'AverageTimetoProcessaFederatedFreeBusyRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessafederatedfreebusyrequest_base'} = $process->{'AverageTimetoProcessaFederatedFreeBusyRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessafreebusyrequest'} = $process->{'AverageTimetoProcessaFreeBusyRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessafreebusyrequest_base'} = $process->{'AverageTimetoProcessaFreeBusyRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessameetingsuggestionsrequest'} = $process->{'AverageTimetoProcessaMeetingSuggestionsRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessameetingsuggestionsrequest_base'} = $process->{'AverageTimetoProcessaMeetingSuggestionsRequest_Base'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessanintrasitefreebusyrequest'} = $process->{'AverageTimetoProcessanIntraSiteFreeBusyRequest'};
	$risc->{$name}->{'2'}->{'averagetimetoprocessanintrasitefreebusyrequest_base'} = $process->{'AverageTimetoProcessanIntraSiteFreeBusyRequest_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'clientreportedfailuresautodiscoverfailures'} = $process->{'ClientReportedFailuresAutoDiscoverFailures'};
	$risc->{$name}->{'2'}->{'clientreportedfailuresconnectionfailures'} = $process->{'ClientReportedFailuresConnectionFailures'};
	$risc->{$name}->{'2'}->{'clientreportedfailurespartialorotherfailures'} = $process->{'ClientReportedFailuresPartialorOtherFailures'};
	$risc->{$name}->{'2'}->{'clientreportedfailurestimeoutfailures'} = $process->{'ClientReportedFailuresTimeoutFailures'};
	$risc->{$name}->{'2'}->{'clientreportedfailurestotal'} = $process->{'ClientReportedFailuresTotal'};
	$risc->{$name}->{'2'}->{'crossforestcalendarfailuressec'} = $process->{'CrossForestCalendarFailuressec'};
	$risc->{$name}->{'2'}->{'crossforestcalendarqueriessec'} = $process->{'CrossForestCalendarQueriessec'};
	$risc->{$name}->{'2'}->{'crosssitecalendarfailuressec'} = $process->{'CrossSiteCalendarFailuressec'};
	$risc->{$name}->{'2'}->{'crosssitecalendarqueriessec'} = $process->{'CrossSiteCalendarQueriessec'};
	$risc->{$name}->{'2'}->{'currentrequests'} = $process->{'CurrentRequests'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'federatedfreebusycalendarqueriessec'} = $process->{'FederatedFreeBusyCalendarQueriessec'};
	$risc->{$name}->{'2'}->{'federatedfreebusyfailuressec'} = $process->{'FederatedFreeBusyFailuressec'};
	$risc->{$name}->{'2'}->{'foreignconnectorqueriessec'} = $process->{'ForeignConnectorQueriessec'};
	$risc->{$name}->{'2'}->{'foreignconnectorrequestfailurerate'} = $process->{'ForeignConnectorRequestFailureRate'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'intrasitecalendarfailuressec'} = $process->{'IntraSiteCalendarFailuressec'};
	$risc->{$name}->{'2'}->{'intrasitecalendarqueriessec'} = $process->{'IntraSiteCalendarQueriessec'};
	$risc->{$name}->{'2'}->{'intrasiteproxyfreebusycalendarqueriessec'} = $process->{'IntraSiteProxyFreeBusyCalendarQueriessec'};
	$risc->{$name}->{'2'}->{'intrasiteproxyfreebusyfailuressec'} = $process->{'IntraSiteProxyFreeBusyFailuressec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'publicfolderqueriessec'} = $process->{'PublicFolderQueriessec'};
	$risc->{$name}->{'2'}->{'publicfolderrequestfailuressec'} = $process->{'PublicFolderRequestFailuressec'};
	$risc->{$name}->{'2'}->{'successfulclientreportedrequestslessthan10seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan10seconds'};
	$risc->{$name}->{'2'}->{'successfulclientreportedrequestslessthan20seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan20seconds'};
	$risc->{$name}->{'2'}->{'successfulclientreportedrequestslessthan5seconds'} = $process->{'SuccessfulClientReportedRequestsLessthan5seconds'};
	$risc->{$name}->{'2'}->{'successfulclientreportedrequestsover20seconds'} = $process->{'SuccessfulClientReportedRequestsOver20seconds'};
	$risc->{$name}->{'2'}->{'successfulclientreportedrequeststotal'} = $process->{'SuccessfulClientReportedRequestsTotal'};
	$risc->{$name}->{'2'}->{'suggestionsrequestssec'} = $process->{'SuggestionsRequestssec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};


	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";


	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;


	#---find AvailabilityRequestssec---#	
	$val1 = $risc->{$calname}->{'1'}->{'availabilityrequestssec'};	
#	print "AvailabilityRequestssec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'availabilityrequestssec'};	
#	print "AvailabilityRequestssec2: $val2 \n";	
	eval 	
	{	
	$availabilityrequestssec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "AvailabilityRequestssec: $availabilityrequestssec \n\n";	


	#---find AverageNumberofMailboxesProcessedperRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagenumberofmailboxesprocessedperrequest'};	
#	print "AverageNumberofMailboxesProcessedperRequest1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagenumberofmailboxesprocessedperrequest'};	
#	print "AverageNumberofMailboxesProcessedperRequest2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagenumberofmailboxesprocessedperrequest_base'};	
#	print "AverageNumberofMailboxesProcessedperRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagenumberofmailboxesprocessedperrequest_base'};	
#	print "AverageNumberofMailboxesProcessedperRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagenumberofmailboxesprocessedperrequest = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageNumberofMailboxesProcessedperRequest: $averagenumberofmailboxesprocessedperrequest \n";	


	#---find AverageTimetoMapExternalCallertoInternalIdentity---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetomapexternalcallertointernalidentity'};	
#	print "AverageTimetoMapExternalCallertoInternalIdentity1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetomapexternalcallertointernalidentity'};	
#	print "AverageTimetoMapExternalCallertoInternalIdentity2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetomapexternalcallertointernalidentity_base'};	
#	print "AverageTimetoMapExternalCallertoInternalIdentity_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetomapexternalcallertointernalidentity_base'};	
#	print "AverageTimetoMapExternalCallertoInternalIdentity_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetomapexternalcallertointernalidentity = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoMapExternalCallertoInternalIdentity: $averagetimetomapexternalcallertointernalidentity \n\n";	
	

	#---find AverageTimetoProcessaCrossForestFreeBusyRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessacrossforestfreebusyrequest'};	
#	print "AverageTimetoProcessaCrossForestFreeBusyRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessacrossforestfreebusyrequest'};	
#	print "AverageTimetoProcessaCrossForestFreeBusyRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessacrossforestfreebusyrequest_base'};	
#	print "AverageTimetoProcessaCrossForestFreeBusyRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessacrossforestfreebusyrequest_base'};	
#	print "AverageTimetoProcessaCrossForestFreeBusyRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessacrossforestfreebusyrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessaCrossForestFreeBusyRequest: $averagetimetoprocessacrossforestfreebusyrequest \n\n";	


	#---find AverageTimetoProcessaCrossSiteFreeBusyRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessacrosssitefreebusyrequest'};	
#	print "AverageTimetoProcessaCrossSiteFreeBusyRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessacrosssitefreebusyrequest'};	
#	print "AverageTimetoProcessaCrossSiteFreeBusyRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessacrosssitefreebusyrequest_base'};	
#	print "AverageTimetoProcessaCrossSiteFreeBusyRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessacrosssitefreebusyrequest_base'};	
#	print "AverageTimetoProcessaCrossSiteFreeBusyRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessacrosssitefreebusyrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessaCrossSiteFreeBusyRequest: $averagetimetoprocessacrosssitefreebusyrequest \n\n";	


	#---find AverageTimetoProcessaFederatedFreeBusyRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessafederatedfreebusyrequest'};	
#	print "AverageTimetoProcessaFederatedFreeBusyRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessafederatedfreebusyrequest'};	
#	print "AverageTimetoProcessaFederatedFreeBusyRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessafederatedfreebusyrequest_base'};	
#	print "AverageTimetoProcessaFederatedFreeBusyRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessafederatedfreebusyrequest_base'};	
#	print "AverageTimetoProcessaFederatedFreeBusyRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessafederatedfreebusyrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessaFederatedFreeBusyRequest: $averagetimetoprocessafederatedfreebusyrequest \n\n";	


	#---find AverageTimetoProcessaFreeBusyRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessafreebusyrequest'};	
#	print "AverageTimetoProcessaFreeBusyRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessafreebusyrequest'};	
#	print "AverageTimetoProcessaFreeBusyRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessafreebusyrequest_base'};	
#	print "AverageTimetoProcessaFreeBusyRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessafreebusyrequest_base'};	
#	print "AverageTimetoProcessaFreeBusyRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessafreebusyrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessaFreeBusyRequest: $averagetimetoprocessafreebusyrequest \n\n";	


	#---find AverageTimetoProcessaMeetingSuggestionsRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessameetingsuggestionsrequest'};	
#	print "AverageTimetoProcessaMeetingSuggestionsRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessameetingsuggestionsrequest'};	
#	print "AverageTimetoProcessaMeetingSuggestionsRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessameetingsuggestionsrequest_base'};	
#	print "AverageTimetoProcessaMeetingSuggestionsRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessameetingsuggestionsrequest_base'};	
#	print "AverageTimetoProcessaMeetingSuggestionsRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessameetingsuggestionsrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessaMeetingSuggestionsRequest: $averagetimetoprocessameetingsuggestionsrequest \n\n";	


	#---find AverageTimetoProcessanIntraSiteFreeBusyRequest---#	
	$val1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessanintrasitefreebusyrequest'};	
#	print "AverageTimetoProcessanIntraSiteFreeBusyRequest1: $val1\n";	
	$val2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessanintrasitefreebusyrequest'};	
#	print "AverageTimetoProcessanIntraSiteFreeBusyRequest2: $val2\n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'averagetimetoprocessanintrasitefreebusyrequest_base'};	
#	print "AverageTimetoProcessanIntraSiteFreeBusyRequest_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'averagetimetoprocessanintrasitefreebusyrequest_base'};	
#	print "AverageTimetoProcessanIntraSiteFreeBusyRequest_base2: $val_base2\n";	
	eval 	
	{	
	$averagetimetoprocessanintrasitefreebusyrequest = PERF_AVERAGE_TIMER(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$frequency_perftime2 #Perf freq 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "AverageTimetoProcessanIntraSiteFreeBusyRequest: $averagetimetoprocessanintrasitefreebusyrequest \n\n";	


	#---find ClientReportedFailuresAutoDiscoverFailures---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$clientreportedfailuresautodiscoverfailures = $risc->{$calname}->{'2'}->{'clientreportedfailuresautodiscoverfailures'};
#	print "ClientReportedFailuresAutoDiscoverFailures: $clientreportedfailuresautodiscoverfailures \n\n";


	#---find ClientReportedFailuresConnectionFailures---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$clientreportedfailuresconnectionfailures = $risc->{$calname}->{'2'}->{'clientreportedfailuresconnectionfailures'};
#	print "ClientReportedFailuresConnectionFailures: $clientreportedfailuresconnectionfailures \n\n";


	#---find ClientReportedFailuresPartialorOtherFailures---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$clientreportedfailurespartialorotherfailures = $risc->{$calname}->{'2'}->{'clientreportedfailurespartialorotherfailures'};
#	print "ClientReportedFailuresPartialorOtherFailures: $clientreportedfailurespartialorotherfailures \n\n";


	#---find ClientReportedFailuresTimeoutFailures---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$clientreportedfailurestimeoutfailures = $risc->{$calname}->{'2'}->{'clientreportedfailurestimeoutfailures'};
#	print "ClientReportedFailuresTimeoutFailures: $clientreportedfailurestimeoutfailures \n\n";


	#---find ClientReportedFailuresTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$clientreportedfailurestotal = $risc->{$calname}->{'2'}->{'clientreportedfailurestotal'};
#	print "ClientReportedFailuresTotal: $clientreportedfailurestotal \n\n";


	#---find CrossForestCalendarFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'crossforestcalendarfailuressec'};	
#	print "CrossForestCalendarFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'crossforestcalendarfailuressec'};	
#	print "CrossForestCalendarFailuressec2: $val2 \n";	
	eval 	
	{	
	$crossforestcalendarfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "CrossForestCalendarFailuressec: $crossforestcalendarfailuressec \n\n";	


	#---find CrossForestCalendarQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'crossforestcalendarqueriessec'};	
#	print "CrossForestCalendarQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'crossforestcalendarqueriessec'};	
#	print "CrossForestCalendarQueriessec2: $val2 \n";	
	eval 	
	{	
	$crossforestcalendarqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "CrossForestCalendarQueriessec: $crossforestcalendarqueriessec \n\n";	


	#---find CrossSiteCalendarFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'crosssitecalendarfailuressec'};	
#	print "CrossSiteCalendarFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'crosssitecalendarfailuressec'};	
#	print "CrossSiteCalendarFailuressec2: $val2 \n";	
	eval 	
	{	
	$crosssitecalendarfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "CrossSiteCalendarFailuressec: $crosssitecalendarfailuressec \n\n";	


	#---find CrossSiteCalendarQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'crosssitecalendarqueriessec'};	
#	print "CrossSiteCalendarQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'crosssitecalendarqueriessec'};	
#	print "CrossSiteCalendarQueriessec2: $val2 \n";	
	eval 	
	{	
	$crosssitecalendarqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "CrossSiteCalendarQueriessec: $crosssitecalendarqueriessec \n\n";	


	#---find CurrentRequests---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$currentrequests = $risc->{$calname}->{'2'}->{'currentrequests'};
#	print "CurrentRequests: $currentrequests \n\n";


	#---find FederatedFreeBusyCalendarQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'federatedfreebusycalendarqueriessec'};	
#	print "FederatedFreeBusyCalendarQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'federatedfreebusycalendarqueriessec'};	
#	print "FederatedFreeBusyCalendarQueriessec2: $val2 \n";	
	eval 	
	{	
	$federatedfreebusycalendarqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "FederatedFreeBusyCalendarQueriessec: $federatedfreebusycalendarqueriessec \n\n";	


	#---find FederatedFreeBusyFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'federatedfreebusyfailuressec'};	
#	print "FederatedFreeBusyFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'federatedfreebusyfailuressec'};	
#	print "FederatedFreeBusyFailuressec2: $val2 \n";	
	eval 	
	{	
	$federatedfreebusyfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "FederatedFreeBusyFailuressec: $federatedfreebusyfailuressec \n\n";	


	#---find ForeignConnectorQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'foreignconnectorqueriessec'};	
#	print "ForeignConnectorQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'foreignconnectorqueriessec'};	
#	print "ForeignConnectorQueriessec2: $val2 \n";	
	eval 	
	{	
	$foreignconnectorqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ForeignConnectorQueriessec: $foreignconnectorqueriessec \n\n";	


	#---find ForeignConnectorRequestFailureRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'foreignconnectorrequestfailurerate'};	
#	print "ForeignConnectorRequestFailureRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'foreignconnectorrequestfailurerate'};	
#	print "ForeignConnectorRequestFailureRate2: $val2 \n";	
	eval 	
	{	
	$foreignconnectorrequestfailurerate = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ForeignConnectorRequestFailureRate: $foreignconnectorrequestfailurerate \n\n";	


	#---find IntraSiteCalendarFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'intrasitecalendarfailuressec'};	
#	print "IntraSiteCalendarFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'intrasitecalendarfailuressec'};	
#	print "IntraSiteCalendarFailuressec2: $val2 \n";	
	eval 	
	{	
	$intrasitecalendarfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "IntraSiteCalendarFailuressec: $intrasitecalendarfailuressec \n\n";	


	#---find IntraSiteCalendarQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'intrasitecalendarqueriessec'};	
#	print "IntraSiteCalendarQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'intrasitecalendarqueriessec'};	
#	print "IntraSiteCalendarQueriessec2: $val2 \n";	
	eval 	
	{	
	$intrasitecalendarqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "IntraSiteCalendarQueriessec: $intrasitecalendarqueriessec \n\n";	


	#---find IntraSiteProxyFreeBusyCalendarQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'intrasiteproxyfreebusycalendarqueriessec'};	
#	print "IntraSiteProxyFreeBusyCalendarQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'intrasiteproxyfreebusycalendarqueriessec'};	
#	print "IntraSiteProxyFreeBusyCalendarQueriessec2: $val2 \n";	
	eval 	
	{	
	$intrasiteproxyfreebusycalendarqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "IntraSiteProxyFreeBusyCalendarQueriessec: $intrasiteproxyfreebusycalendarqueriessec \n\n";	


	#---find IntraSiteProxyFreeBusyFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'intrasiteproxyfreebusyfailuressec'};	
#	print "IntraSiteProxyFreeBusyFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'intrasiteproxyfreebusyfailuressec'};	
#	print "IntraSiteProxyFreeBusyFailuressec2: $val2 \n";	
	eval 	
	{	
	$intrasiteproxyfreebusyfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "IntraSiteProxyFreeBusyFailuressec: $intrasiteproxyfreebusyfailuressec \n\n";	


	#---find PublicFolderQueriessec---#	
	$val1 = $risc->{$calname}->{'1'}->{'publicfolderqueriessec'};	
#	print "PublicFolderQueriessec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'publicfolderqueriessec'};	
#	print "PublicFolderQueriessec2: $val2 \n";	
	eval 	
	{	
	$publicfolderqueriessec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "PublicFolderQueriessec: $publicfolderqueriessec \n\n";	


	#---find PublicFolderRequestFailuressec---#	
	$val1 = $risc->{$calname}->{'1'}->{'publicfolderrequestfailuressec'};	
#	print "PublicFolderRequestFailuressec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'publicfolderrequestfailuressec'};	
#	print "PublicFolderRequestFailuressec2: $val2 \n";	
	eval 	
	{	
	$publicfolderrequestfailuressec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "PublicFolderRequestFailuressec: $publicfolderrequestfailuressec \n\n";	


	#---find SuccessfulClientReportedRequestsLessthan10seconds---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulclientreportedrequestslessthan10seconds = $risc->{$calname}->{'2'}->{'successfulclientreportedrequestslessthan10seconds'};
#	print "SuccessfulClientReportedRequestsLessthan10seconds: $successfulclientreportedrequestslessthan10seconds \n\n";


	#---find SuccessfulClientReportedRequestsLessthan20seconds---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulclientreportedrequestslessthan20seconds = $risc->{$calname}->{'2'}->{'successfulclientreportedrequestslessthan20seconds'};
#	print "SuccessfulClientReportedRequestsLessthan20seconds: $successfulclientreportedrequestslessthan20seconds \n\n";


	#---find SuccessfulClientReportedRequestsLessthan5seconds---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulclientreportedrequestslessthan5seconds = $risc->{$calname}->{'2'}->{'successfulclientreportedrequestslessthan5seconds'};
#	print "SuccessfulClientReportedRequestsLessthan5seconds: $successfulclientreportedrequestslessthan5seconds \n\n";


	#---find SuccessfulClientReportedRequestsOver20seconds---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulclientreportedrequestsover20seconds = $risc->{$calname}->{'2'}->{'successfulclientreportedrequestsover20seconds'};
#	print "SuccessfulClientReportedRequestsOver20seconds: $successfulclientreportedrequestsover20seconds \n\n";


	#---find SuccessfulClientReportedRequestsTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulclientreportedrequeststotal = $risc->{$calname}->{'2'}->{'successfulclientreportedrequeststotal'};
#	print "SuccessfulClientReportedRequestsTotal: $successfulclientreportedrequeststotal \n\n";


	#---find SuggestionsRequestssec---#	
	$val1 = $risc->{$calname}->{'1'}->{'suggestionsrequestssec'};	
#	print "SuggestionsRequestssec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'suggestionsrequestssec'};	
#	print "SuggestionsRequestssec2: $val2 \n";	
	eval 	
	{	
	$suggestionsrequestssec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "SuggestionsRequestssec: $suggestionsrequestssec \n\n";	


##################################################################
									
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$availabilityrequestssec
	,$averagenumberofmailboxesprocessedperrequest
	,$averagetimetomapexternalcallertointernalidentity
	,$averagetimetoprocessacrossforestfreebusyrequest
	,$averagetimetoprocessacrosssitefreebusyrequest
	,$averagetimetoprocessafederatedfreebusyrequest
	,$averagetimetoprocessafreebusyrequest
	,$averagetimetoprocessameetingsuggestionsrequest
	,$averagetimetoprocessanintrasitefreebusyrequest
	,$caption
	,$clientreportedfailuresautodiscoverfailures
	,$clientreportedfailuresconnectionfailures
	,$clientreportedfailurespartialorotherfailures
	,$clientreportedfailurestimeoutfailures
	,$clientreportedfailurestotal
	,$crossforestcalendarfailuressec
	,$crossforestcalendarqueriessec
	,$crosssitecalendarfailuressec
	,$crosssitecalendarqueriessec
	,$currentrequests
	,$description
	,$federatedfreebusycalendarqueriessec
	,$federatedfreebusyfailuressec
	,$foreignconnectorqueriessec
	,$foreignconnectorrequestfailurerate
	,$intrasitecalendarfailuressec
	,$intrasitecalendarqueriessec
	,$intrasiteproxyfreebusycalendarqueriessec
	,$intrasiteproxyfreebusyfailuressec
	,$tablename
	,$publicfolderqueriessec
	,$publicfolderrequestfailuressec
	,$successfulclientreportedrequestslessthan10seconds
	,$successfulclientreportedrequestslessthan20seconds
	,$successfulclientreportedrequestslessthan5seconds
	,$successfulclientreportedrequestsover20seconds
	,$successfulclientreportedrequeststotal
	,$suggestionsrequestssec
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeCallendarAttendant
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchcalenatten (
	deviceid
	,scantime
	,averagecalendarattendantprocessingtime
	,caption
	,description
	,invitations
	,lastcalendarattendantprocessingtime
	,lostraces
	,meetingcancellations
	,meetingmessagesdeleted
	,meetingmessagesprocessed
	,meetingresponses
	,name
	,requestsfailed
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $averagecalendarattendantprocessingtime = undef;
my $caption = undef;
my $description = undef;
my $invitations = undef;
my $lastcalendarattendantprocessingtime = undef;
my $lostraces = undef;
my $meetingcancellations = undef;
my $meetingmessagesdeleted = undef;
my $meetingmessagesprocessed = undef;
my $meetingresponses = undef;
my $tablename = undef;
my $requestsfailed = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'averagecalendarattendantprocessingtime'} = $process->{'AverageCalendarAttendantProcessingTime'};
	$risc->{$name}->{'1'}->{'averagecalendarattendantprocessingtime_base'} = $process->{'AverageCalendarAttendantProcessingTime_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'invitations'} = $process->{'Invitations'};
	$risc->{$name}->{'1'}->{'lastcalendarattendantprocessingtime'} = $process->{'LastCalendarAttendantProcessingTime'};
	$risc->{$name}->{'1'}->{'lostraces'} = $process->{'LostRaces'};
	$risc->{$name}->{'1'}->{'meetingcancellations'} = $process->{'MeetingCancellations'};
	$risc->{$name}->{'1'}->{'meetingmessagesdeleted'} = $process->{'MeetingMessagesDeleted'};
	$risc->{$name}->{'1'}->{'meetingmessagesprocessed'} = $process->{'MeetingMessagesProcessed'};
	$risc->{$name}->{'1'}->{'meetingresponses'} = $process->{'MeetingResponses'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'requestsfailed'} = $process->{'RequestsFailed'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'averagecalendarattendantprocessingtime'} = $process->{'AverageCalendarAttendantProcessingTime'};
	$risc->{$name}->{'2'}->{'averagecalendarattendantprocessingtime_base'} = $process->{'AverageCalendarAttendantProcessingTime_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'invitations'} = $process->{'Invitations'};
	$risc->{$name}->{'2'}->{'lastcalendarattendantprocessingtime'} = $process->{'LastCalendarAttendantProcessingTime'};
	$risc->{$name}->{'2'}->{'lostraces'} = $process->{'LostRaces'};
	$risc->{$name}->{'2'}->{'meetingcancellations'} = $process->{'MeetingCancellations'};
	$risc->{$name}->{'2'}->{'meetingmessagesdeleted'} = $process->{'MeetingMessagesDeleted'};
	$risc->{$name}->{'2'}->{'meetingmessagesprocessed'} = $process->{'MeetingMessagesProcessed'};
	$risc->{$name}->{'2'}->{'meetingresponses'} = $process->{'MeetingResponses'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'requestsfailed'} = $process->{'RequestsFailed'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find AverageCalendarAttendantProcessingTime---#	
	my $averagecalendarattendantprocessingtime1 = $risc->{$calname}->{'1'}->{'averagecalendarattendantprocessingtime'};	
#	print "averagecalendarattendantprocessingtime1: $averagecalendarattendantprocessingtime1 \n";	
	my $averagecalendarattendantprocessingtime2 = $risc->{$calname}->{'2'}->{'averagecalendarattendantprocessingtime'};	
#	print "averagecalendarattendantprocessingtime2: $averagecalendarattendantprocessingtime2 \n";	
	my $averagecalendarattendantprocessingtime_base1 = $risc->{$calname}->{'1'}->{'averagecalendarattendantprocessingtime_base'};	
#	print "averagecalendarattendantprocessingtime_base1: $averagecalendarattendantprocessingtime_base1\n";	
	my $averagecalendarattendantprocessingtime_base2 = $risc->{$calname}->{'2'}->{'averagecalendarattendantprocessingtime_base'};	
#	print "averagecalendarattendantprocessingtime_base2: $averagecalendarattendantprocessingtime_base2\n";	
	eval 	
	{	
	$averagecalendarattendantprocessingtime = PERF_AVERAGE_BULK(	
		$averagecalendarattendantprocessingtime1 #counter value 1
		,$averagecalendarattendantprocessingtime2 #counter value 2
		,$averagecalendarattendantprocessingtime_base1 #base counter value 1
		,$averagecalendarattendantprocessingtime_base2); #base counter value 2
	};	
#	print "averagecalendarattendantprocessingtime: $averagecalendarattendantprocessingtime \n";	


	#---find Invitations---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$invitations = $risc->{$calname}->{'2'}->{'invitations'};
#	print "invitations: $invitations \n";


	#---find LastCalendarAttendantProcessingTime---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$lastcalendarattendantprocessingtime = $risc->{$calname}->{'2'}->{'lastcalendarattendantprocessingtime'};
#	print "lastcalendarattendantprocessingtime: $lastcalendarattendantprocessingtime \n";


	#---find LostRaces---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$lostraces = $risc->{$calname}->{'2'}->{'lostraces'};
#	print "lostraces: $lostraces \n";


	#---find MeetingCancellations---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$meetingcancellations = $risc->{$calname}->{'2'}->{'meetingcancellations'};
#	print "meetingcancellations: $meetingcancellations \n";


	#---find MeetingMessagesDeleted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$meetingmessagesdeleted = $risc->{$calname}->{'2'}->{'meetingmessagesdeleted'};
#	print "meetingmessagesdeleted: $meetingmessagesdeleted \n";


	#---find MeetingMessagesProcessed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$meetingmessagesprocessed = $risc->{$calname}->{'2'}->{'meetingmessagesprocessed'};
#	print "meetingmessagesprocessed: $meetingmessagesprocessed \n";


	#---find MeetingResponses---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$meetingresponses = $risc->{$calname}->{'2'}->{'meetingresponses'};
#	print "meetingresponses: $meetingresponses \n";


	#---find RequestsFailed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$requestsfailed = $risc->{$calname}->{'2'}->{'requestsfailed'};
#	print "requestsfailed: $requestsfailed \n";

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$averagecalendarattendantprocessingtime
	,$caption
	,$description
	,$invitations
	,$lastcalendarattendantprocessingtime
	,$lostraces
	,$meetingcancellations
	,$meetingmessagesdeleted
	,$meetingmessagesprocessed
	,$meetingresponses
	,$tablename
	,$requestsfailed
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeDatabase
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchdatabase (
	deviceid
	,scantime
	,caption
	,databasecachemissespersec
	,databasecachepercentdehydrated
	,databasecachepercenthit
	,databasecacherequestspersec
	,databasecachesize
	,databasecachesizeeffective
	,databasecachesizeeffectivemb
	,databasecachesizemb
	,databasecachesizeresident
	,databasecachesizeresidentmb
	,databasemaintenanceduration
	,databasemaintenancepagesbadchecksums
	,databasepageevictionspersec
	,databasepagefaultspersec
	,databasepagefaultstallspersec
	,defragmentationtasks
	,defragmentationtaskspending
	,description
	,iodatabasereadsattachedaveragelatency
	,iodatabasereadsattachedpersec
	,iodatabasereadsaveragelatency
	,iodatabasereadspersec
	,iodatabasereadsrecoveryaveragelatency
	,iodatabasereadsrecoverypersec
	,iodatabasewritesattachedaveragelatency
	,iodatabasewritesattachedpersec
	,iodatabasewritesaveragelatency
	,iodatabasewritespersec
	,iodatabasewritesrecoveryaveragelatency
	,iodatabasewritesrecoverypersec
	,iologreadsaveragelatency
	,iologreadspersec
	,iologwritesaveragelatency
	,iologwritespersec
	,logbytesgeneratedpersec
	,logbyteswritepersec
	,logrecordstallspersec
	,logthreadswaiting
	,logwritespersec
	,name
	,pagesconverted
	,pagesconvertedpersec
	,recordsconverted
	,recordsconvertedpersec
	,sessionsinuse
	,sessionspercentused
	,tableopencachehitspersec
	,tableopencachemissespersec
	,tableopencachepercenthit
	,tableopenspersec
	,versionbucketsallocated
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $caption = undef;
my $databasecachemissespersec = undef;
my $databasecachepercentdehydrated = undef;
my $databasecachepercenthit = undef;
my $databasecacherequestspersec = undef;
my $databasecachesize = undef;
my $databasecachesizeeffective = undef;
my $databasecachesizeeffectivemb = undef;
my $databasecachesizemb = undef;
my $databasecachesizeresident = undef;
my $databasecachesizeresidentmb = undef;
my $databasemaintenanceduration = undef;
my $databasemaintenancepagesbadchecksums = undef;
my $databasepageevictionspersec = undef;
my $databasepagefaultspersec = undef;
my $databasepagefaultstallspersec = undef;
my $defragmentationtasks = undef;
my $defragmentationtaskspending = undef;
my $description = undef;
my $iodatabasereadsattachedaveragelatency = undef;
my $iodatabasereadsattachedpersec = undef;
my $iodatabasereadsaveragelatency = undef;
my $iodatabasereadspersec = undef;
my $iodatabasereadsrecoveryaveragelatency = undef;
my $iodatabasereadsrecoverypersec = undef;
my $iodatabasewritesattachedaveragelatency = undef;
my $iodatabasewritesattachedpersec = undef;
my $iodatabasewritesaveragelatency = undef;
my $iodatabasewritespersec = undef;
my $iodatabasewritesrecoveryaveragelatency = undef;
my $iodatabasewritesrecoverypersec = undef;
my $iologreadsaveragelatency = undef;
my $iologreadspersec = undef;
my $iologwritesaveragelatency = undef;
my $iologwritespersec = undef;
my $logbytesgeneratedpersec = undef;
my $logbyteswritepersec = undef;
my $logrecordstallspersec = undef;
my $logthreadswaiting = undef;
my $logwritespersec = undef;
my $tablename = undef;
my $pagesconverted = undef;
my $pagesconvertedpersec = undef;
my $recordsconverted = undef;
my $recordsconvertedpersec = undef;
my $sessionsinuse = undef;
my $sessionspercentused = undef;
my $tableopencachehitspersec = undef;
my $tableopencachemissespersec = undef;
my $tableopencachepercenthit = undef;
my $tableopenspersec = undef;
my $versionbucketsallocated = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'databasecachemissespersec'} = $process->{'DatabaseCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'databasecachepercentdehydrated'} = $process->{'DatabaseCachePercentDehydrated'};
	$risc->{$name}->{'1'}->{'databasecachepercentdehydrated_base'} = $process->{'DatabaseCachePercentDehydrated_Base'};
	$risc->{$name}->{'1'}->{'databasecachepercenthit'} = $process->{'DatabaseCachePercentHit'};
	$risc->{$name}->{'1'}->{'databasecachepercenthit_base'} = $process->{'DatabaseCachePercentHit_Base'};
	$risc->{$name}->{'1'}->{'databasecacherequestspersec'} = $process->{'DatabaseCacheRequestsPersec'};
	$risc->{$name}->{'1'}->{'databasecachesize'} = $process->{'DatabaseCacheSize'};
	$risc->{$name}->{'1'}->{'databasecachesizeeffective'} = $process->{'DatabaseCacheSizeEffective'};
	$risc->{$name}->{'1'}->{'databasecachesizeeffectivemb'} = $process->{'DatabaseCacheSizeEffectiveMB'};
	$risc->{$name}->{'1'}->{'databasecachesizemb'} = $process->{'DatabaseCacheSizeMB'};
	$risc->{$name}->{'1'}->{'databasecachesizeresident'} = $process->{'DatabaseCacheSizeResident'};
	$risc->{$name}->{'1'}->{'databasecachesizeresidentmb'} = $process->{'DatabaseCacheSizeResidentMB'};
	$risc->{$name}->{'1'}->{'databasemaintenanceduration'} = $process->{'DatabaseMaintenanceDuration'};
	$risc->{$name}->{'1'}->{'databasemaintenancepagesbadchecksums'} = $process->{'DatabaseMaintenancePagesBadChecksums'};
	$risc->{$name}->{'1'}->{'databasepageevictionspersec'} = $process->{'DatabasePageEvictionsPersec'};
	$risc->{$name}->{'1'}->{'databasepagefaultspersec'} = $process->{'DatabasePageFaultsPersec'};
	$risc->{$name}->{'1'}->{'databasepagefaultstallspersec'} = $process->{'DatabasePageFaultStallsPersec'};
	$risc->{$name}->{'1'}->{'defragmentationtasks'} = $process->{'DefragmentationTasks'};
	$risc->{$name}->{'1'}->{'defragmentationtaskspending'} = $process->{'DefragmentationTasksPending'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedaveragelatency'} = $process->{'IODatabaseReadsAttachedAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedaveragelatency_base'} = $process->{'IODatabaseReadsAttachedAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedpersec'} = $process->{'IODatabaseReadsAttachedPersec'};
	$risc->{$name}->{'1'}->{'iodatabasereadsaveragelatency'} = $process->{'IODatabaseReadsAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsaveragelatency_base'} = $process->{'IODatabaseReadsAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadspersec'} = $process->{'IODatabaseReadsPersec'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoveryaveragelatency'} = $process->{'IODatabaseReadsRecoveryAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoveryaveragelatency_base'} = $process->{'IODatabaseReadsRecoveryAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoverypersec'} = $process->{'IODatabaseReadsRecoveryPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedaveragelatency'} = $process->{'IODatabaseWritesAttachedAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedaveragelatency_base'} = $process->{'IODatabaseWritesAttachedAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedpersec'} = $process->{'IODatabaseWritesAttachedPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesaveragelatency'} = $process->{'IODatabaseWritesAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesaveragelatency_base'} = $process->{'IODatabaseWritesAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritespersec'} = $process->{'IODatabaseWritesPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoveryaveragelatency'} = $process->{'IODatabaseWritesRecoveryAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoveryaveragelatency_base'} = $process->{'IODatabaseWritesRecoveryAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoverypersec'} = $process->{'IODatabaseWritesRecoveryPersec'};
	$risc->{$name}->{'1'}->{'iologreadsaveragelatency'} = $process->{'IOLogReadsAverageLatency'};
	$risc->{$name}->{'1'}->{'iologreadsaveragelatency_base'} = $process->{'IOLogReadsAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iologreadspersec'} = $process->{'IOLogReadsPersec'};
	$risc->{$name}->{'1'}->{'iologwritesaveragelatency'} = $process->{'IOLogWritesAverageLatency'};
	$risc->{$name}->{'1'}->{'iologwritesaveragelatency_base'} = $process->{'IOLogWritesAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iologwritespersec'} = $process->{'IOLogWritesPersec'};
	$risc->{$name}->{'1'}->{'logbytesgeneratedpersec'} = $process->{'LogBytesGeneratedPersec'};
	$risc->{$name}->{'1'}->{'logbyteswritepersec'} = $process->{'LogBytesWritePersec'};
	$risc->{$name}->{'1'}->{'logrecordstallspersec'} = $process->{'LogRecordStallsPersec'};
	$risc->{$name}->{'1'}->{'logthreadswaiting'} = $process->{'LogThreadsWaiting'};
	$risc->{$name}->{'1'}->{'logwritespersec'} = $process->{'LogWritesPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'pagesconverted'} = $process->{'PagesConverted'};
	$risc->{$name}->{'1'}->{'pagesconvertedpersec'} = $process->{'PagesConvertedPersec'};
	$risc->{$name}->{'1'}->{'recordsconverted'} = $process->{'RecordsConverted'};
	$risc->{$name}->{'1'}->{'recordsconvertedpersec'} = $process->{'RecordsConvertedPersec'};
	$risc->{$name}->{'1'}->{'sessionsinuse'} = $process->{'SessionsInUse'};
	$risc->{$name}->{'1'}->{'sessionspercentused'} = $process->{'SessionsPercentUsed'};
	$risc->{$name}->{'1'}->{'sessionspercentused_base'} = $process->{'SessionsPercentUsed_Base'};
	$risc->{$name}->{'1'}->{'tableopencachehitspersec'} = $process->{'TableOpenCacheHitsPersec'};
	$risc->{$name}->{'1'}->{'tableopencachemissespersec'} = $process->{'TableOpenCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'tableopencachepercenthit'} = $process->{'TableOpenCachePercentHit'};
	$risc->{$name}->{'1'}->{'tableopencachepercenthit_base'} = $process->{'TableOpenCachePercentHit_Base'};
	$risc->{$name}->{'1'}->{'tableopenspersec'} = $process->{'TableOpensPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'versionbucketsallocated'} = $process->{'VersionBucketsAllocated'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'databasecachemissespersec'} = $process->{'DatabaseCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'databasecachepercentdehydrated'} = $process->{'DatabaseCachePercentDehydrated'};
	$risc->{$name}->{'2'}->{'databasecachepercentdehydrated_base'} = $process->{'DatabaseCachePercentDehydrated_Base'};
	$risc->{$name}->{'2'}->{'databasecachepercenthit'} = $process->{'DatabaseCachePercentHit'};
	$risc->{$name}->{'2'}->{'databasecachepercenthit_base'} = $process->{'DatabaseCachePercentHit_Base'};
	$risc->{$name}->{'2'}->{'databasecacherequestspersec'} = $process->{'DatabaseCacheRequestsPersec'};
	$risc->{$name}->{'2'}->{'databasecachesize'} = $process->{'DatabaseCacheSize'};
	$risc->{$name}->{'2'}->{'databasecachesizeeffective'} = $process->{'DatabaseCacheSizeEffective'};
	$risc->{$name}->{'2'}->{'databasecachesizeeffectivemb'} = $process->{'DatabaseCacheSizeEffectiveMB'};
	$risc->{$name}->{'2'}->{'databasecachesizemb'} = $process->{'DatabaseCacheSizeMB'};
	$risc->{$name}->{'2'}->{'databasecachesizeresident'} = $process->{'DatabaseCacheSizeResident'};
	$risc->{$name}->{'2'}->{'databasecachesizeresidentmb'} = $process->{'DatabaseCacheSizeResidentMB'};
	$risc->{$name}->{'2'}->{'databasemaintenanceduration'} = $process->{'DatabaseMaintenanceDuration'};
	$risc->{$name}->{'2'}->{'databasemaintenancepagesbadchecksums'} = $process->{'DatabaseMaintenancePagesBadChecksums'};
	$risc->{$name}->{'2'}->{'databasepageevictionspersec'} = $process->{'DatabasePageEvictionsPersec'};
	$risc->{$name}->{'2'}->{'databasepagefaultspersec'} = $process->{'DatabasePageFaultsPersec'};
	$risc->{$name}->{'2'}->{'databasepagefaultstallspersec'} = $process->{'DatabasePageFaultStallsPersec'};
	$risc->{$name}->{'2'}->{'defragmentationtasks'} = $process->{'DefragmentationTasks'};
	$risc->{$name}->{'2'}->{'defragmentationtaskspending'} = $process->{'DefragmentationTasksPending'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedaveragelatency'} = $process->{'IODatabaseReadsAttachedAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedaveragelatency_base'} = $process->{'IODatabaseReadsAttachedAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedpersec'} = $process->{'IODatabaseReadsAttachedPersec'};
	$risc->{$name}->{'2'}->{'iodatabasereadsaveragelatency'} = $process->{'IODatabaseReadsAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsaveragelatency_base'} = $process->{'IODatabaseReadsAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadspersec'} = $process->{'IODatabaseReadsPersec'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoveryaveragelatency'} = $process->{'IODatabaseReadsRecoveryAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoveryaveragelatency_base'} = $process->{'IODatabaseReadsRecoveryAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoverypersec'} = $process->{'IODatabaseReadsRecoveryPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedaveragelatency'} = $process->{'IODatabaseWritesAttachedAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedaveragelatency_base'} = $process->{'IODatabaseWritesAttachedAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedpersec'} = $process->{'IODatabaseWritesAttachedPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesaveragelatency'} = $process->{'IODatabaseWritesAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesaveragelatency_base'} = $process->{'IODatabaseWritesAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritespersec'} = $process->{'IODatabaseWritesPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoveryaveragelatency'} = $process->{'IODatabaseWritesRecoveryAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoveryaveragelatency_base'} = $process->{'IODatabaseWritesRecoveryAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoverypersec'} = $process->{'IODatabaseWritesRecoveryPersec'};
	$risc->{$name}->{'2'}->{'iologreadsaveragelatency'} = $process->{'IOLogReadsAverageLatency'};
	$risc->{$name}->{'2'}->{'iologreadsaveragelatency_base'} = $process->{'IOLogReadsAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iologreadspersec'} = $process->{'IOLogReadsPersec'};
	$risc->{$name}->{'2'}->{'iologwritesaveragelatency'} = $process->{'IOLogWritesAverageLatency'};
	$risc->{$name}->{'2'}->{'iologwritesaveragelatency_base'} = $process->{'IOLogWritesAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iologwritespersec'} = $process->{'IOLogWritesPersec'};
	$risc->{$name}->{'2'}->{'logbytesgeneratedpersec'} = $process->{'LogBytesGeneratedPersec'};
	$risc->{$name}->{'2'}->{'logbyteswritepersec'} = $process->{'LogBytesWritePersec'};
	$risc->{$name}->{'2'}->{'logrecordstallspersec'} = $process->{'LogRecordStallsPersec'};
	$risc->{$name}->{'2'}->{'logthreadswaiting'} = $process->{'LogThreadsWaiting'};
	$risc->{$name}->{'2'}->{'logwritespersec'} = $process->{'LogWritesPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'pagesconverted'} = $process->{'PagesConverted'};
	$risc->{$name}->{'2'}->{'pagesconvertedpersec'} = $process->{'PagesConvertedPersec'};
	$risc->{$name}->{'2'}->{'recordsconverted'} = $process->{'RecordsConverted'};
	$risc->{$name}->{'2'}->{'recordsconvertedpersec'} = $process->{'RecordsConvertedPersec'};
	$risc->{$name}->{'2'}->{'sessionsinuse'} = $process->{'SessionsInUse'};
	$risc->{$name}->{'2'}->{'sessionspercentused'} = $process->{'SessionsPercentUsed'};
	$risc->{$name}->{'2'}->{'sessionspercentused_base'} = $process->{'SessionsPercentUsed_Base'};
	$risc->{$name}->{'2'}->{'tableopencachehitspersec'} = $process->{'TableOpenCacheHitsPersec'};
	$risc->{$name}->{'2'}->{'tableopencachemissespersec'} = $process->{'TableOpenCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'tableopencachepercenthit'} = $process->{'TableOpenCachePercentHit'};
	$risc->{$name}->{'2'}->{'tableopencachepercenthit_base'} = $process->{'TableOpenCachePercentHit_Base'};
	$risc->{$name}->{'2'}->{'tableopenspersec'} = $process->{'TableOpensPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'versionbucketsallocated'} = $process->{'VersionBucketsAllocated'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find DatabaseCacheMissesPersec---#	
	my $databasecachemissespersec1 = $risc->{$calname}->{'1'}->{'databasecachemissespersec'};	
#	print "databasecachemissespersec1: $databasecachemissespersec1 \n";	
	my $databasecachemissespersec2 = $risc->{$calname}->{'2'}->{'databasecachemissespersec'};	
#	print "databasecachemissespersec2: $databasecachemissespersec2 \n";	
	eval 	
	{	
	$databasecachemissespersec = perf_counter_counter(	
		$databasecachemissespersec1 #c1
		,$databasecachemissespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasecachemissespersec: $databasecachemissespersec \n";	


	#---find DatabaseCachePercentDehydrated---#	
	my $databasecachepercentdehydrated2 = $risc->{$calname}->{'2'}->{'databasecachepercentdehydrated'};	
#	print "databasecachepercentdehydrated2: $databasecachepercentdehydrated2 \n";	
	my $databasecachepercentdehydrated_base2 = $risc->{$calname}->{'2'}->{'databasecachepercentdehydrated_base'};	
#	print "databasecachepercentdehydrated_base2: $databasecachepercentdehydrated_base2\n";	
	eval 	
	{	
	$databasecachepercentdehydrated = PERF_RAW_FRACTION(	
		$databasecachepercentdehydrated2 #counter value 2
		,$databasecachepercentdehydrated_base2); #base counter value 2
	};	
#	print "databasecachepercentdehydrated: $databasecachepercentdehydrated \n";	


	#---find DatabaseCachePercentHit---#	
	my $databasecachepercenthit1 = $risc->{$calname}->{'1'}->{'databasecachepercenthit'};	
#	print "databasecachepercenthit1: $databasecachepercenthit1 \n";	
	my $databasecachepercenthit2 = $risc->{$calname}->{'2'}->{'databasecachepercenthit'};	
#	print "databasecachepercenthit2: $databasecachepercenthit2 \n";	
	my $databasecachepercenthit_base1 = $risc->{$calname}->{'1'}->{'databasecachepercenthit_base'};	
#	print "databasecachepercenthit_base1: $databasecachepercenthit_base1\n";	
	my $databasecachepercenthit_base2 = $risc->{$calname}->{'2'}->{'databasecachepercenthit_base'};	
#	print "databasecachepercenthit_base2: $databasecachepercenthit_base2\n";	
	eval 	
	{	
	$databasecachepercenthit = PERF_SAMPLE_FRACTION (	
		$databasecachepercenthit1 #counter value 1
		,$databasecachepercenthit2 #counter value 2
		,$databasecachepercenthit_base1 #base counter value 1
		,$databasecachepercenthit_base2); #base counter value 2
	};	
#	print "databasecachepercenthit: $databasecachepercenthit \n";	


	#---find DatabaseCacheRequestsPersec---#	
	my $databasecacherequestspersec1 = $risc->{$calname}->{'1'}->{'databasecacherequestspersec'};	
#	print "databasecacherequestspersec1: $databasecacherequestspersec1 \n";	
	my $databasecacherequestspersec2 = $risc->{$calname}->{'2'}->{'databasecacherequestspersec'};	
#	print "databasecacherequestspersec2: $databasecacherequestspersec2 \n";	
	eval 	
	{	
	$databasecacherequestspersec = perf_counter_counter(	
		$databasecacherequestspersec1 #c1
		,$databasecacherequestspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasecacherequestspersec: $databasecacherequestspersec \n";	


	#---find DatabaseCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesize = $risc->{$calname}->{'2'}->{'databasecachesize'};
#	print "databasecachesize: $databasecachesize \n";


	#---find DatabaseCacheSizeEffective---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizeeffective = $risc->{$calname}->{'2'}->{'databasecachesizeeffective'};
#	print "databasecachesizeeffective: $databasecachesizeeffective \n";


	#---find DatabaseCacheSizeEffectiveMB---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizeeffectivemb = $risc->{$calname}->{'2'}->{'databasecachesizeeffectivemb'};
#	print "databasecachesizeeffectivemb: $databasecachesizeeffectivemb \n";


	#---find DatabaseCacheSizeMB---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizemb = $risc->{$calname}->{'2'}->{'databasecachesizemb'};
#	print "databasecachesizemb: $databasecachesizemb \n";


	#---find DatabaseCacheSizeResident---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizeresident = $risc->{$calname}->{'2'}->{'databasecachesizeresident'};
#	print "databasecachesizeresident: $databasecachesizeresident \n";


	#---find DatabaseCacheSizeResidentMB---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizeresidentmb = $risc->{$calname}->{'2'}->{'databasecachesizeresidentmb'};
#	print "databasecachesizeresidentmb: $databasecachesizeresidentmb \n";


	#---find DatabaseMaintenanceDuration---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$databasemaintenanceduration = $risc->{$calname}->{'2'}->{'databasemaintenanceduration'};
#	print "databasemaintenanceduration: $databasemaintenanceduration \n";


	#---find DatabaseMaintenancePagesBadChecksums---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$databasemaintenancepagesbadchecksums = $risc->{$calname}->{'2'}->{'databasemaintenancepagesbadchecksums'};
#	print "databasemaintenancepagesbadchecksums: $databasemaintenancepagesbadchecksums \n";


	#---find DatabasePageEvictionsPersec---#	
	my $databasepageevictionspersec1 = $risc->{$calname}->{'1'}->{'databasepageevictionspersec'};	
#	print "databasepageevictionspersec1: $databasepageevictionspersec1 \n";	
	my $databasepageevictionspersec2 = $risc->{$calname}->{'2'}->{'databasepageevictionspersec'};	
#	print "databasepageevictionspersec2: $databasepageevictionspersec2 \n";	
	eval 	
	{	
	$databasepageevictionspersec = perf_counter_counter(	
		$databasepageevictionspersec1 #c1
		,$databasepageevictionspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasepageevictionspersec: $databasepageevictionspersec \n";	


	#---find DatabasePageFaultsPersec---#	
	my $databasepagefaultspersec1 = $risc->{$calname}->{'1'}->{'databasepagefaultspersec'};	
#	print "databasepagefaultspersec1: $databasepagefaultspersec1 \n";	
	my $databasepagefaultspersec2 = $risc->{$calname}->{'2'}->{'databasepagefaultspersec'};	
#	print "databasepagefaultspersec2: $databasepagefaultspersec2 \n";	
	eval 	
	{	
	$databasepagefaultspersec = perf_counter_counter(	
		$databasepagefaultspersec1 #c1
		,$databasepagefaultspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasepagefaultspersec: $databasepagefaultspersec \n";	


	#---find DatabasePageFaultStallsPersec---#	
	my $databasepagefaultstallspersec1 = $risc->{$calname}->{'1'}->{'databasepagefaultstallspersec'};	
#	print "databasepagefaultstallspersec1: $databasepagefaultstallspersec1 \n";	
	my $databasepagefaultstallspersec2 = $risc->{$calname}->{'2'}->{'databasepagefaultstallspersec'};	
#	print "databasepagefaultstallspersec2: $databasepagefaultstallspersec2 \n";	
	eval 	
	{	
	$databasepagefaultstallspersec = perf_counter_counter(	
		$databasepagefaultstallspersec1 #c1
		,$databasepagefaultstallspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasepagefaultstallspersec: $databasepagefaultstallspersec \n";	


	#---find DefragmentationTasks---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$defragmentationtasks = $risc->{$calname}->{'2'}->{'defragmentationtasks'};
#	print "defragmentationtasks: $defragmentationtasks \n";


	#---find DefragmentationTasksPending---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$defragmentationtaskspending = $risc->{$calname}->{'2'}->{'defragmentationtaskspending'};
#	print "defragmentationtaskspending: $defragmentationtaskspending \n";


	#---find IODatabaseReadsAttachedAverageLatency---#	
	my $iodatabasereadsattachedaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedaveragelatency'};	
#	print "iodatabasereadsattachedaveragelatency1: $iodatabasereadsattachedaveragelatency1 \n";	
	my $iodatabasereadsattachedaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedaveragelatency'};	
#	print "iodatabasereadsattachedaveragelatency2: $iodatabasereadsattachedaveragelatency2 \n";	
	my $iodatabasereadsattachedaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedaveragelatency_base'};	
#	print "iodatabasereadsattachedaveragelatency_base1: $iodatabasereadsattachedaveragelatency_base1\n";	
	my $iodatabasereadsattachedaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedaveragelatency_base'};	
#	print "iodatabasereadsattachedaveragelatency_base2: $iodatabasereadsattachedaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsattachedaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsattachedaveragelatency1 #counter value 1
		,$iodatabasereadsattachedaveragelatency2 #counter value 2
		,$iodatabasereadsattachedaveragelatency_base1 #base counter value 1
		,$iodatabasereadsattachedaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsattachedaveragelatency: $iodatabasereadsattachedaveragelatency \n";	


	#---find IODatabaseReadsAttachedPersec---#	
	my $iodatabasereadsattachedpersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedpersec'};	
#	print "iodatabasereadsattachedpersec1: $iodatabasereadsattachedpersec1 \n";	
	my $iodatabasereadsattachedpersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedpersec'};	
#	print "iodatabasereadsattachedpersec2: $iodatabasereadsattachedpersec2 \n";	
	eval 	
	{	
	$iodatabasereadsattachedpersec = perf_counter_counter(	
		$iodatabasereadsattachedpersec1 #c1
		,$iodatabasereadsattachedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadsattachedpersec: $iodatabasereadsattachedpersec \n";	


	#---find IODatabaseReadsAverageLatency---#	
	my $iodatabasereadsaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsaveragelatency'};	
#	print "iodatabasereadsaveragelatency1: $iodatabasereadsaveragelatency1 \n";	
	my $iodatabasereadsaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsaveragelatency'};	
#	print "iodatabasereadsaveragelatency2: $iodatabasereadsaveragelatency2 \n";	
	my $iodatabasereadsaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsaveragelatency_base'};	
#	print "iodatabasereadsaveragelatency_base1: $iodatabasereadsaveragelatency_base1\n";	
	my $iodatabasereadsaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsaveragelatency_base'};	
#	print "iodatabasereadsaveragelatency_base2: $iodatabasereadsaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsaveragelatency1 #counter value 1
		,$iodatabasereadsaveragelatency2 #counter value 2
		,$iodatabasereadsaveragelatency_base1 #base counter value 1
		,$iodatabasereadsaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsaveragelatency: $iodatabasereadsaveragelatency \n";	


	#---find IODatabaseReadsPersec---#	
	my $iodatabasereadspersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadspersec'};	
#	print "iodatabasereadspersec1: $iodatabasereadspersec1 \n";	
	my $iodatabasereadspersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadspersec'};	
#	print "iodatabasereadspersec2: $iodatabasereadspersec2 \n";	
	eval 	
	{	
	$iodatabasereadspersec = perf_counter_counter(	
		$iodatabasereadspersec1 #c1
		,$iodatabasereadspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadspersec: $iodatabasereadspersec \n";	


	#---find IODatabaseReadsRecoveryAverageLatency---#	
	my $iodatabasereadsrecoveryaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoveryaveragelatency'};	
#	print "iodatabasereadsrecoveryaveragelatency1: $iodatabasereadsrecoveryaveragelatency1 \n";	
	my $iodatabasereadsrecoveryaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoveryaveragelatency'};	
#	print "iodatabasereadsrecoveryaveragelatency2: $iodatabasereadsrecoveryaveragelatency2 \n";	
	my $iodatabasereadsrecoveryaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoveryaveragelatency_base'};	
#	print "iodatabasereadsrecoveryaveragelatency_base1: $iodatabasereadsrecoveryaveragelatency_base1\n";	
	my $iodatabasereadsrecoveryaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoveryaveragelatency_base'};	
#	print "iodatabasereadsrecoveryaveragelatency_base2: $iodatabasereadsrecoveryaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsrecoveryaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsrecoveryaveragelatency1 #counter value 1
		,$iodatabasereadsrecoveryaveragelatency2 #counter value 2
		,$iodatabasereadsrecoveryaveragelatency_base1 #base counter value 1
		,$iodatabasereadsrecoveryaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsrecoveryaveragelatency: $iodatabasereadsrecoveryaveragelatency \n";	


	#---find IODatabaseReadsRecoveryPersec---#	
	my $iodatabasereadsrecoverypersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoverypersec'};	
#	print "iodatabasereadsrecoverypersec1: $iodatabasereadsrecoverypersec1 \n";	
	my $iodatabasereadsrecoverypersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoverypersec'};	
#	print "iodatabasereadsrecoverypersec2: $iodatabasereadsrecoverypersec2 \n";	
	eval 	
	{	
	$iodatabasereadsrecoverypersec = perf_counter_counter(	
		$iodatabasereadsrecoverypersec1 #c1
		,$iodatabasereadsrecoverypersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadsrecoverypersec: $iodatabasereadsrecoverypersec \n";	


	#---find IODatabaseWritesAttachedAverageLatency---#	
	my $iodatabasewritesattachedaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedaveragelatency'};	
#	print "iodatabasewritesattachedaveragelatency1: $iodatabasewritesattachedaveragelatency1 \n";	
	my $iodatabasewritesattachedaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedaveragelatency'};	
#	print "iodatabasewritesattachedaveragelatency2: $iodatabasewritesattachedaveragelatency2 \n";	
	my $iodatabasewritesattachedaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedaveragelatency_base'};	
#	print "iodatabasewritesattachedaveragelatency_base1: $iodatabasewritesattachedaveragelatency_base1\n";	
	my $iodatabasewritesattachedaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedaveragelatency_base'};	
#	print "iodatabasewritesattachedaveragelatency_base2: $iodatabasewritesattachedaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesattachedaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesattachedaveragelatency1 #counter value 1
		,$iodatabasewritesattachedaveragelatency2 #counter value 2
		,$iodatabasewritesattachedaveragelatency_base1 #base counter value 1
		,$iodatabasewritesattachedaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesattachedaveragelatency: $iodatabasewritesattachedaveragelatency \n";	


	#---find IODatabaseWritesAttachedPersec---#	
	my $iodatabasewritesattachedpersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedpersec'};	
#	print "iodatabasewritesattachedpersec1: $iodatabasewritesattachedpersec1 \n";	
	my $iodatabasewritesattachedpersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedpersec'};	
#	print "iodatabasewritesattachedpersec2: $iodatabasewritesattachedpersec2 \n";	
	eval 	
	{	
	$iodatabasewritesattachedpersec = perf_counter_counter(	
		$iodatabasewritesattachedpersec1 #c1
		,$iodatabasewritesattachedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritesattachedpersec: $iodatabasewritesattachedpersec \n";	


	#---find IODatabaseWritesAverageLatency---#	
	my $iodatabasewritesaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesaveragelatency'};	
#	print "iodatabasewritesaveragelatency1: $iodatabasewritesaveragelatency1 \n";	
	my $iodatabasewritesaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesaveragelatency'};	
#	print "iodatabasewritesaveragelatency2: $iodatabasewritesaveragelatency2 \n";	
	my $iodatabasewritesaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesaveragelatency_base'};	
#	print "iodatabasewritesaveragelatency_base1: $iodatabasewritesaveragelatency_base1\n";	
	my $iodatabasewritesaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesaveragelatency_base'};	
#	print "iodatabasewritesaveragelatency_base2: $iodatabasewritesaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesaveragelatency1 #counter value 1
		,$iodatabasewritesaveragelatency2 #counter value 2
		,$iodatabasewritesaveragelatency_base1 #base counter value 1
		,$iodatabasewritesaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesaveragelatency: $iodatabasewritesaveragelatency \n";	


	#---find IODatabaseWritesPersec---#	
	my $iodatabasewritespersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritespersec'};	
#	print "iodatabasewritespersec1: $iodatabasewritespersec1 \n";	
	my $iodatabasewritespersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritespersec'};	
#	print "iodatabasewritespersec2: $iodatabasewritespersec2 \n";	
	eval 	
	{	
	$iodatabasewritespersec = perf_counter_counter(	
		$iodatabasewritespersec1 #c1
		,$iodatabasewritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritespersec: $iodatabasewritespersec \n";	


	#---find IODatabaseWritesRecoveryAverageLatency---#	
	my $iodatabasewritesrecoveryaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoveryaveragelatency'};	
#	print "iodatabasewritesrecoveryaveragelatency1: $iodatabasewritesrecoveryaveragelatency1 \n";	
	my $iodatabasewritesrecoveryaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoveryaveragelatency'};	
#	print "iodatabasewritesrecoveryaveragelatency2: $iodatabasewritesrecoveryaveragelatency2 \n";	
	my $iodatabasewritesrecoveryaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoveryaveragelatency_base'};	
#	print "iodatabasewritesrecoveryaveragelatency_base1: $iodatabasewritesrecoveryaveragelatency_base1\n";	
	my $iodatabasewritesrecoveryaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoveryaveragelatency_base'};	
#	print "iodatabasewritesrecoveryaveragelatency_base2: $iodatabasewritesrecoveryaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesrecoveryaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesrecoveryaveragelatency1 #counter value 1
		,$iodatabasewritesrecoveryaveragelatency2 #counter value 2
		,$iodatabasewritesrecoveryaveragelatency_base1 #base counter value 1
		,$iodatabasewritesrecoveryaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesrecoveryaveragelatency: $iodatabasewritesrecoveryaveragelatency \n";	


	#---find IODatabaseWritesRecoveryPersec---#	
	my $iodatabasewritesrecoverypersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoverypersec'};	
#	print "iodatabasewritesrecoverypersec1: $iodatabasewritesrecoverypersec1 \n";	
	my $iodatabasewritesrecoverypersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoverypersec'};	
#	print "iodatabasewritesrecoverypersec2: $iodatabasewritesrecoverypersec2 \n";	
	eval 	
	{	
	$iodatabasewritesrecoverypersec = perf_counter_counter(	
		$iodatabasewritesrecoverypersec1 #c1
		,$iodatabasewritesrecoverypersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritesrecoverypersec: $iodatabasewritesrecoverypersec \n";	


	#---find IOLogReadsAverageLatency---#	
	my $iologreadsaveragelatency1 = $risc->{$calname}->{'1'}->{'iologreadsaveragelatency'};	
#	print "iologreadsaveragelatency1: $iologreadsaveragelatency1 \n";	
	my $iologreadsaveragelatency2 = $risc->{$calname}->{'2'}->{'iologreadsaveragelatency'};	
#	print "iologreadsaveragelatency2: $iologreadsaveragelatency2 \n";	
	my $iologreadsaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iologreadsaveragelatency_base'};	
#	print "iologreadsaveragelatency_base1: $iologreadsaveragelatency_base1\n";	
	my $iologreadsaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iologreadsaveragelatency_base'};	
#	print "iologreadsaveragelatency_base2: $iologreadsaveragelatency_base2\n";	
	eval 	
	{	
	$iologreadsaveragelatency = PERF_AVERAGE_BULK(	
		$iologreadsaveragelatency1 #counter value 1
		,$iologreadsaveragelatency2 #counter value 2
		,$iologreadsaveragelatency_base1 #base counter value 1
		,$iologreadsaveragelatency_base2); #base counter value 2
	};	
#	print "iologreadsaveragelatency: $iologreadsaveragelatency \n";	


	#---find IOLogReadsPersec---#	
	my $iologreadspersec1 = $risc->{$calname}->{'1'}->{'iologreadspersec'};	
#	print "iologreadspersec1: $iologreadspersec1 \n";	
	my $iologreadspersec2 = $risc->{$calname}->{'2'}->{'iologreadspersec'};	
#	print "iologreadspersec2: $iologreadspersec2 \n";	
	eval 	
	{	
	$iologreadspersec = perf_counter_counter(	
		$iologreadspersec1 #c1
		,$iologreadspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iologreadspersec: $iologreadspersec \n";	


	#---find IOLogWritesAverageLatency---#	
	my $iologwritesaveragelatency1 = $risc->{$calname}->{'1'}->{'iologwritesaveragelatency'};	
#	print "iologwritesaveragelatency1: $iologwritesaveragelatency1 \n";	
	my $iologwritesaveragelatency2 = $risc->{$calname}->{'2'}->{'iologwritesaveragelatency'};	
#	print "iologwritesaveragelatency2: $iologwritesaveragelatency2 \n";	
	my $iologwritesaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iologwritesaveragelatency_base'};	
#	print "iologwritesaveragelatency_base1: $iologwritesaveragelatency_base1\n";	
	my $iologwritesaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iologwritesaveragelatency_base'};	
#	print "iologwritesaveragelatency_base2: $iologwritesaveragelatency_base2\n";	
	eval 	
	{	
	$iologwritesaveragelatency = PERF_AVERAGE_BULK(	
		$iologwritesaveragelatency1 #counter value 1
		,$iologwritesaveragelatency2 #counter value 2
		,$iologwritesaveragelatency_base1 #base counter value 1
		,$iologwritesaveragelatency_base2); #base counter value 2
	};	
#	print "iologwritesaveragelatency: $iologwritesaveragelatency \n";	


	#---find IOLogWritesPersec---#	
	my $iologwritespersec1 = $risc->{$calname}->{'1'}->{'iologwritespersec'};	
#	print "iologwritespersec1: $iologwritespersec1 \n";	
	my $iologwritespersec2 = $risc->{$calname}->{'2'}->{'iologwritespersec'};	
#	print "iologwritespersec2: $iologwritespersec2 \n";	
	eval 	
	{	
	$iologwritespersec = perf_counter_counter(	
		$iologwritespersec1 #c1
		,$iologwritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iologwritespersec: $iologwritespersec \n";	


	#---find LogBytesGeneratedPersec---#	
	my $logbytesgeneratedpersec1 = $risc->{$calname}->{'1'}->{'logbytesgeneratedpersec'};	
#	print "logbytesgeneratedpersec1: $logbytesgeneratedpersec1 \n";	
	my $logbytesgeneratedpersec2 = $risc->{$calname}->{'2'}->{'logbytesgeneratedpersec'};	
#	print "logbytesgeneratedpersec2: $logbytesgeneratedpersec2 \n";	
	eval 	
	{	
	$logbytesgeneratedpersec = perf_counter_counter(	
		$logbytesgeneratedpersec1 #c1
		,$logbytesgeneratedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logbytesgeneratedpersec: $logbytesgeneratedpersec \n";	


	#---find LogBytesWritePersec---#	
	my $logbyteswritepersec1 = $risc->{$calname}->{'1'}->{'logbyteswritepersec'};	
#	print "logbyteswritepersec1: $logbyteswritepersec1 \n";	
	my $logbyteswritepersec2 = $risc->{$calname}->{'2'}->{'logbyteswritepersec'};	
#	print "logbyteswritepersec2: $logbyteswritepersec2 \n";	
	eval 	
	{	
	$logbyteswritepersec = perf_counter_counter(	
		$logbyteswritepersec1 #c1
		,$logbyteswritepersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logbyteswritepersec: $logbyteswritepersec \n";	


	#---find LogRecordStallsPersec---#	
	my $logrecordstallspersec1 = $risc->{$calname}->{'1'}->{'logrecordstallspersec'};	
#	print "logrecordstallspersec1: $logrecordstallspersec1 \n";	
	my $logrecordstallspersec2 = $risc->{$calname}->{'2'}->{'logrecordstallspersec'};	
#	print "logrecordstallspersec2: $logrecordstallspersec2 \n";	
	eval 	
	{	
	$logrecordstallspersec = perf_counter_counter(	
		$logrecordstallspersec1 #c1
		,$logrecordstallspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logrecordstallspersec: $logrecordstallspersec \n";	


	#---find LogThreadsWaiting---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$logthreadswaiting = $risc->{$calname}->{'2'}->{'logthreadswaiting'};
#	print "logthreadswaiting: $logthreadswaiting \n";


	#---find LogWritesPersec---#	
	my $logwritespersec1 = $risc->{$calname}->{'1'}->{'logwritespersec'};	
#	print "logwritespersec1: $logwritespersec1 \n";	
	my $logwritespersec2 = $risc->{$calname}->{'2'}->{'logwritespersec'};	
#	print "logwritespersec2: $logwritespersec2 \n";	
	eval 	
	{	
	$logwritespersec = perf_counter_counter(	
		$logwritespersec1 #c1
		,$logwritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logwritespersec: $logwritespersec \n";	


	#---find PagesConverted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$pagesconverted = $risc->{$calname}->{'2'}->{'pagesconverted'};
#	print "pagesconverted: $pagesconverted \n";


	#---find PagesConvertedPersec---#	
	my $pagesconvertedpersec1 = $risc->{$calname}->{'1'}->{'pagesconvertedpersec'};	
#	print "pagesconvertedpersec1: $pagesconvertedpersec1 \n";	
	my $pagesconvertedpersec2 = $risc->{$calname}->{'2'}->{'pagesconvertedpersec'};	
#	print "pagesconvertedpersec2: $pagesconvertedpersec2 \n";	
	eval 	
	{	
	$pagesconvertedpersec = perf_counter_counter(	
		$pagesconvertedpersec1 #c1
		,$pagesconvertedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "pagesconvertedpersec: $pagesconvertedpersec \n";	


	#---find RecordsConverted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$recordsconverted = $risc->{$calname}->{'2'}->{'recordsconverted'};
#	print "recordsconverted: $recordsconverted \n";


	#---find RecordsConvertedPersec---#	
	my $recordsconvertedpersec1 = $risc->{$calname}->{'1'}->{'recordsconvertedpersec'};	
#	print "recordsconvertedpersec1: $recordsconvertedpersec1 \n";	
	my $recordsconvertedpersec2 = $risc->{$calname}->{'2'}->{'recordsconvertedpersec'};	
#	print "recordsconvertedpersec2: $recordsconvertedpersec2 \n";	
	eval 	
	{	
	$recordsconvertedpersec = perf_counter_counter(	
		$recordsconvertedpersec1 #c1
		,$recordsconvertedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "recordsconvertedpersec: $recordsconvertedpersec \n";	


	#---find SessionsInUse---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$sessionsinuse = $risc->{$calname}->{'2'}->{'sessionsinuse'};
#	print "sessionsinuse: $sessionsinuse \n";


	#---find SessionsPercentUsed---#	
	my $sessionspercentused2 = $risc->{$calname}->{'2'}->{'sessionspercentused'};	
#	print "sessionspercentused2: $sessionspercentused2 \n";	
	my $sessionspercentused_base2 = $risc->{$calname}->{'2'}->{'sessionspercentused_base'};	
#	print "sessionspercentused_base2: $sessionspercentused_base2\n";	
	eval 	
	{	
	$sessionspercentused = PERF_RAW_FRACTION(	
		$sessionspercentused2 #counter value 2
		,$sessionspercentused_base2); #base counter value 2
	};	
#	print "sessionspercentused: $sessionspercentused \n";	


	#---find TableOpenCacheHitsPersec---#	
	my $tableopencachehitspersec1 = $risc->{$calname}->{'1'}->{'tableopencachehitspersec'};	
#	print "tableopencachehitspersec1: $tableopencachehitspersec1 \n";	
	my $tableopencachehitspersec2 = $risc->{$calname}->{'2'}->{'tableopencachehitspersec'};	
#	print "tableopencachehitspersec2: $tableopencachehitspersec2 \n";	
	eval 	
	{	
	$tableopencachehitspersec = perf_counter_counter(	
		$tableopencachehitspersec1 #c1
		,$tableopencachehitspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopencachehitspersec: $tableopencachehitspersec \n";	


	#---find TableOpenCacheMissesPersec---#	
	my $tableopencachemissespersec1 = $risc->{$calname}->{'1'}->{'tableopencachemissespersec'};	
#	print "tableopencachemissespersec1: $tableopencachemissespersec1 \n";	
	my $tableopencachemissespersec2 = $risc->{$calname}->{'2'}->{'tableopencachemissespersec'};	
#	print "tableopencachemissespersec2: $tableopencachemissespersec2 \n";	
	eval 	
	{	
	$tableopencachemissespersec = perf_counter_counter(	
		$tableopencachemissespersec1 #c1
		,$tableopencachemissespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopencachemissespersec: $tableopencachemissespersec \n";	


	#---find TableOpenCachePercentHit---#	
	my $tableopencachepercenthit1 = $risc->{$calname}->{'1'}->{'tableopencachepercenthit'};	
#	print "tableopencachepercenthit1: $tableopencachepercenthit1 \n";	
	my $tableopencachepercenthit2 = $risc->{$calname}->{'2'}->{'tableopencachepercenthit'};	
#	print "tableopencachepercenthit2: $tableopencachepercenthit2 \n";	
	my $tableopencachepercenthit_base1 = $risc->{$calname}->{'1'}->{'tableopencachepercenthit_base'};	
#	print "tableopencachepercenthit_base1: $tableopencachepercenthit_base1\n";	
	my $tableopencachepercenthit_base2 = $risc->{$calname}->{'2'}->{'tableopencachepercenthit_base'};	
#	print "tableopencachepercenthit_base2: $tableopencachepercenthit_base2\n";	
	eval 	
	{	
	$tableopencachepercenthit = PERF_SAMPLE_FRACTION (	
		$tableopencachepercenthit1 #counter value 1
		,$tableopencachepercenthit2 #counter value 2
		,$tableopencachepercenthit_base1 #base counter value 1
		,$tableopencachepercenthit_base2); #base counter value 2
	};	
#	print "tableopencachepercenthit: $tableopencachepercenthit \n";	


	#---find TableOpensPersec---#	
	my $tableopenspersec1 = $risc->{$calname}->{'1'}->{'tableopenspersec'};	
#	print "tableopenspersec1: $tableopenspersec1 \n";	
	my $tableopenspersec2 = $risc->{$calname}->{'2'}->{'tableopenspersec'};	
#	print "tableopenspersec2: $tableopenspersec2 \n";	
	eval 	
	{	
	$tableopenspersec = perf_counter_counter(	
		$tableopenspersec1 #c1
		,$tableopenspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopenspersec: $tableopenspersec \n";	


	#---find VersionBucketsAllocated---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$versionbucketsallocated = $risc->{$calname}->{'2'}->{'versionbucketsallocated'};
#	print "versionbucketsallocated: $versionbucketsallocated \n";

######################################################################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$caption
	,$databasecachemissespersec
	,$databasecachepercentdehydrated
	,$databasecachepercenthit
	,$databasecacherequestspersec
	,$databasecachesize
	,$databasecachesizeeffective
	,$databasecachesizeeffectivemb
	,$databasecachesizemb
	,$databasecachesizeresident
	,$databasecachesizeresidentmb
	,$databasemaintenanceduration
	,$databasemaintenancepagesbadchecksums
	,$databasepageevictionspersec
	,$databasepagefaultspersec
	,$databasepagefaultstallspersec
	,$defragmentationtasks
	,$defragmentationtaskspending
	,$description
	,$iodatabasereadsattachedaveragelatency
	,$iodatabasereadsattachedpersec
	,$iodatabasereadsaveragelatency
	,$iodatabasereadspersec
	,$iodatabasereadsrecoveryaveragelatency
	,$iodatabasereadsrecoverypersec
	,$iodatabasewritesattachedaveragelatency
	,$iodatabasewritesattachedpersec
	,$iodatabasewritesaveragelatency
	,$iodatabasewritespersec
	,$iodatabasewritesrecoveryaveragelatency
	,$iodatabasewritesrecoverypersec
	,$iologreadsaveragelatency
	,$iologreadspersec
	,$iologwritesaveragelatency
	,$iologwritespersec
	,$logbytesgeneratedpersec
	,$logbyteswritepersec
	,$logrecordstallspersec
	,$logthreadswaiting
	,$logwritespersec
	,$tablename
	,$pagesconverted
	,$pagesconvertedpersec
	,$recordsconverted
	,$recordsconvertedpersec
	,$sessionsinuse
	,$sessionspercentused
	,$tableopencachehitspersec
	,$tableopencachemissespersec
	,$tableopencachepercenthit
	,$tableopenspersec
	,$versionbucketsallocated
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeDatabaseInstances
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchdatainstances (
	deviceid
	,scantime
	,caption
	,databasecachemissespersec
	,databasecachepercenthit
	,databasecacherequestspersec
	,databasecachesizemb
	,databasemaintenanceduration
	,databasemaintenancepagesbadchecksums
	,defragmentationtasks
	,defragmentationtaskspending
	,description
	,iodatabasereadsattachedaveragelatency
	,iodatabasereadsattachedpersec
	,iodatabasereadsaveragelatency
	,iodatabasereadspersec
	,iodatabasereadsrecoveryaveragelatency
	,iodatabasereadsrecoverypersec
	,iodatabasewritesattachedaveragelatency
	,iodatabasewritesattachedpersec
	,iodatabasewritesaveragelatency
	,iodatabasewritespersec
	,iodatabasewritesrecoveryaveragelatency
	,iodatabasewritesrecoverypersec
	,iologreadsaveragelatency
	,iologreadspersec
	,iologwritesaveragelatency
	,iologwritespersec
	,logbytesgeneratedpersec
	,logbyteswritepersec
	,logcheckpointdepthasapercentoftarget
	,logfilecurrentgeneration
	,logfilesgenerated
	,logfilesgeneratedprematurely
	,loggenerationcheckpointdepth
	,loggenerationcheckpointdepthmax
	,loggenerationcheckpointdepthtarget
	,loggenerationlossresiliencydepth
	,logrecordstallspersec
	,logthreadswaiting
	,logwritespersec
	,name
	,pagesconverted
	,pagesconvertedpersec
	,recordsconverted
	,recordsconvertedpersec
	,sessionsinuse
	,sessionspercentused
	,streamingbackuppagesreadpersec
	,tableopencachehitspersec
	,tableopencachemissespersec
	,tableopencachepercenthit
	,tableopenspersec
	,versionbucketsallocated
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $caption = undef;
my $databasecachemissespersec = undef;
my $databasecachepercenthit = undef;
my $databasecacherequestspersec = undef;
my $databasecachesizemb = undef;
my $databasemaintenanceduration = undef;
my $databasemaintenancepagesbadchecksums = undef;
my $defragmentationtasks = undef;
my $defragmentationtaskspending = undef;
my $description = undef;
my $iodatabasereadsattachedaveragelatency = undef;
my $iodatabasereadsattachedpersec = undef;
my $iodatabasereadsaveragelatency = undef;
my $iodatabasereadspersec = undef;
my $iodatabasereadsrecoveryaveragelatency = undef;
my $iodatabasereadsrecoverypersec = undef;
my $iodatabasewritesattachedaveragelatency = undef;
my $iodatabasewritesattachedpersec = undef;
my $iodatabasewritesaveragelatency = undef;
my $iodatabasewritespersec = undef;
my $iodatabasewritesrecoveryaveragelatency = undef;
my $iodatabasewritesrecoverypersec = undef;
my $iologreadsaveragelatency = undef;
my $iologreadspersec = undef;
my $iologwritesaveragelatency = undef;
my $iologwritespersec = undef;
my $logbytesgeneratedpersec = undef;
my $logbyteswritepersec = undef;
my $logcheckpointdepthasapercentoftarget = undef;
my $logfilecurrentgeneration = undef;
my $logfilesgenerated = undef;
my $logfilesgeneratedprematurely = undef;
my $loggenerationcheckpointdepth = undef;
my $loggenerationcheckpointdepthmax = undef;
my $loggenerationcheckpointdepthtarget = undef;
my $loggenerationlossresiliencydepth = undef;
my $logrecordstallspersec = undef;
my $logthreadswaiting = undef;
my $logwritespersec = undef;
my $tablename = undef;
my $pagesconverted = undef;
my $pagesconvertedpersec = undef;
my $recordsconverted = undef;
my $recordsconvertedpersec = undef;
my $sessionsinuse = undef;
my $sessionspercentused = undef;
my $streamingbackuppagesreadpersec = undef;
my $tableopencachehitspersec = undef;
my $tableopencachemissespersec = undef;
my $tableopencachepercenthit = undef;
my $tableopenspersec = undef;
my $versionbucketsallocated = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'databasecachemissespersec'} = $process->{'DatabaseCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'databasecachepercenthit'} = $process->{'DatabaseCachePercentHit'};
	$risc->{$name}->{'1'}->{'databasecachepercenthit_base'} = $process->{'DatabaseCachePercentHit_Base'};
	$risc->{$name}->{'1'}->{'databasecacherequestspersec'} = $process->{'DatabaseCacheRequestsPersec'};
	$risc->{$name}->{'1'}->{'databasecachesizemb'} = $process->{'DatabaseCacheSizeMB'};
	$risc->{$name}->{'1'}->{'databasemaintenanceduration'} = $process->{'DatabaseMaintenanceDuration'};
	$risc->{$name}->{'1'}->{'databasemaintenancepagesbadchecksums'} = $process->{'DatabaseMaintenancePagesBadChecksums'};
	$risc->{$name}->{'1'}->{'defragmentationtasks'} = $process->{'DefragmentationTasks'};
	$risc->{$name}->{'1'}->{'defragmentationtaskspending'} = $process->{'DefragmentationTasksPending'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedaveragelatency'} = $process->{'IODatabaseReadsAttachedAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedaveragelatency_base'} = $process->{'IODatabaseReadsAttachedAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadsattachedpersec'} = $process->{'IODatabaseReadsAttachedPersec'};
	$risc->{$name}->{'1'}->{'iodatabasereadsaveragelatency'} = $process->{'IODatabaseReadsAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsaveragelatency_base'} = $process->{'IODatabaseReadsAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadspersec'} = $process->{'IODatabaseReadsPersec'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoveryaveragelatency'} = $process->{'IODatabaseReadsRecoveryAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoveryaveragelatency_base'} = $process->{'IODatabaseReadsRecoveryAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasereadsrecoverypersec'} = $process->{'IODatabaseReadsRecoveryPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedaveragelatency'} = $process->{'IODatabaseWritesAttachedAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedaveragelatency_base'} = $process->{'IODatabaseWritesAttachedAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritesattachedpersec'} = $process->{'IODatabaseWritesAttachedPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesaveragelatency'} = $process->{'IODatabaseWritesAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesaveragelatency_base'} = $process->{'IODatabaseWritesAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritespersec'} = $process->{'IODatabaseWritesPersec'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoveryaveragelatency'} = $process->{'IODatabaseWritesRecoveryAverageLatency'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoveryaveragelatency_base'} = $process->{'IODatabaseWritesRecoveryAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iodatabasewritesrecoverypersec'} = $process->{'IODatabaseWritesRecoveryPersec'};
	$risc->{$name}->{'1'}->{'iologreadsaveragelatency'} = $process->{'IOLogReadsAverageLatency'};
	$risc->{$name}->{'1'}->{'iologreadsaveragelatency_base'} = $process->{'IOLogReadsAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iologreadspersec'} = $process->{'IOLogReadsPersec'};
	$risc->{$name}->{'1'}->{'iologwritesaveragelatency'} = $process->{'IOLogWritesAverageLatency'};
	$risc->{$name}->{'1'}->{'iologwritesaveragelatency_base'} = $process->{'IOLogWritesAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'iologwritespersec'} = $process->{'IOLogWritesPersec'};
	$risc->{$name}->{'1'}->{'logbytesgeneratedpersec'} = $process->{'LogBytesGeneratedPersec'};
	$risc->{$name}->{'1'}->{'logbyteswritepersec'} = $process->{'LogBytesWritePersec'};
	$risc->{$name}->{'1'}->{'logcheckpointdepthasapercentoftarget'} = $process->{'LogCheckpointDepthasaPercentofTarget'};
	$risc->{$name}->{'1'}->{'logcheckpointdepthasapercentoftarget_base'} = $process->{'LogCheckpointDepthasaPercentofTarget_Base'};
	$risc->{$name}->{'1'}->{'logfilecurrentgeneration'} = $process->{'LogFileCurrentGeneration'};
	$risc->{$name}->{'1'}->{'logfilesgenerated'} = $process->{'LogFilesGenerated'};
	$risc->{$name}->{'1'}->{'logfilesgeneratedprematurely'} = $process->{'LogFilesGeneratedPrematurely'};
	$risc->{$name}->{'1'}->{'loggenerationcheckpointdepth'} = $process->{'LogGenerationCheckpointDepth'};
	$risc->{$name}->{'1'}->{'loggenerationcheckpointdepthmax'} = $process->{'LogGenerationCheckpointDepthMax'};
	$risc->{$name}->{'1'}->{'loggenerationcheckpointdepthtarget'} = $process->{'LogGenerationCheckpointDepthTarget'};
	$risc->{$name}->{'1'}->{'loggenerationlossresiliencydepth'} = $process->{'LogGenerationLossResiliencyDepth'};
	$risc->{$name}->{'1'}->{'logrecordstallspersec'} = $process->{'LogRecordStallsPersec'};
	$risc->{$name}->{'1'}->{'logthreadswaiting'} = $process->{'LogThreadsWaiting'};
	$risc->{$name}->{'1'}->{'logwritespersec'} = $process->{'LogWritesPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'pagesconverted'} = $process->{'PagesConverted'};
	$risc->{$name}->{'1'}->{'pagesconvertedpersec'} = $process->{'PagesConvertedPersec'};
	$risc->{$name}->{'1'}->{'recordsconverted'} = $process->{'RecordsConverted'};
	$risc->{$name}->{'1'}->{'recordsconvertedpersec'} = $process->{'RecordsConvertedPersec'};
	$risc->{$name}->{'1'}->{'sessionsinuse'} = $process->{'SessionsInUse'};
	$risc->{$name}->{'1'}->{'sessionspercentused'} = $process->{'SessionsPercentUsed'};
	$risc->{$name}->{'1'}->{'sessionspercentused_base'} = $process->{'SessionsPercentUsed_Base'};
	$risc->{$name}->{'1'}->{'streamingbackuppagesreadpersec'} = $process->{'StreamingBackupPagesReadPersec'};
	$risc->{$name}->{'1'}->{'tableopencachehitspersec'} = $process->{'TableOpenCacheHitsPersec'};
	$risc->{$name}->{'1'}->{'tableopencachemissespersec'} = $process->{'TableOpenCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'tableopencachepercenthit'} = $process->{'TableOpenCachePercentHit'};
	$risc->{$name}->{'1'}->{'tableopencachepercenthit_base'} = $process->{'TableOpenCachePercentHit_Base'};
	$risc->{$name}->{'1'}->{'tableopenspersec'} = $process->{'TableOpensPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'versionbucketsallocated'} = $process->{'Versionbucketsallocated'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'databasecachemissespersec'} = $process->{'DatabaseCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'databasecachepercenthit'} = $process->{'DatabaseCachePercentHit'};
	$risc->{$name}->{'2'}->{'databasecachepercenthit_base'} = $process->{'DatabaseCachePercentHit_Base'};
	$risc->{$name}->{'2'}->{'databasecacherequestspersec'} = $process->{'DatabaseCacheRequestsPersec'};
	$risc->{$name}->{'2'}->{'databasecachesizemb'} = $process->{'DatabaseCacheSizeMB'};
	$risc->{$name}->{'2'}->{'databasemaintenanceduration'} = $process->{'DatabaseMaintenanceDuration'};
	$risc->{$name}->{'2'}->{'databasemaintenancepagesbadchecksums'} = $process->{'DatabaseMaintenancePagesBadChecksums'};
	$risc->{$name}->{'2'}->{'defragmentationtasks'} = $process->{'DefragmentationTasks'};
	$risc->{$name}->{'2'}->{'defragmentationtaskspending'} = $process->{'DefragmentationTasksPending'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedaveragelatency'} = $process->{'IODatabaseReadsAttachedAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedaveragelatency_base'} = $process->{'IODatabaseReadsAttachedAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadsattachedpersec'} = $process->{'IODatabaseReadsAttachedPersec'};
	$risc->{$name}->{'2'}->{'iodatabasereadsaveragelatency'} = $process->{'IODatabaseReadsAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsaveragelatency_base'} = $process->{'IODatabaseReadsAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadspersec'} = $process->{'IODatabaseReadsPersec'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoveryaveragelatency'} = $process->{'IODatabaseReadsRecoveryAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoveryaveragelatency_base'} = $process->{'IODatabaseReadsRecoveryAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasereadsrecoverypersec'} = $process->{'IODatabaseReadsRecoveryPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedaveragelatency'} = $process->{'IODatabaseWritesAttachedAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedaveragelatency_base'} = $process->{'IODatabaseWritesAttachedAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritesattachedpersec'} = $process->{'IODatabaseWritesAttachedPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesaveragelatency'} = $process->{'IODatabaseWritesAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesaveragelatency_base'} = $process->{'IODatabaseWritesAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritespersec'} = $process->{'IODatabaseWritesPersec'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoveryaveragelatency'} = $process->{'IODatabaseWritesRecoveryAverageLatency'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoveryaveragelatency_base'} = $process->{'IODatabaseWritesRecoveryAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iodatabasewritesrecoverypersec'} = $process->{'IODatabaseWritesRecoveryPersec'};
	$risc->{$name}->{'2'}->{'iologreadsaveragelatency'} = $process->{'IOLogReadsAverageLatency'};
	$risc->{$name}->{'2'}->{'iologreadsaveragelatency_base'} = $process->{'IOLogReadsAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iologreadspersec'} = $process->{'IOLogReadsPersec'};
	$risc->{$name}->{'2'}->{'iologwritesaveragelatency'} = $process->{'IOLogWritesAverageLatency'};
	$risc->{$name}->{'2'}->{'iologwritesaveragelatency_base'} = $process->{'IOLogWritesAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'iologwritespersec'} = $process->{'IOLogWritesPersec'};
	$risc->{$name}->{'2'}->{'logbytesgeneratedpersec'} = $process->{'LogBytesGeneratedPersec'};
	$risc->{$name}->{'2'}->{'logbyteswritepersec'} = $process->{'LogBytesWritePersec'};
	$risc->{$name}->{'2'}->{'logcheckpointdepthasapercentoftarget'} = $process->{'LogCheckpointDepthasaPercentofTarget'};
	$risc->{$name}->{'2'}->{'logcheckpointdepthasapercentoftarget_base'} = $process->{'LogCheckpointDepthasaPercentofTarget_Base'};
	$risc->{$name}->{'2'}->{'logfilecurrentgeneration'} = $process->{'LogFileCurrentGeneration'};
	$risc->{$name}->{'2'}->{'logfilesgenerated'} = $process->{'LogFilesGenerated'};
	$risc->{$name}->{'2'}->{'logfilesgeneratedprematurely'} = $process->{'LogFilesGeneratedPrematurely'};
	$risc->{$name}->{'2'}->{'loggenerationcheckpointdepth'} = $process->{'LogGenerationCheckpointDepth'};
	$risc->{$name}->{'2'}->{'loggenerationcheckpointdepthmax'} = $process->{'LogGenerationCheckpointDepthMax'};
	$risc->{$name}->{'2'}->{'loggenerationcheckpointdepthtarget'} = $process->{'LogGenerationCheckpointDepthTarget'};
	$risc->{$name}->{'2'}->{'loggenerationlossresiliencydepth'} = $process->{'LogGenerationLossResiliencyDepth'};
	$risc->{$name}->{'2'}->{'logrecordstallspersec'} = $process->{'LogRecordStallsPersec'};
	$risc->{$name}->{'2'}->{'logthreadswaiting'} = $process->{'LogThreadsWaiting'};
	$risc->{$name}->{'2'}->{'logwritespersec'} = $process->{'LogWritesPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'pagesconverted'} = $process->{'PagesConverted'};
	$risc->{$name}->{'2'}->{'pagesconvertedpersec'} = $process->{'PagesConvertedPersec'};
	$risc->{$name}->{'2'}->{'recordsconverted'} = $process->{'RecordsConverted'};
	$risc->{$name}->{'2'}->{'recordsconvertedpersec'} = $process->{'RecordsConvertedPersec'};
	$risc->{$name}->{'2'}->{'sessionsinuse'} = $process->{'SessionsInUse'};
	$risc->{$name}->{'2'}->{'sessionspercentused'} = $process->{'SessionsPercentUsed'};
	$risc->{$name}->{'2'}->{'sessionspercentused_base'} = $process->{'SessionsPercentUsed_Base'};
	$risc->{$name}->{'2'}->{'streamingbackuppagesreadpersec'} = $process->{'StreamingBackupPagesReadPersec'};
	$risc->{$name}->{'2'}->{'tableopencachehitspersec'} = $process->{'TableOpenCacheHitsPersec'};
	$risc->{$name}->{'2'}->{'tableopencachemissespersec'} = $process->{'TableOpenCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'tableopencachepercenthit'} = $process->{'TableOpenCachePercentHit'};
	$risc->{$name}->{'2'}->{'tableopencachepercenthit_base'} = $process->{'TableOpenCachePercentHit_Base'};
	$risc->{$name}->{'2'}->{'tableopenspersec'} = $process->{'TableOpensPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'versionbucketsallocated'} = $process->{'Versionbucketsallocated'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};


	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find DatabaseCacheMissesPersec---#	
	my $databasecachemissespersec1 = $risc->{$calname}->{'1'}->{'databasecachemissespersec'};	
#	print "databasecachemissespersec1: $databasecachemissespersec1 \n";	
	my $databasecachemissespersec2 = $risc->{$calname}->{'2'}->{'databasecachemissespersec'};	
#	print "databasecachemissespersec2: $databasecachemissespersec2 \n";	
	eval 	
	{	
	$databasecachemissespersec = perf_counter_counter(	
		$databasecachemissespersec1 #c1
		,$databasecachemissespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasecachemissespersec: $databasecachemissespersec \n";	


	#---find DatabaseCachePercentHit---#	
	my $databasecachepercenthit1 = $risc->{$calname}->{'1'}->{'databasecachepercenthit'};	
#	print "databasecachepercenthit1: $databasecachepercenthit1 \n";	
	my $databasecachepercenthit2 = $risc->{$calname}->{'2'}->{'databasecachepercenthit'};	
#	print "databasecachepercenthit2: $databasecachepercenthit2 \n";	
	my $databasecachepercenthit_base1 = $risc->{$calname}->{'1'}->{'databasecachepercenthit_base'};	
#	print "databasecachepercenthit_base1: $databasecachepercenthit_base1\n";	
	my $databasecachepercenthit_base2 = $risc->{$calname}->{'2'}->{'databasecachepercenthit_base'};	
#	print "databasecachepercenthit_base2: $databasecachepercenthit_base2\n";	
	eval 	
	{	
	$databasecachepercenthit = PERF_SAMPLE_FRACTION (	
		$databasecachepercenthit1 #counter value 1
		,$databasecachepercenthit2 #counter value 2
		,$databasecachepercenthit_base1 #base counter value 1
		,$databasecachepercenthit_base2); #base counter value 2
	};	
#	print "databasecachepercenthit: $databasecachepercenthit \n";	


	#---find DatabaseCacheRequestsPersec---#	
	my $databasecacherequestspersec1 = $risc->{$calname}->{'1'}->{'databasecacherequestspersec'};	
#	print "databasecacherequestspersec1: $databasecacherequestspersec1 \n";	
	my $databasecacherequestspersec2 = $risc->{$calname}->{'2'}->{'databasecacherequestspersec'};	
#	print "databasecacherequestspersec2: $databasecacherequestspersec2 \n";	
	eval 	
	{	
	$databasecacherequestspersec = perf_counter_counter(	
		$databasecacherequestspersec1 #c1
		,$databasecacherequestspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "databasecacherequestspersec: $databasecacherequestspersec \n";	


	#---find DatabaseCacheSizeMB---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$databasecachesizemb = $risc->{$calname}->{'2'}->{'databasecachesizemb'};
#	print "databasecachesizemb: $databasecachesizemb \n";


	#---find DatabaseMaintenanceDuration---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$databasemaintenanceduration = $risc->{$calname}->{'2'}->{'databasemaintenanceduration'};
#	print "databasemaintenanceduration: $databasemaintenanceduration \n";


	#---find DatabaseMaintenancePagesBadChecksums---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$databasemaintenancepagesbadchecksums = $risc->{$calname}->{'2'}->{'databasemaintenancepagesbadchecksums'};
#	print "databasemaintenancepagesbadchecksums: $databasemaintenancepagesbadchecksums \n";


	#---find DefragmentationTasks---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$defragmentationtasks = $risc->{$calname}->{'2'}->{'defragmentationtasks'};
#	print "defragmentationtasks: $defragmentationtasks \n";


	#---find DefragmentationTasksPending---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$defragmentationtaskspending = $risc->{$calname}->{'2'}->{'defragmentationtaskspending'};
#	print "defragmentationtaskspending: $defragmentationtaskspending \n";


	#---find IODatabaseReadsAttachedAverageLatency---#	
	my $iodatabasereadsattachedaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedaveragelatency'};	
#	print "iodatabasereadsattachedaveragelatency1: $iodatabasereadsattachedaveragelatency1 \n";	
	my $iodatabasereadsattachedaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedaveragelatency'};	
#	print "iodatabasereadsattachedaveragelatency2: $iodatabasereadsattachedaveragelatency2 \n";	
	my $iodatabasereadsattachedaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedaveragelatency_base'};	
#	print "iodatabasereadsattachedaveragelatency_base1: $iodatabasereadsattachedaveragelatency_base1\n";	
	my $iodatabasereadsattachedaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedaveragelatency_base'};	
#	print "iodatabasereadsattachedaveragelatency_base2: $iodatabasereadsattachedaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsattachedaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsattachedaveragelatency1 #counter value 1
		,$iodatabasereadsattachedaveragelatency2 #counter value 2
		,$iodatabasereadsattachedaveragelatency_base1 #base counter value 1
		,$iodatabasereadsattachedaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsattachedaveragelatency: $iodatabasereadsattachedaveragelatency \n";	


	#---find IODatabaseReadsAttachedPersec---#	
	my $iodatabasereadsattachedpersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadsattachedpersec'};	
#	print "iodatabasereadsattachedpersec1: $iodatabasereadsattachedpersec1 \n";	
	my $iodatabasereadsattachedpersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadsattachedpersec'};	
#	print "iodatabasereadsattachedpersec2: $iodatabasereadsattachedpersec2 \n";	
	eval 	
	{	
	$iodatabasereadsattachedpersec = perf_counter_counter(	
		$iodatabasereadsattachedpersec1 #c1
		,$iodatabasereadsattachedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadsattachedpersec: $iodatabasereadsattachedpersec \n";	


	#---find IODatabaseReadsAverageLatency---#	
	my $iodatabasereadsaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsaveragelatency'};	
#	print "iodatabasereadsaveragelatency1: $iodatabasereadsaveragelatency1 \n";	
	my $iodatabasereadsaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsaveragelatency'};	
#	print "iodatabasereadsaveragelatency2: $iodatabasereadsaveragelatency2 \n";	
	my $iodatabasereadsaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsaveragelatency_base'};	
#	print "iodatabasereadsaveragelatency_base1: $iodatabasereadsaveragelatency_base1\n";	
	my $iodatabasereadsaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsaveragelatency_base'};	
#	print "iodatabasereadsaveragelatency_base2: $iodatabasereadsaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsaveragelatency1 #counter value 1
		,$iodatabasereadsaveragelatency2 #counter value 2
		,$iodatabasereadsaveragelatency_base1 #base counter value 1
		,$iodatabasereadsaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsaveragelatency: $iodatabasereadsaveragelatency \n";	


	#---find IODatabaseReadsPersec---#	
	my $iodatabasereadspersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadspersec'};	
#	print "iodatabasereadspersec1: $iodatabasereadspersec1 \n";	
	my $iodatabasereadspersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadspersec'};	
#	print "iodatabasereadspersec2: $iodatabasereadspersec2 \n";	
	eval 	
	{	
	$iodatabasereadspersec = perf_counter_counter(	
		$iodatabasereadspersec1 #c1
		,$iodatabasereadspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadspersec: $iodatabasereadspersec \n";	


	#---find IODatabaseReadsRecoveryAverageLatency---#	
	my $iodatabasereadsrecoveryaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoveryaveragelatency'};	
#	print "iodatabasereadsrecoveryaveragelatency1: $iodatabasereadsrecoveryaveragelatency1 \n";	
	my $iodatabasereadsrecoveryaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoveryaveragelatency'};	
#	print "iodatabasereadsrecoveryaveragelatency2: $iodatabasereadsrecoveryaveragelatency2 \n";	
	my $iodatabasereadsrecoveryaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoveryaveragelatency_base'};	
#	print "iodatabasereadsrecoveryaveragelatency_base1: $iodatabasereadsrecoveryaveragelatency_base1\n";	
	my $iodatabasereadsrecoveryaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoveryaveragelatency_base'};	
#	print "iodatabasereadsrecoveryaveragelatency_base2: $iodatabasereadsrecoveryaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasereadsrecoveryaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasereadsrecoveryaveragelatency1 #counter value 1
		,$iodatabasereadsrecoveryaveragelatency2 #counter value 2
		,$iodatabasereadsrecoveryaveragelatency_base1 #base counter value 1
		,$iodatabasereadsrecoveryaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasereadsrecoveryaveragelatency: $iodatabasereadsrecoveryaveragelatency \n";	


	#---find IODatabaseReadsRecoveryPersec---#	
	my $iodatabasereadsrecoverypersec1 = $risc->{$calname}->{'1'}->{'iodatabasereadsrecoverypersec'};	
#	print "iodatabasereadsrecoverypersec1: $iodatabasereadsrecoverypersec1 \n";	
	my $iodatabasereadsrecoverypersec2 = $risc->{$calname}->{'2'}->{'iodatabasereadsrecoverypersec'};	
#	print "iodatabasereadsrecoverypersec2: $iodatabasereadsrecoverypersec2 \n";	
	eval 	
	{	
	$iodatabasereadsrecoverypersec = perf_counter_counter(	
		$iodatabasereadsrecoverypersec1 #c1
		,$iodatabasereadsrecoverypersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasereadsrecoverypersec: $iodatabasereadsrecoverypersec \n";	


	#---find IODatabaseWritesAttachedAverageLatency---#	
	my $iodatabasewritesattachedaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedaveragelatency'};	
#	print "iodatabasewritesattachedaveragelatency1: $iodatabasewritesattachedaveragelatency1 \n";	
	my $iodatabasewritesattachedaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedaveragelatency'};	
#	print "iodatabasewritesattachedaveragelatency2: $iodatabasewritesattachedaveragelatency2 \n";	
	my $iodatabasewritesattachedaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedaveragelatency_base'};	
#	print "iodatabasewritesattachedaveragelatency_base1: $iodatabasewritesattachedaveragelatency_base1\n";	
	my $iodatabasewritesattachedaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedaveragelatency_base'};	
#	print "iodatabasewritesattachedaveragelatency_base2: $iodatabasewritesattachedaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesattachedaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesattachedaveragelatency1 #counter value 1
		,$iodatabasewritesattachedaveragelatency2 #counter value 2
		,$iodatabasewritesattachedaveragelatency_base1 #base counter value 1
		,$iodatabasewritesattachedaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesattachedaveragelatency: $iodatabasewritesattachedaveragelatency \n";	


	#---find IODatabaseWritesAttachedPersec---#	
	my $iodatabasewritesattachedpersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritesattachedpersec'};	
#	print "iodatabasewritesattachedpersec1: $iodatabasewritesattachedpersec1 \n";	
	my $iodatabasewritesattachedpersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritesattachedpersec'};	
#	print "iodatabasewritesattachedpersec2: $iodatabasewritesattachedpersec2 \n";	
	eval 	
	{	
	$iodatabasewritesattachedpersec = perf_counter_counter(	
		$iodatabasewritesattachedpersec1 #c1
		,$iodatabasewritesattachedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritesattachedpersec: $iodatabasewritesattachedpersec \n";	


	#---find IODatabaseWritesAverageLatency---#	
	my $iodatabasewritesaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesaveragelatency'};	
#	print "iodatabasewritesaveragelatency1: $iodatabasewritesaveragelatency1 \n";	
	my $iodatabasewritesaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesaveragelatency'};	
#	print "iodatabasewritesaveragelatency2: $iodatabasewritesaveragelatency2 \n";	
	my $iodatabasewritesaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesaveragelatency_base'};	
#	print "iodatabasewritesaveragelatency_base1: $iodatabasewritesaveragelatency_base1\n";	
	my $iodatabasewritesaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesaveragelatency_base'};	
#	print "iodatabasewritesaveragelatency_base2: $iodatabasewritesaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesaveragelatency1 #counter value 1
		,$iodatabasewritesaveragelatency2 #counter value 2
		,$iodatabasewritesaveragelatency_base1 #base counter value 1
		,$iodatabasewritesaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesaveragelatency: $iodatabasewritesaveragelatency \n";	


	#---find IODatabaseWritesPersec---#	
	my $iodatabasewritespersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritespersec'};	
#	print "iodatabasewritespersec1: $iodatabasewritespersec1 \n";	
	my $iodatabasewritespersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritespersec'};	
#	print "iodatabasewritespersec2: $iodatabasewritespersec2 \n";	
	eval 	
	{	
	$iodatabasewritespersec = perf_counter_counter(	
		$iodatabasewritespersec1 #c1
		,$iodatabasewritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritespersec: $iodatabasewritespersec \n";	


	#---find IODatabaseWritesRecoveryAverageLatency---#	
	my $iodatabasewritesrecoveryaveragelatency1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoveryaveragelatency'};	
#	print "iodatabasewritesrecoveryaveragelatency1: $iodatabasewritesrecoveryaveragelatency1 \n";	
	my $iodatabasewritesrecoveryaveragelatency2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoveryaveragelatency'};	
#	print "iodatabasewritesrecoveryaveragelatency2: $iodatabasewritesrecoveryaveragelatency2 \n";	
	my $iodatabasewritesrecoveryaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoveryaveragelatency_base'};	
#	print "iodatabasewritesrecoveryaveragelatency_base1: $iodatabasewritesrecoveryaveragelatency_base1\n";	
	my $iodatabasewritesrecoveryaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoveryaveragelatency_base'};	
#	print "iodatabasewritesrecoveryaveragelatency_base2: $iodatabasewritesrecoveryaveragelatency_base2\n";	
	eval 	
	{	
	$iodatabasewritesrecoveryaveragelatency = PERF_AVERAGE_BULK(	
		$iodatabasewritesrecoveryaveragelatency1 #counter value 1
		,$iodatabasewritesrecoveryaveragelatency2 #counter value 2
		,$iodatabasewritesrecoveryaveragelatency_base1 #base counter value 1
		,$iodatabasewritesrecoveryaveragelatency_base2); #base counter value 2
	};	
#	print "iodatabasewritesrecoveryaveragelatency: $iodatabasewritesrecoveryaveragelatency \n";	


	#---find IODatabaseWritesRecoveryPersec---#	
	my $iodatabasewritesrecoverypersec1 = $risc->{$calname}->{'1'}->{'iodatabasewritesrecoverypersec'};	
#	print "iodatabasewritesrecoverypersec1: $iodatabasewritesrecoverypersec1 \n";	
	my $iodatabasewritesrecoverypersec2 = $risc->{$calname}->{'2'}->{'iodatabasewritesrecoverypersec'};	
#	print "iodatabasewritesrecoverypersec2: $iodatabasewritesrecoverypersec2 \n";	
	eval 	
	{	
	$iodatabasewritesrecoverypersec = perf_counter_counter(	
		$iodatabasewritesrecoverypersec1 #c1
		,$iodatabasewritesrecoverypersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iodatabasewritesrecoverypersec: $iodatabasewritesrecoverypersec \n";	


	#---find IOLogReadsAverageLatency---#	
	my $iologreadsaveragelatency1 = $risc->{$calname}->{'1'}->{'iologreadsaveragelatency'};	
#	print "iologreadsaveragelatency1: $iologreadsaveragelatency1 \n";	
	my $iologreadsaveragelatency2 = $risc->{$calname}->{'2'}->{'iologreadsaveragelatency'};	
#	print "iologreadsaveragelatency2: $iologreadsaveragelatency2 \n";	
	my $iologreadsaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iologreadsaveragelatency_base'};	
#	print "iologreadsaveragelatency_base1: $iologreadsaveragelatency_base1\n";	
	my $iologreadsaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iologreadsaveragelatency_base'};	
#	print "iologreadsaveragelatency_base2: $iologreadsaveragelatency_base2\n";	
	eval 	
	{	
	$iologreadsaveragelatency = PERF_AVERAGE_BULK(	
		$iologreadsaveragelatency1 #counter value 1
		,$iologreadsaveragelatency2 #counter value 2
		,$iologreadsaveragelatency_base1 #base counter value 1
		,$iologreadsaveragelatency_base2); #base counter value 2
	};	
#	print "iologreadsaveragelatency: $iologreadsaveragelatency \n";	


	#---find IOLogReadsPersec---#	
	my $iologreadspersec1 = $risc->{$calname}->{'1'}->{'iologreadspersec'};	
#	print "iologreadspersec1: $iologreadspersec1 \n";	
	my $iologreadspersec2 = $risc->{$calname}->{'2'}->{'iologreadspersec'};	
#	print "iologreadspersec2: $iologreadspersec2 \n";	
	eval 	
	{	
	$iologreadspersec = perf_counter_counter(	
		$iologreadspersec1 #c1
		,$iologreadspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iologreadspersec: $iologreadspersec \n";	


	#---find IOLogWritesAverageLatency---#	
	my $iologwritesaveragelatency1 = $risc->{$calname}->{'1'}->{'iologwritesaveragelatency'};	
#	print "iologwritesaveragelatency1: $iologwritesaveragelatency1 \n";	
	my $iologwritesaveragelatency2 = $risc->{$calname}->{'2'}->{'iologwritesaveragelatency'};	
#	print "iologwritesaveragelatency2: $iologwritesaveragelatency2 \n";	
	my $iologwritesaveragelatency_base1 = $risc->{$calname}->{'1'}->{'iologwritesaveragelatency_base'};	
#	print "iologwritesaveragelatency_base1: $iologwritesaveragelatency_base1\n";	
	my $iologwritesaveragelatency_base2 = $risc->{$calname}->{'2'}->{'iologwritesaveragelatency_base'};	
#	print "iologwritesaveragelatency_base2: $iologwritesaveragelatency_base2\n";	
	eval 	
	{	
	$iologwritesaveragelatency = PERF_AVERAGE_BULK(	
		$iologwritesaveragelatency1 #counter value 1
		,$iologwritesaveragelatency2 #counter value 2
		,$iologwritesaveragelatency_base1 #base counter value 1
		,$iologwritesaveragelatency_base2); #base counter value 2
	};	
#	print "iologwritesaveragelatency: $iologwritesaveragelatency \n";	


	#---find IOLogWritesPersec---#	
	my $iologwritespersec1 = $risc->{$calname}->{'1'}->{'iologwritespersec'};	
#	print "iologwritespersec1: $iologwritespersec1 \n";	
	my $iologwritespersec2 = $risc->{$calname}->{'2'}->{'iologwritespersec'};	
#	print "iologwritespersec2: $iologwritespersec2 \n";	
	eval 	
	{	
	$iologwritespersec = perf_counter_counter(	
		$iologwritespersec1 #c1
		,$iologwritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "iologwritespersec: $iologwritespersec \n";	


	#---find LogBytesGeneratedPersec---#	
	my $logbytesgeneratedpersec1 = $risc->{$calname}->{'1'}->{'logbytesgeneratedpersec'};	
#	print "logbytesgeneratedpersec1: $logbytesgeneratedpersec1 \n";	
	my $logbytesgeneratedpersec2 = $risc->{$calname}->{'2'}->{'logbytesgeneratedpersec'};	
#	print "logbytesgeneratedpersec2: $logbytesgeneratedpersec2 \n";	
	eval 	
	{	
	$logbytesgeneratedpersec = perf_counter_counter(	
		$logbytesgeneratedpersec1 #c1
		,$logbytesgeneratedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logbytesgeneratedpersec: $logbytesgeneratedpersec \n";	


	#---find LogBytesWritePersec---#	
	my $logbyteswritepersec1 = $risc->{$calname}->{'1'}->{'logbyteswritepersec'};	
#	print "logbyteswritepersec1: $logbyteswritepersec1 \n";	
	my $logbyteswritepersec2 = $risc->{$calname}->{'2'}->{'logbyteswritepersec'};	
#	print "logbyteswritepersec2: $logbyteswritepersec2 \n";	
	eval 	
	{	
	$logbyteswritepersec = perf_counter_counter(	
		$logbyteswritepersec1 #c1
		,$logbyteswritepersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logbyteswritepersec: $logbyteswritepersec \n";	


	#---find LogCheckpointDepthasaPercentofTarget---#	
	my $logcheckpointdepthasapercentoftarget2 = $risc->{$calname}->{'2'}->{'logcheckpointdepthasapercentoftarget'};	
#	print "logcheckpointdepthasapercentoftarget2: $logcheckpointdepthasapercentoftarget2 \n";	
	my $logcheckpointdepthasapercentoftarget_base2 = $risc->{$calname}->{'2'}->{'logcheckpointdepthasapercentoftarget_base'};	
#	print "logcheckpointdepthasapercentoftarget_base2: $logcheckpointdepthasapercentoftarget_base2\n";	
	eval 	
	{	
	$logcheckpointdepthasapercentoftarget = PERF_RAW_FRACTION(	
		$logcheckpointdepthasapercentoftarget2 #counter value 2
		,$logcheckpointdepthasapercentoftarget_base2); #base counter value 2
	};	
#	print "logcheckpointdepthasapercentoftarget: $logcheckpointdepthasapercentoftarget \n";	


	#---find LogFileCurrentGeneration---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$logfilecurrentgeneration = $risc->{$calname}->{'2'}->{'logfilecurrentgeneration'};
#	print "logfilecurrentgeneration: $logfilecurrentgeneration \n";


	#---find LogFilesGenerated---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$logfilesgenerated = $risc->{$calname}->{'2'}->{'logfilesgenerated'};
#	print "logfilesgenerated: $logfilesgenerated \n";


	#---find LogFilesGeneratedPrematurely---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$logfilesgeneratedprematurely = $risc->{$calname}->{'2'}->{'logfilesgeneratedprematurely'};
#	print "logfilesgeneratedprematurely: $logfilesgeneratedprematurely \n";


	#---find LogGenerationCheckpointDepth---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$loggenerationcheckpointdepth = $risc->{$calname}->{'2'}->{'loggenerationcheckpointdepth'};
#	print "loggenerationcheckpointdepth: $loggenerationcheckpointdepth \n";


	#---find LogGenerationCheckpointDepthMax---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$loggenerationcheckpointdepthmax = $risc->{$calname}->{'2'}->{'loggenerationcheckpointdepthmax'};
#	print "loggenerationcheckpointdepthmax: $loggenerationcheckpointdepthmax \n";


	#---find LogGenerationCheckpointDepthTarget---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$loggenerationcheckpointdepthtarget = $risc->{$calname}->{'2'}->{'loggenerationcheckpointdepthtarget'};
#	print "loggenerationcheckpointdepthtarget: $loggenerationcheckpointdepthtarget \n";


	#---find LogGenerationLossResiliencyDepth---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$loggenerationlossresiliencydepth = $risc->{$calname}->{'2'}->{'loggenerationlossresiliencydepth'};
#	print "loggenerationlossresiliencydepth: $loggenerationlossresiliencydepth \n";


	#---find LogRecordStallsPersec---#	
	my $logrecordstallspersec1 = $risc->{$calname}->{'1'}->{'logrecordstallspersec'};	
#	print "logrecordstallspersec1: $logrecordstallspersec1 \n";	
	my $logrecordstallspersec2 = $risc->{$calname}->{'2'}->{'logrecordstallspersec'};	
#	print "logrecordstallspersec2: $logrecordstallspersec2 \n";	
	eval 	
	{	
	$logrecordstallspersec = perf_counter_counter(	
		$logrecordstallspersec1 #c1
		,$logrecordstallspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logrecordstallspersec: $logrecordstallspersec \n";	


	#---find LogThreadsWaiting---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$logthreadswaiting = $risc->{$calname}->{'2'}->{'logthreadswaiting'};
#	print "logthreadswaiting: $logthreadswaiting \n";


	#---find LogWritesPersec---#	
	my $logwritespersec1 = $risc->{$calname}->{'1'}->{'logwritespersec'};	
#	print "logwritespersec1: $logwritespersec1 \n";	
	my $logwritespersec2 = $risc->{$calname}->{'2'}->{'logwritespersec'};	
#	print "logwritespersec2: $logwritespersec2 \n";	
	eval 	
	{	
	$logwritespersec = perf_counter_counter(	
		$logwritespersec1 #c1
		,$logwritespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "logwritespersec: $logwritespersec \n";	


	#---find PagesConverted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$pagesconverted = $risc->{$calname}->{'2'}->{'pagesconverted'};
#	print "pagesconverted: $pagesconverted \n";


	#---find PagesConvertedPersec---#	
	my $pagesconvertedpersec1 = $risc->{$calname}->{'1'}->{'pagesconvertedpersec'};	
#	print "pagesconvertedpersec1: $pagesconvertedpersec1 \n";	
	my $pagesconvertedpersec2 = $risc->{$calname}->{'2'}->{'pagesconvertedpersec'};	
#	print "pagesconvertedpersec2: $pagesconvertedpersec2 \n";	
	eval 	
	{	
	$pagesconvertedpersec = perf_counter_counter(	
		$pagesconvertedpersec1 #c1
		,$pagesconvertedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "pagesconvertedpersec: $pagesconvertedpersec \n";	


	#---find RecordsConverted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$recordsconverted = $risc->{$calname}->{'2'}->{'recordsconverted'};
#	print "recordsconverted: $recordsconverted \n";


	#---find RecordsConvertedPersec---#	
	my $recordsconvertedpersec1 = $risc->{$calname}->{'1'}->{'recordsconvertedpersec'};	
#	print "recordsconvertedpersec1: $recordsconvertedpersec1 \n";	
	my $recordsconvertedpersec2 = $risc->{$calname}->{'2'}->{'recordsconvertedpersec'};	
#	print "recordsconvertedpersec2: $recordsconvertedpersec2 \n";	
	eval 	
	{	
	$recordsconvertedpersec = perf_counter_counter(	
		$recordsconvertedpersec1 #c1
		,$recordsconvertedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "recordsconvertedpersec: $recordsconvertedpersec \n";	


	#---find SessionsInUse---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$sessionsinuse = $risc->{$calname}->{'2'}->{'sessionsinuse'};
#	print "sessionsinuse: $sessionsinuse \n";


	#---find SessionsPercentUsed---#	
	my $sessionspercentused2 = $risc->{$calname}->{'2'}->{'sessionspercentused'};	
#	print "sessionspercentused2: $sessionspercentused2 \n";	
	my $sessionspercentused_base2 = $risc->{$calname}->{'2'}->{'sessionspercentused_base'};	
#	print "sessionspercentused_base2: $sessionspercentused_base2\n";	
	eval 	
	{	
	$sessionspercentused = PERF_RAW_FRACTION(	
		$sessionspercentused2 #counter value 2
		,$sessionspercentused_base2); #base counter value 2
	};	
#	print "sessionspercentused: $sessionspercentused \n";	


	#---find StreamingBackupPagesReadPersec---#	
	my $streamingbackuppagesreadpersec1 = $risc->{$calname}->{'1'}->{'streamingbackuppagesreadpersec'};	
#	print "streamingbackuppagesreadpersec1: $streamingbackuppagesreadpersec1 \n";	
	my $streamingbackuppagesreadpersec2 = $risc->{$calname}->{'2'}->{'streamingbackuppagesreadpersec'};	
#	print "streamingbackuppagesreadpersec2: $streamingbackuppagesreadpersec2 \n";	
	eval 	
	{	
	$streamingbackuppagesreadpersec = perf_counter_counter(	
		$streamingbackuppagesreadpersec1 #c1
		,$streamingbackuppagesreadpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "streamingbackuppagesreadpersec: $streamingbackuppagesreadpersec \n";	


	#---find TableOpenCacheHitsPersec---#	
	my $tableopencachehitspersec1 = $risc->{$calname}->{'1'}->{'tableopencachehitspersec'};	
#	print "tableopencachehitspersec1: $tableopencachehitspersec1 \n";	
	my $tableopencachehitspersec2 = $risc->{$calname}->{'2'}->{'tableopencachehitspersec'};	
#	print "tableopencachehitspersec2: $tableopencachehitspersec2 \n";	
	eval 	
	{	
	$tableopencachehitspersec = perf_counter_counter(	
		$tableopencachehitspersec1 #c1
		,$tableopencachehitspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopencachehitspersec: $tableopencachehitspersec \n";	


	#---find TableOpenCacheMissesPersec---#	
	my $tableopencachemissespersec1 = $risc->{$calname}->{'1'}->{'tableopencachemissespersec'};	
#	print "tableopencachemissespersec1: $tableopencachemissespersec1 \n";	
	my $tableopencachemissespersec2 = $risc->{$calname}->{'2'}->{'tableopencachemissespersec'};	
#	print "tableopencachemissespersec2: $tableopencachemissespersec2 \n";	
	eval 	
	{	
	$tableopencachemissespersec = perf_counter_counter(	
		$tableopencachemissespersec1 #c1
		,$tableopencachemissespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopencachemissespersec: $tableopencachemissespersec \n";	


	#---find TableOpenCachePercentHit---#	
	my $tableopencachepercenthit1 = $risc->{$calname}->{'1'}->{'tableopencachepercenthit'};	
#	print "tableopencachepercenthit1: $tableopencachepercenthit1 \n";	
	my $tableopencachepercenthit2 = $risc->{$calname}->{'2'}->{'tableopencachepercenthit'};	
#	print "tableopencachepercenthit2: $tableopencachepercenthit2 \n";	
	my $tableopencachepercenthit_base1 = $risc->{$calname}->{'1'}->{'tableopencachepercenthit_base'};	
#	print "tableopencachepercenthit_base1: $tableopencachepercenthit_base1\n";	
	my $tableopencachepercenthit_base2 = $risc->{$calname}->{'2'}->{'tableopencachepercenthit_base'};	
#	print "tableopencachepercenthit_base2: $tableopencachepercenthit_base2\n";	
	eval 	
	{	
	$tableopencachepercenthit = PERF_SAMPLE_FRACTION (	
		$tableopencachepercenthit1 #counter value 1
		,$tableopencachepercenthit2 #counter value 2
		,$tableopencachepercenthit_base1 #base counter value 1
		,$tableopencachepercenthit_base2); #base counter value 2
	};	
#	print "tableopencachepercenthit: $tableopencachepercenthit \n";	


	#---find TableOpensPersec---#	
	my $tableopenspersec1 = $risc->{$calname}->{'1'}->{'tableopenspersec'};	
#	print "tableopenspersec1: $tableopenspersec1 \n";	
	my $tableopenspersec2 = $risc->{$calname}->{'2'}->{'tableopenspersec'};	
#	print "tableopenspersec2: $tableopenspersec2 \n";	
	eval 	
	{	
	$tableopenspersec = perf_counter_counter(	
		$tableopenspersec1 #c1
		,$tableopenspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "tableopenspersec: $tableopenspersec \n";	


	#---find Versionbucketsallocated---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$versionbucketsallocated = $risc->{$calname}->{'2'}->{'versionbucketsallocated'};
#	print "versionbucketsallocated: $versionbucketsallocated \n";

######################################################################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$caption
	,$databasecachemissespersec
	,$databasecachepercenthit
	,$databasecacherequestspersec
	,$databasecachesizemb
	,$databasemaintenanceduration
	,$databasemaintenancepagesbadchecksums
	,$defragmentationtasks
	,$defragmentationtaskspending
	,$description
	,$iodatabasereadsattachedaveragelatency
	,$iodatabasereadsattachedpersec
	,$iodatabasereadsaveragelatency
	,$iodatabasereadspersec
	,$iodatabasereadsrecoveryaveragelatency
	,$iodatabasereadsrecoverypersec
	,$iodatabasewritesattachedaveragelatency
	,$iodatabasewritesattachedpersec
	,$iodatabasewritesaveragelatency
	,$iodatabasewritespersec
	,$iodatabasewritesrecoveryaveragelatency
	,$iodatabasewritesrecoverypersec
	,$iologreadsaveragelatency
	,$iologreadspersec
	,$iologwritesaveragelatency
	,$iologwritespersec
	,$logbytesgeneratedpersec
	,$logbyteswritepersec
	,$logcheckpointdepthasapercentoftarget
	,$logfilecurrentgeneration
	,$logfilesgenerated
	,$logfilesgeneratedprematurely
	,$loggenerationcheckpointdepth
	,$loggenerationcheckpointdepthmax
	,$loggenerationcheckpointdepthtarget
	,$loggenerationlossresiliencydepth
	,$logrecordstallspersec
	,$logthreadswaiting
	,$logwritespersec
	,$tablename
	,$pagesconverted
	,$pagesconvertedpersec
	,$recordsconverted
	,$recordsconvertedpersec
	,$sessionsinuse
	,$sessionspercentused
	,$streamingbackuppagesreadpersec
	,$tableopencachehitspersec
	,$tableopencachemissespersec
	,$tableopencachepercenthit
	,$tableopenspersec
	,$versionbucketsallocated
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeDomainCon
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchdomaincon (
	deviceid
	,scantime
	,bindfailuresperminute
	,caption
	,criticaldataflag
	,description
	,dsgetdcnameelapsedtime
	,gccapableflag
	,gethostbynameelapsedtime
	,issynchronizedflag
	,kerberosticketlifetime
	,ldapconnectionlifetime
	,ldapdisconnectsperminute
	,ldapfatalerrorsperminute
	,ldappagespersec
	,ldapreadcallspersec
	,ldapreadtime
	,ldapsearchcallspersec
	,ldapsearchestimedoutperminute
	,ldapsearchtime
	,ldapvlvrequestspersec
	,localsiteflag
	,longrunningldapoperationspermin
	,name
	,netlogonflag
	,numberofoutstandingrequests
	,osversionflag
	,pdcflag
	,reachabilitybitmask
	,saclrightflag
	,usersearchesfailedperminute
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $bindfailuresperminute = undef;
my $caption = undef;
my $criticaldataflag = undef;
my $description = undef;
my $dsgetdcnameelapsedtime = undef;
my $gccapableflag = undef;
my $gethostbynameelapsedtime = undef;
my $issynchronizedflag = undef;
my $kerberosticketlifetime = undef;
my $ldapconnectionlifetime = undef;
my $ldapdisconnectsperminute = undef;
my $ldapfatalerrorsperminute = undef;
my $ldappagespersec = undef;
my $ldapreadcallspersec = undef;
my $ldapreadtime = undef;
my $ldapsearchcallspersec = undef;
my $ldapsearchestimedoutperminute = undef;
my $ldapsearchtime = undef;
my $ldapvlvrequestspersec = undef;
my $localsiteflag = undef;
my $longrunningldapoperationspermin = undef;
my $tablename = undef;
my $netlogonflag = undef;
my $numberofoutstandingrequests = undef;
my $osversionflag = undef;
my $pdcflag = undef;
my $reachabilitybitmask = undef;
my $saclrightflag = undef;
my $usersearchesfailedperminute = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'bindfailuresperminute'} = $process->{'BindFailuresperMinute'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'criticaldataflag'} = $process->{'CriticalDataFlag'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'dsgetdcnameelapsedtime'} = $process->{'DsGetDcNameElapsedTime'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'gccapableflag'} = $process->{'GCCapableFlag'};
	$risc->{$name}->{'1'}->{'gethostbynameelapsedtime'} = $process->{'GetHostByNameElapsedTime'};
	$risc->{$name}->{'1'}->{'issynchronizedflag'} = $process->{'IsSynchronizedFlag'};
	$risc->{$name}->{'1'}->{'kerberosticketlifetime'} = $process->{'KerberosTicketLifetime'};
	$risc->{$name}->{'1'}->{'ldapconnectionlifetime'} = $process->{'LDAPConnectionLifetime'};
	$risc->{$name}->{'1'}->{'ldapdisconnectsperminute'} = $process->{'LDAPDisconnectsperMinute'};
	$risc->{$name}->{'1'}->{'ldapfatalerrorsperminute'} = $process->{'LDAPFatalErrorsperMinute'};
	$risc->{$name}->{'1'}->{'ldappagespersec'} = $process->{'LDAPPagesPersec'};
	$risc->{$name}->{'1'}->{'ldapreadcallspersec'} = $process->{'LDAPReadCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapreadtime'} = $process->{'LDAPReadTime'};
	$risc->{$name}->{'1'}->{'ldapreadtime_base'} = $process->{'LDAPReadTime_Base'};
	$risc->{$name}->{'1'}->{'ldapsearchcallspersec'} = $process->{'LDAPSearchCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapsearchestimedoutperminute'} = $process->{'LDAPSearchesTimedOutperMinute'};
	$risc->{$name}->{'1'}->{'ldapsearchtime'} = $process->{'LDAPSearchTime'};
	$risc->{$name}->{'1'}->{'ldapsearchtime_base'} = $process->{'LDAPSearchTime_Base'};
	$risc->{$name}->{'1'}->{'ldapvlvrequestspersec'} = $process->{'LDAPVLVRequestsPersec'};
	$risc->{$name}->{'1'}->{'localsiteflag'} = $process->{'LocalSiteFlag'};
	$risc->{$name}->{'1'}->{'longrunningldapoperationspermin'} = $process->{'LongRunningLDAPOperationsPermin'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'netlogonflag'} = $process->{'NetlogonFlag'};
	$risc->{$name}->{'1'}->{'numberofoutstandingrequests'} = $process->{'NumberofOutstandingRequests'};
	$risc->{$name}->{'1'}->{'osversionflag'} = $process->{'OSVersionFlag'};
	$risc->{$name}->{'1'}->{'pdcflag'} = $process->{'PDCFlag'};
	$risc->{$name}->{'1'}->{'reachabilitybitmask'} = $process->{'ReachabilityBitmask'};
	$risc->{$name}->{'1'}->{'saclrightflag'} = $process->{'SACLRightFlag'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'usersearchesfailedperminute'} = $process->{'UserSearchesFailedperMinute'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'bindfailuresperminute'} = $process->{'BindFailuresperMinute'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'criticaldataflag'} = $process->{'CriticalDataFlag'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'dsgetdcnameelapsedtime'} = $process->{'DsGetDcNameElapsedTime'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'gccapableflag'} = $process->{'GCCapableFlag'};
	$risc->{$name}->{'2'}->{'gethostbynameelapsedtime'} = $process->{'GetHostByNameElapsedTime'};
	$risc->{$name}->{'2'}->{'issynchronizedflag'} = $process->{'IsSynchronizedFlag'};
	$risc->{$name}->{'2'}->{'kerberosticketlifetime'} = $process->{'KerberosTicketLifetime'};
	$risc->{$name}->{'2'}->{'ldapconnectionlifetime'} = $process->{'LDAPConnectionLifetime'};
	$risc->{$name}->{'2'}->{'ldapdisconnectsperminute'} = $process->{'LDAPDisconnectsperMinute'};
	$risc->{$name}->{'2'}->{'ldapfatalerrorsperminute'} = $process->{'LDAPFatalErrorsperMinute'};
	$risc->{$name}->{'2'}->{'ldappagespersec'} = $process->{'LDAPPagesPersec'};
	$risc->{$name}->{'2'}->{'ldapreadcallspersec'} = $process->{'LDAPReadCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapreadtime'} = $process->{'LDAPReadTime'};
	$risc->{$name}->{'2'}->{'ldapreadtime_base'} = $process->{'LDAPReadTime_Base'};
	$risc->{$name}->{'2'}->{'ldapsearchcallspersec'} = $process->{'LDAPSearchCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapsearchestimedoutperminute'} = $process->{'LDAPSearchesTimedOutperMinute'};
	$risc->{$name}->{'2'}->{'ldapsearchtime'} = $process->{'LDAPSearchTime'};
	$risc->{$name}->{'2'}->{'ldapsearchtime_base'} = $process->{'LDAPSearchTime_Base'};
	$risc->{$name}->{'2'}->{'ldapvlvrequestspersec'} = $process->{'LDAPVLVRequestsPersec'};
	$risc->{$name}->{'2'}->{'localsiteflag'} = $process->{'LocalSiteFlag'};
	$risc->{$name}->{'2'}->{'longrunningldapoperationspermin'} = $process->{'LongRunningLDAPOperationsPermin'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'netlogonflag'} = $process->{'NetlogonFlag'};
	$risc->{$name}->{'2'}->{'numberofoutstandingrequests'} = $process->{'NumberofOutstandingRequests'};
	$risc->{$name}->{'2'}->{'osversionflag'} = $process->{'OSVersionFlag'};
	$risc->{$name}->{'2'}->{'pdcflag'} = $process->{'PDCFlag'};
	$risc->{$name}->{'2'}->{'reachabilitybitmask'} = $process->{'ReachabilityBitmask'};
	$risc->{$name}->{'2'}->{'saclrightflag'} = $process->{'SACLRightFlag'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'usersearchesfailedperminute'} = $process->{'UserSearchesFailedperMinute'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};


	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";


	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;


	#---find BindFailuresperMinute---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$bindfailuresperminute = $risc->{$calname}->{'2'}->{'bindfailuresperminute'};
#	print "BindFailuresperMinute: $bindfailuresperminute \n\n";


	#---find CriticalDataFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$criticaldataflag = $risc->{$calname}->{'2'}->{'criticaldataflag'};
#	print "CriticalDataFlag: $criticaldataflag \n\n";


	#---find DsGetDcNameElapsedTime---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$dsgetdcnameelapsedtime = $risc->{$calname}->{'2'}->{'dsgetdcnameelapsedtime'};
#	print "DsGetDcNameElapsedTime: $dsgetdcnameelapsedtime \n\n";


	#---find GCCapableFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$gccapableflag = $risc->{$calname}->{'2'}->{'gccapableflag'};
#	print "GCCapableFlag: $gccapableflag \n\n";


	#---find GetHostByNameElapsedTime---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$gethostbynameelapsedtime = $risc->{$calname}->{'2'}->{'gethostbynameelapsedtime'};
#	print "GetHostByNameElapsedTime: $gethostbynameelapsedtime \n\n";


	#---find IsSynchronizedFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$issynchronizedflag = $risc->{$calname}->{'2'}->{'issynchronizedflag'};
#	print "IsSynchronizedFlag: $issynchronizedflag \n\n";


	#---find KerberosTicketLifetime---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$kerberosticketlifetime = $risc->{$calname}->{'2'}->{'kerberosticketlifetime'};
#	print "KerberosTicketLifetime: $kerberosticketlifetime \n\n";


	#---find LDAPConnectionLifetime---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ldapconnectionlifetime = $risc->{$calname}->{'2'}->{'ldapconnectionlifetime'};
#	print "LDAPConnectionLifetime: $ldapconnectionlifetime \n\n";


	#---find LDAPDisconnectsperMinute---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ldapdisconnectsperminute = $risc->{$calname}->{'2'}->{'ldapdisconnectsperminute'};
#	print "LDAPDisconnectsperMinute: $ldapdisconnectsperminute \n\n";


	#---find LDAPFatalErrorsperMinute---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ldapfatalerrorsperminute = $risc->{$calname}->{'2'}->{'ldapfatalerrorsperminute'};
#	print "LDAPFatalErrorsperMinute: $ldapfatalerrorsperminute \n\n";


	#---find LDAPPagesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldappagespersec'};	
#	print "LDAPPagesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldappagespersec'};	
#	print "LDAPPagesPersec2: $val2 \n";	
	eval 	
	{	
	$ldappagespersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "LDAPPagesPersec: $ldappagespersec \n\n";	


	#---find LDAPReadCallsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapreadcallspersec'};	
#	print "LDAPReadCallsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapreadcallspersec'};	
#	print "LDAPReadCallsPersec2: $val2 \n";	
	eval 	
	{	
	$ldapreadcallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "LDAPReadCallsPersec: $ldapreadcallspersec \n\n";	


	#---find LDAPReadTime---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapreadtime'};	
#	print "LDAPReadTime1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapreadtime'};	
#	print "LDAPReadTime2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'ldapreadtime_base'};	
#	print "LDAPReadTime_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'ldapreadtime_base'};	
#	print "LDAPReadTime_base2: $val_base2\n";	
	eval 	
	{	
	$ldapreadtime = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "LDAPReadTime: $ldapreadtime \n";	


	#---find LDAPSearchCallsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapsearchcallspersec'};	
#	print "LDAPSearchCallsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapsearchcallspersec'};	
#	print "LDAPSearchCallsPersec2: $val2 \n";	
	eval 	
	{	
	$ldapsearchcallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "LDAPSearchCallsPersec: $ldapsearchcallspersec \n\n";	


	#---find LDAPSearchesTimedOutperMinute---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ldapsearchestimedoutperminute = $risc->{$calname}->{'2'}->{'ldapsearchestimedoutperminute'};
#	print "LDAPSearchesTimedOutperMinute: $ldapsearchestimedoutperminute \n\n";


	#---find LDAPSearchTime---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapsearchtime'};	
#	print "LDAPSearchTime1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapsearchtime'};	
#	print "LDAPSearchTime2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'ldapsearchtime_base'};	
#	print "LDAPSearchTime_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'ldapsearchtime_base'};	
#	print "LDAPSearchTime_base2: $val_base2\n";	
	eval 	
	{	
	$ldapsearchtime = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "LDAPSearchTime: $ldapsearchtime \n";	


	#---find LDAPVLVRequestsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapvlvrequestspersec'};	
#	print "LDAPVLVRequestsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapvlvrequestspersec'};	
#	print "LDAPVLVRequestsPersec2: $val2 \n";	
	eval 	
	{	
	$ldapvlvrequestspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "LDAPVLVRequestsPersec: $ldapvlvrequestspersec \n\n";	


	#---find LocalSiteFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$localsiteflag = $risc->{$calname}->{'2'}->{'localsiteflag'};
#	print "LocalSiteFlag: $localsiteflag \n\n";


	#---find LongRunningLDAPOperationsPermin---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$longrunningldapoperationspermin = $risc->{$calname}->{'2'}->{'longrunningldapoperationspermin'};
#	print "LongRunningLDAPOperationsPermin: $longrunningldapoperationspermin \n\n";


	#---find NetlogonFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$netlogonflag = $risc->{$calname}->{'2'}->{'netlogonflag'};
#	print "NetlogonFlag: $netlogonflag \n\n";


	#---find NumberofOutstandingRequests---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofoutstandingrequests = $risc->{$calname}->{'2'}->{'numberofoutstandingrequests'};
#	print "NumberofOutstandingRequests: $numberofoutstandingrequests \n\n";


	#---find OSVersionFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$osversionflag = $risc->{$calname}->{'2'}->{'osversionflag'};
#	print "OSVersionFlag: $osversionflag \n\n";


	#---find PDCFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$pdcflag = $risc->{$calname}->{'2'}->{'pdcflag'};
#	print "PDCFlag: $pdcflag \n\n";


	#---find ReachabilityBitmask---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$reachabilitybitmask = $risc->{$calname}->{'2'}->{'reachabilitybitmask'};
#	print "ReachabilityBitmask: $reachabilitybitmask \n\n";


	#---find SACLRightFlag---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$saclrightflag = $risc->{$calname}->{'2'}->{'saclrightflag'};
#	print "SACLRightFlag: $saclrightflag \n\n";


	#---find UserSearchesFailedperMinute---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$usersearchesfailedperminute = $risc->{$calname}->{'2'}->{'usersearchesfailedperminute'};
#	print "UserSearchesFailedperMinute: $usersearchesfailedperminute \n\n";


#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$bindfailuresperminute
	,$caption
	,$criticaldataflag
	,$description
	,$dsgetdcnameelapsedtime
	,$gccapableflag
	,$gethostbynameelapsedtime
	,$issynchronizedflag
	,$kerberosticketlifetime
	,$ldapconnectionlifetime
	,$ldapdisconnectsperminute
	,$ldapfatalerrorsperminute
	,$ldappagespersec
	,$ldapreadcallspersec
	,$ldapreadtime
	,$ldapsearchcallspersec
	,$ldapsearchestimedoutperminute
	,$ldapsearchtime
	,$ldapvlvrequestspersec
	,$localsiteflag
	,$longrunningldapoperationspermin
	,$tablename
	,$netlogonflag
	,$numberofoutstandingrequests
	,$osversionflag
	,$pdcflag
	,$reachabilitybitmask
	,$saclrightflag
	,$usersearchesfailedperminute
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub ExchangeExtensibilityAgents
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchextenagen (
	deviceid
	,scantime
	,averageagentprocessingtimesec
	,caption
	,description
	,name
	,totalagentinvocations
	) VALUES (?,?,?,?,?,?,?)");


my $averageagentprocessingtimesec = undef;
my $caption = undef;
my $description = undef;
my $tablename = undef;
my $totalagentinvocations = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'averageagentprocessingtimesec'} = $process->{'AverageAgentProcessingTimesec'};
	$risc->{$name}->{'1'}->{'averageagentprocessingtimesec_base'} = $process->{'AverageAgentProcessingTimesec_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalagentinvocations'} = $process->{'TotalAgentInvocations'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'averageagentprocessingtimesec'} = $process->{'AverageAgentProcessingTimesec'};
	$risc->{$name}->{'2'}->{'averageagentprocessingtimesec_base'} = $process->{'AverageAgentProcessingTimesec_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalagentinvocations'} = $process->{'TotalAgentInvocations'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";


	#---find AverageAgentProcessingTimesec---#
	my $averageagentprocessingtimesec1 = $risc->{$calname}->{'1'}->{'averageagentprocessingtimesec'};
#	print "averageagentprocessingtimesec1: $averageagentprocessingtimesec1\n";		
	my $averageagentprocessingtimesec2 = $risc->{$calname}->{'2'}->{'averageagentprocessingtimesec'};
#	print "averageagentprocessingtimesec2: $averageagentprocessingtimesec2\n";
	my $averageagentprocessingtimesec_base1 = $risc->{$calname}->{'1'}->{'averageagentprocessingtimesec_base'};
#	print "averageagentprocessingtimesec_base1: $averageagentprocessingtimesec_base1\n";		
	my $averageagentprocessingtimesec_base2 = $risc->{$calname}->{'2'}->{'averageagentprocessingtimesec_base'};
#	print "averageagentprocessingtimesec_base2: $averageagentprocessingtimesec_base2\n";
	eval 		
	{		
	$averageagentprocessingtimesec = PERF_AVERAGE_TIMER(	
		$averageagentprocessingtimesec1 #counter value 1
		,$averageagentprocessingtimesec2 #ccounter value 2
		,$frequency_perftime2 #Perf freq 2
		,$averageagentprocessingtimesec_base1 #base counter value 1
		,$averageagentprocessingtimesec_base2); #base counter value 2
	};
#	print "averageagentprocessingtimesec = $averageagentprocessingtimesec\n";
	
	
	#---find TotalAgentInvocations---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalagentinvocations = $risc->{$calname}->{'2'}->{'totalagentinvocations'};
#	print "totalagentinvocations: $totalagentinvocations\n";
	
######################################################################################
													
	#---add data to the table---
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$averageagentprocessingtimesec
	,$caption
	,$description
	,$tablename
	,$totalagentinvocations
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeFDSOAB
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchfdsoab (
	deviceid
	,scantime
	,bytesdownloaded
	,caption
	,description
	,downloadtaskqueued
	,downloadtaskscompleted
	,name
	,totalbytestodownload
	) VALUES (?,?,?,?,?,?,?,?,?)");


my $bytesdownloaded = undef;
my $caption = undef;
my $description = undef;
my $downloadtaskqueued = undef;
my $downloadtaskscompleted = undef;
my $tablename = undef;
my $totalbytestodownload = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'bytesdownloaded'} = $process->{'BytesDownloaded'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'downloadtaskqueued'} = $process->{'DownloadTaskQueued'};
	$risc->{$name}->{'1'}->{'downloadtaskscompleted'} = $process->{'DownloadTasksCompleted'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalbytestodownload'} = $process->{'TotalBytesToDownload'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'bytesdownloaded'} = $process->{'BytesDownloaded'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'downloadtaskqueued'} = $process->{'DownloadTaskQueued'};
	$risc->{$name}->{'2'}->{'downloadtaskscompleted'} = $process->{'DownloadTasksCompleted'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalbytestodownload'} = $process->{'TotalBytesToDownload'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};


	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";


	#---find BytesDownloaded---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$bytesdownloaded = $risc->{$calname}->{'2'}->{'bytesdownloaded'};
#	print "BytesDownloaded: $bytesdownloaded \n";


	#---find DownloadTaskQueued---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$downloadtaskqueued = $risc->{$calname}->{'2'}->{'downloadtaskqueued'};
#	print "DownloadTaskQueued: $downloadtaskqueued \n";


	#---find DownloadTasksCompleted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$downloadtaskscompleted = $risc->{$calname}->{'2'}->{'downloadtaskscompleted'};
#	print "DownloadTasksCompleted: $downloadtaskscompleted \n";


	#---find TotalBytesToDownload---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$totalbytestodownload = $risc->{$calname}->{'2'}->{'totalbytestodownload'};
#	print "TotalBytesToDownload: $totalbytestodownload \n";


###################################################################################
				
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$bytesdownloaded
	,$caption
	,$description
	,$downloadtaskqueued
	,$downloadtaskscompleted
	,$tablename
	,$totalbytestodownload
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeIS
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchis (
	deviceid
	,scantime
	,activeanonymoususercount
	,activeconnectioncount
	,activeusercount
	,adminrpcrequests
	,adminrpcrequestspeak
	,anonymoususercount
	,appointmentinstancecreationrate
	,appointmentinstancedeletionrate
	,appointmentinstancescreated
	,appointmentinstancesdeleted
	,asyncnotificationscachesize
	,asyncnotificationsgeneratedpersec
	,asyncrpcrequests
	,asyncrpcrequestspeak
	,backgroundexpansionqueuelength
	,caption
	,ciqpthreads
	,clientbackgroundrpcsfailed
	,clientbackgroundrpcsfailedpersec
	,clientbackgroundrpcssucceeded
	,clientbackgroundrpcssucceededpersec
	,clientforegroundrpcsfailed
	,clientforegroundrpcsfailedpersec
	,clientforegroundrpcssucceeded
	,clientforegroundrpcssucceededpersec
	,clientlatency10secrpcs
	,clientlatency2secrpcs
	,clientlatency5secrpcs
	,clientrpcsattempted
	,clientrpcsattemptedpersec
	,clientrpcsfailed
	,clientrpcsfailedaccessdenied
	,clientrpcsfailedaccessdeniedpersec
	,clientrpcsfailedallothererrors
	,clientrpcsfailedallothererrorspersec
	,clientrpcsfailedcallcancelled
	,clientrpcsfailedcallcancelledpersec
	,clientrpcsfailedcallfailed
	,clientrpcsfailedcallfailedpersec
	,clientrpcsfailedpersec
	,clientrpcsfailedservertoobusy
	,clientrpcsfailedservertoobusypersec
	,clientrpcsfailedserverunavailable
	,clientrpcsfailedserverunavailablepersec
	,clientrpcssucceeded
	,clientrpcssucceededpersec
	,clienttotalreportedlatency
	,connectioncount
	,description
	,dlmembershipcacheentriescount
	,dlmembershipcachehits
	,dlmembershipcachemisses
	,dlmembershipcachesize
	,exchmemcurrentbytesallocated
	,exchmemcurrentnumberofvirtualallocations
	,exchmemcurrentvirtualbytesallocated
	,exchmemmaximumbytesallocated
	,exchmemmaximumvirtualbytesallocated
	,exchmemnumberofadditionalheaps
	,exchmemnumberofheaps
	,exchmemnumberofheapswithmemoryerrors
	,exchmemnumberofmemoryerrors
	,exchmemtotalnumberofvirtualallocations
	,fbpublishcount
	,fbpublishrate
	,maximumanonymoususers
	,maximumconnections
	,maximumusers
	,messagecreatepersec
	,messagedeletepersec
	,messagemodifypersec
	,messagemovepersec
	,messagesprereadascendingpersec
	,messagesprereaddescendingpersec
	,messagesprereadskippedpersec
	,minimsgcreatedforviewspersec
	,minimsgmsgtableseekspersec
	,msgviewrecordsdeletedpersec
	,msgviewrecordsdeletesdeferredpersec
	,msgviewrecordsinsertedpersec
	,msgviewrecordsinsertsdeferredpersec
	,msgviewtablecreatepersec
	,msgviewtabledeletepersec
	,msgviewtablenullrefreshpersec
	,msgviewtablerefreshdvurecordsscanned
	,msgviewtablerefreshpersec
	,msgviewtablerefreshupdatesapplied
	,name
	,oabdifferentialdownloadattempts
	,oabdifferentialdownloadbytes
	,oabdifferentialdownloadbytespersec
	,oabfulldownloadattempts
	,oabfulldownloadattemptsblocked
	,oabfulldownloadbytes
	,oabfulldownloadbytespersec
	,peakasyncnotificationscachesize
	,peakpushnotificationscachesize
	,percentconnections
	,percentrpcthreads
	,pushnotificationscachesize
	,pushnotificationsgeneratedpersec
	,pushnotificationsskippedpersec
	,readbytesrpcclientspersec
	,recurringappointmentdeletionrate
	,recurringappointmentmodificationrate
	,recurringappointmentscreated
	,recurringappointmentsdeleted
	,recurringappointmentsmodified
	,recurringapppointmentcreationrate
	,recurringmasterappointmentsexpanded
	,recurringmasterexpansionrate
	,rpcaveragedlatency
	,rpcclientbackoffpersec
	,rpcclientsbytesread
	,rpcclientsbyteswritten
	,rpcclientsuncompressedbytesread
	,rpcclientsuncompressedbyteswritten
	,rpcnumofslowpackets
	,rpcoperationspersec
	,rpcpacketspersec
	,rpcpoolasyncnotificationsgeneratedpersec
	,rpcpoolcontexthandles
	,rpcpoolparkedasyncnotificationcalls
	,rpcpoolpools
	,rpcpoolsessionnotificationspending
	,rpcpoolsessions
	,rpcrequests
	,rpcrequestspeak
	,rpcrequesttimeoutdetected
	,singleappointmentcreationrate
	,singleappointmentdeletionrate
	,singleappointmentmodificationrate
	,singleappointmentscreated
	,singleappointmentsdeleted
	,singleappointmentsmodified
	,slowqpthreads
	,slowsearchthreads
	,totalparkedasyncnotificationcalls
	,usercount
	,viewcleanupcategorizationindexdeletionspersec
	,viewcleanupdvuentrydeletionspersec
	,viewcleanuprestrictionindexdeletionspersec
	,viewcleanupsearchindexdeletionspersec
	,viewcleanupsortindexdeletionspersec
	,viewcleanuptasksnullifiedpersec
	,viewcleanuptaskspersec
	,virusscanbytesscanned
	,virusscanfilescleaned
	,virusscanfilescleanedpersec
	,virusscanfilesquarantined
	,virusscanfilesquarantinedpersec
	,virusscanfilesscanned
	,virusscanfilesscannedpersec
	,virusscanfoldersscannedinbackground
	,virusscanmessagescleaned
	,virusscanmessagescleanedpersec
	,virusscanmessagesdeleted
	,virusscanmessagesdeletedpersec
	,virusscanmessagesprocessed
	,virusscanmessagesprocessedpersec
	,virusscanmessagesquarantined
	,virusscanmessagesquarantinedpersec
	,virusscanmessagesscannedinbackground
	,virusscanqueuelength
	,vmlargestblocksize
	,vmtotal16mbfreeblocks
	,vmtotalfreeblocks
	,vmtotallargefreeblockbytes
	,writebytesrpcclientspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $activeanonymoususercount = undef;
my $activeconnectioncount = undef;
my $activeusercount = undef;
my $adminrpcrequests = undef;
my $adminrpcrequestspeak = undef;
my $anonymoususercount = undef;
my $appointmentinstancecreationrate = undef;
my $appointmentinstancedeletionrate = undef;
my $appointmentinstancescreated = undef;
my $appointmentinstancesdeleted = undef;
my $asyncnotificationscachesize = undef;
my $asyncnotificationsgeneratedpersec = undef;
my $asyncrpcrequests = undef;
my $asyncrpcrequestspeak = undef;
my $backgroundexpansionqueuelength = undef;
my $caption = undef;
my $ciqpthreads = undef;
my $clientbackgroundrpcsfailed = undef;
my $clientbackgroundrpcsfailedpersec = undef;
my $clientbackgroundrpcssucceeded = undef;
my $clientbackgroundrpcssucceededpersec = undef;
my $clientforegroundrpcsfailed = undef;
my $clientforegroundrpcsfailedpersec = undef;
my $clientforegroundrpcssucceeded = undef;
my $clientforegroundrpcssucceededpersec = undef;
my $clientlatency10secrpcs = undef;
my $clientlatency2secrpcs = undef;
my $clientlatency5secrpcs = undef;
my $clientrpcsattempted = undef;
my $clientrpcsattemptedpersec = undef;
my $clientrpcsfailed = undef;
my $clientrpcsfailedaccessdenied = undef;
my $clientrpcsfailedaccessdeniedpersec = undef;
my $clientrpcsfailedallothererrors = undef;
my $clientrpcsfailedallothererrorspersec = undef;
my $clientrpcsfailedcallcancelled = undef;
my $clientrpcsfailedcallcancelledpersec = undef;
my $clientrpcsfailedcallfailed = undef;
my $clientrpcsfailedcallfailedpersec = undef;
my $clientrpcsfailedpersec = undef;
my $clientrpcsfailedservertoobusy = undef;
my $clientrpcsfailedservertoobusypersec = undef;
my $clientrpcsfailedserverunavailable = undef;
my $clientrpcsfailedserverunavailablepersec = undef;
my $clientrpcssucceeded = undef;
my $clientrpcssucceededpersec = undef;
my $clienttotalreportedlatency = undef;
my $connectioncount = undef;
my $description = undef;
my $dlmembershipcacheentriescount = undef;
my $dlmembershipcachehits = undef;
my $dlmembershipcachemisses = undef;
my $dlmembershipcachesize = undef;
my $exchmemcurrentbytesallocated = undef;
my $exchmemcurrentnumberofvirtualallocations = undef;
my $exchmemcurrentvirtualbytesallocated = undef;
my $exchmemmaximumbytesallocated = undef;
my $exchmemmaximumvirtualbytesallocated = undef;
my $exchmemnumberofadditionalheaps = undef;
my $exchmemnumberofheaps = undef;
my $exchmemnumberofheapswithmemoryerrors = undef;
my $exchmemnumberofmemoryerrors = undef;
my $exchmemtotalnumberofvirtualallocations = undef;
my $fbpublishcount = undef;
my $fbpublishrate = undef;
my $maximumanonymoususers = undef;
my $maximumconnections = undef;
my $maximumusers = undef;
my $messagecreatepersec = undef;
my $messagedeletepersec = undef;
my $messagemodifypersec = undef;
my $messagemovepersec = undef;
my $messagesprereadascendingpersec = undef;
my $messagesprereaddescendingpersec = undef;
my $messagesprereadskippedpersec = undef;
my $minimsgcreatedforviewspersec = undef;
my $minimsgmsgtableseekspersec = undef;
my $msgviewrecordsdeletedpersec = undef;
my $msgviewrecordsdeletesdeferredpersec = undef;
my $msgviewrecordsinsertedpersec = undef;
my $msgviewrecordsinsertsdeferredpersec = undef;
my $msgviewtablecreatepersec = undef;
my $msgviewtabledeletepersec = undef;
my $msgviewtablenullrefreshpersec = undef;
my $msgviewtablerefreshdvurecordsscanned = undef;
my $msgviewtablerefreshpersec = undef;
my $msgviewtablerefreshupdatesapplied = undef;
my $tablename = undef;
my $oabdifferentialdownloadattempts = undef;
my $oabdifferentialdownloadbytes = undef;
my $oabdifferentialdownloadbytespersec = undef;
my $oabfulldownloadattempts = undef;
my $oabfulldownloadattemptsblocked = undef;
my $oabfulldownloadbytes = undef;
my $oabfulldownloadbytespersec = undef;
my $peakasyncnotificationscachesize = undef;
my $peakpushnotificationscachesize = undef;
my $percentconnections = undef;
my $percentrpcthreads = undef;
my $pushnotificationscachesize = undef;
my $pushnotificationsgeneratedpersec = undef;
my $pushnotificationsskippedpersec = undef;
my $readbytesrpcclientspersec = undef;
my $recurringappointmentdeletionrate = undef;
my $recurringappointmentmodificationrate = undef;
my $recurringappointmentscreated = undef;
my $recurringappointmentsdeleted = undef;
my $recurringappointmentsmodified = undef;
my $recurringapppointmentcreationrate = undef;
my $recurringmasterappointmentsexpanded = undef;
my $recurringmasterexpansionrate = undef;
my $rpcaveragedlatency = undef;
my $rpcclientbackoffpersec = undef;
my $rpcclientsbytesread = undef;
my $rpcclientsbyteswritten = undef;
my $rpcclientsuncompressedbytesread = undef;
my $rpcclientsuncompressedbyteswritten = undef;
my $rpcnumofslowpackets = undef;
my $rpcoperationspersec = undef;
my $rpcpacketspersec = undef;
my $rpcpoolasyncnotificationsgeneratedpersec = undef;
my $rpcpoolcontexthandles = undef;
my $rpcpoolparkedasyncnotificationcalls = undef;
my $rpcpoolpools = undef;
my $rpcpoolsessionnotificationspending = undef;
my $rpcpoolsessions = undef;
my $rpcrequests = undef;
my $rpcrequestspeak = undef;
my $rpcrequesttimeoutdetected = undef;
my $singleappointmentcreationrate = undef;
my $singleappointmentdeletionrate = undef;
my $singleappointmentmodificationrate = undef;
my $singleappointmentscreated = undef;
my $singleappointmentsdeleted = undef;
my $singleappointmentsmodified = undef;
my $slowqpthreads = undef;
my $slowsearchthreads = undef;
my $totalparkedasyncnotificationcalls = undef;
my $usercount = undef;
my $viewcleanupcategorizationindexdeletionspersec = undef;
my $viewcleanupdvuentrydeletionspersec = undef;
my $viewcleanuprestrictionindexdeletionspersec = undef;
my $viewcleanupsearchindexdeletionspersec = undef;
my $viewcleanupsortindexdeletionspersec = undef;
my $viewcleanuptasksnullifiedpersec = undef;
my $viewcleanuptaskspersec = undef;
my $virusscanbytesscanned = undef;
my $virusscanfilescleaned = undef;
my $virusscanfilescleanedpersec = undef;
my $virusscanfilesquarantined = undef;
my $virusscanfilesquarantinedpersec = undef;
my $virusscanfilesscanned = undef;
my $virusscanfilesscannedpersec = undef;
my $virusscanfoldersscannedinbackground = undef;
my $virusscanmessagescleaned = undef;
my $virusscanmessagescleanedpersec = undef;
my $virusscanmessagesdeleted = undef;
my $virusscanmessagesdeletedpersec = undef;
my $virusscanmessagesprocessed = undef;
my $virusscanmessagesprocessedpersec = undef;
my $virusscanmessagesquarantined = undef;
my $virusscanmessagesquarantinedpersec = undef;
my $virusscanmessagesscannedinbackground = undef;
my $virusscanqueuelength = undef;
my $vmlargestblocksize = undef;
my $vmtotal16mbfreeblocks = undef;
my $vmtotalfreeblocks = undef;
my $vmtotallargefreeblockbytes = undef;
my $writebytesrpcclientspersec = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'activeanonymoususercount'} = $process->{'ActiveAnonymousUserCount'};
	$risc->{$name}->{'1'}->{'activeconnectioncount'} = $process->{'ActiveConnectionCount'};
	$risc->{$name}->{'1'}->{'activeusercount'} = $process->{'ActiveUserCount'};
	$risc->{$name}->{'1'}->{'adminrpcrequests'} = $process->{'AdminRPCRequests'};
	$risc->{$name}->{'1'}->{'adminrpcrequestspeak'} = $process->{'AdminRPCRequestsPeak'};
	$risc->{$name}->{'1'}->{'anonymoususercount'} = $process->{'AnonymousUserCount'};
	$risc->{$name}->{'1'}->{'appointmentinstancecreationrate'} = $process->{'AppointmentInstanceCreationRate'};
	$risc->{$name}->{'1'}->{'appointmentinstancedeletionrate'} = $process->{'AppointmentInstanceDeletionRate'};
	$risc->{$name}->{'1'}->{'appointmentinstancescreated'} = $process->{'AppointmentInstancesCreated'};
	$risc->{$name}->{'1'}->{'appointmentinstancesdeleted'} = $process->{'AppointmentInstancesDeleted'};
	$risc->{$name}->{'1'}->{'asyncnotificationscachesize'} = $process->{'AsyncNotificationsCacheSize'};
	$risc->{$name}->{'1'}->{'asyncnotificationsgeneratedpersec'} = $process->{'AsyncNotificationsGeneratedPersec'};
	$risc->{$name}->{'1'}->{'asyncrpcrequests'} = $process->{'AsyncRPCRequests'};
	$risc->{$name}->{'1'}->{'asyncrpcrequestspeak'} = $process->{'AsyncRPCRequestsPeak'};
	$risc->{$name}->{'1'}->{'backgroundexpansionqueuelength'} = $process->{'BackgroundExpansionQueueLength'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'ciqpthreads'} = $process->{'CIQPThreads'};
	$risc->{$name}->{'1'}->{'clientbackgroundrpcsfailed'} = $process->{'ClientBackgroundRPCsFailed'};
	$risc->{$name}->{'1'}->{'clientbackgroundrpcsfailedpersec'} = $process->{'ClientBackgroundRPCsFailedPersec'};
	$risc->{$name}->{'1'}->{'clientbackgroundrpcssucceeded'} = $process->{'ClientBackgroundRPCssucceeded'};
	$risc->{$name}->{'1'}->{'clientbackgroundrpcssucceededpersec'} = $process->{'ClientBackgroundRPCssucceededPersec'};
	$risc->{$name}->{'1'}->{'clientforegroundrpcsfailed'} = $process->{'ClientForegroundRPCsFailed'};
	$risc->{$name}->{'1'}->{'clientforegroundrpcsfailedpersec'} = $process->{'ClientForegroundRPCsFailedPersec'};
	$risc->{$name}->{'1'}->{'clientforegroundrpcssucceeded'} = $process->{'ClientForegroundRPCssucceeded'};
	$risc->{$name}->{'1'}->{'clientforegroundrpcssucceededpersec'} = $process->{'ClientForegroundRPCssucceededPersec'};
	$risc->{$name}->{'1'}->{'clientlatency10secrpcs'} = $process->{'ClientLatency10secRPCs'};
	$risc->{$name}->{'1'}->{'clientlatency2secrpcs'} = $process->{'ClientLatency2secRPCs'};
	$risc->{$name}->{'1'}->{'clientlatency5secrpcs'} = $process->{'ClientLatency5secRPCs'};
	$risc->{$name}->{'1'}->{'clientrpcsattempted'} = $process->{'ClientRPCsattempted'};
	$risc->{$name}->{'1'}->{'clientrpcsattemptedpersec'} = $process->{'ClientRPCsattemptedPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailed'} = $process->{'ClientRPCsFailed'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedaccessdenied'} = $process->{'ClientRPCsFailedAccessDenied'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedaccessdeniedpersec'} = $process->{'ClientRPCsFailedAccessDeniedPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedallothererrors'} = $process->{'ClientRPCsFailedAllothererrors'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedallothererrorspersec'} = $process->{'ClientRPCsFailedAllothererrorsPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedcallcancelled'} = $process->{'ClientRPCsFailedCallCancelled'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedcallcancelledpersec'} = $process->{'ClientRPCsFailedCallCancelledPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedcallfailed'} = $process->{'ClientRPCsFailedCallFailed'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedcallfailedpersec'} = $process->{'ClientRPCsFailedCallFailedPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedpersec'} = $process->{'ClientRPCsFailedPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedservertoobusy'} = $process->{'ClientRPCsFailedServerTooBusy'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedservertoobusypersec'} = $process->{'ClientRPCsFailedServerTooBusyPersec'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedserverunavailable'} = $process->{'ClientRPCsFailedServerUnavailable'};
	$risc->{$name}->{'1'}->{'clientrpcsfailedserverunavailablepersec'} = $process->{'ClientRPCsFailedServerUnavailablePersec'};
	$risc->{$name}->{'1'}->{'clientrpcssucceeded'} = $process->{'ClientRPCssucceeded'};
	$risc->{$name}->{'1'}->{'clientrpcssucceededpersec'} = $process->{'ClientRPCssucceededPersec'};
	$risc->{$name}->{'1'}->{'clienttotalreportedlatency'} = $process->{'ClientTotalreportedlatency'};
	$risc->{$name}->{'1'}->{'connectioncount'} = $process->{'ConnectionCount'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'dlmembershipcacheentriescount'} = $process->{'DLmembershipcacheentriescount'};
	$risc->{$name}->{'1'}->{'dlmembershipcachehits'} = $process->{'DLmembershipcachehits'};
	$risc->{$name}->{'1'}->{'dlmembershipcachemisses'} = $process->{'DLmembershipcachemisses'};
	$risc->{$name}->{'1'}->{'dlmembershipcachesize'} = $process->{'DLmembershipcachesize'};
	$risc->{$name}->{'1'}->{'exchmemcurrentbytesallocated'} = $process->{'ExchmemCurrentBytesAllocated'};
	$risc->{$name}->{'1'}->{'exchmemcurrentnumberofvirtualallocations'} = $process->{'ExchmemCurrentNumberofVirtualAllocations'};
	$risc->{$name}->{'1'}->{'exchmemcurrentvirtualbytesallocated'} = $process->{'ExchmemCurrentVirtualBytesAllocated'};
	$risc->{$name}->{'1'}->{'exchmemmaximumbytesallocated'} = $process->{'ExchmemMaximumBytesAllocated'};
	$risc->{$name}->{'1'}->{'exchmemmaximumvirtualbytesallocated'} = $process->{'ExchmemMaximumVirtualBytesAllocated'};
	$risc->{$name}->{'1'}->{'exchmemnumberofadditionalheaps'} = $process->{'ExchmemNumberofAdditionalHeaps'};
	$risc->{$name}->{'1'}->{'exchmemnumberofheaps'} = $process->{'ExchmemNumberofHeaps'};
	$risc->{$name}->{'1'}->{'exchmemnumberofheapswithmemoryerrors'} = $process->{'ExchmemNumberofheapswithmemoryerrors'};
	$risc->{$name}->{'1'}->{'exchmemnumberofmemoryerrors'} = $process->{'ExchmemNumberofmemoryerrors'};
	$risc->{$name}->{'1'}->{'exchmemtotalnumberofvirtualallocations'} = $process->{'ExchmemTotalNumberofVirtualAllocations'};
	$risc->{$name}->{'1'}->{'fbpublishcount'} = $process->{'FBPublishCount'};
	$risc->{$name}->{'1'}->{'fbpublishrate'} = $process->{'FBPublishRate'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'maximumanonymoususers'} = $process->{'MaximumAnonymousUsers'};
	$risc->{$name}->{'1'}->{'maximumconnections'} = $process->{'MaximumConnections'};
	$risc->{$name}->{'1'}->{'maximumusers'} = $process->{'MaximumUsers'};
	$risc->{$name}->{'1'}->{'messagecreatepersec'} = $process->{'MessageCreatePersec'};
	$risc->{$name}->{'1'}->{'messagedeletepersec'} = $process->{'MessageDeletePersec'};
	$risc->{$name}->{'1'}->{'messagemodifypersec'} = $process->{'MessageModifyPersec'};
	$risc->{$name}->{'1'}->{'messagemovepersec'} = $process->{'MessageMovePersec'};
	$risc->{$name}->{'1'}->{'messagesprereadascendingpersec'} = $process->{'MessagesPrereadAscendingPersec'};
	$risc->{$name}->{'1'}->{'messagesprereaddescendingpersec'} = $process->{'MessagesPrereadDescendingPersec'};
	$risc->{$name}->{'1'}->{'messagesprereadskippedpersec'} = $process->{'MessagesPrereadSkippedPersec'};
	$risc->{$name}->{'1'}->{'minimsgcreatedforviewspersec'} = $process->{'MinimsgcreatedforviewsPersec'};
	$risc->{$name}->{'1'}->{'minimsgmsgtableseekspersec'} = $process->{'MinimsgMsgtableseeksPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsdeletedpersec'} = $process->{'MsgViewRecordsDeletedPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsdeletesdeferredpersec'} = $process->{'MsgViewRecordsDeletesDeferredPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsinsertedpersec'} = $process->{'MsgViewRecordsInsertedPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsinsertsdeferredpersec'} = $process->{'MsgViewRecordsInsertsDeferredPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablecreatepersec'} = $process->{'MsgViewtableCreatePersec'};
	$risc->{$name}->{'1'}->{'msgviewtabledeletepersec'} = $process->{'MsgViewtableDeletePersec'};
	$risc->{$name}->{'1'}->{'msgviewtablenullrefreshpersec'} = $process->{'MsgViewtableNullRefreshPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshdvurecordsscanned'} = $process->{'MsgViewtablerefreshDVUrecordsscanned'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshdvurecordsscanned_base'} = $process->{'MsgViewtablerefreshDVUrecordsscanned_Base'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshpersec'} = $process->{'MsgViewtableRefreshPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshupdatesapplied'} = $process->{'MsgViewtablerefreshupdatesapplied'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshupdatesapplied_base'} = $process->{'MsgViewtablerefreshupdatesapplied_Base'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'oabdifferentialdownloadattempts'} = $process->{'OABDifferentialDownloadAttempts'};
	$risc->{$name}->{'1'}->{'oabdifferentialdownloadbytes'} = $process->{'OABDifferentialDownloadBytes'};
	$risc->{$name}->{'1'}->{'oabdifferentialdownloadbytespersec'} = $process->{'OABDifferentialDownloadBytesPersec'};
	$risc->{$name}->{'1'}->{'oabfulldownloadattempts'} = $process->{'OABFullDownloadAttempts'};
	$risc->{$name}->{'1'}->{'oabfulldownloadattemptsblocked'} = $process->{'OABFullDownloadAttemptsBlocked'};
	$risc->{$name}->{'1'}->{'oabfulldownloadbytes'} = $process->{'OABFullDownloadBytes'};
	$risc->{$name}->{'1'}->{'oabfulldownloadbytespersec'} = $process->{'OABFullDownloadBytesPersec'};
	$risc->{$name}->{'1'}->{'peakasyncnotificationscachesize'} = $process->{'PeakAsyncNotificationsCacheSize'};
	$risc->{$name}->{'1'}->{'peakpushnotificationscachesize'} = $process->{'PeakPushNotificationsCacheSize'};
	$risc->{$name}->{'1'}->{'percentconnections'} = $process->{'PercentConnections'};
	$risc->{$name}->{'1'}->{'percentconnections_base'} = $process->{'PercentConnections_Base'};
	$risc->{$name}->{'1'}->{'percentrpcthreads'} = $process->{'PercentRPCThreads'};
	$risc->{$name}->{'1'}->{'percentrpcthreads_base'} = $process->{'PercentRPCThreads_Base'};
	$risc->{$name}->{'1'}->{'pushnotificationscachesize'} = $process->{'PushNotificationsCacheSize'};
	$risc->{$name}->{'1'}->{'pushnotificationsgeneratedpersec'} = $process->{'PushNotificationsGeneratedPersec'};
	$risc->{$name}->{'1'}->{'pushnotificationsskippedpersec'} = $process->{'PushNotificationsSkippedPersec'};
	$risc->{$name}->{'1'}->{'readbytesrpcclientspersec'} = $process->{'ReadBytesRPCClientsPersec'};
	$risc->{$name}->{'1'}->{'recurringappointmentdeletionrate'} = $process->{'RecurringAppointmentDeletionRate'};
	$risc->{$name}->{'1'}->{'recurringappointmentmodificationrate'} = $process->{'RecurringAppointmentModificationRate'};
	$risc->{$name}->{'1'}->{'recurringappointmentscreated'} = $process->{'RecurringAppointmentsCreated'};
	$risc->{$name}->{'1'}->{'recurringappointmentsdeleted'} = $process->{'RecurringAppointmentsDeleted'};
	$risc->{$name}->{'1'}->{'recurringappointmentsmodified'} = $process->{'RecurringAppointmentsModified'};
	$risc->{$name}->{'1'}->{'recurringapppointmentcreationrate'} = $process->{'RecurringApppointmentCreationRate'};
	$risc->{$name}->{'1'}->{'recurringmasterappointmentsexpanded'} = $process->{'RecurringMasterAppointmentsExpanded'};
	$risc->{$name}->{'1'}->{'recurringmasterexpansionrate'} = $process->{'RecurringMasterExpansionRate'};
	$risc->{$name}->{'1'}->{'rpcaveragedlatency'} = $process->{'RPCAveragedLatency'};
	$risc->{$name}->{'1'}->{'rpcclientbackoffpersec'} = $process->{'RPCClientBackoffPersec'};
	$risc->{$name}->{'1'}->{'rpcclientsbytesread'} = $process->{'RPCClientsBytesRead'};
	$risc->{$name}->{'1'}->{'rpcclientsbyteswritten'} = $process->{'RPCClientsBytesWritten'};
	$risc->{$name}->{'1'}->{'rpcclientsuncompressedbytesread'} = $process->{'RPCClientsUncompressedBytesRead'};
	$risc->{$name}->{'1'}->{'rpcclientsuncompressedbyteswritten'} = $process->{'RPCClientsUncompressedBytesWritten'};
	$risc->{$name}->{'1'}->{'rpcnumofslowpackets'} = $process->{'RPCNumofSlowPackets'};
	$risc->{$name}->{'1'}->{'rpcoperationspersec'} = $process->{'RPCOperationsPersec'};
	$risc->{$name}->{'1'}->{'rpcpacketspersec'} = $process->{'RPCPacketsPersec'};
	$risc->{$name}->{'1'}->{'rpcpoolasyncnotificationsgeneratedpersec'} = $process->{'RPCPoolAsyncNotificationsGeneratedPersec'};
	$risc->{$name}->{'1'}->{'rpcpoolcontexthandles'} = $process->{'RPCPoolContextHandles'};
	$risc->{$name}->{'1'}->{'rpcpoolparkedasyncnotificationcalls'} = $process->{'RPCPoolParkedAsyncNotificationCalls'};
	$risc->{$name}->{'1'}->{'rpcpoolpools'} = $process->{'RPCPoolPools'};
	$risc->{$name}->{'1'}->{'rpcpoolsessionnotificationspending'} = $process->{'RPCPoolSessionNotificationsPending'};
	$risc->{$name}->{'1'}->{'rpcpoolsessions'} = $process->{'RPCPoolSessions'};
	$risc->{$name}->{'1'}->{'rpcrequests'} = $process->{'RPCRequests'};
	$risc->{$name}->{'1'}->{'rpcrequestspeak'} = $process->{'RPCRequestsPeak'};
	$risc->{$name}->{'1'}->{'rpcrequesttimeoutdetected'} = $process->{'RPCRequestTimeoutDetected'};
	$risc->{$name}->{'1'}->{'singleappointmentcreationrate'} = $process->{'SingleAppointmentCreationRate'};
	$risc->{$name}->{'1'}->{'singleappointmentdeletionrate'} = $process->{'SingleAppointmentDeletionRate'};
	$risc->{$name}->{'1'}->{'singleappointmentmodificationrate'} = $process->{'SingleAppointmentModificationRate'};
	$risc->{$name}->{'1'}->{'singleappointmentscreated'} = $process->{'SingleAppointmentsCreated'};
	$risc->{$name}->{'1'}->{'singleappointmentsdeleted'} = $process->{'SingleAppointmentsDeleted'};
	$risc->{$name}->{'1'}->{'singleappointmentsmodified'} = $process->{'SingleAppointmentsModified'};
	$risc->{$name}->{'1'}->{'slowqpthreads'} = $process->{'SlowQPThreads'};
	$risc->{$name}->{'1'}->{'slowsearchthreads'} = $process->{'SlowSearchThreads'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalparkedasyncnotificationcalls'} = $process->{'TotalParkedAsyncNotificationCalls'};
	$risc->{$name}->{'1'}->{'usercount'} = $process->{'UserCount'};
	$risc->{$name}->{'1'}->{'viewcleanupcategorizationindexdeletionspersec'} = $process->{'ViewCleanupCategorizationIndexDeletionsPersec'};
	$risc->{$name}->{'1'}->{'viewcleanupdvuentrydeletionspersec'} = $process->{'ViewCleanupDVUEntryDeletionsPersec'};
	$risc->{$name}->{'1'}->{'viewcleanuprestrictionindexdeletionspersec'} = $process->{'ViewCleanupRestrictionIndexDeletionsPersec'};
	$risc->{$name}->{'1'}->{'viewcleanupsearchindexdeletionspersec'} = $process->{'ViewCleanupSearchIndexDeletionsPersec'};
	$risc->{$name}->{'1'}->{'viewcleanupsortindexdeletionspersec'} = $process->{'ViewCleanupSortIndexDeletionsPersec'};
	$risc->{$name}->{'1'}->{'viewcleanuptasksnullifiedpersec'} = $process->{'ViewCleanupTasksNullifiedPersec'};
	$risc->{$name}->{'1'}->{'viewcleanuptaskspersec'} = $process->{'ViewCleanupTasksPersec'};
	$risc->{$name}->{'1'}->{'virusscanbytesscanned'} = $process->{'VirusScanBytesScanned'};
	$risc->{$name}->{'1'}->{'virusscanfilescleaned'} = $process->{'VirusScanFilesCleaned'};
	$risc->{$name}->{'1'}->{'virusscanfilescleanedpersec'} = $process->{'VirusScanFilesCleanedPersec'};
	$risc->{$name}->{'1'}->{'virusscanfilesquarantined'} = $process->{'VirusScanFilesQuarantined'};
	$risc->{$name}->{'1'}->{'virusscanfilesquarantinedpersec'} = $process->{'VirusScanFilesQuarantinedPersec'};
	$risc->{$name}->{'1'}->{'virusscanfilesscanned'} = $process->{'VirusScanFilesScanned'};
	$risc->{$name}->{'1'}->{'virusscanfilesscannedpersec'} = $process->{'VirusScanFilesScannedPersec'};
	$risc->{$name}->{'1'}->{'virusscanfoldersscannedinbackground'} = $process->{'VirusScanFoldersScannedinBackground'};
	$risc->{$name}->{'1'}->{'virusscanmessagescleaned'} = $process->{'VirusScanMessagesCleaned'};
	$risc->{$name}->{'1'}->{'virusscanmessagescleanedpersec'} = $process->{'VirusScanMessagesCleanedPersec'};
	$risc->{$name}->{'1'}->{'virusscanmessagesdeleted'} = $process->{'VirusScanMessagesDeleted'};
	$risc->{$name}->{'1'}->{'virusscanmessagesdeletedpersec'} = $process->{'VirusScanMessagesDeletedPersec'};
	$risc->{$name}->{'1'}->{'virusscanmessagesprocessed'} = $process->{'VirusScanMessagesProcessed'};
	$risc->{$name}->{'1'}->{'virusscanmessagesprocessedpersec'} = $process->{'VirusScanMessagesProcessedPersec'};
	$risc->{$name}->{'1'}->{'virusscanmessagesquarantined'} = $process->{'VirusScanMessagesQuarantined'};
	$risc->{$name}->{'1'}->{'virusscanmessagesquarantinedpersec'} = $process->{'VirusScanMessagesQuarantinedPersec'};
	$risc->{$name}->{'1'}->{'virusscanmessagesscannedinbackground'} = $process->{'VirusScanMessagesScannedinBackground'};
	$risc->{$name}->{'1'}->{'virusscanqueuelength'} = $process->{'VirusScanQueueLength'};
	$risc->{$name}->{'1'}->{'vmlargestblocksize'} = $process->{'VMLargestBlockSize'};
	$risc->{$name}->{'1'}->{'vmtotal16mbfreeblocks'} = $process->{'VMTotal16MBFreeBlocks'};
	$risc->{$name}->{'1'}->{'vmtotalfreeblocks'} = $process->{'VMTotalFreeBlocks'};
	$risc->{$name}->{'1'}->{'vmtotallargefreeblockbytes'} = $process->{'VMTotalLargeFreeBlockBytes'};
	$risc->{$name}->{'1'}->{'writebytesrpcclientspersec'} = $process->{'WriteBytesRPCClientsPersec'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'activeanonymoususercount'} = $process->{'ActiveAnonymousUserCount'};
	$risc->{$name}->{'2'}->{'activeconnectioncount'} = $process->{'ActiveConnectionCount'};
	$risc->{$name}->{'2'}->{'activeusercount'} = $process->{'ActiveUserCount'};
	$risc->{$name}->{'2'}->{'adminrpcrequests'} = $process->{'AdminRPCRequests'};
	$risc->{$name}->{'2'}->{'adminrpcrequestspeak'} = $process->{'AdminRPCRequestsPeak'};
	$risc->{$name}->{'2'}->{'anonymoususercount'} = $process->{'AnonymousUserCount'};
	$risc->{$name}->{'2'}->{'appointmentinstancecreationrate'} = $process->{'AppointmentInstanceCreationRate'};
	$risc->{$name}->{'2'}->{'appointmentinstancedeletionrate'} = $process->{'AppointmentInstanceDeletionRate'};
	$risc->{$name}->{'2'}->{'appointmentinstancescreated'} = $process->{'AppointmentInstancesCreated'};
	$risc->{$name}->{'2'}->{'appointmentinstancesdeleted'} = $process->{'AppointmentInstancesDeleted'};
	$risc->{$name}->{'2'}->{'asyncnotificationscachesize'} = $process->{'AsyncNotificationsCacheSize'};
	$risc->{$name}->{'2'}->{'asyncnotificationsgeneratedpersec'} = $process->{'AsyncNotificationsGeneratedPersec'};
	$risc->{$name}->{'2'}->{'asyncrpcrequests'} = $process->{'AsyncRPCRequests'};
	$risc->{$name}->{'2'}->{'asyncrpcrequestspeak'} = $process->{'AsyncRPCRequestsPeak'};
	$risc->{$name}->{'2'}->{'backgroundexpansionqueuelength'} = $process->{'BackgroundExpansionQueueLength'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'ciqpthreads'} = $process->{'CIQPThreads'};
	$risc->{$name}->{'2'}->{'clientbackgroundrpcsfailed'} = $process->{'ClientBackgroundRPCsFailed'};
	$risc->{$name}->{'2'}->{'clientbackgroundrpcsfailedpersec'} = $process->{'ClientBackgroundRPCsFailedPersec'};
	$risc->{$name}->{'2'}->{'clientbackgroundrpcssucceeded'} = $process->{'ClientBackgroundRPCssucceeded'};
	$risc->{$name}->{'2'}->{'clientbackgroundrpcssucceededpersec'} = $process->{'ClientBackgroundRPCssucceededPersec'};
	$risc->{$name}->{'2'}->{'clientforegroundrpcsfailed'} = $process->{'ClientForegroundRPCsFailed'};
	$risc->{$name}->{'2'}->{'clientforegroundrpcsfailedpersec'} = $process->{'ClientForegroundRPCsFailedPersec'};
	$risc->{$name}->{'2'}->{'clientforegroundrpcssucceeded'} = $process->{'ClientForegroundRPCssucceeded'};
	$risc->{$name}->{'2'}->{'clientforegroundrpcssucceededpersec'} = $process->{'ClientForegroundRPCssucceededPersec'};
	$risc->{$name}->{'2'}->{'clientlatency10secrpcs'} = $process->{'ClientLatency10secRPCs'};
	$risc->{$name}->{'2'}->{'clientlatency2secrpcs'} = $process->{'ClientLatency2secRPCs'};
	$risc->{$name}->{'2'}->{'clientlatency5secrpcs'} = $process->{'ClientLatency5secRPCs'};
	$risc->{$name}->{'2'}->{'clientrpcsattempted'} = $process->{'ClientRPCsattempted'};
	$risc->{$name}->{'2'}->{'clientrpcsattemptedpersec'} = $process->{'ClientRPCsattemptedPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailed'} = $process->{'ClientRPCsFailed'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedaccessdenied'} = $process->{'ClientRPCsFailedAccessDenied'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedaccessdeniedpersec'} = $process->{'ClientRPCsFailedAccessDeniedPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedallothererrors'} = $process->{'ClientRPCsFailedAllothererrors'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedallothererrorspersec'} = $process->{'ClientRPCsFailedAllothererrorsPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedcallcancelled'} = $process->{'ClientRPCsFailedCallCancelled'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedcallcancelledpersec'} = $process->{'ClientRPCsFailedCallCancelledPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedcallfailed'} = $process->{'ClientRPCsFailedCallFailed'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedcallfailedpersec'} = $process->{'ClientRPCsFailedCallFailedPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedpersec'} = $process->{'ClientRPCsFailedPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedservertoobusy'} = $process->{'ClientRPCsFailedServerTooBusy'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedservertoobusypersec'} = $process->{'ClientRPCsFailedServerTooBusyPersec'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedserverunavailable'} = $process->{'ClientRPCsFailedServerUnavailable'};
	$risc->{$name}->{'2'}->{'clientrpcsfailedserverunavailablepersec'} = $process->{'ClientRPCsFailedServerUnavailablePersec'};
	$risc->{$name}->{'2'}->{'clientrpcssucceeded'} = $process->{'ClientRPCssucceeded'};
	$risc->{$name}->{'2'}->{'clientrpcssucceededpersec'} = $process->{'ClientRPCssucceededPersec'};
	$risc->{$name}->{'2'}->{'clienttotalreportedlatency'} = $process->{'ClientTotalreportedlatency'};
	$risc->{$name}->{'2'}->{'connectioncount'} = $process->{'ConnectionCount'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'dlmembershipcacheentriescount'} = $process->{'DLmembershipcacheentriescount'};
	$risc->{$name}->{'2'}->{'dlmembershipcachehits'} = $process->{'DLmembershipcachehits'};
	$risc->{$name}->{'2'}->{'dlmembershipcachemisses'} = $process->{'DLmembershipcachemisses'};
	$risc->{$name}->{'2'}->{'dlmembershipcachesize'} = $process->{'DLmembershipcachesize'};
	$risc->{$name}->{'2'}->{'exchmemcurrentbytesallocated'} = $process->{'ExchmemCurrentBytesAllocated'};
	$risc->{$name}->{'2'}->{'exchmemcurrentnumberofvirtualallocations'} = $process->{'ExchmemCurrentNumberofVirtualAllocations'};
	$risc->{$name}->{'2'}->{'exchmemcurrentvirtualbytesallocated'} = $process->{'ExchmemCurrentVirtualBytesAllocated'};
	$risc->{$name}->{'2'}->{'exchmemmaximumbytesallocated'} = $process->{'ExchmemMaximumBytesAllocated'};
	$risc->{$name}->{'2'}->{'exchmemmaximumvirtualbytesallocated'} = $process->{'ExchmemMaximumVirtualBytesAllocated'};
	$risc->{$name}->{'2'}->{'exchmemnumberofadditionalheaps'} = $process->{'ExchmemNumberofAdditionalHeaps'};
	$risc->{$name}->{'2'}->{'exchmemnumberofheaps'} = $process->{'ExchmemNumberofHeaps'};
	$risc->{$name}->{'2'}->{'exchmemnumberofheapswithmemoryerrors'} = $process->{'ExchmemNumberofheapswithmemoryerrors'};
	$risc->{$name}->{'2'}->{'exchmemnumberofmemoryerrors'} = $process->{'ExchmemNumberofmemoryerrors'};
	$risc->{$name}->{'2'}->{'exchmemtotalnumberofvirtualallocations'} = $process->{'ExchmemTotalNumberofVirtualAllocations'};
	$risc->{$name}->{'2'}->{'fbpublishcount'} = $process->{'FBPublishCount'};
	$risc->{$name}->{'2'}->{'fbpublishrate'} = $process->{'FBPublishRate'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'maximumanonymoususers'} = $process->{'MaximumAnonymousUsers'};
	$risc->{$name}->{'2'}->{'maximumconnections'} = $process->{'MaximumConnections'};
	$risc->{$name}->{'2'}->{'maximumusers'} = $process->{'MaximumUsers'};
	$risc->{$name}->{'2'}->{'messagecreatepersec'} = $process->{'MessageCreatePersec'};
	$risc->{$name}->{'2'}->{'messagedeletepersec'} = $process->{'MessageDeletePersec'};
	$risc->{$name}->{'2'}->{'messagemodifypersec'} = $process->{'MessageModifyPersec'};
	$risc->{$name}->{'2'}->{'messagemovepersec'} = $process->{'MessageMovePersec'};
	$risc->{$name}->{'2'}->{'messagesprereadascendingpersec'} = $process->{'MessagesPrereadAscendingPersec'};
	$risc->{$name}->{'2'}->{'messagesprereaddescendingpersec'} = $process->{'MessagesPrereadDescendingPersec'};
	$risc->{$name}->{'2'}->{'messagesprereadskippedpersec'} = $process->{'MessagesPrereadSkippedPersec'};
	$risc->{$name}->{'2'}->{'minimsgcreatedforviewspersec'} = $process->{'MinimsgcreatedforviewsPersec'};
	$risc->{$name}->{'2'}->{'minimsgmsgtableseekspersec'} = $process->{'MinimsgMsgtableseeksPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsdeletedpersec'} = $process->{'MsgViewRecordsDeletedPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsdeletesdeferredpersec'} = $process->{'MsgViewRecordsDeletesDeferredPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsinsertedpersec'} = $process->{'MsgViewRecordsInsertedPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsinsertsdeferredpersec'} = $process->{'MsgViewRecordsInsertsDeferredPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablecreatepersec'} = $process->{'MsgViewtableCreatePersec'};
	$risc->{$name}->{'2'}->{'msgviewtabledeletepersec'} = $process->{'MsgViewtableDeletePersec'};
	$risc->{$name}->{'2'}->{'msgviewtablenullrefreshpersec'} = $process->{'MsgViewtableNullRefreshPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshdvurecordsscanned'} = $process->{'MsgViewtablerefreshDVUrecordsscanned'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshdvurecordsscanned_base'} = $process->{'MsgViewtablerefreshDVUrecordsscanned_Base'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshpersec'} = $process->{'MsgViewtableRefreshPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshupdatesapplied'} = $process->{'MsgViewtablerefreshupdatesapplied'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshupdatesapplied_base'} = $process->{'MsgViewtablerefreshupdatesapplied_Base'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'oabdifferentialdownloadattempts'} = $process->{'OABDifferentialDownloadAttempts'};
	$risc->{$name}->{'2'}->{'oabdifferentialdownloadbytes'} = $process->{'OABDifferentialDownloadBytes'};
	$risc->{$name}->{'2'}->{'oabdifferentialdownloadbytespersec'} = $process->{'OABDifferentialDownloadBytesPersec'};
	$risc->{$name}->{'2'}->{'oabfulldownloadattempts'} = $process->{'OABFullDownloadAttempts'};
	$risc->{$name}->{'2'}->{'oabfulldownloadattemptsblocked'} = $process->{'OABFullDownloadAttemptsBlocked'};
	$risc->{$name}->{'2'}->{'oabfulldownloadbytes'} = $process->{'OABFullDownloadBytes'};
	$risc->{$name}->{'2'}->{'oabfulldownloadbytespersec'} = $process->{'OABFullDownloadBytesPersec'};
	$risc->{$name}->{'2'}->{'peakasyncnotificationscachesize'} = $process->{'PeakAsyncNotificationsCacheSize'};
	$risc->{$name}->{'2'}->{'peakpushnotificationscachesize'} = $process->{'PeakPushNotificationsCacheSize'};
	$risc->{$name}->{'2'}->{'percentconnections'} = $process->{'PercentConnections'};
	$risc->{$name}->{'2'}->{'percentconnections_base'} = $process->{'PercentConnections_Base'};
	$risc->{$name}->{'2'}->{'percentrpcthreads'} = $process->{'PercentRPCThreads'};
	$risc->{$name}->{'2'}->{'percentrpcthreads_base'} = $process->{'PercentRPCThreads_Base'};
	$risc->{$name}->{'2'}->{'pushnotificationscachesize'} = $process->{'PushNotificationsCacheSize'};
	$risc->{$name}->{'2'}->{'pushnotificationsgeneratedpersec'} = $process->{'PushNotificationsGeneratedPersec'};
	$risc->{$name}->{'2'}->{'pushnotificationsskippedpersec'} = $process->{'PushNotificationsSkippedPersec'};
	$risc->{$name}->{'2'}->{'readbytesrpcclientspersec'} = $process->{'ReadBytesRPCClientsPersec'};
	$risc->{$name}->{'2'}->{'recurringappointmentdeletionrate'} = $process->{'RecurringAppointmentDeletionRate'};
	$risc->{$name}->{'2'}->{'recurringappointmentmodificationrate'} = $process->{'RecurringAppointmentModificationRate'};
	$risc->{$name}->{'2'}->{'recurringappointmentscreated'} = $process->{'RecurringAppointmentsCreated'};
	$risc->{$name}->{'2'}->{'recurringappointmentsdeleted'} = $process->{'RecurringAppointmentsDeleted'};
	$risc->{$name}->{'2'}->{'recurringappointmentsmodified'} = $process->{'RecurringAppointmentsModified'};
	$risc->{$name}->{'2'}->{'recurringapppointmentcreationrate'} = $process->{'RecurringApppointmentCreationRate'};
	$risc->{$name}->{'2'}->{'recurringmasterappointmentsexpanded'} = $process->{'RecurringMasterAppointmentsExpanded'};
	$risc->{$name}->{'2'}->{'recurringmasterexpansionrate'} = $process->{'RecurringMasterExpansionRate'};
	$risc->{$name}->{'2'}->{'rpcaveragedlatency'} = $process->{'RPCAveragedLatency'};
	$risc->{$name}->{'2'}->{'rpcclientbackoffpersec'} = $process->{'RPCClientBackoffPersec'};
	$risc->{$name}->{'2'}->{'rpcclientsbytesread'} = $process->{'RPCClientsBytesRead'};
	$risc->{$name}->{'2'}->{'rpcclientsbyteswritten'} = $process->{'RPCClientsBytesWritten'};
	$risc->{$name}->{'2'}->{'rpcclientsuncompressedbytesread'} = $process->{'RPCClientsUncompressedBytesRead'};
	$risc->{$name}->{'2'}->{'rpcclientsuncompressedbyteswritten'} = $process->{'RPCClientsUncompressedBytesWritten'};
	$risc->{$name}->{'2'}->{'rpcnumofslowpackets'} = $process->{'RPCNumofSlowPackets'};
	$risc->{$name}->{'2'}->{'rpcoperationspersec'} = $process->{'RPCOperationsPersec'};
	$risc->{$name}->{'2'}->{'rpcpacketspersec'} = $process->{'RPCPacketsPersec'};
	$risc->{$name}->{'2'}->{'rpcpoolasyncnotificationsgeneratedpersec'} = $process->{'RPCPoolAsyncNotificationsGeneratedPersec'};
	$risc->{$name}->{'2'}->{'rpcpoolcontexthandles'} = $process->{'RPCPoolContextHandles'};
	$risc->{$name}->{'2'}->{'rpcpoolparkedasyncnotificationcalls'} = $process->{'RPCPoolParkedAsyncNotificationCalls'};
	$risc->{$name}->{'2'}->{'rpcpoolpools'} = $process->{'RPCPoolPools'};
	$risc->{$name}->{'2'}->{'rpcpoolsessionnotificationspending'} = $process->{'RPCPoolSessionNotificationsPending'};
	$risc->{$name}->{'2'}->{'rpcpoolsessions'} = $process->{'RPCPoolSessions'};
	$risc->{$name}->{'2'}->{'rpcrequests'} = $process->{'RPCRequests'};
	$risc->{$name}->{'2'}->{'rpcrequestspeak'} = $process->{'RPCRequestsPeak'};
	$risc->{$name}->{'2'}->{'rpcrequesttimeoutdetected'} = $process->{'RPCRequestTimeoutDetected'};
	$risc->{$name}->{'2'}->{'singleappointmentcreationrate'} = $process->{'SingleAppointmentCreationRate'};
	$risc->{$name}->{'2'}->{'singleappointmentdeletionrate'} = $process->{'SingleAppointmentDeletionRate'};
	$risc->{$name}->{'2'}->{'singleappointmentmodificationrate'} = $process->{'SingleAppointmentModificationRate'};
	$risc->{$name}->{'2'}->{'singleappointmentscreated'} = $process->{'SingleAppointmentsCreated'};
	$risc->{$name}->{'2'}->{'singleappointmentsdeleted'} = $process->{'SingleAppointmentsDeleted'};
	$risc->{$name}->{'2'}->{'singleappointmentsmodified'} = $process->{'SingleAppointmentsModified'};
	$risc->{$name}->{'2'}->{'slowqpthreads'} = $process->{'SlowQPThreads'};
	$risc->{$name}->{'2'}->{'slowsearchthreads'} = $process->{'SlowSearchThreads'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalparkedasyncnotificationcalls'} = $process->{'TotalParkedAsyncNotificationCalls'};
	$risc->{$name}->{'2'}->{'usercount'} = $process->{'UserCount'};
	$risc->{$name}->{'2'}->{'viewcleanupcategorizationindexdeletionspersec'} = $process->{'ViewCleanupCategorizationIndexDeletionsPersec'};
	$risc->{$name}->{'2'}->{'viewcleanupdvuentrydeletionspersec'} = $process->{'ViewCleanupDVUEntryDeletionsPersec'};
	$risc->{$name}->{'2'}->{'viewcleanuprestrictionindexdeletionspersec'} = $process->{'ViewCleanupRestrictionIndexDeletionsPersec'};
	$risc->{$name}->{'2'}->{'viewcleanupsearchindexdeletionspersec'} = $process->{'ViewCleanupSearchIndexDeletionsPersec'};
	$risc->{$name}->{'2'}->{'viewcleanupsortindexdeletionspersec'} = $process->{'ViewCleanupSortIndexDeletionsPersec'};
	$risc->{$name}->{'2'}->{'viewcleanuptasksnullifiedpersec'} = $process->{'ViewCleanupTasksNullifiedPersec'};
	$risc->{$name}->{'2'}->{'viewcleanuptaskspersec'} = $process->{'ViewCleanupTasksPersec'};
	$risc->{$name}->{'2'}->{'virusscanbytesscanned'} = $process->{'VirusScanBytesScanned'};
	$risc->{$name}->{'2'}->{'virusscanfilescleaned'} = $process->{'VirusScanFilesCleaned'};
	$risc->{$name}->{'2'}->{'virusscanfilescleanedpersec'} = $process->{'VirusScanFilesCleanedPersec'};
	$risc->{$name}->{'2'}->{'virusscanfilesquarantined'} = $process->{'VirusScanFilesQuarantined'};
	$risc->{$name}->{'2'}->{'virusscanfilesquarantinedpersec'} = $process->{'VirusScanFilesQuarantinedPersec'};
	$risc->{$name}->{'2'}->{'virusscanfilesscanned'} = $process->{'VirusScanFilesScanned'};
	$risc->{$name}->{'2'}->{'virusscanfilesscannedpersec'} = $process->{'VirusScanFilesScannedPersec'};
	$risc->{$name}->{'2'}->{'virusscanfoldersscannedinbackground'} = $process->{'VirusScanFoldersScannedinBackground'};
	$risc->{$name}->{'2'}->{'virusscanmessagescleaned'} = $process->{'VirusScanMessagesCleaned'};
	$risc->{$name}->{'2'}->{'virusscanmessagescleanedpersec'} = $process->{'VirusScanMessagesCleanedPersec'};
	$risc->{$name}->{'2'}->{'virusscanmessagesdeleted'} = $process->{'VirusScanMessagesDeleted'};
	$risc->{$name}->{'2'}->{'virusscanmessagesdeletedpersec'} = $process->{'VirusScanMessagesDeletedPersec'};
	$risc->{$name}->{'2'}->{'virusscanmessagesprocessed'} = $process->{'VirusScanMessagesProcessed'};
	$risc->{$name}->{'2'}->{'virusscanmessagesprocessedpersec'} = $process->{'VirusScanMessagesProcessedPersec'};
	$risc->{$name}->{'2'}->{'virusscanmessagesquarantined'} = $process->{'VirusScanMessagesQuarantined'};
	$risc->{$name}->{'2'}->{'virusscanmessagesquarantinedpersec'} = $process->{'VirusScanMessagesQuarantinedPersec'};
	$risc->{$name}->{'2'}->{'virusscanmessagesscannedinbackground'} = $process->{'VirusScanMessagesScannedinBackground'};
	$risc->{$name}->{'2'}->{'virusscanqueuelength'} = $process->{'VirusScanQueueLength'};
	$risc->{$name}->{'2'}->{'vmlargestblocksize'} = $process->{'VMLargestBlockSize'};
	$risc->{$name}->{'2'}->{'vmtotal16mbfreeblocks'} = $process->{'VMTotal16MBFreeBlocks'};
	$risc->{$name}->{'2'}->{'vmtotalfreeblocks'} = $process->{'VMTotalFreeBlocks'};
	$risc->{$name}->{'2'}->{'vmtotallargefreeblockbytes'} = $process->{'VMTotalLargeFreeBlockBytes'};
	$risc->{$name}->{'2'}->{'writebytesrpcclientspersec'} = $process->{'WriteBytesRPCClientsPersec'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;


	#---find ActiveAnonymousUserCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeanonymoususercount = $risc->{$calname}->{'2'}->{'activeanonymoususercount'};
#	print "ActiveAnonymousUserCount: $activeanonymoususercount \n\n";


	#---find ActiveConnectionCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeconnectioncount = $risc->{$calname}->{'2'}->{'activeconnectioncount'};
#	print "ActiveConnectionCount: $activeconnectioncount \n\n";


	#---find ActiveUserCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeusercount = $risc->{$calname}->{'2'}->{'activeusercount'};
#	print "ActiveUserCount: $activeusercount \n\n";


	#---find AdminRPCRequests---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$adminrpcrequests = $risc->{$calname}->{'2'}->{'adminrpcrequests'};
#	print "AdminRPCRequests: $adminrpcrequests \n\n";


	#---find AdminRPCRequestsPeak---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$adminrpcrequestspeak = $risc->{$calname}->{'2'}->{'adminrpcrequestspeak'};
#	print "AdminRPCRequestsPeak: $adminrpcrequestspeak \n\n";


	#---find AnonymousUserCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$anonymoususercount = $risc->{$calname}->{'2'}->{'anonymoususercount'};
#	print "AnonymousUserCount: $anonymoususercount \n\n";


	#---find AppointmentInstanceCreationRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'appointmentinstancecreationrate'};	
#	print "AppointmentInstanceCreationRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'appointmentinstancecreationrate'};	
#	print "AppointmentInstanceCreationRate2: $val2 \n";	
	eval 	
	{	
	$appointmentinstancecreationrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "AppointmentInstanceCreationRate: $appointmentinstancecreationrate \n\n";	


	#---find AppointmentInstanceDeletionRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'appointmentinstancedeletionrate'};	
#	print "AppointmentInstanceDeletionRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'appointmentinstancedeletionrate'};	
#	print "AppointmentInstanceDeletionRate2: $val2 \n";	
	eval 	
	{	
	$appointmentinstancedeletionrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "AppointmentInstanceDeletionRate: $appointmentinstancedeletionrate \n\n";	


	#---find AppointmentInstancesCreated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$appointmentinstancescreated = $risc->{$calname}->{'2'}->{'appointmentinstancescreated'};
#	print "AppointmentInstancesCreated: $appointmentinstancescreated \n\n";


	#---find AppointmentInstancesDeleted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$appointmentinstancesdeleted = $risc->{$calname}->{'2'}->{'appointmentinstancesdeleted'};
#	print "AppointmentInstancesDeleted: $appointmentinstancesdeleted \n\n";


	#---find AsyncNotificationsCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$asyncnotificationscachesize = $risc->{$calname}->{'2'}->{'asyncnotificationscachesize'};
#	print "AsyncNotificationsCacheSize: $asyncnotificationscachesize \n\n";


	#---find AsyncNotificationsGeneratedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'asyncnotificationsgeneratedpersec'};	
#	print "AsyncNotificationsGeneratedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'asyncnotificationsgeneratedpersec'};	
#	print "AsyncNotificationsGeneratedPersec2: $val2 \n";	
	eval 	
	{	
	$asyncnotificationsgeneratedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "AsyncNotificationsGeneratedPersec: $asyncnotificationsgeneratedpersec \n\n";	


	#---find AsyncRPCRequests---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$asyncrpcrequests = $risc->{$calname}->{'2'}->{'asyncrpcrequests'};
#	print "AsyncRPCRequests: $asyncrpcrequests \n\n";


	#---find AsyncRPCRequestsPeak---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$asyncrpcrequestspeak = $risc->{$calname}->{'2'}->{'asyncrpcrequestspeak'};
#	print "AsyncRPCRequestsPeak: $asyncrpcrequestspeak \n\n";


	#---find BackgroundExpansionQueueLength---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$backgroundexpansionqueuelength = $risc->{$calname}->{'2'}->{'backgroundexpansionqueuelength'};
#	print "BackgroundExpansionQueueLength: $backgroundexpansionqueuelength \n\n";


	#---find CIQPThreads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$ciqpthreads = $risc->{$calname}->{'2'}->{'ciqpthreads'};
#	print "CIQPThreads: $ciqpthreads \n\n";


	#---find ClientBackgroundRPCsFailed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientbackgroundrpcsfailed = $risc->{$calname}->{'2'}->{'clientbackgroundrpcsfailed'};
#	print "ClientBackgroundRPCsFailed: $clientbackgroundrpcsfailed \n\n";


	#---find ClientBackgroundRPCsFailedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientbackgroundrpcsfailedpersec'};	
#	print "ClientBackgroundRPCsFailedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientbackgroundrpcsfailedpersec'};	
#	print "ClientBackgroundRPCsFailedPersec2: $val2 \n";	
	eval 	
	{	
	$clientbackgroundrpcsfailedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientBackgroundRPCsFailedPersec: $clientbackgroundrpcsfailedpersec \n\n";	


	#---find ClientBackgroundRPCssucceeded---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientbackgroundrpcssucceeded = $risc->{$calname}->{'2'}->{'clientbackgroundrpcssucceeded'};
#	print "ClientBackgroundRPCssucceeded: $clientbackgroundrpcssucceeded \n\n";


	#---find ClientBackgroundRPCssucceededPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientbackgroundrpcssucceededpersec'};	
#	print "ClientBackgroundRPCssucceededPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientbackgroundrpcssucceededpersec'};	
#	print "ClientBackgroundRPCssucceededPersec2: $val2 \n";	
	eval 	
	{	
	$clientbackgroundrpcssucceededpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientBackgroundRPCssucceededPersec: $clientbackgroundrpcssucceededpersec \n\n";	


	#---find ClientForegroundRPCsFailed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientforegroundrpcsfailed = $risc->{$calname}->{'2'}->{'clientforegroundrpcsfailed'};
#	print "ClientForegroundRPCsFailed: $clientforegroundrpcsfailed \n\n";


	#---find ClientForegroundRPCsFailedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientforegroundrpcsfailedpersec'};	
#	print "ClientForegroundRPCsFailedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientforegroundrpcsfailedpersec'};	
#	print "ClientForegroundRPCsFailedPersec2: $val2 \n";	
	eval 	
	{	
	$clientforegroundrpcsfailedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientForegroundRPCsFailedPersec: $clientforegroundrpcsfailedpersec \n\n";	


	#---find ClientForegroundRPCssucceeded---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientforegroundrpcssucceeded = $risc->{$calname}->{'2'}->{'clientforegroundrpcssucceeded'};
#	print "ClientForegroundRPCssucceeded: $clientforegroundrpcssucceeded \n\n";


	#---find ClientForegroundRPCssucceededPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientforegroundrpcssucceededpersec'};	
#	print "ClientForegroundRPCssucceededPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientforegroundrpcssucceededpersec'};	
#	print "ClientForegroundRPCssucceededPersec2: $val2 \n";	
	eval 	
	{	
	$clientforegroundrpcssucceededpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientForegroundRPCssucceededPersec: $clientforegroundrpcssucceededpersec \n\n";	


	#---find ClientLatency10secRPCs---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientlatency10secrpcs = $risc->{$calname}->{'2'}->{'clientlatency10secrpcs'};
#	print "ClientLatency10secRPCs: $clientlatency10secrpcs \n\n";


	#---find ClientLatency2secRPCs---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientlatency2secrpcs = $risc->{$calname}->{'2'}->{'clientlatency2secrpcs'};
#	print "ClientLatency2secRPCs: $clientlatency2secrpcs \n\n";


	#---find ClientLatency5secRPCs---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientlatency5secrpcs = $risc->{$calname}->{'2'}->{'clientlatency5secrpcs'};
#	print "ClientLatency5secRPCs: $clientlatency5secrpcs \n\n";


	#---find ClientRPCsattempted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsattempted = $risc->{$calname}->{'2'}->{'clientrpcsattempted'};
#	print "ClientRPCsattempted: $clientrpcsattempted \n\n";


	#---find ClientRPCsattemptedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsattemptedpersec'};	
#	print "ClientRPCsattemptedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsattemptedpersec'};	
#	print "ClientRPCsattemptedPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsattemptedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsattemptedPersec: $clientrpcsattemptedpersec \n\n";	


	#---find ClientRPCsFailed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailed = $risc->{$calname}->{'2'}->{'clientrpcsfailed'};
#	print "ClientRPCsFailed: $clientrpcsfailed \n\n";


	#---find ClientRPCsFailedAccessDenied---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedaccessdenied = $risc->{$calname}->{'2'}->{'clientrpcsfailedaccessdenied'};
#	print "ClientRPCsFailedAccessDenied: $clientrpcsfailedaccessdenied \n\n";


	#---find ClientRPCsFailedAccessDeniedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedaccessdeniedpersec'};	
#	print "ClientRPCsFailedAccessDeniedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedaccessdeniedpersec'};	
#	print "ClientRPCsFailedAccessDeniedPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedaccessdeniedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedAccessDeniedPersec: $clientrpcsfailedaccessdeniedpersec \n\n";	


	#---find ClientRPCsFailedAllothererrors---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedallothererrors = $risc->{$calname}->{'2'}->{'clientrpcsfailedallothererrors'};
#	print "ClientRPCsFailedAllothererrors: $clientrpcsfailedallothererrors \n\n";


	#---find ClientRPCsFailedAllothererrorsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedallothererrorspersec'};	
#	print "ClientRPCsFailedAllothererrorsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedallothererrorspersec'};	
#	print "ClientRPCsFailedAllothererrorsPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedallothererrorspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedAllothererrorsPersec: $clientrpcsfailedallothererrorspersec \n\n";	


	#---find ClientRPCsFailedCallCancelled---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedcallcancelled = $risc->{$calname}->{'2'}->{'clientrpcsfailedcallcancelled'};
#	print "ClientRPCsFailedCallCancelled: $clientrpcsfailedcallcancelled \n\n";


	#---find ClientRPCsFailedCallCancelledPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedcallcancelledpersec'};	
#	print "ClientRPCsFailedCallCancelledPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedcallcancelledpersec'};	
#	print "ClientRPCsFailedCallCancelledPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedcallcancelledpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedCallCancelledPersec: $clientrpcsfailedcallcancelledpersec \n\n";	


	#---find ClientRPCsFailedCallFailed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedcallfailed = $risc->{$calname}->{'2'}->{'clientrpcsfailedcallfailed'};
#	print "ClientRPCsFailedCallFailed: $clientrpcsfailedcallfailed \n\n";


	#---find ClientRPCsFailedCallFailedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedcallfailedpersec'};	
#	print "ClientRPCsFailedCallFailedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedcallfailedpersec'};	
#	print "ClientRPCsFailedCallFailedPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedcallfailedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedCallFailedPersec: $clientrpcsfailedcallfailedpersec \n\n";	


	#---find ClientRPCsFailedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedpersec'};	
#	print "ClientRPCsFailedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedpersec'};	
#	print "ClientRPCsFailedPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedPersec: $clientrpcsfailedpersec \n\n";	


	#---find ClientRPCsFailedServerTooBusy---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedservertoobusy = $risc->{$calname}->{'2'}->{'clientrpcsfailedservertoobusy'};
#	print "ClientRPCsFailedServerTooBusy: $clientrpcsfailedservertoobusy \n\n";


	#---find ClientRPCsFailedServerTooBusyPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedservertoobusypersec'};	
#	print "ClientRPCsFailedServerTooBusyPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedservertoobusypersec'};	
#	print "ClientRPCsFailedServerTooBusyPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedservertoobusypersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedServerTooBusyPersec: $clientrpcsfailedservertoobusypersec \n\n";	


	#---find ClientRPCsFailedServerUnavailable---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcsfailedserverunavailable = $risc->{$calname}->{'2'}->{'clientrpcsfailedserverunavailable'};
#	print "ClientRPCsFailedServerUnavailable: $clientrpcsfailedserverunavailable \n\n";


	#---find ClientRPCsFailedServerUnavailablePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcsfailedserverunavailablepersec'};	
#	print "ClientRPCsFailedServerUnavailablePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcsfailedserverunavailablepersec'};	
#	print "ClientRPCsFailedServerUnavailablePersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcsfailedserverunavailablepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCsFailedServerUnavailablePersec: $clientrpcsfailedserverunavailablepersec \n\n";	


	#---find ClientRPCssucceeded---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientrpcssucceeded = $risc->{$calname}->{'2'}->{'clientrpcssucceeded'};
#	print "ClientRPCssucceeded: $clientrpcssucceeded \n\n";


	#---find ClientRPCssucceededPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'clientrpcssucceededpersec'};	
#	print "ClientRPCssucceededPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'clientrpcssucceededpersec'};	
#	print "ClientRPCssucceededPersec2: $val2 \n";	
	eval 	
	{	
	$clientrpcssucceededpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ClientRPCssucceededPersec: $clientrpcssucceededpersec \n\n";	


	#---find ClientTotalreportedlatency---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clienttotalreportedlatency = $risc->{$calname}->{'2'}->{'clienttotalreportedlatency'};
#	print "ClientTotalreportedlatency: $clienttotalreportedlatency \n\n";


	#---find ConnectionCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$connectioncount = $risc->{$calname}->{'2'}->{'connectioncount'};
#	print "ConnectionCount: $connectioncount \n\n";


	#---find DLmembershipcacheentriescount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$dlmembershipcacheentriescount = $risc->{$calname}->{'2'}->{'dlmembershipcacheentriescount'};
#	print "DLmembershipcacheentriescount: $dlmembershipcacheentriescount \n\n";


	#---find DLmembershipcachehits---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$dlmembershipcachehits = $risc->{$calname}->{'2'}->{'dlmembershipcachehits'};
#	print "DLmembershipcachehits: $dlmembershipcachehits \n\n";


	#---find DLmembershipcachemisses---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$dlmembershipcachemisses = $risc->{$calname}->{'2'}->{'dlmembershipcachemisses'};
#	print "DLmembershipcachemisses: $dlmembershipcachemisses \n\n";


	#---find DLmembershipcachesize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$dlmembershipcachesize = $risc->{$calname}->{'2'}->{'dlmembershipcachesize'};
#	print "DLmembershipcachesize: $dlmembershipcachesize \n\n";


	#---find ExchmemCurrentBytesAllocated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemcurrentbytesallocated = $risc->{$calname}->{'2'}->{'exchmemcurrentbytesallocated'};
#	print "ExchmemCurrentBytesAllocated: $exchmemcurrentbytesallocated \n\n";


	#---find ExchmemCurrentNumberofVirtualAllocations---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemcurrentnumberofvirtualallocations = $risc->{$calname}->{'2'}->{'exchmemcurrentnumberofvirtualallocations'};
#	print "ExchmemCurrentNumberofVirtualAllocations: $exchmemcurrentnumberofvirtualallocations \n\n";


	#---find ExchmemCurrentVirtualBytesAllocated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemcurrentvirtualbytesallocated = $risc->{$calname}->{'2'}->{'exchmemcurrentvirtualbytesallocated'};
#	print "ExchmemCurrentVirtualBytesAllocated: $exchmemcurrentvirtualbytesallocated \n\n";


	#---find ExchmemMaximumBytesAllocated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemmaximumbytesallocated = $risc->{$calname}->{'2'}->{'exchmemmaximumbytesallocated'};
#	print "ExchmemMaximumBytesAllocated: $exchmemmaximumbytesallocated \n\n";


	#---find ExchmemMaximumVirtualBytesAllocated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemmaximumvirtualbytesallocated = $risc->{$calname}->{'2'}->{'exchmemmaximumvirtualbytesallocated'};
#	print "ExchmemMaximumVirtualBytesAllocated: $exchmemmaximumvirtualbytesallocated \n\n";


	#---find ExchmemNumberofAdditionalHeaps---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemnumberofadditionalheaps = $risc->{$calname}->{'2'}->{'exchmemnumberofadditionalheaps'};
#	print "ExchmemNumberofAdditionalHeaps: $exchmemnumberofadditionalheaps \n\n";


	#---find ExchmemNumberofHeaps---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemnumberofheaps = $risc->{$calname}->{'2'}->{'exchmemnumberofheaps'};
#	print "ExchmemNumberofHeaps: $exchmemnumberofheaps \n\n";


	#---find ExchmemNumberofheapswithmemoryerrors---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemnumberofheapswithmemoryerrors = $risc->{$calname}->{'2'}->{'exchmemnumberofheapswithmemoryerrors'};
#	print "ExchmemNumberofheapswithmemoryerrors: $exchmemnumberofheapswithmemoryerrors \n\n";


	#---find ExchmemNumberofmemoryerrors---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemnumberofmemoryerrors = $risc->{$calname}->{'2'}->{'exchmemnumberofmemoryerrors'};
#	print "ExchmemNumberofmemoryerrors: $exchmemnumberofmemoryerrors \n\n";


	#---find ExchmemTotalNumberofVirtualAllocations---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchmemtotalnumberofvirtualallocations = $risc->{$calname}->{'2'}->{'exchmemtotalnumberofvirtualallocations'};
#	print "ExchmemTotalNumberofVirtualAllocations: $exchmemtotalnumberofvirtualallocations \n\n";


	#---find FBPublishCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$fbpublishcount = $risc->{$calname}->{'2'}->{'fbpublishcount'};
#	print "FBPublishCount: $fbpublishcount \n\n";


	#---find FBPublishRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'fbpublishrate'};	
#	print "FBPublishRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'fbpublishrate'};	
#	print "FBPublishRate2: $val2 \n";	
	eval 	
	{	
	$fbpublishrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "FBPublishRate: $fbpublishrate \n\n";	


	#---find MaximumAnonymousUsers---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$maximumanonymoususers = $risc->{$calname}->{'2'}->{'maximumanonymoususers'};
#	print "MaximumAnonymousUsers: $maximumanonymoususers \n\n";


	#---find MaximumConnections---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$maximumconnections = $risc->{$calname}->{'2'}->{'maximumconnections'};
#	print "MaximumConnections: $maximumconnections \n\n";


	#---find MaximumUsers---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$maximumusers = $risc->{$calname}->{'2'}->{'maximumusers'};
#	print "MaximumUsers: $maximumusers \n\n";


	#---find MessageCreatePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagecreatepersec'};	
#	print "MessageCreatePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagecreatepersec'};	
#	print "MessageCreatePersec2: $val2 \n";	
	eval 	
	{	
	$messagecreatepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageCreatePersec: $messagecreatepersec \n\n";	


	#---find MessageDeletePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagedeletepersec'};	
#	print "MessageDeletePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagedeletepersec'};	
#	print "MessageDeletePersec2: $val2 \n";	
	eval 	
	{	
	$messagedeletepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageDeletePersec: $messagedeletepersec \n\n";	


	#---find MessageModifyPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagemodifypersec'};	
#	print "MessageModifyPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagemodifypersec'};	
#	print "MessageModifyPersec2: $val2 \n";	
	eval 	
	{	
	$messagemodifypersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageModifyPersec: $messagemodifypersec \n\n";	


	#---find MessageMovePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagemovepersec'};	
#	print "MessageMovePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagemovepersec'};	
#	print "MessageMovePersec2: $val2 \n";	
	eval 	
	{	
	$messagemovepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageMovePersec: $messagemovepersec \n\n";	


	#---find MessagesPrereadAscendingPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagesprereadascendingpersec'};	
#	print "MessagesPrereadAscendingPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagesprereadascendingpersec'};	
#	print "MessagesPrereadAscendingPersec2: $val2 \n";	
	eval 	
	{	
	$messagesprereadascendingpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesPrereadAscendingPersec: $messagesprereadascendingpersec \n\n";	


	#---find MessagesPrereadDescendingPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagesprereaddescendingpersec'};	
#	print "MessagesPrereadDescendingPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagesprereaddescendingpersec'};	
#	print "MessagesPrereadDescendingPersec2: $val2 \n";	
	eval 	
	{	
	$messagesprereaddescendingpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesPrereadDescendingPersec: $messagesprereaddescendingpersec \n\n";	


	#---find MessagesPrereadSkippedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagesprereadskippedpersec'};	
#	print "MessagesPrereadSkippedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagesprereadskippedpersec'};	
#	print "MessagesPrereadSkippedPersec2: $val2 \n";	
	eval 	
	{	
	$messagesprereadskippedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesPrereadSkippedPersec: $messagesprereadskippedpersec \n\n";	


	#---find MinimsgcreatedforviewsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'minimsgcreatedforviewspersec'};	
#	print "MinimsgcreatedforviewsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'minimsgcreatedforviewspersec'};	
#	print "MinimsgcreatedforviewsPersec2: $val2 \n";	
	eval 	
	{	
	$minimsgcreatedforviewspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MinimsgcreatedforviewsPersec: $minimsgcreatedforviewspersec \n\n";	


	#---find MinimsgMsgtableseeksPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'minimsgmsgtableseekspersec'};	
#	print "MinimsgMsgtableseeksPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'minimsgmsgtableseekspersec'};	
#	print "MinimsgMsgtableseeksPersec2: $val2 \n";	
	eval 	
	{	
	$minimsgmsgtableseekspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MinimsgMsgtableseeksPersec: $minimsgmsgtableseekspersec \n\n";	


	#---find MsgViewRecordsDeletedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsdeletedpersec'};	
#	print "MsgViewRecordsDeletedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsdeletedpersec'};	
#	print "MsgViewRecordsDeletedPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsdeletedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsDeletedPersec: $msgviewrecordsdeletedpersec \n\n";	


	#---find MsgViewRecordsDeletesDeferredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsdeletesdeferredpersec'};	
#	print "MsgViewRecordsDeletesDeferredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsdeletesdeferredpersec'};	
#	print "MsgViewRecordsDeletesDeferredPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsdeletesdeferredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsDeletesDeferredPersec: $msgviewrecordsdeletesdeferredpersec \n\n";	


	#---find MsgViewRecordsInsertedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsinsertedpersec'};	
#	print "MsgViewRecordsInsertedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsinsertedpersec'};	
#	print "MsgViewRecordsInsertedPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsinsertedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsInsertedPersec: $msgviewrecordsinsertedpersec \n\n";	


	#---find MsgViewRecordsInsertsDeferredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsinsertsdeferredpersec'};	
#	print "MsgViewRecordsInsertsDeferredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsinsertsdeferredpersec'};	
#	print "MsgViewRecordsInsertsDeferredPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsinsertsdeferredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsInsertsDeferredPersec: $msgviewrecordsinsertsdeferredpersec \n\n";	


	#---find MsgViewtableCreatePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablecreatepersec'};	
#	print "MsgViewtableCreatePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablecreatepersec'};	
#	print "MsgViewtableCreatePersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablecreatepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableCreatePersec: $msgviewtablecreatepersec \n\n";	


	#---find MsgViewtableDeletePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtabledeletepersec'};	
#	print "MsgViewtableDeletePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtabledeletepersec'};	
#	print "MsgViewtableDeletePersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtabledeletepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableDeletePersec: $msgviewtabledeletepersec \n\n";	


	#---find MsgViewtableNullRefreshPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablenullrefreshpersec'};	
#	print "MsgViewtableNullRefreshPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablenullrefreshpersec'};	
#	print "MsgViewtableNullRefreshPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablenullrefreshpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableNullRefreshPersec: $msgviewtablenullrefreshpersec \n\n";	


	#---find MsgViewtablerefreshDVUrecordsscanned---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshdvurecordsscanned'};	
#	print "MsgViewtablerefreshDVUrecordsscanned1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshdvurecordsscanned'};	
#	print "MsgViewtablerefreshDVUrecordsscanned2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshdvurecordsscanned_base'};	
#	print "MsgViewtablerefreshDVUrecordsscanned_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshdvurecordsscanned_base'};	
#	print "MsgViewtablerefreshDVUrecordsscanned_base2: $val_base2\n";	
	eval 	
	{	
	$msgviewtablerefreshdvurecordsscanned = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MsgViewtablerefreshDVUrecordsscanned: $msgviewtablerefreshdvurecordsscanned \n";	


	#---find MsgViewtableRefreshPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshpersec'};	
#	print "MsgViewtableRefreshPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshpersec'};	
#	print "MsgViewtableRefreshPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablerefreshpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableRefreshPersec: $msgviewtablerefreshpersec \n\n";	


	#---find MsgViewtablerefreshupdatesapplied---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshupdatesapplied'};	
#	print "MsgViewtablerefreshupdatesapplied1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshupdatesapplied'};	
#	print "MsgViewtablerefreshupdatesapplied2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshupdatesapplied_base'};	
#	print "MsgViewtablerefreshupdatesapplied_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshupdatesapplied_base'};	
#	print "MsgViewtablerefreshupdatesapplied_base2: $val_base2\n";	
	eval 	
	{	
	$msgviewtablerefreshupdatesapplied = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MsgViewtablerefreshupdatesapplied: $msgviewtablerefreshupdatesapplied \n";	


	#---find OABDifferentialDownloadAttempts---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$oabdifferentialdownloadattempts = $risc->{$calname}->{'2'}->{'oabdifferentialdownloadattempts'};
#	print "OABDifferentialDownloadAttempts: $oabdifferentialdownloadattempts \n\n";


	#---find OABDifferentialDownloadBytes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$oabdifferentialdownloadbytes = $risc->{$calname}->{'2'}->{'oabdifferentialdownloadbytes'};
#	print "OABDifferentialDownloadBytes: $oabdifferentialdownloadbytes \n\n";


	#---find OABDifferentialDownloadBytesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'oabdifferentialdownloadbytespersec'};	
#	print "OABDifferentialDownloadBytesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'oabdifferentialdownloadbytespersec'};	
#	print "OABDifferentialDownloadBytesPersec2: $val2 \n";	
	eval 	
	{	
	$oabdifferentialdownloadbytespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "OABDifferentialDownloadBytesPersec: $oabdifferentialdownloadbytespersec \n\n";	


	#---find OABFullDownloadAttempts---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$oabfulldownloadattempts = $risc->{$calname}->{'2'}->{'oabfulldownloadattempts'};
#	print "OABFullDownloadAttempts: $oabfulldownloadattempts \n\n";


	#---find OABFullDownloadAttemptsBlocked---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$oabfulldownloadattemptsblocked = $risc->{$calname}->{'2'}->{'oabfulldownloadattemptsblocked'};
#	print "OABFullDownloadAttemptsBlocked: $oabfulldownloadattemptsblocked \n\n";


	#---find OABFullDownloadBytes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$oabfulldownloadbytes = $risc->{$calname}->{'2'}->{'oabfulldownloadbytes'};
#	print "OABFullDownloadBytes: $oabfulldownloadbytes \n\n";


	#---find OABFullDownloadBytesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'oabfulldownloadbytespersec'};	
#	print "OABFullDownloadBytesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'oabfulldownloadbytespersec'};	
#	print "OABFullDownloadBytesPersec2: $val2 \n";	
	eval 	
	{	
	$oabfulldownloadbytespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "OABFullDownloadBytesPersec: $oabfulldownloadbytespersec \n\n";	


	#---find PeakAsyncNotificationsCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$peakasyncnotificationscachesize = $risc->{$calname}->{'2'}->{'peakasyncnotificationscachesize'};
#	print "PeakAsyncNotificationsCacheSize: $peakasyncnotificationscachesize \n\n";


	#---find PeakPushNotificationsCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$peakpushnotificationscachesize = $risc->{$calname}->{'2'}->{'peakpushnotificationscachesize'};
#	print "PeakPushNotificationsCacheSize: $peakpushnotificationscachesize \n\n";


	#---find PercentConnections---#	
	$val1 = $risc->{$calname}->{'1'}->{'percentconnections'};	
#	print "PercentConnections1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'percentconnections'};	
#	print "PercentConnections2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'percentconnections_base'};	
#	print "PercentConnections_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'percentconnections_base'};	
#	print "PercentConnections_base2: $val_base2\n";	
	eval 	
	{	
	$percentconnections = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "PercentConnections: $percentconnections \n";	


	#---find PercentRPCThreads---#	
	$val1 = $risc->{$calname}->{'1'}->{'percentrpcthreads'};	
#	print "PercentRPCThreads1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'percentrpcthreads'};	
#	print "PercentRPCThreads2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'percentrpcthreads_base'};	
#	print "PercentRPCThreads_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'percentrpcthreads_base'};	
#	print "PercentRPCThreads_base2: $val_base2\n";	
	eval 	
	{	
	$percentrpcthreads = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "PercentRPCThreads: $percentrpcthreads \n";	


	#---find PushNotificationsCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$pushnotificationscachesize = $risc->{$calname}->{'2'}->{'pushnotificationscachesize'};
#	print "PushNotificationsCacheSize: $pushnotificationscachesize \n\n";


	#---find PushNotificationsGeneratedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'pushnotificationsgeneratedpersec'};	
#	print "PushNotificationsGeneratedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'pushnotificationsgeneratedpersec'};	
#	print "PushNotificationsGeneratedPersec2: $val2 \n";	
	eval 	
	{	
	$pushnotificationsgeneratedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "PushNotificationsGeneratedPersec: $pushnotificationsgeneratedpersec \n\n";	


	#---find PushNotificationsSkippedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'pushnotificationsskippedpersec'};	
#	print "PushNotificationsSkippedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'pushnotificationsskippedpersec'};	
#	print "PushNotificationsSkippedPersec2: $val2 \n";	
	eval 	
	{	
	$pushnotificationsskippedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "PushNotificationsSkippedPersec: $pushnotificationsskippedpersec \n\n";	


	#---find ReadBytesRPCClientsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'readbytesrpcclientspersec'};	
#	print "ReadBytesRPCClientsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'readbytesrpcclientspersec'};	
#	print "ReadBytesRPCClientsPersec2: $val2 \n";	
	eval 	
	{	
	$readbytesrpcclientspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ReadBytesRPCClientsPersec: $readbytesrpcclientspersec \n\n";	


	#---find RecurringAppointmentDeletionRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'recurringappointmentdeletionrate'};	
#	print "RecurringAppointmentDeletionRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'recurringappointmentdeletionrate'};	
#	print "RecurringAppointmentDeletionRate2: $val2 \n";	
	eval 	
	{	
	$recurringappointmentdeletionrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RecurringAppointmentDeletionRate: $recurringappointmentdeletionrate \n\n";	


	#---find RecurringAppointmentModificationRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'recurringappointmentmodificationrate'};	
#	print "RecurringAppointmentModificationRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'recurringappointmentmodificationrate'};	
#	print "RecurringAppointmentModificationRate2: $val2 \n";	
	eval 	
	{	
	$recurringappointmentmodificationrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RecurringAppointmentModificationRate: $recurringappointmentmodificationrate \n\n";	


	#---find RecurringAppointmentsCreated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$recurringappointmentscreated = $risc->{$calname}->{'2'}->{'recurringappointmentscreated'};
#	print "RecurringAppointmentsCreated: $recurringappointmentscreated \n\n";


	#---find RecurringAppointmentsDeleted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$recurringappointmentsdeleted = $risc->{$calname}->{'2'}->{'recurringappointmentsdeleted'};
#	print "RecurringAppointmentsDeleted: $recurringappointmentsdeleted \n\n";


	#---find RecurringAppointmentsModified---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$recurringappointmentsmodified = $risc->{$calname}->{'2'}->{'recurringappointmentsmodified'};
#	print "RecurringAppointmentsModified: $recurringappointmentsmodified \n\n";


	#---find RecurringApppointmentCreationRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'recurringapppointmentcreationrate'};	
#	print "RecurringApppointmentCreationRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'recurringapppointmentcreationrate'};	
#	print "RecurringApppointmentCreationRate2: $val2 \n";	
	eval 	
	{	
	$recurringapppointmentcreationrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RecurringApppointmentCreationRate: $recurringapppointmentcreationrate \n\n";	


	#---find RecurringMasterAppointmentsExpanded---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$recurringmasterappointmentsexpanded = $risc->{$calname}->{'2'}->{'recurringmasterappointmentsexpanded'};
#	print "RecurringMasterAppointmentsExpanded: $recurringmasterappointmentsexpanded \n\n";


	#---find RecurringMasterExpansionRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'recurringmasterexpansionrate'};	
#	print "RecurringMasterExpansionRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'recurringmasterexpansionrate'};	
#	print "RecurringMasterExpansionRate2: $val2 \n";	
	eval 	
	{	
	$recurringmasterexpansionrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RecurringMasterExpansionRate: $recurringmasterexpansionrate \n\n";	


	#---find RPCAveragedLatency---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcaveragedlatency = $risc->{$calname}->{'2'}->{'rpcaveragedlatency'};
#	print "RPCAveragedLatency: $rpcaveragedlatency \n\n";


	#---find RPCClientBackoffPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcclientbackoffpersec'};	
#	print "RPCClientBackoffPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcclientbackoffpersec'};	
#	print "RPCClientBackoffPersec2: $val2 \n";	
	eval 	
	{	
	$rpcclientbackoffpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCClientBackoffPersec: $rpcclientbackoffpersec \n\n";	


	#---find RPCClientsBytesRead---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcclientsbytesread = $risc->{$calname}->{'2'}->{'rpcclientsbytesread'};
#	print "RPCClientsBytesRead: $rpcclientsbytesread \n\n";


	#---find RPCClientsBytesWritten---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcclientsbyteswritten = $risc->{$calname}->{'2'}->{'rpcclientsbyteswritten'};
#	print "RPCClientsBytesWritten: $rpcclientsbyteswritten \n\n";


	#---find RPCClientsUncompressedBytesRead---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcclientsuncompressedbytesread = $risc->{$calname}->{'2'}->{'rpcclientsuncompressedbytesread'};
#	print "RPCClientsUncompressedBytesRead: $rpcclientsuncompressedbytesread \n\n";


	#---find RPCClientsUncompressedBytesWritten---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcclientsuncompressedbyteswritten = $risc->{$calname}->{'2'}->{'rpcclientsuncompressedbyteswritten'};
#	print "RPCClientsUncompressedBytesWritten: $rpcclientsuncompressedbyteswritten \n\n";


	#---find RPCNumofSlowPackets---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcnumofslowpackets = $risc->{$calname}->{'2'}->{'rpcnumofslowpackets'};
#	print "RPCNumofSlowPackets: $rpcnumofslowpackets \n\n";


	#---find RPCOperationsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcoperationspersec'};	
#	print "RPCOperationsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcoperationspersec'};	
#	print "RPCOperationsPersec2: $val2 \n";	
	eval 	
	{	
	$rpcoperationspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCOperationsPersec: $rpcoperationspersec \n\n";	


	#---find RPCPacketsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcpacketspersec'};	
#	print "RPCPacketsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcpacketspersec'};	
#	print "RPCPacketsPersec2: $val2 \n";	
	eval 	
	{	
	$rpcpacketspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCPacketsPersec: $rpcpacketspersec \n\n";	


	#---find RPCPoolAsyncNotificationsGeneratedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcpoolasyncnotificationsgeneratedpersec'};	
#	print "RPCPoolAsyncNotificationsGeneratedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcpoolasyncnotificationsgeneratedpersec'};	
#	print "RPCPoolAsyncNotificationsGeneratedPersec2: $val2 \n";	
	eval 	
	{	
	$rpcpoolasyncnotificationsgeneratedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCPoolAsyncNotificationsGeneratedPersec: $rpcpoolasyncnotificationsgeneratedpersec \n\n";	


	#---find RPCPoolContextHandles---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolcontexthandles = $risc->{$calname}->{'2'}->{'rpcpoolcontexthandles'};
#	print "RPCPoolContextHandles: $rpcpoolcontexthandles \n\n";


	#---find RPCPoolParkedAsyncNotificationCalls---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolparkedasyncnotificationcalls = $risc->{$calname}->{'2'}->{'rpcpoolparkedasyncnotificationcalls'};
#	print "RPCPoolParkedAsyncNotificationCalls: $rpcpoolparkedasyncnotificationcalls \n\n";


	#---find RPCPoolPools---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolpools = $risc->{$calname}->{'2'}->{'rpcpoolpools'};
#	print "RPCPoolPools: $rpcpoolpools \n\n";


	#---find RPCPoolSessionNotificationsPending---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolsessionnotificationspending = $risc->{$calname}->{'2'}->{'rpcpoolsessionnotificationspending'};
#	print "RPCPoolSessionNotificationsPending: $rpcpoolsessionnotificationspending \n\n";


	#---find RPCPoolSessions---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolsessions = $risc->{$calname}->{'2'}->{'rpcpoolsessions'};
#	print "RPCPoolSessions: $rpcpoolsessions \n\n";


	#---find RPCRequests---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequests = $risc->{$calname}->{'2'}->{'rpcrequests'};
#	print "RPCRequests: $rpcrequests \n\n";


	#---find RPCRequestsPeak---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestspeak = $risc->{$calname}->{'2'}->{'rpcrequestspeak'};
#	print "RPCRequestsPeak: $rpcrequestspeak \n\n";


	#---find RPCRequestTimeoutDetected---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequesttimeoutdetected = $risc->{$calname}->{'2'}->{'rpcrequesttimeoutdetected'};
#	print "RPCRequestTimeoutDetected: $rpcrequesttimeoutdetected \n\n";


	#---find SingleAppointmentCreationRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'singleappointmentcreationrate'};	
#	print "SingleAppointmentCreationRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'singleappointmentcreationrate'};	
#	print "SingleAppointmentCreationRate2: $val2 \n";	
	eval 	
	{	
	$singleappointmentcreationrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SingleAppointmentCreationRate: $singleappointmentcreationrate \n\n";	


	#---find SingleAppointmentDeletionRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'singleappointmentdeletionrate'};	
#	print "SingleAppointmentDeletionRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'singleappointmentdeletionrate'};	
#	print "SingleAppointmentDeletionRate2: $val2 \n";	
	eval 	
	{	
	$singleappointmentdeletionrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SingleAppointmentDeletionRate: $singleappointmentdeletionrate \n\n";	


	#---find SingleAppointmentModificationRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'singleappointmentmodificationrate'};	
#	print "SingleAppointmentModificationRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'singleappointmentmodificationrate'};	
#	print "SingleAppointmentModificationRate2: $val2 \n";	
	eval 	
	{	
	$singleappointmentmodificationrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SingleAppointmentModificationRate: $singleappointmentmodificationrate \n\n";	


	#---find SingleAppointmentsCreated---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$singleappointmentscreated = $risc->{$calname}->{'2'}->{'singleappointmentscreated'};
#	print "SingleAppointmentsCreated: $singleappointmentscreated \n\n";


	#---find SingleAppointmentsDeleted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$singleappointmentsdeleted = $risc->{$calname}->{'2'}->{'singleappointmentsdeleted'};
#	print "SingleAppointmentsDeleted: $singleappointmentsdeleted \n\n";


	#---find SingleAppointmentsModified---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$singleappointmentsmodified = $risc->{$calname}->{'2'}->{'singleappointmentsmodified'};
#	print "SingleAppointmentsModified: $singleappointmentsmodified \n\n";


	#---find SlowQPThreads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$slowqpthreads = $risc->{$calname}->{'2'}->{'slowqpthreads'};
#	print "SlowQPThreads: $slowqpthreads \n\n";


	#---find SlowSearchThreads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$slowsearchthreads = $risc->{$calname}->{'2'}->{'slowsearchthreads'};
#	print "SlowSearchThreads: $slowsearchthreads \n\n";


	#---find TotalParkedAsyncNotificationCalls---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalparkedasyncnotificationcalls = $risc->{$calname}->{'2'}->{'totalparkedasyncnotificationcalls'};
#	print "TotalParkedAsyncNotificationCalls: $totalparkedasyncnotificationcalls \n\n";


	#---find UserCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$usercount = $risc->{$calname}->{'2'}->{'usercount'};
#	print "UserCount: $usercount \n\n";


	#---find ViewCleanupCategorizationIndexDeletionsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanupcategorizationindexdeletionspersec'};	
#	print "ViewCleanupCategorizationIndexDeletionsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanupcategorizationindexdeletionspersec'};	
#	print "ViewCleanupCategorizationIndexDeletionsPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanupcategorizationindexdeletionspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupCategorizationIndexDeletionsPersec: $viewcleanupcategorizationindexdeletionspersec \n\n";	


	#---find ViewCleanupDVUEntryDeletionsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanupdvuentrydeletionspersec'};	
#	print "ViewCleanupDVUEntryDeletionsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanupdvuentrydeletionspersec'};	
#	print "ViewCleanupDVUEntryDeletionsPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanupdvuentrydeletionspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupDVUEntryDeletionsPersec: $viewcleanupdvuentrydeletionspersec \n\n";	


	#---find ViewCleanupRestrictionIndexDeletionsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanuprestrictionindexdeletionspersec'};	
#	print "ViewCleanupRestrictionIndexDeletionsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanuprestrictionindexdeletionspersec'};	
#	print "ViewCleanupRestrictionIndexDeletionsPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanuprestrictionindexdeletionspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupRestrictionIndexDeletionsPersec: $viewcleanuprestrictionindexdeletionspersec \n\n";	


	#---find ViewCleanupSearchIndexDeletionsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanupsearchindexdeletionspersec'};	
#	print "ViewCleanupSearchIndexDeletionsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanupsearchindexdeletionspersec'};	
#	print "ViewCleanupSearchIndexDeletionsPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanupsearchindexdeletionspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupSearchIndexDeletionsPersec: $viewcleanupsearchindexdeletionspersec \n\n";	


	#---find ViewCleanupSortIndexDeletionsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanupsortindexdeletionspersec'};	
#	print "ViewCleanupSortIndexDeletionsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanupsortindexdeletionspersec'};	
#	print "ViewCleanupSortIndexDeletionsPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanupsortindexdeletionspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupSortIndexDeletionsPersec: $viewcleanupsortindexdeletionspersec \n\n";	


	#---find ViewCleanupTasksNullifiedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanuptasksnullifiedpersec'};	
#	print "ViewCleanupTasksNullifiedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanuptasksnullifiedpersec'};	
#	print "ViewCleanupTasksNullifiedPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanuptasksnullifiedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupTasksNullifiedPersec: $viewcleanuptasksnullifiedpersec \n\n";	


	#---find ViewCleanupTasksPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'viewcleanuptaskspersec'};	
#	print "ViewCleanupTasksPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'viewcleanuptaskspersec'};	
#	print "ViewCleanupTasksPersec2: $val2 \n";	
	eval 	
	{	
	$viewcleanuptaskspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "ViewCleanupTasksPersec: $viewcleanuptaskspersec \n\n";	


	#---find VirusScanFilesCleaned---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanfilescleaned = $risc->{$calname}->{'2'}->{'virusscanfilescleaned'};
#	print "VirusScanFilesCleaned: $virusscanfilescleaned \n\n";


	#---find VirusScanFilesCleanedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanfilescleanedpersec'};	
#	print "VirusScanFilesCleanedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanfilescleanedpersec'};	
#	print "VirusScanFilesCleanedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanfilescleanedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanFilesCleanedPersec: $virusscanfilescleanedpersec \n\n";	


	#---find VirusScanFilesQuarantined---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanfilesquarantined = $risc->{$calname}->{'2'}->{'virusscanfilesquarantined'};
#	print "VirusScanFilesQuarantined: $virusscanfilesquarantined \n\n";


	#---find VirusScanFilesQuarantinedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanfilesquarantinedpersec'};	
#	print "VirusScanFilesQuarantinedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanfilesquarantinedpersec'};	
#	print "VirusScanFilesQuarantinedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanfilesquarantinedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanFilesQuarantinedPersec: $virusscanfilesquarantinedpersec \n\n";	


	#---find VirusScanFilesScanned---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanfilesscanned = $risc->{$calname}->{'2'}->{'virusscanfilesscanned'};
#	print "VirusScanFilesScanned: $virusscanfilesscanned \n\n";


	#---find VirusScanFilesScannedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanfilesscannedpersec'};	
#	print "VirusScanFilesScannedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanfilesscannedpersec'};	
#	print "VirusScanFilesScannedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanfilesscannedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanFilesScannedPersec: $virusscanfilesscannedpersec \n\n";	


	#---find VirusScanFoldersScannedinBackground---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanfoldersscannedinbackground = $risc->{$calname}->{'2'}->{'virusscanfoldersscannedinbackground'};
#	print "VirusScanFoldersScannedinBackground: $virusscanfoldersscannedinbackground \n\n";


	#---find VirusScanMessagesCleaned---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanmessagescleaned = $risc->{$calname}->{'2'}->{'virusscanmessagescleaned'};
#	print "VirusScanMessagesCleaned: $virusscanmessagescleaned \n\n";

	#---find VirusScanMessagesCleanedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanmessagescleanedpersec'};	
#	print "VirusScanMessagesCleanedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanmessagescleanedpersec'};	
#	print "VirusScanMessagesCleanedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanmessagescleanedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanMessagesCleanedPersec: $virusscanmessagescleanedpersec \n\n";	


	#---find VirusScanMessagesDeleted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanmessagesdeleted = $risc->{$calname}->{'2'}->{'virusscanmessagesdeleted'};
#	print "VirusScanMessagesDeleted: $virusscanmessagesdeleted \n\n";


	#---find VirusScanMessagesDeletedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanmessagesdeletedpersec'};	
#	print "VirusScanMessagesDeletedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanmessagesdeletedpersec'};	
#	print "VirusScanMessagesDeletedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanmessagesdeletedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanMessagesDeletedPersec: $virusscanmessagesdeletedpersec \n\n";	


	#---find VirusScanMessagesProcessed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanmessagesprocessed = $risc->{$calname}->{'2'}->{'virusscanmessagesprocessed'};
#	print "VirusScanMessagesProcessed: $virusscanmessagesprocessed \n\n";


	#---find VirusScanMessagesProcessedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanmessagesprocessedpersec'};	
#	print "VirusScanMessagesProcessedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanmessagesprocessedpersec'};	
#	print "VirusScanMessagesProcessedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanmessagesprocessedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanMessagesProcessedPersec: $virusscanmessagesprocessedpersec \n\n";	


	#---find VirusScanMessagesQuarantined---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanmessagesquarantined = $risc->{$calname}->{'2'}->{'virusscanmessagesquarantined'};
#	print "VirusScanMessagesQuarantined: $virusscanmessagesquarantined \n\n";


	#---find VirusScanMessagesQuarantinedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'virusscanmessagesquarantinedpersec'};	
#	print "VirusScanMessagesQuarantinedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'virusscanmessagesquarantinedpersec'};	
#	print "VirusScanMessagesQuarantinedPersec2: $val2 \n";	
	eval 	
	{	
	$virusscanmessagesquarantinedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "VirusScanMessagesQuarantinedPersec: $virusscanmessagesquarantinedpersec \n\n";	


	#---find VirusScanMessagesScannedinBackground---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanmessagesscannedinbackground = $risc->{$calname}->{'2'}->{'virusscanmessagesscannedinbackground'};
#	print "VirusScanMessagesScannedinBackground: $virusscanmessagesscannedinbackground \n\n";


	#---find VirusScanQueueLength---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanqueuelength = $risc->{$calname}->{'2'}->{'virusscanqueuelength'};
#	print "VirusScanQueueLength: $virusscanqueuelength \n\n";


	#---find VMLargestBlockSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$vmlargestblocksize = $risc->{$calname}->{'2'}->{'vmlargestblocksize'};
#	print "VMLargestBlockSize: $vmlargestblocksize \n\n";


	#---find VMTotal16MBFreeBlocks---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$vmtotal16mbfreeblocks = $risc->{$calname}->{'2'}->{'vmtotal16mbfreeblocks'};
#	print "VMTotal16MBFreeBlocks: $vmtotal16mbfreeblocks \n\n";


	#---find VMTotalFreeBlocks---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$vmtotalfreeblocks = $risc->{$calname}->{'2'}->{'vmtotalfreeblocks'};
#	print "VMTotalFreeBlocks: $vmtotalfreeblocks \n\n";


	#---find VMTotalLargeFreeBlockBytes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$vmtotallargefreeblockbytes = $risc->{$calname}->{'2'}->{'vmtotallargefreeblockbytes'};
#	print "VMTotalLargeFreeBlockBytes: $vmtotallargefreeblockbytes \n\n";


	#---find WriteBytesRPCClientsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'writebytesrpcclientspersec'};	
#	print "WriteBytesRPCClientsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'writebytesrpcclientspersec'};	
#	print "WriteBytesRPCClientsPersec2: $val2 \n";	
	eval 	
	{	
	$writebytesrpcclientspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "WriteBytesRPCClientsPersec: $writebytesrpcclientspersec \n\n";	


#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$activeanonymoususercount
	,$activeconnectioncount
	,$activeusercount
	,$adminrpcrequests
	,$adminrpcrequestspeak
	,$anonymoususercount
	,$appointmentinstancecreationrate
	,$appointmentinstancedeletionrate
	,$appointmentinstancescreated
	,$appointmentinstancesdeleted
	,$asyncnotificationscachesize
	,$asyncnotificationsgeneratedpersec
	,$asyncrpcrequests
	,$asyncrpcrequestspeak
	,$backgroundexpansionqueuelength
	,$caption
	,$ciqpthreads
	,$clientbackgroundrpcsfailed
	,$clientbackgroundrpcsfailedpersec
	,$clientbackgroundrpcssucceeded
	,$clientbackgroundrpcssucceededpersec
	,$clientforegroundrpcsfailed
	,$clientforegroundrpcsfailedpersec
	,$clientforegroundrpcssucceeded
	,$clientforegroundrpcssucceededpersec
	,$clientlatency10secrpcs
	,$clientlatency2secrpcs
	,$clientlatency5secrpcs
	,$clientrpcsattempted
	,$clientrpcsattemptedpersec
	,$clientrpcsfailed
	,$clientrpcsfailedaccessdenied
	,$clientrpcsfailedaccessdeniedpersec
	,$clientrpcsfailedallothererrors
	,$clientrpcsfailedallothererrorspersec
	,$clientrpcsfailedcallcancelled
	,$clientrpcsfailedcallcancelledpersec
	,$clientrpcsfailedcallfailed
	,$clientrpcsfailedcallfailedpersec
	,$clientrpcsfailedpersec
	,$clientrpcsfailedservertoobusy
	,$clientrpcsfailedservertoobusypersec
	,$clientrpcsfailedserverunavailable
	,$clientrpcsfailedserverunavailablepersec
	,$clientrpcssucceeded
	,$clientrpcssucceededpersec
	,$clienttotalreportedlatency
	,$connectioncount
	,$description
	,$dlmembershipcacheentriescount
	,$dlmembershipcachehits
	,$dlmembershipcachemisses
	,$dlmembershipcachesize
	,$exchmemcurrentbytesallocated
	,$exchmemcurrentnumberofvirtualallocations
	,$exchmemcurrentvirtualbytesallocated
	,$exchmemmaximumbytesallocated
	,$exchmemmaximumvirtualbytesallocated
	,$exchmemnumberofadditionalheaps
	,$exchmemnumberofheaps
	,$exchmemnumberofheapswithmemoryerrors
	,$exchmemnumberofmemoryerrors
	,$exchmemtotalnumberofvirtualallocations
	,$fbpublishcount
	,$fbpublishrate
	,$maximumanonymoususers
	,$maximumconnections
	,$maximumusers
	,$messagecreatepersec
	,$messagedeletepersec
	,$messagemodifypersec
	,$messagemovepersec
	,$messagesprereadascendingpersec
	,$messagesprereaddescendingpersec
	,$messagesprereadskippedpersec
	,$minimsgcreatedforviewspersec
	,$minimsgmsgtableseekspersec
	,$msgviewrecordsdeletedpersec
	,$msgviewrecordsdeletesdeferredpersec
	,$msgviewrecordsinsertedpersec
	,$msgviewrecordsinsertsdeferredpersec
	,$msgviewtablecreatepersec
	,$msgviewtabledeletepersec
	,$msgviewtablenullrefreshpersec
	,$msgviewtablerefreshdvurecordsscanned
	,$msgviewtablerefreshpersec
	,$msgviewtablerefreshupdatesapplied
	,$tablename
	,$oabdifferentialdownloadattempts
	,$oabdifferentialdownloadbytes
	,$oabdifferentialdownloadbytespersec
	,$oabfulldownloadattempts
	,$oabfulldownloadattemptsblocked
	,$oabfulldownloadbytes
	,$oabfulldownloadbytespersec
	,$peakasyncnotificationscachesize
	,$peakpushnotificationscachesize
	,$percentconnections
	,$percentrpcthreads
	,$pushnotificationscachesize
	,$pushnotificationsgeneratedpersec
	,$pushnotificationsskippedpersec
	,$readbytesrpcclientspersec
	,$recurringappointmentdeletionrate
	,$recurringappointmentmodificationrate
	,$recurringappointmentscreated
	,$recurringappointmentsdeleted
	,$recurringappointmentsmodified
	,$recurringapppointmentcreationrate
	,$recurringmasterappointmentsexpanded
	,$recurringmasterexpansionrate
	,$rpcaveragedlatency
	,$rpcclientbackoffpersec
	,$rpcclientsbytesread
	,$rpcclientsbyteswritten
	,$rpcclientsuncompressedbytesread
	,$rpcclientsuncompressedbyteswritten
	,$rpcnumofslowpackets
	,$rpcoperationspersec
	,$rpcpacketspersec
	,$rpcpoolasyncnotificationsgeneratedpersec
	,$rpcpoolcontexthandles
	,$rpcpoolparkedasyncnotificationcalls
	,$rpcpoolpools
	,$rpcpoolsessionnotificationspending
	,$rpcpoolsessions
	,$rpcrequests
	,$rpcrequestspeak
	,$rpcrequesttimeoutdetected
	,$singleappointmentcreationrate
	,$singleappointmentdeletionrate
	,$singleappointmentmodificationrate
	,$singleappointmentscreated
	,$singleappointmentsdeleted
	,$singleappointmentsmodified
	,$slowqpthreads
	,$slowsearchthreads
	,$totalparkedasyncnotificationcalls
	,$usercount
	,$viewcleanupcategorizationindexdeletionspersec
	,$viewcleanupdvuentrydeletionspersec
	,$viewcleanuprestrictionindexdeletionspersec
	,$viewcleanupsearchindexdeletionspersec
	,$viewcleanupsortindexdeletionspersec
	,$viewcleanuptasksnullifiedpersec
	,$viewcleanuptaskspersec
	,$virusscanbytesscanned
	,$virusscanfilescleaned
	,$virusscanfilescleanedpersec
	,$virusscanfilesquarantined
	,$virusscanfilesquarantinedpersec
	,$virusscanfilesscanned
	,$virusscanfilesscannedpersec
	,$virusscanfoldersscannedinbackground
	,$virusscanmessagescleaned
	,$virusscanmessagescleanedpersec
	,$virusscanmessagesdeleted
	,$virusscanmessagesdeletedpersec
	,$virusscanmessagesprocessed
	,$virusscanmessagesprocessedpersec
	,$virusscanmessagesquarantined
	,$virusscanmessagesquarantinedpersec
	,$virusscanmessagesscannedinbackground
	,$virusscanqueuelength
	,$vmlargestblocksize
	,$vmtotal16mbfreeblocks
	,$vmtotalfreeblocks
	,$vmtotallargefreeblockbytes
	,$writebytesrpcclientspersec
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeISClient
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchisclient (
	deviceid
	,scantime
	,activeclientconnections
	,caption
	,clientconnections
	,description
	,directoryaccesscacheentriesaddedpersec
	,directoryaccesscacheentriesexpiredpersec
	,directoryaccesscachehitspercent
	,directoryaccessldapreadspersec
	,directoryaccessldapsearchespersec
	,jetlogrecordbytespersec
	,jetlogrecordspersec
	,jetpagesmodifiedpersec
	,jetpagesprereadpersec
	,jetpagesreadpersec
	,jetpagesreferencedpersec
	,jetpagesremodifiedpersec
	,messagecreatepersec
	,messagedeletepersec
	,messagemodifypersec
	,messagemovepersec
	,minimsgcreatedforviewspersec
	,minimsgmsgtableseekspersec
	,msgviewrecordsdeletedpersec
	,msgviewrecordsdeletesdeferredpersec
	,msgviewrecordsinsertedpersec
	,msgviewrecordsinsertsdeferredpersec
	,msgviewtablecreatepersec
	,msgviewtablenullrefreshpersec
	,msgviewtablerefreshdvurecordsscanned
	,msgviewtablerefreshpersec
	,msgviewtablerefreshupdatesapplied
	,name
	,rpcaveragelatency
	,rpcbytesreceivedpersec
	,rpcbytessentpersec
	,rpcoperationspersec
	,rpcpacketspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $activeclientconnections = undef;
my $caption = undef;
my $clientconnections = undef;
my $description = undef;
my $directoryaccesscacheentriesaddedpersec = undef;
my $directoryaccesscacheentriesexpiredpersec = undef;
my $directoryaccesscachehitspercent = undef;
my $directoryaccessldapreadspersec = undef;
my $directoryaccessldapsearchespersec = undef;
my $jetlogrecordbytespersec = undef;
my $jetlogrecordspersec = undef;
my $jetpagesmodifiedpersec = undef;
my $jetpagesprereadpersec = undef;
my $jetpagesreadpersec = undef;
my $jetpagesreferencedpersec = undef;
my $jetpagesremodifiedpersec = undef;
my $messagecreatepersec = undef;
my $messagedeletepersec = undef;
my $messagemodifypersec = undef;
my $messagemovepersec = undef;
my $minimsgcreatedforviewspersec = undef;
my $minimsgmsgtableseekspersec = undef;
my $msgviewrecordsdeletedpersec = undef;
my $msgviewrecordsdeletesdeferredpersec = undef;
my $msgviewrecordsinsertedpersec = undef;
my $msgviewrecordsinsertsdeferredpersec = undef;
my $msgviewtablecreatepersec = undef;
my $msgviewtablenullrefreshpersec = undef;
my $msgviewtablerefreshdvurecordsscanned = undef;
my $msgviewtablerefreshpersec = undef;
my $msgviewtablerefreshupdatesapplied = undef;
my $tablename = undef;
my $rpcaveragelatency = undef;
my $rpcbytesreceivedpersec = undef;
my $rpcbytessentpersec = undef;
my $rpcoperationspersec = undef;
my $rpcpacketspersec = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'activeclientconnections'} = $process->{'ActiveClientConnections'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'clientconnections'} = $process->{'ClientConnections'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'directoryaccesscacheentriesaddedpersec'} = $process->{'DirectoryAccessCacheEntriesAddedPersec'};
	$risc->{$name}->{'1'}->{'directoryaccesscacheentriesexpiredpersec'} = $process->{'DirectoryAccessCacheEntriesExpiredPersec'};
	$risc->{$name}->{'1'}->{'directoryaccesscachehitspercent'} = $process->{'DirectoryAccessCacheHitsPercent'};
	$risc->{$name}->{'1'}->{'directoryaccesscachehitspercent_base'} = $process->{'DirectoryAccessCacheHitsPercent_Base'};
	$risc->{$name}->{'1'}->{'directoryaccessldapreadspersec'} = $process->{'DirectoryAccessLDAPReadsPersec'};
	$risc->{$name}->{'1'}->{'directoryaccessldapsearchespersec'} = $process->{'DirectoryAccessLDAPSearchesPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'jetlogrecordbytespersec'} = $process->{'JETLogRecordBytesPersec'};
	$risc->{$name}->{'1'}->{'jetlogrecordspersec'} = $process->{'JETLogRecordsPersec'};
	$risc->{$name}->{'1'}->{'jetpagesmodifiedpersec'} = $process->{'JETPagesModifiedPersec'};
	$risc->{$name}->{'1'}->{'jetpagesprereadpersec'} = $process->{'JETPagesPrereadPersec'};
	$risc->{$name}->{'1'}->{'jetpagesreadpersec'} = $process->{'JETPagesReadPersec'};
	$risc->{$name}->{'1'}->{'jetpagesreferencedpersec'} = $process->{'JETPagesReferencedPersec'};
	$risc->{$name}->{'1'}->{'jetpagesremodifiedpersec'} = $process->{'JETPagesRemodifiedPersec'};
	$risc->{$name}->{'1'}->{'messagecreatepersec'} = $process->{'MessageCreatePersec'};
	$risc->{$name}->{'1'}->{'messagedeletepersec'} = $process->{'MessageDeletePersec'};
	$risc->{$name}->{'1'}->{'messagemodifypersec'} = $process->{'MessageModifyPersec'};
	$risc->{$name}->{'1'}->{'messagemovepersec'} = $process->{'MessageMovePersec'};
	$risc->{$name}->{'1'}->{'minimsgcreatedforviewspersec'} = $process->{'MinimsgCreatedforViewsPersec'};
	$risc->{$name}->{'1'}->{'minimsgmsgtableseekspersec'} = $process->{'MinimsgMsgtableseeksPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsdeletedpersec'} = $process->{'MsgViewRecordsDeletedPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsdeletesdeferredpersec'} = $process->{'MsgViewRecordsDeletesDeferredPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsinsertedpersec'} = $process->{'MsgViewRecordsInsertedPersec'};
	$risc->{$name}->{'1'}->{'msgviewrecordsinsertsdeferredpersec'} = $process->{'MsgViewRecordsInsertsDeferredPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablecreatepersec'} = $process->{'MsgViewtableCreatePersec'};
	$risc->{$name}->{'1'}->{'msgviewtablenullrefreshpersec'} = $process->{'MsgViewtableNullRefreshPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshdvurecordsscanned'} = $process->{'MsgViewtablerefreshDVUrecordsscanned'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshdvurecordsscanned_base'} = $process->{'MsgViewtablerefreshDVUrecordsscanned_Base'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshpersec'} = $process->{'MsgViewtableRefreshPersec'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshupdatesapplied'} = $process->{'MsgViewtablerefreshupdatesapplied'};
	$risc->{$name}->{'1'}->{'msgviewtablerefreshupdatesapplied_base'} = $process->{'MsgViewtablerefreshupdatesapplied_Base'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'1'}->{'rpcbytesreceivedpersec'} = $process->{'RPCBytesReceivedPersec'};
	$risc->{$name}->{'1'}->{'rpcbytessentpersec'} = $process->{'RPCBytesSentPersec'};
	$risc->{$name}->{'1'}->{'rpcoperationspersec'} = $process->{'RPCOperationsPersec'};
	$risc->{$name}->{'1'}->{'rpcpacketspersec'} = $process->{'RPCPacketsPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'activeclientconnections'} = $process->{'ActiveClientConnections'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'clientconnections'} = $process->{'ClientConnections'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'directoryaccesscacheentriesaddedpersec'} = $process->{'DirectoryAccessCacheEntriesAddedPersec'};
	$risc->{$name}->{'2'}->{'directoryaccesscacheentriesexpiredpersec'} = $process->{'DirectoryAccessCacheEntriesExpiredPersec'};
	$risc->{$name}->{'2'}->{'directoryaccesscachehitspercent'} = $process->{'DirectoryAccessCacheHitsPercent'};
	$risc->{$name}->{'2'}->{'directoryaccesscachehitspercent_base'} = $process->{'DirectoryAccessCacheHitsPercent_Base'};
	$risc->{$name}->{'2'}->{'directoryaccessldapreadspersec'} = $process->{'DirectoryAccessLDAPReadsPersec'};
	$risc->{$name}->{'2'}->{'directoryaccessldapsearchespersec'} = $process->{'DirectoryAccessLDAPSearchesPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'jetlogrecordbytespersec'} = $process->{'JETLogRecordBytesPersec'};
	$risc->{$name}->{'2'}->{'jetlogrecordspersec'} = $process->{'JETLogRecordsPersec'};
	$risc->{$name}->{'2'}->{'jetpagesmodifiedpersec'} = $process->{'JETPagesModifiedPersec'};
	$risc->{$name}->{'2'}->{'jetpagesprereadpersec'} = $process->{'JETPagesPrereadPersec'};
	$risc->{$name}->{'2'}->{'jetpagesreadpersec'} = $process->{'JETPagesReadPersec'};
	$risc->{$name}->{'2'}->{'jetpagesreferencedpersec'} = $process->{'JETPagesReferencedPersec'};
	$risc->{$name}->{'2'}->{'jetpagesremodifiedpersec'} = $process->{'JETPagesRemodifiedPersec'};
	$risc->{$name}->{'2'}->{'messagecreatepersec'} = $process->{'MessageCreatePersec'};
	$risc->{$name}->{'2'}->{'messagedeletepersec'} = $process->{'MessageDeletePersec'};
	$risc->{$name}->{'2'}->{'messagemodifypersec'} = $process->{'MessageModifyPersec'};
	$risc->{$name}->{'2'}->{'messagemovepersec'} = $process->{'MessageMovePersec'};
	$risc->{$name}->{'2'}->{'minimsgcreatedforviewspersec'} = $process->{'MinimsgCreatedforViewsPersec'};
	$risc->{$name}->{'2'}->{'minimsgmsgtableseekspersec'} = $process->{'MinimsgMsgtableseeksPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsdeletedpersec'} = $process->{'MsgViewRecordsDeletedPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsdeletesdeferredpersec'} = $process->{'MsgViewRecordsDeletesDeferredPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsinsertedpersec'} = $process->{'MsgViewRecordsInsertedPersec'};
	$risc->{$name}->{'2'}->{'msgviewrecordsinsertsdeferredpersec'} = $process->{'MsgViewRecordsInsertsDeferredPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablecreatepersec'} = $process->{'MsgViewtableCreatePersec'};
	$risc->{$name}->{'2'}->{'msgviewtablenullrefreshpersec'} = $process->{'MsgViewtableNullRefreshPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshdvurecordsscanned'} = $process->{'MsgViewtablerefreshDVUrecordsscanned'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshdvurecordsscanned_base'} = $process->{'MsgViewtablerefreshDVUrecordsscanned_Base'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshpersec'} = $process->{'MsgViewtableRefreshPersec'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshupdatesapplied'} = $process->{'MsgViewtablerefreshupdatesapplied'};
	$risc->{$name}->{'2'}->{'msgviewtablerefreshupdatesapplied_base'} = $process->{'MsgViewtablerefreshupdatesapplied_Base'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'2'}->{'rpcbytesreceivedpersec'} = $process->{'RPCBytesReceivedPersec'};
	$risc->{$name}->{'2'}->{'rpcbytessentpersec'} = $process->{'RPCBytesSentPersec'};
	$risc->{$name}->{'2'}->{'rpcoperationspersec'} = $process->{'RPCOperationsPersec'};
	$risc->{$name}->{'2'}->{'rpcpacketspersec'} = $process->{'RPCPacketsPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};	
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;


	#---find ActiveClientConnections---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeclientconnections = $risc->{$calname}->{'2'}->{'activeclientconnections'};
#	print "ActiveClientConnections: $activeclientconnections \n\n";
	

	#---find ClientConnections---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientconnections = $risc->{$calname}->{'2'}->{'clientconnections'};
#	print "ClientConnections: $clientconnections \n\n";


	#---find DirectoryAccessCacheEntriesAddedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'directoryaccesscacheentriesaddedpersec'};	
#	print "DirectoryAccessCacheEntriesAddedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'directoryaccesscacheentriesaddedpersec'};	
#	print "DirectoryAccessCacheEntriesAddedPersec2: $val2 \n";	
	eval 	
	{	
	$directoryaccesscacheentriesaddedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "DirectoryAccessCacheEntriesAddedPersec: $directoryaccesscacheentriesaddedpersec \n\n";	


	#---find DirectoryAccessCacheEntriesExpiredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'directoryaccesscacheentriesexpiredpersec'};	
#	print "DirectoryAccessCacheEntriesExpiredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'directoryaccesscacheentriesexpiredpersec'};	
#	print "DirectoryAccessCacheEntriesExpiredPersec2: $val2 \n";	
	eval 	
	{	
	$directoryaccesscacheentriesexpiredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "DirectoryAccessCacheEntriesExpiredPersec: $directoryaccesscacheentriesexpiredpersec \n\n";	


	#---find DirectoryAccessCacheHitsPercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'directoryaccesscachehitspercent'};	
#	print "DirectoryAccessCacheHitsPercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'directoryaccesscachehitspercent'};	
#	print "DirectoryAccessCacheHitsPercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'directoryaccesscachehitspercent_base'};	
#	print "DirectoryAccessCacheHitsPercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'directoryaccesscachehitspercent_base'};	
#	print "DirectoryAccessCacheHitsPercent_base2: $val_base2\n";	
	eval 	
	{	
	$directoryaccesscachehitspercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "DirectoryAccessCacheHitsPercent: $directoryaccesscachehitspercent \n";	


	#---find DirectoryAccessLDAPReadsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'directoryaccessldapreadspersec'};	
#	print "DirectoryAccessLDAPReadsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'directoryaccessldapreadspersec'};	
#	print "DirectoryAccessLDAPReadsPersec2: $val2 \n";	
	eval 	
	{	
	$directoryaccessldapreadspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "DirectoryAccessLDAPReadsPersec: $directoryaccessldapreadspersec \n\n";	


	#---find DirectoryAccessLDAPSearchesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'directoryaccessldapsearchespersec'};	
#	print "DirectoryAccessLDAPSearchesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'directoryaccessldapsearchespersec'};	
#	print "DirectoryAccessLDAPSearchesPersec2: $val2 \n";	
	eval 	
	{	
	$directoryaccessldapsearchespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "DirectoryAccessLDAPSearchesPersec: $directoryaccessldapsearchespersec \n\n";	


	#---find JETLogRecordBytesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetlogrecordbytespersec'};	
#	print "JETLogRecordBytesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetlogrecordbytespersec'};	
#	print "JETLogRecordBytesPersec2: $val2 \n";	
	eval 	
	{	
	$jetlogrecordbytespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETLogRecordBytesPersec: $jetlogrecordbytespersec \n\n";	


	#---find JETLogRecordsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetlogrecordspersec'};	
#	print "JETLogRecordsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetlogrecordspersec'};	
#	print "JETLogRecordsPersec2: $val2 \n";	
	eval 	
	{	
	$jetlogrecordspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETLogRecordsPersec: $jetlogrecordspersec \n\n";	


	#---find JETPagesModifiedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetpagesmodifiedpersec'};	
#	print "JETPagesModifiedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetpagesmodifiedpersec'};	
#	print "JETPagesModifiedPersec2: $val2 \n";	
	eval 	
	{	
	$jetpagesmodifiedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETPagesModifiedPersec: $jetpagesmodifiedpersec \n\n";	


	#---find JETPagesPrereadPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetpagesprereadpersec'};	
#	print "JETPagesPrereadPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetpagesprereadpersec'};	
#	print "JETPagesPrereadPersec2: $val2 \n";	
	eval 	
	{	
	$jetpagesprereadpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETPagesPrereadPersec: $jetpagesprereadpersec \n\n";	


	#---find JETPagesReadPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetpagesreadpersec'};	
#	print "JETPagesReadPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetpagesreadpersec'};	
#	print "JETPagesReadPersec2: $val2 \n";	
	eval 	
	{	
	$jetpagesreadpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETPagesReadPersec: $jetpagesreadpersec \n\n";	


	#---find JETPagesReferencedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetpagesreferencedpersec'};	
#	print "JETPagesReferencedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetpagesreferencedpersec'};	
#	print "JETPagesReferencedPersec2: $val2 \n";	
	eval 	
	{	
	$jetpagesreferencedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETPagesReferencedPersec: $jetpagesreferencedpersec \n\n";	


	#---find JETPagesRemodifiedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'jetpagesremodifiedpersec'};	
#	print "JETPagesRemodifiedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'jetpagesremodifiedpersec'};	
#	print "JETPagesRemodifiedPersec2: $val2 \n";	
	eval 	
	{	
	$jetpagesremodifiedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "JETPagesRemodifiedPersec: $jetpagesremodifiedpersec \n\n";	


	#---find MessageCreatePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagecreatepersec'};	
#	print "MessageCreatePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagecreatepersec'};	
#	print "MessageCreatePersec2: $val2 \n";	
	eval 	
	{	
	$messagecreatepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageCreatePersec: $messagecreatepersec \n\n";	


	#---find MessageDeletePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagedeletepersec'};	
#	print "MessageDeletePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagedeletepersec'};	
#	print "MessageDeletePersec2: $val2 \n";	
	eval 	
	{	
	$messagedeletepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageDeletePersec: $messagedeletepersec \n\n";	


	#---find MessageModifyPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagemodifypersec'};	
#	print "MessageModifyPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagemodifypersec'};	
#	print "MessageModifyPersec2: $val2 \n";	
	eval 	
	{	
	$messagemodifypersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageModifyPersec: $messagemodifypersec \n\n";	


	#---find MessageMovePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagemovepersec'};	
#	print "MessageMovePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagemovepersec'};	
#	print "MessageMovePersec2: $val2 \n";	
	eval 	
	{	
	$messagemovepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageMovePersec: $messagemovepersec \n\n";	


	#---find MinimsgCreatedforViewsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'minimsgcreatedforviewspersec'};	
#	print "MinimsgCreatedforViewsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'minimsgcreatedforviewspersec'};	
#	print "MinimsgCreatedforViewsPersec2: $val2 \n";	
	eval 	
	{	
	$minimsgcreatedforviewspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MinimsgCreatedforViewsPersec: $minimsgcreatedforviewspersec \n\n";	


	#---find MinimsgMsgtableseeksPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'minimsgmsgtableseekspersec'};	
#	print "MinimsgMsgtableseeksPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'minimsgmsgtableseekspersec'};	
#	print "MinimsgMsgtableseeksPersec2: $val2 \n";	
	eval 	
	{	
	$minimsgmsgtableseekspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MinimsgMsgtableseeksPersec: $minimsgmsgtableseekspersec \n\n";	


	#---find MsgViewRecordsDeletedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsdeletedpersec'};	
#	print "MsgViewRecordsDeletedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsdeletedpersec'};	
#	print "MsgViewRecordsDeletedPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsdeletedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsDeletedPersec: $msgviewrecordsdeletedpersec \n\n";	


	#---find MsgViewRecordsDeletesDeferredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsdeletesdeferredpersec'};	
#	print "MsgViewRecordsDeletesDeferredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsdeletesdeferredpersec'};	
#	print "MsgViewRecordsDeletesDeferredPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsdeletesdeferredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsDeletesDeferredPersec: $msgviewrecordsdeletesdeferredpersec \n\n";	


	#---find MsgViewRecordsInsertedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsinsertedpersec'};	
#	print "MsgViewRecordsInsertedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsinsertedpersec'};	
#	print "MsgViewRecordsInsertedPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsinsertedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsInsertedPersec: $msgviewrecordsinsertedpersec \n\n";	


	#---find MsgViewRecordsInsertsDeferredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewrecordsinsertsdeferredpersec'};	
#	print "MsgViewRecordsInsertsDeferredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewrecordsinsertsdeferredpersec'};	
#	print "MsgViewRecordsInsertsDeferredPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewrecordsinsertsdeferredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewRecordsInsertsDeferredPersec: $msgviewrecordsinsertsdeferredpersec \n\n";	


	#---find MsgViewtableCreatePersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablecreatepersec'};	
#	print "MsgViewtableCreatePersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablecreatepersec'};	
#	print "MsgViewtableCreatePersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablecreatepersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableCreatePersec: $msgviewtablecreatepersec \n\n";	


	#---find MsgViewtableNullRefreshPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablenullrefreshpersec'};	
#	print "MsgViewtableNullRefreshPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablenullrefreshpersec'};	
#	print "MsgViewtableNullRefreshPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablenullrefreshpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableNullRefreshPersec: $msgviewtablenullrefreshpersec \n\n";	


	#---find MsgViewtablerefreshDVUrecordsscanned---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshdvurecordsscanned'};	
#	print "MsgViewtablerefreshDVUrecordsscanned1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshdvurecordsscanned'};	
#	print "MsgViewtablerefreshDVUrecordsscanned2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshdvurecordsscanned_base'};	
#	print "MsgViewtablerefreshDVUrecordsscanned_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshdvurecordsscanned_base'};	
#	print "MsgViewtablerefreshDVUrecordsscanned_base2: $val_base2\n";	
	eval 	
	{	
	$msgviewtablerefreshdvurecordsscanned = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MsgViewtablerefreshDVUrecordsscanned: $msgviewtablerefreshdvurecordsscanned \n";	


	#---find MsgViewtableRefreshPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshpersec'};	
#	print "MsgViewtableRefreshPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshpersec'};	
#	print "MsgViewtableRefreshPersec2: $val2 \n";	
	eval 	
	{	
	$msgviewtablerefreshpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MsgViewtableRefreshPersec: $msgviewtablerefreshpersec \n\n";	


	#---find MsgViewtablerefreshupdatesapplied---#	
	$val1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshupdatesapplied'};	
#	print "MsgViewtablerefreshupdatesapplied1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshupdatesapplied'};	
#	print "MsgViewtablerefreshupdatesapplied2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'msgviewtablerefreshupdatesapplied_base'};	
#	print "MsgViewtablerefreshupdatesapplied_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'msgviewtablerefreshupdatesapplied_base'};	
#	print "MsgViewtablerefreshupdatesapplied_base2: $val_base2\n";	
	eval 	
	{	
	$msgviewtablerefreshupdatesapplied = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MsgViewtablerefreshupdatesapplied: $msgviewtablerefreshupdatesapplied \n";	


	#---find RPCAverageLatency---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcaveragelatency = $risc->{$calname}->{'2'}->{'rpcaveragelatency'};
#	print "RPCAverageLatency: $rpcaveragelatency \n\n";


	#---find RPCBytesReceivedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcbytesreceivedpersec'};	
#	print "RPCBytesReceivedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcbytesreceivedpersec'};	
#	print "RPCBytesReceivedPersec2: $val2 \n";	
	eval 	
	{	
	$rpcbytesreceivedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCBytesReceivedPersec: $rpcbytesreceivedpersec \n\n";	


	#---find RPCBytesSentPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcbytessentpersec'};	
#	print "RPCBytesSentPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcbytessentpersec'};	
#	print "RPCBytesSentPersec2: $val2 \n";	
	eval 	
	{	
	$rpcbytessentpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCBytesSentPersec: $rpcbytessentpersec \n\n";	


	#---find RPCOperationsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcoperationspersec'};	
#	print "RPCOperationsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcoperationspersec'};	
#	print "RPCOperationsPersec2: $val2 \n";	
	eval 	
	{	
	$rpcoperationspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCOperationsPersec: $rpcoperationspersec \n\n";	


	#---find RPCPacketsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'rpcpacketspersec'};	
#	print "RPCPacketsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'rpcpacketspersec'};	
#	print "RPCPacketsPersec2: $val2 \n";	
	eval 	
	{	
	$rpcpacketspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RPCPacketsPersec: $rpcpacketspersec \n\n";	


#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$activeclientconnections
	,$caption
	,$clientconnections
	,$description
	,$directoryaccesscacheentriesaddedpersec
	,$directoryaccesscacheentriesexpiredpersec
	,$directoryaccesscachehitspercent
	,$directoryaccessldapreadspersec
	,$directoryaccessldapsearchespersec
	,$jetlogrecordbytespersec
	,$jetlogrecordspersec
	,$jetpagesmodifiedpersec
	,$jetpagesprereadpersec
	,$jetpagesreadpersec
	,$jetpagesreferencedpersec
	,$jetpagesremodifiedpersec
	,$messagecreatepersec
	,$messagedeletepersec
	,$messagemodifypersec
	,$messagemovepersec
	,$minimsgcreatedforviewspersec
	,$minimsgmsgtableseekspersec
	,$msgviewrecordsdeletedpersec
	,$msgviewrecordsdeletesdeferredpersec
	,$msgviewrecordsinsertedpersec
	,$msgviewrecordsinsertsdeferredpersec
	,$msgviewtablecreatepersec
	,$msgviewtablenullrefreshpersec
	,$msgviewtablerefreshdvurecordsscanned
	,$msgviewtablerefreshpersec
	,$msgviewtablerefreshupdatesapplied
	,$tablename
	,$rpcaveragelatency
	,$rpcbytesreceivedpersec
	,$rpcbytessentpersec
	,$rpcoperationspersec
	,$rpcpacketspersec
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeISMailbox
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchismailbox (
	deviceid
	,scantime
	,activeclientlogons
	,averagedeliverytime
	,caption
	,clientlogons
	,deliveryblockedlowdatabasespace
	,deliveryblockedlowlogdiskspace
	,description
	,eventhistorydeletes
	,eventhistorydeletespersec
	,eventhistoryeventcachehitspercent
	,eventhistoryeventscount
	,eventhistoryeventswithemptycontainerclass
	,eventhistoryeventswithemptymessageclass
	,eventhistoryeventswithtruncatedcontainerclass
	,eventhistoryeventswithtruncatedmessageclass
	,eventhistoryreads
	,eventhistoryreadspersec
	,eventhistoryuncommittedtransactionscount
	,eventhistorywatermarkscount
	,eventhistorywatermarksdeletes
	,eventhistorywatermarksdeletespersec
	,eventhistorywatermarksreads
	,eventhistorywatermarksreadspersec
	,eventhistorywatermarkswrites
	,eventhistorywatermarkswritespersec
	,eventhistorywrites
	,eventhistorywritespersec
	,exchangesearchfirstbatch
	,exchangesearchlessone
	,exchangesearchonetoten
	,exchangesearchqueries
	,exchangesearchslowfirstbatch
	,exchangesearchtenmore
	,exchangesearchzeroresultsqueries
	,folderopenspersec
	,lastquerytime
	,localdeliveries
	,localdeliveryrate
	,logonoperationspersec
	,mailboxlogonentrycachehitrate
	,mailboxlogonentrycachehitratepercent
	,mailboxlogonentrycachemissrate
	,mailboxlogonentrycachemissratepercent
	,mailboxlogonentrycachesize
	,mailboxmetadatacachehitrate
	,mailboxmetadatacachehitratepercent
	,mailboxmetadatacachemissrate
	,mailboxmetadatacachemissratepercent
	,mailboxmetadatacachesize
	,mailboxreplicationreadconnections
	,mailboxreplicationwriteconnections
	,messageopenspersec
	,messagerecipientsdelivered
	,messagerecipientsdeliveredpersec
	,messagesdelivered
	,messagesdeliveredpersec
	,messagesqueuedforsubmission
	,messagessent
	,messagessentpersec
	,messagessubmitted
	,messagessubmittedpersec
	,name
	,peakclientlogons
	,quarantinedmailboxcount
	,replidcount
	,restrictedviewcachehitrate
	,restrictedviewcachemissrate
	,rpcaveragelatency
	,searchtaskrate
	,slowfindrowrate
	,storeonlyqueries
	,storeonlyquerytenmore
	,storeonlyqueryuptoten
	,totalcountofrecoverableitems
	,totalqueries
	,totalsizeofrecoverableitems
	,virusscanbackgroundmessagesscanned
	,virusscanbackgroundmessagesskipped
	,virusscanbackgroundmessagesuptodate
	,virusscanbackgroundscanningthreads
	,virusscanexternalresultsaccepted
	,virusscanexternalresultsnotaccepted
	,virusscanexternalresultsnotpresent
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $activeclientlogons = undef;
my $averagedeliverytime = undef;
my $caption = undef;
my $clientlogons = undef;
my $deliveryblockedlowdatabasespace = undef;
my $deliveryblockedlowlogdiskspace = undef;
my $description = undef;
my $eventhistorydeletes = undef;
my $eventhistorydeletespersec = undef;
my $eventhistoryeventcachehitspercent = undef;
my $eventhistoryeventscount = undef;
my $eventhistoryeventswithemptycontainerclass = undef;
my $eventhistoryeventswithemptymessageclass = undef;
my $eventhistoryeventswithtruncatedcontainerclass = undef;
my $eventhistoryeventswithtruncatedmessageclass = undef;
my $eventhistoryreads = undef;
my $eventhistoryreadspersec = undef;
my $eventhistoryuncommittedtransactionscount = undef;
my $eventhistorywatermarkscount = undef;
my $eventhistorywatermarksdeletes = undef;
my $eventhistorywatermarksdeletespersec = undef;
my $eventhistorywatermarksreads = undef;
my $eventhistorywatermarksreadspersec = undef;
my $eventhistorywatermarkswrites = undef;
my $eventhistorywatermarkswritespersec = undef;
my $eventhistorywrites = undef;
my $eventhistorywritespersec = undef;
my $exchangesearchfirstbatch = undef;
my $exchangesearchlessone = undef;
my $exchangesearchonetoten = undef;
my $exchangesearchqueries = undef;
my $exchangesearchslowfirstbatch = undef;
my $exchangesearchtenmore = undef;
my $exchangesearchzeroresultsqueries = undef;
my $folderopenspersec = undef;
my $lastquerytime = undef;
my $localdeliveries = undef;
my $localdeliveryrate = undef;
my $logonoperationspersec = undef;
my $mailboxlogonentrycachehitrate = undef;
my $mailboxlogonentrycachehitratepercent = undef;
my $mailboxlogonentrycachemissrate = undef;
my $mailboxlogonentrycachemissratepercent = undef;
my $mailboxlogonentrycachesize = undef;
my $mailboxmetadatacachehitrate = undef;
my $mailboxmetadatacachehitratepercent = undef;
my $mailboxmetadatacachemissrate = undef;
my $mailboxmetadatacachemissratepercent = undef;
my $mailboxmetadatacachesize = undef;
my $mailboxreplicationreadconnections = undef;
my $mailboxreplicationwriteconnections = undef;
my $messageopenspersec = undef;
my $messagerecipientsdelivered = undef;
my $messagerecipientsdeliveredpersec = undef;
my $messagesdelivered = undef;
my $messagesdeliveredpersec = undef;
my $messagesqueuedforsubmission = undef;
my $messagessent = undef;
my $messagessentpersec = undef;
my $messagessubmitted = undef;
my $messagessubmittedpersec = undef;
my $tablename = undef;
my $peakclientlogons = undef;
my $quarantinedmailboxcount = undef;
my $replidcount = undef;
my $restrictedviewcachehitrate = undef;
my $restrictedviewcachemissrate = undef;
my $rpcaveragelatency = undef;
my $searchtaskrate = undef;
my $slowfindrowrate = undef;
my $storeonlyqueries = undef;
my $storeonlyquerytenmore = undef;
my $storeonlyqueryuptoten = undef;
my $totalcountofrecoverableitems = undef;
my $totalqueries = undef;
my $totalsizeofrecoverableitems = undef;
my $virusscanbackgroundmessagesscanned = undef;
my $virusscanbackgroundmessagesskipped = undef;
my $virusscanbackgroundmessagesuptodate = undef;
my $virusscanbackgroundscanningthreads = undef;
my $virusscanexternalresultsaccepted = undef;
my $virusscanexternalresultsnotaccepted = undef;
my $virusscanexternalresultsnotpresent = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'activeclientlogons'} = $process->{'ActiveClientLogons'};
	$risc->{$name}->{'1'}->{'averagedeliverytime'} = $process->{'AverageDeliveryTime'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'clientlogons'} = $process->{'ClientLogons'};
	$risc->{$name}->{'1'}->{'deliveryblockedlowdatabasespace'} = $process->{'DeliveryBlockedLowDatabaseSpace'};
	$risc->{$name}->{'1'}->{'deliveryblockedlowlogdiskspace'} = $process->{'DeliveryBlockedLowLogDiskSpace'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'eventhistorydeletes'} = $process->{'EventHistoryDeletes'};
	$risc->{$name}->{'1'}->{'eventhistorydeletespersec'} = $process->{'EventHistoryDeletesPersec'};
	$risc->{$name}->{'1'}->{'eventhistoryeventcachehitspercent'} = $process->{'EventHistoryEventCacheHitsPercent'};
	$risc->{$name}->{'1'}->{'eventhistoryeventcachehitspercent_base'} = $process->{'EventHistoryEventCacheHitsPercent_Base'};
	$risc->{$name}->{'1'}->{'eventhistoryeventscount'} = $process->{'EventHistoryEventsCount'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithemptycontainerclass'} = $process->{'EventHistoryEventsWithEmptyContainerClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithemptymessageclass'} = $process->{'EventHistoryEventsWithEmptyMessageClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithtruncatedcontainerclass'} = $process->{'EventHistoryEventsWithTruncatedContainerClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithtruncatedmessageclass'} = $process->{'EventHistoryEventsWithTruncatedMessageClass'};
	$risc->{$name}->{'1'}->{'eventhistoryreads'} = $process->{'EventHistoryReads'};
	$risc->{$name}->{'1'}->{'eventhistoryreadspersec'} = $process->{'EventHistoryReadsPersec'};
	$risc->{$name}->{'1'}->{'eventhistoryuncommittedtransactionscount'} = $process->{'EventHistoryUncommittedTransactionsCount'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkscount'} = $process->{'EventHistoryWatermarksCount'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksdeletes'} = $process->{'EventHistoryWatermarksDeletes'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksdeletespersec'} = $process->{'EventHistoryWatermarksDeletesPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksreads'} = $process->{'EventHistoryWatermarksReads'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksreadspersec'} = $process->{'EventHistoryWatermarksReadsPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkswrites'} = $process->{'EventHistoryWatermarksWrites'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkswritespersec'} = $process->{'EventHistoryWatermarksWritesPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywrites'} = $process->{'EventHistoryWrites'};
	$risc->{$name}->{'1'}->{'eventhistorywritespersec'} = $process->{'EventHistoryWritesPersec'};
	$risc->{$name}->{'1'}->{'exchangesearchfirstbatch'} = $process->{'ExchangeSearchFirstBatch'};
	$risc->{$name}->{'1'}->{'exchangesearchlessone'} = $process->{'ExchangeSearchLessOne'};
	$risc->{$name}->{'1'}->{'exchangesearchonetoten'} = $process->{'ExchangeSearchOneToTen'};
	$risc->{$name}->{'1'}->{'exchangesearchqueries'} = $process->{'ExchangeSearchQueries'};
	$risc->{$name}->{'1'}->{'exchangesearchslowfirstbatch'} = $process->{'ExchangeSearchSlowFirstBatch'};
	$risc->{$name}->{'1'}->{'exchangesearchtenmore'} = $process->{'ExchangeSearchTenMore'};
	$risc->{$name}->{'1'}->{'exchangesearchzeroresultsqueries'} = $process->{'ExchangeSearchZeroResultsQueries'};
	$risc->{$name}->{'1'}->{'folderopenspersec'} = $process->{'FolderopensPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'lastquerytime'} = $process->{'LastQueryTime'};
	$risc->{$name}->{'1'}->{'localdeliveries'} = $process->{'Localdeliveries'};
	$risc->{$name}->{'1'}->{'localdeliveryrate'} = $process->{'Localdeliveryrate'};
	$risc->{$name}->{'1'}->{'logonoperationspersec'} = $process->{'LogonOperationsPersec'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitrate'} = $process->{'MailboxLogonEntryCacheHitRate'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitratepercent'} = $process->{'MailboxLogonEntryCacheHitRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitratepercent_base'} = $process->{'MailboxLogonEntryCacheHitRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissrate'} = $process->{'MailboxLogonEntryCacheMissRate'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissratepercent'} = $process->{'MailboxLogonEntryCacheMissRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissratepercent_base'} = $process->{'MailboxLogonEntryCacheMissRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachesize'} = $process->{'MailboxLogonEntryCacheSize'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitrate'} = $process->{'MailboxMetadataCacheHitRate'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitratepercent'} = $process->{'MailboxMetadataCacheHitRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitratepercent_base'} = $process->{'MailboxMetadataCacheHitRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissrate'} = $process->{'MailboxMetadataCacheMissRate'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissratepercent'} = $process->{'MailboxMetadataCacheMissRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissratepercent_base'} = $process->{'MailboxMetadataCacheMissRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachesize'} = $process->{'MailboxMetadataCacheSize'};
	$risc->{$name}->{'1'}->{'mailboxreplicationreadconnections'} = $process->{'MailboxReplicationReadConnections'};
	$risc->{$name}->{'1'}->{'mailboxreplicationwriteconnections'} = $process->{'MailboxReplicationWriteConnections'};
	$risc->{$name}->{'1'}->{'messageopenspersec'} = $process->{'MessageOpensPersec'};
	$risc->{$name}->{'1'}->{'messagerecipientsdelivered'} = $process->{'MessageRecipientsDelivered'};
	$risc->{$name}->{'1'}->{'messagerecipientsdeliveredpersec'} = $process->{'MessageRecipientsDeliveredPersec'};
	$risc->{$name}->{'1'}->{'messagesdelivered'} = $process->{'MessagesDelivered'};
	$risc->{$name}->{'1'}->{'messagesdeliveredpersec'} = $process->{'MessagesDeliveredPersec'};
	$risc->{$name}->{'1'}->{'messagesqueuedforsubmission'} = $process->{'MessagesQueuedForSubmission'};
	$risc->{$name}->{'1'}->{'messagessent'} = $process->{'MessagesSent'};
	$risc->{$name}->{'1'}->{'messagessentpersec'} = $process->{'MessagesSentPersec'};
	$risc->{$name}->{'1'}->{'messagessubmitted'} = $process->{'MessagesSubmitted'};
	$risc->{$name}->{'1'}->{'messagessubmittedpersec'} = $process->{'MessagesSubmittedPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'peakclientlogons'} = $process->{'PeakClientLogons'};
	$risc->{$name}->{'1'}->{'quarantinedmailboxcount'} = $process->{'QuarantinedMailboxCount'};
	$risc->{$name}->{'1'}->{'replidcount'} = $process->{'ReplIDCount'};
	$risc->{$name}->{'1'}->{'restrictedviewcachehitrate'} = $process->{'RestrictedViewCacheHitRate'};
	$risc->{$name}->{'1'}->{'restrictedviewcachemissrate'} = $process->{'RestrictedViewCacheMissRate'};
	$risc->{$name}->{'1'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'1'}->{'searchtaskrate'} = $process->{'SearchTaskRate'};
	$risc->{$name}->{'1'}->{'slowfindrowrate'} = $process->{'SlowFindRowRate'};
	$risc->{$name}->{'1'}->{'storeonlyqueries'} = $process->{'StoreOnlyQueries'};
	$risc->{$name}->{'1'}->{'storeonlyquerytenmore'} = $process->{'StoreOnlyQueryTenMore'};
	$risc->{$name}->{'1'}->{'storeonlyqueryuptoten'} = $process->{'StoreOnlyQueryUpToTen'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalcountofrecoverableitems'} = $process->{'TotalCountofRecoverableItems'};
	$risc->{$name}->{'1'}->{'totalqueries'} = $process->{'TotalQueries'};
	$risc->{$name}->{'1'}->{'totalsizeofrecoverableitems'} = $process->{'TotalSizeofRecoverableItems'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesscanned'} = $process->{'VirusScanBackgroundMessagesScanned'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesskipped'} = $process->{'VirusScanBackgroundMessagesSkipped'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesuptodate'} = $process->{'VirusScanBackgroundMessagesUpToDate'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundscanningthreads'} = $process->{'VirusScanBackgroundScanningThreads'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsaccepted'} = $process->{'VirusScanExternalResultsAccepted'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsnotaccepted'} = $process->{'VirusScanExternalResultsNotAccepted'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsnotpresent'} = $process->{'VirusScanExternalResultsNotPresent'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'activeclientlogons'} = $process->{'ActiveClientLogons'};
	$risc->{$name}->{'2'}->{'averagedeliverytime'} = $process->{'AverageDeliveryTime'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'clientlogons'} = $process->{'ClientLogons'};
	$risc->{$name}->{'2'}->{'deliveryblockedlowdatabasespace'} = $process->{'DeliveryBlockedLowDatabaseSpace'};
	$risc->{$name}->{'2'}->{'deliveryblockedlowlogdiskspace'} = $process->{'DeliveryBlockedLowLogDiskSpace'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'eventhistorydeletes'} = $process->{'EventHistoryDeletes'};
	$risc->{$name}->{'2'}->{'eventhistorydeletespersec'} = $process->{'EventHistoryDeletesPersec'};
	$risc->{$name}->{'2'}->{'eventhistoryeventcachehitspercent'} = $process->{'EventHistoryEventCacheHitsPercent'};
	$risc->{$name}->{'2'}->{'eventhistoryeventcachehitspercent_base'} = $process->{'EventHistoryEventCacheHitsPercent_Base'};
	$risc->{$name}->{'2'}->{'eventhistoryeventscount'} = $process->{'EventHistoryEventsCount'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithemptycontainerclass'} = $process->{'EventHistoryEventsWithEmptyContainerClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithemptymessageclass'} = $process->{'EventHistoryEventsWithEmptyMessageClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithtruncatedcontainerclass'} = $process->{'EventHistoryEventsWithTruncatedContainerClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithtruncatedmessageclass'} = $process->{'EventHistoryEventsWithTruncatedMessageClass'};
	$risc->{$name}->{'2'}->{'eventhistoryreads'} = $process->{'EventHistoryReads'};
	$risc->{$name}->{'2'}->{'eventhistoryreadspersec'} = $process->{'EventHistoryReadsPersec'};
	$risc->{$name}->{'2'}->{'eventhistoryuncommittedtransactionscount'} = $process->{'EventHistoryUncommittedTransactionsCount'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkscount'} = $process->{'EventHistoryWatermarksCount'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksdeletes'} = $process->{'EventHistoryWatermarksDeletes'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksdeletespersec'} = $process->{'EventHistoryWatermarksDeletesPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksreads'} = $process->{'EventHistoryWatermarksReads'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksreadspersec'} = $process->{'EventHistoryWatermarksReadsPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkswrites'} = $process->{'EventHistoryWatermarksWrites'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkswritespersec'} = $process->{'EventHistoryWatermarksWritesPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywrites'} = $process->{'EventHistoryWrites'};
	$risc->{$name}->{'2'}->{'eventhistorywritespersec'} = $process->{'EventHistoryWritesPersec'};
	$risc->{$name}->{'2'}->{'exchangesearchfirstbatch'} = $process->{'ExchangeSearchFirstBatch'};
	$risc->{$name}->{'2'}->{'exchangesearchlessone'} = $process->{'ExchangeSearchLessOne'};
	$risc->{$name}->{'2'}->{'exchangesearchonetoten'} = $process->{'ExchangeSearchOneToTen'};
	$risc->{$name}->{'2'}->{'exchangesearchqueries'} = $process->{'ExchangeSearchQueries'};
	$risc->{$name}->{'2'}->{'exchangesearchslowfirstbatch'} = $process->{'ExchangeSearchSlowFirstBatch'};
	$risc->{$name}->{'2'}->{'exchangesearchtenmore'} = $process->{'ExchangeSearchTenMore'};
	$risc->{$name}->{'2'}->{'exchangesearchzeroresultsqueries'} = $process->{'ExchangeSearchZeroResultsQueries'};
	$risc->{$name}->{'2'}->{'folderopenspersec'} = $process->{'FolderopensPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'lastquerytime'} = $process->{'LastQueryTime'};
	$risc->{$name}->{'2'}->{'localdeliveries'} = $process->{'Localdeliveries'};
	$risc->{$name}->{'2'}->{'localdeliveryrate'} = $process->{'Localdeliveryrate'};
	$risc->{$name}->{'2'}->{'logonoperationspersec'} = $process->{'LogonOperationsPersec'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitrate'} = $process->{'MailboxLogonEntryCacheHitRate'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitratepercent'} = $process->{'MailboxLogonEntryCacheHitRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitratepercent_base'} = $process->{'MailboxLogonEntryCacheHitRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissrate'} = $process->{'MailboxLogonEntryCacheMissRate'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissratepercent'} = $process->{'MailboxLogonEntryCacheMissRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissratepercent_base'} = $process->{'MailboxLogonEntryCacheMissRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachesize'} = $process->{'MailboxLogonEntryCacheSize'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitrate'} = $process->{'MailboxMetadataCacheHitRate'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitratepercent'} = $process->{'MailboxMetadataCacheHitRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitratepercent_base'} = $process->{'MailboxMetadataCacheHitRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissrate'} = $process->{'MailboxMetadataCacheMissRate'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissratepercent'} = $process->{'MailboxMetadataCacheMissRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissratepercent_base'} = $process->{'MailboxMetadataCacheMissRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachesize'} = $process->{'MailboxMetadataCacheSize'};
	$risc->{$name}->{'2'}->{'mailboxreplicationreadconnections'} = $process->{'MailboxReplicationReadConnections'};
	$risc->{$name}->{'2'}->{'mailboxreplicationwriteconnections'} = $process->{'MailboxReplicationWriteConnections'};
	$risc->{$name}->{'2'}->{'messageopenspersec'} = $process->{'MessageOpensPersec'};
	$risc->{$name}->{'2'}->{'messagerecipientsdelivered'} = $process->{'MessageRecipientsDelivered'};
	$risc->{$name}->{'2'}->{'messagerecipientsdeliveredpersec'} = $process->{'MessageRecipientsDeliveredPersec'};
	$risc->{$name}->{'2'}->{'messagesdelivered'} = $process->{'MessagesDelivered'};
	$risc->{$name}->{'2'}->{'messagesdeliveredpersec'} = $process->{'MessagesDeliveredPersec'};
	$risc->{$name}->{'2'}->{'messagesqueuedforsubmission'} = $process->{'MessagesQueuedForSubmission'};
	$risc->{$name}->{'2'}->{'messagessent'} = $process->{'MessagesSent'};
	$risc->{$name}->{'2'}->{'messagessentpersec'} = $process->{'MessagesSentPersec'};
	$risc->{$name}->{'2'}->{'messagessubmitted'} = $process->{'MessagesSubmitted'};
	$risc->{$name}->{'2'}->{'messagessubmittedpersec'} = $process->{'MessagesSubmittedPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'peakclientlogons'} = $process->{'PeakClientLogons'};
	$risc->{$name}->{'2'}->{'quarantinedmailboxcount'} = $process->{'QuarantinedMailboxCount'};
	$risc->{$name}->{'2'}->{'replidcount'} = $process->{'ReplIDCount'};
	$risc->{$name}->{'2'}->{'restrictedviewcachehitrate'} = $process->{'RestrictedViewCacheHitRate'};
	$risc->{$name}->{'2'}->{'restrictedviewcachemissrate'} = $process->{'RestrictedViewCacheMissRate'};
	$risc->{$name}->{'2'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'2'}->{'searchtaskrate'} = $process->{'SearchTaskRate'};
	$risc->{$name}->{'2'}->{'slowfindrowrate'} = $process->{'SlowFindRowRate'};
	$risc->{$name}->{'2'}->{'storeonlyqueries'} = $process->{'StoreOnlyQueries'};
	$risc->{$name}->{'2'}->{'storeonlyquerytenmore'} = $process->{'StoreOnlyQueryTenMore'};
	$risc->{$name}->{'2'}->{'storeonlyqueryuptoten'} = $process->{'StoreOnlyQueryUpToTen'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalcountofrecoverableitems'} = $process->{'TotalCountofRecoverableItems'};
	$risc->{$name}->{'2'}->{'totalqueries'} = $process->{'TotalQueries'};
	$risc->{$name}->{'2'}->{'totalsizeofrecoverableitems'} = $process->{'TotalSizeofRecoverableItems'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesscanned'} = $process->{'VirusScanBackgroundMessagesScanned'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesskipped'} = $process->{'VirusScanBackgroundMessagesSkipped'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesuptodate'} = $process->{'VirusScanBackgroundMessagesUpToDate'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundscanningthreads'} = $process->{'VirusScanBackgroundScanningThreads'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsaccepted'} = $process->{'VirusScanExternalResultsAccepted'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsnotaccepted'} = $process->{'VirusScanExternalResultsNotAccepted'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsnotpresent'} = $process->{'VirusScanExternalResultsNotPresent'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;


	#---find ActiveClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeclientlogons = $risc->{$calname}->{'2'}->{'activeclientlogons'};
#	print "ActiveClientLogons: $activeclientlogons \n\n";


	#---find AverageDeliveryTime---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$averagedeliverytime = $risc->{$calname}->{'2'}->{'averagedeliverytime'};
#	print "AverageDeliveryTime: $averagedeliverytime \n\n";


	#---find ClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientlogons = $risc->{$calname}->{'2'}->{'clientlogons'};
#	print "ClientLogons: $clientlogons \n\n";


	#---find DeliveryBlockedLowDatabaseSpace---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$deliveryblockedlowdatabasespace = $risc->{$calname}->{'2'}->{'deliveryblockedlowdatabasespace'};
#	print "DeliveryBlockedLowDatabaseSpace: $deliveryblockedlowdatabasespace \n\n";


	#---find DeliveryBlockedLowLogDiskSpace---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$deliveryblockedlowlogdiskspace = $risc->{$calname}->{'2'}->{'deliveryblockedlowlogdiskspace'};
#	print "DeliveryBlockedLowLogDiskSpace: $deliveryblockedlowlogdiskspace \n\n";


	#---find EventHistoryDeletes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorydeletes = $risc->{$calname}->{'2'}->{'eventhistorydeletes'};
#	print "EventHistoryDeletes: $eventhistorydeletes \n\n";


	#---find EventHistoryDeletesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorydeletespersec'};	
#	print "EventHistoryDeletesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorydeletespersec'};	
#	print "EventHistoryDeletesPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorydeletespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryDeletesPersec: $eventhistorydeletespersec \n\n";	


	#---find EventHistoryEventCacheHitsPercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistoryeventcachehitspercent'};	
#	print "eventhistoryeventcachehitspercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistoryeventcachehitspercent'};	
#	print "eventhistoryeventcachehitspercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'eventhistoryeventcachehitspercent_base'};	
#	print "eventhistoryeventcachehitspercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'eventhistoryeventcachehitspercent_base'};	
#	print "eventhistoryeventcachehitspercent_base2: $val_base2\n";	
	eval 	
	{	
	$eventhistoryeventcachehitspercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "eventhistoryeventcachehitspercent: $eventhistoryeventcachehitspercent \n";	

	#---find EventHistoryEventsCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventscount = $risc->{$calname}->{'2'}->{'eventhistoryeventscount'};
#	print "EventHistoryEventsCount: $eventhistoryeventscount \n\n";


	#---find EventHistoryEventsWithEmptyContainerClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithemptycontainerclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithemptycontainerclass'};
#	print "EventHistoryEventsWithEmptyContainerClass: $eventhistoryeventswithemptycontainerclass \n\n";


	#---find EventHistoryEventsWithEmptyMessageClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithemptymessageclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithemptymessageclass'};
#	print "EventHistoryEventsWithEmptyMessageClass: $eventhistoryeventswithemptymessageclass \n\n";


	#---find EventHistoryEventsWithTruncatedContainerClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithtruncatedcontainerclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithtruncatedcontainerclass'};
#	print "EventHistoryEventsWithTruncatedContainerClass: $eventhistoryeventswithtruncatedcontainerclass \n\n";


	#---find EventHistoryEventsWithTruncatedMessageClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithtruncatedmessageclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithtruncatedmessageclass'};
#	print "EventHistoryEventsWithTruncatedMessageClass: $eventhistoryeventswithtruncatedmessageclass \n\n";


	#---find EventHistoryReads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryreads = $risc->{$calname}->{'2'}->{'eventhistoryreads'};
#	print "EventHistoryReads: $eventhistoryreads \n\n";


	#---find EventHistoryReadsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistoryreadspersec'};	
#	print "EventHistoryReadsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistoryreadspersec'};	
#	print "EventHistoryReadsPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistoryreadspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryReadsPersec: $eventhistoryreadspersec \n\n";	


	#---find EventHistoryUncommittedTransactionsCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryuncommittedtransactionscount = $risc->{$calname}->{'2'}->{'eventhistoryuncommittedtransactionscount'};
#	print "EventHistoryUncommittedTransactionsCount: $eventhistoryuncommittedtransactionscount \n\n";


	#---find EventHistoryWatermarksCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarkscount = $risc->{$calname}->{'2'}->{'eventhistorywatermarkscount'};
#	print "EventHistoryWatermarksCount: $eventhistorywatermarkscount \n\n";


	#---find EventHistoryWatermarksDeletes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarksdeletes = $risc->{$calname}->{'2'}->{'eventhistorywatermarksdeletes'};
#	print "EventHistoryWatermarksDeletes: $eventhistorywatermarksdeletes \n\n";


	#---find EventHistoryWatermarksDeletesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarksdeletespersec'};	
#	print "EventHistoryWatermarksDeletesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarksdeletespersec'};	
#	print "EventHistoryWatermarksDeletesPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorywatermarksdeletespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryWatermarksDeletesPersec: $eventhistorywatermarksdeletespersec \n\n";	


	#---find EventHistoryWatermarksReads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarksreads = $risc->{$calname}->{'2'}->{'eventhistorywatermarksreads'};
#	print "EventHistoryWatermarksReads: $eventhistorywatermarksreads \n\n";


	#---find EventHistoryWatermarksReadsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarksreadspersec'};	
#	print "EventHistoryWatermarksReadsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarksreadspersec'};	
#	print "EventHistoryWatermarksReadsPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorywatermarksreadspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryWatermarksReadsPersec: $eventhistorywatermarksreadspersec \n\n";	


	#---find EventHistoryWatermarksWrites---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarkswrites = $risc->{$calname}->{'2'}->{'eventhistorywatermarkswrites'};
#	print "EventHistoryWatermarksWrites: $eventhistorywatermarkswrites \n\n";


	#---find EventHistoryWatermarksWritesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarkswritespersec'};	
#	print "EventHistoryWatermarksWritesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarkswritespersec'};	
#	print "EventHistoryWatermarksWritesPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorywatermarkswritespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryWatermarksWritesPersec: $eventhistorywatermarkswritespersec \n\n";	


	#---find EventHistoryWrites---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywrites = $risc->{$calname}->{'2'}->{'eventhistorywrites'};
#	print "EventHistoryWrites: $eventhistorywrites \n\n";


	#---find EventHistoryWritesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorywritespersec'};	
#	print "EventHistoryWritesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorywritespersec'};	
#	print "EventHistoryWritesPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorywritespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryWritesPersec: $eventhistorywritespersec \n\n";	


	#---find ExchangeSearchFirstBatch---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchfirstbatch = $risc->{$calname}->{'2'}->{'exchangesearchfirstbatch'};
#	print "ExchangeSearchFirstBatch: $exchangesearchfirstbatch \n\n";


	#---find ExchangeSearchLessOne---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchlessone = $risc->{$calname}->{'2'}->{'exchangesearchlessone'};
#	print "ExchangeSearchLessOne: $exchangesearchlessone \n\n";


	#---find ExchangeSearchOneToTen---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchonetoten = $risc->{$calname}->{'2'}->{'exchangesearchonetoten'};
#	print "ExchangeSearchOneToTen: $exchangesearchonetoten \n\n";


	#---find ExchangeSearchQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchqueries = $risc->{$calname}->{'2'}->{'exchangesearchqueries'};
#	print "ExchangeSearchQueries: $exchangesearchqueries \n\n";


	#---find ExchangeSearchSlowFirstBatch---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchslowfirstbatch = $risc->{$calname}->{'2'}->{'exchangesearchslowfirstbatch'};
#	print "ExchangeSearchSlowFirstBatch: $exchangesearchslowfirstbatch \n\n";


	#---find ExchangeSearchTenMore---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchtenmore = $risc->{$calname}->{'2'}->{'exchangesearchtenmore'};
#	print "ExchangeSearchTenMore: $exchangesearchtenmore \n\n";


	#---find ExchangeSearchZeroResultsQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$exchangesearchzeroresultsqueries = $risc->{$calname}->{'2'}->{'exchangesearchzeroresultsqueries'};
#	print "ExchangeSearchZeroResultsQueries: $exchangesearchzeroresultsqueries \n\n";


	#---find FolderopensPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'folderopenspersec'};	
#	print "FolderopensPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'folderopenspersec'};	
#	print "FolderopensPersec2: $val2 \n";	
	eval 	
	{	
	$folderopenspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "FolderopensPersec: $folderopenspersec \n\n";	


	#---find LastQueryTime---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$lastquerytime = $risc->{$calname}->{'2'}->{'lastquerytime'};
#	print "LastQueryTime: $lastquerytime \n\n";


	#---find Localdeliveries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$localdeliveries = $risc->{$calname}->{'2'}->{'localdeliveries'};
#	print "Localdeliveries: $localdeliveries \n\n";


	#---find Localdeliveryrate---#	
	$val1 = $risc->{$calname}->{'1'}->{'localdeliveryrate'};	
#	print "Localdeliveryrate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'localdeliveryrate'};	
#	print "Localdeliveryrate2: $val2 \n";	
	eval 	
	{	
	$localdeliveryrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "Localdeliveryrate: $localdeliveryrate \n\n";	


	#---find LogonOperationsPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'logonoperationspersec'};	
#	print "LogonOperationsPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'logonoperationspersec'};	
#	print "LogonOperationsPersec2: $val2 \n";	
	eval 	
	{	
	$logonoperationspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "LogonOperationsPersec: $logonoperationspersec \n\n";	


	#---find MailboxLogonEntryCacheHitRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitrate'};	
#	print "MailboxLogonEntryCacheHitRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitrate'};	
#	print "MailboxLogonEntryCacheHitRate2: $val2 \n";	
	eval 	
	{	
	$mailboxlogonentrycachehitrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MailboxLogonEntryCacheHitRate: $mailboxlogonentrycachehitrate \n\n";	


	#---find MailboxLogonEntryCacheHitRatePercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitratepercent'};	
#	print "MailboxLogonEntryCacheHitRatePercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitratepercent'};	
#	print "MailboxLogonEntryCacheHitRatePercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitratepercent_base'};	
#	print "MailboxLogonEntryCacheHitRatePercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitratepercent_base'};	
#	print "MailboxLogonEntryCacheHitRatePercent_base2: $val_base2\n";	
	eval 	
	{	
	$mailboxlogonentrycachehitratepercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MailboxLogonEntryCacheHitRatePercent: $mailboxlogonentrycachehitratepercent \n";	


	#---find MailboxLogonEntryCacheMissRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissrate'};	
#	print "MailboxLogonEntryCacheMissRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissrate'};	
#	print "MailboxLogonEntryCacheMissRate2: $val2 \n";	
	eval 	
	{	
	$mailboxlogonentrycachemissrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MailboxLogonEntryCacheMissRate: $mailboxlogonentrycachemissrate \n\n";	


	#---find MailboxLogonEntryCacheMissRatePercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissratepercent'};	
#	print "MailboxLogonEntryCacheMissRatePercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissratepercent'};	
#	print "MailboxLogonEntryCacheMissRatePercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissratepercent_base'};	
#	print "MailboxLogonEntryCacheMissRatePercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissratepercent_base'};	
#	print "MailboxLogonEntryCacheMissRatePercent_base2: $val_base2\n";	
	eval 	
	{	
	$mailboxlogonentrycachemissratepercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MailboxLogonEntryCacheMissRatePercent: $mailboxlogonentrycachemissratepercent \n";	


	#---find MailboxLogonEntryCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxlogonentrycachesize = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachesize'};
#	print "MailboxLogonEntryCacheSize: $mailboxlogonentrycachesize \n\n";


	#---find MailboxMetadataCacheHitRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitrate'};	
#	print "MailboxMetadataCacheHitRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitrate'};	
#	print "MailboxMetadataCacheHitRate2: $val2 \n";	
	eval 	
	{	
	$mailboxmetadatacachehitrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MailboxMetadataCacheHitRate: $mailboxmetadatacachehitrate \n\n";	


	#---find MailboxMetadataCacheHitRatePercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitratepercent'};	
#	print "MailboxMetadataCacheHitRatePercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitratepercent'};	
#	print "MailboxMetadataCacheHitRatePercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitratepercent_base'};	
#	print "MailboxMetadataCacheHitRatePercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitratepercent_base'};	
#	print "MailboxMetadataCacheHitRatePercent_base2: $val_base2\n";	
	eval 	
	{	
	$mailboxmetadatacachehitratepercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MailboxMetadataCacheHitRatePercent: $mailboxmetadatacachehitratepercent \n";	


	#---find MailboxMetadataCacheMissRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissrate'};	
#	print "MailboxMetadataCacheMissRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissrate'};	
#	print "MailboxMetadataCacheMissRate2: $val2 \n";	
	eval 	
	{	
	$mailboxmetadatacachemissrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MailboxMetadataCacheMissRate: $mailboxmetadatacachemissrate \n\n";	


	#---find MailboxMetadataCacheMissRatePercent---#	
	$val1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissratepercent'};	
#	print "MailboxMetadataCacheMissRatePercent1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissratepercent'};	
#	print "MailboxMetadataCacheMissRatePercent2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissratepercent_base'};	
#	print "MailboxMetadataCacheMissRatePercent_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissratepercent_base'};	
#	print "MailboxMetadataCacheMissRatePercent_base2: $val_base2\n";	
	eval 	
	{	
	$mailboxmetadatacachemissratepercent = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "MailboxMetadataCacheMissRatePercent: $mailboxmetadatacachemissratepercent \n";	


	#---find MailboxMetadataCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxmetadatacachesize = $risc->{$calname}->{'2'}->{'mailboxmetadatacachesize'};
#	print "MailboxMetadataCacheSize: $mailboxmetadatacachesize \n\n";


	#---find MailboxReplicationReadConnections---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxreplicationreadconnections = $risc->{$calname}->{'2'}->{'mailboxreplicationreadconnections'};
#	print "MailboxReplicationReadConnections: $mailboxreplicationreadconnections \n\n";


	#---find MailboxReplicationWriteConnections---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxreplicationwriteconnections = $risc->{$calname}->{'2'}->{'mailboxreplicationwriteconnections'};
#	print "MailboxReplicationWriteConnections: $mailboxreplicationwriteconnections \n\n";


	#---find MessageOpensPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messageopenspersec'};	
#	print "MessageOpensPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messageopenspersec'};	
#	print "MessageOpensPersec2: $val2 \n";	
	eval 	
	{	
	$messageopenspersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageOpensPersec: $messageopenspersec \n\n";	


	#---find MessageRecipientsDelivered---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagerecipientsdelivered = $risc->{$calname}->{'2'}->{'messagerecipientsdelivered'};
#	print "MessageRecipientsDelivered: $messagerecipientsdelivered \n\n";


	#---find MessageRecipientsDeliveredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagerecipientsdeliveredpersec'};	
#	print "MessageRecipientsDeliveredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagerecipientsdeliveredpersec'};	
#	print "MessageRecipientsDeliveredPersec2: $val2 \n";	
	eval 	
	{	
	$messagerecipientsdeliveredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessageRecipientsDeliveredPersec: $messagerecipientsdeliveredpersec \n\n";	


	#---find MessagesDelivered---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagesdelivered = $risc->{$calname}->{'2'}->{'messagesdelivered'};
#	print "MessagesDelivered: $messagesdelivered \n\n";


	#---find MessagesDeliveredPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagesdeliveredpersec'};	
#	print "MessagesDeliveredPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagesdeliveredpersec'};	
#	print "MessagesDeliveredPersec2: $val2 \n";	
	eval 	
	{	
	$messagesdeliveredpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesDeliveredPersec: $messagesdeliveredpersec \n\n";	


	#---find MessagesQueuedForSubmission---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagesqueuedforsubmission = $risc->{$calname}->{'2'}->{'messagesqueuedforsubmission'};
#	print "MessagesQueuedForSubmission: $messagesqueuedforsubmission \n\n";


	#---find MessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagessent = $risc->{$calname}->{'2'}->{'messagessent'};
#	print "MessagesSent: $messagessent \n\n";


	#---find MessagesSentPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagessentpersec'};	
#	print "MessagesSentPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagessentpersec'};	
#	print "MessagesSentPersec2: $val2 \n";	
	eval 	
	{	
	$messagessentpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesSentPersec: $messagessentpersec \n\n";	


	#---find MessagesSubmitted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagessubmitted = $risc->{$calname}->{'2'}->{'messagessubmitted'};
#	print "MessagesSubmitted: $messagessubmitted \n\n";


	#---find MessagesSubmittedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagessubmittedpersec'};	
#	print "MessagesSubmittedPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagessubmittedpersec'};	
#	print "MessagesSubmittedPersec2: $val2 \n";	
	eval 	
	{	
	$messagessubmittedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "MessagesSubmittedPersec: $messagessubmittedpersec \n\n";	


	#---find PeakClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$peakclientlogons = $risc->{$calname}->{'2'}->{'peakclientlogons'};
#	print "PeakClientLogons: $peakclientlogons \n\n";


	#---find QuarantinedMailboxCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$quarantinedmailboxcount = $risc->{$calname}->{'2'}->{'quarantinedmailboxcount'};
#	print "QuarantinedMailboxCount: $quarantinedmailboxcount \n\n";


	#---find ReplIDCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replidcount = $risc->{$calname}->{'2'}->{'replidcount'};
#	print "ReplIDCount: $replidcount \n\n";


	#---find RestrictedViewCacheHitRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'restrictedviewcachehitrate'};	
#	print "RestrictedViewCacheHitRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'restrictedviewcachehitrate'};	
#	print "RestrictedViewCacheHitRate2: $val2 \n";	
	eval 	
	{	
	$restrictedviewcachehitrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RestrictedViewCacheHitRate: $restrictedviewcachehitrate \n\n";	


	#---find RestrictedViewCacheMissRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'restrictedviewcachemissrate'};	
#	print "RestrictedViewCacheMissRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'restrictedviewcachemissrate'};	
#	print "RestrictedViewCacheMissRate2: $val2 \n";	
	eval 	
	{	
	$restrictedviewcachemissrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RestrictedViewCacheMissRate: $restrictedviewcachemissrate \n\n";	


	#---find RPCAverageLatency---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcaveragelatency = $risc->{$calname}->{'2'}->{'rpcaveragelatency'};
#	print "RPCAverageLatency: $rpcaveragelatency \n\n";


	#---find SearchTaskRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'searchtaskrate'};	
#	print "SearchTaskRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'searchtaskrate'};	
#	print "SearchTaskRate2: $val2 \n";	
	eval 	
	{	
	$searchtaskrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SearchTaskRate: $searchtaskrate \n\n";	


	#---find SlowFindRowRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'slowfindrowrate'};	
#	print "SlowFindRowRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'slowfindrowrate'};	
#	print "SlowFindRowRate2: $val2 \n";	
	eval 	
	{	
	$slowfindrowrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SlowFindRowRate: $slowfindrowrate \n\n";	


	#---find StoreOnlyQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyqueries = $risc->{$calname}->{'2'}->{'storeonlyqueries'};
#	print "StoreOnlyQueries: $storeonlyqueries \n\n";


	#---find StoreOnlyQueryTenMore---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyquerytenmore = $risc->{$calname}->{'2'}->{'storeonlyquerytenmore'};
#	print "StoreOnlyQueryTenMore: $storeonlyquerytenmore \n\n";


	#---find StoreOnlyQueryUpToTen---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyqueryuptoten = $risc->{$calname}->{'2'}->{'storeonlyqueryuptoten'};
#	print "StoreOnlyQueryUpToTen: $storeonlyqueryuptoten \n\n";


	#---find TotalCountofRecoverableItems---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalcountofrecoverableitems = $risc->{$calname}->{'2'}->{'totalcountofrecoverableitems'};
#	print "TotalCountofRecoverableItems: $totalcountofrecoverableitems \n\n";


	#---find TotalQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalqueries = $risc->{$calname}->{'2'}->{'totalqueries'};
#	print "TotalQueries: $totalqueries \n\n";


	#---find TotalSizeofRecoverableItems---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalsizeofrecoverableitems = $risc->{$calname}->{'2'}->{'totalsizeofrecoverableitems'};
#	print "TotalSizeofRecoverableItems: $totalsizeofrecoverableitems \n\n";


	#---find VirusScanBackgroundMessagesScanned---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesscanned = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesscanned'};
#	print "VirusScanBackgroundMessagesScanned: $virusscanbackgroundmessagesscanned \n\n";


	#---find VirusScanBackgroundMessagesSkipped---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesskipped = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesskipped'};
#	print "VirusScanBackgroundMessagesSkipped: $virusscanbackgroundmessagesskipped \n\n";


	#---find VirusScanBackgroundMessagesUpToDate---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesuptodate = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesuptodate'};
#	print "VirusScanBackgroundMessagesUpToDate: $virusscanbackgroundmessagesuptodate \n\n";


	#---find VirusScanBackgroundScanningThreads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundscanningthreads = $risc->{$calname}->{'2'}->{'virusscanbackgroundscanningthreads'};
#	print "VirusScanBackgroundScanningThreads: $virusscanbackgroundscanningthreads \n\n";


	#---find VirusScanExternalResultsAccepted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsaccepted = $risc->{$calname}->{'2'}->{'virusscanexternalresultsaccepted'};
#	print "VirusScanExternalResultsAccepted: $virusscanexternalresultsaccepted \n\n";


	#---find VirusScanExternalResultsNotAccepted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsnotaccepted = $risc->{$calname}->{'2'}->{'virusscanexternalresultsnotaccepted'};
#	print "VirusScanExternalResultsNotAccepted: $virusscanexternalresultsnotaccepted \n\n";


	#---find VirusScanExternalResultsNotPresent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsnotpresent = $risc->{$calname}->{'2'}->{'virusscanexternalresultsnotpresent'};
#	print "VirusScanExternalResultsNotPresent: $virusscanexternalresultsnotpresent \n\n";

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$activeclientlogons
	,$averagedeliverytime
	,$caption
	,$clientlogons
	,$deliveryblockedlowdatabasespace
	,$deliveryblockedlowlogdiskspace
	,$description
	,$eventhistorydeletes
	,$eventhistorydeletespersec
	,$eventhistoryeventcachehitspercent
	,$eventhistoryeventscount
	,$eventhistoryeventswithemptycontainerclass
	,$eventhistoryeventswithemptymessageclass
	,$eventhistoryeventswithtruncatedcontainerclass
	,$eventhistoryeventswithtruncatedmessageclass
	,$eventhistoryreads
	,$eventhistoryreadspersec
	,$eventhistoryuncommittedtransactionscount
	,$eventhistorywatermarkscount
	,$eventhistorywatermarksdeletes
	,$eventhistorywatermarksdeletespersec
	,$eventhistorywatermarksreads
	,$eventhistorywatermarksreadspersec
	,$eventhistorywatermarkswrites
	,$eventhistorywatermarkswritespersec
	,$eventhistorywrites
	,$eventhistorywritespersec
	,$exchangesearchfirstbatch
	,$exchangesearchlessone
	,$exchangesearchonetoten
	,$exchangesearchqueries
	,$exchangesearchslowfirstbatch
	,$exchangesearchtenmore
	,$exchangesearchzeroresultsqueries
	,$folderopenspersec
	,$lastquerytime
	,$localdeliveries
	,$localdeliveryrate
	,$logonoperationspersec
	,$mailboxlogonentrycachehitrate
	,$mailboxlogonentrycachehitratepercent
	,$mailboxlogonentrycachemissrate
	,$mailboxlogonentrycachemissratepercent
	,$mailboxlogonentrycachesize
	,$mailboxmetadatacachehitrate
	,$mailboxmetadatacachehitratepercent
	,$mailboxmetadatacachemissrate
	,$mailboxmetadatacachemissratepercent
	,$mailboxmetadatacachesize
	,$mailboxreplicationreadconnections
	,$mailboxreplicationwriteconnections
	,$messageopenspersec
	,$messagerecipientsdelivered
	,$messagerecipientsdeliveredpersec
	,$messagesdelivered
	,$messagesdeliveredpersec
	,$messagesqueuedforsubmission
	,$messagessent
	,$messagessentpersec
	,$messagessubmitted
	,$messagessubmittedpersec
	,$tablename
	,$peakclientlogons
	,$quarantinedmailboxcount
	,$replidcount
	,$restrictedviewcachehitrate
	,$restrictedviewcachemissrate
	,$rpcaveragelatency
	,$searchtaskrate
	,$slowfindrowrate
	,$storeonlyqueries
	,$storeonlyquerytenmore
	,$storeonlyqueryuptoten
	,$totalcountofrecoverableitems
	,$totalqueries
	,$totalsizeofrecoverableitems
	,$virusscanbackgroundmessagesscanned
	,$virusscanbackgroundmessagesskipped
	,$virusscanbackgroundmessagesuptodate
	,$virusscanbackgroundscanningthreads
	,$virusscanexternalresultsaccepted
	,$virusscanexternalresultsnotaccepted
	,$virusscanexternalresultsnotpresent	
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeISPublic
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchispublic (
	deviceid
	,scantime
	,activeclientlogons
	,averagedeliverytime
	,caption
	,clientlogons
	,deliveryblockedlowdatabasespace
	,deliveryblockedlowlogdiskspace
	,description
	,eventhistorydeletes
	,eventhistorydeletespersec
	,eventhistoryeventcachehitspercent
	,eventhistoryeventscount
	,eventhistoryeventswithemptycontainerclass
	,eventhistoryeventswithemptymessageclass
	,eventhistoryeventswithtruncatedcontainerclass
	,eventhistoryeventswithtruncatedmessageclass
	,eventhistoryreads
	,eventhistoryreadspersec
	,eventhistoryuncommittedtransactionscount
	,eventhistorywatermarkscount
	,eventhistorywatermarksdeletes
	,eventhistorywatermarksdeletespersec
	,eventhistorywatermarksreads
	,eventhistorywatermarksreadspersec
	,eventhistorywatermarkswrites
	,eventhistorywatermarkswritespersec
	,eventhistorywrites
	,eventhistorywritespersec
	,folderopenspersec
	,lastquerytime
	,logonoperationspersec
	,mailboxlogonentrycachehitrate
	,mailboxlogonentrycachehitratepercent
	,mailboxlogonentrycachemissrate
	,mailboxlogonentrycachemissratepercent
	,mailboxlogonentrycachesize
	,mailboxmetadatacachehitrate
	,mailboxmetadatacachehitratepercent
	,mailboxmetadatacachemissrate
	,mailboxmetadatacachemissratepercent
	,mailboxmetadatacachesize
	,messageopenspersec
	,messagerecipientsdelivered
	,messagerecipientsdeliveredpersec
	,messagesdelivered
	,messagesdeliveredpersec
	,messagesqueuedforsubmission
	,messagessent
	,messagessentpersec
	,messagessubmitted
	,messagessubmittedpersec
	,name
	,numberofmessagesexpiredfrompublicfolders
	,peakclientlogons
	,replicationbackfilldatamessagesreceived
	,replicationbackfilldatamessagessent
	,replicationbackfillrequestsreceived
	,replicationbackfillrequestssent
	,replicationfolderchangesreceived
	,replicationfolderchangessent
	,replicationfolderdatamessagesreceived
	,replicationfolderdatamessagessent
	,replicationfoldertreemessagesreceived
	,replicationfoldertreemessagessent
	,replicationmessagechangesreceived
	,replicationmessagechangessent
	,replicationmessagesreceived
	,replicationmessagessent
	,replicationreceivequeuesize
	,replicationstatusmessagesreceived
	,replicationstatusmessagessent
	,replidcount
	,restrictedviewcachehitrate
	,restrictedviewcachemissrate
	,rpcaveragelatency
	,searchtaskrate
	,slowfindrowrate
	,storeonlyqueries
	,storeonlyquerytenmore
	,storeonlyqueryuptoten
	,totalcountofrecoverableitems
	,totalqueries
	,totalsizeofrecoverableitems
	,virusscanbackgroundmessagesscanned
	,virusscanbackgroundmessagesskipped
	,virusscanbackgroundmessagesuptodate
	,virusscanbackgroundscanningthreads
	,virusscanexternalresultsaccepted
	,virusscanexternalresultsnotaccepted
	,virusscanexternalresultsnotpresent
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $activeclientlogons = undef;
my $averagedeliverytime = undef;
my $caption = undef;
my $clientlogons = undef;
my $deliveryblockedlowdatabasespace = undef;
my $deliveryblockedlowlogdiskspace = undef;
my $description = undef;
my $eventhistorydeletes = undef;
my $eventhistorydeletespersec = undef;
my $eventhistoryeventcachehitspercent = undef;
my $eventhistoryeventscount = undef;
my $eventhistoryeventswithemptycontainerclass = undef;
my $eventhistoryeventswithemptymessageclass = undef;
my $eventhistoryeventswithtruncatedcontainerclass = undef;
my $eventhistoryeventswithtruncatedmessageclass = undef;
my $eventhistoryreads = undef;
my $eventhistoryreadspersec = undef;
my $eventhistoryuncommittedtransactionscount = undef;
my $eventhistorywatermarkscount = undef;
my $eventhistorywatermarksdeletes = undef;
my $eventhistorywatermarksdeletespersec = undef;
my $eventhistorywatermarksreads = undef;
my $eventhistorywatermarksreadspersec = undef;
my $eventhistorywatermarkswrites = undef;
my $eventhistorywatermarkswritespersec = undef;
my $eventhistorywrites = undef;
my $eventhistorywritespersec = undef;
my $folderopenspersec = undef;
my $lastquerytime = undef;
my $logonoperationspersec = undef;
my $mailboxlogonentrycachehitrate = undef;
my $mailboxlogonentrycachehitratepercent = undef;
my $mailboxlogonentrycachemissrate = undef;
my $mailboxlogonentrycachemissratepercent = undef;
my $mailboxlogonentrycachesize = undef;
my $mailboxmetadatacachehitrate = undef;
my $mailboxmetadatacachehitratepercent = undef;
my $mailboxmetadatacachemissrate = undef;
my $mailboxmetadatacachemissratepercent = undef;
my $mailboxmetadatacachesize = undef;
my $messageopenspersec = undef;
my $messagerecipientsdelivered = undef;
my $messagerecipientsdeliveredpersec = undef;
my $messagesdelivered = undef;
my $messagesdeliveredpersec = undef;
my $messagesqueuedforsubmission = undef;
my $messagessent = undef;
my $messagessentpersec = undef;
my $messagessubmitted = undef;
my $messagessubmittedpersec = undef;
my $tablename = undef;
my $numberofmessagesexpiredfrompublicfolders = undef;
my $peakclientlogons = undef;
my $replicationbackfilldatamessagesreceived = undef;
my $replicationbackfilldatamessagessent = undef;
my $replicationbackfillrequestsreceived = undef;
my $replicationbackfillrequestssent = undef;
my $replicationfolderchangesreceived = undef;
my $replicationfolderchangessent = undef;
my $replicationfolderdatamessagesreceived = undef;
my $replicationfolderdatamessagessent = undef;
my $replicationfoldertreemessagesreceived = undef;
my $replicationfoldertreemessagessent = undef;
my $replicationmessagechangesreceived = undef;
my $replicationmessagechangessent = undef;
my $replicationmessagesreceived = undef;
my $replicationmessagessent = undef;
my $replicationreceivequeuesize = undef;
my $replicationstatusmessagesreceived = undef;
my $replicationstatusmessagessent = undef;
my $replidcount = undef;
my $restrictedviewcachehitrate = undef;
my $restrictedviewcachemissrate = undef;
my $rpcaveragelatency = undef;
my $searchtaskrate = undef;
my $slowfindrowrate = undef;
my $storeonlyqueries = undef;
my $storeonlyquerytenmore = undef;
my $storeonlyqueryuptoten = undef;
my $totalcountofrecoverableitems = undef;
my $totalqueries = undef;
my $totalsizeofrecoverableitems = undef;
my $virusscanbackgroundmessagesscanned = undef;
my $virusscanbackgroundmessagesskipped = undef;
my $virusscanbackgroundmessagesuptodate = undef;
my $virusscanbackgroundscanningthreads = undef;
my $virusscanexternalresultsaccepted = undef;
my $virusscanexternalresultsnotaccepted = undef;
my $virusscanexternalresultsnotpresent = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'activeclientlogons'} = $process->{'ActiveClientLogons'};
	$risc->{$name}->{'1'}->{'averagedeliverytime'} = $process->{'AverageDeliveryTime'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'clientlogons'} = $process->{'ClientLogons'};
	$risc->{$name}->{'1'}->{'deliveryblockedlowdatabasespace'} = $process->{'DeliveryBlockedLowDatabaseSpace'};
	$risc->{$name}->{'1'}->{'deliveryblockedlowlogdiskspace'} = $process->{'DeliveryBlockedLowLogDiskSpace'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'eventhistorydeletes'} = $process->{'EventHistoryDeletes'};
	$risc->{$name}->{'1'}->{'eventhistorydeletespersec'} = $process->{'EventHistoryDeletesPersec'};
	$risc->{$name}->{'1'}->{'eventhistoryeventcachehitspercent'} = $process->{'EventHistoryEventCacheHitsPercent'};
	$risc->{$name}->{'1'}->{'eventhistoryeventcachehitspercent_base'} = $process->{'EventHistoryEventCacheHitsPercent_Base'};
	$risc->{$name}->{'1'}->{'eventhistoryeventscount'} = $process->{'EventHistoryEventsCount'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithemptycontainerclass'} = $process->{'EventHistoryEventsWithEmptyContainerClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithemptymessageclass'} = $process->{'EventHistoryEventsWithEmptyMessageClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithtruncatedcontainerclass'} = $process->{'EventHistoryEventsWithTruncatedContainerClass'};
	$risc->{$name}->{'1'}->{'eventhistoryeventswithtruncatedmessageclass'} = $process->{'EventHistoryEventsWithTruncatedMessageClass'};
	$risc->{$name}->{'1'}->{'eventhistoryreads'} = $process->{'EventHistoryReads'};
	$risc->{$name}->{'1'}->{'eventhistoryreadspersec'} = $process->{'EventHistoryReadsPersec'};
	$risc->{$name}->{'1'}->{'eventhistoryuncommittedtransactionscount'} = $process->{'EventHistoryUncommittedTransactionsCount'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkscount'} = $process->{'EventHistoryWatermarksCount'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksdeletes'} = $process->{'EventHistoryWatermarksDeletes'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksdeletespersec'} = $process->{'EventHistoryWatermarksDeletesPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksreads'} = $process->{'EventHistoryWatermarksReads'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarksreadspersec'} = $process->{'EventHistoryWatermarksReadsPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkswrites'} = $process->{'EventHistoryWatermarksWrites'};
	$risc->{$name}->{'1'}->{'eventhistorywatermarkswritespersec'} = $process->{'EventHistoryWatermarksWritesPersec'};
	$risc->{$name}->{'1'}->{'eventhistorywrites'} = $process->{'EventHistoryWrites'};
	$risc->{$name}->{'1'}->{'eventhistorywritespersec'} = $process->{'EventHistoryWritesPersec'};
	$risc->{$name}->{'1'}->{'folderopenspersec'} = $process->{'FolderopensPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'lastquerytime'} = $process->{'LastQueryTime'};
	$risc->{$name}->{'1'}->{'logonoperationspersec'} = $process->{'LogonOperationsPersec'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitrate'} = $process->{'MailboxLogonEntryCacheHitRate'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitratepercent'} = $process->{'MailboxLogonEntryCacheHitRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachehitratepercent_base'} = $process->{'MailboxLogonEntryCacheHitRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissrate'} = $process->{'MailboxLogonEntryCacheMissRate'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissratepercent'} = $process->{'MailboxLogonEntryCacheMissRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachemissratepercent_base'} = $process->{'MailboxLogonEntryCacheMissRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxlogonentrycachesize'} = $process->{'MailboxLogonEntryCacheSize'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitrate'} = $process->{'MailboxMetadataCacheHitRate'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitratepercent'} = $process->{'MailboxMetadataCacheHitRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachehitratepercent_base'} = $process->{'MailboxMetadataCacheHitRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissrate'} = $process->{'MailboxMetadataCacheMissRate'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissratepercent'} = $process->{'MailboxMetadataCacheMissRatePercent'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachemissratepercent_base'} = $process->{'MailboxMetadataCacheMissRatePercent_Base'};
	$risc->{$name}->{'1'}->{'mailboxmetadatacachesize'} = $process->{'MailboxMetadataCacheSize'};
	$risc->{$name}->{'1'}->{'messageopenspersec'} = $process->{'MessageOpensPersec'};
	$risc->{$name}->{'1'}->{'messagerecipientsdelivered'} = $process->{'MessageRecipientsDelivered'};
	$risc->{$name}->{'1'}->{'messagerecipientsdeliveredpersec'} = $process->{'MessageRecipientsDeliveredPersec'};
	$risc->{$name}->{'1'}->{'messagesdelivered'} = $process->{'MessagesDelivered'};
	$risc->{$name}->{'1'}->{'messagesdeliveredpersec'} = $process->{'MessagesDeliveredPersec'};
	$risc->{$name}->{'1'}->{'messagesqueuedforsubmission'} = $process->{'MessagesQueuedForSubmission'};
	$risc->{$name}->{'1'}->{'messagessent'} = $process->{'MessagesSent'};
	$risc->{$name}->{'1'}->{'messagessentpersec'} = $process->{'MessagesSentPersec'};
	$risc->{$name}->{'1'}->{'messagessubmitted'} = $process->{'MessagesSubmitted'};
	$risc->{$name}->{'1'}->{'messagessubmittedpersec'} = $process->{'MessagesSubmittedPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'numberofmessagesexpiredfrompublicfolders'} = $process->{'Numberofmessagesexpiredfrompublicfolders'};
	$risc->{$name}->{'1'}->{'peakclientlogons'} = $process->{'PeakClientLogons'};
	$risc->{$name}->{'1'}->{'replicationbackfilldatamessagesreceived'} = $process->{'ReplicationBackfillDataMessagesReceived'};
	$risc->{$name}->{'1'}->{'replicationbackfilldatamessagessent'} = $process->{'ReplicationBackfillDataMessagesSent'};
	$risc->{$name}->{'1'}->{'replicationbackfillrequestsreceived'} = $process->{'ReplicationBackfillRequestsReceived'};
	$risc->{$name}->{'1'}->{'replicationbackfillrequestssent'} = $process->{'ReplicationBackfillRequestsSent'};
	$risc->{$name}->{'1'}->{'replicationfolderchangesreceived'} = $process->{'ReplicationFolderChangesReceived'};
	$risc->{$name}->{'1'}->{'replicationfolderchangessent'} = $process->{'ReplicationFolderChangesSent'};
	$risc->{$name}->{'1'}->{'replicationfolderdatamessagesreceived'} = $process->{'ReplicationFolderDataMessagesReceived'};
	$risc->{$name}->{'1'}->{'replicationfolderdatamessagessent'} = $process->{'ReplicationFolderDataMessagesSent'};
	$risc->{$name}->{'1'}->{'replicationfoldertreemessagesreceived'} = $process->{'ReplicationFolderTreeMessagesReceived'};
	$risc->{$name}->{'1'}->{'replicationfoldertreemessagessent'} = $process->{'ReplicationFolderTreeMessagesSent'};
	$risc->{$name}->{'1'}->{'replicationmessagechangesreceived'} = $process->{'ReplicationMessageChangesReceived'};
	$risc->{$name}->{'1'}->{'replicationmessagechangessent'} = $process->{'ReplicationMessageChangesSent'};
	$risc->{$name}->{'1'}->{'replicationmessagesreceived'} = $process->{'ReplicationMessagesReceived'};
	$risc->{$name}->{'1'}->{'replicationmessagessent'} = $process->{'ReplicationMessagesSent'};
	$risc->{$name}->{'1'}->{'replicationreceivequeuesize'} = $process->{'ReplicationReceiveQueueSize'};
	$risc->{$name}->{'1'}->{'replicationstatusmessagesreceived'} = $process->{'ReplicationStatusMessagesReceived'};
	$risc->{$name}->{'1'}->{'replicationstatusmessagessent'} = $process->{'ReplicationStatusMessagesSent'};
	$risc->{$name}->{'1'}->{'replidcount'} = $process->{'ReplIDCount'};
	$risc->{$name}->{'1'}->{'restrictedviewcachehitrate'} = $process->{'RestrictedViewCacheHitRate'};
	$risc->{$name}->{'1'}->{'restrictedviewcachemissrate'} = $process->{'RestrictedViewCacheMissRate'};
	$risc->{$name}->{'1'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'1'}->{'searchtaskrate'} = $process->{'SearchTaskRate'};
	$risc->{$name}->{'1'}->{'slowfindrowrate'} = $process->{'SlowFindRowRate'};
	$risc->{$name}->{'1'}->{'storeonlyqueries'} = $process->{'StoreOnlyQueries'};
	$risc->{$name}->{'1'}->{'storeonlyquerytenmore'} = $process->{'StoreOnlyQueryTenMore'};
	$risc->{$name}->{'1'}->{'storeonlyqueryuptoten'} = $process->{'StoreOnlyQueryUpToTen'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalcountofrecoverableitems'} = $process->{'TotalCountofRecoverableItems'};
	$risc->{$name}->{'1'}->{'totalqueries'} = $process->{'TotalQueries'};
	$risc->{$name}->{'1'}->{'totalsizeofrecoverableitems'} = $process->{'TotalSizeofRecoverableItems'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesscanned'} = $process->{'VirusScanBackgroundMessagesScanned'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesskipped'} = $process->{'VirusScanBackgroundMessagesSkipped'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundmessagesuptodate'} = $process->{'VirusScanBackgroundMessagesUpToDate'};
	$risc->{$name}->{'1'}->{'virusscanbackgroundscanningthreads'} = $process->{'VirusScanBackgroundScanningThreads'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsaccepted'} = $process->{'VirusScanExternalResultsAccepted'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsnotaccepted'} = $process->{'VirusScanExternalResultsNotAccepted'};
	$risc->{$name}->{'1'}->{'virusscanexternalresultsnotpresent'} = $process->{'VirusScanExternalResultsNotPresent'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'activeclientlogons'} = $process->{'ActiveClientLogons'};
	$risc->{$name}->{'2'}->{'averagedeliverytime'} = $process->{'AverageDeliveryTime'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'clientlogons'} = $process->{'ClientLogons'};
	$risc->{$name}->{'2'}->{'deliveryblockedlowdatabasespace'} = $process->{'DeliveryBlockedLowDatabaseSpace'};
	$risc->{$name}->{'2'}->{'deliveryblockedlowlogdiskspace'} = $process->{'DeliveryBlockedLowLogDiskSpace'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'eventhistorydeletes'} = $process->{'EventHistoryDeletes'};
	$risc->{$name}->{'2'}->{'eventhistorydeletespersec'} = $process->{'EventHistoryDeletesPersec'};
	$risc->{$name}->{'2'}->{'eventhistoryeventcachehitspercent'} = $process->{'EventHistoryEventCacheHitsPercent'};
	$risc->{$name}->{'2'}->{'eventhistoryeventcachehitspercent_base'} = $process->{'EventHistoryEventCacheHitsPercent_Base'};
	$risc->{$name}->{'2'}->{'eventhistoryeventscount'} = $process->{'EventHistoryEventsCount'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithemptycontainerclass'} = $process->{'EventHistoryEventsWithEmptyContainerClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithemptymessageclass'} = $process->{'EventHistoryEventsWithEmptyMessageClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithtruncatedcontainerclass'} = $process->{'EventHistoryEventsWithTruncatedContainerClass'};
	$risc->{$name}->{'2'}->{'eventhistoryeventswithtruncatedmessageclass'} = $process->{'EventHistoryEventsWithTruncatedMessageClass'};
	$risc->{$name}->{'2'}->{'eventhistoryreads'} = $process->{'EventHistoryReads'};
	$risc->{$name}->{'2'}->{'eventhistoryreadspersec'} = $process->{'EventHistoryReadsPersec'};
	$risc->{$name}->{'2'}->{'eventhistoryuncommittedtransactionscount'} = $process->{'EventHistoryUncommittedTransactionsCount'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkscount'} = $process->{'EventHistoryWatermarksCount'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksdeletes'} = $process->{'EventHistoryWatermarksDeletes'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksdeletespersec'} = $process->{'EventHistoryWatermarksDeletesPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksreads'} = $process->{'EventHistoryWatermarksReads'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarksreadspersec'} = $process->{'EventHistoryWatermarksReadsPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkswrites'} = $process->{'EventHistoryWatermarksWrites'};
	$risc->{$name}->{'2'}->{'eventhistorywatermarkswritespersec'} = $process->{'EventHistoryWatermarksWritesPersec'};
	$risc->{$name}->{'2'}->{'eventhistorywrites'} = $process->{'EventHistoryWrites'};
	$risc->{$name}->{'2'}->{'eventhistorywritespersec'} = $process->{'EventHistoryWritesPersec'};
	$risc->{$name}->{'2'}->{'folderopenspersec'} = $process->{'FolderopensPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'lastquerytime'} = $process->{'LastQueryTime'};
	$risc->{$name}->{'2'}->{'logonoperationspersec'} = $process->{'LogonOperationsPersec'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitrate'} = $process->{'MailboxLogonEntryCacheHitRate'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitratepercent'} = $process->{'MailboxLogonEntryCacheHitRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachehitratepercent_base'} = $process->{'MailboxLogonEntryCacheHitRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissrate'} = $process->{'MailboxLogonEntryCacheMissRate'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissratepercent'} = $process->{'MailboxLogonEntryCacheMissRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachemissratepercent_base'} = $process->{'MailboxLogonEntryCacheMissRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxlogonentrycachesize'} = $process->{'MailboxLogonEntryCacheSize'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitrate'} = $process->{'MailboxMetadataCacheHitRate'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitratepercent'} = $process->{'MailboxMetadataCacheHitRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachehitratepercent_base'} = $process->{'MailboxMetadataCacheHitRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissrate'} = $process->{'MailboxMetadataCacheMissRate'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissratepercent'} = $process->{'MailboxMetadataCacheMissRatePercent'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachemissratepercent_base'} = $process->{'MailboxMetadataCacheMissRatePercent_Base'};
	$risc->{$name}->{'2'}->{'mailboxmetadatacachesize'} = $process->{'MailboxMetadataCacheSize'};
	$risc->{$name}->{'2'}->{'messageopenspersec'} = $process->{'MessageOpensPersec'};
	$risc->{$name}->{'2'}->{'messagerecipientsdelivered'} = $process->{'MessageRecipientsDelivered'};
	$risc->{$name}->{'2'}->{'messagerecipientsdeliveredpersec'} = $process->{'MessageRecipientsDeliveredPersec'};
	$risc->{$name}->{'2'}->{'messagesdelivered'} = $process->{'MessagesDelivered'};
	$risc->{$name}->{'2'}->{'messagesdeliveredpersec'} = $process->{'MessagesDeliveredPersec'};
	$risc->{$name}->{'2'}->{'messagesqueuedforsubmission'} = $process->{'MessagesQueuedForSubmission'};
	$risc->{$name}->{'2'}->{'messagessent'} = $process->{'MessagesSent'};
	$risc->{$name}->{'2'}->{'messagessentpersec'} = $process->{'MessagesSentPersec'};
	$risc->{$name}->{'2'}->{'messagessubmitted'} = $process->{'MessagesSubmitted'};
	$risc->{$name}->{'2'}->{'messagessubmittedpersec'} = $process->{'MessagesSubmittedPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'numberofmessagesexpiredfrompublicfolders'} = $process->{'Numberofmessagesexpiredfrompublicfolders'};
	$risc->{$name}->{'2'}->{'peakclientlogons'} = $process->{'PeakClientLogons'};
	$risc->{$name}->{'2'}->{'replicationbackfilldatamessagesreceived'} = $process->{'ReplicationBackfillDataMessagesReceived'};
	$risc->{$name}->{'2'}->{'replicationbackfilldatamessagessent'} = $process->{'ReplicationBackfillDataMessagesSent'};
	$risc->{$name}->{'2'}->{'replicationbackfillrequestsreceived'} = $process->{'ReplicationBackfillRequestsReceived'};
	$risc->{$name}->{'2'}->{'replicationbackfillrequestssent'} = $process->{'ReplicationBackfillRequestsSent'};
	$risc->{$name}->{'2'}->{'replicationfolderchangesreceived'} = $process->{'ReplicationFolderChangesReceived'};
	$risc->{$name}->{'2'}->{'replicationfolderchangessent'} = $process->{'ReplicationFolderChangesSent'};
	$risc->{$name}->{'2'}->{'replicationfolderdatamessagesreceived'} = $process->{'ReplicationFolderDataMessagesReceived'};
	$risc->{$name}->{'2'}->{'replicationfolderdatamessagessent'} = $process->{'ReplicationFolderDataMessagesSent'};
	$risc->{$name}->{'2'}->{'replicationfoldertreemessagesreceived'} = $process->{'ReplicationFolderTreeMessagesReceived'};
	$risc->{$name}->{'2'}->{'replicationfoldertreemessagessent'} = $process->{'ReplicationFolderTreeMessagesSent'};
	$risc->{$name}->{'2'}->{'replicationmessagechangesreceived'} = $process->{'ReplicationMessageChangesReceived'};
	$risc->{$name}->{'2'}->{'replicationmessagechangessent'} = $process->{'ReplicationMessageChangesSent'};
	$risc->{$name}->{'2'}->{'replicationmessagesreceived'} = $process->{'ReplicationMessagesReceived'};
	$risc->{$name}->{'2'}->{'replicationmessagessent'} = $process->{'ReplicationMessagesSent'};
	$risc->{$name}->{'2'}->{'replicationreceivequeuesize'} = $process->{'ReplicationReceiveQueueSize'};
	$risc->{$name}->{'2'}->{'replicationstatusmessagesreceived'} = $process->{'ReplicationStatusMessagesReceived'};
	$risc->{$name}->{'2'}->{'replicationstatusmessagessent'} = $process->{'ReplicationStatusMessagesSent'};
	$risc->{$name}->{'2'}->{'replidcount'} = $process->{'ReplIDCount'};
	$risc->{$name}->{'2'}->{'restrictedviewcachehitrate'} = $process->{'RestrictedViewCacheHitRate'};
	$risc->{$name}->{'2'}->{'restrictedviewcachemissrate'} = $process->{'RestrictedViewCacheMissRate'};
	$risc->{$name}->{'2'}->{'rpcaveragelatency'} = $process->{'RPCAverageLatency'};
	$risc->{$name}->{'2'}->{'searchtaskrate'} = $process->{'SearchTaskRate'};
	$risc->{$name}->{'2'}->{'slowfindrowrate'} = $process->{'SlowFindRowRate'};
	$risc->{$name}->{'2'}->{'storeonlyqueries'} = $process->{'StoreOnlyQueries'};
	$risc->{$name}->{'2'}->{'storeonlyquerytenmore'} = $process->{'StoreOnlyQueryTenMore'};
	$risc->{$name}->{'2'}->{'storeonlyqueryuptoten'} = $process->{'StoreOnlyQueryUpToTen'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalcountofrecoverableitems'} = $process->{'TotalCountofRecoverableItems'};
	$risc->{$name}->{'2'}->{'totalqueries'} = $process->{'TotalQueries'};
	$risc->{$name}->{'2'}->{'totalsizeofrecoverableitems'} = $process->{'TotalSizeofRecoverableItems'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesscanned'} = $process->{'VirusScanBackgroundMessagesScanned'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesskipped'} = $process->{'VirusScanBackgroundMessagesSkipped'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundmessagesuptodate'} = $process->{'VirusScanBackgroundMessagesUpToDate'};
	$risc->{$name}->{'2'}->{'virusscanbackgroundscanningthreads'} = $process->{'VirusScanBackgroundScanningThreads'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsaccepted'} = $process->{'VirusScanExternalResultsAccepted'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsnotaccepted'} = $process->{'VirusScanExternalResultsNotAccepted'};
	$risc->{$name}->{'2'}->{'virusscanexternalresultsnotpresent'} = $process->{'VirusScanExternalResultsNotPresent'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;

	
	#---find ActiveClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$activeclientlogons = $risc->{$calname}->{'2'}->{'activeclientlogons'};
#	print "activeclientlogons: $activeclientlogons \n";


	#---find AverageDeliveryTime---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$averagedeliverytime = $risc->{$calname}->{'2'}->{'averagedeliverytime'};
#	print "averagedeliverytime: $averagedeliverytime \n";


	#---find ClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$clientlogons = $risc->{$calname}->{'2'}->{'clientlogons'};
#	print "clientlogons: $clientlogons \n";


	#---find DeliveryBlockedLowDatabaseSpace---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$deliveryblockedlowdatabasespace = $risc->{$calname}->{'2'}->{'deliveryblockedlowdatabasespace'};
#	print "deliveryblockedlowdatabasespace: $deliveryblockedlowdatabasespace \n";


	#---find DeliveryBlockedLowLogDiskSpace---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$deliveryblockedlowlogdiskspace = $risc->{$calname}->{'2'}->{'deliveryblockedlowlogdiskspace'};
#	print "deliveryblockedlowlogdiskspace: $deliveryblockedlowlogdiskspace \n";


	#---find EventHistoryDeletes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorydeletes = $risc->{$calname}->{'2'}->{'eventhistorydeletes'};
#	print "eventhistorydeletes: $eventhistorydeletes \n";


	#---find EventHistoryDeletesPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'eventhistorydeletespersec'};	
#	print "EventHistoryDeletesPersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'eventhistorydeletespersec'};	
#	print "EventHistoryDeletesPersec2: $val2 \n";	
	eval 	
	{	
	$eventhistorydeletespersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "EventHistoryDeletesPersec: $eventhistorydeletespersec \n";	

	
	#---find EventHistoryEventCacheHitsPercent---#	
	my $eventhistoryeventcachehitspercent1 = $risc->{$calname}->{'1'}->{'eventhistoryeventcachehitspercent'};	
#	print "eventhistoryeventcachehitspercent1: $eventhistoryeventcachehitspercent1 \n";	
	my $eventhistoryeventcachehitspercent2 = $risc->{$calname}->{'2'}->{'eventhistoryeventcachehitspercent'};	
#	print "eventhistoryeventcachehitspercent2: $eventhistoryeventcachehitspercent2 \n";	
	my $eventhistoryeventcachehitspercent_base1 = $risc->{$calname}->{'1'}->{'eventhistoryeventcachehitspercent_base'};	
#	print "eventhistoryeventcachehitspercent_base1: $eventhistoryeventcachehitspercent_base1\n";	
	my $eventhistoryeventcachehitspercent_base2 = $risc->{$calname}->{'2'}->{'eventhistoryeventcachehitspercent_base'};	
#	print "eventhistoryeventcachehitspercent_base2: $eventhistoryeventcachehitspercent_base2\n";	
	eval 	
	{	
	$eventhistoryeventcachehitspercent = PERF_AVERAGE_BULK(	
		$eventhistoryeventcachehitspercent1 #counter value 1
		,$eventhistoryeventcachehitspercent2 #counter value 2
		,$eventhistoryeventcachehitspercent_base1 #base counter value 1
		,$eventhistoryeventcachehitspercent_base2); #base counter value 2
	};	
#	print "eventhistoryeventcachehitspercent: $eventhistoryeventcachehitspercent \n";	


	#---find EventHistoryEventsCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventscount = $risc->{$calname}->{'2'}->{'eventhistoryeventscount'};
#	print "eventhistoryeventscount: $eventhistoryeventscount \n";


	#---find EventHistoryEventsWithEmptyContainerClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithemptycontainerclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithemptycontainerclass'};
#	print "eventhistoryeventswithemptycontainerclass: $eventhistoryeventswithemptycontainerclass \n";


	#---find EventHistoryEventsWithEmptyMessageClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithemptymessageclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithemptymessageclass'};
#	print "eventhistoryeventswithemptymessageclass: $eventhistoryeventswithemptymessageclass \n";


	#---find EventHistoryEventsWithTruncatedContainerClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithtruncatedcontainerclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithtruncatedcontainerclass'};
#	print "eventhistoryeventswithtruncatedcontainerclass: $eventhistoryeventswithtruncatedcontainerclass \n";


	#---find EventHistoryEventsWithTruncatedMessageClass---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryeventswithtruncatedmessageclass = $risc->{$calname}->{'2'}->{'eventhistoryeventswithtruncatedmessageclass'};
#	print "eventhistoryeventswithtruncatedmessageclass: $eventhistoryeventswithtruncatedmessageclass \n";


	#---find EventHistoryReads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryreads = $risc->{$calname}->{'2'}->{'eventhistoryreads'};
#	print "eventhistoryreads: $eventhistoryreads \n";


	#---find EventHistoryReadsPersec---#	
	my $eventhistoryreadspersec1 = $risc->{$calname}->{'1'}->{'eventhistoryreadspersec'};	
#	print "eventhistoryreadspersec1: $eventhistoryreadspersec1 \n";	
	my $eventhistoryreadspersec2 = $risc->{$calname}->{'2'}->{'eventhistoryreadspersec'};	
#	print "eventhistoryreadspersec2: $eventhistoryreadspersec2 \n";	
	eval 	
	{	
	$eventhistoryreadspersec = PERF_COUNTER_BULK_COUNT(	
		$eventhistoryreadspersec1 #c1
		,$eventhistoryreadspersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "eventhistoryreadspersec: $eventhistoryreadspersec \n";	


	#---find EventHistoryUncommittedTransactionsCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistoryuncommittedtransactionscount = $risc->{$calname}->{'2'}->{'eventhistoryuncommittedtransactionscount'};
#	print "eventhistoryuncommittedtransactionscount: $eventhistoryuncommittedtransactionscount \n";


	#---find EventHistoryWatermarksCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarkscount = $risc->{$calname}->{'2'}->{'eventhistorywatermarkscount'};
#	print "eventhistorywatermarkscount: $eventhistorywatermarkscount \n";


	#---find EventHistoryWatermarksDeletes---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarksdeletes = $risc->{$calname}->{'2'}->{'eventhistorywatermarksdeletes'};
#	print "eventhistorywatermarksdeletes: $eventhistorywatermarksdeletes \n";


	#---find EventHistoryWatermarksDeletesPersec---#	
	my $eventhistorywatermarksdeletespersec1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarksdeletespersec'};	
#	print "eventhistorywatermarksdeletespersec1: $eventhistorywatermarksdeletespersec1 \n";	
	my $eventhistorywatermarksdeletespersec2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarksdeletespersec'};	
#	print "eventhistorywatermarksdeletespersec2: $eventhistorywatermarksdeletespersec2 \n";	
	eval 	
	{	
	$eventhistorywatermarksdeletespersec = PERF_COUNTER_BULK_COUNT(	
		$eventhistorywatermarksdeletespersec1 #c1
		,$eventhistorywatermarksdeletespersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "eventhistorywatermarksdeletespersec: $eventhistorywatermarksdeletespersec \n";	


	#---find EventHistoryWatermarksReads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarksreads = $risc->{$calname}->{'2'}->{'eventhistorywatermarksreads'};
#	print "eventhistorywatermarksreads: $eventhistorywatermarksreads \n";


	#---find EventHistoryWatermarksReadsPersec---#	
	my $eventhistorywatermarksreadspersec1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarksreadspersec'};	
#	print "eventhistorywatermarksreadspersec1: $eventhistorywatermarksreadspersec1 \n";	
	my $eventhistorywatermarksreadspersec2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarksreadspersec'};	
#	print "eventhistorywatermarksreadspersec2: $eventhistorywatermarksreadspersec2 \n";	
	eval 	
	{	
	$eventhistorywatermarksreadspersec = PERF_COUNTER_BULK_COUNT(	
		$eventhistorywatermarksreadspersec1 #c1
		,$eventhistorywatermarksreadspersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "eventhistorywatermarksreadspersec: $eventhistorywatermarksreadspersec \n";	


	#---find EventHistoryWatermarksWrites---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywatermarkswrites = $risc->{$calname}->{'2'}->{'eventhistorywatermarkswrites'};
#	print "eventhistorywatermarkswrites: $eventhistorywatermarkswrites \n";


	#---find EventHistoryWatermarksWritesPersec---#	
	my $eventhistorywatermarkswritespersec1 = $risc->{$calname}->{'1'}->{'eventhistorywatermarkswritespersec'};	
#	print "eventhistorywatermarkswritespersec1: $eventhistorywatermarkswritespersec1 \n";	
	my $eventhistorywatermarkswritespersec2 = $risc->{$calname}->{'2'}->{'eventhistorywatermarkswritespersec'};	
#	print "eventhistorywatermarkswritespersec2: $eventhistorywatermarkswritespersec2 \n";	
	eval 	
	{	
	$eventhistorywatermarkswritespersec = PERF_COUNTER_BULK_COUNT(	
		$eventhistorywatermarkswritespersec1 #c1
		,$eventhistorywatermarkswritespersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "eventhistorywatermarkswritespersec: $eventhistorywatermarkswritespersec \n";	


	#---find EventHistoryWrites---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$eventhistorywrites = $risc->{$calname}->{'2'}->{'eventhistorywrites'};
#	print "eventhistorywrites: $eventhistorywrites \n";


	#---find EventHistoryWritesPersec---#	
	my $eventhistorywritespersec1 = $risc->{$calname}->{'1'}->{'eventhistorywritespersec'};	
#	print "eventhistorywritespersec1: $eventhistorywritespersec1 \n";	
	my $eventhistorywritespersec2 = $risc->{$calname}->{'2'}->{'eventhistorywritespersec'};	
#	print "eventhistorywritespersec2: $eventhistorywritespersec2 \n";	
	eval 	
	{	
	$eventhistorywritespersec = PERF_COUNTER_BULK_COUNT(	
		$eventhistorywritespersec1 #c1
		,$eventhistorywritespersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "eventhistorywritespersec: $eventhistorywritespersec \n";	


	#---find FolderopensPersec---#	
	my $folderopenspersec1 = $risc->{$calname}->{'1'}->{'folderopenspersec'};	
#	print "folderopenspersec1: $folderopenspersec1 \n";	
	my $folderopenspersec2 = $risc->{$calname}->{'2'}->{'folderopenspersec'};	
#	print "folderopenspersec2: $folderopenspersec2 \n";	
	eval 	
	{	
	$folderopenspersec = PERF_COUNTER_BULK_COUNT(	
		$folderopenspersec1 #c1
		,$folderopenspersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "folderopenspersec: $folderopenspersec \n";	


	#---find LastQueryTime---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$lastquerytime = $risc->{$calname}->{'2'}->{'lastquerytime'};
#	print "lastquerytime: $lastquerytime \n";


	#---find LogonOperationsPersec---#	
	my $logonoperationspersec1 = $risc->{$calname}->{'1'}->{'logonoperationspersec'};	
#	print "logonoperationspersec1: $logonoperationspersec1 \n";	
	my $logonoperationspersec2 = $risc->{$calname}->{'2'}->{'logonoperationspersec'};	
#	print "logonoperationspersec2: $logonoperationspersec2 \n";	
	eval 	
	{	
	$logonoperationspersec = PERF_COUNTER_BULK_COUNT(	
		$logonoperationspersec1 #c1
		,$logonoperationspersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "logonoperationspersec: $logonoperationspersec \n";	


	#---find MailboxLogonEntryCacheHitRate---#	
	my $mailboxlogonentrycachehitrate1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitrate'};	
#	print "mailboxlogonentrycachehitrate1: $mailboxlogonentrycachehitrate1 \n";	
	my $mailboxlogonentrycachehitrate2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitrate'};	
#	print "mailboxlogonentrycachehitrate2: $mailboxlogonentrycachehitrate2 \n";	
	eval 	
	{	
	$mailboxlogonentrycachehitrate = PERF_COUNTER_BULK_COUNT(	
		$mailboxlogonentrycachehitrate1 #c1
		,$mailboxlogonentrycachehitrate2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "mailboxlogonentrycachehitrate: $mailboxlogonentrycachehitrate \n";	


	#---find MailboxLogonEntryCacheHitRatePercent---#	
	my $mailboxlogonentrycachehitratepercent1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitratepercent'};	
#	print "mailboxlogonentrycachehitratepercent1: $mailboxlogonentrycachehitratepercent1 \n";	
	my $mailboxlogonentrycachehitratepercent2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitratepercent'};	
#	print "mailboxlogonentrycachehitratepercent2: $mailboxlogonentrycachehitratepercent2 \n";	
	my $mailboxlogonentrycachehitratepercent_base1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachehitratepercent_base'};	
#	print "mailboxlogonentrycachehitratepercent_base1: $mailboxlogonentrycachehitratepercent_base1\n";	
	my $mailboxlogonentrycachehitratepercent_base2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachehitratepercent_base'};	
#	print "mailboxlogonentrycachehitratepercent_base2: $mailboxlogonentrycachehitratepercent_base2\n";	
	eval 	
	{	
	$mailboxlogonentrycachehitratepercent = PERF_AVERAGE_BULK(	
		$mailboxlogonentrycachehitratepercent1 #counter value 1
		,$mailboxlogonentrycachehitratepercent2 #counter value 2
		,$mailboxlogonentrycachehitratepercent_base1 #base counter value 1
		,$mailboxlogonentrycachehitratepercent_base2); #base counter value 2
	};	
#	print "mailboxlogonentrycachehitratepercent: $mailboxlogonentrycachehitratepercent \n";	


	#---find MailboxLogonEntryCacheMissRate---#	
	my $mailboxlogonentrycachemissrate1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissrate'};	
#	print "mailboxlogonentrycachemissrate1: $mailboxlogonentrycachemissrate1 \n";	
	my $mailboxlogonentrycachemissrate2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissrate'};	
#	print "mailboxlogonentrycachemissrate2: $mailboxlogonentrycachemissrate2 \n";	
	eval 	
	{	
	$mailboxlogonentrycachemissrate = PERF_COUNTER_BULK_COUNT(	
		$mailboxlogonentrycachemissrate1 #c1
		,$mailboxlogonentrycachemissrate2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "mailboxlogonentrycachemissrate: $mailboxlogonentrycachemissrate \n";	


	#---find MailboxLogonEntryCacheMissRatePercent---#	
	my $mailboxlogonentrycachemissratepercent1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissratepercent'};	
#	print "mailboxlogonentrycachemissratepercent1: $mailboxlogonentrycachemissratepercent1 \n";	
	my $mailboxlogonentrycachemissratepercent2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissratepercent'};	
#	print "mailboxlogonentrycachemissratepercent2: $mailboxlogonentrycachemissratepercent2 \n";	
	my $mailboxlogonentrycachemissratepercent_base1 = $risc->{$calname}->{'1'}->{'mailboxlogonentrycachemissratepercent_base'};	
#	print "mailboxlogonentrycachemissratepercent_base1: $mailboxlogonentrycachemissratepercent_base1\n";	
	my $mailboxlogonentrycachemissratepercent_base2 = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachemissratepercent_base'};	
#	print "mailboxlogonentrycachemissratepercent_base2: $mailboxlogonentrycachemissratepercent_base2\n";	
	eval 	
	{	
	$mailboxlogonentrycachemissratepercent = PERF_AVERAGE_BULK(	
		$mailboxlogonentrycachemissratepercent1 #counter value 1
		,$mailboxlogonentrycachemissratepercent2 #counter value 2
		,$mailboxlogonentrycachemissratepercent_base1 #base counter value 1
		,$mailboxlogonentrycachemissratepercent_base2); #base counter value 2
	};	
#	print "mailboxlogonentrycachemissratepercent: $mailboxlogonentrycachemissratepercent \n";	


	#---find MailboxLogonEntryCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxlogonentrycachesize = $risc->{$calname}->{'2'}->{'mailboxlogonentrycachesize'};
#	print "mailboxlogonentrycachesize: $mailboxlogonentrycachesize \n";


	#---find MailboxMetadataCacheHitRate---#	
	my $mailboxmetadatacachehitrate1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitrate'};	
#	print "mailboxmetadatacachehitrate1: $mailboxmetadatacachehitrate1 \n";	
	my $mailboxmetadatacachehitrate2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitrate'};	
#	print "mailboxmetadatacachehitrate2: $mailboxmetadatacachehitrate2 \n";	
	eval 	
	{	
	$mailboxmetadatacachehitrate = PERF_COUNTER_BULK_COUNT(	
		$mailboxmetadatacachehitrate1 #c1
		,$mailboxmetadatacachehitrate2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "mailboxmetadatacachehitrate: $mailboxmetadatacachehitrate \n";	


	#---find MailboxMetadataCacheHitRatePercent---#	
	my $mailboxmetadatacachehitratepercent1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitratepercent'};	
#	print "mailboxmetadatacachehitratepercent1: $mailboxmetadatacachehitratepercent1 \n";	
	my $mailboxmetadatacachehitratepercent2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitratepercent'};	
#	print "mailboxmetadatacachehitratepercent2: $mailboxmetadatacachehitratepercent2 \n";	
	my $mailboxmetadatacachehitratepercent_base1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachehitratepercent_base'};	
#	print "mailboxmetadatacachehitratepercent_base1: $mailboxmetadatacachehitratepercent_base1\n";	
	my $mailboxmetadatacachehitratepercent_base2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachehitratepercent_base'};	
#	print "mailboxmetadatacachehitratepercent_base2: $mailboxmetadatacachehitratepercent_base2\n";	
	eval 	
	{	
	$mailboxmetadatacachehitratepercent = PERF_AVERAGE_BULK(	
		$mailboxmetadatacachehitratepercent1 #counter value 1
		,$mailboxmetadatacachehitratepercent2 #counter value 2
		,$mailboxmetadatacachehitratepercent_base1 #base counter value 1
		,$mailboxmetadatacachehitratepercent_base2); #base counter value 2
	};	
#	print "mailboxmetadatacachehitratepercent: $mailboxmetadatacachehitratepercent \n";	


	#---find MailboxMetadataCacheMissRate---#	
	my $mailboxmetadatacachemissrate1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissrate'};	
#	print "mailboxmetadatacachemissrate1: $mailboxmetadatacachemissrate1 \n";	
	my $mailboxmetadatacachemissrate2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissrate'};	
#	print "mailboxmetadatacachemissrate2: $mailboxmetadatacachemissrate2 \n";	
	eval 	
	{	
	$mailboxmetadatacachemissrate = PERF_COUNTER_BULK_COUNT(	
		$mailboxmetadatacachemissrate1 #c1
		,$mailboxmetadatacachemissrate2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "mailboxmetadatacachemissrate: $mailboxmetadatacachemissrate \n";	


	#---find MailboxMetadataCacheMissRatePercent---#	
	my $mailboxmetadatacachemissratepercent1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissratepercent'};	
#	print "mailboxmetadatacachemissratepercent1: $mailboxmetadatacachemissratepercent1 \n";	
	my $mailboxmetadatacachemissratepercent2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissratepercent'};	
#	print "mailboxmetadatacachemissratepercent2: $mailboxmetadatacachemissratepercent2 \n";	
	my $mailboxmetadatacachemissratepercent_base1 = $risc->{$calname}->{'1'}->{'mailboxmetadatacachemissratepercent_base'};	
#	print "mailboxmetadatacachemissratepercent_base1: $mailboxmetadatacachemissratepercent_base1\n";	
	my $mailboxmetadatacachemissratepercent_base2 = $risc->{$calname}->{'2'}->{'mailboxmetadatacachemissratepercent_base'};	
#	print "mailboxmetadatacachemissratepercent_base2: $mailboxmetadatacachemissratepercent_base2\n";	
	eval 	
	{	
	$mailboxmetadatacachemissratepercent = PERF_AVERAGE_BULK(	
		$mailboxmetadatacachemissratepercent1 #counter value 1
		,$mailboxmetadatacachemissratepercent2 #counter value 2
		,$mailboxmetadatacachemissratepercent_base1 #base counter value 1
		,$mailboxmetadatacachemissratepercent_base2); #base counter value 2
	};	
#	print "mailboxmetadatacachemissratepercent: $mailboxmetadatacachemissratepercent \n";	


	#---find MailboxMetadataCacheSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$mailboxmetadatacachesize = $risc->{$calname}->{'2'}->{'mailboxmetadatacachesize'};
#	print "mailboxmetadatacachesize: $mailboxmetadatacachesize \n";


	#---find MessageOpensPersec---#	
	my $messageopenspersec1 = $risc->{$calname}->{'1'}->{'messageopenspersec'};	
#	print "messageopenspersec1: $messageopenspersec1 \n";	
	my $messageopenspersec2 = $risc->{$calname}->{'2'}->{'messageopenspersec'};	
#	print "messageopenspersec2: $messageopenspersec2 \n";	
	eval 	
	{	
	$messageopenspersec = PERF_COUNTER_BULK_COUNT(	
		$messageopenspersec1 #c1
		,$messageopenspersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "messageopenspersec: $messageopenspersec \n";	


	#---find MessageRecipientsDelivered---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagerecipientsdelivered = $risc->{$calname}->{'2'}->{'messagerecipientsdelivered'};
#	print "messagerecipientsdelivered: $messagerecipientsdelivered \n";


	#---find MessageRecipientsDeliveredPersec---#	
	my $messagerecipientsdeliveredpersec1 = $risc->{$calname}->{'1'}->{'messagerecipientsdeliveredpersec'};	
#	print "messagerecipientsdeliveredpersec1: $messagerecipientsdeliveredpersec1 \n";	
	my $messagerecipientsdeliveredpersec2 = $risc->{$calname}->{'2'}->{'messagerecipientsdeliveredpersec'};	
#	print "messagerecipientsdeliveredpersec2: $messagerecipientsdeliveredpersec2 \n";	
	eval 	
	{	
	$messagerecipientsdeliveredpersec = PERF_COUNTER_BULK_COUNT(	
		$messagerecipientsdeliveredpersec1 #c1
		,$messagerecipientsdeliveredpersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "messagerecipientsdeliveredpersec: $messagerecipientsdeliveredpersec \n";	


	#---find MessagesDelivered---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagesdelivered = $risc->{$calname}->{'2'}->{'messagesdelivered'};
#	print "messagesdelivered: $messagesdelivered \n";


	#---find MessagesDeliveredPersec---#	
	my $messagesdeliveredpersec1 = $risc->{$calname}->{'1'}->{'messagesdeliveredpersec'};	
#	print "messagesdeliveredpersec1: $messagesdeliveredpersec1 \n";	
	my $messagesdeliveredpersec2 = $risc->{$calname}->{'2'}->{'messagesdeliveredpersec'};	
#	print "messagesdeliveredpersec2: $messagesdeliveredpersec2 \n";	
	eval 	
	{	
	$messagesdeliveredpersec = PERF_COUNTER_BULK_COUNT(	
		$messagesdeliveredpersec1 #c1
		,$messagesdeliveredpersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "messagesdeliveredpersec: $messagesdeliveredpersec \n";	


	#---find MessagesQueuedForSubmission---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagesqueuedforsubmission = $risc->{$calname}->{'2'}->{'messagesqueuedforsubmission'};
#	print "messagesqueuedforsubmission: $messagesqueuedforsubmission \n";


	#---find MessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagessent = $risc->{$calname}->{'2'}->{'messagessent'};
#	print "messagessent: $messagessent \n";


	#---find MessagesSentPersec---#	
	my $messagessentpersec1 = $risc->{$calname}->{'1'}->{'messagessentpersec'};	
#	print "messagessentpersec1: $messagessentpersec1 \n";	
	my $messagessentpersec2 = $risc->{$calname}->{'2'}->{'messagessentpersec'};	
#	print "messagessentpersec2: $messagessentpersec2 \n";	
	eval 	
	{	
	$messagessentpersec = PERF_COUNTER_BULK_COUNT(	
		$messagessentpersec1 #c1
		,$messagessentpersec2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "messagessentpersec: $messagessentpersec \n";	


	#---find MessagesSubmitted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$messagessubmitted = $risc->{$calname}->{'2'}->{'messagessubmitted'};
#	print "messagessubmitted: $messagessubmitted \n";


	#---find MessagesSubmittedPersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'messagessubmittedpersec'};	
#	print "messagessubmittedpersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'messagessubmittedpersec'};	
#	print "messagessubmittedpersec2: $val2 \n";	
	eval 	
	{	
	$messagessubmittedpersec = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "messagessubmittedpersec: $messagessubmittedpersec \n";	
	

	#---find Numberofmessagesexpiredfrompublicfolders---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$numberofmessagesexpiredfrompublicfolders = $risc->{$calname}->{'2'}->{'numberofmessagesexpiredfrompublicfolders'};
#	print "numberofmessagesexpiredfrompublicfolders: $numberofmessagesexpiredfrompublicfolders \n";


	#---find PeakClientLogons---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$peakclientlogons = $risc->{$calname}->{'2'}->{'peakclientlogons'};
#	print "peakclientlogons: $peakclientlogons \n";


	#---find ReplicationBackfillDataMessagesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationbackfilldatamessagesreceived = $risc->{$calname}->{'2'}->{'replicationbackfilldatamessagesreceived'};
#	print "replicationbackfilldatamessagesreceived: $replicationbackfilldatamessagesreceived \n";


	#---find ReplicationBackfillDataMessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationbackfilldatamessagessent = $risc->{$calname}->{'2'}->{'replicationbackfilldatamessagessent'};
#	print "replicationbackfilldatamessagessent: $replicationbackfilldatamessagessent \n";


	#---find ReplicationBackfillRequestsReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationbackfillrequestsreceived = $risc->{$calname}->{'2'}->{'replicationbackfillrequestsreceived'};
#	print "replicationbackfillrequestsreceived: $replicationbackfillrequestsreceived \n";


	#---find ReplicationBackfillRequestsSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationbackfillrequestssent = $risc->{$calname}->{'2'}->{'replicationbackfillrequestssent'};
#	print "replicationbackfillrequestssent: $replicationbackfillrequestssent \n";

	#---find ReplicationFolderChangesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfolderchangesreceived = $risc->{$calname}->{'2'}->{'replicationfolderchangesreceived'};
#	print "replicationfolderchangesreceived: $replicationfolderchangesreceived \n";


	#---find ReplicationFolderChangesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfolderchangessent = $risc->{$calname}->{'2'}->{'replicationfolderchangessent'};
#	print "ReplicationFolderChangesSent: $replicationfolderchangessent \n";


	#---find ReplicationFolderDataMessagesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfolderdatamessagesreceived = $risc->{$calname}->{'2'}->{'replicationfolderdatamessagesreceived'};
#	print "ReplicationFolderDataMessagesReceived: $replicationfolderdatamessagesreceived \n\n";


	#---find ReplicationFolderDataMessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfolderdatamessagessent = $risc->{$calname}->{'2'}->{'replicationfolderdatamessagessent'};
#	print "ReplicationFolderDataMessagesSent: $replicationfolderdatamessagessent \n\n";


	#---find ReplicationFolderTreeMessagesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfoldertreemessagesreceived = $risc->{$calname}->{'2'}->{'replicationfoldertreemessagesreceived'};
#	print "ReplicationFolderTreeMessagesReceived: $replicationfoldertreemessagesreceived \n\n";


	#---find ReplicationFolderTreeMessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationfoldertreemessagessent = $risc->{$calname}->{'2'}->{'replicationfoldertreemessagessent'};
#	print "ReplicationFolderTreeMessagesSent: $replicationfoldertreemessagessent \n\n";


	#---find ReplicationMessageChangesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationmessagechangesreceived = $risc->{$calname}->{'2'}->{'replicationmessagechangesreceived'};
#	print "ReplicationMessageChangesReceived: $replicationmessagechangesreceived \n\n";


	#---find ReplicationMessageChangesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationmessagechangessent = $risc->{$calname}->{'2'}->{'replicationmessagechangessent'};
#	print "ReplicationMessageChangesSent: $replicationmessagechangessent \n\n";


	#---find ReplicationMessagesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationmessagesreceived = $risc->{$calname}->{'2'}->{'replicationmessagesreceived'};
#	print "ReplicationMessagesReceived: $replicationmessagesreceived \n\n";


	#---find ReplicationMessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationmessagessent = $risc->{$calname}->{'2'}->{'replicationmessagessent'};
#	print "ReplicationMessagesSent: $replicationmessagessent \n\n";


	#---find ReplicationReceiveQueueSize---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationreceivequeuesize = $risc->{$calname}->{'2'}->{'replicationreceivequeuesize'};
#	print "ReplicationReceiveQueueSize: $replicationreceivequeuesize \n\n";


	#---find ReplicationStatusMessagesReceived---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationstatusmessagesreceived = $risc->{$calname}->{'2'}->{'replicationstatusmessagesreceived'};
#	print "ReplicationStatusMessagesReceived: $replicationstatusmessagesreceived \n\n";


	#---find ReplicationStatusMessagesSent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replicationstatusmessagessent = $risc->{$calname}->{'2'}->{'replicationstatusmessagessent'};
#	print "ReplicationStatusMessagesSent: $replicationstatusmessagessent \n\n";


	#---find ReplIDCount---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$replidcount = $risc->{$calname}->{'2'}->{'replidcount'};
#	print "ReplIDCount: $replidcount \n\n";


	#---find RestrictedViewCacheHitRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'restrictedviewcachehitrate'};	
#	print "RestrictedViewCacheHitRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'restrictedviewcachehitrate'};	
#	print "RestrictedViewCacheHitRate2: $val2 \n";	
	eval 	
	{	
	$restrictedviewcachehitrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RestrictedViewCacheHitRate: $restrictedviewcachehitrate \n\n";	


	#---find RestrictedViewCacheMissRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'restrictedviewcachemissrate'};	
#	print "RestrictedViewCacheMissRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'restrictedviewcachemissrate'};	
#	print "RestrictedViewCacheMissRate2: $val2 \n";	
	eval 	
	{	
	$restrictedviewcachemissrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "RestrictedViewCacheMissRate: $restrictedviewcachemissrate \n\n";	


	#---find RPCAverageLatency---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcaveragelatency = $risc->{$calname}->{'2'}->{'rpcaveragelatency'};
#	print "RPCAverageLatency: $rpcaveragelatency \n\n";


	#---find SearchTaskRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'searchtaskrate'};	
#	print "SearchTaskRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'searchtaskrate'};	
#	print "SearchTaskRate2: $val2 \n";	
	eval 	
	{	
	$searchtaskrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SearchTaskRate: $searchtaskrate \n\n";	


	#---find SlowFindRowRate---#	
	$val1 = $risc->{$calname}->{'1'}->{'slowfindrowrate'};	
#	print "SlowFindRowRate1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'slowfindrowrate'};	
#	print "SlowFindRowRate2: $val2 \n";	
	eval 	
	{	
	$slowfindrowrate = PERF_COUNTER_BULK_COUNT(	
		$val1 #c1
		,$val2 #c2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2 #Perftime2
		,$frequency_perftime2); #PerfFreg2
	};	
#	print "SlowFindRowRate: $slowfindrowrate \n\n";	


	#---find StoreOnlyQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyqueries = $risc->{$calname}->{'2'}->{'storeonlyqueries'};
#	print "StoreOnlyQueries: $storeonlyqueries \n\n";


	#---find StoreOnlyQueryTenMore---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyquerytenmore = $risc->{$calname}->{'2'}->{'storeonlyquerytenmore'};
#	print "StoreOnlyQueryTenMore: $storeonlyquerytenmore \n\n";


	#---find StoreOnlyQueryUpToTen---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$storeonlyqueryuptoten = $risc->{$calname}->{'2'}->{'storeonlyqueryuptoten'};
#	print "StoreOnlyQueryUpToTen: $storeonlyqueryuptoten \n\n";


	#---find TotalCountofRecoverableItems---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalcountofrecoverableitems = $risc->{$calname}->{'2'}->{'totalcountofrecoverableitems'};
#	print "TotalCountofRecoverableItems: $totalcountofrecoverableitems \n\n";


	#---find TotalQueries---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalqueries = $risc->{$calname}->{'2'}->{'totalqueries'};
#	print "TotalQueries: $totalqueries \n\n";


	#---find TotalSizeofRecoverableItems---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$totalsizeofrecoverableitems = $risc->{$calname}->{'2'}->{'totalsizeofrecoverableitems'};
#	print "TotalSizeofRecoverableItems: $totalsizeofrecoverableitems \n\n";


	#---find VirusScanBackgroundMessagesScanned---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesscanned = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesscanned'};
#	print "VirusScanBackgroundMessagesScanned: $virusscanbackgroundmessagesscanned \n\n";


	#---find VirusScanBackgroundMessagesSkipped---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesskipped = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesskipped'};
#	print "VirusScanBackgroundMessagesSkipped: $virusscanbackgroundmessagesskipped \n\n";


	#---find VirusScanBackgroundMessagesUpToDate---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundmessagesuptodate = $risc->{$calname}->{'2'}->{'virusscanbackgroundmessagesuptodate'};
#	print "VirusScanBackgroundMessagesUpToDate: $virusscanbackgroundmessagesuptodate \n\n";


	#---find VirusScanBackgroundScanningThreads---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanbackgroundscanningthreads = $risc->{$calname}->{'2'}->{'virusscanbackgroundscanningthreads'};
#	print "VirusScanBackgroundScanningThreads: $virusscanbackgroundscanningthreads \n\n";


	#---find VirusScanExternalResultsAccepted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsaccepted = $risc->{$calname}->{'2'}->{'virusscanexternalresultsaccepted'};
#	print "VirusScanExternalResultsAccepted: $virusscanexternalresultsaccepted \n\n";


	#---find VirusScanExternalResultsNotAccepted---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsnotaccepted = $risc->{$calname}->{'2'}->{'virusscanexternalresultsnotaccepted'};
#	print "VirusScanExternalResultsNotAccepted: $virusscanexternalresultsnotaccepted \n\n";


	#---find VirusScanExternalResultsNotPresent---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$virusscanexternalresultsnotpresent = $risc->{$calname}->{'2'}->{'virusscanexternalresultsnotpresent'};
#	print "VirusScanExternalResultsNotPresent: $virusscanexternalresultsnotpresent \n\n";


##############################################################
					
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$activeclientlogons
	,$averagedeliverytime
	,$caption
	,$clientlogons
	,$deliveryblockedlowdatabasespace
	,$deliveryblockedlowlogdiskspace
	,$description
	,$eventhistorydeletes
	,$eventhistorydeletespersec
	,$eventhistoryeventcachehitspercent
	,$eventhistoryeventscount
	,$eventhistoryeventswithemptycontainerclass
	,$eventhistoryeventswithemptymessageclass
	,$eventhistoryeventswithtruncatedcontainerclass
	,$eventhistoryeventswithtruncatedmessageclass
	,$eventhistoryreads
	,$eventhistoryreadspersec
	,$eventhistoryuncommittedtransactionscount
	,$eventhistorywatermarkscount
	,$eventhistorywatermarksdeletes
	,$eventhistorywatermarksdeletespersec
	,$eventhistorywatermarksreads
	,$eventhistorywatermarksreadspersec
	,$eventhistorywatermarkswrites
	,$eventhistorywatermarkswritespersec
	,$eventhistorywrites
	,$eventhistorywritespersec
	,$folderopenspersec
	,$lastquerytime
	,$logonoperationspersec
	,$mailboxlogonentrycachehitrate
	,$mailboxlogonentrycachehitratepercent
	,$mailboxlogonentrycachemissrate
	,$mailboxlogonentrycachemissratepercent
	,$mailboxlogonentrycachesize
	,$mailboxmetadatacachehitrate
	,$mailboxmetadatacachehitratepercent
	,$mailboxmetadatacachemissrate
	,$mailboxmetadatacachemissratepercent
	,$mailboxmetadatacachesize
	,$messageopenspersec
	,$messagerecipientsdelivered
	,$messagerecipientsdeliveredpersec
	,$messagesdelivered
	,$messagesdeliveredpersec
	,$messagesqueuedforsubmission
	,$messagessent
	,$messagessentpersec
	,$messagessubmitted
	,$messagessubmittedpersec
	,$tablename
	,$numberofmessagesexpiredfrompublicfolders
	,$peakclientlogons
	,$replicationbackfilldatamessagesreceived
	,$replicationbackfilldatamessagessent
	,$replicationbackfillrequestsreceived
	,$replicationbackfillrequestssent
	,$replicationfolderchangesreceived
	,$replicationfolderchangessent
	,$replicationfolderdatamessagesreceived
	,$replicationfolderdatamessagessent
	,$replicationfoldertreemessagesreceived
	,$replicationfoldertreemessagessent
	,$replicationmessagechangesreceived
	,$replicationmessagechangessent
	,$replicationmessagesreceived
	,$replicationmessagessent
	,$replicationreceivequeuesize
	,$replicationstatusmessagesreceived
	,$replicationstatusmessagessent
	,$replidcount
	,$restrictedviewcachehitrate
	,$restrictedviewcachemissrate
	,$rpcaveragelatency
	,$searchtaskrate
	,$slowfindrowrate
	,$storeonlyqueries
	,$storeonlyquerytenmore
	,$storeonlyqueryuptoten
	,$totalcountofrecoverableitems
	,$totalqueries
	,$totalsizeofrecoverableitems
	,$virusscanbackgroundmessagesscanned
	,$virusscanbackgroundmessagesskipped
	,$virusscanbackgroundmessagesuptodate
	,$virusscanbackgroundscanningthreads
	,$virusscanexternalresultsaccepted
	,$virusscanexternalresultsnotaccepted
	,$virusscanexternalresultsnotpresent
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeMailSubmission
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchmailsub (
	deviceid
	,scantime
	,aggregateshadowqueuelength
	,caption
	,description
	,failedsubmissions
	,failedsubmissionspersecond
	,hubservers
	,hubserversinretry
	,hubtransportserverspercentactive
	,name
	,shadowmessageresubmissionstotal
	,shadowqueueautodiscardstotal
	,shadowresubmissionqueuelength
	,successfulsubmissions
	,successfulsubmissionspersecond
	,temporarysubmissionfailures
	,temporarysubmissionfailurespersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $aggregateshadowqueuelength = undef;
my $caption = undef;
my $description = undef;
my $failedsubmissions = undef;
my $failedsubmissionspersecond = undef;
my $hubservers = undef;
my $hubserversinretry = undef;
my $hubtransportserverspercentactive = undef;
my $tablename = undef;
my $shadowmessageresubmissionstotal = undef;
my $shadowqueueautodiscardstotal = undef;
my $shadowresubmissionqueuelength = undef;
my $successfulsubmissions = undef;
my $successfulsubmissionspersecond = undef;
my $temporarysubmissionfailures = undef;
my $temporarysubmissionfailurespersec = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'aggregateshadowqueuelength'} = $process->{'AggregateShadowQueueLength'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'failedsubmissions'} = $process->{'FailedSubmissions'};
	$risc->{$name}->{'1'}->{'failedsubmissionspersecond'} = $process->{'FailedSubmissionsPerSecond'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'hubservers'} = $process->{'HubServers'};
	$risc->{$name}->{'1'}->{'hubserversinretry'} = $process->{'HubServersInRetry'};
	$risc->{$name}->{'1'}->{'hubtransportserverspercentactive'} = $process->{'HubTransportServersPercentActive'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'shadowmessageresubmissionstotal'} = $process->{'ShadowMessageResubmissionsTotal'};
	$risc->{$name}->{'1'}->{'shadowqueueautodiscardstotal'} = $process->{'ShadowQueueAutoDiscardsTotal'};
	$risc->{$name}->{'1'}->{'shadowresubmissionqueuelength'} = $process->{'ShadowResubmissionQueueLength'};
	$risc->{$name}->{'1'}->{'successfulsubmissions'} = $process->{'SuccessfulSubmissions'};
	$risc->{$name}->{'1'}->{'successfulsubmissionspersecond'} = $process->{'SuccessfulSubmissionsPerSecond'};
	$risc->{$name}->{'1'}->{'temporarysubmissionfailures'} = $process->{'TemporarySubmissionFailures'};
	$risc->{$name}->{'1'}->{'temporarysubmissionfailurespersec'} = $process->{'TemporarySubmissionFailuresPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'aggregateshadowqueuelength'} = $process->{'AggregateShadowQueueLength'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'failedsubmissions'} = $process->{'FailedSubmissions'};
	$risc->{$name}->{'2'}->{'failedsubmissionspersecond'} = $process->{'FailedSubmissionsPerSecond'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'hubservers'} = $process->{'HubServers'};
	$risc->{$name}->{'2'}->{'hubserversinretry'} = $process->{'HubServersInRetry'};
	$risc->{$name}->{'2'}->{'hubtransportserverspercentactive'} = $process->{'HubTransportServersPercentActive'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'shadowmessageresubmissionstotal'} = $process->{'ShadowMessageResubmissionsTotal'};
	$risc->{$name}->{'2'}->{'shadowqueueautodiscardstotal'} = $process->{'ShadowQueueAutoDiscardsTotal'};
	$risc->{$name}->{'2'}->{'shadowresubmissionqueuelength'} = $process->{'ShadowResubmissionQueueLength'};
	$risc->{$name}->{'2'}->{'successfulsubmissions'} = $process->{'SuccessfulSubmissions'};
	$risc->{$name}->{'2'}->{'successfulsubmissionspersecond'} = $process->{'SuccessfulSubmissionsPerSecond'};
	$risc->{$name}->{'2'}->{'temporarysubmissionfailures'} = $process->{'TemporarySubmissionFailures'};
	$risc->{$name}->{'2'}->{'temporarysubmissionfailurespersec'} = $process->{'TemporarySubmissionFailuresPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";


	#---find AggregateShadowQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$aggregateshadowqueuelength = $risc->{$calname}->{'2'}->{'aggregateshadowqueuelength'};
#	print "aggregateshadowqueuelength: $aggregateshadowqueuelength \n";


	#---find FailedSubmissions---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$failedsubmissions = $risc->{$calname}->{'2'}->{'failedsubmissions'};
#	print "failedsubmissions: $failedsubmissions \n";


	#---find FailedSubmissionsPerSecond---#	
	my $failedsubmissionspersecond1 = $risc->{$calname}->{'1'}->{'failedsubmissionspersecond'};	
#	print "failedsubmissionspersecond1: $failedsubmissionspersecond1 \n";	
	my $failedsubmissionspersecond2 = $risc->{$calname}->{'2'}->{'failedsubmissionspersecond'};	
#	print "failedsubmissionspersecond2: $failedsubmissionspersecond2 \n";	
	eval 	
	{	
	$failedsubmissionspersecond = perf_counter_counter(	
		$failedsubmissionspersecond1 #c1
		,$failedsubmissionspersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "failedsubmissionspersecond: $failedsubmissionspersecond \n";	


	#---find HubServers---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$hubservers = $risc->{$calname}->{'2'}->{'hubservers'};
#	print "hubservers: $hubservers \n";


	#---find HubServersInRetry---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$hubserversinretry = $risc->{$calname}->{'2'}->{'hubserversinretry'};
#	print "hubserversinretry: $hubserversinretry \n";


	#---find HubTransportServersPercentActive---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$hubtransportserverspercentactive = $risc->{$calname}->{'2'}->{'hubtransportserverspercentactive'};
#	print "hubtransportserverspercentactive: $hubtransportserverspercentactive \n";


	#---find ShadowMessageResubmissionsTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$shadowmessageresubmissionstotal = $risc->{$calname}->{'2'}->{'shadowmessageresubmissionstotal'};
#	print "shadowmessageresubmissionstotal: $shadowmessageresubmissionstotal \n";


	#---find ShadowQueueAutoDiscardsTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$shadowqueueautodiscardstotal = $risc->{$calname}->{'2'}->{'shadowqueueautodiscardstotal'};
#	print "shadowqueueautodiscardstotal: $shadowqueueautodiscardstotal \n";


	#---find ShadowResubmissionQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$shadowresubmissionqueuelength = $risc->{$calname}->{'2'}->{'shadowresubmissionqueuelength'};
#	print "shadowresubmissionqueuelength: $shadowresubmissionqueuelength \n";


	#---find SuccessfulSubmissions---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$successfulsubmissions = $risc->{$calname}->{'2'}->{'successfulsubmissions'};
#	print "successfulsubmissions: $successfulsubmissions \n";


	#---find SuccessfulSubmissionsPerSecond---#	
	my $successfulsubmissionspersecond1 = $risc->{$calname}->{'1'}->{'successfulsubmissionspersecond'};	
#	print "successfulsubmissionspersecond1: $successfulsubmissionspersecond1 \n";	
	my $successfulsubmissionspersecond2 = $risc->{$calname}->{'2'}->{'successfulsubmissionspersecond'};	
#	print "successfulsubmissionspersecond2: $successfulsubmissionspersecond2 \n";	
	eval 	
	{	
	$successfulsubmissionspersecond = perf_counter_counter(	
		$successfulsubmissionspersecond1 #c1
		,$successfulsubmissionspersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "successfulsubmissionspersecond: $successfulsubmissionspersecond \n";	


	#---find TemporarySubmissionFailures---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$temporarysubmissionfailures = $risc->{$calname}->{'2'}->{'temporarysubmissionfailures'};
#	print "temporarysubmissionfailures: $temporarysubmissionfailures \n";


	#---find TemporarySubmissionFailuresPersec---#	
	my $temporarysubmissionfailurespersec1 = $risc->{$calname}->{'1'}->{'temporarysubmissionfailurespersec'};	
#	print "temporarysubmissionfailurespersec1: $temporarysubmissionfailurespersec1 \n";	
	my $temporarysubmissionfailurespersec2 = $risc->{$calname}->{'2'}->{'temporarysubmissionfailurespersec'};	
#	print "temporarysubmissionfailurespersec2: $temporarysubmissionfailurespersec2 \n";	
	eval 	
	{	
	$temporarysubmissionfailurespersec = perf_counter_counter(	
		$temporarysubmissionfailurespersec1 #c1
		,$temporarysubmissionfailurespersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "temporarysubmissionfailurespersec: $temporarysubmissionfailurespersec \n";	

#####################################################################################
													
	#---add data to the table---#
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$aggregateshadowqueuelength
	,$caption
	,$description
	,$failedsubmissions
	,$failedsubmissionspersecond
	,$hubservers
	,$hubserversinretry
	,$hubtransportserverspercentactive
	,$tablename
	,$shadowmessageresubmissionstotal
	,$shadowqueueautodiscardstotal
	,$shadowresubmissionqueuelength
	,$successfulsubmissions
	,$successfulsubmissionspersecond
	,$temporarysubmissionfailures
	,$temporarysubmissionfailurespersec
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeResourceBooking
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchresourcebook (
	deviceid
	,scantime
	,accepted
	,averageresourcebookingprocessingtime
	,cancelled
	,caption
	,declined
	,description
	,events
	,name
	,requestsfailed
	,requestsprocessed
	,requestssubmitted
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $accepted = undef;
my $averageresourcebookingprocessingtime = undef;
my $cancelled = undef;
my $caption = undef;
my $declined = undef;
my $description = undef;
my $events = undef;
my $tablename = undef;
my $requestsfailed = undef;
my $requestsprocessed = undef;
my $requestssubmitted = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'accepted'} = $process->{'Accepted'};
	$risc->{$name}->{'1'}->{'averageresourcebookingprocessingtime'} = $process->{'AverageResourceBookingProcessingTime'};
	$risc->{$name}->{'1'}->{'averageresourcebookingprocessingtime_base'} = $process->{'AverageResourceBookingProcessingTime_Base'};
	$risc->{$name}->{'1'}->{'cancelled'} = $process->{'Cancelled'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'declined'} = $process->{'Declined'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'events'} = $process->{'Events'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'requestsfailed'} = $process->{'RequestsFailed'};
	$risc->{$name}->{'1'}->{'requestsprocessed'} = $process->{'RequestsProcessed'};
	$risc->{$name}->{'1'}->{'requestssubmitted'} = $process->{'RequestsSubmitted'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'accepted'} = $process->{'Accepted'};
	$risc->{$name}->{'2'}->{'averageresourcebookingprocessingtime'} = $process->{'AverageResourceBookingProcessingTime'};
	$risc->{$name}->{'2'}->{'averageresourcebookingprocessingtime_base'} = $process->{'AverageResourceBookingProcessingTime_Base'};
	$risc->{$name}->{'2'}->{'cancelled'} = $process->{'Cancelled'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'declined'} = $process->{'Declined'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'events'} = $process->{'Events'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'requestsfailed'} = $process->{'RequestsFailed'};
	$risc->{$name}->{'2'}->{'requestsprocessed'} = $process->{'RequestsProcessed'};
	$risc->{$name}->{'2'}->{'requestssubmitted'} = $process->{'RequestsSubmitted'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find Accepted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$accepted = $risc->{$calname}->{'2'}->{'accepted'};
#	print "accepted: $accepted \n";


	#---find AverageResourceBookingProcessingTime---#	
	my $averageresourcebookingprocessingtime1 = $risc->{$calname}->{'1'}->{'averageresourcebookingprocessingtime'};	
#	print "averageresourcebookingprocessingtime1: $averageresourcebookingprocessingtime1 \n";	
	my $averageresourcebookingprocessingtime2 = $risc->{$calname}->{'2'}->{'averageresourcebookingprocessingtime'};	
#	print "averageresourcebookingprocessingtime2: $averageresourcebookingprocessingtime2 \n";	
	my $averageresourcebookingprocessingtime_base1 = $risc->{$calname}->{'1'}->{'averageresourcebookingprocessingtime_base'};	
#	print "averageresourcebookingprocessingtime_base1: $averageresourcebookingprocessingtime_base1\n";	
	my $averageresourcebookingprocessingtime_base2 = $risc->{$calname}->{'2'}->{'averageresourcebookingprocessingtime_base'};	
#	print "averageresourcebookingprocessingtime_base2: $averageresourcebookingprocessingtime_base2\n";	
	eval 	
	{	
	$averageresourcebookingprocessingtime = PERF_AVERAGE_BULK(	
		$averageresourcebookingprocessingtime1 #counter value 1
		,$averageresourcebookingprocessingtime2 #counter value 2
		,$averageresourcebookingprocessingtime_base1 #base counter value 1
		,$averageresourcebookingprocessingtime_base2); #base counter value 2
	};	
#	print "averageresourcebookingprocessingtime: $averageresourcebookingprocessingtime \n";	


	#---find Cancelled---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$cancelled = $risc->{$calname}->{'2'}->{'cancelled'};
#	print "cancelled: $cancelled \n";


	#---find Declined---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$declined = $risc->{$calname}->{'2'}->{'declined'};
#	print "declined: $declined \n";


	#---find Events---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$events = $risc->{$calname}->{'2'}->{'events'};
#	print "events: $events \n";


	#---find RequestsFailed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$requestsfailed = $risc->{$calname}->{'2'}->{'requestsfailed'};
#	print "requestsfailed: $requestsfailed \n";


	#---find RequestsProcessed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$requestsprocessed = $risc->{$calname}->{'2'}->{'requestsprocessed'};
#	print "requestsprocessed: $requestsprocessed \n";


	#---find RequestsSubmitted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$requestssubmitted = $risc->{$calname}->{'2'}->{'requestssubmitted'};
#	print "requestssubmitted: $requestssubmitted \n";

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$accepted
	,$averageresourcebookingprocessingtime
	,$cancelled
	,$caption
	,$declined
	,$description
	,$events
	,$tablename
	,$requestsfailed
	,$requestsprocessed
	,$requestssubmitted
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeSearchIndices
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchsearchindices (
	deviceid
	,scantime
	,ageofthelastnotificationindexed
	,ageofthelastnotificationprocessed
	,averagedocumentindexingtime
	,averagelatencyofrpcsduringcrawling
	,averagelatencyofrpcstogetnotifications
	,averagelatencyofrpcsusedtoobtaincontent
	,averagesizeofindexedattachments
	,averagesizeofindexedattachmentsforprotectedmessages
	,caption
	,description
	,documentindexingrate
	,fullcrawlmodestatus
	,name
	,numberofcontentconversionsdone
	,numberofcreatenotifications
	,numberofcreatenotificationspersec
	,numberofdeletenotifications
	,numberofdeletenotificationspersec
	,numberofdocumentssuccessfullyindexed
	,numberofdocumentsthatfailedduringindexing
	,numberoffailedmailboxes
	,numberoffailedretries
	,numberofhtmlmessagebodies
	,numberofindexedattachments
	,numberofindexedattachmentsforprotectedmessages
	,numberofindexedrecipients
	,numberofintransitmailboxesbeingindexedonthisdestinationdatabase
	,numberofitemsinanotificationqueue
	,numberofmailboxeslefttocrawl
	,numberofmovenotifications
	,numberofmovenotificationspersec
	,numberofoutstandingbatches
	,numberofoutstandingdocuments
	,numberofplaintextmessagebodies
	,numberofretries
	,numberofretriesfornewfilter
	,numberofrmsprotectedmessages
	,numberofrtfmessagebodies
	,numberofsuccessfulretries
	,numberofupdatenotifications
	,numberofupdatenotificationspersec
	,percentageofnotificationsoptimized
	,recentaveragelatencyofrpcsusedtoobtaincontent
	,searchableifmounted
	,throttlingdelayvalue
	,timesincelastnotificationwasindexed
	,totaltimetakenforindexingprotectedmessages
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $ageofthelastnotificationindexed = undef;
my $ageofthelastnotificationprocessed = undef;
my $averagedocumentindexingtime = undef;
my $averagelatencyofrpcsduringcrawling = undef;
my $averagelatencyofrpcstogetnotifications = undef;
my $averagelatencyofrpcsusedtoobtaincontent = undef;
my $averagesizeofindexedattachments = undef;
my $averagesizeofindexedattachmentsforprotectedmessages = undef;
my $caption = undef;
my $description = undef;
my $documentindexingrate = undef;
my $fullcrawlmodestatus = undef;
my $tablename = undef;
my $numberofcontentconversionsdone = undef;
my $numberofcreatenotifications = undef;
my $numberofcreatenotificationspersec = undef;
my $numberofdeletenotifications = undef;
my $numberofdeletenotificationspersec = undef;
my $numberofdocumentssuccessfullyindexed = undef;
my $numberofdocumentsthatfailedduringindexing = undef;
my $numberoffailedmailboxes = undef;
my $numberoffailedretries = undef;
my $numberofhtmlmessagebodies = undef;
my $numberofindexedattachments = undef;
my $numberofindexedattachmentsforprotectedmessages = undef;
my $numberofindexedrecipients = undef;
my $numberofintransitmailboxesbeingindexedonthisdestinationdatabase = undef;
my $numberofitemsinanotificationqueue = undef;
my $numberofmailboxeslefttocrawl = undef;
my $numberofmovenotifications = undef;
my $numberofmovenotificationspersec = undef;
my $numberofoutstandingbatches = undef;
my $numberofoutstandingdocuments = undef;
my $numberofplaintextmessagebodies = undef;
my $numberofretries = undef;
my $numberofretriesfornewfilter = undef;
my $numberofrmsprotectedmessages = undef;
my $numberofrtfmessagebodies = undef;
my $numberofsuccessfulretries = undef;
my $numberofupdatenotifications = undef;
my $numberofupdatenotificationspersec = undef;
my $percentageofnotificationsoptimized = undef;
my $recentaveragelatencyofrpcsusedtoobtaincontent = undef;
my $searchableifmounted = undef;
my $throttlingdelayvalue = undef;
my $timesincelastnotificationwasindexed = undef;
my $totaltimetakenforindexingprotectedmessages = undef;

#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'ageofthelastnotificationindexed'} = $process->{'AgeoftheLastNotificationIndexed'};
	$risc->{$name}->{'1'}->{'ageofthelastnotificationprocessed'} = $process->{'AgeoftheLastNotificationProcessed'};
	$risc->{$name}->{'1'}->{'averagedocumentindexingtime'} = $process->{'Averagedocumentindexingtime'};
	$risc->{$name}->{'1'}->{'averagedocumentindexingtime_base'} = $process->{'Averagedocumentindexingtime_Base'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcsduringcrawling'} = $process->{'AverageLatencyofRPCsDuringCrawling'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcsduringcrawling_base'} = $process->{'AverageLatencyofRPCsDuringCrawling_Base'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcstogetnotifications'} = $process->{'AveragelatencyofRPCstogetnotifications'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcstogetnotifications_base'} = $process->{'AveragelatencyofRPCstogetnotifications_Base'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcsusedtoobtaincontent'} = $process->{'AverageLatencyofRPCsUsedtoObtainContent'};
	$risc->{$name}->{'1'}->{'averagelatencyofrpcsusedtoobtaincontent_base'} = $process->{'AverageLatencyofRPCsUsedtoObtainContent_Base'};
	$risc->{$name}->{'1'}->{'averagesizeofindexedattachments'} = $process->{'Averagesizeofindexedattachments'};
	$risc->{$name}->{'1'}->{'averagesizeofindexedattachments_base'} = $process->{'Averagesizeofindexedattachments_Base'};
	$risc->{$name}->{'1'}->{'averagesizeofindexedattachmentsforprotectedmessages'} = $process->{'AverageSizeOfIndexedAttachmentsForProtectedMessages'};
	$risc->{$name}->{'1'}->{'averagesizeofindexedattachmentsforprotectedmessages_base'} = $process->{'AverageSizeOfIndexedAttachmentsForProtectedMessages_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'documentindexingrate'} = $process->{'DocumentIndexingRate'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'fullcrawlmodestatus'} = $process->{'FullCrawlModeStatus'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'numberofcontentconversionsdone'} = $process->{'NumberofContentConversionsDone'};
	$risc->{$name}->{'1'}->{'numberofcreatenotifications'} = $process->{'NumberofCreateNotifications'};
	$risc->{$name}->{'1'}->{'numberofcreatenotificationspersec'} = $process->{'NumberofCreateNotificationsPersec'};
	$risc->{$name}->{'1'}->{'numberofdeletenotifications'} = $process->{'NumberofDeleteNotifications'};
	$risc->{$name}->{'1'}->{'numberofdeletenotificationspersec'} = $process->{'NumberofDeleteNotificationsPersec'};
	$risc->{$name}->{'1'}->{'numberofdocumentssuccessfullyindexed'} = $process->{'NumberofDocumentsSuccessfullyIndexed'};
	$risc->{$name}->{'1'}->{'numberofdocumentsthatfailedduringindexing'} = $process->{'NumberofDocumentsThatFailedDuringIndexing'};
	$risc->{$name}->{'1'}->{'numberoffailedmailboxes'} = $process->{'NumberofFailedMailboxes'};
	$risc->{$name}->{'1'}->{'numberoffailedretries'} = $process->{'NumberofFailedRetries'};
	$risc->{$name}->{'1'}->{'numberofhtmlmessagebodies'} = $process->{'NumberofHTMLMessageBodies'};
	$risc->{$name}->{'1'}->{'numberofindexedattachments'} = $process->{'NumberofIndexedAttachments'};
	$risc->{$name}->{'1'}->{'numberofindexedattachmentsforprotectedmessages'} = $process->{'NumberofIndexedAttachmentsForProtectedMessages'};
	$risc->{$name}->{'1'}->{'numberofindexedrecipients'} = $process->{'NumberofIndexedRecipients'};
	$risc->{$name}->{'1'}->{'numberofintransitmailboxesbeingindexedonthisdestinationdatabase'} = $process->{'NumberofInTransitMailboxesBeingIndexedonthisDestinationDatabase'};
	$risc->{$name}->{'1'}->{'numberofitemsinanotificationqueue'} = $process->{'NumberofItemsinaNotificationQueue'};
	$risc->{$name}->{'1'}->{'numberofmailboxeslefttocrawl'} = $process->{'NumberofMailboxesLefttoCrawl'};
	$risc->{$name}->{'1'}->{'numberofmovenotifications'} = $process->{'NumberofMoveNotifications'};
	$risc->{$name}->{'1'}->{'numberofmovenotificationspersec'} = $process->{'NumberofMoveNotificationsPersec'};
	$risc->{$name}->{'1'}->{'numberofoutstandingbatches'} = $process->{'NumberofOutstandingBatches'};
	$risc->{$name}->{'1'}->{'numberofoutstandingdocuments'} = $process->{'NumberofOutstandingDocuments'};
	$risc->{$name}->{'1'}->{'numberofplaintextmessagebodies'} = $process->{'NumberofPlainTextMessageBodies'};
	$risc->{$name}->{'1'}->{'numberofretries'} = $process->{'NumberofRetries'};
	$risc->{$name}->{'1'}->{'numberofretriesfornewfilter'} = $process->{'NumberofRetriesforNewFilter'};
	$risc->{$name}->{'1'}->{'numberofrmsprotectedmessages'} = $process->{'NumberofRMSProtectedMessages'};
	$risc->{$name}->{'1'}->{'numberofrtfmessagebodies'} = $process->{'NumberofRTFMessageBodies'};
	$risc->{$name}->{'1'}->{'numberofsuccessfulretries'} = $process->{'NumberofSuccessfulRetries'};
	$risc->{$name}->{'1'}->{'numberofupdatenotifications'} = $process->{'NumberofUpdateNotifications'};
	$risc->{$name}->{'1'}->{'numberofupdatenotificationspersec'} = $process->{'NumberofUpdateNotificationsPersec'};
	$risc->{$name}->{'1'}->{'percentageofnotificationsoptimized'} = $process->{'PercentageofNotificationsOptimized'};
	$risc->{$name}->{'1'}->{'percentageofnotificationsoptimized_base'} = $process->{'PercentageofNotificationsOptimized_Base'};
	$risc->{$name}->{'1'}->{'recentaveragelatencyofrpcsusedtoobtaincontent'} = $process->{'RecentAverageLatencyofRPCsUsedtoObtainContent'};
	$risc->{$name}->{'1'}->{'searchableifmounted'} = $process->{'SearchableifMounted'};
	$risc->{$name}->{'1'}->{'throttlingdelayvalue'} = $process->{'ThrottlingDelayValue'};
	$risc->{$name}->{'1'}->{'timesincelastnotificationwasindexed'} = $process->{'TimeSinceLastNotificationWasIndexed'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totaltimetakenforindexingprotectedmessages'} = $process->{'TotalTimeTakenForIndexingProtectedMessages'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'ageofthelastnotificationindexed'} = $process->{'AgeoftheLastNotificationIndexed'};
	$risc->{$name}->{'2'}->{'ageofthelastnotificationprocessed'} = $process->{'AgeoftheLastNotificationProcessed'};
	$risc->{$name}->{'2'}->{'averagedocumentindexingtime'} = $process->{'Averagedocumentindexingtime'};
	$risc->{$name}->{'2'}->{'averagedocumentindexingtime_base'} = $process->{'Averagedocumentindexingtime_Base'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcsduringcrawling'} = $process->{'AverageLatencyofRPCsDuringCrawling'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcsduringcrawling_base'} = $process->{'AverageLatencyofRPCsDuringCrawling_Base'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcstogetnotifications'} = $process->{'AveragelatencyofRPCstogetnotifications'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcstogetnotifications_base'} = $process->{'AveragelatencyofRPCstogetnotifications_Base'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcsusedtoobtaincontent'} = $process->{'AverageLatencyofRPCsUsedtoObtainContent'};
	$risc->{$name}->{'2'}->{'averagelatencyofrpcsusedtoobtaincontent_base'} = $process->{'AverageLatencyofRPCsUsedtoObtainContent_Base'};
	$risc->{$name}->{'2'}->{'averagesizeofindexedattachments'} = $process->{'Averagesizeofindexedattachments'};
	$risc->{$name}->{'2'}->{'averagesizeofindexedattachments_base'} = $process->{'Averagesizeofindexedattachments_Base'};
	$risc->{$name}->{'2'}->{'averagesizeofindexedattachmentsforprotectedmessages'} = $process->{'AverageSizeOfIndexedAttachmentsForProtectedMessages'};
	$risc->{$name}->{'2'}->{'averagesizeofindexedattachmentsforprotectedmessages_base'} = $process->{'AverageSizeOfIndexedAttachmentsForProtectedMessages_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'documentindexingrate'} = $process->{'DocumentIndexingRate'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'fullcrawlmodestatus'} = $process->{'FullCrawlModeStatus'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'numberofcontentconversionsdone'} = $process->{'NumberofContentConversionsDone'};
	$risc->{$name}->{'2'}->{'numberofcreatenotifications'} = $process->{'NumberofCreateNotifications'};
	$risc->{$name}->{'2'}->{'numberofcreatenotificationspersec'} = $process->{'NumberofCreateNotificationsPersec'};
	$risc->{$name}->{'2'}->{'numberofdeletenotifications'} = $process->{'NumberofDeleteNotifications'};
	$risc->{$name}->{'2'}->{'numberofdeletenotificationspersec'} = $process->{'NumberofDeleteNotificationsPersec'};
	$risc->{$name}->{'2'}->{'numberofdocumentssuccessfullyindexed'} = $process->{'NumberofDocumentsSuccessfullyIndexed'};
	$risc->{$name}->{'2'}->{'numberofdocumentsthatfailedduringindexing'} = $process->{'NumberofDocumentsThatFailedDuringIndexing'};
	$risc->{$name}->{'2'}->{'numberoffailedmailboxes'} = $process->{'NumberofFailedMailboxes'};
	$risc->{$name}->{'2'}->{'numberoffailedretries'} = $process->{'NumberofFailedRetries'};
	$risc->{$name}->{'2'}->{'numberofhtmlmessagebodies'} = $process->{'NumberofHTMLMessageBodies'};
	$risc->{$name}->{'2'}->{'numberofindexedattachments'} = $process->{'NumberofIndexedAttachments'};
	$risc->{$name}->{'2'}->{'numberofindexedattachmentsforprotectedmessages'} = $process->{'NumberofIndexedAttachmentsForProtectedMessages'};
	$risc->{$name}->{'2'}->{'numberofindexedrecipients'} = $process->{'NumberofIndexedRecipients'};
	$risc->{$name}->{'2'}->{'numberofintransitmailboxesbeingindexedonthisdestinationdatabase'} = $process->{'NumberofInTransitMailboxesBeingIndexedonthisDestinationDatabase'};
	$risc->{$name}->{'2'}->{'numberofitemsinanotificationqueue'} = $process->{'NumberofItemsinaNotificationQueue'};
	$risc->{$name}->{'2'}->{'numberofmailboxeslefttocrawl'} = $process->{'NumberofMailboxesLefttoCrawl'};
	$risc->{$name}->{'2'}->{'numberofmovenotifications'} = $process->{'NumberofMoveNotifications'};
	$risc->{$name}->{'2'}->{'numberofmovenotificationspersec'} = $process->{'NumberofMoveNotificationsPersec'};
	$risc->{$name}->{'2'}->{'numberofoutstandingbatches'} = $process->{'NumberofOutstandingBatches'};
	$risc->{$name}->{'2'}->{'numberofoutstandingdocuments'} = $process->{'NumberofOutstandingDocuments'};
	$risc->{$name}->{'2'}->{'numberofplaintextmessagebodies'} = $process->{'NumberofPlainTextMessageBodies'};
	$risc->{$name}->{'2'}->{'numberofretries'} = $process->{'NumberofRetries'};
	$risc->{$name}->{'2'}->{'numberofretriesfornewfilter'} = $process->{'NumberofRetriesforNewFilter'};
	$risc->{$name}->{'2'}->{'numberofrmsprotectedmessages'} = $process->{'NumberofRMSProtectedMessages'};
	$risc->{$name}->{'2'}->{'numberofrtfmessagebodies'} = $process->{'NumberofRTFMessageBodies'};
	$risc->{$name}->{'2'}->{'numberofsuccessfulretries'} = $process->{'NumberofSuccessfulRetries'};
	$risc->{$name}->{'2'}->{'numberofupdatenotifications'} = $process->{'NumberofUpdateNotifications'};
	$risc->{$name}->{'2'}->{'numberofupdatenotificationspersec'} = $process->{'NumberofUpdateNotificationsPersec'};
	$risc->{$name}->{'2'}->{'percentageofnotificationsoptimized'} = $process->{'PercentageofNotificationsOptimized'};
	$risc->{$name}->{'2'}->{'percentageofnotificationsoptimized_base'} = $process->{'PercentageofNotificationsOptimized_Base'};
	$risc->{$name}->{'2'}->{'recentaveragelatencyofrpcsusedtoobtaincontent'} = $process->{'RecentAverageLatencyofRPCsUsedtoObtainContent'};
	$risc->{$name}->{'2'}->{'searchableifmounted'} = $process->{'SearchableifMounted'};
	$risc->{$name}->{'2'}->{'throttlingdelayvalue'} = $process->{'ThrottlingDelayValue'};
	$risc->{$name}->{'2'}->{'timesincelastnotificationwasindexed'} = $process->{'TimeSinceLastNotificationWasIndexed'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totaltimetakenforindexingprotectedmessages'} = $process->{'TotalTimeTakenForIndexingProtectedMessages'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---find AgeoftheLastNotificationIndexed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ageofthelastnotificationindexed = $risc->{$calname}->{'2'}->{'ageofthelastnotificationindexed'};
#	print "ageofthelastnotificationindexed: $ageofthelastnotificationindexed \n";


	#---find AgeoftheLastNotificationProcessed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$ageofthelastnotificationprocessed = $risc->{$calname}->{'2'}->{'ageofthelastnotificationprocessed'};
#	print "ageofthelastnotificationprocessed: $ageofthelastnotificationprocessed \n";


	#---find Averagedocumentindexingtime---#	
	my $averagedocumentindexingtime1 = $risc->{$calname}->{'1'}->{'averagedocumentindexingtime'};	
#	print "averagedocumentindexingtime1: $averagedocumentindexingtime1 \n";	
	my $averagedocumentindexingtime2 = $risc->{$calname}->{'2'}->{'averagedocumentindexingtime'};	
#	print "averagedocumentindexingtime2: $averagedocumentindexingtime2 \n";	
	my $averagedocumentindexingtime_base1 = $risc->{$calname}->{'1'}->{'averagedocumentindexingtime_base'};	
#	print "averagedocumentindexingtime_base1: $averagedocumentindexingtime_base1\n";	
	my $averagedocumentindexingtime_base2 = $risc->{$calname}->{'2'}->{'averagedocumentindexingtime_base'};	
#	print "averagedocumentindexingtime_base2: $averagedocumentindexingtime_base2\n";	
	eval 	
	{	
	$averagedocumentindexingtime = PERF_AVERAGE_BULK(	
		$averagedocumentindexingtime1 #counter value 1
		,$averagedocumentindexingtime2 #counter value 2
		,$averagedocumentindexingtime_base1 #base counter value 1
		,$averagedocumentindexingtime_base2); #base counter value 2
	};	
#	print "averagedocumentindexingtime: $averagedocumentindexingtime \n";	


	#---find AverageLatencyofRPCsDuringCrawling---#	
	my $averagelatencyofrpcsduringcrawling1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcsduringcrawling'};	
#	print "averagelatencyofrpcsduringcrawling1: $averagelatencyofrpcsduringcrawling1 \n";	
	my $averagelatencyofrpcsduringcrawling2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcsduringcrawling'};	
#	print "averagelatencyofrpcsduringcrawling2: $averagelatencyofrpcsduringcrawling2 \n";	
	my $averagelatencyofrpcsduringcrawling_base1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcsduringcrawling_base'};	
#	print "averagelatencyofrpcsduringcrawling_base1: $averagelatencyofrpcsduringcrawling_base1\n";	
	my $averagelatencyofrpcsduringcrawling_base2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcsduringcrawling_base'};	
#	print "averagelatencyofrpcsduringcrawling_base2: $averagelatencyofrpcsduringcrawling_base2\n";	
	eval 	
	{	
	$averagelatencyofrpcsduringcrawling = PERF_AVERAGE_BULK(	
		$averagelatencyofrpcsduringcrawling1 #counter value 1
		,$averagelatencyofrpcsduringcrawling2 #counter value 2
		,$averagelatencyofrpcsduringcrawling_base1 #base counter value 1
		,$averagelatencyofrpcsduringcrawling_base2); #base counter value 2
	};	
#	print "averagelatencyofrpcsduringcrawling: $averagelatencyofrpcsduringcrawling \n";	


	#---find AveragelatencyofRPCstogetnotifications---#	
	my $averagelatencyofrpcstogetnotifications1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcstogetnotifications'};	
#	print "averagelatencyofrpcstogetnotifications1: $averagelatencyofrpcstogetnotifications1 \n";	
	my $averagelatencyofrpcstogetnotifications2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcstogetnotifications'};	
#	print "averagelatencyofrpcstogetnotifications2: $averagelatencyofrpcstogetnotifications2 \n";	
	my $averagelatencyofrpcstogetnotifications_base1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcstogetnotifications_base'};	
#	print "averagelatencyofrpcstogetnotifications_base1: $averagelatencyofrpcstogetnotifications_base1\n";	
	my $averagelatencyofrpcstogetnotifications_base2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcstogetnotifications_base'};	
#	print "averagelatencyofrpcstogetnotifications_base2: $averagelatencyofrpcstogetnotifications_base2\n";	
	eval 	
	{	
	$averagelatencyofrpcstogetnotifications = PERF_AVERAGE_BULK(	
		$averagelatencyofrpcstogetnotifications1 #counter value 1
		,$averagelatencyofrpcstogetnotifications2 #counter value 2
		,$averagelatencyofrpcstogetnotifications_base1 #base counter value 1
		,$averagelatencyofrpcstogetnotifications_base2); #base counter value 2
	};	
#	print "averagelatencyofrpcstogetnotifications: $averagelatencyofrpcstogetnotifications \n";	


	#---find AverageLatencyofRPCsUsedtoObtainContent---#	
	my $averagelatencyofrpcsusedtoobtaincontent1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcsusedtoobtaincontent'};	
#	print "averagelatencyofrpcsusedtoobtaincontent1: $averagelatencyofrpcsusedtoobtaincontent1 \n";	
	my $averagelatencyofrpcsusedtoobtaincontent2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcsusedtoobtaincontent'};	
#	print "averagelatencyofrpcsusedtoobtaincontent2: $averagelatencyofrpcsusedtoobtaincontent2 \n";	
	my $averagelatencyofrpcsusedtoobtaincontent_base1 = $risc->{$calname}->{'1'}->{'averagelatencyofrpcsusedtoobtaincontent_base'};	
#	print "averagelatencyofrpcsusedtoobtaincontent_base1: $averagelatencyofrpcsusedtoobtaincontent_base1\n";	
	my $averagelatencyofrpcsusedtoobtaincontent_base2 = $risc->{$calname}->{'2'}->{'averagelatencyofrpcsusedtoobtaincontent_base'};	
#	print "averagelatencyofrpcsusedtoobtaincontent_base2: $averagelatencyofrpcsusedtoobtaincontent_base2\n";	
	eval 	
	{	
	$averagelatencyofrpcsusedtoobtaincontent = PERF_AVERAGE_BULK(	
		$averagelatencyofrpcsusedtoobtaincontent1 #counter value 1
		,$averagelatencyofrpcsusedtoobtaincontent2 #counter value 2
		,$averagelatencyofrpcsusedtoobtaincontent_base1 #base counter value 1
		,$averagelatencyofrpcsusedtoobtaincontent_base2); #base counter value 2
	};	
#	print "averagelatencyofrpcsusedtoobtaincontent: $averagelatencyofrpcsusedtoobtaincontent \n";	


	#---find Averagesizeofindexedattachments---#	
	my $averagesizeofindexedattachments1 = $risc->{$calname}->{'1'}->{'averagesizeofindexedattachments'};	
#	print "averagesizeofindexedattachments1: $averagesizeofindexedattachments1 \n";	
	my $averagesizeofindexedattachments2 = $risc->{$calname}->{'2'}->{'averagesizeofindexedattachments'};	
#	print "averagesizeofindexedattachments2: $averagesizeofindexedattachments2 \n";	
	my $averagesizeofindexedattachments_base1 = $risc->{$calname}->{'1'}->{'averagesizeofindexedattachments_base'};	
#	print "averagesizeofindexedattachments_base1: $averagesizeofindexedattachments_base1\n";	
	my $averagesizeofindexedattachments_base2 = $risc->{$calname}->{'2'}->{'averagesizeofindexedattachments_base'};	
#	print "averagesizeofindexedattachments_base2: $averagesizeofindexedattachments_base2\n";	
	eval 	
	{	
	$averagesizeofindexedattachments = PERF_AVERAGE_BULK(	
		$averagesizeofindexedattachments1 #counter value 1
		,$averagesizeofindexedattachments2 #counter value 2
		,$averagesizeofindexedattachments_base1 #base counter value 1
		,$averagesizeofindexedattachments_base2); #base counter value 2
	};	
#	print "averagesizeofindexedattachments: $averagesizeofindexedattachments \n";	


	#---find AverageSizeOfIndexedAttachmentsForProtectedMessages---#	
	my $averagesizeofindexedattachmentsforprotectedmessages1 = $risc->{$calname}->{'1'}->{'averagesizeofindexedattachmentsforprotectedmessages'};	
#	print "averagesizeofindexedattachmentsforprotectedmessages1: $averagesizeofindexedattachmentsforprotectedmessages1 \n";	
	my $averagesizeofindexedattachmentsforprotectedmessages2 = $risc->{$calname}->{'2'}->{'averagesizeofindexedattachmentsforprotectedmessages'};	
#	print "averagesizeofindexedattachmentsforprotectedmessages2: $averagesizeofindexedattachmentsforprotectedmessages2 \n";	
	my $averagesizeofindexedattachmentsforprotectedmessages_base1 = $risc->{$calname}->{'1'}->{'averagesizeofindexedattachmentsforprotectedmessages_base'};	
#	print "averagesizeofindexedattachmentsforprotectedmessages_base1: $averagesizeofindexedattachmentsforprotectedmessages_base1\n";	
	my $averagesizeofindexedattachmentsforprotectedmessages_base2 = $risc->{$calname}->{'2'}->{'averagesizeofindexedattachmentsforprotectedmessages_base'};	
#	print "averagesizeofindexedattachmentsforprotectedmessages_base2: $averagesizeofindexedattachmentsforprotectedmessages_base2\n";	
	eval 	
	{	
	$averagesizeofindexedattachmentsforprotectedmessages = PERF_AVERAGE_BULK(	
		$averagesizeofindexedattachmentsforprotectedmessages1 #counter value 1
		,$averagesizeofindexedattachmentsforprotectedmessages2 #counter value 2
		,$averagesizeofindexedattachmentsforprotectedmessages_base1 #base counter value 1
		,$averagesizeofindexedattachmentsforprotectedmessages_base2); #base counter value 2
	};	
#	print "averagesizeofindexedattachmentsforprotectedmessages: $averagesizeofindexedattachmentsforprotectedmessages \n";	


	#---find DocumentIndexingRate---#	
	my $documentindexingrate1 = $risc->{$calname}->{'1'}->{'documentindexingrate'};	
#	print "documentindexingrate1: $documentindexingrate1 \n";	
	my $documentindexingrate2 = $risc->{$calname}->{'2'}->{'documentindexingrate'};	
#	print "documentindexingrate2: $documentindexingrate2 \n";	
	eval 	
	{	
	$documentindexingrate = perf_counter_counter(	
		$documentindexingrate1 #c1
		,$documentindexingrate2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "documentindexingrate: $documentindexingrate \n";	


	#---find FullCrawlModeStatus---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$fullcrawlmodestatus = $risc->{$calname}->{'2'}->{'fullcrawlmodestatus'};
#	print "fullcrawlmodestatus: $fullcrawlmodestatus \n";


	#---find NumberofContentConversionsDone---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofcontentconversionsdone = $risc->{$calname}->{'2'}->{'numberofcontentconversionsdone'};
#	print "numberofcontentconversionsdone: $numberofcontentconversionsdone \n";


	#---find NumberofCreateNotifications---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofcreatenotifications = $risc->{$calname}->{'2'}->{'numberofcreatenotifications'};
#	print "numberofcreatenotifications: $numberofcreatenotifications \n";


	#---find NumberofCreateNotificationsPersec---#	
	my $numberofcreatenotificationspersec1 = $risc->{$calname}->{'1'}->{'numberofcreatenotificationspersec'};	
#	print "numberofcreatenotificationspersec1: $numberofcreatenotificationspersec1 \n";	
	my $numberofcreatenotificationspersec2 = $risc->{$calname}->{'2'}->{'numberofcreatenotificationspersec'};	
#	print "numberofcreatenotificationspersec2: $numberofcreatenotificationspersec2 \n";	
	eval 	
	{	
	$numberofcreatenotificationspersec = perf_counter_counter(	
		$numberofcreatenotificationspersec1 #c1
		,$numberofcreatenotificationspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "numberofcreatenotificationspersec: $numberofcreatenotificationspersec \n";	


	#---find NumberofDeleteNotifications---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofdeletenotifications = $risc->{$calname}->{'2'}->{'numberofdeletenotifications'};
#	print "numberofdeletenotifications: $numberofdeletenotifications \n";


	#---find NumberofDeleteNotificationsPersec---#	
	my $numberofdeletenotificationspersec1 = $risc->{$calname}->{'1'}->{'numberofdeletenotificationspersec'};	
#	print "numberofdeletenotificationspersec1: $numberofdeletenotificationspersec1 \n";	
	my $numberofdeletenotificationspersec2 = $risc->{$calname}->{'2'}->{'numberofdeletenotificationspersec'};	
#	print "numberofdeletenotificationspersec2: $numberofdeletenotificationspersec2 \n";	
	eval 	
	{	
	$numberofdeletenotificationspersec = perf_counter_counter(	
		$numberofdeletenotificationspersec1 #c1
		,$numberofdeletenotificationspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "numberofdeletenotificationspersec: $numberofdeletenotificationspersec \n";	


	#---find NumberofDocumentsSuccessfullyIndexed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofdocumentssuccessfullyindexed = $risc->{$calname}->{'2'}->{'numberofdocumentssuccessfullyindexed'};
#	print "numberofdocumentssuccessfullyindexed: $numberofdocumentssuccessfullyindexed \n";


	#---find NumberofDocumentsThatFailedDuringIndexing---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofdocumentsthatfailedduringindexing = $risc->{$calname}->{'2'}->{'numberofdocumentsthatfailedduringindexing'};
#	print "numberofdocumentsthatfailedduringindexing: $numberofdocumentsthatfailedduringindexing \n";


	#---find NumberofFailedMailboxes---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberoffailedmailboxes = $risc->{$calname}->{'2'}->{'numberoffailedmailboxes'};
#	print "numberoffailedmailboxes: $numberoffailedmailboxes \n";


	#---find NumberofFailedRetries---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberoffailedretries = $risc->{$calname}->{'2'}->{'numberoffailedretries'};
#	print "numberoffailedretries: $numberoffailedretries \n";


	#---find NumberofHTMLMessageBodies---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofhtmlmessagebodies = $risc->{$calname}->{'2'}->{'numberofhtmlmessagebodies'};
#	print "numberofhtmlmessagebodies: $numberofhtmlmessagebodies \n";


	#---find NumberofIndexedAttachments---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofindexedattachments = $risc->{$calname}->{'2'}->{'numberofindexedattachments'};
#	print "numberofindexedattachments: $numberofindexedattachments \n";


	#---find NumberofIndexedAttachmentsForProtectedMessages---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofindexedattachmentsforprotectedmessages = $risc->{$calname}->{'2'}->{'numberofindexedattachmentsforprotectedmessages'};
#	print "numberofindexedattachmentsforprotectedmessages: $numberofindexedattachmentsforprotectedmessages \n";


	#---find NumberofIndexedRecipients---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$numberofindexedrecipients = $risc->{$calname}->{'2'}->{'numberofindexedrecipients'};
#	print "numberofindexedrecipients: $numberofindexedrecipients \n";


	#---find NumberofInTransitMailboxesBeingIndexedonthisDestinationDatabase---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofintransitmailboxesbeingindexedonthisdestinationdatabase = $risc->{$calname}->{'2'}->{'numberofintransitmailboxesbeingindexedonthisdestinationdatabase'};
#	print "numberofintransitmailboxesbeingindexedonthisdestinationdatabase: $numberofintransitmailboxesbeingindexedonthisdestinationdatabase \n";


	#---find NumberofItemsinaNotificationQueue---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofitemsinanotificationqueue = $risc->{$calname}->{'2'}->{'numberofitemsinanotificationqueue'};
#	print "numberofitemsinanotificationqueue: $numberofitemsinanotificationqueue \n";


	#---find NumberofMailboxesLefttoCrawl---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofmailboxeslefttocrawl = $risc->{$calname}->{'2'}->{'numberofmailboxeslefttocrawl'};
#	print "numberofmailboxeslefttocrawl: $numberofmailboxeslefttocrawl \n";


	#---find NumberofMoveNotifications---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofmovenotifications = $risc->{$calname}->{'2'}->{'numberofmovenotifications'};
#	print "numberofmovenotifications: $numberofmovenotifications \n";


	#---find NumberofMoveNotificationsPersec---#	
	my $numberofmovenotificationspersec1 = $risc->{$calname}->{'1'}->{'numberofmovenotificationspersec'};	
#	print "numberofmovenotificationspersec1: $numberofmovenotificationspersec1 \n";	
	my $numberofmovenotificationspersec2 = $risc->{$calname}->{'2'}->{'numberofmovenotificationspersec'};	
#	print "numberofmovenotificationspersec2: $numberofmovenotificationspersec2 \n";	
	eval 	
	{	
	$numberofmovenotificationspersec = perf_counter_counter(	
		$numberofmovenotificationspersec1 #c1
		,$numberofmovenotificationspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "numberofmovenotificationspersec: $numberofmovenotificationspersec \n";	


	#---find NumberofOutstandingBatches---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofoutstandingbatches = $risc->{$calname}->{'2'}->{'numberofoutstandingbatches'};
#	print "numberofoutstandingbatches: $numberofoutstandingbatches \n";


	#---find NumberofOutstandingDocuments---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofoutstandingdocuments = $risc->{$calname}->{'2'}->{'numberofoutstandingdocuments'};
#	print "numberofoutstandingdocuments: $numberofoutstandingdocuments \n";


	#---find NumberofPlainTextMessageBodies---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofplaintextmessagebodies = $risc->{$calname}->{'2'}->{'numberofplaintextmessagebodies'};
#	print "numberofplaintextmessagebodies: $numberofplaintextmessagebodies \n";


	#---find NumberofRetries---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofretries = $risc->{$calname}->{'2'}->{'numberofretries'};
#	print "numberofretries: $numberofretries \n";


	#---find NumberofRetriesforNewFilter---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofretriesfornewfilter = $risc->{$calname}->{'2'}->{'numberofretriesfornewfilter'};
#	print "numberofretriesfornewfilter: $numberofretriesfornewfilter \n";


	#---find NumberofRMSProtectedMessages---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofrmsprotectedmessages = $risc->{$calname}->{'2'}->{'numberofrmsprotectedmessages'};
#	print "numberofrmsprotectedmessages: $numberofrmsprotectedmessages \n";


	#---find NumberofRTFMessageBodies---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofrtfmessagebodies = $risc->{$calname}->{'2'}->{'numberofrtfmessagebodies'};
#	print "numberofrtfmessagebodies: $numberofrtfmessagebodies \n";


	#---find NumberofSuccessfulRetries---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofsuccessfulretries = $risc->{$calname}->{'2'}->{'numberofsuccessfulretries'};
#	print "numberofsuccessfulretries: $numberofsuccessfulretries \n";


	#---find NumberofUpdateNotifications---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofupdatenotifications = $risc->{$calname}->{'2'}->{'numberofupdatenotifications'};
#	print "numberofupdatenotifications: $numberofupdatenotifications \n";


	#---find NumberofUpdateNotificationsPersec---#	
	my $numberofupdatenotificationspersec1 = $risc->{$calname}->{'1'}->{'numberofupdatenotificationspersec'};	
#	print "numberofupdatenotificationspersec1: $numberofupdatenotificationspersec1 \n";	
	my $numberofupdatenotificationspersec2 = $risc->{$calname}->{'2'}->{'numberofupdatenotificationspersec'};	
#	print "numberofupdatenotificationspersec2: $numberofupdatenotificationspersec2 \n";	
	eval 	
	{	
	$numberofupdatenotificationspersec = perf_counter_counter(	
		$numberofupdatenotificationspersec1 #c1
		,$numberofupdatenotificationspersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "numberofupdatenotificationspersec: $numberofupdatenotificationspersec \n";	


	#---find PercentageofNotificationsOptimized---#	
	my $percentageofnotificationsoptimized2 = $risc->{$calname}->{'2'}->{'percentageofnotificationsoptimized'};	
#	print "percentageofnotificationsoptimized2: $percentageofnotificationsoptimized2 \n";	
	my $percentageofnotificationsoptimized_base2 = $risc->{$calname}->{'2'}->{'percentageofnotificationsoptimized_base'};	
#	print "percentageofnotificationsoptimized_base2: $percentageofnotificationsoptimized_base2\n";	
	eval 	
	{	
	$percentageofnotificationsoptimized = PERF_RAW_FRACTION(	
		$percentageofnotificationsoptimized2 #counter value 2
		,$percentageofnotificationsoptimized_base2); #base counter value 2
	};	
#	print "percentageofnotificationsoptimized: $percentageofnotificationsoptimized \n";	


	#---find RecentAverageLatencyofRPCsUsedtoObtainContent---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$recentaveragelatencyofrpcsusedtoobtaincontent = $risc->{$calname}->{'2'}->{'recentaveragelatencyofrpcsusedtoobtaincontent'};
#	print "recentaveragelatencyofrpcsusedtoobtaincontent: $recentaveragelatencyofrpcsusedtoobtaincontent \n";


	#---find SearchableifMounted---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$searchableifmounted = $risc->{$calname}->{'2'}->{'searchableifmounted'};
#	print "searchableifmounted: $searchableifmounted \n";


	#---find ThrottlingDelayValue---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$throttlingdelayvalue = $risc->{$calname}->{'2'}->{'throttlingdelayvalue'};
#	print "throttlingdelayvalue: $throttlingdelayvalue \n";


	#---find TimeSinceLastNotificationWasIndexed---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$timesincelastnotificationwasindexed = $risc->{$calname}->{'2'}->{'timesincelastnotificationwasindexed'};
#	print "timesincelastnotificationwasindexed: $timesincelastnotificationwasindexed \n";


	#---find TotalTimeTakenForIndexingProtectedMessages---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$totaltimetakenforindexingprotectedmessages = $risc->{$calname}->{'2'}->{'totaltimetakenforindexingprotectedmessages'};
#	print "totaltimetakenforindexingprotectedmessages: $totaltimetakenforindexingprotectedmessages \n";

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$ageofthelastnotificationindexed
	,$ageofthelastnotificationprocessed
	,$averagedocumentindexingtime
	,$averagelatencyofrpcsduringcrawling
	,$averagelatencyofrpcstogetnotifications
	,$averagelatencyofrpcsusedtoobtaincontent
	,$averagesizeofindexedattachments
	,$averagesizeofindexedattachmentsforprotectedmessages
	,$caption
	,$description
	,$documentindexingrate
	,$fullcrawlmodestatus
	,$tablename
	,$numberofcontentconversionsdone
	,$numberofcreatenotifications
	,$numberofcreatenotificationspersec
	,$numberofdeletenotifications
	,$numberofdeletenotificationspersec
	,$numberofdocumentssuccessfullyindexed
	,$numberofdocumentsthatfailedduringindexing
	,$numberoffailedmailboxes
	,$numberoffailedretries
	,$numberofhtmlmessagebodies
	,$numberofindexedattachments
	,$numberofindexedattachmentsforprotectedmessages
	,$numberofindexedrecipients
	,$numberofintransitmailboxesbeingindexedonthisdestinationdatabase
	,$numberofitemsinanotificationqueue
	,$numberofmailboxeslefttocrawl
	,$numberofmovenotifications
	,$numberofmovenotificationspersec
	,$numberofoutstandingbatches
	,$numberofoutstandingdocuments
	,$numberofplaintextmessagebodies
	,$numberofretries
	,$numberofretriesfornewfilter
	,$numberofrmsprotectedmessages
	,$numberofrtfmessagebodies
	,$numberofsuccessfulretries
	,$numberofupdatenotifications
	,$numberofupdatenotificationspersec
	,$percentageofnotificationsoptimized
	,$recentaveragelatencyofrpcsusedtoobtaincontent
	,$searchableifmounted
	,$throttlingdelayvalue
	,$timesincelastnotificationwasindexed
	,$totaltimetakenforindexingprotectedmessages
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeStoreInterface
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchstoreint (
	deviceid
	,scantime
	,caption
	,connectioncacheactiveconnections
	,connectioncacheidleconnections
	,connectioncachenumcaches
	,connectioncacheoutoflimitcreations
	,connectioncachetotalcapacity
	,description
	,exrpcconnectioncreationevents
	,exrpcconnectiondisposalevents
	,exrpcconnectionoutstanding
	,name
	,roprequestscomplete
	,roprequestsoutstanding
	,roprequestssent
	,rpcbytesreceived
	,rpcbytesreceivedaverage
	,rpcbytessent
	,rpcbytessentaverage
	,rpclatencyaveragemsec
	,rpclatencytotalmsec
	,rpcpoolactivethreadsratio
	,rpcpoolasyncnotificationsreceivedpersec
	,rpcpoolaveragelatency
	,rpcpoolparkedasyncnotificationcalls
	,rpcpoolpools
	,rpcpoolrpccontexthandles
	,rpcpoolsessionnotificationsreceivedpersec
	,rpcpoolsessions
	,rpcrequestsfailed
	,rpcrequestsfailedpercent
	,rpcrequestsfailedwithexception
	,rpcrequestsoutstanding
	,rpcrequestssent
	,rpcrequestssentpersec
	,rpcrequestssucceeded
	,rpcslowrequests
	,rpcslowrequestslatencyaveragemsec
	,rpcslowrequestslatencytotalmsec
	,rpcslowrequestspercent
	,unkfolders
	,unklogons
	,unkmessages
	,unkobjectstotal
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $caption = undef;
my $connectioncacheactiveconnections = undef;
my $connectioncacheidleconnections = undef;
my $connectioncachenumcaches = undef;
my $connectioncacheoutoflimitcreations = undef;
my $connectioncachetotalcapacity = undef;
my $description = undef;
my $exrpcconnectioncreationevents = undef;
my $exrpcconnectiondisposalevents = undef;
my $exrpcconnectionoutstanding = undef;
my $tablename = undef;
my $roprequestscomplete = undef;
my $roprequestsoutstanding = undef;
my $roprequestssent = undef;
my $rpcbytesreceived = undef;
my $rpcbytesreceivedaverage = undef;
my $rpcbytessent = undef;
my $rpcbytessentaverage = undef;
my $rpclatencyaveragemsec = undef;
my $rpclatencytotalmsec = undef;
my $rpcpoolactivethreadsratio = undef;
my $rpcpoolasyncnotificationsreceivedpersec = undef;
my $rpcpoolaveragelatency = undef;
my $rpcpoolparkedasyncnotificationcalls = undef;
my $rpcpoolpools = undef;
my $rpcpoolrpccontexthandles = undef;
my $rpcpoolsessionnotificationsreceivedpersec = undef;
my $rpcpoolsessions = undef;
my $rpcrequestsfailed = undef;
my $rpcrequestsfailedpercent = undef;
my $rpcrequestsfailedwithexception = undef;
my $rpcrequestsoutstanding = undef;
my $rpcrequestssent = undef;
my $rpcrequestssentpersec = undef;
my $rpcrequestssucceeded = undef;
my $rpcslowrequests = undef;
my $rpcslowrequestslatencyaveragemsec = undef;
my $rpcslowrequestslatencytotalmsec = undef;
my $rpcslowrequestspercent = undef;
my $unkfolders = undef;
my $unklogons = undef;
my $unkmessages = undef;
my $unkobjectstotal = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'connectioncacheactiveconnections'} = $process->{'ConnectionCacheactiveconnections'};
	$risc->{$name}->{'1'}->{'connectioncacheidleconnections'} = $process->{'ConnectionCacheidleconnections'};
	$risc->{$name}->{'1'}->{'connectioncachenumcaches'} = $process->{'ConnectionCachenumcaches'};
	$risc->{$name}->{'1'}->{'connectioncacheoutoflimitcreations'} = $process->{'ConnectionCacheoutoflimitcreations'};
	$risc->{$name}->{'1'}->{'connectioncachetotalcapacity'} = $process->{'ConnectionCachetotalcapacity'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'exrpcconnectioncreationevents'} = $process->{'ExRpcConnectioncreationevents'};
	$risc->{$name}->{'1'}->{'exrpcconnectiondisposalevents'} = $process->{'ExRpcConnectiondisposalevents'};
	$risc->{$name}->{'1'}->{'exrpcconnectionoutstanding'} = $process->{'ExRpcConnectionoutstanding'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'roprequestscomplete'} = $process->{'ROPRequestscomplete'};
	$risc->{$name}->{'1'}->{'roprequestsoutstanding'} = $process->{'ROPRequestsoutstanding'};
	$risc->{$name}->{'1'}->{'roprequestssent'} = $process->{'ROPRequestssent'};
	$risc->{$name}->{'1'}->{'rpcbytesreceived'} = $process->{'RPCBytesreceived'};
	$risc->{$name}->{'1'}->{'rpcbytesreceivedaverage'} = $process->{'RPCBytesreceivedaverage'};
	$risc->{$name}->{'1'}->{'rpcbytesreceivedaverage_base'} = $process->{'RPCBytesreceivedaverage_Base'};
	$risc->{$name}->{'1'}->{'rpcbytessent'} = $process->{'RPCBytessent'};
	$risc->{$name}->{'1'}->{'rpcbytessentaverage'} = $process->{'RPCBytessentaverage'};
	$risc->{$name}->{'1'}->{'rpcbytessentaverage_base'} = $process->{'RPCBytessentaverage_Base'};
	$risc->{$name}->{'1'}->{'rpclatencyaveragemsec'} = $process->{'RPCLatencyaveragemsec'};
	$risc->{$name}->{'1'}->{'rpclatencyaveragemsec_base'} = $process->{'RPCLatencyaveragemsec_Base'};
	$risc->{$name}->{'1'}->{'rpclatencytotalmsec'} = $process->{'RPCLatencytotalmsec'};
	$risc->{$name}->{'1'}->{'rpcpoolactivethreadsratio'} = $process->{'RPCPoolActiveThreadsRatio'};
	$risc->{$name}->{'1'}->{'rpcpoolactivethreadsratio_base'} = $process->{'RPCPoolActiveThreadsRatio_Base'};
	$risc->{$name}->{'1'}->{'rpcpoolasyncnotificationsreceivedpersec'} = $process->{'RPCPoolAsyncNotificationsReceivedPersec'};
	$risc->{$name}->{'1'}->{'rpcpoolaveragelatency'} = $process->{'RPCPoolAverageLatency'};
	$risc->{$name}->{'1'}->{'rpcpoolaveragelatency_base'} = $process->{'RPCPoolAverageLatency_Base'};
	$risc->{$name}->{'1'}->{'rpcpoolparkedasyncnotificationcalls'} = $process->{'RPCPoolParkedAsyncNotificationCalls'};
	$risc->{$name}->{'1'}->{'rpcpoolpools'} = $process->{'RPCPoolPools'};
	$risc->{$name}->{'1'}->{'rpcpoolrpccontexthandles'} = $process->{'RPCPoolRPCContextHandles'};
	$risc->{$name}->{'1'}->{'rpcpoolsessionnotificationsreceivedpersec'} = $process->{'RPCPoolSessionNotificationsReceivedPersec'};
	$risc->{$name}->{'1'}->{'rpcpoolsessions'} = $process->{'RPCPoolSessions'};
	$risc->{$name}->{'1'}->{'rpcrequestsfailed'} = $process->{'RPCRequestsfailed'};
	$risc->{$name}->{'1'}->{'rpcrequestsfailedpercent'} = $process->{'RPCRequestsfailedPercent'};
	$risc->{$name}->{'1'}->{'rpcrequestsfailedpercent_base'} = $process->{'RPCRequestsfailedPercent_Base'};
	$risc->{$name}->{'1'}->{'rpcrequestsfailedwithexception'} = $process->{'RPCRequestsfailedwithexception'};
	$risc->{$name}->{'1'}->{'rpcrequestsoutstanding'} = $process->{'RPCRequestsoutstanding'};
	$risc->{$name}->{'1'}->{'rpcrequestssent'} = $process->{'RPCRequestssent'};
	$risc->{$name}->{'1'}->{'rpcrequestssentpersec'} = $process->{'RPCRequestssentPersec'};
	$risc->{$name}->{'1'}->{'rpcrequestssucceeded'} = $process->{'RPCRequestssucceeded'};
	$risc->{$name}->{'1'}->{'rpcslowrequests'} = $process->{'RPCSlowrequests'};
	$risc->{$name}->{'1'}->{'rpcslowrequestslatencyaveragemsec'} = $process->{'RPCSlowrequestslatencyaveragemsec'};
	$risc->{$name}->{'1'}->{'rpcslowrequestslatencyaveragemsec_base'} = $process->{'RPCSlowrequestslatencyaveragemsec_Base'};
	$risc->{$name}->{'1'}->{'rpcslowrequestslatencytotalmsec'} = $process->{'RPCSlowrequestslatencytotalmsec'};
	$risc->{$name}->{'1'}->{'rpcslowrequestspercent'} = $process->{'RPCSlowrequestsPercent'};
	$risc->{$name}->{'1'}->{'rpcslowrequestspercent_base'} = $process->{'RPCSlowrequestsPercent_Base'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'unkfolders'} = $process->{'UNKFolders'};
	$risc->{$name}->{'1'}->{'unklogons'} = $process->{'UNKLogons'};
	$risc->{$name}->{'1'}->{'unkmessages'} = $process->{'UNKMessages'};
	$risc->{$name}->{'1'}->{'unkobjectstotal'} = $process->{'UNKObjectstotal'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'connectioncacheactiveconnections'} = $process->{'ConnectionCacheactiveconnections'};
	$risc->{$name}->{'2'}->{'connectioncacheidleconnections'} = $process->{'ConnectionCacheidleconnections'};
	$risc->{$name}->{'2'}->{'connectioncachenumcaches'} = $process->{'ConnectionCachenumcaches'};
	$risc->{$name}->{'2'}->{'connectioncacheoutoflimitcreations'} = $process->{'ConnectionCacheoutoflimitcreations'};
	$risc->{$name}->{'2'}->{'connectioncachetotalcapacity'} = $process->{'ConnectionCachetotalcapacity'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'exrpcconnectioncreationevents'} = $process->{'ExRpcConnectioncreationevents'};
	$risc->{$name}->{'2'}->{'exrpcconnectiondisposalevents'} = $process->{'ExRpcConnectiondisposalevents'};
	$risc->{$name}->{'2'}->{'exrpcconnectionoutstanding'} = $process->{'ExRpcConnectionoutstanding'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'roprequestscomplete'} = $process->{'ROPRequestscomplete'};
	$risc->{$name}->{'2'}->{'roprequestsoutstanding'} = $process->{'ROPRequestsoutstanding'};
	$risc->{$name}->{'2'}->{'roprequestssent'} = $process->{'ROPRequestssent'};
	$risc->{$name}->{'2'}->{'rpcbytesreceived'} = $process->{'RPCBytesreceived'};
	$risc->{$name}->{'2'}->{'rpcbytesreceivedaverage'} = $process->{'RPCBytesreceivedaverage'};
	$risc->{$name}->{'2'}->{'rpcbytesreceivedaverage_base'} = $process->{'RPCBytesreceivedaverage_Base'};
	$risc->{$name}->{'2'}->{'rpcbytessent'} = $process->{'RPCBytessent'};
	$risc->{$name}->{'2'}->{'rpcbytessentaverage'} = $process->{'RPCBytessentaverage'};
	$risc->{$name}->{'2'}->{'rpcbytessentaverage_base'} = $process->{'RPCBytessentaverage_Base'};
	$risc->{$name}->{'2'}->{'rpclatencyaveragemsec'} = $process->{'RPCLatencyaveragemsec'};
	$risc->{$name}->{'2'}->{'rpclatencyaveragemsec_base'} = $process->{'RPCLatencyaveragemsec_Base'};
	$risc->{$name}->{'2'}->{'rpclatencytotalmsec'} = $process->{'RPCLatencytotalmsec'};
	$risc->{$name}->{'2'}->{'rpcpoolactivethreadsratio'} = $process->{'RPCPoolActiveThreadsRatio'};
	$risc->{$name}->{'2'}->{'rpcpoolactivethreadsratio_base'} = $process->{'RPCPoolActiveThreadsRatio_Base'};
	$risc->{$name}->{'2'}->{'rpcpoolasyncnotificationsreceivedpersec'} = $process->{'RPCPoolAsyncNotificationsReceivedPersec'};
	$risc->{$name}->{'2'}->{'rpcpoolaveragelatency'} = $process->{'RPCPoolAverageLatency'};
	$risc->{$name}->{'2'}->{'rpcpoolaveragelatency_base'} = $process->{'RPCPoolAverageLatency_Base'};
	$risc->{$name}->{'2'}->{'rpcpoolparkedasyncnotificationcalls'} = $process->{'RPCPoolParkedAsyncNotificationCalls'};
	$risc->{$name}->{'2'}->{'rpcpoolpools'} = $process->{'RPCPoolPools'};
	$risc->{$name}->{'2'}->{'rpcpoolrpccontexthandles'} = $process->{'RPCPoolRPCContextHandles'};
	$risc->{$name}->{'2'}->{'rpcpoolsessionnotificationsreceivedpersec'} = $process->{'RPCPoolSessionNotificationsReceivedPersec'};
	$risc->{$name}->{'2'}->{'rpcpoolsessions'} = $process->{'RPCPoolSessions'};
	$risc->{$name}->{'2'}->{'rpcrequestsfailed'} = $process->{'RPCRequestsfailed'};
	$risc->{$name}->{'2'}->{'rpcrequestsfailedpercent'} = $process->{'RPCRequestsfailedPercent'};
	$risc->{$name}->{'2'}->{'rpcrequestsfailedpercent_base'} = $process->{'RPCRequestsfailedPercent_Base'};
	$risc->{$name}->{'2'}->{'rpcrequestsfailedwithexception'} = $process->{'RPCRequestsfailedwithexception'};
	$risc->{$name}->{'2'}->{'rpcrequestsoutstanding'} = $process->{'RPCRequestsoutstanding'};
	$risc->{$name}->{'2'}->{'rpcrequestssent'} = $process->{'RPCRequestssent'};
	$risc->{$name}->{'2'}->{'rpcrequestssentpersec'} = $process->{'RPCRequestssentPersec'};
	$risc->{$name}->{'2'}->{'rpcrequestssucceeded'} = $process->{'RPCRequestssucceeded'};
	$risc->{$name}->{'2'}->{'rpcslowrequests'} = $process->{'RPCSlowrequests'};
	$risc->{$name}->{'2'}->{'rpcslowrequestslatencyaveragemsec'} = $process->{'RPCSlowrequestslatencyaveragemsec'};
	$risc->{$name}->{'2'}->{'rpcslowrequestslatencyaveragemsec_base'} = $process->{'RPCSlowrequestslatencyaveragemsec_Base'};
	$risc->{$name}->{'2'}->{'rpcslowrequestslatencytotalmsec'} = $process->{'RPCSlowrequestslatencytotalmsec'};
	$risc->{$name}->{'2'}->{'rpcslowrequestspercent'} = $process->{'RPCSlowrequestsPercent'};
	$risc->{$name}->{'2'}->{'rpcslowrequestspercent_base'} = $process->{'RPCSlowrequestsPercent_Base'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'unkfolders'} = $process->{'UNKFolders'};
	$risc->{$name}->{'2'}->{'unklogons'} = $process->{'UNKLogons'};
	$risc->{$name}->{'2'}->{'unkmessages'} = $process->{'UNKMessages'};
	$risc->{$name}->{'2'}->{'unkobjectstotal'} = $process->{'UNKObjectstotal'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";


	#---find ConnectionCacheactiveconnections---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$connectioncacheactiveconnections = $risc->{$calname}->{'2'}->{'connectioncacheactiveconnections'};
#	print "connectioncacheactiveconnections: $connectioncacheactiveconnections \n";


	#---find ConnectionCacheidleconnections---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$connectioncacheidleconnections = $risc->{$calname}->{'2'}->{'connectioncacheidleconnections'};
#	print "connectioncacheidleconnections: $connectioncacheidleconnections \n";


	#---find ConnectionCachenumcaches---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$connectioncachenumcaches = $risc->{$calname}->{'2'}->{'connectioncachenumcaches'};
#	print "connectioncachenumcaches: $connectioncachenumcaches \n";


	#---find ConnectionCacheoutoflimitcreations---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$connectioncacheoutoflimitcreations = $risc->{$calname}->{'2'}->{'connectioncacheoutoflimitcreations'};
#	print "connectioncacheoutoflimitcreations: $connectioncacheoutoflimitcreations \n";


	#---find ConnectionCachetotalcapacity---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$connectioncachetotalcapacity = $risc->{$calname}->{'2'}->{'connectioncachetotalcapacity'};
#	print "connectioncachetotalcapacity: $connectioncachetotalcapacity \n";


	#---find ExRpcConnectioncreationevents---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$exrpcconnectioncreationevents = $risc->{$calname}->{'2'}->{'exrpcconnectioncreationevents'};
#	print "exrpcconnectioncreationevents: $exrpcconnectioncreationevents \n";


	#---find ExRpcConnectiondisposalevents---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$exrpcconnectiondisposalevents = $risc->{$calname}->{'2'}->{'exrpcconnectiondisposalevents'};
#	print "exrpcconnectiondisposalevents: $exrpcconnectiondisposalevents \n";


	#---find ExRpcConnectionoutstanding---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$exrpcconnectionoutstanding = $risc->{$calname}->{'2'}->{'exrpcconnectionoutstanding'};
#	print "exrpcconnectionoutstanding: $exrpcconnectionoutstanding \n";


	#---find ROPRequestscomplete---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$roprequestscomplete = $risc->{$calname}->{'2'}->{'roprequestscomplete'};
#	print "roprequestscomplete: $roprequestscomplete \n";


	#---find ROPRequestsoutstanding---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$roprequestsoutstanding = $risc->{$calname}->{'2'}->{'roprequestsoutstanding'};
#	print "roprequestsoutstanding: $roprequestsoutstanding \n";


	#---find ROPRequestssent---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$roprequestssent = $risc->{$calname}->{'2'}->{'roprequestssent'};
#	print "roprequestssent: $roprequestssent \n";


	#---find RPCBytesreceived---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcbytesreceived = $risc->{$calname}->{'2'}->{'rpcbytesreceived'};
#	print "rpcbytesreceived: $rpcbytesreceived \n";


	#---find RPCBytesreceivedaverage---#	
	my $rpcbytesreceivedaverage2 = $risc->{$calname}->{'2'}->{'rpcbytesreceivedaverage'};	
#	print "rpcbytesreceivedaverage2: $rpcbytesreceivedaverage2 \n";	
	my $rpcbytesreceivedaverage_base2 = $risc->{$calname}->{'2'}->{'rpcbytesreceivedaverage_base'};	
#	print "rpcbytesreceivedaverage_base2: $rpcbytesreceivedaverage_base2\n";	
	eval 	
	{	
	$rpcbytesreceivedaverage = PERF_RAW_FRACTION(	
		$rpcbytesreceivedaverage2 #c2
		,$rpcbytesreceivedaverage_base2); #base counter value 2
	};	
#	print "rpcbytesreceivedaverage: $rpcbytesreceivedaverage \n";	


	#---find RPCBytessent---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcbytessent = $risc->{$calname}->{'2'}->{'rpcbytessent'};
#	print "rpcbytessent: $rpcbytessent \n";


	#---find RPCBytessentaverage---#	
	my $rpcbytessentaverage2 = $risc->{$calname}->{'2'}->{'rpcbytessentaverage'};	
#	print "rpcbytessentaverage2: $rpcbytessentaverage2 \n";	
	my $rpcbytessentaverage_base2 = $risc->{$calname}->{'2'}->{'rpcbytessentaverage_base'};	
#	print "rpcbytessentaverage_base2: $rpcbytessentaverage_base2\n";	
	eval 	
	{	
	$rpcbytessentaverage = PERF_RAW_FRACTION(	
		$rpcbytessentaverage2 #c2
		,$rpcbytessentaverage_base2); #base counter value 2
	};	
#	print "rpcbytessentaverage: $rpcbytessentaverage \n";	


	#---find RPCLatencyaveragemsec---#	
	my $rpclatencyaveragemsec1 = $risc->{$calname}->{'1'}->{'rpclatencyaveragemsec'};	
#	print "rpclatencyaveragemsec1: $rpclatencyaveragemsec1 \n";	
	my $rpclatencyaveragemsec2 = $risc->{$calname}->{'2'}->{'rpclatencyaveragemsec'};	
#	print "rpclatencyaveragemsec2: $rpclatencyaveragemsec2 \n";	
	my $rpclatencyaveragemsec_base1 = $risc->{$calname}->{'1'}->{'rpclatencyaveragemsec_base'};	
#	print "rpclatencyaveragemsec_base1: $rpclatencyaveragemsec_base1\n";	
	my $rpclatencyaveragemsec_base2 = $risc->{$calname}->{'2'}->{'rpclatencyaveragemsec_base'};	
#	print "rpclatencyaveragemsec_base2: $rpclatencyaveragemsec_base2\n";	
	eval 	
	{	
	$rpclatencyaveragemsec = PERF_AVERAGE_BULK(	
		$rpclatencyaveragemsec1 #counter value 1
		,$rpclatencyaveragemsec2 #counter value 2
		,$rpclatencyaveragemsec_base1 #base counter value 1
		,$rpclatencyaveragemsec_base2); #base counter value 2
	};	
#	print "rpclatencyaveragemsec: $rpclatencyaveragemsec \n";	


	#---find RPCLatencytotalmsec---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpclatencytotalmsec = $risc->{$calname}->{'2'}->{'rpclatencytotalmsec'};
#	print "rpclatencytotalmsec: $rpclatencytotalmsec \n";


	#---find RPCPoolActiveThreadsRatio---#	
	my $rpcpoolactivethreadsratio2 = $risc->{$calname}->{'2'}->{'rpcpoolactivethreadsratio'};	
#	print "rpcpoolactivethreadsratio2: $rpcpoolactivethreadsratio2 \n";	
	my $rpcpoolactivethreadsratio_base2 = $risc->{$calname}->{'2'}->{'rpcpoolactivethreadsratio_base'};	
#	print "rpcpoolactivethreadsratio_base2: $rpcpoolactivethreadsratio_base2\n";	
	eval 	
	{	
	$rpcpoolactivethreadsratio = PERF_RAW_FRACTION(	
		$rpcpoolactivethreadsratio2 #counter value 2
		,$rpcpoolactivethreadsratio_base2); #base counter value 2
	};	
#	print "rpcpoolactivethreadsratio: $rpcpoolactivethreadsratio \n";	


	#---find RPCPoolAsyncNotificationsReceivedPersec---#	
	my $rpcpoolasyncnotificationsreceivedpersec1 = $risc->{$calname}->{'1'}->{'rpcpoolasyncnotificationsreceivedpersec'};	
#	print "rpcpoolasyncnotificationsreceivedpersec1: $rpcpoolasyncnotificationsreceivedpersec1 \n";	
	my $rpcpoolasyncnotificationsreceivedpersec2 = $risc->{$calname}->{'2'}->{'rpcpoolasyncnotificationsreceivedpersec'};	
#	print "rpcpoolasyncnotificationsreceivedpersec2: $rpcpoolasyncnotificationsreceivedpersec2 \n";	
	eval 	
	{	
	$rpcpoolasyncnotificationsreceivedpersec = perf_counter_counter(	
		$rpcpoolasyncnotificationsreceivedpersec1 #c1
		,$rpcpoolasyncnotificationsreceivedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "rpcpoolasyncnotificationsreceivedpersec: $rpcpoolasyncnotificationsreceivedpersec \n";	


	#---find RPCPoolAverageLatency---#	
	my $rpcpoolaveragelatency1 = $risc->{$calname}->{'1'}->{'rpcpoolaveragelatency'};	
#	print "rpcpoolaveragelatency1: $rpcpoolaveragelatency1 \n";	
	my $rpcpoolaveragelatency2 = $risc->{$calname}->{'2'}->{'rpcpoolaveragelatency'};	
#	print "rpcpoolaveragelatency2: $rpcpoolaveragelatency2 \n";	
	my $rpcpoolaveragelatency_base1 = $risc->{$calname}->{'1'}->{'rpcpoolaveragelatency_base'};	
#	print "rpcpoolaveragelatency_base1: $rpcpoolaveragelatency_base1\n";	
	my $rpcpoolaveragelatency_base2 = $risc->{$calname}->{'2'}->{'rpcpoolaveragelatency_base'};	
#	print "rpcpoolaveragelatency_base2: $rpcpoolaveragelatency_base2\n";	
	eval 	
	{	
	$rpcpoolaveragelatency = PERF_AVERAGE_BULK(	
		$rpcpoolaveragelatency1 #counter value 1
		,$rpcpoolaveragelatency2 #counter value 2
		,$rpcpoolaveragelatency_base1 #base counter value 1
		,$rpcpoolaveragelatency_base2); #base counter value 2
	};	
#	print "rpcpoolaveragelatency: $rpcpoolaveragelatency \n";	


	#---find RPCPoolParkedAsyncNotificationCalls---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolparkedasyncnotificationcalls = $risc->{$calname}->{'2'}->{'rpcpoolparkedasyncnotificationcalls'};
#	print "rpcpoolparkedasyncnotificationcalls: $rpcpoolparkedasyncnotificationcalls \n";


	#---find RPCPoolPools---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolpools = $risc->{$calname}->{'2'}->{'rpcpoolpools'};
#	print "rpcpoolpools: $rpcpoolpools \n";


	#---find RPCPoolRPCContextHandles---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolrpccontexthandles = $risc->{$calname}->{'2'}->{'rpcpoolrpccontexthandles'};
#	print "rpcpoolrpccontexthandles: $rpcpoolrpccontexthandles \n";


	#---find RPCPoolSessionNotificationsReceivedPersec---#	
	my $rpcpoolsessionnotificationsreceivedpersec1 = $risc->{$calname}->{'1'}->{'rpcpoolsessionnotificationsreceivedpersec'};	
#	print "rpcpoolsessionnotificationsreceivedpersec1: $rpcpoolsessionnotificationsreceivedpersec1 \n";	
	my $rpcpoolsessionnotificationsreceivedpersec2 = $risc->{$calname}->{'2'}->{'rpcpoolsessionnotificationsreceivedpersec'};	
#	print "rpcpoolsessionnotificationsreceivedpersec2: $rpcpoolsessionnotificationsreceivedpersec2 \n";	
	eval 	
	{	
	$rpcpoolsessionnotificationsreceivedpersec = perf_counter_counter(	
		$rpcpoolsessionnotificationsreceivedpersec1 #c1
		,$rpcpoolsessionnotificationsreceivedpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "rpcpoolsessionnotificationsreceivedpersec: $rpcpoolsessionnotificationsreceivedpersec \n";	


	#---find RPCPoolSessions---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcpoolsessions = $risc->{$calname}->{'2'}->{'rpcpoolsessions'};
#	print "rpcpoolsessions: $rpcpoolsessions \n";


	#---find RPCRequestsfailed---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestsfailed = $risc->{$calname}->{'2'}->{'rpcrequestsfailed'};
#	print "rpcrequestsfailed: $rpcrequestsfailed \n";


	#---find RPCRequestsfailedPercent---#	
	my $rpcrequestsfailedpercent2 = $risc->{$calname}->{'2'}->{'rpcrequestsfailedpercent'};	
#	print "rpcrequestsfailedpercent2: $rpcrequestsfailedpercent2 \n";	
	my $rpcrequestsfailedpercent_base2 = $risc->{$calname}->{'2'}->{'rpcrequestsfailedpercent_base'};	
#	print "rpcrequestsfailedpercent_base2: $rpcrequestsfailedpercent_base2\n";	
	eval 	
	{	
	$rpcrequestsfailedpercent = PERF_RAW_FRACTION(	
		$rpcrequestsfailedpercent2 #counter value 2
		,$rpcrequestsfailedpercent_base2); #base counter value 2
	};	
#	print "rpcrequestsfailedpercent: $rpcrequestsfailedpercent \n";	


	#---find RPCRequestsfailedwithexception---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestsfailedwithexception = $risc->{$calname}->{'2'}->{'rpcrequestsfailedwithexception'};
#	print "rpcrequestsfailedwithexception: $rpcrequestsfailedwithexception \n";


	#---find RPCRequestsoutstanding---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestsoutstanding = $risc->{$calname}->{'2'}->{'rpcrequestsoutstanding'};
#	print "rpcrequestsoutstanding: $rpcrequestsoutstanding \n";


	#---find RPCRequestssent---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestssent = $risc->{$calname}->{'2'}->{'rpcrequestssent'};
#	print "rpcrequestssent: $rpcrequestssent \n";


	#---find RPCRequestssentPersec---#	
	my $rpcrequestssentpersec1 = $risc->{$calname}->{'1'}->{'rpcrequestssentpersec'};	
#	print "rpcrequestssentpersec1: $rpcrequestssentpersec1 \n";	
	my $rpcrequestssentpersec2 = $risc->{$calname}->{'2'}->{'rpcrequestssentpersec'};	
#	print "rpcrequestssentpersec2: $rpcrequestssentpersec2 \n";	
	eval 	
	{	
	$rpcrequestssentpersec = perf_counter_counter(	
		$rpcrequestssentpersec1 #c1
		,$rpcrequestssentpersec2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "rpcrequestssentpersec: $rpcrequestssentpersec \n";	


	#---find RPCRequestssucceeded---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcrequestssucceeded = $risc->{$calname}->{'2'}->{'rpcrequestssucceeded'};
#	print "rpcrequestssucceeded: $rpcrequestssucceeded \n";


	#---find RPCSlowrequests---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$rpcslowrequests = $risc->{$calname}->{'2'}->{'rpcslowrequests'};
#	print "rpcslowrequests: $rpcslowrequests \n";


	#---find RPCSlowrequestslatencyaveragemsec---#	
	my $rpcslowrequestslatencyaveragemsec1 = $risc->{$calname}->{'1'}->{'rpcslowrequestslatencyaveragemsec'};	
#	print "rpcslowrequestslatencyaveragemsec1: $rpcslowrequestslatencyaveragemsec1 \n";	
	my $rpcslowrequestslatencyaveragemsec2 = $risc->{$calname}->{'2'}->{'rpcslowrequestslatencyaveragemsec'};	
#	print "rpcslowrequestslatencyaveragemsec2: $rpcslowrequestslatencyaveragemsec2 \n";	
	my $rpcslowrequestslatencyaveragemsec_base1 = $risc->{$calname}->{'1'}->{'rpcslowrequestslatencyaveragemsec_base'};	
#	print "rpcslowrequestslatencyaveragemsec_base1: $rpcslowrequestslatencyaveragemsec_base1\n";	
	my $rpcslowrequestslatencyaveragemsec_base2 = $risc->{$calname}->{'2'}->{'rpcslowrequestslatencyaveragemsec_base'};	
#	print "rpcslowrequestslatencyaveragemsec_base2: $rpcslowrequestslatencyaveragemsec_base2\n";	
	eval 	
	{	
	$rpcslowrequestslatencyaveragemsec = PERF_AVERAGE_BULK(	
		$rpcslowrequestslatencyaveragemsec1 #counter value 1
		,$rpcslowrequestslatencyaveragemsec2 #counter value 2
		,$rpcslowrequestslatencyaveragemsec_base1 #base counter value 1
		,$rpcslowrequestslatencyaveragemsec_base2); #base counter value 2
	};	
#	print "rpcslowrequestslatencyaveragemsec: $rpcslowrequestslatencyaveragemsec \n";	


	#---find RPCSlowrequestslatencytotalmsec---#
	#The formular is PERF_COUNTER_LARGE_RAWCOUNT = None. Shows raw data as collected.
	$rpcslowrequestslatencytotalmsec = $risc->{$calname}->{'2'}->{'rpcslowrequestslatencytotalmsec'};
#	print "rpcslowrequestslatencytotalmsec: $rpcslowrequestslatencytotalmsec \n";


	#---find RPCSlowrequestsPercent---#	
	my $rpcslowrequestspercent2 = $risc->{$calname}->{'2'}->{'rpcslowrequestspercent'};	
#	print "rpcslowrequestspercent2: $rpcslowrequestspercent2 \n";	
	my $rpcslowrequestspercent_base2 = $risc->{$calname}->{'2'}->{'rpcslowrequestspercent_base'};	
#	print "rpcslowrequestspercent_base2: $rpcslowrequestspercent_base2\n";	
	eval 	
	{	
	$rpcslowrequestspercent = PERF_RAW_FRACTION(	
		$rpcslowrequestspercent2 #counter value 2
		,$rpcslowrequestspercent_base2); #base counter value 2
	};	
#	print "rpcslowrequestspercent: $rpcslowrequestspercent \n";	


	#---find UNKFolders---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$unkfolders = $risc->{$calname}->{'2'}->{'unkfolders'};
#	print "unkfolders: $unkfolders \n";


	#---find UNKLogons---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$unklogons = $risc->{$calname}->{'2'}->{'unklogons'};
#	print "unklogons: $unklogons \n";


	#---find UNKMessages---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$unkmessages = $risc->{$calname}->{'2'}->{'unkmessages'};
#	print "unkmessages: $unkmessages \n";


	#---find UNKObjectstotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$unkobjectstotal = $risc->{$calname}->{'2'}->{'unkobjectstotal'};
#	print "unkobjectstotal: $unkobjectstotal \n";

#####################################
													
	#---add data to the table---#
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$caption
	,$connectioncacheactiveconnections
	,$connectioncacheidleconnections
	,$connectioncachenumcaches
	,$connectioncacheoutoflimitcreations
	,$connectioncachetotalcapacity
	,$description
	,$exrpcconnectioncreationevents
	,$exrpcconnectiondisposalevents
	,$exrpcconnectionoutstanding
	,$tablename
	,$roprequestscomplete
	,$roprequestsoutstanding
	,$roprequestssent
	,$rpcbytesreceived
	,$rpcbytesreceivedaverage
	,$rpcbytessent
	,$rpcbytessentaverage
	,$rpclatencyaveragemsec
	,$rpclatencytotalmsec
	,$rpcpoolactivethreadsratio
	,$rpcpoolasyncnotificationsreceivedpersec
	,$rpcpoolaveragelatency
	,$rpcpoolparkedasyncnotificationcalls
	,$rpcpoolpools
	,$rpcpoolrpccontexthandles
	,$rpcpoolsessionnotificationsreceivedpersec
	,$rpcpoolsessions
	,$rpcrequestsfailed
	,$rpcrequestsfailedpercent
	,$rpcrequestsfailedwithexception
	,$rpcrequestsoutstanding
	,$rpcrequestssent
	,$rpcrequestssentpersec
	,$rpcrequestssucceeded
	,$rpcslowrequests
	,$rpcslowrequestslatencyaveragemsec
	,$rpcslowrequestslatencytotalmsec
	,$rpcslowrequestspercent
	,$unkfolders
	,$unklogons
	,$unkmessages
	,$unkobjectstotal
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeTransportQueues
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchtranque (
	deviceid
	,scantime
	,activemailboxdeliveryqueuelength
	,activenonsmtpdeliveryqueuelength
	,activeremotedeliveryqueuelength
	,aggregatedeliveryqueuelengthallqueues
	,aggregateshadowqueuelength
	,caption
	,categorizerjobavailability
	,description
	,itemscompleteddeliverypersecond
	,itemscompleteddeliverytotal
	,itemsdeletedbyadmintotal
	,itemsqueuedfordeliveryexpiredtotal
	,itemsqueuedfordeliverypersecond
	,itemsqueuedfordeliverytotal
	,itemsresubmittedtotal
	,largestdeliveryqueuelength
	,messagescompleteddeliverypersecond
	,messagescompleteddeliverytotal
	,messagescompletingcategorization
	,messagesdeferredduringcategorization
	,messagesqueuedfordelivery
	,messagesqueuedfordeliverypersecond
	,messagesqueuedfordeliverytotal
	,messagessubmittedpersecond
	,messagessubmittedtotal
	,name
	,poisonqueuelength
	,retrymailboxdeliveryqueuelength
	,retrynonsmtpdeliveryqueuelength
	,retryremotedeliveryqueuelength
	,shadowqueueautodiscardstotal
	,submissionqueueitemsexpiredtotal
	,submissionqueuelength
	,unreachablequeuelength
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $activemailboxdeliveryqueuelength = undef;
my $activenonsmtpdeliveryqueuelength = undef;
my $activeremotedeliveryqueuelength = undef;
my $aggregatedeliveryqueuelengthallqueues = undef;
my $aggregateshadowqueuelength = undef;
my $caption = undef;
my $categorizerjobavailability = undef;
my $description = undef;
my $itemscompleteddeliverypersecond = undef;
my $itemscompleteddeliverytotal = undef;
my $itemsdeletedbyadmintotal = undef;
my $itemsqueuedfordeliveryexpiredtotal = undef;
my $itemsqueuedfordeliverypersecond = undef;
my $itemsqueuedfordeliverytotal = undef;
my $itemsresubmittedtotal = undef;
my $largestdeliveryqueuelength = undef;
my $messagescompleteddeliverypersecond = undef;
my $messagescompleteddeliverytotal = undef;
my $messagescompletingcategorization = undef;
my $messagesdeferredduringcategorization = undef;
my $messagesqueuedfordelivery = undef;
my $messagesqueuedfordeliverypersecond = undef;
my $messagesqueuedfordeliverytotal = undef;
my $messagessubmittedpersecond = undef;
my $messagessubmittedtotal = undef;
my $tablename = undef;
my $poisonqueuelength = undef;
my $retrymailboxdeliveryqueuelength = undef;
my $retrynonsmtpdeliveryqueuelength = undef;
my $retryremotedeliveryqueuelength = undef;
my $shadowqueueautodiscardstotal = undef;
my $submissionqueueitemsexpiredtotal = undef;
my $submissionqueuelength = undef;
my $unreachablequeuelength = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach  my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'1'}->{'activemailboxdeliveryqueuelength'} = $process->{'ActiveMailboxDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'activenonsmtpdeliveryqueuelength'} = $process->{'ActiveNonSmtpDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'activeremotedeliveryqueuelength'} = $process->{'ActiveRemoteDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'aggregatedeliveryqueuelengthallqueues'} = $process->{'AggregateDeliveryQueueLengthAllQueues'};
	$risc->{$name}->{'1'}->{'aggregateshadowqueuelength'} = $process->{'AggregateShadowQueueLength'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'categorizerjobavailability'} = $process->{'CategorizerJobAvailability'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'itemscompleteddeliverypersecond'} = $process->{'ItemsCompletedDeliveryPerSecond'};
	$risc->{$name}->{'1'}->{'itemscompleteddeliverytotal'} = $process->{'ItemsCompletedDeliveryTotal'};
	$risc->{$name}->{'1'}->{'itemsdeletedbyadmintotal'} = $process->{'ItemsDeletedByAdminTotal'};
	$risc->{$name}->{'1'}->{'itemsqueuedfordeliveryexpiredtotal'} = $process->{'ItemsQueuedForDeliveryExpiredTotal'};
	$risc->{$name}->{'1'}->{'itemsqueuedfordeliverypersecond'} = $process->{'ItemsQueuedforDeliveryPerSecond'};
	$risc->{$name}->{'1'}->{'itemsqueuedfordeliverytotal'} = $process->{'ItemsQueuedForDeliveryTotal'};
	$risc->{$name}->{'1'}->{'itemsresubmittedtotal'} = $process->{'ItemsResubmittedTotal'};
	$risc->{$name}->{'1'}->{'largestdeliveryqueuelength'} = $process->{'LargestDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'messagescompleteddeliverypersecond'} = $process->{'MessagesCompletedDeliveryPerSecond'};
	$risc->{$name}->{'1'}->{'messagescompleteddeliverytotal'} = $process->{'MessagesCompletedDeliveryTotal'};
	$risc->{$name}->{'1'}->{'messagescompletingcategorization'} = $process->{'MessagesCompletingCategorization'};
	$risc->{$name}->{'1'}->{'messagesdeferredduringcategorization'} = $process->{'MessagesDeferredduringCategorization'};
	$risc->{$name}->{'1'}->{'messagesqueuedfordelivery'} = $process->{'MessagesQueuedForDelivery'};
	$risc->{$name}->{'1'}->{'messagesqueuedfordeliverypersecond'} = $process->{'MessagesQueuedforDeliveryPerSecond'};
	$risc->{$name}->{'1'}->{'messagesqueuedfordeliverytotal'} = $process->{'MessagesQueuedForDeliveryTotal'};
	$risc->{$name}->{'1'}->{'messagessubmittedpersecond'} = $process->{'MessagesSubmittedPerSecond'};
	$risc->{$name}->{'1'}->{'messagessubmittedtotal'} = $process->{'MessagesSubmittedTotal'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'poisonqueuelength'} = $process->{'PoisonQueueLength'};
	$risc->{$name}->{'1'}->{'retrymailboxdeliveryqueuelength'} = $process->{'RetryMailboxDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'retrynonsmtpdeliveryqueuelength'} = $process->{'RetryNonSmtpDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'retryremotedeliveryqueuelength'} = $process->{'RetryRemoteDeliveryQueueLength'};
	$risc->{$name}->{'1'}->{'shadowqueueautodiscardstotal'} = $process->{'ShadowQueueAutoDiscardsTotal'};
	$risc->{$name}->{'1'}->{'submissionqueueitemsexpiredtotal'} = $process->{'SubmissionQueueItemsExpiredTotal'};
	$risc->{$name}->{'1'}->{'submissionqueuelength'} = $process->{'SubmissionQueueLength'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'unreachablequeuelength'} = $process->{'UnreachableQueueLength'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};
	
	$risc->{$name}->{'2'}->{'activemailboxdeliveryqueuelength'} = $process->{'ActiveMailboxDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'activenonsmtpdeliveryqueuelength'} = $process->{'ActiveNonSmtpDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'activeremotedeliveryqueuelength'} = $process->{'ActiveRemoteDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'aggregatedeliveryqueuelengthallqueues'} = $process->{'AggregateDeliveryQueueLengthAllQueues'};
	$risc->{$name}->{'2'}->{'aggregateshadowqueuelength'} = $process->{'AggregateShadowQueueLength'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'categorizerjobavailability'} = $process->{'CategorizerJobAvailability'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'itemscompleteddeliverypersecond'} = $process->{'ItemsCompletedDeliveryPerSecond'};
	$risc->{$name}->{'2'}->{'itemscompleteddeliverytotal'} = $process->{'ItemsCompletedDeliveryTotal'};
	$risc->{$name}->{'2'}->{'itemsdeletedbyadmintotal'} = $process->{'ItemsDeletedByAdminTotal'};
	$risc->{$name}->{'2'}->{'itemsqueuedfordeliveryexpiredtotal'} = $process->{'ItemsQueuedForDeliveryExpiredTotal'};
	$risc->{$name}->{'2'}->{'itemsqueuedfordeliverypersecond'} = $process->{'ItemsQueuedforDeliveryPerSecond'};
	$risc->{$name}->{'2'}->{'itemsqueuedfordeliverytotal'} = $process->{'ItemsQueuedForDeliveryTotal'};
	$risc->{$name}->{'2'}->{'itemsresubmittedtotal'} = $process->{'ItemsResubmittedTotal'};
	$risc->{$name}->{'2'}->{'largestdeliveryqueuelength'} = $process->{'LargestDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'messagescompleteddeliverypersecond'} = $process->{'MessagesCompletedDeliveryPerSecond'};
	$risc->{$name}->{'2'}->{'messagescompleteddeliverytotal'} = $process->{'MessagesCompletedDeliveryTotal'};
	$risc->{$name}->{'2'}->{'messagescompletingcategorization'} = $process->{'MessagesCompletingCategorization'};
	$risc->{$name}->{'2'}->{'messagesdeferredduringcategorization'} = $process->{'MessagesDeferredduringCategorization'};
	$risc->{$name}->{'2'}->{'messagesqueuedfordelivery'} = $process->{'MessagesQueuedForDelivery'};
	$risc->{$name}->{'2'}->{'messagesqueuedfordeliverypersecond'} = $process->{'MessagesQueuedforDeliveryPerSecond'};
	$risc->{$name}->{'2'}->{'messagesqueuedfordeliverytotal'} = $process->{'MessagesQueuedForDeliveryTotal'};
	$risc->{$name}->{'2'}->{'messagessubmittedpersecond'} = $process->{'MessagesSubmittedPerSecond'};
	$risc->{$name}->{'2'}->{'messagessubmittedtotal'} = $process->{'MessagesSubmittedTotal'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'poisonqueuelength'} = $process->{'PoisonQueueLength'};
	$risc->{$name}->{'2'}->{'retrymailboxdeliveryqueuelength'} = $process->{'RetryMailboxDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'retrynonsmtpdeliveryqueuelength'} = $process->{'RetryNonSmtpDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'retryremotedeliveryqueuelength'} = $process->{'RetryRemoteDeliveryQueueLength'};
	$risc->{$name}->{'2'}->{'shadowqueueautodiscardstotal'} = $process->{'ShadowQueueAutoDiscardsTotal'};
	$risc->{$name}->{'2'}->{'submissionqueueitemsexpiredtotal'} = $process->{'SubmissionQueueItemsExpiredTotal'};
	$risc->{$name}->{'2'}->{'submissionqueuelength'} = $process->{'SubmissionQueueLength'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'unreachablequeuelength'} = $process->{'UnreachableQueueLength'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$tablename = $risc->{$calname}->{'2'}->{'name'};

	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
#	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";


	#---find ActiveMailboxDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$activemailboxdeliveryqueuelength = $risc->{$calname}->{'2'}->{'activemailboxdeliveryqueuelength'};
#	print "activemailboxdeliveryqueuelength: $activemailboxdeliveryqueuelength\n";


	#---find ActiveNonSmtpDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$activenonsmtpdeliveryqueuelength = $risc->{$calname}->{'2'}->{'activenonsmtpdeliveryqueuelength'};
#	print "activenonsmtpdeliveryqueuelength: $activenonsmtpdeliveryqueuelength\n";


	#---find ActiveRemoteDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$activeremotedeliveryqueuelength = $risc->{$calname}->{'2'}->{'activeremotedeliveryqueuelength'};
#	print "activeremotedeliveryqueuelength: $activeremotedeliveryqueuelength\n";


	#---find AggregateDeliveryQueueLengthAllQueues---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$aggregatedeliveryqueuelengthallqueues = $risc->{$calname}->{'2'}->{'aggregatedeliveryqueuelengthallqueues'};
#	print "aggregatedeliveryqueuelengthallqueues: $aggregatedeliveryqueuelengthallqueues\n";


	#---find AggregateShadowQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$aggregateshadowqueuelength = $risc->{$calname}->{'2'}->{'aggregateshadowqueuelength'};
#	print "aggregateshadowqueuelength : $aggregateshadowqueuelength \n";


	#---find CategorizerJobAvailability---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$categorizerjobavailability = $risc->{$calname}->{'2'}->{'categorizerjobavailability'};
#	print "categorizerjobavailability: $categorizerjobavailability\n";


	#---find ItemsCompletedDeliveryPerSecond---#
	my $itemscompleteddeliverypersecond1 = $risc->{$calname}->{'1'}->{'itemscompleteddeliverypersecond'};
#	print "itemscompleteddeliverypersecond1: $itemscompleteddeliverypersecond1\n";		
	my $itemscompleteddeliverypersecond2 = $risc->{$calname}->{'2'}->{'itemscompleteddeliverypersecond'};
#	print "itemscompleteddeliverypersecond2: $itemscompleteddeliverypersecond2\n";		
	eval 		
	{		
	$itemscompleteddeliverypersecond = perf_counter_counter(	
		$itemscompleteddeliverypersecond1 #c1
		,$itemscompleteddeliverypersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};
#	print "itemscompleteddeliverypersecond: $itemscompleteddeliverypersecond \n";

	
	#---find ItemsCompletedDeliveryTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$itemscompleteddeliverytotal = $risc->{$calname}->{'2'}->{'itemscompleteddeliverytotal'};
#	print "itemscompleteddeliverytotal: $itemscompleteddeliverytotal\n";

	
	#---find ItemsDeletedByAdminTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$itemsdeletedbyadmintotal = $risc->{$calname}->{'2'}->{'itemsdeletedbyadmintotal'};
#	print "itemsdeletedbyadmintotal: $itemsdeletedbyadmintotal\n";


	#---find ItemsQueuedForDeliveryExpiredTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$itemsqueuedfordeliveryexpiredtotal = $risc->{$calname}->{'2'}->{'itemsqueuedfordeliveryexpiredtotal'};
#	print "itemsqueuedfordeliveryexpiredtotal: $itemsqueuedfordeliveryexpiredtotal\n";


	#---find ItemsQueuedforDeliveryPerSecond---#	
	my $itemsqueuedfordeliverypersecond1 = $risc->{$calname}->{'1'}->{'itemsqueuedfordeliverypersecond'};	
#	print "itemsqueuedfordeliverypersecond1: $itemsqueuedfordeliverypersecond1 \n";	
	my $itemsqueuedfordeliverypersecond2 = $risc->{$calname}->{'2'}->{'itemsqueuedfordeliverypersecond'};	
#	print "itemsqueuedfordeliverypersecond2: $itemsqueuedfordeliverypersecond2 \n";	
	eval 	
	{	
	$itemsqueuedfordeliverypersecond = perf_counter_counter(	
		$itemsqueuedfordeliverypersecond1 #c1
		,$itemsqueuedfordeliverypersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "itemsqueuedfordeliverypersecond: $itemsqueuedfordeliverypersecond \n";	

	
	#---find ItemsQueuedForDeliveryTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$itemsqueuedfordeliverytotal = $risc->{$calname}->{'2'}->{'itemsqueuedfordeliverytotal'};
#	print "itemsqueuedfordeliverytotal: $itemsqueuedfordeliverytotal \n";

	
	#---find ItemsResubmittedTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$itemsresubmittedtotal = $risc->{$calname}->{'2'}->{'itemsresubmittedtotal'};
#	print "itemsresubmittedtotal: $itemsresubmittedtotal \n";

	
	#---find LargestDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$largestdeliveryqueuelength = $risc->{$calname}->{'2'}->{'largestdeliveryqueuelength'};
#	print "largestdeliveryqueuelength: $largestdeliveryqueuelength \n";

	
	#---find MessagesCompletedDeliveryPerSecond---#	
	my $messagescompleteddeliverypersecond1 = $risc->{$calname}->{'1'}->{'messagescompleteddeliverypersecond'};	
#	print "messagescompleteddeliverypersecond1: $messagescompleteddeliverypersecond1 \n";	
	my $messagescompleteddeliverypersecond2 = $risc->{$calname}->{'2'}->{'messagescompleteddeliverypersecond'};	
#	print "messagescompleteddeliverypersecond2: $messagescompleteddeliverypersecond2 \n";	
	eval 	
	{	
	$messagescompleteddeliverypersecond = perf_counter_counter(	
		$messagescompleteddeliverypersecond1 #c1
		,$messagescompleteddeliverypersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "messagescompleteddeliverypersecond: $messagescompleteddeliverypersecond \n";	


	#---find MessagesCompletedDeliveryTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagescompleteddeliverytotal = $risc->{$calname}->{'2'}->{'messagescompleteddeliverytotal'};
#	print "messagescompleteddeliverytotal: $messagescompleteddeliverytotal \n";


	#---find MessagesCompletingCategorization---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagescompletingcategorization = $risc->{$calname}->{'2'}->{'messagescompletingcategorization'};
#	print "messagescompletingcategorization: $messagescompletingcategorization \n";


	#---find MessagesDeferredduringCategorization---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagesdeferredduringcategorization = $risc->{$calname}->{'2'}->{'messagesdeferredduringcategorization'};
#	print "messagesdeferredduringcategorization: $messagesdeferredduringcategorization \n";


	#---find MessagesQueuedForDelivery---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagesqueuedfordelivery = $risc->{$calname}->{'2'}->{'messagesqueuedfordelivery'};
#	print "messagesqueuedfordelivery: $messagesqueuedfordelivery \n";


	#---find MessagesQueuedforDeliveryPerSecond---#	
	my $messagesqueuedfordeliverypersecond1 = $risc->{$calname}->{'1'}->{'messagesqueuedfordeliverypersecond'};	
#	print "messagesqueuedfordeliverypersecond1: $messagesqueuedfordeliverypersecond1 \n";	
	my $messagesqueuedfordeliverypersecond2 = $risc->{$calname}->{'2'}->{'messagesqueuedfordeliverypersecond'};	
#	print "messagesqueuedfordeliverypersecond2: $messagesqueuedfordeliverypersecond2 \n";	
	eval 	
	{	
	$messagesqueuedfordeliverypersecond = perf_counter_counter(	
		$messagesqueuedfordeliverypersecond1 #c1
		,$messagesqueuedfordeliverypersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "messagesqueuedfordeliverypersecond: $messagesqueuedfordeliverypersecond \n";	


	#---find MessagesQueuedForDeliveryTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagesqueuedfordeliverytotal = $risc->{$calname}->{'2'}->{'messagesqueuedfordeliverytotal'};
#	print "messagesqueuedfordeliverytotal: $messagesqueuedfordeliverytotal \n";


	#---find MessagesSubmittedPerSecond---#	
	my $messagessubmittedpersecond1 = $risc->{$calname}->{'1'}->{'messagessubmittedpersecond'};	
#	print "messagessubmittedpersecond1: $messagessubmittedpersecond1 \n";	
	my $messagessubmittedpersecond2 = $risc->{$calname}->{'2'}->{'messagessubmittedpersecond'};	
#	print "messagessubmittedpersecond2: $messagessubmittedpersecond2 \n";	
	eval 	
	{	
	$messagessubmittedpersecond = perf_counter_counter(	
		$messagessubmittedpersecond1 #c1
		,$messagessubmittedpersecond2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "messagessubmittedpersecond: $messagessubmittedpersecond \n";	


	#---find MessagesSubmittedTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$messagessubmittedtotal = $risc->{$calname}->{'2'}->{'messagessubmittedtotal'};
#	print "messagessubmittedtotal: $messagessubmittedtotal \n";


	#---find PoisonQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$poisonqueuelength = $risc->{$calname}->{'2'}->{'poisonqueuelength'};
#	print "poisonqueuelength: $poisonqueuelength \n";


	#---find RetryMailboxDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$retrymailboxdeliveryqueuelength = $risc->{$calname}->{'2'}->{'retrymailboxdeliveryqueuelength'};
#	print "retrymailboxdeliveryqueuelength: $retrymailboxdeliveryqueuelength \n";


	#---find RetryNonSmtpDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$retrynonsmtpdeliveryqueuelength = $risc->{$calname}->{'2'}->{'retrynonsmtpdeliveryqueuelength'};
#	print "retrynonsmtpdeliveryqueuelength: $retrynonsmtpdeliveryqueuelength \n";


	#---find RetryRemoteDeliveryQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$retryremotedeliveryqueuelength = $risc->{$calname}->{'2'}->{'retryremotedeliveryqueuelength'};
#	print "retryremotedeliveryqueuelength: $retryremotedeliveryqueuelength \n";


	#---find ShadowQueueAutoDiscardsTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$shadowqueueautodiscardstotal = $risc->{$calname}->{'2'}->{'shadowqueueautodiscardstotal'};
#	print "shadowqueueautodiscardstotal: $shadowqueueautodiscardstotal \n";


	#---find SubmissionQueueItemsExpiredTotal---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$submissionqueueitemsexpiredtotal = $risc->{$calname}->{'2'}->{'submissionqueueitemsexpiredtotal'};
#	print "submissionqueueitemsexpiredtotal: $submissionqueueitemsexpiredtotal \n";


	#---find SubmissionQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$submissionqueuelength = $risc->{$calname}->{'2'}->{'submissionqueuelength'};
#	print "submissionqueuelength: $submissionqueuelength \n";


	#---find UnreachableQueueLength---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$unreachablequeuelength = $risc->{$calname}->{'2'}->{'unreachablequeuelength'};
#	print "unreachablequeuelength: $unreachablequeuelength \n";

###################################################################################
													
	#---add data to the table---#
	$insertinfo->execute(	
	$deviceid
	,$scantime
	,$activemailboxdeliveryqueuelength
	,$activenonsmtpdeliveryqueuelength
	,$activeremotedeliveryqueuelength
	,$aggregatedeliveryqueuelengthallqueues
	,$aggregateshadowqueuelength
	,$caption
	,$categorizerjobavailability
	,$description
	,$itemscompleteddeliverypersecond
	,$itemscompleteddeliverytotal
	,$itemsdeletedbyadmintotal
	,$itemsqueuedfordeliveryexpiredtotal
	,$itemsqueuedfordeliverypersecond
	,$itemsqueuedfordeliverytotal
	,$itemsresubmittedtotal
	,$largestdeliveryqueuelength
	,$messagescompleteddeliverypersecond
	,$messagescompleteddeliverytotal
	,$messagescompletingcategorization
	,$messagesdeferredduringcategorization
	,$messagesqueuedfordelivery
	,$messagesqueuedfordeliverypersecond
	,$messagesqueuedfordeliverytotal
	,$messagessubmittedpersecond
	,$messagessubmittedtotal
	,$tablename
	,$poisonqueuelength
	,$retrymailboxdeliveryqueuelength
	,$retrynonsmtpdeliveryqueuelength
	,$retryremotedeliveryqueuelength
	,$shadowqueueautodiscardstotal
	,$submissionqueueitemsexpiredtotal
	,$submissionqueuelength
	,$unreachablequeuelength
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of PercentProcessorTime subroutine 

sub WinPerfExchangeADAccessProcess
{
my $wmi = shift; #wmi class name
my $objWMI = shift;
my $deviceid = shift;

#---store data---#
my $insertinfo = $mysql->prepare_cached("
	INSERT INTO winperfexchadaccessprocess (
	deviceid
	,scantime
	,caption
	,criticalvalidationfailurespermin
	,description
	,ignoredvalidationfailurespermin
	,ldapnotfoundconfigurationreadcallspersec
	,ldapnotificationsreceivedpersec
	,ldapnotificationsreportedpersec
	,ldappagespersec
	,ldapreadcallspersec
	,ldapreadtime
	,ldapsearchcallspersec
	,ldapsearchtime
	,ldaptimeouterrorspersec
	,ldapvlvrequestspersec
	,ldapwritecallspersec
	,ldapwritetime
	,longrunningldapoperationspermin
	,name
	,noncriticalvalidationfailurespermin
	,numberofoutstandingrequests
	,openconnectionstodomaincontrollers
	,openconnectionstoglobalcatalogs
	,processid
	,topologyversion
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $caption = undef;
my $criticalvalidationfailurespermin = undef;
my $description = undef;
my $ignoredvalidationfailurespermin = undef;
my $ldapnotfoundconfigurationreadcallspersec = undef;
my $ldapnotificationsreceivedpersec = undef;
my $ldapnotificationsreportedpersec = undef;
my $ldappagespersec = undef;
my $ldapreadcallspersec = undef;
my $ldapreadtime = undef;
my $ldapreadtime_base = undef;
my $ldapsearchcallspersec = undef;
my $ldapsearchtime = undef;
my $ldapsearchtime_base = undef;
my $ldaptimeouterrorspersec = undef;
my $ldapvlvrequestspersec = undef;
my $ldapwritecallspersec = undef;
my $ldapwritetime = undef;
my $ldapwritetime_base = undef;
my $longrunningldapoperationspermin = undef;
my $namecolumn = undef;
my $noncriticalvalidationfailurespermin = undef;
my $numberofoutstandingrequests = undef;
my $openconnectionstodomaincontrollers = undef;
my $openconnectionstoglobalcatalogs = undef;
my $processid = undef;
my $topologyversion = undef;


#---Collect Statistics---#
my $colRawPerf1 = $objWMI->InstancesOf($wmi);
sleep 1;
my $colRawPerf2 = $objWMI->InstancesOf($wmi);

my $risc;

foreach my $process (@$colRawPerf1) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'criticalvalidationfailurespermin'} = $process->{'CriticalValidationFailuresPermin'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'ignoredvalidationfailurespermin'} = $process->{'IgnoredValidationFailuresPermin'};
	$risc->{$name}->{'1'}->{'ldapnotfoundconfigurationreadcallspersec'} = $process->{'LDAPNotFoundConfigurationReadCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapnotificationsreceivedpersec'} = $process->{'LDAPNotificationsreceivedPersec'};
	$risc->{$name}->{'1'}->{'ldapnotificationsreportedpersec'} = $process->{'LDAPNotificationsReportedPersec'};
	$risc->{$name}->{'1'}->{'ldappagespersec'} = $process->{'LDAPPagesPersec'};
	$risc->{$name}->{'1'}->{'ldapreadcallspersec'} = $process->{'LDAPReadCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapreadtime'} = $process->{'LDAPReadTime'};
	$risc->{$name}->{'1'}->{'ldapreadtime_base'} = $process->{'LDAPReadTime_Base'};
	$risc->{$name}->{'1'}->{'ldapsearchcallspersec'} = $process->{'LDAPSearchCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapsearchtime'} = $process->{'LDAPSearchTime'};
	$risc->{$name}->{'1'}->{'ldapsearchtime_base'} = $process->{'LDAPSearchTime_Base'};
	$risc->{$name}->{'1'}->{'ldaptimeouterrorspersec'} = $process->{'LDAPTimeoutErrorsPersec'};
	$risc->{$name}->{'1'}->{'ldapvlvrequestspersec'} = $process->{'LDAPVLVRequestsPersec'};
	$risc->{$name}->{'1'}->{'ldapwritecallspersec'} = $process->{'LDAPWriteCallsPersec'};
	$risc->{$name}->{'1'}->{'ldapwritetime'} = $process->{'LDAPWriteTime'};
	$risc->{$name}->{'1'}->{'ldapwritetime_base'} = $process->{'LDAPWriteTime_Base'};
	$risc->{$name}->{'1'}->{'longrunningldapoperationspermin'} = $process->{'LongRunningLDAPOperationsPermin'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'noncriticalvalidationfailurespermin'} = $process->{'NoncriticalValidationFailuresPermin'};
	$risc->{$name}->{'1'}->{'numberofoutstandingrequests'} = $process->{'NumberofOutstandingRequests'};
	$risc->{$name}->{'1'}->{'openconnectionstodomaincontrollers'} = $process->{'OpenConnectionstoDomainControllers'};
	$risc->{$name}->{'1'}->{'openconnectionstoglobalcatalogs'} = $process->{'OpenConnectionstoGlobalCatalogs'};
	$risc->{$name}->{'1'}->{'processid'} = $process->{'ProcessID'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'topologyversion'} = $process->{'TopologyVersion'};
}

foreach  my $process (@$colRawPerf2) 
{
	my $name = $process->{'Name'};

	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'criticalvalidationfailurespermin'} = $process->{'CriticalValidationFailuresPermin'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'ignoredvalidationfailurespermin'} = $process->{'IgnoredValidationFailuresPermin'};
	$risc->{$name}->{'2'}->{'ldapnotfoundconfigurationreadcallspersec'} = $process->{'LDAPNotFoundConfigurationReadCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapnotificationsreceivedpersec'} = $process->{'LDAPNotificationsreceivedPersec'};
	$risc->{$name}->{'2'}->{'ldapnotificationsreportedpersec'} = $process->{'LDAPNotificationsReportedPersec'};
	$risc->{$name}->{'2'}->{'ldappagespersec'} = $process->{'LDAPPagesPersec'};
	$risc->{$name}->{'2'}->{'ldapreadcallspersec'} = $process->{'LDAPReadCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapreadtime'} = $process->{'LDAPReadTime'};
	$risc->{$name}->{'2'}->{'ldapreadtime_base'} = $process->{'LDAPReadTime_Base'};
	$risc->{$name}->{'2'}->{'ldapsearchcallspersec'} = $process->{'LDAPSearchCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapsearchtime'} = $process->{'LDAPSearchTime'};
	$risc->{$name}->{'2'}->{'ldapsearchtime_base'} = $process->{'LDAPSearchTime_Base'};
	$risc->{$name}->{'2'}->{'ldaptimeouterrorspersec'} = $process->{'LDAPTimeoutErrorsPersec'};
	$risc->{$name}->{'2'}->{'ldapvlvrequestspersec'} = $process->{'LDAPVLVRequestsPersec'};
	$risc->{$name}->{'2'}->{'ldapwritecallspersec'} = $process->{'LDAPWriteCallsPersec'};
	$risc->{$name}->{'2'}->{'ldapwritetime'} = $process->{'LDAPWriteTime'};
	$risc->{$name}->{'2'}->{'ldapwritetime_base'} = $process->{'LDAPWriteTime_Base'};
	$risc->{$name}->{'2'}->{'longrunningldapoperationspermin'} = $process->{'LongRunningLDAPOperationsPermin'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'noncriticalvalidationfailurespermin'} = $process->{'NoncriticalValidationFailuresPermin'};
	$risc->{$name}->{'2'}->{'numberofoutstandingrequests'} = $process->{'NumberofOutstandingRequests'};
	$risc->{$name}->{'2'}->{'openconnectionstodomaincontrollers'} = $process->{'OpenConnectionstoDomainControllers'};
	$risc->{$name}->{'2'}->{'openconnectionstoglobalcatalogs'} = $process->{'OpenConnectionstoGlobalCatalogs'};
	$risc->{$name}->{'2'}->{'processid'} = $process->{'ProcessID'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'topologyversion'} = $process->{'TopologyVersion'};
}

foreach my $cal (keys %$risc)
{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'};


	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
#	print "freq_perftime2: $frequency_perftime2\n";
#	print "time_perftime1: $timestamp_perftime1\n";
#	print "tiem_perftime2: $timestamp_perftime2\n";
#	print "time_100ns1: $timestamp_sys100ns1\n";
#	print "time_100ns2: $timestamp_sys100ns2\n";
#	print "---------------------------------\n";

	#---I use these 4 scalars to tem store data for each counter---#
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;

	#---find criticalvalidationfailurespermin---#	
	$val1 = $risc->{$calname}->{'1'}->{'criticalvalidationfailurespermin'};	
#	print "criticalvalidationfailurespermin1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'criticalvalidationfailurespermin'};	
#	print "criticalvalidationfailurespermin2: $val2 \n";	
	eval 	
	{	
	$criticalvalidationfailurespermin = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "criticalvalidationfailurespermin: $criticalvalidationfailurespermin \n\n";	

	#---find ignoredvalidationfailurespermin---#	
	$val1 = $risc->{$calname}->{'1'}->{'ignoredvalidationfailurespermin'};	
#	print "ignoredvalidationfailurespermin1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ignoredvalidationfailurespermin'};	
#	print "ignoredvalidationfailurespermin2: $val2 \n";	
	eval 	
	{	
	$ignoredvalidationfailurespermin = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ignoredvalidationfailurespermin: $ignoredvalidationfailurespermin \n\n";	

	#---find ldapnotfoundconfigurationreadcallspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapnotfoundconfigurationreadcallspersec'};	
#	print "ldapnotfoundconfigurationreadcallspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapnotfoundconfigurationreadcallspersec'};	
#	print "ldapnotfoundconfigurationreadcallspersec2: $val2 \n";	
	eval 	
	{	
	$ldapnotfoundconfigurationreadcallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapnotfoundconfigurationreadcallspersec: $ldapnotfoundconfigurationreadcallspersec \n\n";	

	#---find ldapnotificationsreceivedpersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapnotificationsreceivedpersec'};	
#	print "ldapnotificationsreceivedpersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapnotificationsreceivedpersec'};	
#	print "ldapnotificationsreceivedpersec2: $val2 \n";	
	eval 	
	{	
	$ldapnotificationsreceivedpersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapnotificationsreceivedpersec: $ldapnotificationsreceivedpersec \n\n";	

	#---find ldapnotificationsreportedpersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapnotificationsreportedpersec'};	
#	print "ldapnotificationsreportedpersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapnotificationsreportedpersec'};	
#	print "ldapnotificationsreportedpersec2: $val2 \n";	
	eval 	
	{	
	$ldapnotificationsreportedpersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapnotificationsreportedpersec: $ldapnotificationsreportedpersec \n\n";	

	#---find ldappagespersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldappagespersec'};	
#	print "ldappagespersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldappagespersec'};	
#	print "ldappagespersec2: $val2 \n";	
	eval 	
	{	
	$ldappagespersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldappagespersec: $ldappagespersec \n\n";

	#---find ldapreadcallspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapreadcallspersec'};	
#	print "ldapreadcallspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapreadcallspersec'};	
#	print "ldapreadcallspersec2: $val2 \n";	
	eval 	
	{	
	$ldapreadcallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapreadcallspersec: $ldapreadcallspersec \n\n";

	#---find ldapreadtime---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapreadtime'};	
#	print "ldapreadtime1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapreadtime'};	
#	print "ldapreadtime2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'ldapreadtime_base'};	
#	print "ldapreadtime_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'ldapreadtime_base'};	
#	print "ldapreadtime_base2: $val_base2\n";	
	eval 	
	{	
	$ldapreadtime = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "ldapreadtime: $ldapreadtime \n";	

	#---find ldapsearchcallspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapsearchcallspersec'};	
#	print "ldapsearchcallspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapsearchcallspersec'};	
#	print "ldapsearchcallspersec2: $val2 \n";	
	eval 	
	{	
	$ldapsearchcallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapsearchcallspersec: $ldapsearchcallspersec \n\n";

	#---find ldapsearchtime---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapsearchtime'};	
#	print "ldapsearchtime1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapsearchtime'};	
#	print "ldapsearchtime2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'ldapsearchtime_base'};	
#	print "ldapsearchtime_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'ldapsearchtime_base'};	
#	print "ldapsearchtime_base2: $val_base2\n";	
	eval 	
	{	
	$ldapsearchtime = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "ldapsearchtime: $ldapsearchtime \n";

	#---find ldaptimeouterrorspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldaptimeouterrorspersec'};	
#	print "ldaptimeouterrorspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldaptimeouterrorspersec'};	
#	print "ldaptimeouterrorspersec2: $val2 \n";	
	eval 	
	{	
	$ldaptimeouterrorspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldaptimeouterrorspersec: $ldaptimeouterrorspersec \n\n";

	#---find ldapvlvrequestspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapvlvrequestspersec'};	
#	print "ldapvlvrequestspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapvlvrequestspersec'};	
#	print "ldapvlvrequestspersec2: $val2 \n";	
	eval 	
	{	
	$ldapvlvrequestspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapvlvrequestspersec: $ldapvlvrequestspersec \n\n";

	#---find ldapwritecallspersec---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapwritecallspersec'};	
#	print "ldapwritecallspersec1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapwritecallspersec'};	
#	print "ldapwritecallspersec2: $val2 \n";	
	eval 	
	{	
	$ldapwritecallspersec = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "ldapwritecallspersec: $ldapwritecallspersec \n\n";

	#---find ldapwritetime---#	
	$val1 = $risc->{$calname}->{'1'}->{'ldapwritetime'};	
#	print "ldapwritetime1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'ldapwritetime'};	
#	print "ldapwritetime2: $val2 \n";	
	$val_base1 = $risc->{$calname}->{'1'}->{'ldapwritetime_base'};	
#	print "ldapwritetime_base1: $val_base1\n";	
	$val_base2 = $risc->{$calname}->{'2'}->{'ldapwritetime_base'};	
#	print "ldapwritetime_base2: $val_base2\n";	
	eval 	
	{	
	$ldapwritetime = PERF_AVERAGE_BULK(	
		$val1 #counter value 1
		,$val2 #counter value 2
		,$val_base1 #base counter value 1
		,$val_base2); #base counter value 2
	};	
#	print "ldapwritetime: $ldapwritetime \n";

	#---find longrunningldapoperationspermin---#	
	$val1 = $risc->{$calname}->{'1'}->{'longrunningldapoperationspermin'};	
#	print "longrunningldapoperationspermin1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'longrunningldapoperationspermin'};	
#	print "longrunningldapoperationspermin2: $val2 \n";	
	eval 	
	{	
	$longrunningldapoperationspermin = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "longrunningldapoperationspermin: $longrunningldapoperationspermin \n\n";

	#---find noncriticalvalidationfailurespermin---#	
	$val1 = $risc->{$calname}->{'1'}->{'noncriticalvalidationfailurespermin'};	
#	print "noncriticalvalidationfailurespermin1: $val1 \n";	
	$val2 = $risc->{$calname}->{'2'}->{'noncriticalvalidationfailurespermin'};	
#	print "noncriticalvalidationfailurespermin2: $val2 \n";	
	eval 	
	{	
	$noncriticalvalidationfailurespermin = perf_counter_counter(	
		$val1 #c1
		,$val2 #c2
		,$frequency_perftime2 #Perffreq2
		,$timestamp_perftime1 #Perftime1
		,$timestamp_perftime2); #Perftime2
	};	
#	print "noncriticalvalidationfailurespermin: $noncriticalvalidationfailurespermin \n\n";

	#---find numberofoutstandingrequests---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$numberofoutstandingrequests = $risc->{$calname}->{'2'}->{'numberofoutstandingrequests'};
#	print "numberofoutstandingrequests: $numberofoutstandingrequests \n\n";

	#---find openconnectionstodomaincontrollers---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$openconnectionstodomaincontrollers = $risc->{$calname}->{'2'}->{'openconnectionstodomaincontrollers'};
#	print "openconnectionstodomaincontrollers: $openconnectionstodomaincontrollers \n\n";

	#---find openconnectionstoglobalcatalogs---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$openconnectionstoglobalcatalogs = $risc->{$calname}->{'2'}->{'openconnectionstoglobalcatalogs'};
#	print "openconnectionstoglobalcatalogs: $openconnectionstoglobalcatalogs \n\n";

	#---find processid---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$processid = $risc->{$calname}->{'2'}->{'processid'};
#	print "processid: $processid \n\n";

	#---find topologyversion---#
	#The formular is PERF_COUNTER_RAWCOUNT = None. Shows raw data as collected.
	$topologyversion = $risc->{$calname}->{'2'}->{'topologyversion'};
#	print "topologyversion: $topologyversion \n\n";


#####################################

													
	#---add data to the table---#
	$insertinfo->execute(
	$deviceid
	,$scantime
	,$caption
	,$criticalvalidationfailurespermin
	,$description
	,$ignoredvalidationfailurespermin
	,$ldapnotfoundconfigurationreadcallspersec
	,$ldapnotificationsreceivedpersec
	,$ldapnotificationsreportedpersec
	,$ldappagespersec
	,$ldapreadcallspersec
	,$ldapreadtime
	,$ldapsearchcallspersec
	,$ldapsearchtime
	,$ldaptimeouterrorspersec
	,$ldapvlvrequestspersec
	,$ldapwritecallspersec
	,$ldapwritetime
	,$longrunningldapoperationspermin
	,$namecolumn
	,$noncriticalvalidationfailurespermin
	,$numberofoutstandingrequests
	,$openconnectionstodomaincontrollers
	,$openconnectionstoglobalcatalogs
	,$processid
	,$topologyversion
	);   	
	
} #end of foreach my $cal (%$risc)                            

} #end of AD Access Process subroutine 

sub SQLAccMethods
{
	##---store data---#
	my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLAccMethods (
		deviceid
		,scantime
		,instancename
		,aucleanupbatchespersec
		,aucleanupspersec
		,byreferencelobcreatecount
		,byreferencelobusecount
		,caption
		,countlobreadahead
		,countpullinrow
		,countpushoffrow
		,deferreddroppedaus
		,deferreddroppedrowsets
		,description
		,droppedrowsetcleanupspersec
		,droppedrowsetsskippedpersec
		,extentdeallocationspersec
		,extentsallocatedpersec
		,failedaucleanupbatchespersec
		,failedleafpagecookie
		,failedtreepagecookie
		,forwardedrecordspersec
		,freespacepagefetchespersec
		,freespacescanspersec
		,fullscanspersec
		,indexsearchespersec
		,insysxactwaitspersec
		,lobhandlecreatecount
		,lobhandledestroycount
		,lobssprovidercreatecount
		,lobssproviderdestroycount
		,lobssprovidertruncationcount
		,mixedpageallocationspersec
		,name
		,pagecompressionattemptspersec
		,pagedeallocationspersec
		,pagesallocatedpersec
		,pagescompressedpersec
		,pagesplitspersec
		,probescanspersec
		,rangescanspersec
		,scanpointrevalidationspersec
		,skippedghostedrecordspersec
		,tablelockescalationspersec
		,usedleafpagecookie
		,usedtreepagecookie
		,workfilescreatedpersec
		,worktablescreatedpersec
		,worktablesfromcacheratio
		,batchrequestspersec
		,percentforwardedrecordspersec_to_batchrequestspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	
	my $instancename = undef;
	my $aucleanupbatchespersec = undef;
	my $aucleanupspersec = undef;
	my $byreferencelobcreatecount = undef;
	my $byreferencelobusecount = undef;
	my $caption = undef;
	my $countlobreadahead = undef;
	my $countpullinrow = undef;
	my $countpushoffrow = undef;
	my $deferreddroppedaus = undef;
	my $deferreddroppedrowsets = undef;
	my $description = undef;
	my $droppedrowsetcleanupspersec = undef;
	my $droppedrowsetsskippedpersec = undef;
	my $extentdeallocationspersec = undef;
	my $extentsallocatedpersec = undef;
	my $failedaucleanupbatchespersec = undef;
	my $failedleafpagecookie = undef;
	my $failedtreepagecookie = undef;
	my $forwardedrecordspersec = undef;
	my $freespacepagefetchespersec = undef;
	my $freespacescanspersec = undef;
	my $frequency_object = undef;
	my $frequency_perftime = undef;
	my $frequency_sys100ns = undef;
	my $fullscanspersec = undef;
	my $indexsearchespersec = undef;
	my $insysxactwaitspersec = undef;
	my $lobhandlecreatecount = undef;
	my $lobhandledestroycount = undef;
	my $lobssprovidercreatecount = undef;
	my $lobssproviderdestroycount = undef;
	my $lobssprovidertruncationcount = undef;
	my $mixedpageallocationspersec = undef;
	my $namecolumn = undef;
	my $pagecompressionattemptspersec = undef;
	my $pagedeallocationspersec = undef;
	my $pagesallocatedpersec = undef;
	my $pagescompressedpersec = undef;
	my $pagesplitspersec = undef;
	my $probescanspersec = undef;
	my $rangescanspersec = undef;
	my $scanpointrevalidationspersec = undef;
	my $skippedghostedrecordspersec = undef;
	my $tablelockescalationspersec = undef;
	my $timestamp_object = undef;
	my $timestamp_perftime = undef;
	my $timestamp_sys100ns = undef;
	my $usedleafpagecookie = undef;
	my $usedtreepagecookie = undef;
	my $workfilescreatedpersec = undef;
	my $worktablescreatedpersec = undef;
	my $worktablesfromcacheratio = undef;
	my $worktablesfromcacheratio_base = undef;
	
	my $batchrequestspersec = undef;
	my $percentforwardedrecordspersec_to_batchrequestspersec;

	
#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# every instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl "winperfSQLAccMethods"
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "AccessMethods";
	my $sqlstat = "Win32_PerfRawData_MSSQL". $name . "_MSSQL". $name . "SQLStatistics";


	##########################
	#---Collect Statistics---#
	##########################
	my $colSQLAccMethodsRawPerf1 = $objWMI->InstancesOf($wmi);
	my $colsqlstat1 = $objWMI->InstancesOf($sqlstat);
	sleep 5;
	my $colSQLAccMethodsRawPerf2 = $objWMI->InstancesOf($wmi);
	my $colsqlstat2 = $objWMI->InstancesOf($sqlstat);
	
	my $risc;
	foreach  my $process (@$colSQLAccMethodsRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'aucleanupbatchespersec'} = $process->{'AUcleanupbatchesPersec'};
	$risc->{$name}->{'1'}->{'aucleanupspersec'} = $process->{'AUcleanupsPersec'};
	$risc->{$name}->{'1'}->{'byreferencelobcreatecount'} = $process->{'ByreferenceLobCreateCount'};
	$risc->{$name}->{'1'}->{'byreferencelobusecount'} = $process->{'ByreferenceLobUseCount'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'countlobreadahead'} = $process->{'CountLobReadahead'};
	$risc->{$name}->{'1'}->{'countpullinrow'} = $process->{'CountPullInRow'};
	$risc->{$name}->{'1'}->{'countpushoffrow'} = $process->{'CountPushOffRow'};
	$risc->{$name}->{'1'}->{'deferreddroppedaus'} = $process->{'DeferreddroppedAUs'};
	$risc->{$name}->{'1'}->{'deferreddroppedrowsets'} = $process->{'DeferredDroppedrowsets'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'droppedrowsetcleanupspersec'} = $process->{'DroppedrowsetcleanupsPersec'};
	$risc->{$name}->{'1'}->{'droppedrowsetsskippedpersec'} = $process->{'DroppedrowsetsskippedPersec'};
	$risc->{$name}->{'1'}->{'extentdeallocationspersec'} = $process->{'ExtentDeallocationsPersec'};
	$risc->{$name}->{'1'}->{'extentsallocatedpersec'} = $process->{'ExtentsAllocatedPersec'};
	$risc->{$name}->{'1'}->{'failedaucleanupbatchespersec'} = $process->{'FailedAUcleanupbatchesPersec'};
	$risc->{$name}->{'1'}->{'failedleafpagecookie'} = $process->{'Failedleafpagecookie'};
	$risc->{$name}->{'1'}->{'failedtreepagecookie'} = $process->{'Failedtreepagecookie'};
	$risc->{$name}->{'1'}->{'forwardedrecordspersec'} = $process->{'ForwardedRecordsPersec'};
	$risc->{$name}->{'1'}->{'freespacepagefetchespersec'} = $process->{'FreeSpacePageFetchesPersec'};
	$risc->{$name}->{'1'}->{'freespacescanspersec'} = $process->{'FreeSpaceScansPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'fullscanspersec'} = $process->{'FullScansPersec'};
	$risc->{$name}->{'1'}->{'indexsearchespersec'} = $process->{'IndexSearchesPersec'};
	$risc->{$name}->{'1'}->{'insysxactwaitspersec'} = $process->{'InSysXactwaitsPersec'};
	$risc->{$name}->{'1'}->{'lobhandlecreatecount'} = $process->{'LobHandleCreateCount'};
	$risc->{$name}->{'1'}->{'lobhandledestroycount'} = $process->{'LobHandleDestroyCount'};
	$risc->{$name}->{'1'}->{'lobssprovidercreatecount'} = $process->{'LobSSProviderCreateCount'};
	$risc->{$name}->{'1'}->{'lobssproviderdestroycount'} = $process->{'LobSSProviderDestroyCount'};
	$risc->{$name}->{'1'}->{'lobssprovidertruncationcount'} = $process->{'LobSSProviderTruncationCount'};
	$risc->{$name}->{'1'}->{'mixedpageallocationspersec'} = $process->{'MixedpageallocationsPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'pagecompressionattemptspersec'} = $process->{'PagecompressionattemptsPersec'};
	$risc->{$name}->{'1'}->{'pagedeallocationspersec'} = $process->{'PageDeallocationsPersec'};
	$risc->{$name}->{'1'}->{'pagesallocatedpersec'} = $process->{'PagesAllocatedPersec'};
	$risc->{$name}->{'1'}->{'pagescompressedpersec'} = $process->{'PagescompressedPersec'};
	$risc->{$name}->{'1'}->{'pagesplitspersec'} = $process->{'PageSplitsPersec'};
	$risc->{$name}->{'1'}->{'probescanspersec'} = $process->{'ProbeScansPersec'};
	$risc->{$name}->{'1'}->{'rangescanspersec'} = $process->{'RangeScansPersec'};
	$risc->{$name}->{'1'}->{'scanpointrevalidationspersec'} = $process->{'ScanPointRevalidationsPersec'};
	$risc->{$name}->{'1'}->{'skippedghostedrecordspersec'} = $process->{'SkippedGhostedRecordsPersec'};
	$risc->{$name}->{'1'}->{'tablelockescalationspersec'} = $process->{'TableLockEscalationsPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'usedleafpagecookie'} = $process->{'Usedleafpagecookie'};
	$risc->{$name}->{'1'}->{'usedtreepagecookie'} = $process->{'Usedtreepagecookie'};
	$risc->{$name}->{'1'}->{'workfilescreatedpersec'} = $process->{'WorkfilesCreatedPersec'};
	$risc->{$name}->{'1'}->{'worktablescreatedpersec'} = $process->{'WorktablesCreatedPersec'};
	$risc->{$name}->{'1'}->{'worktablesfromcacheratio'} = $process->{'WorktablesFromCacheRatio'};
	$risc->{$name}->{'1'}->{'worktablesfromcacheratio_base'} = $process->{'WorktablesFromCacheRatio_Base'};
	}
#	print Dumper(\$risc);

	foreach  my $process (@$colsqlstat1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	}
#	print Dumper(\$risc);	
	
	foreach  my $process (@$colSQLAccMethodsRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'aucleanupbatchespersec'} = $process->{'AUcleanupbatchesPersec'};
	$risc->{$name}->{'2'}->{'aucleanupspersec'} = $process->{'AUcleanupsPersec'};
	$risc->{$name}->{'2'}->{'byreferencelobcreatecount'} = $process->{'ByreferenceLobCreateCount'};
	$risc->{$name}->{'2'}->{'byreferencelobusecount'} = $process->{'ByreferenceLobUseCount'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'countlobreadahead'} = $process->{'CountLobReadahead'};
	$risc->{$name}->{'2'}->{'countpullinrow'} = $process->{'CountPullInRow'};
	$risc->{$name}->{'2'}->{'countpushoffrow'} = $process->{'CountPushOffRow'};
	$risc->{$name}->{'2'}->{'deferreddroppedaus'} = $process->{'DeferreddroppedAUs'};
	$risc->{$name}->{'2'}->{'deferreddroppedrowsets'} = $process->{'DeferredDroppedrowsets'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'droppedrowsetcleanupspersec'} = $process->{'DroppedrowsetcleanupsPersec'};
	$risc->{$name}->{'2'}->{'droppedrowsetsskippedpersec'} = $process->{'DroppedrowsetsskippedPersec'};
	$risc->{$name}->{'2'}->{'extentdeallocationspersec'} = $process->{'ExtentDeallocationsPersec'};
	$risc->{$name}->{'2'}->{'extentsallocatedpersec'} = $process->{'ExtentsAllocatedPersec'};
	$risc->{$name}->{'2'}->{'failedaucleanupbatchespersec'} = $process->{'FailedAUcleanupbatchesPersec'};
	$risc->{$name}->{'2'}->{'failedleafpagecookie'} = $process->{'Failedleafpagecookie'};
	$risc->{$name}->{'2'}->{'failedtreepagecookie'} = $process->{'Failedtreepagecookie'};
	$risc->{$name}->{'2'}->{'forwardedrecordspersec'} = $process->{'ForwardedRecordsPersec'};
	$risc->{$name}->{'2'}->{'freespacepagefetchespersec'} = $process->{'FreeSpacePageFetchesPersec'};
	$risc->{$name}->{'2'}->{'freespacescanspersec'} = $process->{'FreeSpaceScansPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'fullscanspersec'} = $process->{'FullScansPersec'};
	$risc->{$name}->{'2'}->{'indexsearchespersec'} = $process->{'IndexSearchesPersec'};
	$risc->{$name}->{'2'}->{'insysxactwaitspersec'} = $process->{'InSysXactwaitsPersec'};
	$risc->{$name}->{'2'}->{'lobhandlecreatecount'} = $process->{'LobHandleCreateCount'};
	$risc->{$name}->{'2'}->{'lobhandledestroycount'} = $process->{'LobHandleDestroyCount'};
	$risc->{$name}->{'2'}->{'lobssprovidercreatecount'} = $process->{'LobSSProviderCreateCount'};
	$risc->{$name}->{'2'}->{'lobssproviderdestroycount'} = $process->{'LobSSProviderDestroyCount'};
	$risc->{$name}->{'2'}->{'lobssprovidertruncationcount'} = $process->{'LobSSProviderTruncationCount'};
	$risc->{$name}->{'2'}->{'mixedpageallocationspersec'} = $process->{'MixedpageallocationsPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'pagecompressionattemptspersec'} = $process->{'PagecompressionattemptsPersec'};
	$risc->{$name}->{'2'}->{'pagedeallocationspersec'} = $process->{'PageDeallocationsPersec'};
	$risc->{$name}->{'2'}->{'pagesallocatedpersec'} = $process->{'PagesAllocatedPersec'};
	$risc->{$name}->{'2'}->{'pagescompressedpersec'} = $process->{'PagescompressedPersec'};
	$risc->{$name}->{'2'}->{'pagesplitspersec'} = $process->{'PageSplitsPersec'};
	$risc->{$name}->{'2'}->{'probescanspersec'} = $process->{'ProbeScansPersec'};
	$risc->{$name}->{'2'}->{'rangescanspersec'} = $process->{'RangeScansPersec'};
	$risc->{$name}->{'2'}->{'scanpointrevalidationspersec'} = $process->{'ScanPointRevalidationsPersec'};
	$risc->{$name}->{'2'}->{'skippedghostedrecordspersec'} = $process->{'SkippedGhostedRecordsPersec'};
	$risc->{$name}->{'2'}->{'tablelockescalationspersec'} = $process->{'TableLockEscalationsPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'usedleafpagecookie'} = $process->{'Usedleafpagecookie'};
	$risc->{$name}->{'2'}->{'usedtreepagecookie'} = $process->{'Usedtreepagecookie'};
	$risc->{$name}->{'2'}->{'workfilescreatedpersec'} = $process->{'WorkfilesCreatedPersec'};
	$risc->{$name}->{'2'}->{'worktablescreatedpersec'} = $process->{'WorktablesCreatedPersec'};
	$risc->{$name}->{'2'}->{'worktablesfromcacheratio'} = $process->{'WorktablesFromCacheRatio'};
	$risc->{$name}->{'2'}->{'worktablesfromcacheratio_base'} = $process->{'WorktablesFromCacheRatio_Base'};
	}
#	print Dumper(\$risc);	

	
	foreach  my $process (@$colsqlstat2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	}
#	print Dumper(\$risc);
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scanlars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#---find each object of WMI class---#
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	$aucleanupbatchespersec = CAL_PERF_COUNTER_BULK_COUNT('AUcleanupbatchesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$aucleanupspersec = CAL_PERF_COUNTER_BULK_COUNT('AUcleanupsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$byreferencelobcreatecount = CAL_PERF_COUNTER_BULK_COUNT('ByreferenceLobCreateCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$byreferencelobusecount = CAL_PERF_COUNTER_BULK_COUNT('ByreferenceLobUseCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$countlobreadahead = CAL_PERF_COUNTER_BULK_COUNT('CountLobReadahead',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$countpullinrow = CAL_PERF_COUNTER_BULK_COUNT('CountPullInRow',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$countpushoffrow = CAL_PERF_COUNTER_BULK_COUNT('CountPushOffRow',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$droppedrowsetcleanupspersec = CAL_PERF_COUNTER_BULK_COUNT('DroppedrowsetcleanupsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$droppedrowsetsskippedpersec = CAL_PERF_COUNTER_BULK_COUNT('DroppedrowsetsskippedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$extentdeallocationspersec = CAL_PERF_COUNTER_BULK_COUNT('ExtentDeallocationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$extentsallocatedpersec = CAL_PERF_COUNTER_BULK_COUNT('ExtentsAllocatedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$failedaucleanupbatchespersec = CAL_PERF_COUNTER_BULK_COUNT('FailedAUcleanupbatchesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$failedleafpagecookie = CAL_PERF_COUNTER_BULK_COUNT('Failedleafpagecookie',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$failedtreepagecookie = CAL_PERF_COUNTER_BULK_COUNT('Failedtreepagecookie',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$forwardedrecordspersec = CAL_PERF_COUNTER_BULK_COUNT('ForwardedRecordsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$freespacepagefetchespersec = CAL_PERF_COUNTER_BULK_COUNT('FreeSpacePageFetchesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$freespacescanspersec = CAL_PERF_COUNTER_BULK_COUNT('FreeSpaceScansPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$fullscanspersec = CAL_PERF_COUNTER_BULK_COUNT('FullScansPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$indexsearchespersec = CAL_PERF_COUNTER_BULK_COUNT('IndexSearchesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$insysxactwaitspersec = CAL_PERF_COUNTER_BULK_COUNT('InSysXactwaitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lobhandlecreatecount = CAL_PERF_COUNTER_BULK_COUNT('LobHandleCreateCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lobhandledestroycount = CAL_PERF_COUNTER_BULK_COUNT('LobHandleDestroyCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lobssprovidercreatecount = CAL_PERF_COUNTER_BULK_COUNT('LobSSProviderCreateCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lobssproviderdestroycount = CAL_PERF_COUNTER_BULK_COUNT('LobSSProviderDestroyCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lobssprovidertruncationcount = CAL_PERF_COUNTER_BULK_COUNT('LobSSProviderTruncationCount',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$mixedpageallocationspersec = CAL_PERF_COUNTER_BULK_COUNT('MixedpageallocationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagecompressionattemptspersec = CAL_PERF_COUNTER_BULK_COUNT('PagecompressionattemptsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagedeallocationspersec = CAL_PERF_COUNTER_BULK_COUNT('PageDeallocationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagesallocatedpersec = CAL_PERF_COUNTER_BULK_COUNT('PagesAllocatedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagescompressedpersec = CAL_PERF_COUNTER_BULK_COUNT('PagescompressedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagesplitspersec = CAL_PERF_COUNTER_BULK_COUNT('PageSplitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$probescanspersec = CAL_PERF_COUNTER_BULK_COUNT('ProbeScansPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$rangescanspersec = CAL_PERF_COUNTER_BULK_COUNT('RangeScansPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$scanpointrevalidationspersec = CAL_PERF_COUNTER_BULK_COUNT('ScanPointRevalidationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$skippedghostedrecordspersec = CAL_PERF_COUNTER_BULK_COUNT('SkippedGhostedRecordsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$tablelockescalationspersec = CAL_PERF_COUNTER_BULK_COUNT('TableLockEscalationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$usedleafpagecookie = CAL_PERF_COUNTER_BULK_COUNT('Usedleafpagecookie',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$usedtreepagecookie = CAL_PERF_COUNTER_BULK_COUNT('Usedtreepagecookie',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$workfilescreatedpersec = CAL_PERF_COUNTER_BULK_COUNT('WorkfilesCreatedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$worktablescreatedpersec = CAL_PERF_COUNTER_BULK_COUNT('WorktablesCreatedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$worktablesfromcacheratio = CAL_PERF_AVERAGE_BULK('WorktablesFromCacheRatio',$risc,$calname);
	
	$deferreddroppedaus = $risc->{$calname}->{'2'}->{'deferreddroppedaus'}; # CounterType = 65792 uses raw data
	print "DeferreddroppedAUs $deferreddroppedaus \n\n";
	$deferreddroppedrowsets = $risc->{$calname}->{'2'}->{'deferreddroppedrowsets'}; # CounterType = 65792 uses raw data
	print "DeferredDroppedrowsets $deferreddroppedrowsets \n\n";
	
	$batchrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('BatchRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	# result for percentforwardedrecordspersec_to_batchrequestspersec
	if ( int($forwardedrecordspersec) != 0 && int($batchrequestspersec) != 0 )
	{ $percentforwardedrecordspersec_to_batchrequestspersec = ( $forwardedrecordspersec * 100 ) / $batchrequestspersec; } 
	else { $percentforwardedrecordspersec_to_batchrequestspersec = 0; }
		
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$aucleanupbatchespersec
	,$aucleanupspersec
	,$byreferencelobcreatecount
	,$byreferencelobusecount
	,$caption
	,$countlobreadahead
	,$countpullinrow
	,$countpushoffrow
	,$deferreddroppedaus
	,$deferreddroppedrowsets
	,$description
	,$droppedrowsetcleanupspersec
	,$droppedrowsetsskippedpersec
	,$extentdeallocationspersec
	,$extentsallocatedpersec
	,$failedaucleanupbatchespersec
	,$failedleafpagecookie
	,$failedtreepagecookie
	,$forwardedrecordspersec
	,$freespacepagefetchespersec
	,$freespacescanspersec
	,$fullscanspersec
	,$indexsearchespersec
	,$insysxactwaitspersec
	,$lobhandlecreatecount
	,$lobhandledestroycount
	,$lobssprovidercreatecount
	,$lobssproviderdestroycount
	,$lobssprovidertruncationcount
	,$mixedpageallocationspersec
	,$namecolumn
	,$pagecompressionattemptspersec
	,$pagedeallocationspersec
	,$pagesallocatedpersec
	,$pagescompressedpersec
	,$pagesplitspersec
	,$probescanspersec
	,$rangescanspersec
	,$scanpointrevalidationspersec
	,$skippedghostedrecordspersec
	,$tablelockescalationspersec
	,$usedleafpagecookie
	,$usedtreepagecookie
	,$workfilescreatedpersec
	,$worktablescreatedpersec
	,$worktablesfromcacheratio
	,$batchrequestspersec
	,$percentforwardedrecordspersec_to_batchrequestspersec
	);
	
	} #end of foreach my $cal (%$risc)                            

} #end of FOREACH (@instanceNameArray)

} #end of SQLAccMethods

sub SQLBufferMana
{
	
##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLBufferMana (
	deviceid
	,scantime
	,instancename
	,backgroundwriterpagespersec
	,buffercachehitratio
	,caption
	,checkpointpagespersec
	,databasepages
	,description
	,freeliststallspersec
	,integralcontrollerslope
	,lazywritespersec
	,name
	,pagelifeexpectancy
	,pagelookupspersec
	,pagereadspersec
	,pagewritespersec
	,readaheadpagespersec
	,targetpages
	,batchrequestspersec
	,pagelookupspersec_to_batchrequestspersec
	,readaheadpagespersec_to_pagereadspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	
# belong to 1st WMI object
my $instancename = undef;
my $backgroundwriterpagespersec = undef;
my $buffercachehitratio = undef;
my $buffercachehitratio_base = undef;
my $caption = undef;
my $checkpointpagespersec = undef;
my $databasepages = undef;
my $description = undef;
my $freeliststallspersec = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $integralcontrollerslope = undef;
my $lazywritespersec = undef;
my $namecolumn = undef;
my $pagelifeexpectancy = undef;
my $pagelookupspersec = undef;
my $pagereadspersec = undef;
my $pagewritespersec = undef;
my $readaheadpagespersec = undef;
my $targetpages = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;

# belong to 2nd WMI object
my $batchrequestspersec;
my $pagelookupspersec_to_batchrequestspersec;
my $readaheadpagespersec_to_pagereadspersec;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "BufferManager";
	my $sqlstat = "Win32_PerfRawData_MSSQL". $name . "_MSSQL". $name . "SQLStatistics";


	##########################
	#---Collect Statistics---#
	##########################
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	my $colsqlstat1 = $objWMI->InstancesOf($sqlstat);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	my $colsqlstat2 = $objWMI->InstancesOf($sqlstat);
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'backgroundwriterpagespersec'} = $process->{'BackgroundwriterpagesPersec'};
	$risc->{$name}->{'1'}->{'buffercachehitratio'} = $process->{'Buffercachehitratio'};
	$risc->{$name}->{'1'}->{'buffercachehitratio_base'} = $process->{'Buffercachehitratio_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'checkpointpagespersec'} = $process->{'CheckpointpagesPersec'};
	$risc->{$name}->{'1'}->{'databasepages'} = $process->{'Databasepages'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'freeliststallspersec'} = $process->{'FreeliststallsPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'integralcontrollerslope'} = $process->{'IntegralControllerSlope'};
	$risc->{$name}->{'1'}->{'lazywritespersec'} = $process->{'LazywritesPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'pagelifeexpectancy'} = $process->{'Pagelifeexpectancy'};
	$risc->{$name}->{'1'}->{'pagelookupspersec'} = $process->{'PagelookupsPersec'};
	$risc->{$name}->{'1'}->{'pagereadspersec'} = $process->{'PagereadsPersec'};
	$risc->{$name}->{'1'}->{'pagewritespersec'} = $process->{'PagewritesPersec'};
	$risc->{$name}->{'1'}->{'readaheadpagespersec'} = $process->{'ReadaheadpagesPersec'};
	$risc->{$name}->{'1'}->{'targetpages'} = $process->{'Targetpages'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'backgroundwriterpagespersec'} = $process->{'BackgroundwriterpagesPersec'};
	$risc->{$name}->{'2'}->{'buffercachehitratio'} = $process->{'Buffercachehitratio'};
	$risc->{$name}->{'2'}->{'buffercachehitratio_base'} = $process->{'Buffercachehitratio_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'checkpointpagespersec'} = $process->{'CheckpointpagesPersec'};
	$risc->{$name}->{'2'}->{'databasepages'} = $process->{'Databasepages'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'freeliststallspersec'} = $process->{'FreeliststallsPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'integralcontrollerslope'} = $process->{'IntegralControllerSlope'};
	$risc->{$name}->{'2'}->{'lazywritespersec'} = $process->{'LazywritesPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'pagelifeexpectancy'} = $process->{'Pagelifeexpectancy'};
	$risc->{$name}->{'2'}->{'pagelookupspersec'} = $process->{'PagelookupsPersec'};
	$risc->{$name}->{'2'}->{'pagereadspersec'} = $process->{'PagereadsPersec'};
	$risc->{$name}->{'2'}->{'pagewritespersec'} = $process->{'PagewritesPersec'};
	$risc->{$name}->{'2'}->{'readaheadpagespersec'} = $process->{'ReadaheadpagesPersec'};
	$risc->{$name}->{'2'}->{'targetpages'} = $process->{'Targetpages'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	
	foreach  my $process (@$colsqlstat1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	}
	
	foreach  my $process (@$colsqlstat2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$backgroundwriterpagespersec = CAL_PERF_COUNTER_BULK_COUNT('BackgroundwriterpagesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$buffercachehitratio = CAL_PERF_AVERAGE_BULK('buffercachehitratio',$risc,$calname);
	$buffercachehitratio = 	$buffercachehitratio * 100;
	
	$checkpointpagespersec = CAL_PERF_COUNTER_BULK_COUNT('CheckpointpagesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$databasepages = $risc->{$calname}->{'2'}->{'databasepages'}; # CounterType = 65792 uses raw data
	#	print "Databasepages: $databasepages \n\n";
	
	$freeliststallspersec = CAL_PERF_COUNTER_BULK_COUNT('FreeliststallsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$integralcontrollerslope = $risc->{$calname}->{'2'}->{'integralcontrollerslope'}; # CounterType = 65792 uses raw data
	#	print "IntegralControllerSlope: $integralcontrollerslope \n\n";
	
	$lazywritespersec = CAL_PERF_COUNTER_BULK_COUNT('LazywritesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$pagelifeexpectancy = $risc->{$calname}->{'2'}->{'pagelifeexpectancy'}; # CounterType = 65792 uses raw data
	#	print "Pagelifeexpectancy: $pagelifeexpectancy \n\n";
	
	$pagelookupspersec = CAL_PERF_COUNTER_BULK_COUNT('PagelookupsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagereadspersec = CAL_PERF_COUNTER_BULK_COUNT('PagereadsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$pagewritespersec = CAL_PERF_COUNTER_BULK_COUNT('PagewritesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$readaheadpagespersec = CAL_PERF_COUNTER_BULK_COUNT('ReadaheadpagesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$targetpages = $risc->{$calname}->{'2'}->{'targetpages'}; # CounterType = 65792 uses raw data
	#	print "Targetpages: $targetpages \n\n";
	
	$batchrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('BatchRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	# result for pagelookupspersec_to_batchrequestspersec
	if ( int($pagelookupspersec) != 0 && int($batchrequestspersec) != 0 )
	{ $pagelookupspersec_to_batchrequestspersec = $pagelookupspersec / $batchrequestspersec; }
	else { $pagelookupspersec_to_batchrequestspersec = 0; }
	
	# result for readaheadpagespersec_to_pagereadspersec
	if ( int($readaheadpagespersec) != 0 && int($pagereadspersec) != 0 )
	{ $readaheadpagespersec_to_pagereadspersec = ( $readaheadpagespersec * 100 ) / $pagereadspersec; }
	else { $readaheadpagespersec_to_pagereadspersec = 0; }
	
	####################################################
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$backgroundwriterpagespersec
	,$buffercachehitratio
	,$caption
	,$checkpointpagespersec
	,$databasepages
	,$description
	,$freeliststallspersec
	,$integralcontrollerslope
	,$lazywritespersec
	,$namecolumn
	,$pagelifeexpectancy
	,$pagelookupspersec
	,$pagereadspersec
	,$pagewritespersec
	,$readaheadpagespersec
	,$targetpages
	,$batchrequestspersec
	,$pagelookupspersec_to_batchrequestspersec
	,$readaheadpagespersec_to_pagereadspersec
	);
	
	} #end of foreach my $cal (%$risc)

} # end FOREACH (@instanceNameArray)

} #end of SQLBufferMana

sub SQLGenStatis
{

my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLGenStatis (
	deviceid
	,scantime
	,instancename
	,activetemptables
	,caption
	,connectionresetpersec
	,description
	,eventnotificationsdelayeddrop
	,httpauthenticatedrequests
	,logicalconnections
	,loginspersec
	,logoutspersec
	,marsdeadlocks
	,name
	,nonatomicyieldrate
	,processesblocked
	,soapemptyrequests
	,soapmethodinvocations
	,soapsessioninitiaterequests
	,soapsessionterminaterequests
	,soapsqlrequests
	,soapwsdlrequests
	,sqltraceioproviderlockwaits
	,tempdbrecoveryunitid
	,tempdbrowsetid
	,temptablescreationrate
	,temptablesfordestruction
	,traceeventnotificationqueue
	,transactions
	,userconnections
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $activetemptables = undef;
my $caption = undef;
my $connectionresetpersec = undef;
my $description = undef;
my $eventnotificationsdelayeddrop = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $httpauthenticatedrequests = undef;
my $logicalconnections = undef;
my $loginspersec = undef;
my $logoutspersec = undef;
my $marsdeadlocks = undef;
my $namecolumn = undef;
my $nonatomicyieldrate = undef;
my $processesblocked = undef;
my $soapemptyrequests = undef;
my $soapmethodinvocations = undef;
my $soapsessioninitiaterequests = undef;
my $soapsessionterminaterequests = undef;
my $soapsqlrequests = undef;
my $soapwsdlrequests = undef;
my $sqltraceioproviderlockwaits = undef;
my $tempdbrecoveryunitid = undef;
my $tempdbrowsetid = undef;
my $temptablescreationrate = undef;
my $temptablesfordestruction = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $traceeventnotificationqueue = undef;
my $transactions = undef;
my $userconnections = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "GeneralStatistics";

	##########################
	#---Collect Statistics---#
	##########################
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'activetemptables'} = $process->{'ActiveTempTables'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'connectionresetpersec'} = $process->{'ConnectionResetPersec'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'eventnotificationsdelayeddrop'} = $process->{'EventNotificationsDelayedDrop'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'httpauthenticatedrequests'} = $process->{'HTTPAuthenticatedRequests'};
	$risc->{$name}->{'1'}->{'logicalconnections'} = $process->{'LogicalConnections'};
	$risc->{$name}->{'1'}->{'loginspersec'} = $process->{'LoginsPersec'};
	$risc->{$name}->{'1'}->{'logoutspersec'} = $process->{'LogoutsPersec'};
	$risc->{$name}->{'1'}->{'marsdeadlocks'} = $process->{'MarsDeadlocks'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'nonatomicyieldrate'} = $process->{'Nonatomicyieldrate'};
	$risc->{$name}->{'1'}->{'processesblocked'} = $process->{'Processesblocked'};
	$risc->{$name}->{'1'}->{'soapemptyrequests'} = $process->{'SOAPEmptyRequests'};
	$risc->{$name}->{'1'}->{'soapmethodinvocations'} = $process->{'SOAPMethodInvocations'};
	$risc->{$name}->{'1'}->{'soapsessioninitiaterequests'} = $process->{'SOAPSessionInitiateRequests'};
	$risc->{$name}->{'1'}->{'soapsessionterminaterequests'} = $process->{'SOAPSessionTerminateRequests'};
	$risc->{$name}->{'1'}->{'soapsqlrequests'} = $process->{'SOAPSQLRequests'};
	$risc->{$name}->{'1'}->{'soapwsdlrequests'} = $process->{'SOAPWSDLRequests'};
	$risc->{$name}->{'1'}->{'sqltraceioproviderlockwaits'} = $process->{'SQLTraceIOProviderLockWaits'};
	$risc->{$name}->{'1'}->{'tempdbrecoveryunitid'} = $process->{'Tempdbrecoveryunitid'};
	$risc->{$name}->{'1'}->{'tempdbrowsetid'} = $process->{'Tempdbrowsetid'};
	$risc->{$name}->{'1'}->{'temptablescreationrate'} = $process->{'TempTablesCreationRate'};
	$risc->{$name}->{'1'}->{'temptablesfordestruction'} = $process->{'TempTablesForDestruction'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'traceeventnotificationqueue'} = $process->{'TraceEventNotificationQueue'};
	$risc->{$name}->{'1'}->{'transactions'} = $process->{'Transactions'};
	$risc->{$name}->{'1'}->{'userconnections'} = $process->{'UserConnections'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'activetemptables'} = $process->{'ActiveTempTables'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'connectionresetpersec'} = $process->{'ConnectionResetPersec'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'eventnotificationsdelayeddrop'} = $process->{'EventNotificationsDelayedDrop'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'httpauthenticatedrequests'} = $process->{'HTTPAuthenticatedRequests'};
	$risc->{$name}->{'2'}->{'logicalconnections'} = $process->{'LogicalConnections'};
	$risc->{$name}->{'2'}->{'loginspersec'} = $process->{'LoginsPersec'};
	$risc->{$name}->{'2'}->{'logoutspersec'} = $process->{'LogoutsPersec'};
	$risc->{$name}->{'2'}->{'marsdeadlocks'} = $process->{'MarsDeadlocks'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'nonatomicyieldrate'} = $process->{'Nonatomicyieldrate'};
	$risc->{$name}->{'2'}->{'processesblocked'} = $process->{'Processesblocked'};
	$risc->{$name}->{'2'}->{'soapemptyrequests'} = $process->{'SOAPEmptyRequests'};
	$risc->{$name}->{'2'}->{'soapmethodinvocations'} = $process->{'SOAPMethodInvocations'};
	$risc->{$name}->{'2'}->{'soapsessioninitiaterequests'} = $process->{'SOAPSessionInitiateRequests'};
	$risc->{$name}->{'2'}->{'soapsessionterminaterequests'} = $process->{'SOAPSessionTerminateRequests'};
	$risc->{$name}->{'2'}->{'soapsqlrequests'} = $process->{'SOAPSQLRequests'};
	$risc->{$name}->{'2'}->{'soapwsdlrequests'} = $process->{'SOAPWSDLRequests'};
	$risc->{$name}->{'2'}->{'sqltraceioproviderlockwaits'} = $process->{'SQLTraceIOProviderLockWaits'};
	$risc->{$name}->{'2'}->{'tempdbrecoveryunitid'} = $process->{'Tempdbrecoveryunitid'};
	$risc->{$name}->{'2'}->{'tempdbrowsetid'} = $process->{'Tempdbrowsetid'};
	$risc->{$name}->{'2'}->{'temptablescreationrate'} = $process->{'TempTablesCreationRate'};
	$risc->{$name}->{'2'}->{'temptablesfordestruction'} = $process->{'TempTablesForDestruction'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'traceeventnotificationqueue'} = $process->{'TraceEventNotificationQueue'};
	$risc->{$name}->{'2'}->{'transactions'} = $process->{'Transactions'};
	$risc->{$name}->{'2'}->{'userconnections'} = $process->{'UserConnections'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scanlars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$activetemptables = $risc->{$calname}->{'2'}->{'activetemptables'}; # CounterType = 65792 uses raw data
	print "ActiveTempTables: $activetemptables \n\n";
	
	$connectionresetpersec = CAL_PERF_COUNTER_BULK_COUNT('ConnectionResetPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$eventnotificationsdelayeddrop = $risc->{$calname}->{'2'}->{'eventnotificationsdelayeddrop'}; # CounterType = 65792 uses raw data
	print "EventNotificationsDelayedDrop: $eventnotificationsdelayeddrop \n\n";
	
	$httpauthenticatedrequests = CAL_PERF_COUNTER_BULK_COUNT('HTTPAuthenticatedRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logicalconnections = $risc->{$calname}->{'2'}->{'logicalconnections'}; # CounterType = 65792 uses raw data
	print "LogicalConnections: $logicalconnections \n\n";
	
	$loginspersec = CAL_PERF_COUNTER_BULK_COUNT('LoginsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logoutspersec = CAL_PERF_COUNTER_BULK_COUNT('LogoutsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$marsdeadlocks = CAL_PERF_COUNTER_BULK_COUNT('MarsDeadlocks',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$nonatomicyieldrate = CAL_PERF_COUNTER_BULK_COUNT('Nonatomicyieldrate',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$processesblocked = $risc->{$calname}->{'2'}->{'processesblocked'}; # CounterType = 65792 uses raw data
	print "Processesblocked: $processesblocked \n\n";
	
	$soapemptyrequests = CAL_PERF_COUNTER_BULK_COUNT('SOAPEmptyRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$soapmethodinvocations = CAL_PERF_COUNTER_BULK_COUNT('SOAPMethodInvocations',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$soapsessioninitiaterequests = CAL_PERF_COUNTER_BULK_COUNT('SOAPSessionInitiateRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$soapsessionterminaterequests = CAL_PERF_COUNTER_BULK_COUNT('SOAPSessionTerminateRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$soapsqlrequests = CAL_PERF_COUNTER_BULK_COUNT('SOAPSQLRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$soapwsdlrequests = CAL_PERF_COUNTER_BULK_COUNT('SOAPWSDLRequests',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$sqltraceioproviderlockwaits = CAL_PERF_COUNTER_BULK_COUNT('SQLTraceIOProviderLockWaits',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$tempdbrecoveryunitid = CAL_PERF_COUNTER_BULK_COUNT('Tempdbrecoveryunitid',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$tempdbrowsetid = CAL_PERF_COUNTER_BULK_COUNT('Tempdbrowsetid',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$temptablescreationrate = CAL_PERF_COUNTER_BULK_COUNT('TempTablesCreationRate',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$temptablesfordestruction = $risc->{$calname}->{'2'}->{'temptablesfordestruction'}; # CounterType = 65792 uses raw data
	print "TempTablesForDestruction: $temptablesfordestruction \n\n";
	
	$traceeventnotificationqueue = $risc->{$calname}->{'2'}->{'traceeventnotificationqueue'}; # CounterType = 65792 uses raw data
	print "TraceEventNotificationQueue: $traceeventnotificationqueue \n\n";
	
	$transactions = $risc->{$calname}->{'2'}->{'transactions'}; # CounterType = 65792 uses raw data
	print "Transactions: $transactions \n\n";
	
	$userconnections = $risc->{$calname}->{'2'}->{'userconnections'}; # CounterType = 65792 uses raw data
	print "UserConnections: $userconnections \n\n";
	
	####################################################
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$activetemptables
	,$caption
	,$connectionresetpersec
	,$description
	,$eventnotificationsdelayeddrop
	,$httpauthenticatedrequests
	,$logicalconnections
	,$loginspersec
	,$logoutspersec
	,$marsdeadlocks
	,$namecolumn
	,$nonatomicyieldrate
	,$processesblocked
	,$soapemptyrequests
	,$soapmethodinvocations
	,$soapsessioninitiaterequests
	,$soapsessionterminaterequests
	,$soapsqlrequests
	,$soapwsdlrequests
	,$sqltraceioproviderlockwaits
	,$tempdbrecoveryunitid
	,$tempdbrowsetid
	,$temptablescreationrate
	,$temptablesfordestruction
	,$traceeventnotificationqueue
	,$transactions
	,$userconnections
	);
	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of SQLGenStatis

sub SQLLatches
{

my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLLatches (
	deviceid
	,scantime
	,instancename
	,averagelatchwaittimems
	,caption
	,description
	,latchwaitspersec
	,name
	,numberofsuperlatches
	,superlatchdemotionspersec
	,superlatchpromotionspersec
	,totallatchwaittimems
	,totallatchwaittimems_to_latchwaitspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $averagelatchwaittimems = undef;
my $averagelatchwaittimems_base = undef;
my $caption = undef;
my $description = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $latchwaitspersec = undef;
my $namecolumn = undef;
my $numberofsuperlatches = undef;
my $superlatchdemotionspersec = undef;
my $superlatchpromotionspersec = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $totallatchwaittimems = undef;
my $totallatchwaittimems_to_latchwaitspersec;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "Latches";

	##########################
	#---Collect Statistics---#
	##########################
	
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'averagelatchwaittimems'} = $process->{'AverageLatchWaitTimems'};
	$risc->{$name}->{'1'}->{'averagelatchwaittimems_base'} = $process->{'AverageLatchWaitTimems_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'latchwaitspersec'} = $process->{'LatchWaitsPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'numberofsuperlatches'} = $process->{'NumberofSuperLatches'};
	$risc->{$name}->{'1'}->{'superlatchdemotionspersec'} = $process->{'SuperLatchDemotionsPersec'};
	$risc->{$name}->{'1'}->{'superlatchpromotionspersec'} = $process->{'SuperLatchPromotionsPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totallatchwaittimems'} = $process->{'TotalLatchWaitTimems'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'averagelatchwaittimems'} = $process->{'AverageLatchWaitTimems'};
	$risc->{$name}->{'2'}->{'averagelatchwaittimems_base'} = $process->{'AverageLatchWaitTimems_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'latchwaitspersec'} = $process->{'LatchWaitsPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'numberofsuperlatches'} = $process->{'NumberofSuperLatches'};
	$risc->{$name}->{'2'}->{'superlatchdemotionspersec'} = $process->{'SuperLatchDemotionsPersec'};
	$risc->{$name}->{'2'}->{'superlatchpromotionspersec'} = $process->{'SuperLatchPromotionsPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totallatchwaittimems'} = $process->{'TotalLatchWaitTimems'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$averagelatchwaittimems = CAL_PERF_AVERAGE_BULK('averagelatchwaittimems',$risc,$calname);
	$latchwaitspersec = CAL_PERF_COUNTER_BULK_COUNT('LatchWaitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$numberofsuperlatches = $risc->{$calname}->{'2'}->{'numberofsuperlatches'}; # CounterType = 65792 uses raw data
	print "NumberofSuperLatches: $numberofsuperlatches \n\n";
	
	$superlatchdemotionspersec = CAL_PERF_COUNTER_BULK_COUNT('SuperLatchDemotionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$superlatchpromotionspersec = CAL_PERF_COUNTER_BULK_COUNT('SuperLatchPromotionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$totallatchwaittimems = CAL_PERF_COUNTER_BULK_COUNT('TotalLatchWaitTimems',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	# result for totallatchwaittimems_to_latchwaitspersec
	if ( int($totallatchwaittimems) != 0 && int($latchwaitspersec) != 0 )
	{ $totallatchwaittimems_to_latchwaitspersec = $totallatchwaittimems / $latchwaitspersec; }
	else { $totallatchwaittimems_to_latchwaitspersec = 0; }
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$averagelatchwaittimems
	,$caption
	,$description
	,$latchwaitspersec
	,$namecolumn
	,$numberofsuperlatches
	,$superlatchdemotionspersec
	,$superlatchpromotionspersec
	,$totallatchwaittimems
	,$totallatchwaittimems_to_latchwaitspersec
	);
	
	} ### end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} ### end of SQLLatches

sub SQLLocks
{

my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLLocks (
	deviceid
	,scantime
	,instancename
	,averagewaittimems
	,caption
	,description
	,lockrequestspersec
	,locktimeoutspersec
	,locktimeoutstimeout0persec
	,lockwaitspersec
	,lockwaittimems
	,name
	,numberofdeadlockspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $averagewaittimems = undef;
my $averagewaittimems_base = undef;
my $caption = undef;
my $description = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $lockrequestspersec = undef;
my $locktimeoutspersec = undef;
my $locktimeoutstimeout0persec = undef;
my $lockwaitspersec = undef;
my $lockwaittimems = undef;
my $namecolumn = undef;
my $numberofdeadlockspersec = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;


#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "Locks";

	##########################
	#---Collect Statistics---#
	##########################
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'averagewaittimems'} = $process->{'AverageWaitTimems'};
	$risc->{$name}->{'1'}->{'averagewaittimems_base'} = $process->{'AverageWaitTimems_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'lockrequestspersec'} = $process->{'LockRequestsPersec'};
	$risc->{$name}->{'1'}->{'locktimeoutspersec'} = $process->{'LockTimeoutsPersec'};
	$risc->{$name}->{'1'}->{'locktimeoutstimeout0persec'} = $process->{'LockTimeoutstimeout0Persec'};
	$risc->{$name}->{'1'}->{'lockwaitspersec'} = $process->{'LockWaitsPersec'};
	$risc->{$name}->{'1'}->{'lockwaittimems'} = $process->{'LockWaitTimems'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'numberofdeadlockspersec'} = $process->{'NumberofDeadlocksPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'averagewaittimems'} = $process->{'AverageWaitTimems'};
	$risc->{$name}->{'2'}->{'averagewaittimems_base'} = $process->{'AverageWaitTimems_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'lockrequestspersec'} = $process->{'LockRequestsPersec'};
	$risc->{$name}->{'2'}->{'locktimeoutspersec'} = $process->{'LockTimeoutsPersec'};
	$risc->{$name}->{'2'}->{'locktimeoutstimeout0persec'} = $process->{'LockTimeoutstimeout0Persec'};
	$risc->{$name}->{'2'}->{'lockwaitspersec'} = $process->{'LockWaitsPersec'};
	$risc->{$name}->{'2'}->{'lockwaittimems'} = $process->{'LockWaitTimems'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'numberofdeadlockspersec'} = $process->{'NumberofDeadlocksPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	

	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB

	$averagewaittimems = CAL_PERF_AVERAGE_BULK('averagewaittimems',$risc,$calname);
	$lockrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('LockRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$locktimeoutspersec = CAL_PERF_COUNTER_BULK_COUNT('LockTimeoutsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$locktimeoutstimeout0persec = CAL_PERF_COUNTER_BULK_COUNT('LockTimeoutstimeout0Persec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lockwaitspersec = CAL_PERF_COUNTER_BULK_COUNT('LockWaitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$lockwaittimems = CAL_PERF_COUNTER_BULK_COUNT('LockWaitTimems',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$numberofdeadlockspersec = CAL_PERF_COUNTER_BULK_COUNT('NumberofDeadlocksPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$averagewaittimems
	,$caption
	,$description
	,$lockrequestspersec
	,$locktimeoutspersec
	,$locktimeoutstimeout0persec
	,$lockwaitspersec
	,$lockwaittimems
	,$namecolumn
	,$numberofdeadlockspersec
	);
	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of SQLLocks

sub SQLMemMan
{
##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLMemMan (
	deviceid
	,scantime
	,instancename
	,caption
	,connectionmemorykb
	,databasecachememorykb
	,description
	,externalbenefitofmemory
	,freememorykb
	,grantedworkspacememorykb
	,lockblocks
	,lockblocksallocated
	,lockmemorykb
	,lockownerblocks
	,lockownerblocksallocated
	,logpoolmemorykb
	,maximumworkspacememorykb
	,memorygrantsoutstanding
	,memorygrantspending
	,name
	,optimizermemorykb
	,reservedservermemorykb
	,sqlcachememorykb
	,stolenservermemorykb
	,targetservermemorykb
	,totalservermemorykb
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $caption = undef;
my $connectionmemorykb = undef;
my $databasecachememorykb = undef;
my $description = undef;
my $externalbenefitofmemory = undef;
my $freememorykb = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $grantedworkspacememorykb = undef;
my $lockblocks = undef;
my $lockblocksallocated = undef;
my $lockmemorykb = undef;
my $lockownerblocks = undef;
my $lockownerblocksallocated = undef;
my $logpoolmemorykb = undef;
my $maximumworkspacememorykb = undef;
my $memorygrantsoutstanding = undef;
my $memorygrantspending = undef;
my $namecolumn = undef;
my $optimizermemorykb = undef;
my $reservedservermemorykb = undef;
my $sqlcachememorykb = undef;
my $stolenservermemorykb = undef;
my $targetservermemorykb = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $totalservermemorykb = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "MemoryManager";

	##########################
	#---Collect Statistics---#
	##########################
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'connectionmemorykb'} = $process->{'ConnectionMemoryKB'};
	$risc->{$name}->{'1'}->{'databasecachememorykb'} = $process->{'DatabaseCacheMemoryKB'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'externalbenefitofmemory'} = $process->{'Externalbenefitofmemory'};
	$risc->{$name}->{'1'}->{'freememorykb'} = $process->{'FreeMemoryKB'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'grantedworkspacememorykb'} = $process->{'GrantedWorkspaceMemoryKB'};
	$risc->{$name}->{'1'}->{'lockblocks'} = $process->{'LockBlocks'};
	$risc->{$name}->{'1'}->{'lockblocksallocated'} = $process->{'LockBlocksAllocated'};
	$risc->{$name}->{'1'}->{'lockmemorykb'} = $process->{'LockMemoryKB'};
	$risc->{$name}->{'1'}->{'lockownerblocks'} = $process->{'LockOwnerBlocks'};
	$risc->{$name}->{'1'}->{'lockownerblocksallocated'} = $process->{'LockOwnerBlocksAllocated'};
	$risc->{$name}->{'1'}->{'logpoolmemorykb'} = $process->{'LogPoolMemoryKB'};
	$risc->{$name}->{'1'}->{'maximumworkspacememorykb'} = $process->{'MaximumWorkspaceMemoryKB'};
	$risc->{$name}->{'1'}->{'memorygrantsoutstanding'} = $process->{'MemoryGrantsOutstanding'};
	$risc->{$name}->{'1'}->{'memorygrantspending'} = $process->{'MemoryGrantsPending'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'optimizermemorykb'} = $process->{'OptimizerMemoryKB'};
	$risc->{$name}->{'1'}->{'reservedservermemorykb'} = $process->{'ReservedServerMemoryKB'};
	$risc->{$name}->{'1'}->{'sqlcachememorykb'} = $process->{'SQLCacheMemoryKB'};
	$risc->{$name}->{'1'}->{'stolenservermemorykb'} = $process->{'StolenServerMemoryKB'};
	$risc->{$name}->{'1'}->{'targetservermemorykb'} = $process->{'TargetServerMemoryKB'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'totalservermemorykb'} = $process->{'TotalServerMemoryKB'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'connectionmemorykb'} = $process->{'ConnectionMemoryKB'};
	$risc->{$name}->{'2'}->{'databasecachememorykb'} = $process->{'DatabaseCacheMemoryKB'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'externalbenefitofmemory'} = $process->{'Externalbenefitofmemory'};
	$risc->{$name}->{'2'}->{'freememorykb'} = $process->{'FreeMemoryKB'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'grantedworkspacememorykb'} = $process->{'GrantedWorkspaceMemoryKB'};
	$risc->{$name}->{'2'}->{'lockblocks'} = $process->{'LockBlocks'};
	$risc->{$name}->{'2'}->{'lockblocksallocated'} = $process->{'LockBlocksAllocated'};
	$risc->{$name}->{'2'}->{'lockmemorykb'} = $process->{'LockMemoryKB'};
	$risc->{$name}->{'2'}->{'lockownerblocks'} = $process->{'LockOwnerBlocks'};
	$risc->{$name}->{'2'}->{'lockownerblocksallocated'} = $process->{'LockOwnerBlocksAllocated'};
	$risc->{$name}->{'2'}->{'logpoolmemorykb'} = $process->{'LogPoolMemoryKB'};
	$risc->{$name}->{'2'}->{'maximumworkspacememorykb'} = $process->{'MaximumWorkspaceMemoryKB'};
	$risc->{$name}->{'2'}->{'memorygrantsoutstanding'} = $process->{'MemoryGrantsOutstanding'};
	$risc->{$name}->{'2'}->{'memorygrantspending'} = $process->{'MemoryGrantsPending'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'optimizermemorykb'} = $process->{'OptimizerMemoryKB'};
	$risc->{$name}->{'2'}->{'reservedservermemorykb'} = $process->{'ReservedServerMemoryKB'};
	$risc->{$name}->{'2'}->{'sqlcachememorykb'} = $process->{'SQLCacheMemoryKB'};
	$risc->{$name}->{'2'}->{'stolenservermemorykb'} = $process->{'StolenServerMemoryKB'};
	$risc->{$name}->{'2'}->{'targetservermemorykb'} = $process->{'TargetServerMemoryKB'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'totalservermemorykb'} = $process->{'TotalServerMemoryKB'};
	}
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	
	$connectionmemorykb = $risc->{$calname}->{'2'}->{'connectionmemorykb'}; # CounterType = 65792 uses raw data
	print "ConnectionMemoryKB: $connectionmemorykb \n\n";
	
	$databasecachememorykb = $risc->{$calname}->{'2'}->{'databasecachememorykb'}; # CounterType = 65792 uses raw data
	print "DatabaseCacheMemoryKB: $databasecachememorykb \n\n";
	
	$externalbenefitofmemory = $risc->{$calname}->{'2'}->{'externalbenefitofmemory'}; # CounterType = 65792 uses raw data
	print "Externalbenefitofmemory: $externalbenefitofmemory \n\n";
	
	$freememorykb = $risc->{$calname}->{'2'}->{'freememorykb'}; # CounterType = 65792 uses raw data
	print "FreeMemoryKB: $freememorykb \n\n";
	
	$grantedworkspacememorykb = $risc->{$calname}->{'2'}->{'grantedworkspacememorykb'}; # CounterType = 65792 uses raw data
	print "GrantedWorkspaceMemoryKB: $grantedworkspacememorykb \n\n";
	
	$lockblocks = $risc->{$calname}->{'2'}->{'lockblocks'}; # CounterType = 65792 uses raw data
	print "LockBlocks: $lockblocks \n\n";
	
	$lockblocksallocated = $risc->{$calname}->{'2'}->{'lockblocksallocated'}; # CounterType = 65792 uses raw data
	print "LockBlocksAllocated: $lockblocksallocated \n\n";
	
	$lockmemorykb = $risc->{$calname}->{'2'}->{'lockmemorykb'}; # CounterType = 65792 uses raw data
	print "LockMemoryKB: $lockmemorykb \n\n";
	
	$lockownerblocks = $risc->{$calname}->{'2'}->{'lockownerblocks'}; # CounterType = 65792 uses raw data
	print "LockOwnerBlocks: $lockownerblocks \n\n";
	
	$lockownerblocksallocated = $risc->{$calname}->{'2'}->{'lockownerblocksallocated'}; # CounterType = 65792 uses raw data
	print "LockOwnerBlocksAllocated: $lockownerblocksallocated \n\n";
	
	$logpoolmemorykb = $risc->{$calname}->{'2'}->{'logpoolmemorykb'}; # CounterType = 65792 uses raw data
	print "LogPoolMemoryKB: $logpoolmemorykb \n\n";
	
	$maximumworkspacememorykb = $risc->{$calname}->{'2'}->{'maximumworkspacememorykb'}; # CounterType = 65792 uses raw data
	print "MaximumWorkspaceMemoryKB: $maximumworkspacememorykb \n\n";
	
	$memorygrantsoutstanding = $risc->{$calname}->{'2'}->{'memorygrantsoutstanding'}; # CounterType = 65792 uses raw data
	print "MemoryGrantsOutstanding: $memorygrantsoutstanding \n\n";
	
	$memorygrantspending = $risc->{$calname}->{'2'}->{'memorygrantspending'}; # CounterType = 65792 uses raw data
	print "MemoryGrantsPending: $memorygrantspending \n\n";
	
	$optimizermemorykb = $risc->{$calname}->{'2'}->{'optimizermemorykb'}; # CounterType = 65792 uses raw data
	print "OptimizerMemoryKB: $optimizermemorykb \n\n";
	
	$reservedservermemorykb = $risc->{$calname}->{'2'}->{'reservedservermemorykb'}; # CounterType = 65792 uses raw data
	print "ReservedServerMemoryKB: $reservedservermemorykb \n\n";
	
	$sqlcachememorykb = $risc->{$calname}->{'2'}->{'sqlcachememorykb'}; # CounterType = 65792 uses raw data
	print "SQLCacheMemoryKB: $sqlcachememorykb \n\n";
	
	$stolenservermemorykb = $risc->{$calname}->{'2'}->{'stolenservermemorykb'}; # CounterType = 65792 uses raw data
	print "StolenServerMemoryKB: $stolenservermemorykb \n\n";
	
	$targetservermemorykb = $risc->{$calname}->{'2'}->{'targetservermemorykb'}; # CounterType = 65792 uses raw data
	print "TargetServerMemoryKB: $targetservermemorykb \n\n";
	
	$totalservermemorykb = $risc->{$calname}->{'2'}->{'totalservermemorykb'}; # CounterType = 65792 uses raw data
	print "TotalServerMemoryKB: $totalservermemorykb \n\n";
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$caption
	,$connectionmemorykb
	,$databasecachememorykb
	,$description
	,$externalbenefitofmemory
	,$freememorykb
	,$grantedworkspacememorykb
	,$lockblocks
	,$lockblocksallocated
	,$lockmemorykb
	,$lockownerblocks
	,$lockownerblocksallocated
	,$logpoolmemorykb
	,$maximumworkspacememorykb
	,$memorygrantsoutstanding
	,$memorygrantspending
	,$namecolumn
	,$optimizermemorykb
	,$reservedservermemorykb
	,$sqlcachememorykb
	,$stolenservermemorykb
	,$targetservermemorykb
	,$totalservermemorykb
	);
	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of SQLMemMan

sub SQLStatis
{
##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLStatis (
	deviceid
	,scantime
	,instancename
	,autoparamattemptspersec
	,batchrequestspersec
	,caption
	,description
	,failedautoparamspersec
	,forcedparameterizationspersec
	,guidedplanexecutionspersec
	,misguidedplanexecutionspersec
	,name
	,safeautoparamspersec
	,sqlattentionrate
	,sqlcompilationspersec
	,sqlrecompilationspersec
	,unsafeautoparamspersec
	,sqlcompilationspersec_to_batchrequestspersec
	,sqlrecompilationspersec_to_sqlcompilationspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $autoparamattemptspersec = undef;
my $batchrequestspersec = undef;
my $caption = undef;
my $description = undef;
my $failedautoparamspersec = undef;
my $forcedparameterizationspersec = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $guidedplanexecutionspersec = undef;
my $misguidedplanexecutionspersec = undef;
my $namecolumn = undef;
my $safeautoparamspersec = undef;
my $sqlattentionrate = undef;
my $sqlcompilationspersec = undef;
my $sqlrecompilationspersec = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $unsafeautoparamspersec = undef;

my $sqlcompilationspersec_to_batchrequestspersec = undef;
my $sqlrecompilationspersec_to_sqlcompilationspersec = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "SQLStatistics";

	##########################
	#---Collect Statistics---#
	##########################
	my $colProcessorRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colProcessorRawPerf2 = $objWMI->InstancesOf($wmi);
	
	my $risc;
	foreach  my $process (@$colProcessorRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'autoparamattemptspersec'} = $process->{'AutoParamAttemptsPersec'};
	$risc->{$name}->{'1'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'failedautoparamspersec'} = $process->{'FailedAutoParamsPersec'};
	$risc->{$name}->{'1'}->{'forcedparameterizationspersec'} = $process->{'ForcedParameterizationsPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'guidedplanexecutionspersec'} = $process->{'GuidedplanexecutionsPersec'};
	$risc->{$name}->{'1'}->{'misguidedplanexecutionspersec'} = $process->{'MisguidedplanexecutionsPersec'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'safeautoparamspersec'} = $process->{'SafeAutoParamsPersec'};
	$risc->{$name}->{'1'}->{'sqlattentionrate'} = $process->{'SQLAttentionrate'};
	$risc->{$name}->{'1'}->{'sqlcompilationspersec'} = $process->{'SQLCompilationsPersec'};
	$risc->{$name}->{'1'}->{'sqlrecompilationspersec'} = $process->{'SQLReCompilationsPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'unsafeautoparamspersec'} = $process->{'UnsafeAutoParamsPersec'};
	}
	
	foreach  my $process (@$colProcessorRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'autoparamattemptspersec'} = $process->{'AutoParamAttemptsPersec'};
	$risc->{$name}->{'2'}->{'batchrequestspersec'} = $process->{'BatchRequestsPersec'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'failedautoparamspersec'} = $process->{'FailedAutoParamsPersec'};
	$risc->{$name}->{'2'}->{'forcedparameterizationspersec'} = $process->{'ForcedParameterizationsPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'guidedplanexecutionspersec'} = $process->{'GuidedplanexecutionsPersec'};
	$risc->{$name}->{'2'}->{'misguidedplanexecutionspersec'} = $process->{'MisguidedplanexecutionsPersec'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'safeautoparamspersec'} = $process->{'SafeAutoParamsPersec'};
	$risc->{$name}->{'2'}->{'sqlattentionrate'} = $process->{'SQLAttentionrate'};
	$risc->{$name}->{'2'}->{'sqlcompilationspersec'} = $process->{'SQLCompilationsPersec'};
	$risc->{$name}->{'2'}->{'sqlrecompilationspersec'} = $process->{'SQLReCompilationsPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'unsafeautoparamspersec'} = $process->{'UnsafeAutoParamsPersec'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$autoparamattemptspersec = CAL_PERF_COUNTER_BULK_COUNT('AutoParamAttemptsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$batchrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('BatchRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$failedautoparamspersec = CAL_PERF_COUNTER_BULK_COUNT('FailedAutoParamsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$forcedparameterizationspersec = CAL_PERF_COUNTER_BULK_COUNT('ForcedParameterizationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$guidedplanexecutionspersec = CAL_PERF_COUNTER_BULK_COUNT('GuidedplanexecutionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$misguidedplanexecutionspersec = CAL_PERF_COUNTER_BULK_COUNT('MisguidedplanexecutionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$safeautoparamspersec = CAL_PERF_COUNTER_BULK_COUNT('SafeAutoParamsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$sqlattentionrate = CAL_PERF_COUNTER_BULK_COUNT('SQLAttentionrate',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$sqlcompilationspersec = CAL_PERF_COUNTER_BULK_COUNT('SQLCompilationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$sqlrecompilationspersec = CAL_PERF_COUNTER_BULK_COUNT('SQLReCompilationsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$unsafeautoparamspersec = CAL_PERF_COUNTER_BULK_COUNT('UnsafeAutoParamsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	# result for sqlcompilationspersec_to_batchrequestspersec
	if ( $sqlcompilationspersec != 0 && $batchrequestspersec != 0 )
	{ $sqlcompilationspersec_to_batchrequestspersec = ($sqlcompilationspersec * 100) / $batchrequestspersec; }
	else { $sqlcompilationspersec_to_batchrequestspersec = 0; }
	
	# result for sqlrecompilationspersec_to_sqlcompilationspersec
	if ( $sqlcompilationspersec != 0 && $sqlrecompilationspersec != 0 )
	{ $sqlrecompilationspersec_to_sqlcompilationspersec = ($sqlcompilationspersec * 100) / $sqlrecompilationspersec; }
	else { $sqlrecompilationspersec_to_sqlcompilationspersec = 0; }
	
	####################################################
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$autoparamattemptspersec
	,$batchrequestspersec
	,$caption
	,$description
	,$failedautoparamspersec
	,$forcedparameterizationspersec
	,$guidedplanexecutionspersec
	,$misguidedplanexecutionspersec
	,$namecolumn
	,$safeautoparamspersec
	,$sqlattentionrate
	,$sqlcompilationspersec
	,$sqlrecompilationspersec
	,$unsafeautoparamspersec
	,$sqlcompilationspersec_to_batchrequestspersec
	,$sqlrecompilationspersec_to_sqlcompilationspersec
	);
	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of SQLStatis

sub SQLDatabase
{
my $wmi = shift; #wmi class name


##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfsqlDatabase (
	deviceid
	,scantime
	,instancename
	,activetransactions
	,backupperrestorethroughputpersec
	,bulkcopyrowspersec
	,bulkcopythroughputpersec
	,caption
	,committableentries
	,datafilessizekb
	,dbcclogicalscanbytespersec
	,description
	,logbytesflushedpersec
	,logcachehitratio
	,logcachereadspersec
	,logfilessizekb
	,logfilesusedsizekb
	,logflushespersec
	,logflushwaitspersec
	,logflushwaittime
	,logflushwritetimems
	,loggrowths
	,logpoolcachemissespersec
	,logpooldiskreadspersec
	,logpoolrequestspersec
	,logshrinks
	,logtruncations
	,name
	,percentlogused
	,replpendingxacts
	,repltransrate
	,shrinkdatamovementbytespersec
	,trackedtransactionspersec
	,transactionspersec
	,writetransactionspersec
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");


my $instancename = undef;
my $activetransactions = undef;
my $backupperrestorethroughputpersec = undef;
my $bulkcopyrowspersec = undef;
my $bulkcopythroughputpersec = undef;
my $caption = undef;
my $committableentries = undef;
my $datafilessizekb = undef;
my $dbcclogicalscanbytespersec = undef;
my $description = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $logbytesflushedpersec = undef;
my $logcachehitratio = undef;
my $logcachehitratio_base = undef;
my $logcachereadspersec = undef;
my $logfilessizekb = undef;
my $logfilesusedsizekb = undef;
my $logflushespersec = undef;
my $logflushwaitspersec = undef;
my $logflushwaittime = undef;
my $logflushwritetimems = undef;
my $loggrowths = undef;
my $logpoolcachemissespersec = undef;
my $logpooldiskreadspersec = undef;
my $logpoolrequestspersec = undef;
my $logshrinks = undef;
my $logtruncations = undef;
my $namecolumn = undef;
my $percentlogused = undef;
my $replpendingxacts = undef;
my $repltransrate = undef;
my $shrinkdatamovementbytespersec = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $trackedtransactionspersec = undef;
my $transactionspersec = undef;
my $writetransactionspersec = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "Databases";


	##########################
	#---Collect Statistics---#
	##########################
	my $colRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colRawPerf2 = $objWMI->InstancesOf($wmi);
	
	my $risc;
	foreach  my $process (@$colRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'activetransactions'} = $process->{'ActiveTransactions'};
	$risc->{$name}->{'1'}->{'backupperrestorethroughputpersec'} = $process->{'BackupPerRestoreThroughputPersec'};
	$risc->{$name}->{'1'}->{'bulkcopyrowspersec'} = $process->{'BulkCopyRowsPersec'};
	$risc->{$name}->{'1'}->{'bulkcopythroughputpersec'} = $process->{'BulkCopyThroughputPersec'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'committableentries'} = $process->{'Committableentries'};
	$risc->{$name}->{'1'}->{'datafilessizekb'} = $process->{'DataFilesSizeKB'};
	$risc->{$name}->{'1'}->{'dbcclogicalscanbytespersec'} = $process->{'DBCCLogicalScanBytesPersec'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'logbytesflushedpersec'} = $process->{'LogBytesFlushedPersec'};
	$risc->{$name}->{'1'}->{'logcachehitratio'} = $process->{'LogCacheHitRatio'};
	$risc->{$name}->{'1'}->{'logcachehitratio_base'} = $process->{'LogCacheHitRatio_Base'};
	$risc->{$name}->{'1'}->{'logcachereadspersec'} = $process->{'LogCacheReadsPersec'};
	$risc->{$name}->{'1'}->{'logfilessizekb'} = $process->{'LogFilesSizeKB'};
	$risc->{$name}->{'1'}->{'logfilesusedsizekb'} = $process->{'LogFilesUsedSizeKB'};
	$risc->{$name}->{'1'}->{'logflushespersec'} = $process->{'LogFlushesPersec'};
	$risc->{$name}->{'1'}->{'logflushwaitspersec'} = $process->{'LogFlushWaitsPersec'};
	$risc->{$name}->{'1'}->{'logflushwaittime'} = $process->{'LogFlushWaitTime'};
	$risc->{$name}->{'1'}->{'logflushwritetimems'} = $process->{'LogFlushWriteTimems'};
	$risc->{$name}->{'1'}->{'loggrowths'} = $process->{'LogGrowths'};
	$risc->{$name}->{'1'}->{'logpoolcachemissespersec'} = $process->{'LogPoolCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'logpooldiskreadspersec'} = $process->{'LogPoolDiskReadsPersec'};
	$risc->{$name}->{'1'}->{'logpoolrequestspersec'} = $process->{'LogPoolRequestsPersec'};
	$risc->{$name}->{'1'}->{'logshrinks'} = $process->{'LogShrinks'};
	$risc->{$name}->{'1'}->{'logtruncations'} = $process->{'LogTruncations'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'percentlogused'} = $process->{'PercentLogUsed'};
	$risc->{$name}->{'1'}->{'replpendingxacts'} = $process->{'ReplPendingXacts'};
	$risc->{$name}->{'1'}->{'repltransrate'} = $process->{'ReplTransRate'};
	$risc->{$name}->{'1'}->{'shrinkdatamovementbytespersec'} = $process->{'ShrinkDataMovementBytesPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'trackedtransactionspersec'} = $process->{'TrackedtransactionsPersec'};
	$risc->{$name}->{'1'}->{'transactionspersec'} = $process->{'TransactionsPersec'};
	$risc->{$name}->{'1'}->{'writetransactionspersec'} = $process->{'WriteTransactionsPersec'};
	}
	
	foreach  my $process (@$colRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'activetransactions'} = $process->{'ActiveTransactions'};
	$risc->{$name}->{'2'}->{'backupperrestorethroughputpersec'} = $process->{'BackupPerRestoreThroughputPersec'};
	$risc->{$name}->{'2'}->{'bulkcopyrowspersec'} = $process->{'BulkCopyRowsPersec'};
	$risc->{$name}->{'2'}->{'bulkcopythroughputpersec'} = $process->{'BulkCopyThroughputPersec'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'committableentries'} = $process->{'Committableentries'};
	$risc->{$name}->{'2'}->{'datafilessizekb'} = $process->{'DataFilesSizeKB'};
	$risc->{$name}->{'2'}->{'dbcclogicalscanbytespersec'} = $process->{'DBCCLogicalScanBytesPersec'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'logbytesflushedpersec'} = $process->{'LogBytesFlushedPersec'};
	$risc->{$name}->{'2'}->{'logcachehitratio'} = $process->{'LogCacheHitRatio'};
	$risc->{$name}->{'2'}->{'logcachehitratio_base'} = $process->{'LogCacheHitRatio_Base'};
	$risc->{$name}->{'2'}->{'logcachereadspersec'} = $process->{'LogCacheReadsPersec'};
	$risc->{$name}->{'2'}->{'logfilessizekb'} = $process->{'LogFilesSizeKB'};
	$risc->{$name}->{'2'}->{'logfilesusedsizekb'} = $process->{'LogFilesUsedSizeKB'};
	$risc->{$name}->{'2'}->{'logflushespersec'} = $process->{'LogFlushesPersec'};
	$risc->{$name}->{'2'}->{'logflushwaitspersec'} = $process->{'LogFlushWaitsPersec'};
	$risc->{$name}->{'2'}->{'logflushwaittime'} = $process->{'LogFlushWaitTime'};
	$risc->{$name}->{'2'}->{'logflushwritetimems'} = $process->{'LogFlushWriteTimems'};
	$risc->{$name}->{'2'}->{'loggrowths'} = $process->{'LogGrowths'};
	$risc->{$name}->{'2'}->{'logpoolcachemissespersec'} = $process->{'LogPoolCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'logpooldiskreadspersec'} = $process->{'LogPoolDiskReadsPersec'};
	$risc->{$name}->{'2'}->{'logpoolrequestspersec'} = $process->{'LogPoolRequestsPersec'};
	$risc->{$name}->{'2'}->{'logshrinks'} = $process->{'LogShrinks'};
	$risc->{$name}->{'2'}->{'logtruncations'} = $process->{'LogTruncations'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'percentlogused'} = $process->{'PercentLogUsed'};
	$risc->{$name}->{'2'}->{'replpendingxacts'} = $process->{'ReplPendingXacts'};
	$risc->{$name}->{'2'}->{'repltransrate'} = $process->{'ReplTransRate'};
	$risc->{$name}->{'2'}->{'shrinkdatamovementbytespersec'} = $process->{'ShrinkDataMovementBytesPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'trackedtransactionspersec'} = $process->{'TrackedtransactionsPersec'};
	$risc->{$name}->{'2'}->{'transactionspersec'} = $process->{'TransactionsPersec'};
	$risc->{$name}->{'2'}->{'writetransactionspersec'} = $process->{'WriteTransactionsPersec'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	# the following name or instance is created by SQL Server by defaul
	next if ( $namecolumn eq 'master' || $namecolumn eq 'model' || $namecolumn eq 'mssqlsystemresource' || $namecolumn eq 'msdb' || $namecolumn eq 'tempdb' || $namecolumn eq '_Total' );
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$activetransactions = $risc->{$calname}->{'2'}->{'activetransactions'}; # CounterType = 65792 uses raw data
	print "ActiveTransactions: $activetransactions \n\n";
	
	$backupperrestorethroughputpersec = CAL_PERF_COUNTER_BULK_COUNT('BackupPerRestoreThroughputPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$bulkcopyrowspersec = CAL_PERF_COUNTER_BULK_COUNT('BulkCopyRowsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$bulkcopythroughputpersec = CAL_PERF_COUNTER_BULK_COUNT('BulkCopyThroughputPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$committableentries = $risc->{$calname}->{'2'}->{'committableentries'}; # CounterType = 65792 uses raw data
	print "Committableentries: $committableentries \n\n";
	
	$datafilessizekb = $risc->{$calname}->{'2'}->{'datafilessizekb'}; # CounterType = 65792 uses raw data
	print "DataFilesSizeKB: $datafilessizekb \n\n";
	
	$dbcclogicalscanbytespersec = CAL_PERF_COUNTER_BULK_COUNT('DBCCLogicalScanBytesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logbytesflushedpersec = CAL_PERF_COUNTER_BULK_COUNT('LogBytesFlushedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logcachehitratio = CAL_PERF_AVERAGE_BULK('logcachehitratio',$risc,$calname);
	$logcachereadspersec = CAL_PERF_COUNTER_BULK_COUNT('LogCacheReadsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logfilessizekb = $risc->{$calname}->{'2'}->{'logfilessizekb'}; # CounterType = 65792 uses raw data
	print "LogFilesSizeKB: $logfilessizekb \n\n";
	
	$logfilesusedsizekb = $risc->{$calname}->{'2'}->{'logfilesusedsizekb'}; # CounterType = 65792 uses raw data
	print "LogFilesUsedSizeKB: $logfilesusedsizekb \n\n";
	
	$logflushespersec = CAL_PERF_COUNTER_BULK_COUNT('LogFlushesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logflushwaitspersec = CAL_PERF_COUNTER_BULK_COUNT('LogFlushWaitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logflushwaittime = $risc->{$calname}->{'2'}->{'logflushwaittime'}; # CounterType = 65792 uses raw data
	print "LogFlushWaitTime: $logflushwaittime \n\n";
	
	$logflushwritetimems = CAL_PERF_COUNTER_BULK_COUNT('LogFlushWriteTimems',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$loggrowths = $risc->{$calname}->{'2'}->{'loggrowths'}; # CounterType = 65792 uses raw data
	print "LogGrowths: $loggrowths \n\n";
	
	$logpoolcachemissespersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolCacheMissesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logpooldiskreadspersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolDiskReadsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logpoolrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logshrinks = $risc->{$calname}->{'2'}->{'logshrinks'}; # CounterType = 65792 uses raw data
	print "LogShrinks: $logshrinks \n\n";
	
	
	$logtruncations = $risc->{$calname}->{'2'}->{'logtruncations'}; # CounterType = 65792 uses raw data
	print "LogTruncations: $logtruncations \n\n";
	
	$percentlogused = $risc->{$calname}->{'2'}->{'percentlogused'}; # CounterType = 65792 uses raw data
	print "PercentLogUsed: $percentlogused \n\n";
	
	$replpendingxacts = $risc->{$calname}->{'2'}->{'replpendingxacts'}; # CounterType = 65792 uses raw data
	print "ReplPendingXacts: $replpendingxacts \n\n";
	
	$repltransrate = CAL_PERF_COUNTER_BULK_COUNT('ReplTransRate',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$shrinkdatamovementbytespersec = CAL_PERF_COUNTER_BULK_COUNT('ShrinkDataMovementBytesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$trackedtransactionspersec = CAL_PERF_COUNTER_BULK_COUNT('TrackedtransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$transactionspersec = CAL_PERF_COUNTER_BULK_COUNT('TransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$writetransactionspersec = CAL_PERF_COUNTER_BULK_COUNT('WriteTransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$activetransactions
	,$backupperrestorethroughputpersec
	,$bulkcopyrowspersec
	,$bulkcopythroughputpersec
	,$caption
	,$committableentries
	,$datafilessizekb
	,$dbcclogicalscanbytespersec
	,$description
	,$logbytesflushedpersec
	,$logcachehitratio
	,$logcachereadspersec
	,$logfilessizekb
	,$logfilesusedsizekb
	,$logflushespersec
	,$logflushwaitspersec
	,$logflushwaittime
	,$logflushwritetimems
	,$loggrowths
	,$logpoolcachemissespersec
	,$logpooldiskreadspersec
	,$logpoolrequestspersec
	,$logshrinks
	,$logtruncations
	,$namecolumn
	,$percentlogused
	,$replpendingxacts
	,$repltransrate
	,$shrinkdatamovementbytespersec
	,$trackedtransactionspersec
	,$transactionspersec
	,$writetransactionspersec
	);

	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of SQLDatabase

sub CatalogMeta
{
my $wmi = shift; #wmi class name

##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfsqlCatalogMeta (
	deviceid
	,scantime
	,instancename
	,cacheentriescount
	,cacheentriespinnedcount
	,cachehitratio
	,caption
	,description
	,name
	) VALUES (?,?,?,?,?,?,?,?,?)");

my $instancename = undef;
my $cacheentriescount = undef;
my $cacheentriespinnedcount = undef;
my $cachehitratio = undef;
my $cachehitratio_base = undef;
my $caption = undef;
my $description = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $namecolumn = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "CatalogMetadata";

	##########################
	#---Collect Statistics---#
	##########################
	my $colRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colRawPerf2 = $objWMI->InstancesOf($wmi);
	
	
	my $risc;
	foreach  my $process (@$colRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'cacheentriescount'} = $process->{'CacheEntriesCount'};
	$risc->{$name}->{'1'}->{'cacheentriespinnedcount'} = $process->{'CacheEntriesPinnedCount'};
	$risc->{$name}->{'1'}->{'cachehitratio'} = $process->{'CacheHitRatio'};
	$risc->{$name}->{'1'}->{'cachehitratio_base'} = $process->{'CacheHitRatio_Base'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	foreach  my $process (@$colRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'cacheentriescount'} = $process->{'CacheEntriesCount'};
	$risc->{$name}->{'2'}->{'cacheentriespinnedcount'} = $process->{'CacheEntriesPinnedCount'};
	$risc->{$name}->{'2'}->{'cachehitratio'} = $process->{'CacheHitRatio'};
	$risc->{$name}->{'2'}->{'cachehitratio_base'} = $process->{'CacheHitRatio_Base'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	# the folling name or instance is created by SQL Server by defaul
	next if ( $namecolumn eq 'master' || $namecolumn eq 'model' || $namecolumn eq 'mssqlsystemresource' || $namecolumn eq 'msdb' || $namecolumn eq 'tempdb' || $namecolumn eq '_Total' );
	
	#---I use these 4 scalars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	$cacheentriescount = $risc->{$calname}->{'2'}->{'cacheentriescount'}; # CounterType = 65792 uses raw data
	print "CacheEntriesCount: $cacheentriescount \n\n";
	
	$cacheentriespinnedcount = $risc->{$calname}->{'2'}->{'cacheentriespinnedcount'}; # CounterType = 65792 uses raw data
	print "CacheEntriesPinnedCount: $cacheentriespinnedcount \n\n";
	
	$cachehitratio = CAL_PERF_AVERAGE_BULK('cachehitratio',$risc,$calname);
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$cacheentriescount
	,$cacheentriespinnedcount
	,$cachehitratio
	,$caption
	,$description
	,$namecolumn
	);

	
	} #end of foreach my $cal (%$risc)                            

} ### end of FOREACH (@INSTANCENAMEARRAY)

} #end of CatalogMeta

sub SQLDatabasePerf
{

##---store data---#
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLDatabasePerf (
	deviceid
	,scantime
	,instancename
	,activetransactions
	,backupperrestorethroughputpersec
	,bulkcopyrowspersec
	,bulkcopythroughputpersec
	,caption
	,committableentries
	,datafilessizekb
	,dbcclogicalscanbytespersec
	,description
	,logbytesflushedpersec
	,logcachehitratio
	,logcachereadspersec
	,logfilessizekb
	,logfilesusedsizekb
	,logflushespersec
	,logflushwaitspersec
	,logflushwaittime
	,logflushwritetimems
	,loggrowths
	,logpoolcachemissespersec
	,logpooldiskreadspersec
	,logpoolrequestspersec
	,logshrinks
	,logtruncations
	,name
	,percentlogused
	,replpendingxacts
	,repltransrate
	,shrinkdatamovementbytespersec
	,trackedtransactionspersec
	,transactionspersec
	,writetransactionspersec
	,cacheentriescount
	,cacheentriespinnedcount
	,cachehitratio
	) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

# variables for Server Database
my $instancename = undef;
my $activetransactions = undef;
my $backupperrestorethroughputpersec = undef;
my $bulkcopyrowspersec = undef;
my $bulkcopythroughputpersec = undef;
my $caption = undef;
my $committableentries = undef;
my $datafilessizekb = undef;
my $dbcclogicalscanbytespersec = undef;
my $description = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $logbytesflushedpersec = undef;
my $logcachehitratio = undef;
my $logcachehitratio_base = undef;
my $logcachereadspersec = undef;
my $logfilessizekb = undef;
my $logfilesusedsizekb = undef;
my $logflushespersec = undef;
my $logflushwaitspersec = undef;
my $logflushwaittime = undef;
my $logflushwritetimems = undef;
my $loggrowths = undef;
my $logpoolcachemissespersec = undef;
my $logpooldiskreadspersec = undef;
my $logpoolrequestspersec = undef;
my $logshrinks = undef;
my $logtruncations = undef;
my $namecolumn = undef;
my $percentlogused = undef;
my $replpendingxacts = undef;
my $repltransrate = undef;
my $shrinkdatamovementbytespersec = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;
my $trackedtransactionspersec = undef;
my $transactionspersec = undef;
my $writetransactionspersec = undef;

# Varible for Catalog Metadata
my $cacheentriescount = undef;
my $cacheentriespinnedcount = undef;
my $cachehitratio = undef;
my $cachehitratio_base = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl "winperfSQLAccMethods"
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi1 = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "Databases";
	my $wmi2 = "Win32_PerfRawData_MSSQL". $name . "_MSSQL". $name . "CatalogMetadata";

	##########################
	#---Collect Statistics---#
	##########################
	my $colServerData1 = $objWMI->InstancesOf($wmi1);
	my $colCatalog1 = $objWMI->InstancesOf($wmi2);
	sleep 5;
	my $colServerData2 = $objWMI->InstancesOf($wmi1);
	my $colCatalog2 = $objWMI->InstancesOf($wmi2);
	
	my $risc;
	
	foreach  my $process (@$colServerData1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'activetransactions'} = $process->{'ActiveTransactions'};
	$risc->{$name}->{'1'}->{'backupperrestorethroughputpersec'} = $process->{'BackupPerRestoreThroughputPersec'};
	$risc->{$name}->{'1'}->{'bulkcopyrowspersec'} = $process->{'BulkCopyRowsPersec'};
	$risc->{$name}->{'1'}->{'bulkcopythroughputpersec'} = $process->{'BulkCopyThroughputPersec'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'committableentries'} = $process->{'Committableentries'};
	$risc->{$name}->{'1'}->{'datafilessizekb'} = $process->{'DataFilesSizeKB'};
	$risc->{$name}->{'1'}->{'dbcclogicalscanbytespersec'} = $process->{'DBCCLogicalScanBytesPersec'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'logbytesflushedpersec'} = $process->{'LogBytesFlushedPersec'};
	$risc->{$name}->{'1'}->{'logcachehitratio'} = $process->{'LogCacheHitRatio'};
	$risc->{$name}->{'1'}->{'logcachehitratio_base'} = $process->{'LogCacheHitRatio_Base'};
	$risc->{$name}->{'1'}->{'logcachereadspersec'} = $process->{'LogCacheReadsPersec'};
	$risc->{$name}->{'1'}->{'logfilessizekb'} = $process->{'LogFilesSizeKB'};
	$risc->{$name}->{'1'}->{'logfilesusedsizekb'} = $process->{'LogFilesUsedSizeKB'};
	$risc->{$name}->{'1'}->{'logflushespersec'} = $process->{'LogFlushesPersec'};
	$risc->{$name}->{'1'}->{'logflushwaitspersec'} = $process->{'LogFlushWaitsPersec'};
	$risc->{$name}->{'1'}->{'logflushwaittime'} = $process->{'LogFlushWaitTime'};
	$risc->{$name}->{'1'}->{'logflushwritetimems'} = $process->{'LogFlushWriteTimems'};
	$risc->{$name}->{'1'}->{'loggrowths'} = $process->{'LogGrowths'};
	$risc->{$name}->{'1'}->{'logpoolcachemissespersec'} = $process->{'LogPoolCacheMissesPersec'};
	$risc->{$name}->{'1'}->{'logpooldiskreadspersec'} = $process->{'LogPoolDiskReadsPersec'};
	$risc->{$name}->{'1'}->{'logpoolrequestspersec'} = $process->{'LogPoolRequestsPersec'};
	$risc->{$name}->{'1'}->{'logshrinks'} = $process->{'LogShrinks'};
	$risc->{$name}->{'1'}->{'logtruncations'} = $process->{'LogTruncations'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'percentlogused'} = $process->{'PercentLogUsed'};
	$risc->{$name}->{'1'}->{'replpendingxacts'} = $process->{'ReplPendingXacts'};
	$risc->{$name}->{'1'}->{'repltransrate'} = $process->{'ReplTransRate'};
	$risc->{$name}->{'1'}->{'shrinkdatamovementbytespersec'} = $process->{'ShrinkDataMovementBytesPersec'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'1'}->{'trackedtransactionspersec'} = $process->{'TrackedtransactionsPersec'};
	$risc->{$name}->{'1'}->{'transactionspersec'} = $process->{'TransactionsPersec'};
	$risc->{$name}->{'1'}->{'writetransactionspersec'} = $process->{'WriteTransactionsPersec'};
	}
	
	foreach  my $process (@$colServerData2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'activetransactions'} = $process->{'ActiveTransactions'};
	$risc->{$name}->{'2'}->{'backupperrestorethroughputpersec'} = $process->{'BackupPerRestoreThroughputPersec'};
	$risc->{$name}->{'2'}->{'bulkcopyrowspersec'} = $process->{'BulkCopyRowsPersec'};
	$risc->{$name}->{'2'}->{'bulkcopythroughputpersec'} = $process->{'BulkCopyThroughputPersec'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'committableentries'} = $process->{'Committableentries'};
	$risc->{$name}->{'2'}->{'datafilessizekb'} = $process->{'DataFilesSizeKB'};
	$risc->{$name}->{'2'}->{'dbcclogicalscanbytespersec'} = $process->{'DBCCLogicalScanBytesPersec'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'logbytesflushedpersec'} = $process->{'LogBytesFlushedPersec'};
	$risc->{$name}->{'2'}->{'logcachehitratio'} = $process->{'LogCacheHitRatio'};
	$risc->{$name}->{'2'}->{'logcachehitratio_base'} = $process->{'LogCacheHitRatio_Base'};
	$risc->{$name}->{'2'}->{'logcachereadspersec'} = $process->{'LogCacheReadsPersec'};
	$risc->{$name}->{'2'}->{'logfilessizekb'} = $process->{'LogFilesSizeKB'};
	$risc->{$name}->{'2'}->{'logfilesusedsizekb'} = $process->{'LogFilesUsedSizeKB'};
	$risc->{$name}->{'2'}->{'logflushespersec'} = $process->{'LogFlushesPersec'};
	$risc->{$name}->{'2'}->{'logflushwaitspersec'} = $process->{'LogFlushWaitsPersec'};
	$risc->{$name}->{'2'}->{'logflushwaittime'} = $process->{'LogFlushWaitTime'};
	$risc->{$name}->{'2'}->{'logflushwritetimems'} = $process->{'LogFlushWriteTimems'};
	$risc->{$name}->{'2'}->{'loggrowths'} = $process->{'LogGrowths'};
	$risc->{$name}->{'2'}->{'logpoolcachemissespersec'} = $process->{'LogPoolCacheMissesPersec'};
	$risc->{$name}->{'2'}->{'logpooldiskreadspersec'} = $process->{'LogPoolDiskReadsPersec'};
	$risc->{$name}->{'2'}->{'logpoolrequestspersec'} = $process->{'LogPoolRequestsPersec'};
	$risc->{$name}->{'2'}->{'logshrinks'} = $process->{'LogShrinks'};
	$risc->{$name}->{'2'}->{'logtruncations'} = $process->{'LogTruncations'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'percentlogused'} = $process->{'PercentLogUsed'};
	$risc->{$name}->{'2'}->{'replpendingxacts'} = $process->{'ReplPendingXacts'};
	$risc->{$name}->{'2'}->{'repltransrate'} = $process->{'ReplTransRate'};
	$risc->{$name}->{'2'}->{'shrinkdatamovementbytespersec'} = $process->{'ShrinkDataMovementBytesPersec'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	$risc->{$name}->{'2'}->{'trackedtransactionspersec'} = $process->{'TrackedtransactionsPersec'};
	$risc->{$name}->{'2'}->{'transactionspersec'} = $process->{'TransactionsPersec'};
	$risc->{$name}->{'2'}->{'writetransactionspersec'} = $process->{'WriteTransactionsPersec'};
	}
	
	
	foreach  my $process (@$colCatalog1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'cacheentriescount'} = $process->{'CacheEntriesCount'};
	$risc->{$name}->{'1'}->{'cacheentriespinnedcount'} = $process->{'CacheEntriesPinnedCount'};
	$risc->{$name}->{'1'}->{'cachehitratio'} = $process->{'CacheHitRatio'};
	$risc->{$name}->{'1'}->{'cachehitratio_base'} = $process->{'CacheHitRatio_Base'};
	}
	
	foreach  my $process (@$colCatalog2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'cacheentriescount'} = $process->{'CacheEntriesCount'};
	$risc->{$name}->{'2'}->{'cacheentriespinnedcount'} = $process->{'CacheEntriesPinnedCount'};
	$risc->{$name}->{'2'}->{'cachehitratio'} = $process->{'CacheHitRatio'};
	$risc->{$name}->{'2'}->{'cachehitratio_base'} = $process->{'CacheHitRatio_Base'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	# the folling name or instance is created by SQL Server by defaul
#	next if ( $namecolumn eq 'master' || $namecolumn eq 'model' || $namecolumn eq 'mssqlsystemresource' || $namecolumn eq 'msdb' || $namecolumn eq 'tempdb' || $namecolumn eq '_Total' );
	
	#---I use these 4 scanlars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB
	
	##### for Server Database #####
	$activetransactions = $risc->{$calname}->{'2'}->{'activetransactions'}; # CounterType = 65792 uses raw data
	print "ActiveTransactions: $activetransactions \n\n";
	
	$backupperrestorethroughputpersec = CAL_PERF_COUNTER_BULK_COUNT('BackupPerRestoreThroughputPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$bulkcopyrowspersec = CAL_PERF_COUNTER_BULK_COUNT('BulkCopyRowsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$bulkcopythroughputpersec = CAL_PERF_COUNTER_BULK_COUNT('BulkCopyThroughputPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$committableentries = $risc->{$calname}->{'2'}->{'committableentries'}; # CounterType = 65792 uses raw data
	print "Committableentries: $committableentries \n\n";
	
	$datafilessizekb = $risc->{$calname}->{'2'}->{'datafilessizekb'}; # CounterType = 65792 uses raw data
	print "DataFilesSizeKB: $datafilessizekb \n\n";
	
	$dbcclogicalscanbytespersec = CAL_PERF_COUNTER_BULK_COUNT('DBCCLogicalScanBytesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logbytesflushedpersec = CAL_PERF_COUNTER_BULK_COUNT('LogBytesFlushedPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logcachehitratio = CAL_PERF_AVERAGE_BULK('logcachehitratio',$risc,$calname);
	$logcachereadspersec = CAL_PERF_COUNTER_BULK_COUNT('LogCacheReadsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logfilessizekb = $risc->{$calname}->{'2'}->{'logfilessizekb'}; # CounterType = 65792 uses raw data
	print "LogFilesSizeKB: $logfilessizekb \n\n";
	
	$logfilesusedsizekb = $risc->{$calname}->{'2'}->{'logfilesusedsizekb'}; # CounterType = 65792 uses raw data
	print "LogFilesUsedSizeKB: $logfilesusedsizekb \n\n";
	
	$logflushespersec = CAL_PERF_COUNTER_BULK_COUNT('LogFlushesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logflushwaitspersec = CAL_PERF_COUNTER_BULK_COUNT('LogFlushWaitsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logflushwaittime = $risc->{$calname}->{'2'}->{'logflushwaittime'}; # CounterType = 65792 uses raw data
	print "LogFlushWaitTime: $logflushwaittime \n\n";
	
	$logflushwritetimems = CAL_PERF_COUNTER_BULK_COUNT('LogFlushWriteTimems',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$loggrowths = $risc->{$calname}->{'2'}->{'loggrowths'}; # CounterType = 65792 uses raw data
	print "LogGrowths: $loggrowths \n\n";
	
	$logpoolcachemissespersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolCacheMissesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logpooldiskreadspersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolDiskReadsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$logpoolrequestspersec = CAL_PERF_COUNTER_BULK_COUNT('LogPoolRequestsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	$logshrinks = $risc->{$calname}->{'2'}->{'logshrinks'}; # CounterType = 65792 uses raw data
	print "LogShrinks: $logshrinks \n\n";
	
	$logtruncations = $risc->{$calname}->{'2'}->{'logtruncations'}; # CounterType = 65792 uses raw data
	print "LogTruncations: $logtruncations \n\n";
	
	$percentlogused = $risc->{$calname}->{'2'}->{'percentlogused'}; # CounterType = 65792 uses raw data
	print "PercentLogUsed: $percentlogused \n\n";
	
	$replpendingxacts = $risc->{$calname}->{'2'}->{'replpendingxacts'}; # CounterType = 65792 uses raw data
	print "ReplPendingXacts: $replpendingxacts \n\n";
	
	$repltransrate = CAL_PERF_COUNTER_BULK_COUNT('ReplTransRate',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$shrinkdatamovementbytespersec = CAL_PERF_COUNTER_BULK_COUNT('ShrinkDataMovementBytesPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$trackedtransactionspersec = CAL_PERF_COUNTER_BULK_COUNT('TrackedtransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$transactionspersec = CAL_PERF_COUNTER_BULK_COUNT('TransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	$writetransactionspersec = CAL_PERF_COUNTER_BULK_COUNT('WriteTransactionsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	
	##### for Catalog Metadata #####
	$cacheentriescount = $risc->{$calname}->{'2'}->{'cacheentriescount'}; # CounterType = 65792 uses raw data
	print "CacheEntriesCount: $cacheentriescount \n\n";
	
	$cacheentriespinnedcount = $risc->{$calname}->{'2'}->{'cacheentriespinnedcount'}; # CounterType = 65792 uses raw data
	print "CacheEntriesPinnedCount: $cacheentriespinnedcount \n\n";
	
	$cachehitratio = CAL_PERF_AVERAGE_BULK('cachehitratio',$risc,$calname);
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$activetransactions
	,$backupperrestorethroughputpersec
	,$bulkcopyrowspersec
	,$bulkcopythroughputpersec
	,$caption
	,$committableentries
	,$datafilessizekb
	,$dbcclogicalscanbytespersec
	,$description
	,$logbytesflushedpersec
	,$logcachehitratio
	,$logcachereadspersec
	,$logfilessizekb
	,$logfilesusedsizekb
	,$logflushespersec
	,$logflushwaitspersec
	,$logflushwaittime
	,$logflushwritetimems
	,$loggrowths
	,$logpoolcachemissespersec
	,$logpooldiskreadspersec
	,$logpoolrequestspersec
	,$logshrinks
	,$logtruncations
	,$namecolumn
	,$percentlogused
	,$replpendingxacts
	,$repltransrate
	,$shrinkdatamovementbytespersec
	,$trackedtransactionspersec
	,$transactionspersec
	,$writetransactionspersec
	,$cacheentriescount
	,$cacheentriespinnedcount
	,$cachehitratio
	);
	
	
	} #end of foreach my $cal (%$risc)                            

} # end FOREACH (@instanceNameArray)

} #end of SQLDatabasePerf SUB

sub SQLErrors
{
	
my $inserttotable = $mysql->prepare_cached("
	INSERT INTO winperfSQLSQLErrors (
	deviceid
	,scantime
	,instancename
	,caption
	,description
	,errorspersec
	,name
	) VALUES (?,?,?,?,?,?,?)");

my $instancename = undef;
my $caption = undef;
my $description = undef;
my $errorspersec = undef;
my $frequency_object = undef;
my $frequency_perftime = undef;
my $frequency_sys100ns = undef;
my $namecolumn = undef;
my $timestamp_object = undef;
my $timestamp_perftime = undef;
my $timestamp_sys100ns = undef;

#=== collect all instance name of SQL ===# 	
# All instances will list in "root\Microsoft\SqlServer\ComputerManagement11 => FilestreamSettings => Instancename"
# each instance of MS SQL Server can house many database
my $getInstanceName = $objWMI->sqlQuery("FilestreamSettings");
#print Dumper(\$getInstanceName);

my @instanceNameArray;
foreach  my $grap (@$getInstanceName)
{
	my $name = $grap->{'InstanceName'};
	push(@instanceNameArray,$name);
}
#print Dumper(\@instanceNameArray);

# for each instance name of SQL, we will collect its perf and store in tbl
foreach (@instanceNameArray)
{
	my $name = $_;

	$instancename = $name; # => $instancename refer to NAME colum of the table
	# SQL class name depend on instance name
	my $wmi = "Win32_PerfRawData_MSSQL" . $name . "_MSSQL" . $name . "SQLErrors";

	##########################
	#---Collect Statistics---#
	##########################
	my $colRawPerf1 = $objWMI->InstancesOf($wmi);
	sleep 5;
	my $colRawPerf2 = $objWMI->InstancesOf($wmi);
	
	
	my $risc;
	foreach  my $process (@$colRawPerf1) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'1'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'1'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'1'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'1'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'1'}->{'errorspersec'} = $process->{'ErrorsPersec'};
	$risc->{$name}->{'1'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'1'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'1'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'1'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'1'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'1'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'1'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	foreach  my $process (@$colRawPerf2) 
	{
	my $name = $process->{'Name'};
	$risc->{$name}->{'2'}->{'deviceid'} = $process->{'deviceid'};
	$risc->{$name}->{'2'}->{'scantime'} = $process->{'scantime'};
	$risc->{$name}->{'2'}->{'caption'} = $process->{'Caption'};
	$risc->{$name}->{'2'}->{'description'} = $process->{'Description'};
	$risc->{$name}->{'2'}->{'errorspersec'} = $process->{'ErrorsPersec'};
	$risc->{$name}->{'2'}->{'frequency_object'} = $process->{'Frequency_Object'};
	$risc->{$name}->{'2'}->{'frequency_perftime'} = $process->{'Frequency_PerfTime'};
	$risc->{$name}->{'2'}->{'frequency_sys100ns'} = $process->{'Frequency_Sys100NS'};
	$risc->{$name}->{'2'}->{'name'} = $process->{'Name'};
	$risc->{$name}->{'2'}->{'timestamp_object'} = $process->{'Timestamp_Object'};
	$risc->{$name}->{'2'}->{'timestamp_perftime'} = $process->{'Timestamp_PerfTime'};
	$risc->{$name}->{'2'}->{'timestamp_sys100ns'} = $process->{'Timestamp_Sys100NS'};
	}
	
	
	foreach my $cal (keys %$risc)
	{
	my $calname = $cal;
	$caption = $risc->{$calname}->{'2'}->{'caption'};
	$description = $risc->{$calname}->{'2'}->{'description'};
	$namecolumn = $risc->{$calname}->{'2'}->{'name'}; # NAME column from the table.  $name already used
	
	#---I use these 4 scanlars to tem store data for each counter---#
	# $val1 and $val2 to store primary data
	# $val_base1 and $val_base2 to store "BASE" value is required to calcualte
	my $val1;
	my $val2;
	my $val_base1;
	my $val_base2;
	
	my $frequency_perftime2 = $risc->{$calname}->{'2'}->{'frequency_perftime'};
	my $timestamp_perftime1 = $risc->{$calname}->{'1'}->{'timestamp_perftime'};		
	my $timestamp_perftime2 = $risc->{$calname}->{'2'}->{'timestamp_perftime'};
	my $timestamp_sys100ns1 = $risc->{$calname}->{'1'}->{'timestamp_sys100ns'};
	my $timestamp_sys100ns2 = $risc->{$calname}->{'2'}->{'timestamp_sys100ns'};
	
	print "\n$calname\n---------------------------------\n";
	print "freq_perftime2: $frequency_perftime2\n";
	print "time_perftime1: $timestamp_perftime1\n";
	print "tiem_perftime2: $timestamp_perftime2\n";
	print "time_100ns1: $timestamp_sys100ns1\n";
	print "time_100ns2: $timestamp_sys100ns2\n";
	print "---------------------------------\n";
	
	#####################################
	#---find each object of WMI class---#
	#####################################
	# please refer to each SUB at the end of the code for more detail
	# Note: the SUB formula is seperated from WMI Calculation SUB

	$errorspersec = CAL_PERF_COUNTER_BULK_COUNT('ErrorsPersec',$risc,$calname,$timestamp_perftime1,$timestamp_perftime2,$frequency_perftime2);
	
	
	####################################################
	
	
	#---add data to the table---#
	$inserttotable->execute(
	$deviceid
	,$scantime
	,$instancename
	,$caption
	,$description
	,$errorspersec
	,$namecolumn
	);

	} #end of foreach my $cal (%$risc)

} ### end FOREACH (@instanceNameArray)
                            
} #end of SQLErrors