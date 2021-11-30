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

use Parallel::ForkManager;

use RISC::Collect::Constants qw( :status :schema );
use RISC::Collect::Logger;
use RISC::Collect::DB;
use RISC::Collect::DatasetLog;
use RISC::riscCreds;
use RISC::riscWindows;

$0 = 'winperf-installed-software-parent';

my $concurrent = 10;

my $parent_logger = RISC::Collect::Logger->new("windows::installedsoftware::parent");

my $explicit_target;

GetOptions(
	'concurrent=i'	=> \$concurrent,
	'deviceid|d=i'	=> \$explicit_target,
	'verbose|v'	=> sub {
		$parent_logger->level($RISC::Collect::Logger::LOG_LEVEL{'DEBUG'});
	},
	'help|h'	=> sub { pod2usage(EXIT_SUCCESS) }
);

my $parent_db = RISC::Collect::DB->new(COLLECTION_SCHEMA);

my $run_list;
if (riscUtility::checkLicenseEnforcement($parent_db)) {
	$run_list = $parent_db->selectall_arrayref("
		SELECT	deviceid,
			ipaddress,
			credentialid
		FROM riscdevice
		INNER JOIN credentials USING (deviceid)
		INNER JOIN windowsos USING (deviceid)
		INNER JOIN licensed USING (deviceid)
		GROUP BY deviceid
	", { Slice => { } });
} else {
	## HealthCheck
	$run_list = $parent_db->selectall_arrayref("
		SELECT	deviceid,
			ipaddress,
			credentialid
		FROM riscdevice
		INNER JOIN credentials USING (deviceid)
		INNER JOIN windowsos USING (deviceid)
		GROUP BY deviceid
	", { Slice => { } });
}

if ($explicit_target) {
	$run_list = [
		grep {
			$_->{'deviceid'} eq $explicit_target
		} @{ $run_list }
	];
}

unless (($run_list) and (scalar @{ $run_list })) {
	$parent_logger->info('nothing licensed');
	exit(EXIT_SUCCESS);
}

my $credobj = riscCreds->new();

my %credentials;
foreach my $r (@{ $run_list }) {
	$credobj->{address} = $r->{'ipaddress'};
	unless ($credentials{$r->{'credentialid'}} = $credobj->getWin($r->{'credentialid'})) {
		$parent_logger->error(sprintf(
			'failed to fetch credential %s: %s',
			$r->{'credentialid'},
			$credobj->get_error()
		));
		next;
	}
}

$parent_logger->info(sprintf('running for %d targets', scalar @{ $run_list }));

my $fm = Parallel::ForkManager->new($concurrent);
foreach my $target (@{ $run_list }) {
	$fm->start() and next;

	## now in child

	my $child_logger = RISC::Collect::Logger->new(join('::',
		'windows',
		'installedsoftware',
		$target->{'deviceid'},
		$target->{'ipaddress'}
	));

	$0 = sprintf(
		'winperf-installed-packages-worker %d %s',
		$target->{'deviceid'},
		$target->{'ipaddress'}
	);

	$child_logger->info('begin');

	my $db = RISC::Collect::DB->new(COLLECTION_SCHEMA);

	my $dl = RISC::Collect::DatasetLog->new(
		$target->{'deviceid'},
		'installedsoftware',
		{ db => $db, logger => $child_logger }
	);

	unless ($credentials{$target->{'credentialid'}}) {
		$child_logger->error('no credential');
		$fm->finish(EXIT_FAILURE);
	}

	my $wmi = RISC::riscWindows->new({
		%{ $credentials{$target->{'credentialid'}} },
		collection_id	=> $target->{'deviceid'},
		host	=> $target->{'ipaddress'},
		logger	=> $child_logger,
		db		=> $db
	});

	unless ($wmi->connected()) {
		$child_logger->error(sprintf(
			'failed to connect: %s',
			$wmi->err()
		));
		$fm->finish(EXIT_FAILURE);
	}

	my $data = $wmi->registry_applications();

	unless ($data) {
		$child_logger->error('no data collected');
		$fm->finish(EXIT_FAILURE);
	}

	## We want the installed software data to only contain the most recent
	## data set, so we remove the data for the current device prior to
	## inserting the new data.
	$child_logger->debug('removing existing data');
	$db->do("
		DELETE FROM windowsapplicationregistry
		WHERE deviceid = ?
	", undef, $target->{'deviceid'});

	$child_logger->debug('inserting new data');

	my $ins_registry = $db->prepare("
		INSERT INTO windowsapplicationregistry
		(
			deviceid,
			appkey,
			regkey,
			regvalue
		)
		VALUES
		(?,?,?,?)
	");

	foreach my $app (@$data) {
		my ($appkey, $regkey, $regvalue) = @$app;
		next if(!length($regvalue));
		$ins_registry->execute($target->{'deviceid'}, $appkey, $regkey, $regvalue);
	}

	my $dbh = $db->dbi(); # we need to get at $dbh->{RaiseError}
	$child_logger->debug('iis: fetching registry');
	my ($iis_reg, $sql_err);
	eval {
		$iis_reg = $wmi->registry_iis();
	};
	if($@ || !$iis_reg) {
		$child_logger->error('iis: registry_iis died: ' . $@);
		$fm->finish(EXIT_FAILURE);
	}
	elsif(!$iis_reg->{status}) {
		$child_logger->error('iis: registry_iis failed: ' . $iis_reg->{detail});
		$fm->finish(EXIT_FAILURE);
	}
	elsif($iis_reg->{detail} eq 'key not detected') {
		$child_logger->debug('iis: ' . $iis_reg->{detail}); # not an error
	}
	else { SQLBLOCK: {
		my @inetstp_values = qw(MajorVersion MinorVersion VersionString SetupString ProductString IISProgramGroup PathWWWRoot InstallPath);
		my ($scantime, $dataset_log_id) = (time(), $dl->id());

		local $dbh->{RaiseError} = 0; # turn off for this block

		$db->begin_work() or do { $sql_err = 'iis: unable to begin transaction: ' . $db->errstr; last SQLBLOCK; };
		$db->do('
			DELETE windowsiisregistry, windowsiisregistry_components
			FROM windowsiisregistry
			INNER JOIN windowsiisregistry_components USING(deviceid)
			WHERE windowsiisregistry.deviceid = ?', undef, $target->{deviceid}
		) or do { $sql_err = 'iis: delete failed: ' . $db->errstr; last SQLBLOCK; };

		my $iis_sth = $db->prepare('
			INSERT INTO windowsiisregistry
			(deviceid, scantime, dataset_log_id, ' . join(',', @inetstp_values) . ')
			VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		') or do { $sql_err = 'iis: inetstp prepare failed: ' . $db->errstr; last SQLBLOCK; };

		# reg.exe returns hex e.g. 0x1, but the mysql tables use int types. convert them.
		$iis_sth->execute($target->{deviceid}, $scantime, $dataset_log_id, map {
			if(!exists($iis_reg->{InetStp}->{$_})) {
				undef;
			}
			elsif($iis_reg->{InetStp}->{$_}->{type} =~ /WORD/) {
				hex($iis_reg->{InetStp}->{$_}->{data});
			}
			else {
				$iis_reg->{InetStp}->{$_}->{data};
			}
		} @inetstp_values) or do { $sql_err = 'iis: inetstp execute failed: ' . $iis_sth->errstr; last SQLBLOCK; };

		my $component_sth = $db->prepare('
			INSERT INTO windowsiisregistry_components
			(deviceid, scantime, dataset_log_id, value, data)
			VALUES(?, ?, ?, ?, ?)
		') or do { $sql_err = 'iis: component prepare failed: ' . $db->errstr; last SQLBLOCK; };

		COMPONENT: foreach my $component (keys %{ $iis_reg->{Components} }) {
			my $value = $iis_reg->{Components}->{$component};
			if($value->{type} !~ /WORD/) {
				$child_logger->warn('iis: unexpected type "' . $value->{type} . '" found in Components - skipping');
				next COMPONENT;
			}

			$component_sth->execute($target->{deviceid}, $scantime, $dataset_log_id, $component, hex($value->{data}))
				or do { $sql_err = 'iis: component execute failed: ' . $component_sth->errstr; last SQLBLOCK; };
		}

		$db->commit or do { $sql_err = 'iis: commit failed: ' . $db->errstr; };
	}}
	if($sql_err) {
		local $dbh->{RaiseError} = 0;

		$child_logger->error($sql_err);
		$child_logger->error('iis: rolling back transaction');
		if(!$db->rollback) {
			$child_logger->error('iis: rollback failed: ' . $db->errstr);
		}

		$fm->finish(EXIT_FAILURE);
	}

	$dl->success();

	$child_logger->info('complete');
	$fm->finish(EXIT_SUCCESS);
}

$parent_logger->debug('waiting for all children to complete');
$fm->wait_all_children();

exit(EXIT_SUCCESS);

__END__

=head1 NAME

C<winperf-installed-software.pl>

=head1 SYNOPSIS

	winperf-installed-software.pl [--concurrent N]

	winperf-installed-software.pl --help
	perldoc winperf-installed-software.pl

=head1 DESCRIPTION

C<winperf-installed-software.pl> collects the list of installed packages from
supported UNIX/Linux targets over SSH. The collection is driven by the
C<installed_packages()> method of C<RISC::riscSSH>.

This script implements the C<windows::packages> performance class. It determines
what UNIX/Linux targets are licensed, if any, and uses L<Parallel::ForkManager>
to fork a child process to collect the data from each target.

The maximum number of concurrent target processes is defined in this process,
but can be overridden using the C<--concurrent> flag.

=head1 OPTIONS

=head3 --concurrent N

Sets the number of child processes that can run concurrently to N, overriding
the default.

=head3 --deviceid, -d ID

Runs only for the given C<deviceid>, rather than for all licensed devices. The
device is filtered out of the licensed device list, so attempts to run against
a device that is no licensed or does not correspond to the correct collection
protocol will fail with a 'nothing licensed' error.

=head3 -v, --verbose

Sets the logger level to C<DEBUG>.

=head3 -h, --help

Display the short help message. More detailed documentation is available using
C<perldoc>.

=head1 SEE ALSO

=over

=item C<RISC::riscWindows>

=item C<wininventory-detail.pl>

=item L<Parallel::ForkManager>

=back

=cut
