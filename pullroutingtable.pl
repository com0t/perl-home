use SNMP::Info;
use MIME::Base64;
use DBI();
use RISC::riscUtility;
use lib 'lib';
$|++;

#database connect
my $mysql = riscUtility::getDBH('risc_discovery',1);
	
getSNMPHandle(@ARGV);

eval {
my $ipr_dest = $info->ipr_route();
my $ipr_ifindex = $info->ipr_if();
 my $ipr_1 = $info->ipr_1();
 my $ipr_2 = $info->ipr_2();
 my $ipr_3 = $info->ipr_3();
 my $ipr_4 = $info->ipr_4();
 my $ipr_5 = $info->ipr_5();
 my $ipr_nexthop = $info->ipr_dest();
 my $ipr_type = $info->ipr_type();
 my $ipr_proto = $info->ipr_proto();
 my $ipr_age = $info->ipr_age();
 my $ipr_mask = $info->ipr_mask();
 my $sth15 = $mysql->prepare_cached("INSERT INTO discoverystats (iprange,status,updatetime) values (?,?,?)");
 my $numroutes = 0;
 foreach my $rrid (keys %$ipr_dest) {
 	my $route_dest = $ipr_dest->{$rrid};
 	my $route_int = $ipr_ifindex->{$rrid};
 	my $route_1 = $ipr_1->{$rrid};
 	my $route_2 = $ipr_2->{$rrid};
 	my $route_3 = $ipr_3->{$rrid};
 	my $route_4 = $ipr_4->{$rrid};
 	my $route_5 = $ipr_5->{$rrid};
 	my $route_nh = $ipr_nexthop->{$rrid};
 	my $route_type = $ipr_type->{$rrid};
 	my $route_proto = $ipr_proto->{$rrid};
 	my $route_age = $ipr_age->{$rrid};
 	my $route_mask = $ipr_mask->{$rrid};
 	my $slash = maskSlash($route_mask);
 	my $routeEntry=$route_dest."/".$slash;
 	#print "Adding $routeEntry with time()\n";
 	$sth15->execute($routeEntry,5,time()) unless $slash <16 || $route_dest eq '0.0.0.0' || $route_dest =~ /^127\./;
 	$numroutes++ unless $slash <16 || $route_dest eq '0.0.0.0' || $route_dest =~ /^127\./;;
 }
 $sth15->finish();
 print "$numroutes"
}; if ($@) {print "Error: $@";}



sub getSNMPHandle{
my $orig = shift;
$orig = decode_base64($orig);
#my ($version,$ip,$a1,$a2,$a3,$a4,$a5,$a6,$a7) = split(':',$orig);
eval {
        if ($orig eq '1' || $orig eq '2'){
                my $risc = decode_base64($_[1]);
                $info = new SNMP::Info(
                #AutoSpecify => 1,
                #Debug => 1,
                DestHost => decode_base64($_[0]),
                Community => $risc,
                Version => 2);
        } eval {unless (defined $info->name()) {
        		my $risc = decode_base64($_[1]);
                $info = new SNMP::Info(
                #AutoSpecify => 1,
                #Debug => 1,
                DestHost => decode_base64($_[0]),
                Community => $risc,
                Version => 1);
        }};

        if ($orig eq '3') {
                $info = new SNMP::Info(
                #AutoSpecify =>1,
                if ($_[6] eq 'null'){
                	$privType=undef;}
                	else{
                	$privType=$_[6];
                };
                DestHost=>decode_base64($_[0]),
                #Debug=>1,
                Version=>3,
                SecName=>decode_base64($_[2]),
                SecLevel=>decode_base64($_[1]),
                Context=>decode_base64($_[3]),
                AuthProto=>decode_base64($_[4]),
                AuthPass=>escape(decode_base64($_[5])),
                PrivProto=>$privType,
                PrivPass=>escape(decode_base64($_[7])
                )
        }
  #IF there is no err, then we know that we can read.  Now we need to test write.
   if (defined $info && defined $info->name()) {
   	print "Success:";
   } else {
   	print "Fail:No Access";
   }
}; if ($@) {print "Fail: $@";}
}

sub escape {
        my $string=shift;
        $string=~s/([\/\$\#\%\^\@\&\*\{\}\[\]\<\>\=\+])/\\$1/g;
        return $string;
}
sub maskSlash {
my $mask = shift;
#print "MASK: $mask\n";
my $decimal = ip2bin4($mask);
my $binary = dec2bin($decimal);
#print "Decimal: $decimal\n Binary: $binary\n";
$size = ($binary =~ tr/1//);
return $size if defined $size;
}

sub ip2bin4 {
  my $ip = shift;  # ip format: a.b.c.d
  return(unpack("N", pack("C4", split(/\D/, $ip))));
}
sub dec2bin {
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

