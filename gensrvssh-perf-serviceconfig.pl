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
use RISC::riscSSH;

use RISC::Collect::DB;
use RISC::Collect::Logger;
use RISC::Collect::ServiceConfig qw(
	service_name
	insert_service_config
	$VALID_FILE_RE
);

my %SERVICE_ROUTER = (
	'apache-httpd'	=> \&linux_default_apache,
	'nginx'		=> \&linux_default_nginx
);

my $json = JSON->new->utf8();

my $logger = RISC::Collect::Logger->new('gensrvssh::serviceconfig');

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
	AND technology = 'gensrvssh'
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
my $cred = $credobj->getGenSrvSSH($vector->{'credentialid'});
unless ($cred) {
	$logger->error(sprintf(
		'unable to retreive credential: %s',
		$credobj->err()
	));
	exit(EXIT_FAILURE);
}

my $ssh = RISC::riscSSH->new({ debug => $verbose });
$ssh->connect($vector->{'ipaddress'}, $cred);
unless ($ssh->{'connected'}) {
	$logger->error($ssh->get_error());
	exit(EXIT_FAILURE);
}

if ($ssh->{'os'} eq 'AIX') {
	$logger->error('AIX not yet supported');
	exit(EXIT_FAILURE);
}

map {
	$SERVICE_ROUTER{ $_ }->($services->{$_})
} grep {
	defined $SERVICE_ROUTER{ $_ }
} (keys %{ $services });

exit(EXIT_SUCCESS);

sub cmd_priv_fallback {
	my ($command, $options) = @_;
	my $resp = $ssh->cmd($command, $options);
	return $resp if ($resp);
	$options = ($options)
		? { %{ $options }, priv => 1 }
		: { priv => 1 };
	return $ssh->cmd($command, $options);
}

sub linux_default_nginx {
	my ($nginx_data) = @_;

	$logger->info(sprintf(
		'%s: running for %s',
		$collection_id,
		service_name('NGINX')
	));

	my @data;

	my @commands = (
		{
			command		=> 'nginx -V 2>&1',
			content_type	=> 'version'
		},
		{
			command		=> 'nginx -T',
			content_type	=> 'file'
		}
	);

	if ($nginx_data->{'files'}) {
		map {
			push(@commands, {
				command		=> sprintf(q(nginx -T -c '%s'), $_),
				content_type	=> 'file',
			})
		} @{ $nginx_data->{'files'} }
	}

	foreach my $cmd (@commands) {
		$logger->debug($cmd->{'command'});
		my $resp = cmd_priv_fallback(
			$cmd->{'command'},
			$cmd->{'options'}
		);
		next unless ($resp);
		push(@data, {
			content_type	=> $cmd->{'content_type'},
			content_source	=> $json->encode({
				command => $cmd->{'command'}
			}),
			content		=> $resp
		});
	}

	insert_service_config(
		$collection_id,
		service_name('NGINX'),
		\@data
	) unless ($flags{'noop'});

	return STATUS_SUCCESS;
}

