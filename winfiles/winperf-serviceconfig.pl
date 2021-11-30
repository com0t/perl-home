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

use JSON;

use RISC::Collect::Constants qw(
	:status
	:schema
);

use RISC::riscCreds;
use RISC::riscWindows;

use RISC::Collect::DB;
use RISC::Collect::Logger;
use RISC::Collect::ServiceConfig qw(
	service_name
	insert_service_config
	$VALID_FILE_RE
);

my %SERVICE_ROUTER = (
	'iis'		=> \&iis
);

my $json = JSON->new->utf8();

my $logger = RISC::Collect::Logger->new('windows::serviceconfig');

my $verbose = 0;

my %flags;
GetOptions(\%flags,
	'noop',
	'q|quiet'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'ERROR'});
	},
	'v|verbose'	=> sub {
		$logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
		$verbose = 1;
	},
	'h|help'	=> sub { pod2usage(EXIT_SUCCESS) }
);

my $collection_id	= shift;
my $services		= shift;

unless (($collection_id) and ($services)) {
	$logger->error('bad usage: missing collection_id or service list');
	exit(EXIT_FAILURE);
}

eval {
	$services = $json->decode($services);
}; if ($@) {
	$logger->error(sprintf('JSON decode error: %s', $@));
	exit(EXIT_FAILURE);
}

my $db = RISC::Collect::DB->new(COLLECTION_SCHEMA);
if (my $error = $db->err()) {
	$logger->error($error);
	exit(EXIT_FAILURE);
}

my $vector = $db->selectrow_hashref("
	SELECT credentialid, ipaddress
	FROM credentials
	INNER JOIN riscdevice USING (deviceid)
	WHERE deviceid = ?
	AND technology = 'windows'
", undef, $collection_id);

$db->disconnect();

unless (($vector) and ($vector->{'credentialid'})) {
	$logger->error('unable to determine credentialid');
	exit(EXIT_FAILURE);
}

unless ($vector->{'ipaddress'}) {
	$logger->error('unable to determine address');
	exit(EXIT_FAILURE);
}

my $credobj = riscCreds->new($vector->{'ipaddress'});
my $cred = $credobj->getWin($vector->{'credentialid'});
unless ($cred) {
	$logger->error(sprintf(
		'unable to retreive credential: %s',
		$credobj->err()
	));
	exit(EXIT_FAILURE);
}

my $wmi = RISC::riscWindows->new({
		collection_id	=> $collection_id,
		user		=> $cred->{'user'},
		password	=> $cred->{'password'},
		domain		=> $cred->{'domain'},
		credid		=> $cred->{'credid'},
		host		=> $vector->{'ipaddress'},
		db			=> $db,
		debug		=> $ENV{'DEBUG'}
	});
unless ($wmi->connected()) {
	$logger->error(sprintf(
		'failed to connect: %s',
		$wmi->err()
	));
	exit(EXIT_FAILURE);
}

map {
	$SERVICE_ROUTER{ $_ }->($services->{$_})
} grep {
	defined $SERVICE_ROUTER{ $_ }
} (keys %{ $services });

exit(EXIT_SUCCESS);

sub iis {
	my ($iis_data) = @_;

	$logger->info(sprintf(
		'%s: running for %s',
		$collection_id,
		service_name('IIS')
	));

	my @data;

	my $default_path = 'C:\Windows\System32\inetsrv\config\applicationHost.config';
	my $default_data = get_content($default_path);
	if (($default_data) and ($default_data->{'stdout'})) {
		$default_data = $default_data->{'stdout'};
		if ($default_data =~ /^\s*</) {
			push(@data, {
				content_type	=> 'file',
				content_source	=> $json->encode({
					app	=> 'default',
					path	=> $default_path
				}),
				content		=> $default_data
			});
		} else {
			$logger->warn(sprintf(
				q(%s: failed to get file '%s': %s),
				$collection_id,
				$default_path,
				$default_data
			));
		}
	} else {
		$logger->warn(sprintf(
			q(%s: no data for default appconfig: '%s'),
			$collection_id,
			$default_path
		));
	}

	if ($iis_data->{'app_pools'}) {
		foreach my $app (@{ $iis_data->{'app_pools'} }) {
			$logger->debug(sprintf(
				q(%s: fetching for '%s': %s),
				$collection_id,
				$app->{'app'},
				$app->{'file'}
			));
			my $data = get_content($app->{'file'});
			if (($data) and ($data->{'stdout'})) {
				$data = $data->{'stdout'};
				if ($data =~ /^\s*</) {
					push(@data, {
						content_type	=> 'file',
						content_source	=> $json->encode({
							app	=> $app->{'app'},
							path	=> $app->{'file'}
						}),
						content		=> $data
					});
				} else {
					$logger->warn(sprintf(
						q(%s: failed to fetch for '%s' %s: %s),
						$collection_id,
						$app->{'app'},
						$app->{'file'},
						$data
					));
				}
			} else {
				$logger->warn(sprintf(
					q(%s: no response fetching for '%s': %s),
					$collection_id,
					$app->{'app'},
					$app->{'file'}
				));
			}
		}
	}

	insert_service_config(
		$collection_id,
		service_name('IIS'),
		\@data
	) unless ($flags{'noop'});

	return STATUS_SUCCESS;
}

sub get_content {
	my ($path) = @_;
	return $wmi->wincmd(sprintf(
		q(powershell Get-Content -Path "%s"),
		$path
	));
}
