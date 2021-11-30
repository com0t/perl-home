#!/usr/bin/perl
#
##
use strict;
use RISC::CollectionValidation;
use RISC::riscUtility;
use MIME::Base64;
use Data::Dumper;
use JSON;

my $script_map = {
	'gensrvssh' => {
		'inv'	=> '/home/risc/inventory-detail-gensrvssh.pl',
		'perf'	=> '/home/risc/gensrvssh-perf.pl'
	},
	'windows' => {
		'inv'	=> '/home/risc/winfiles/wininventory-detail.pl',
		'perf'	=> '/home/risc/winfiles/winperf-detail2.pl'
	}
};

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if (defined($ENV{'DEBUG'}));

my ($target, $proto, $rawcred);

# use environment to avoid logging any sensitive strings - this is run via sudo
if (my $risc_credentials = riscUtility::risc_credentials(sub { abrt("Failed to decode credentials") })) {
	($target, $proto, $rawcred) = map {
		$risc_credentials->{$_}
	} qw(target proto rawcred);
# the old fashioned way
} else {
	($target, $proto, $rawcred) = (shift, shift, shift);
}

unless (exists($script_map->{$proto})) {
	abrt("contact us through the community with error code CV02: https://community.flexera.com/t5/Foundation-CloudScape/ct-p/Foundation-Cloudscape");
}

my $logfile = "/srv/httpd/htdocs/dump/".$target."-".$proto."-".time();
$ENV{'VALIDATE'} = $logfile;

my $validator = RISC::CollectionValidation->new({
	'logfile'	=> $logfile,
	'debug'		=> $debugging
});
if ($validator->err()) {
	abrt("contact us through the community with error code CV01: https://community.flexera.com/t5/Foundation-CloudScape/ct-p/Foundation-Cloudscape");
}

my $starttime = localtime();

my $detail = '';
my $failure = "<h3>FAILURE DESCRIPTION</h3>\n";

my $disco = $validator->shellcmd("perl /home/risc/disco.pl 0 $target/32");
if ($disco->{'code'} != $RISC::CollectionValidation::EXITSTATUS{'success'}) {
	$validator->overstatus('fail');
} else {
	$validator->overstatus('success');

	# the child scripts called now accept parameters more securely via the RISC_CREDENTIALS environment variable - use it
	$ENV{RISC_CREDENTIALS} = encode_json({ 'deviceid' => 'validation', 'target' => $target, 'credid' => $rawcred });

	my $inv	= $validator->shellcmd("perl $script_map->{$proto}->{'inv'}");
	if ($inv->{'code'} == $RISC::CollectionValidation::EXITSTATUS{'fail'}) {
		$validator->overstatus('fail');
		$failure .= "<h4>INVENTORY FAILURES</h4>\n".$inv->{'out'};
		$detail = $failure;
	} else {
		if ($inv->{'code'} == $RISC::CollectionValidation::EXITSTATUS{'incomplete'}) {
			$validator->overstatus('partial');
			$failure .= "<h4>INVENTORY FAILURES</h4>\n".$inv->{'out'};
			$detail = $failure;
		} elsif ($inv->{'code'} == $RISC::CollectionValidation::EXITSTATUS{'continue'}) {
			$validator->overstatus('fail');
			$failure .= "<h4>INVENTORY FAILURES</h4>\n".$inv->{'out'};
			$detail = $failure;
		} else {
			$validator->overstatus('success');
		}
		my $perf = $validator->shellcmd("perl $script_map->{$proto}->{'perf'}");
		if ($perf->{'code'} == $RISC::CollectionValidation::EXITSTATUS{'success'}) {
			$validator->overstatus('success');
		} else {
			if ($perf->{'code'} == $RISC::CollectionValidation::EXITSTATUS{'incomplete'}) {
				$validator->overstatus('partial');
			} else {
				$validator->overstatus('fail');
			}
			$failure .= "<h4>PERFORMANCE FAILURES</h4>\n".$perf->{'out'};
			$detail = $failure;
		}
	}

	# clear out creds from environment
	delete($ENV{RISC_CREDENTIALS});
}

$validator->finish();

my $logdata = $validator->dump();
my $ostatus = $validator->overstatus_name();
$logdata = join("\n",
	"<!DOCTYPE html>",
	"<html>",
	$RISC::CollectionValidation::STYLE,
	"<h4>$target</h4>\n",
	"<h4>$starttime</h4>\n",
	"<h3 class='$ostatus'>OVERALL STATUS: $ostatus</h3>\n",
	$detail,
	$logdata,
	"</html>\n"
);

print STDOUT "$logdata\n";

$validator->save_report($target,$proto,$logdata);

unless ($validator->delete_log()) {
	abrt($validator->err());
}
exit(0);

sub abrt {
	my ($err) = @_;
	chomp($err);
	print STDOUT "ERROR: $err\n";
	exit(1);
}

