use strict;
use Data::Dumper;
use RISC::riscUtility;

my $mysql = riscUtility::getDBH('RISC_Discovery',0);

my $netperfIntervals = getNet($mysql);
print Dumper($netperfIntervals);
my $winperfIntervals = getWin($mysql);
print Dumper($winperfIntervals);
my $gensrvperfIntervals = getGensrv($mysql);
print Dumper($gensrvperfIntervals);


sub getGensrv {
	my $mysql = shift;
	my $return;
	$return->{'sum'} = 0;
	$return->{'count'} = 0;
	$return->{'min'} = 1000000000;
	$return->{'max'} = 0;
	
	my $perfNums = $mysql->selectall_arrayref("select deviceid,scantime from gensrvperfcpu order by deviceid,scantime asc",{ Slice => {} });
	
	for (my $i = 0; $i < scalar(@{$perfNums}); $i++) {
		my $line1 = $perfNums->[$i];
		my $line2 = $perfNums->[$i + 1];
		next unless $line1->{'deviceid'} == $line2->{'deviceid'};
		next unless $line1->{'scantime'} < $line2->{'scantime'};
		
		my $diff = $line2->{'scantime'} - $line1->{'scantime'};
		
		$return->{'sum'} += $diff;
		$return->{'count'}++;
		$return->{'min'} = $diff if $diff < $return->{'min'};
		$return->{'max'} = $diff if $diff > $return->{'max'};
	}
	$return->{'avg'} = $return->{'sum'}/$return->{'count'} unless $return->{'count'} == 0;
	$return->{'avg'} = $return->{'sum'}/$return->{'count'};
	return $return;
}

sub getWin {
	my $mysql = shift;
	my $return;
	$return->{'sum'} = 0;
	$return->{'count'} = 0;
	$return->{'min'} = 1000000000;
	$return->{'max'} = 0;
	
	my $perfNums = $mysql->selectall_arrayref("select deviceid,scantime from winperfcpu where cpuid = 'CPU0' order by deviceid,scantime asc",{ Slice => {} });
	
	for (my $i = 0; $i < scalar(@{$perfNums}); $i++) {
		my $line1 = $perfNums->[$i];
		my $line2 = $perfNums->[$i + 1];
		next unless $line1->{'deviceid'} == $line2->{'deviceid'};
		next unless $line1->{'scantime'} < $line2->{'scantime'};
		
		my $diff = $line2->{'scantime'} - $line1->{'scantime'};
		
		$return->{'sum'} += $diff;
		$return->{'count'}++;
		$return->{'min'} = $diff if $diff < $return->{'min'};
		$return->{'max'} = $diff if $diff > $return->{'max'};
	}
	$return->{'avg'} = $return->{'sum'}/$return->{'count'} unless $return->{'count'} == 0;
	return $return;
}

sub getNet {
	my $mysql = shift;
	my $return;
	$return->{'sum'} = 0;
	$return->{'count'} = 0;
	$return->{'min'} = 1000000000;
	$return->{'max'} = 0;
	
	my $perfNums = $mysql->selectall_arrayref("select deviceid,scantime from deviceperformance order by deviceid,scantime asc",{ Slice => {} });
	
	for (my $i = 0; $i < scalar(@{$perfNums}); $i++) {
		my $line1 = $perfNums->[$i];
		my $line2 = $perfNums->[$i + 1];
		next unless $line1->{'deviceid'} == $line2->{'deviceid'};
		next unless $line1->{'scantime'} < $line2->{'scantime'};
		
		my $diff = $line2->{'scantime'} - $line1->{'scantime'};
		
		$return->{'sum'} += $diff;
		$return->{'count'}++;
		$return->{'min'} = $diff if $diff < $return->{'min'};
		$return->{'max'} = $diff if $diff > $return->{'max'};
	}
	$return->{'avg'} = $return->{'sum'}/$return->{'count'} unless $return->{'count'} == 0;
	$return->{'avg'} = $return->{'sum'}/$return->{'count'};
	return $return;
}