#!/usr/bin/env perl
#
##
use strict;
use Data::Dumper

$Data::Dumper::Sortkeys	= 1;
$Data::Dumper::Terse	= 1;

use Pod::Usage;
use Getopt::Long qw(
	:config
	require_order
	bundling
	no_ignore_case
);

use RISC::Collect::Constants qw(
	:status
	:schema
);

use RISC::Collect::DB;
use RISC::Collect::Logger;
use RISC::Collect::Quirks;

use RISC::riscCreds;
use RISC::riscWindows;

my $logger = RISC::Collect::Logger->new('windows::aux');

my (
	$wmi,
	$collection_id,
	$target,
	$credentialid,
	$debugging
);

GetOptions(
	'id=i'		=> \$collection_id,
	'target=s'	=> \$target,
	'credential=s'	=> \$credentialid,
	'verbose'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
		$debugging = 1;
	}
);

unless (($collection_id) and ($target) and ($credentialid)) {
	$logger->error('bad usage: must supply --id, --target, and --credential');
	exit(EXIT_FAILURE);
}

my $cred_driver = riscCreds->new($target);
my $credential = $cred_driver->getWin($credentialid);
unless ($credential) {
	$logger->error(sprintf('unable to load credential: %s', $cred_driver->err()));
	exit(EXIT_FAILURE);
}