sub linux_default_apache {
	my ($apache_data) = @_;

	$logger->info(sprintf(
		'%s: running for %s',
		$collection_id,
		service_name('APACHE_HTTPD')
	));

	my @data;

	my $apachectl_V = cmd_priv_fallback('apachectl -V');
	if ($apachectl_V) {
		push(@data, {
			content_type	=> 'version',
			content_source	=> $json->encode({
				command => 'apachectl -V'
			}),
			content		=> $apachectl_V
		});
	} else {
		$logger->debug(sprintf(
			'%s: apachectl -V: %s',
			$collection_id,
			$ssh->get_error()
		));
		$logger->warn(sprintf(
			'%s: apachectl -V failed, unable to continue APACHE_HTTPD collection: %s',
			$collection_id,
			$ssh->get_error()
		));
		return STATUS_FAILURE;
	}

	## Parse apachectl -V to determine the HTTPD_ROOT.
	my ($httpd_root) = $apachectl_V =~ /HTTPD_ROOT="(\S+)"/;

	$logger->debug(sprintf(
		'%s: HTTPD_ROOT: %s',
		$collection_id,
		$httpd_root
	));

	unless (($httpd_root) and ($httpd_root =~ /$VALID_FILE_RE/)) {
		$logger->warn(sprintf(
			q(%s: bad HTTPD_ROOT: '%s', not safe to continue APACHE_HTTPD collection),
			$httpd_root,
			$collection_id
		));
		return STATUS_FAILURE;
	}

	# Parse apachectl -V to determine the SERVER_CONFIG_FILE.
	my ($server_config_file) = $apachectl_V =~ /SERVER_CONFIG_FILE="(\S+)"/;

	$logger->debug(sprintf(
		'%s: SERVER_CONFIG_FILE: %s',
		$collection_id,
		$server_config_file
	));

	unless (($server_config_file) and ($server_config_file =~ /$VALID_FILE_RE/)) {
		$logger->warn(sprintf(
			q(%s: bad SERVER_CONFIG_FILE: '%s', not safe to continue APACHE_HTTPD collection),
			$server_config_file,
			$collection_id
		));
		return STATUS_FAILURE;
	}

	## On some systems, HTTPD_ROOT is the root of the configuration directory,
	## on others, HTTPD_ROOT is the root of the web content directory (SUSE).
	## If HTTPD_ROOT is not the configuration directory, configuration files
	## are must to be absolute paths.
	## If SERVER_CONFIG_FILE is an absolute path, use it directly.
	## If SERVER_CONFIG_FILE is a relative path, look for it under HTTPD_ROOT.

	my $main_config_path;
	if ($server_config_file =~ /^\//) {
		$main_config_path = $server_config_file;
	} else {
		$main_config_path = join('/', $httpd_root, $server_config_file);
	}

	my $main_config_command = sprintf(
		q(cat '%s'),
		$main_config_path
	);

	$logger->debug(sprintf(
		'%s: %s',
		$collection_id,
		$main_config_command
	));

	my $main_config = cmd_priv_fallback($main_config_command);

	unless ($main_config) {
		$logger->warn(sprintf(
			'%s: failed to retreive main APACHE_HTTPD config file: %s',
			$collection_id,
			$ssh->get_error()
		));
		return STATUS_FAILURE;
	}

	push(@data, {
		content_type	=> 'file',
		content_source	=> $json->encode({
			path => $main_config_path
		}),
		content		=> $main_config
	});

	## Store files that are included from the main or explicit configuration
	## files. This is an array of hashes, each containing the 'root' element
	## that specifies the directory prefix for relative paths, and the path
	## of the included file itself. Included files may contain the '*' glob
	## pattern, in which case multiple files may be included by that single
	## directive, so we will need to expand that list into the files that
	## exist and match the pattern and fetch each one.
	my @includes;

	## Parse the main config file for included files.
	## We cannot just grab all files under the HTTPD_ROOT, since many
	## Apache deployments use the *-available, *-enabled symlink setup,
	## meaning many files are not actually in use.
	map {
		my ($key, $val) = split(/\s+/, $_);
		push(@includes, { root => $httpd_root, file => $val })
	} grep(/^Include/, (split /\n/, $main_config));

	## Process any files in the service JSON data, those that were specified
	## explicitly in the process list entries. Each will additionally be
	## inspected for Include directives that are added to the list to be 
	## processed below.
	if ($apache_data->{'files'}) {
		foreach my $expl (@{ $apache_data->{'files'} }) {
			my $file = $expl->{'file'};
			my $root = ($expl->{'root'} or $httpd_root);

			## Canonicalize the path using the root unless it is already absolute.
			$file = join('/', $root, $file) unless ($file =~ /^\//);

			unless ($file =~ /$VALID_FILE_RE/) {
				$logger->debug(sprintf(
					q(%s: refusing unsafe path '%s'),
					$collection_id,
					$file
				));
				next;
			}

			my $command = sprintf(q(cat '%s'), $file);
			$logger->debug(sprintf('%s: %s', $collection_id, $command));

			my $data = cmd_priv_fallback($command);

			unless ($data) {
				$logger->warn(sprintf(
					'%s: failed to retrieve file %s: %s',
					$collection_id,
					$file,
					$ssh->get_error()
				));
				next;
			}

			push(@data, {
				content_type	=> 'file',
				content_source	=> $json->encode({
					path => $file
				}),
				content		=> $data
			});

			map {
				my ($key, $val) = split(/\s+/, $_);
				push(@includes, { root => $root, file => $val });
			} grep(/^Include/, (split /\n/, $data));
		}
	}

	my %include_dedupe;
	if (@includes) {
		foreach my $inc (@includes) {
			my $root = $inc->{'root'};
			my $file = $inc->{'file'};

			next unless ($file);

			next if ($include_dedupe{ join('/', $root, $file) });
			$include_dedupe{ join('/', $root, $file) } = 1;

			my $found;
			if ($file =~ /^\//) {
				## Included file is an absolute path.
				if ($file =~ /\*/) {
					## Included file uses a glob that must be expanded into a list
					## of files that exist and match the pattern.
					## We must find the first full path element prior to any globs
					## to use as the search prefix.
					## First, we split the path into slash-delimited components,
					## then we push each element into the prefix component list until
					## we reach the first element that contains a glob.
					## Then, we push the remaining components into the glob list that
					## forms the search term.
					## Finally we collapse the two lists back into scalars.
					my @components = split(/\//, $file);
					my ($i, @prefix, @glob);
					for ($i = 0; $i < scalar @components; $i++) {
						last if ($components[$i] =~ /\*/);
						push(@prefix, $components[$i]);
					}
					foreach my $j ($i .. (scalar @components - 1)) {
						push(@glob, $components[$j]);
					}
					my $prefix = join('/', @prefix);
					my $glob = join('/', @glob);

					unless ($prefix =~ /$VALID_FILE_RE/) {
						$logger->warn(sprintf(
							'%s: failed to find a safe search prefix for glob-absolute-path: not continuing for entry %s',
							$collection_id,
							$file
						));
						next;
					}

					## the only unsafe character in the glob should be a single-quote
					if ($glob =~ /\'/) {
						$logger->warn(sprintf(
							'%s: failed to find a safe search term for glob-absolute-path: not continuing for entry %s',
							$collection_id,
							$file
						));
						next;
					}

					my $find_cmd = sprintf(
						q(find %s -wholename '%s'),
						$prefix,
						$glob
					);

					$logger->debug(sprintf(
						'%s: %s',
						$collection_id,
						$find_cmd
					));

					$found = cmd_priv_fallback($find_cmd);

					## Failed to look up include file. We must differentiate
					## between a failure to run the command and the legitimate
					## result that no files matched the pattern.
					if ((not defined($found)) and ($ssh->get_error())) {
						$logger->warn(sprintf(
							q(%s: failed to find APACHE_HTTPD include file '%s': %s),
							$collection_id,
							$file,
							$ssh->get_error()
						));
						next;
					}
					## No files match the Include directive.
					next unless ($found);
				} else {
					## Included files does not include a glob, so it is
					## used directly.
					$found = $file;
				}
			} else {
				## Included file is a relative path, so we look up
				## the location of the file, or files if the relative
				## path contains a glob pattern.

				my $find_cmd = sprintf(
					q(find %s -wholename '*%s'),
					$root,
					$file
				);

				$logger->debug(sprintf(
					'%d: %s',
					$collection_id,
					$find_cmd
				));

				$found = cmd_priv_fallback($find_cmd);

				## Failed to look up included file. We must differentiate
				## between an error running the command and the legitimate
				## result that no files matched a glob pattern.
				if ((not defined($found)) and ($ssh->get_error())) {
					$logger->warn(sprintf(
						'%s: failed to find APACHE_HTTPD include file %s: %s',
						$collection_id,
						$file,
						$ssh->get_error()
					));
					next;
				}
				## No files match the Include directive.
				next unless ($found);
			}

			## For the resolved list of one or more included files,
			## fetch the contents of each.
			my @valid_files = grep(/$VALID_FILE_RE/, (split(/\n/, $found)));
			foreach my $inc_file (@valid_files) {
				unless ($inc_file =~ /^\//) {
					$logger->warn(sprintf(
						q(%s: included file not an absolute path, refusing: '%s'),
						$collection_id,
						$inc_file
					));
					next;
				}

				my $command = sprintf(q(cat '%s'), $inc_file);

				$logger->debug(sprintf(
					'%s: %s',
					$collection_id,
					$command
				));

				my $content = cmd_priv_fallback($command);
				if ($content) {
					push(@data, {
						content_type	=> 'file',
						content_source	=> $json->encode({
							path => $inc_file
						}),
						content		=> $content
					});
				} else {
					$logger->warn(sprintf(
						q(%s: failed to fetch file '%s': %s),
						$collection_id,
						$inc_file,
						$ssh->get_error()
					));
				}
			}
		}
	}

	insert_service_config(
		$collection_id,
		service_name('APACHE_HTTPD'),
		\@data
	) unless ($flags{'noop'});

	return STATUS_SUCCESS;
}
