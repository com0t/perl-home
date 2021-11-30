#!/usr/bin/perl

# 📫️👣️
# take an email message from postfix and push it into elasticsearch
# expects the message to be generated by unattended-upgrades on debian

use Mail::Internet;
use MIME::QuotedPrint;

use RISC::Event qw(add_event call_event);
use RISC::Collect::Logger;
use RISC::riscUtility;

use strict;
use warnings;

my $logger = RISC::Collect::Logger->new('self::mailtoes');

$logger->info($0 . ' started with pid=' . $$);

# /etc/environment won't be automatically loaded when running under postfix
riscUtility::loadenv();

# postfix will pipe the message here via stdin
my $msg = Mail::Internet->new(\*STDIN);
# get the header (e.g. Subject:, From:, etc.)
my $header = $msg->head();
# don't line wrap header fields
$header->unfold();
# remove the 'Quoted Printable' encoding from the body e.g. unwrap lines ending in =
my $body = decode_qp(join('', @{ $msg->body() }));
# unattended-upgrade will add a Subject ending in e.g. SUCCESS or FAILURE
my $subject = $header->get('Subject');
my $status = (($subject =~ / SUCCESS$/) ? 0 : 1);
# try to extract the new package versions
my $packages = [];
foreach my $line (split(/\n/, $body)) {
	if ($line =~ /^Unpacking (?<name>[^ ]+) \((?<version>[^\)]+)\) /) {
		push(@$packages, { name => $+{name}, version => $+{version} });
	}
}

$logger->debug('creating event...');
# just re-purposing existing fields in ES so index doesn't need to be messed with
add_event('unattended-upgrade', sub {
	return({
		description => shift,
		logs => shift,
		packages => shift,
		status => shift
	});
});
$logger->debug('...done');

$logger->debug('calling event...');
call_event('unattended-upgrade', $subject, $body, $packages, $status) or do {
	$logger->error_die('unable to post event: ' . $!);
};
$logger->debug('...done');

exit(0);