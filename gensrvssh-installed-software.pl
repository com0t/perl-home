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
use RISC::riscSSH;

$0 = 'gensrvssh-installed-software-parent';

my $concurrent = 10;

my $parent_logger = RISC::Collect::Logger->new("gensrvssh::installedsoftware::parent");

my ($explicit_target, $limit, $do_legacy);

GetOptions(
	'concurrent=i'	=> \$concurrent,
	'deviceid|d=i'	=> \$explicit_target,
	'limit=i'	=> \$limit,
	'do-legacy'	=> \$do_legacy,
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
		INNER JOIN ssh_inv_detail USING (deviceid)
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
		INNER JOIN ssh_inv_detail USING (deviceid)
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
	unless ($credentials{$r->{'credentialid'}} = $credobj->getGenSrvSSH($r->{'credentialid'})) {
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
		'gensrvssh',
		'installedsoftware',
		$target->{'deviceid'},
		$target->{'ipaddress'}
	));

	$0 = sprintf(
		'gensrvssh-installed-software-worker %d %s',
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

	if (my $error = $dl->err()) {
		$child_logger->error(sprintf(
			'failed to allocate dataset_log entry: %s',
			$error
		));
		$fm->finish(EXIT_FAILURE);
	}

	unless ($credentials{$target->{'credentialid'}}) {
		$child_logger->error('no credential');
		$fm->finish(EXIT_FAILURE);
	}

	my $ssh = RISC::riscSSH->new({
		logger	=> $child_logger
	});

	$ssh->connect($target->{'ipaddress'}, $credentials{$target->{'credentialid'}});
	unless ($ssh->{'connected'}) {
		$child_logger->info(sprintf(
			'failed to connect: %s',
			$ssh->get_error()
		));
		$fm->finish(EXIT_FAILURE);
	}

	$child_logger->debug('collecting installed packages');

	my $cllct_opts = {
		limit	=> $limit
	};

	my $installed_pkgs = $ssh->installed_packages($cllct_opts);

	unless ($installed_pkgs) {
		$child_logger->error(sprintf(
			'failed to collect installed packages: %s',
			$ssh->get_error()
		));
		$fm->finish(EXIT_FAILURE);
	}

	my $ins_opts = {
		do_legacy	=> $do_legacy
	};

	unless ($ssh->insert_installed_packages(
		$target->{'deviceid'},
		$installed_pkgs,
		$dl->id(),
		$db,
		$child_logger,
		$ins_opts))
	{
		$child_logger->error(sprintf
			'failed to insert new data: %s',
			$ssh->get_error()
		);
		$fm->finish(EXIT_FAILURE);
	}

	$dl->success();

	$child_logger->info('complete');
	$fm->finish(EXIT_SUCCESS);	## MUST do this
}

$parent_logger->debug('waiting for all children to complete');
$fm->wait_all_children();

exit(EXIT_SUCCESS);

__END__

=head1 NAME

C<gensrvssh-installed-software.pl>

=head1 SYNOPSIS

	gensrvssh-installed-software.pl [--concurrent N] [--deviceid ID]

	gensrvssh-installed-software.pl --help
	perldoc gensrvssh-installed-software.pl

=head1 DESCRIPTION

C<gensrvssh-installed-software.pl> collects the list of installed packages from
supported UNIX/Linux targets over SSH. The collection is driven by the
C<installed_packages()> method of C<RISC::riscSSH>.

This script implements the C<gensrv::packages> performance class. It determines
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

=head3 --do-legacy

By default, the collection routine does not insert data into the legacy
C<gensrvapplications> table used as an inventory data set. Supplying this flag
will cause this to occur.

=head3 --limit N

Only collect C<N> number of packages from each device. This is only useful for
testing.

=head3 -v, --verbose

Sets the logger level to C<DEBUG>.

=head3 -h, --help

Display the short help message. More detailed documentation is available using
C<perldoc>.

=head1 SEE ALSO

=over

=item C<RISC::riscSSH>

=item C<inventory-detail-gensrvssh.pl>

=item L<Parallel::ForkManager>

=back

=cut