my $db = RISC::Collect::DB->new(COLLECTION_SCHEMA);
if (my $error = $db->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

my $quirks = RISC::Collect::Quirks->new({ db => $db });
my $q = $quirks->get($collection_id);


my $scantime = time();

if ((not $q) or (not defined($q->{'citrix'})) or ($q->{'citrix'})) {
	citrix();
}

$logger->info('complete');
exit(EXIT_SUCCESS);

sub get_wmi {
	return if ($wmi);

	my $wmi_config = {
		collection_id	=> $collection_id,
		user		=> $credential->{'user'},
		password	=> $credential->{'password'},
		domain		=> $credential->{'domain'},
		credid		=> $credential->{'credid'},
		host		=> $target,
		db			=> $db,
		debug		=> $debugging
	};

	$wmi = RISC::riscWindows->new($wmi_config);

	if (my $error = $wmi->err()) {
		$logger->error($error);
		exit(EXIT_FAILURE);
	}
}

sub citrix {
	get_wmi();

	my $terminal_services = $wmi->wmic('Win32_PerfFormattedData_TermService_TerminalServices', {
		fields	=> join(',',
				'ActiveSessions',
				'Caption',
				'Description',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'InactiveSessions',
				'Name',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS',
				'TotalSessions'
			)
	});

	if (($terminal_services) and (scalar @{ $terminal_services })) {
		$quirks->post($collection_id, {
			($q) ? @{ $q } : ( ),
			citrix => 1
		});
	} else {
		$quirks->post($collection_id, {
			($q) ? %{ $q } : ( ),
			citrix => 0
		});
		$logger->info('no citrix');
		return;
	}

	my $terminal_service_session = $wmi->wmic('Win32_PerfFormattedData_TermService_TerminalServicesSession',{
		fields	=> join(',',
				'Caption',
				'Description',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'HandleCount',
				'InputAsyncFrameError',
				'InputAsyncOverflow',
				'InputAsyncOverrun',
				'InputAsyncParityError',
				'InputBytes',
				'InputCompressedBytes',
				'InputCompressFlushes',
				'InputCompressionRatio',
				'InputErrors',
				'InputFrames',
				'InputTimeouts',
				'InputTransportErrors',
				'InputWaitForOutBuf',
				'InputWdBytes',
				'InputWdFrames',
				'Name',
				'OutputAsyncFrameError',
				'OutputAsyncOverflow',
				'OutputAsyncOverrun',
				'OutputAsyncParityError',
				'OutputBytes',
				'OutputCompressedBytes',
				'OutputCompressFlushes',
				'OutputCompressionRatio',
				'OutputErrors',
				'OutputFrames',
				'OutputTimeouts',
				'OutputTransportErrors',
				'OutputWaitForOutBuf',
				'OutputWdBytes',
				'OutputWdFrames',
				'PageFaultsPersec',
				'PageFileBytes',
				'PageFileBytesPeak',
				'PercentPrivilegedTime',
				'PercentProcessorTime',
				'PercentUserTime',
				'PoolNonpagedBytes',
				'PoolPagedBytes',
				'PrivateBytes',
				'ProtocolBitmapCacheHitRatio',
				'ProtocolBitmapCacheHits',
				'ProtocolBitmapCacheReads',
				'ProtocolBrushCacheHitRatio',
				'ProtocolBrushCacheHits',
				'ProtocolBrushCacheReads',
				'ProtocolGlyphCacheHitRatio',
				'ProtocolGlyphCacheHits',
				'ProtocolGlyphCacheReads',
				'ProtocolSaveScreenBitmapCacheHitRatio',
				'ProtocolSaveScreenBitmapCacheHits',
				'ProtocolSaveScreenBitmapCacheReads',
				'ThreadCount',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS',
				'TotalAsyncFrameError',
				'TotalAsyncOverflow',
				'TotalAsyncOverrun',
				'TotalAsyncParityError',
				'TotalBytes',
				'TotalCompressedBytes',
				'TotalCompressFlushes',
				'TotalCompressionRatio',
				'TotalErrors',
				'TotalFrames',
				'TotalProtocolCacheHitRatio',
				'TotalProtocolCacheHits',
				'TotalProtocolCacheReads',
				'TotalTimeouts',
				'TotalTransportErrors',
				'TotalWaitForOutBuf',
				'TotalWdBytes',
				'TotalWdFrames',
				'VirtualBytes',
				'VirtualBytesPeak',
				'WorkingSet',
				'WorkingSetPeak'
			)
	});

	my $ima_networking = $wmi->wmic('Win32_PerfFormattedData_IMAService_CitrixIMANetworking',{
		fields	=> join(',',
				'BytesReceivedPersec',
				'BytesSentPersec',
				'Caption',
				'Description',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'Name',
				'NetworkConnections',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS'
			)
	});

	my $citrix_licensing = $wmi->wmic('Win32_PerfFormattedData_CitrixLicensing_CitrixLicensing',{
		fields	=> join(',',
				'AverageLicenseCheckInResponseTimems',
				'AverageLicenseCheckOutResponseTimems',
				'Caption',
				'Description',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'LastRecordedLicenseCheckInResponseTimems',
				'LastRecordedLicenseCheckOutResponseTimems',
				'LicenseServerConnectionFailure',
				'MaximumLicenseCheckInResponseTimems',
				'MaximumLicenseCheckOutResponseTimems',
				'Name',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS'
			)
	});

	my $metaframe_presentation = $wmi->wmic('Win32_PerfFormattedData_MetaFrameXP_CitrixMetaFramePresentationServer',{
		fields	=> join(',',
				'ApplicationEnumerationsPersec',
				'ApplicationResolutionsFailedPersec',
				'ApplicationResolutionsPersec',
				'ApplicationResolutionTimems',
				'Caption',
				'DataStorebytesread',
				'DataStorebytesreadPersec',
				'DataStorebyteswrittenPersec',
				'DataStoreConnectionFailure',
				'DataStorereads',
				'DataStorereadsPersec',
				'DataStorewritesPersec',
				'Description',
				'DynamicStorebytesreadPersec',
				'DynamicStorebyteswrittenPersec',
				'DynamicStoreGatewayUpdateBytesSent',
				'DynamicStoreGatewayUpdateCount',
				'DynamicStoreQueryCount',
				'DynamicStoreQueryRequestBytesReceived',
				'DynamicStoreQueryResponseBytesSent',
				'DynamicStorereadsPersec',
				'DynamicStoreUpdateBytesReceived',
				'DynamicStoreUpdatePacketsReceived',
				'DynamicStoreUpdateResponseBytesSent',
				'DynamicStorewritesPersec',
				'FilteredApplicationEnumerationsPersec',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'LocalHostCachebytesreadPersec',
				'LocalHostCachebyteswrittenPersec',
				'LocalHostCachereadsPersec',
				'LocalHostCachewritesPersec',
				'MaximumnumberofXMLthreads',
				'Name',
				'NumberofbusyXMLthreads',
				'NumberofXMLthreads',
				'ResolutionWorkItemQueueExecutingCount',
				'ResolutionWorkItemQueueReadyCount',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS',
				'WorkItemQueueExecutingCount',
				'WorkItemQueuePendingCount',
				'WorkItemQueueReadyCount',
				'ZoneElections',
				'ZoneElectionsWon'
			)
	});

	my $ica_session = $wmi->wmic('Win32_PerfFormattedData_CitrixICA_ICASession',{
		fields	=> join(',',
				'Caption',
				'Description',
				'Frequency_Object',
				'Frequency_PerfTime',
				'Frequency_Sys100NS',
				'InputAudioBandwidth',
				'InputClipboardBandwidt',
				'InputCOM1Bandwidth',
				'InputCOM2Bandwidth',
				'InputCOMBandwidth',
				'InputControlChannelBandwidth',
				'InputDriveBandwidth',
				'InputFontDataBandwidth',
				'InputLicensingBandwidth',
				'InputLPT1Bandwidth',
				'InputLPT2Bandwidth',
				'InputManagementBandwidth',
				'InputPNBandwidth',
				'InputPrinterBandwidth',
				'InputSeamlessBandwidth',
				'InputSessionBandwidth',
				'InputSessionCompression',
				'InputSessionLineSpeed',
				'InputSpeedScreenDataChannelBandwidth',
				'InputTextEchoBandwidth',
				'InputThinWireBandwidth',
				'InputVideoFrameBandwidth',
				'LatencyLastRecorded',
				'LatencySessionAverage',
				'LatencySessionDeviation',
				'Name',
				'OutputAudioBandwidth',
				'OutputClipboardBandwidth',
				'OutputCOM1Bandwidth',
				'OutputCOM2Bandwidth',
				'OutputCOMBandwidth',
				'OutputControlChannelBandwidth',
				'OutputDriveBandwidth',
				'OutputFontDataBandwidth',
				'OutputLicensingBandwidth',
				'OutputLPT1Bandwidth',
				'OutputLPT2Bandwidth',
				'OutputManagementBandwidth',
				'OutputPNBandwidth',
				'OutputPrinterBandwidth',
				'OutputSeamlessBandwidth',
				'OutputSessionBandwidth',
				'OutputSessionCompression',
				'OutputSessionLineSpeed',
				'OutputSpeedScreenDataChannelBandwidth',
				'OutputTextEchoBandwidth',
				'OutputThinWireBandwidth',
				'OutputVideoFrameBandwidth',
				'Timestamp_Object',
				'Timestamp_PerfTime',
				'Timestamp_Sys100NS'
			)
	});

	my $ins_terminal_services = $db->prepare("
		INSERT INTO terminalservices
		(
			deviceid,
			scantime,
			ActiveSessions,
			Caption,
			Description,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			InactiveSessions,
			Name,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS,
			TotalSessions
		)
		VALUES
		(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	");

	foreach my $var (@{ $terminal_services }) {
		my $activesessions     = $var->{'ActiveSessions'};
		my $caption            = $var->{'Caption'};
		my $description        = $var->{'Description'};
		my $frequency_object   = $var->{'Frequency_Object'};
		my $frequency_perftime = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns = $var->{'Frequency_Sys100NS'};
		my $inactivesessions   = $var->{'InactiveSessions'};
		my $name               = $var->{'Name'};
		my $timestamp_object   = $var->{'Timestamp_Object'};
		my $timestamp_perftime = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns = $var->{'Timestamp_Sys100NS'};
		my $totalsessions      = $var->{'TotalSessions'};
		$ins_terminal_services->execute(
			$collection_id,
			$scantime,
			$activesessions,
			$caption,
			$description,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$inactivesessions,
			$name,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns,
			$totalsessions
		);
	}

	my $ins_terminal_service_session = $db->prepare("
		INSERT INTO terminalservicessession
		(
			deviceid,
			scantime,
			Caption,
			Description,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			HandleCount,
			InputAsyncFrameError,
			InputAsyncOverflow,
			InputAsyncOverrun,
			InputAsyncParityError,
			InputBytes,
			InputCompressedBytes,
			InputCompressFlushes,
			InputCompressionRatio,
			InputErrors,
			InputFrames,
			InputTimeouts,
			InputTransportErrors,
			InputWaitForOutBuf,
			InputWdBytes,
			InputWdFrames,
			Name,
			OutputAsyncFrameError,
			OutputAsyncOverflow,
			OutputAsyncOverrun,
			OutputAsyncParityError,
			OutputBytes,
			OutputCompressedBytes,
			OutputCompressFlushes,
			OutputCompressionRatio,
			OutputErrors,
			OutputFrames,
			OutputTimeouts,
			OutputTransportErrors,
			OutputWaitForOutBuf,
			OutputWdBytes,
			OutputWdFrames,
			PageFaultsPersec,
			PageFileBytes,
			PageFileBytesPeak,
			PercentPrivilegedTime,
			PercentProcessorTime,
			PercentUserTime,
			PoolNonpagedBytes,
			PoolPagedBytes,
			PrivateBytes,
			ProtocolBitmapCacheHitRatio,
			ProtocolBitmapCacheHits,
			ProtocolBitmapCacheReads,
			ProtocolBrushCacheHitRatio,
			ProtocolBrushCacheHits,
			ProtocolBrushCacheReads,
			ProtocolGlyphCacheHitRatio,
			ProtocolGlyphCacheHits,
			ProtocolGlyphCacheReads,
			ProtocolSaveScreenBitmapCacheHitRatio,
			ProtocolSaveScreenBitmapCacheHits,
			ProtocolSaveScreenBitmapCacheReads,
			ThreadCount,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS,
			TotalAsyncFrameError,
			TotalAsyncOverflow,
			TotalAsyncOverrun,
			TotalAsyncParityError,
			TotalBytes,
			TotalCompressedBytes,
			TotalCompressFlushes,
			TotalCompressionRatio,
			TotalErrors,
			TotalFrames,
			TotalProtocolCacheHitRatio,
			TotalProtocolCacheHits,
			TotalProtocolCacheReads,
			TotalTimeouts,
			TotalTransportErrors,
			TotalWaitForOutBuf,
			TotalWdBytes,
			TotalWdFrames,
			VirtualBytes,
			VirtualBytesPeak,
			WorkingSet,
			WorkingSetPeak
		)
		VALUES
		(
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?
		)
	");

	foreach my $var (@{ $terminal_service_session }) {
		my $caption                               = $var->{'Caption'};
		my $description                           = $var->{'Description'};
		my $frequency_object                      = $var->{'Frequency_Object'};
		my $frequency_perftime                    = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns                    = $var->{'Frequency_Sys100NS'};
		my $handlecount                           = $var->{'HandleCount'};
		my $inputasyncframeerror                  = $var->{'InputAsyncFrameError'};
		my $inputasyncoverflow                    = $var->{'InputAsyncOverflow'};
		my $inputasyncoverrun                     = $var->{'InputAsyncOverrun'};
		my $inputasyncparityerror                 = $var->{'InputAsyncParityError'};
		my $inputbytes                            = $var->{'InputBytes'};
		my $inputcompressedbytes                  = $var->{'InputCompressedBytes'};
		my $inputcompressflushes                  = $var->{'InputCompressFlushes'};
		my $inputcompressionratio                 = $var->{'InputCompressionRatio'};
		my $inputerrors                           = $var->{'InputErrors'};
		my $inputframes                           = $var->{'InputFrames'};
		my $inputtimeouts                         = $var->{'InputTimeouts'};
		my $inputtransporterrors                  = $var->{'InputTransportErrors'};
		my $inputwaitforoutbuf                    = $var->{'InputWaitForOutBuf'};
		my $inputwdbytes                          = $var->{'InputWdBytes'};
		my $inputwdframes                         = $var->{'InputWdFrames'};
		my $name                                  = $var->{'Name'};
		my $outputasyncframeerror                 = $var->{'OutputAsyncFrameError'};
		my $outputasyncoverflow                   = $var->{'OutputAsyncOverflow'};
		my $outputasyncoverrun                    = $var->{'OutputAsyncOverrun'};
		my $outputasyncparityerror                = $var->{'OutputAsyncParityError'};
		my $outputbytes                           = $var->{'OutputBytes'};
		my $outputcompressedbytes                 = $var->{'OutputCompressedBytes'};
		my $outputcompressflushes                 = $var->{'OutputCompressFlushes'};
		my $outputcompressionratio                = $var->{'OutputCompressionRatio'};
		my $outputerrors                          = $var->{'OutputErrors'};
		my $outputframes                          = $var->{'OutputFrames'};
		my $outputtimeouts                        = $var->{'OutputTimeouts'};
		my $outputtransporterrors                 = $var->{'OutputTransportErrors'};
		my $outputwaitforoutbuf                   = $var->{'OutputWaitForOutBuf'};
		my $outputwdbytes                         = $var->{'OutputWdBytes'};
		my $outputwdframes                        = $var->{'OutputWdFrames'};
		my $pagefaultspersec                      = $var->{'PageFaultsPersec'};
		my $pagefilebytes                         = $var->{'PageFileBytes'};
		my $pagefilebytespeak                     = $var->{'PageFileBytesPeak'};
		my $percentprivilegedtime                 = $var->{'PercentPrivilegedTime'};
		my $percentprocessortime                  = $var->{'PercentProcessorTime'};
		my $percentusertime                       = $var->{'PercentUserTime'};
		my $poolnonpagedbytes                     = $var->{'PoolNonpagedBytes'};
		my $poolpagedbytes                        = $var->{'PoolPagedBytes'};
		my $privatebytes                          = $var->{'PrivateBytes'};
		my $protocolbitmapcachehitratio           = $var->{'ProtocolBitmapCacheHitRatio'};
		my $protocolbitmapcachehits               = $var->{'ProtocolBitmapCacheHits'};
		my $protocolbitmapcachereads              = $var->{'ProtocolBitmapCacheReads'};
		my $protocolbrushcachehitratio            = $var->{'ProtocolBrushCacheHitRatio'};
		my $protocolbrushcachehits                = $var->{'ProtocolBrushCacheHits'};
		my $protocolbrushcachereads               = $var->{'ProtocolBrushCacheReads'};
		my $protocolglyphcachehitratio            = $var->{'ProtocolGlyphCacheHitRatio'};
		my $protocolglyphcachehits                = $var->{'ProtocolGlyphCacheHits'};
		my $protocolglyphcachereads               = $var->{'ProtocolGlyphCacheReads'};
		my $protocolsavescreenbitmapcachehitratio = $var->{'ProtocolSaveScreenBitmapCacheHitRatio'};
		my $protocolsavescreenbitmapcachehits     = $var->{'ProtocolSaveScreenBitmapCacheHits'};
		my $protocolsavescreenbitmapcachereads    = $var->{'ProtocolSaveScreenBitmapCacheReads'};
		my $threadcount                           = $var->{'ThreadCount'};
		my $timestamp_object                      = $var->{'Timestamp_Object'};
		my $timestamp_perftime                    = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns                    = $var->{'Timestamp_Sys100NS'};
		my $totalasyncframeerror                  = $var->{'TotalAsyncFrameError'};
		my $totalasyncoverflow                    = $var->{'TotalAsyncOverflow'};
		my $totalasyncoverrun                     = $var->{'TotalAsyncOverrun'};
		my $totalasyncparityerror                 = $var->{'TotalAsyncParityError'};
		my $totalbytes                            = $var->{'TotalBytes'};
		my $totalcompressedbytes                  = $var->{'TotalCompressedBytes'};
		my $totalcompressflushes                  = $var->{'TotalCompressFlushes'};
		my $totalcompressionratio                 = $var->{'TotalCompressionRatio'};
		my $totalerrors                           = $var->{'TotalErrors'};
		my $totalframes                           = $var->{'TotalFrames'};
		my $totalprotocolcachehitratio            = $var->{'TotalProtocolCacheHitRatio'};
		my $totalprotocolcachehits                = $var->{'TotalProtocolCacheHits'};
		my $totalprotocolcachereads               = $var->{'TotalProtocolCacheReads'};
		my $totaltimeouts                         = $var->{'TotalTimeouts'};
		my $totaltransporterrors                  = $var->{'TotalTransportErrors'};
		my $totalwaitforoutbuf                    = $var->{'TotalWaitForOutBuf'};
		my $totalwdbytes                          = $var->{'TotalWdBytes'};
		my $totalwdframes                         = $var->{'TotalWdFrames'};
		my $virtualbytes                          = $var->{'VirtualBytes'};
		my $virtualbytespeak                      = $var->{'VirtualBytesPeak'};
		my $workingset                            = $var->{'WorkingSet'};
		my $workingsetpeak                        = $var->{'WorkingSetPeak'};
		$ins_terminal_service_session->execute(
			$collection_id,
			$scantime,
			$caption,
			$description,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$handlecount,
			$inputasyncframeerror,
			$inputasyncoverflow,
			$inputasyncoverrun,
			$inputasyncparityerror,
			$inputbytes,
			$inputcompressedbytes,
			$inputcompressflushes,
			$inputcompressionratio,
			$inputerrors,
			$inputframes,
			$inputtimeouts,
			$inputtransporterrors,
			$inputwaitforoutbuf,
			$inputwdbytes,
			$inputwdframes,
			$name,
			$outputasyncframeerror,
			$outputasyncoverflow,
			$outputasyncoverrun,
			$outputasyncparityerror,
			$outputbytes,
			$outputcompressedbytes,
			$outputcompressflushes,
			$outputcompressionratio,
			$outputerrors,
			$outputframes,
			$outputtimeouts,
			$outputtransporterrors,
			$outputwaitforoutbuf,
			$outputwdbytes,
			$outputwdframes,
			$pagefaultspersec,
			$pagefilebytes,
			$pagefilebytespeak,
			$percentprivilegedtime,
			$percentprocessortime,
			$percentusertime,
			$poolnonpagedbytes,
			$poolpagedbytes,
			$privatebytes,
			$protocolbitmapcachehitratio,
			$protocolbitmapcachehits,
			$protocolbitmapcachereads,
			$protocolbrushcachehitratio,
			$protocolbrushcachehits,
			$protocolbrushcachereads,
			$protocolglyphcachehitratio,
			$protocolglyphcachehits,
			$protocolglyphcachereads,
			$protocolsavescreenbitmapcachehitratio,
			$protocolsavescreenbitmapcachehits,
			$protocolsavescreenbitmapcachereads,
			$threadcount,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns,
			$totalasyncframeerror,
			$totalasyncoverflow,
			$totalasyncoverrun,
			$totalasyncparityerror,
			$totalbytes,
			$totalcompressedbytes,
			$totalcompressflushes,
			$totalcompressionratio,
			$totalerrors,
			$totalframes,
			$totalprotocolcachehitratio,
			$totalprotocolcachehits,
			$totalprotocolcachereads,
			$totaltimeouts,
			$totaltransporterrors,
			$totalwaitforoutbuf,
			$totalwdbytes,
			$totalwdframes,
			$virtualbytes,
			$virtualbytespeak,
			$workingset,
			$workingsetpeak
		);
	}

	my $ins_ima_networking = $db->prepare("
		INSERT INTO citriximanetworking
		(
			deviceid,
			scantime,
			BytesReceivedPersec,
			BytesSentPersec,
			Caption,
			Description,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			Name,
			NetworkConnections,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS
		)
		VALUES
		(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	");

	foreach my $var (@{$ima_networking}) {
		my $bytesreceivedpersec = $var->{'BytesReceivedPersec'};
		my $bytessentpersec     = $var->{'BytesSentPersec'};
		my $caption             = $var->{'Caption'};
		my $description         = $var->{'Description'};
		my $frequency_object    = $var->{'Frequency_Object'};
		my $frequency_perftime  = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns  = $var->{'Frequency_Sys100NS'};
		my $name                = $var->{'Name'};
		my $networkconnections  = $var->{'NetworkConnections'};
		my $timestamp_object    = $var->{'Timestamp_Object'};
		my $timestamp_perftime  = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns  = $var->{'Timestamp_Sys100NS'};
		$ins_ima_networking->execute(
			$collection_id,
			$scantime,
			$bytesreceivedpersec,
			$bytessentpersec,
			$caption,
			$description,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$name,
			$networkconnections,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns
		);
	}

	my $ins_citrix_licensing = $db->prepare("
		INSERT INTO citrixlicensing
		(
			deviceid,
			scantime,
			AverageLicenseCheckInResponseTimems,
			AverageLicenseCheckOutResponseTimems,
			Caption,
			Description,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			LastRecordedLicenseCheckInResponseTimems,
			LastRecordedLicenseCheckOutResponseTimems,
			LicenseServerConnectionFailure,
			MaximumLicenseCheckInResponseTimems,
			MaximumLicenseCheckOutResponseTimems,
			Name,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS
		)
		VALUES
		(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	");

	foreach my $var (@{ $citrix_licensing }) {
		my $averagelicensecheckinresponsetimems       = $var->{'AverageLicenseCheckInResponseTimems'};
		my $averagelicensecheckoutresponsetimems      = $var->{'AverageLicenseCheckOutResponseTimems'};
		my $caption                                   = $var->{'Caption'};
		my $description                               = $var->{'Description'};
		my $frequency_object                          = $var->{'Frequency_Object'};
		my $frequency_perftime                        = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns                        = $var->{'Frequency_Sys100NS'};
		my $lastrecordedlicensecheckinresponsetimems  = $var->{'LastRecordedLicenseCheckInResponseTimems'};
		my $lastrecordedlicensecheckoutresponsetimems = $var->{'LastRecordedLicenseCheckOutResponseTimems'};
		my $licenseserverconnectionfailure            = $var->{'LicenseServerConnectionFailure'};
		my $maximumlicensecheckinresponsetimems       = $var->{'MaximumLicenseCheckInResponseTimems'};
		my $maximumlicensecheckoutresponsetimems      = $var->{'MaximumLicenseCheckOutResponseTimems'};
		my $name                                      = $var->{'Name'};
		my $timestamp_object                          = $var->{'Timestamp_Object'};
		my $timestamp_perftime                        = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns                        = $var->{'Timestamp_Sys100NS'};
		$ins_citrix_licensing->execute(
			$collection_id,
			$scantime,
			$averagelicensecheckinresponsetimems,
			$averagelicensecheckoutresponsetimems,
			$caption,
			$description,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$lastrecordedlicensecheckinresponsetimems,
			$lastrecordedlicensecheckoutresponsetimems,
			$licenseserverconnectionfailure,
			$maximumlicensecheckinresponsetimems,
			$maximumlicensecheckoutresponsetimems,
			$name,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns
		);
	}

	my $ins_metaframe_presentation = $db->prepare("
		INSERT INTO citrixmetaframepresentationserver
		(
			deviceid,
			scantime,
			ApplicationEnumerationsPersec,
			ApplicationResolutionsFailedPersec,
			ApplicationResolutionsPersec,
			ApplicationResolutionTimems,
			Caption,
			DataStorebytesread,
			DataStorebytesreadPersec,
			DataStorebyteswrittenPersec,
			DataStoreConnectionFailure,
			DataStorereads,
			DataStorereadsPersec,
			DataStorewritesPersec,
			Description,
			DynamicStorebytesreadPersec,
			DynamicStorebyteswrittenPersec,
			DynamicStoreGatewayUpdateBytesSent,
			DynamicStoreGatewayUpdateCount,
			DynamicStoreQueryCount,
			DynamicStoreQueryRequestBytesReceived,
			DynamicStoreQueryResponseBytesSent,
			DynamicStorereadsPersec,
			DynamicStoreUpdateBytesReceived,
			DynamicStoreUpdatePacketsReceived,
			DynamicStoreUpdateResponseBytesSent,
			DynamicStorewritesPersec,
			FilteredApplicationEnumerationsPersec,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			LocalHostCachebytesreadPersec,
			LocalHostCachebyteswrittenPersec,
			LocalHostCachereadsPersec,
			LocalHostCachewritesPersec,
			MaximumnumberofXMLthreads,
			Name,
			NumberofbusyXMLthreads,
			NumberofXMLthreads,
			ResolutionWorkItemQueueExecutingCount,
			ResolutionWorkItemQueueReadyCount,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS,
			WorkItemQueueExecutingCount,
			WorkItemQueuePendingCount,
			WorkItemQueueReadyCount,
			ZoneElections,
			ZoneElectionsWon
		)
		VALUES
		(
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?
		)
	");

	foreach my $var (@{ $metaframe_presentation }) {
		my $applicationenumerationspersec         = $var->{'ApplicationEnumerationsPersec'};
		my $applicationresolutionsfailedpersec    = $var->{'ApplicationResolutionsFailedPersec'};
		my $applicationresolutionspersec          = $var->{'ApplicationResolutionsPersec'};
		my $applicationresolutiontimems           = $var->{'ApplicationResolutionTimems'};
		my $caption                               = $var->{'Caption'};
		my $datastorebytesread                    = $var->{'DataStorebytesread'};
		my $datastorebytesreadpersec              = $var->{'DataStorebytesreadPersec'};
		my $datastorebyteswrittenpersec           = $var->{'DataStorebyteswrittenPersec'};
		my $datastoreconnectionfailure            = $var->{'DataStoreConnectionFailure'};
		my $datastorereads                        = $var->{'DataStorereads'};
		my $datastorereadspersec                  = $var->{'DataStorereadsPersec'};
		my $datastorewritespersec                 = $var->{'DataStorewritesPersec'};
		my $description                           = $var->{'Description'};
		my $dynamicstorebytesreadpersec           = $var->{'DynamicStorebytesreadPersec'};
		my $dynamicstorebyteswrittenpersec        = $var->{'DynamicStorebyteswrittenPersec'};
		my $dynamicstoregatewayupdatebytessent    = $var->{'DynamicStoreGatewayUpdateBytesSent'};
		my $dynamicstoregatewayupdatecount        = $var->{'DynamicStoreGatewayUpdateCount'};
		my $dynamicstorequerycount                = $var->{'DynamicStoreQueryCount'};
		my $dynamicstorequeryrequestbytesreceived = $var->{'DynamicStoreQueryRequestBytesReceived'};
		my $dynamicstorequeryresponsebytessent    = $var->{'DynamicStoreQueryResponseBytesSent'};
		my $dynamicstorereadspersec               = $var->{'DynamicStorereadsPersec'};
		my $dynamicstoreupdatebytesreceived       = $var->{'DynamicStoreUpdateBytesReceived'};
		my $dynamicstoreupdatepacketsreceived     = $var->{'DynamicStoreUpdatePacketsReceived'};
		my $dynamicstoreupdateresponsebytessent   = $var->{'DynamicStoreUpdateResponseBytesSent'};
		my $dynamicstorewritespersec              = $var->{'DynamicStorewritesPersec'};
		my $filteredapplicationenumerationspersec = $var->{'FilteredApplicationEnumerationsPersec'};
		my $frequency_object                      = $var->{'Frequency_Object'};
		my $frequency_perftime                    = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns                    = $var->{'Frequency_Sys100NS'};
		my $localhostcachebytesreadpersec         = $var->{'LocalHostCachebytesreadPersec'};
		my $localhostcachebyteswrittenpersec      = $var->{'LocalHostCachebyteswrittenPersec'};
		my $localhostcachereadspersec             = $var->{'LocalHostCachereadsPersec'};
		my $localhostcachewritespersec            = $var->{'LocalHostCachewritesPersec'};
		my $maximumnumberofxmlthreads             = $var->{'MaximumnumberofXMLthreads'};
		my $name                                  = $var->{'Name'};
		my $numberofbusyxmlthreads                = $var->{'NumberofbusyXMLthreads'};
		my $numberofxmlthreads                    = $var->{'NumberofXMLthreads'};
		my $resolutionworkitemqueueexecutingcount = $var->{'ResolutionWorkItemQueueExecutingCount'};
		my $resolutionworkitemqueuereadycount     = $var->{'ResolutionWorkItemQueueReadyCount'};
		my $timestamp_object                      = $var->{'Timestamp_Object'};
		my $timestamp_perftime                    = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns                    = $var->{'Timestamp_Sys100NS'};
		my $workitemqueueexecutingcount           = $var->{'WorkItemQueueExecutingCount'};
		my $workitemqueuependingcount             = $var->{'WorkItemQueuePendingCount'};
		my $workitemqueuereadycount               = $var->{'WorkItemQueueReadyCount'};
		my $zoneelections                         = $var->{'ZoneElections'};
		my $zoneelectionswon                      = $var->{'ZoneElectionsWon'};
		$ins_metaframe_presentation->execute(
			$collection_id,
			$scantime,
			$applicationenumerationspersec,
			$applicationresolutionsfailedpersec,
			$applicationresolutionspersec,
			$applicationresolutiontimems,
			$caption,
			$datastorebytesread,
			$datastorebytesreadpersec,
			$datastorebyteswrittenpersec,
			$datastoreconnectionfailure,
			$datastorereads,
			$datastorereadspersec,
			$datastorewritespersec,
			$description,
			$dynamicstorebytesreadpersec,
			$dynamicstorebyteswrittenpersec,
			$dynamicstoregatewayupdatebytessent,
			$dynamicstoregatewayupdatecount,
			$dynamicstorequerycount,
			$dynamicstorequeryrequestbytesreceived,
			$dynamicstorequeryresponsebytessent,
			$dynamicstorereadspersec,
			$dynamicstoreupdatebytesreceived,
			$dynamicstoreupdatepacketsreceived,
			$dynamicstoreupdateresponsebytessent,
			$dynamicstorewritespersec,
			$filteredapplicationenumerationspersec,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$localhostcachebytesreadpersec,
			$localhostcachebyteswrittenpersec,
			$localhostcachereadspersec,
			$localhostcachewritespersec,
			$maximumnumberofxmlthreads,
			$name,
			$numberofbusyxmlthreads,
			$numberofxmlthreads,
			$resolutionworkitemqueueexecutingcount,
			$resolutionworkitemqueuereadycount,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns,
			$workitemqueueexecutingcount,
			$workitemqueuependingcount,
			$workitemqueuereadycount,
			$zoneelections,
			$zoneelectionswon
		);
	}

	my $ins_ica_session = $db->prepare("
		INSERT INTO icasession
		(
			deviceid,
			scantime,
			Caption,
			Description,
			Frequency_Object,
			Frequency_PerfTime,
			Frequency_Sys100NS,
			InputAudioBandwidth,
			InputClipboardBandwidt,
			InputCOM1Bandwidth,
			InputCOM2Bandwidth,
			InputCOMBandwidth,
			InputControlChannelBandwidth,
			InputDriveBandwidth,
			InputFontDataBandwidth,
			InputLicensingBandwidth,
			InputLPT1Bandwidth,
			InputLPT2Bandwidth,
			InputManagementBandwidth,
			InputPNBandwidth,
			InputPrinterBandwidth,
			InputSeamlessBandwidth,
			InputSessionBandwidth,
			InputSessionCompression,
			InputSessionLineSpeed,
			InputSpeedScreenDataChannelBandwidth,
			InputTextEchoBandwidth,
			InputThinWireBandwidth,
			InputVideoFrameBandwidth,
			LatencyLastRecorded,
			LatencySessionAverage,
			LatencySessionDeviation,
			Name,
			OutputAudioBandwidth,
			OutputClipboardBandwidth,
			OutputCOM1Bandwidth,
			OutputCOM2Bandwidth,
			OutputCOMBandwidth,
			OutputControlChannelBandwidth,
			OutputDriveBandwidth,
			OutputFontDataBandwidth,
			OutputLicensingBandwidth,
			OutputLPT1Bandwidth,
			OutputLPT2Bandwidth,
			OutputManagementBandwidth,
			OutputPNBandwidth,
			OutputPrinterBandwidth,
			OutputSeamlessBandwidth,
			OutputSessionBandwidth,
			OutputSessionCompression,
			OutputSessionLineSpeed,
			OutputSpeedScreenDataChannelBandwidth,
			OutputTextEchoBandwidth,
			OutputThinWireBandwidth,
			OutputVideoFrameBandwidth,
			Timestamp_Object,
			Timestamp_PerfTime,
			Timestamp_Sys100NS
		)
		VALUES
		(
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
		)
	");

	foreach my $var (@{ $ica_session }) {
		my $caption                               = $var->{'Caption'};
		my $description                           = $var->{'Description'};
		my $frequency_object                      = $var->{'Frequency_Object'};
		my $frequency_perftime                    = $var->{'Frequency_PerfTime'};
		my $frequency_sys100ns                    = $var->{'Frequency_Sys100NS'};
		my $inputaudiobandwidth                   = $var->{'InputAudioBandwidth'};
		my $inputclipboardbandwidt                = $var->{'InputClipboardBandwidt'};
		my $inputcom1bandwidth                    = $var->{'InputCOM1Bandwidth'};
		my $inputcom2bandwidth                    = $var->{'InputCOM2Bandwidth'};
		my $inputcombandwidth                     = $var->{'InputCOMBandwidth'};
		my $inputcontrolchannelbandwidth          = $var->{'InputControlChannelBandwidth'};
		my $inputdrivebandwidth                   = $var->{'InputDriveBandwidth'};
		my $inputfontdatabandwidth                = $var->{'InputFontDataBandwidth'};
		my $inputlicensingbandwidth               = $var->{'InputLicensingBandwidth'};
		my $inputlpt1bandwidth                    = $var->{'InputLPT1Bandwidth'};
		my $inputlpt2bandwidth                    = $var->{'InputLPT2Bandwidth'};
		my $inputmanagementbandwidth              = $var->{'InputManagementBandwidth'};
		my $inputpnbandwidth                      = $var->{'InputPNBandwidth'};
		my $inputprinterbandwidth                 = $var->{'InputPrinterBandwidth'};
		my $inputseamlessbandwidth                = $var->{'InputSeamlessBandwidth'};
		my $inputsessionbandwidth                 = $var->{'InputSessionBandwidth'};
		my $inputsessioncompression               = $var->{'InputSessionCompression'};
		my $inputsessionlinespeed                 = $var->{'InputSessionLineSpeed'};
		my $inputspeedscreendatachannelbandwidth  = $var->{'InputSpeedScreenDataChannelBandwidth'};
		my $inputtextechobandwidth                = $var->{'InputTextEchoBandwidth'};
		my $inputthinwirebandwidth                = $var->{'InputThinWireBandwidth'};
		my $inputvideoframebandwidth              = $var->{'InputVideoFrameBandwidth'};
		my $latencylastrecorded                   = $var->{'LatencyLastRecorded'};
		my $latencysessionaverage                 = $var->{'LatencySessionAverage'};
		my $latencysessiondeviation               = $var->{'LatencySessionDeviation'};
		my $name                                  = $var->{'Name'};
		my $outputaudiobandwidth                  = $var->{'OutputAudioBandwidth'};
		my $outputclipboardbandwidth              = $var->{'OutputClipboardBandwidth'};
		my $outputcom1bandwidth                   = $var->{'OutputCOM1Bandwidth'};
		my $outputcom2bandwidth                   = $var->{'OutputCOM2Bandwidth'};
		my $outputcombandwidth                    = $var->{'OutputCOMBandwidth'};
		my $outputcontrolchannelbandwidth         = $var->{'OutputControlChannelBandwidth'};
		my $outputdrivebandwidth                  = $var->{'OutputDriveBandwidth'};
		my $outputfontdatabandwidth               = $var->{'OutputFontDataBandwidth'};
		my $outputlicensingbandwidth              = $var->{'OutputLicensingBandwidth'};
		my $outputlpt1bandwidth                   = $var->{'OutputLPT1Bandwidth'};
		my $outputlpt2bandwidth                   = $var->{'OutputLPT2Bandwidth'};
		my $outputmanagementbandwidth             = $var->{'OutputManagementBandwidth'};
		my $outputpnbandwidth                     = $var->{'OutputPNBandwidth'};
		my $outputprinterbandwidth                = $var->{'OutputPrinterBandwidth'};
		my $outputseamlessbandwidth               = $var->{'OutputSeamlessBandwidth'};
		my $outputsessionbandwidth                = $var->{'OutputSessionBandwidth'};
		my $outputsessioncompression              = $var->{'OutputSessionCompression'};
		my $outputsessionlinespeed                = $var->{'OutputSessionLineSpeed'};
		my $outputspeedscreendatachannelbandwidth = $var->{'OutputSpeedScreenDataChannelBandwidth'};
		my $outputtextechobandwidth               = $var->{'OutputTextEchoBandwidth'};
		my $outputthinwirebandwidth               = $var->{'OutputThinWireBandwidth'};
		my $outputvideoframebandwidth             = $var->{'OutputVideoFrameBandwidth'};
		my $timestamp_object                      = $var->{'Timestamp_Object'};
		my $timestamp_perftime                    = $var->{'Timestamp_PerfTime'};
		my $timestamp_sys100ns                    = $var->{'Timestamp_Sys100NS'};
		$ins_ica_session->execute(
			$collection_id,
			$scantime,
			$caption,
			$description,
			$frequency_object,
			$frequency_perftime,
			$frequency_sys100ns,
			$inputaudiobandwidth,
			$inputclipboardbandwidt,
			$inputcom1bandwidth,
			$inputcom2bandwidth,
			$inputcombandwidth,
			$inputcontrolchannelbandwidth,
			$inputdrivebandwidth,
			$inputfontdatabandwidth,
			$inputlicensingbandwidth,
			$inputlpt1bandwidth,
			$inputlpt2bandwidth,
			$inputmanagementbandwidth,
			$inputpnbandwidth,
			$inputprinterbandwidth,
			$inputseamlessbandwidth,
			$inputsessionbandwidth,
			$inputsessioncompression,
			$inputsessionlinespeed,
			$inputspeedscreendatachannelbandwidth,
			$inputtextechobandwidth,
			$inputthinwirebandwidth,
			$inputvideoframebandwidth,
			$latencylastrecorded,
			$latencysessionaverage,
			$latencysessiondeviation,
			$name,
			$outputaudiobandwidth,
			$outputclipboardbandwidth,
			$outputcom1bandwidth,
			$outputcom2bandwidth,
			$outputcombandwidth,
			$outputcontrolchannelbandwidth,
			$outputdrivebandwidth,
			$outputfontdatabandwidth,
			$outputlicensingbandwidth,
			$outputlpt1bandwidth,
			$outputlpt2bandwidth,
			$outputmanagementbandwidth,
			$outputpnbandwidth,
			$outputprinterbandwidth,
			$outputseamlessbandwidth,
			$outputsessionbandwidth,
			$outputsessioncompression,
			$outputsessionlinespeed,
			$outputspeedscreendatachannelbandwidth,
			$outputtextechobandwidth,
			$outputthinwirebandwidth,
			$outputvideoframebandwidth,
			$timestamp_object,
			$timestamp_perftime,
			$timestamp_sys100ns
		);
	}
} ## end citrix()

__END__

=head1 NAME

C<winperf-aux.pl>

=head1 SYNOPSIS

	perl winperf-aux.pl --id ID --target IP --credential ID

	perl --help
	perldoc winperf-aux.pl

=head1 DESCRIPTION

C<winperf-aux.pl> executes non-core auxiliary performance data collection
against a collection source at the address identified by C<--target>, using the
credential identified by C<--credential>, and stores collected data attributed
to the ID identified by C<--id>.

Each auxiliary dataset is controlled by the presence of a named C<quirk>. If
there are no stored C<quirks> for the source or the source does not have a
recorded state for the availability of an auxiliary dataset, that dataset is
attempted. If successful, a C<quirk> storing the positive availablity of the
dataset is stored; if this fails the negative availability of the dataset is
stored. This allows us to determine what datasets a source supports and only
collects the supported datasets.

This script is typically spawned by the C<winperf-aux-admin.pl> script.

=head2 AUXILIARY TYPES

=head3 citrix

Collects Citrix Terminal Services Server data for systems running that software.

=head1 OPTIONS

=head3 --id ID

Required; the C<collection_id> of the collection source.

=head3 --target IP

Required; the address of the collection source.

=head3 --credential ID

Required; the C<credential_id> to use for authentication.

=head1 SEE ALSO

=over

=item C<RISC::riscWindows>

=item C<RISC::riscCreds>

=item C<RISC::Collect::Quirks>

=item C<RISC::Collect::Constants>

=item C<winperf-aux-admin.pl>

=back

=cut
