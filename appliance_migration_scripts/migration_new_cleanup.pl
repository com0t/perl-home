#!/usr/bin/perl

use RISC::riscUtility;
use Log::Log4perl;

use strict;
use warnings;

my $log_conf = q(
	log4perl.rootLogger = INFO, SYSLOG
	log4perl.appender.SYSLOG = Log::Dispatch::Syslog
	log4perl.appender.SYSLOG.ident = risc-migration
	log4perl.appender.SYSLOG.facility = user
	log4perl.appender.SYSLOG.layout = Log::Log4perl::Layout::PatternLayout
);

Log::Log4perl::init(\$log_conf);
my $logger = Log::Log4perl->get_logger();

$logger->info('begin ' . $0);

my ($row, $enabled);
eval {
	my $dbh = riscUtility::getDBH('risc_discovery', 1);
	$row = $dbh->selectrow_hashref('select val from features where name = "rssh"');
	$dbh->disconnect();
};
if ($@) {
	$logger->error('failed to query adb status: ' . $@);
	$enabled = 1; # fall back to enabled - something is probably borked that needs manual fixing
}
elsif (!defined($row)) {
	$logger->info('no matching rows found. assuming disabled.');
	$enabled = 0;
}
else {
	$enabled = $row->{val};
	$logger->info('rssh is ' . $enabled);
}

my @ssh_cmds;
if (!$enabled) {
	@ssh_cmds = (
		q(systemctl stop ssh.service),
		q(systemctl mask ssh.service),
	);
}
else {
	@ssh_cmds = (
		q(systemctl reload ssh.service),
	);
}

my @cleanup_cmds = (
	q(pkill -u migration),
	q(sleep 1),
	q(userdel -rf migration),
	q(sed -E -i 's/^AllowUsers admin migration$/AllowUsers admin/' /etc/ssh/sshd_config),
	q(rm -f /etc/sudoers.d/2_migration),
);

foreach my $cmd (@cleanup_cmds, @ssh_cmds) {
	my $output = qx($cmd 2>&1);
	($?) and do {
		$logger->error('non-zero return status from "' . $cmd . '": ' . $?);
		$logger->error('output was: ' . $output);
	}
}

$logger->info('end ' . $0);
