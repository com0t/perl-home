#!/usr/bin/perl
#
## resetEULA.pl - resets the EULA to force the user to re-accept
##	useful in case the user did not accept the pro-services EULA and needs to do so

use strict;
use RISC::riscUtility;

my $db = riscUtility::getDBH('risc_discovery',1);
eval {
	$db->do("update credentials set accepted = 0 where technology='appliance'");
}; if ($@) {
	print '||&|| FAILURE: ' . $@ . ' ||&||' . "\n";
} else {
	print '||&|| SUCCESS ||&||' . "\n";
}