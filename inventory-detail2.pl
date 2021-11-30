#!usr/bin/perl 
use SNMP::Info;
use RISC::visio;
use DBI();
use lib 'lib';
use Data::Dumper;
use RISC::riscUtility;
$|++;

#database connect
my $mysql = riscUtility::getDBH('RISC_Discovery',1);
$mysql->{mysql_auto_reconnect} = 1;
my $mysql2 = riscUtility::getDBH('risc_discovery',1);
$mysql2->{mysql_auto_reconnect} = 1;

#Get Devices
my $getcred;
if ($mysql2->selectrow_hashref("select count(*) as num from information_schema.triggers where trigger_name = 'cred_encrypt'")->{'num'} == 0) {
	$getcred = $mysql2->prepare_cached("select * from credentials where credid=? limit 1");
} else {
	$getcred = $mysql2->prepare_cached("select credid,productkey,technology,status,accepted,version,level,testip,cred_decrypt(passphrase) as passphrase,
											cred_decrypt(context) as context,cred_decrypt(securitylevel) as securitylevel,cred_decrypt(securityname) as securityname,
											cred_decrypt(authtype) as authtype,cred_decrypt(authpassphrase) as authpassphrase,cred_decrypt(privtype) as privtype,
											cred_decrypt(privusername) as privusername,cred_decrypt(privpassphrase) as privpassphrase,cred_decrypt(domain) as domain,
											port,cred_decrypt(userid) as userid,cred_decrypt(username) as username,
											scantime,eu,ap,removed
										from credentials where credid = ? limit 1");
}

$deviceid=shift;
$winmachine = shift;
print "$deviceid\n";
my $credid=shift;
$getcred->execute($credid);
$credential = $getcred->fetchrow_hashref();
getSNMP($credential,$winmachine);
###
#Get Global info that is used in more than one place
##
eval {
$intindex = $info->i_index();
$description = $info->i_description();
$name = $info->i_name();
$type = $info->i_type();
$speed = $info->i_speed();
$mac = $info->i_mac();
$operstatus = $info->i_up();
$adminstatus = $info->i_up_admin();
$ipr_dest = $info->ipr_route();
$ipr_ifindex = $info->ipr_if();
$ipr_1 = $info->ipr_1();
$ipr_2 = $info->ipr_2();
$ipr_3 = $info->ipr_3();
$ipr_4 = $info->ipr_4();
$ipr_5 = $info->ipr_5();
$ipr_nexthop = $info->ipr_dest();
$ipr_type = $info->ipr_type();
$ipr_proto = $info->ipr_proto();
$ipr_age = $info->ipr_age();
$ipr_mask = $info->ipr_mask();
}; if ($@) {print "ERROR: $@ for $winmachine\n"};

######
######Call the subroutines here
######
######
######
###############################################
GatherARPInfo();
GatherCDPInfo();
GatherCDSInfo();
GatherChassisInfo();
GatherFlashInfo();
GatherIPSLAInfo();
GatherIPTables();
GatherNetflowInfo();
GatherNetworkDeviceInfo();
GatherNTPInfo();
GatherQoSInfo();
GatherQosPerfInfo();
GatherStackInfo();
GatherVLANandSTPInfo();
GetEntity();
GetInterfaces();
GetRoutes();
GetSysDescription();
GatherSwitchQoS();



###############################################
sub getSNMP {
	my $test=shift;
	my $ip=shift;
	my $version = $test->{'version'};
	my $passphrase = riscUtility::decode($test->{'passphrase'});
	my $context=$test->{'context'};
	my $securitylevel = $test->{'securitylevel'};
	my $securityname = riscUtility::decode($test->{'securityname'});
	my $authtype = $test->{'authtype'};
	my $authpass = riscUtility::decode($test->{'authpassphrase'});
	if ($test->{'privtype'} eq 'null' || riscUtility::decode($test->{'privtype'}) eq 'null') {
		$privtype=undef;
	}
	my $privuser = riscUtility::decode($test->{'privusername'});
	my $privpass = riscUtility::decode($test->{'privpassphrase'});	
    if ($version eq '1' || $version eq '2'){
                my $risc = escape($passphrase);
                $info = new SNMP::Info(
                AutoSpecify => 1,
                #Debug => 1,
                DestHost => $ip,
                Community => $risc,
                Version => 2);
        } eval {unless (defined $info->name()) {
        		my $risc = escape($passphrase);
                $info = new SNMP::Info(
                AutoSpecify => 1,
                #Debug => 1,
                DestHost => $ip,
                Community => $risc,
                Version => 1);
        }};
    if ($test->{'version'} eq '3') {
				my $privType;
				my $secLevel;
				my $authType;
                if ($test->{'authtype'} eq 'MD5' || $test->{'authtype'} eq 'SHA') {
                	$secLevel=$test->{'securitylevel'};
                	$authType=$test->{'authtype'};
                	if ($test->{'privtype'} eq 'null') {
                        $privType=undef;
                	} else {
                        $privType=$test->{'privtype'};
                	}
                } else {
                	$secLevel=riscUtility::decode($test->{'securitylevel'});
                	$authType=riscUtility::decode($test->{'authtype'});
                	if (riscUtility::decode($test->{'privtype'}) eq 'null'){
                        $privType=undef;
                	} else {
                        $privType=riscUtility::decode($test->{'privtype'});
                	}
                }
                $info = new SNMP::Info(
                AutoSpecify =>1,
                DestHost=>$ip,
                #Debug=>1,
                Version=>3,
                SecName=>riscUtility::decode($test->{'securityname'}),
                SecLevel=>$secLevel,
                Context=>$test->{'context'},
                AuthProto=>$authType,
                AuthPass=>escape(riscUtility::decode($test->{'authpassphrase'})),
                PrivProto=>$privType,
                PrivPass=>escape(riscUtility::decode($test->{'privpassphrase'}))
                )
        }
}
sub stringpos3 {
	my $teststring = $_[0];
	my $position = $_[1];
	#find first position
	$teststring =~ /(^[0-9]*)\.([0-9]*)\.([0-9]*)/;
	if ($position==1){
			return $1;
			}
	elsif ($position==2) {
			return $2;
			}
	elsif ($position==3) {
			return $3;
			}
	elsif ($position==4) {
			return $4;
			}
	}
sub stringpos4 {
	my $teststring = $_[0];
	my $position = $_[1];
	#find first position
	$teststring =~ /(^[0-9]*)\.([0-9]*)\.([0-9]*)\.([0-9]*)/;
	if ($position==1){
			return $1;
			}
	elsif ($position==2) {
			return $2;
			}
	elsif ($position==3) {
			return $3;
			}
	elsif ($position==4) {
			return $4;
			}
	}
sub IntindexWithIP {
	my $teststring = $_[0];
	my $position = $_[1];
	$teststring =~ /(^[0-9]*)\.([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)/;
	if ($position==1) {
			return $1;
			}
	elsif ($position==2) {
			return $2;
			}
	}
sub escape {
        my $string=shift;
        #$string=~s/([\/\$\#\%\^\@\&\*\{\}\[\]\<\>\=])/\\$1/g;
        return $string;
}

sub GetSysDescription{ 
#Get System Description
eval {
my $sth500 = $mysql->prepare_cached("INSERT INTO snmpsysinfo (deviceid,sysdescription,sysuptime,syscontact,sysname,syslocation,sysservices,sysoid) values (?,?,?,?,?,?,?,?)");
my $snmpsysdescription = $info->description();
my $snmpsysuptime = $info->uptime();
my $snmpsyscontact = $info->contact();
my $snmpsyslocation = $info->location();
my $snmpsyslayers = $info->layers();
my $snmpsysname = $info->name();
my $sysoid = $info->id();
$sth500->execute($deviceid,$snmpsysdescription,$snmpsysuptime,$snmpsyscontact,$snmpsysname,$snmpsyslocation,$snmpsysservices,$sysoid);
}; if ($@) {print "Problem with SNMP System Info Pull $@\n";}
}
sub GetInterfaces{
#Get Interface details and Routing Table
eval {
 my $sth = $mysql->prepare_cached("INSERT INTO interfaces (deviceid,name,description,type,speed,intindex,mac,adminstatus,operstatus) VALUES (?,?,?,?,?,?,?,?,?)");
#drop in each interface into the database
 foreach my $instance (keys %$intindex) {
        my $iname = $name->{$instance};
        my $iintindex = $intindex->{$instance};
        my $idescription = $description->{$instance};
        my $itype = $type->{$instance};
        my $ispeed = $speed->{$instance};
        my $imac = $mac->{$instance};
        my $ioperstatus = $operstatus->{$instance};
        my $iadminstatus = $adminstatus->{$instance};
        $iname="DESCR: ".$iname." NAME: ".$idescription;
        $ispeed=10000000000 if $ispeed==10000 && $idescription=~/tengig/i;
        #print "$iname : $iintindex : $idescription : $itype : $ispeed : $imac : $ioperstatus : $iadminstatus \n";
        $sth->execute($deviceid,$iname,$idescription,$itype,$ispeed,$iintindex,$imac,$iadminstatus,$ioperstatus);
        }
$sth->finish();
}; if ($@) {print "Problem with Interfaces $@\n";}
}
sub GetRoutes {
#drop each route from routing table into database
eval {
 my $sth15 = $mysql->prepare_cached("INSERT INTO iproutes (deviceid,ipRouteDest,ipRouteIfIndex,ipRouteMetric1,ipRouteMetric2,ipRouteMetric3,ipRouteMetric4,ipRouteNextHop,ipRouteType,ipRouteProto,ipRouteAge,ipRouteMask,ipRouteMetric5) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
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
 	$sth15->execute($deviceid,$route_dest,$route_int,$route_1,$route_2,$route_3,$route_4,$route_nh,$route_type,$route_proto,$route_age,$route_mask,$route_5);
 }
 $sth15->finish();
}; if ($@) {print "Problem with routes:$@\n";}
}
sub GetEntity {
eval {
my $sth4 = $mysql->prepare_cached("INSERT INTO deviceentity (deviceid,class,description,fwver,hwver,map_id,model,name,parent,serial,swver,type,physindex,manufacturer) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $e_class = $info->e_class();
my $e_description = $info->e_descr();
my $e_fwver = $info->e_fwver();
my $e_hwver = $info->e_hwver();
my $e_map_id = $info->e_pos();
my $e_model = $info->e_model();
my $e_name = $info->e_name();
my $e_parent = $info->e_parent();
my $e_serial = $info->e_serial();
my $e_swver = $info->e_swver();
my $e_type = $info->e_type();
my $e_vendor = $info->e_vendor();
my $e_index = $info->e_index();
#drop into database
foreach my $indices (keys %$e_class) {
        my $cl = $e_class->{$indices};
        my $des = $e_description->{$indices};
        my $fw = $e_fwver->{$indices};
        my $hw = $e_hwver->{$indices};
        my $map = $e_map_id->{indices}; #filling this with Position now - JL 12/09
        my $mo = $e_model->{$indices};
        my $na = $e_name->{$indices};
        my $pa = $e_parent->{$indices};
        my $sw = $e_swver->{$indices};
        my $ty = $e_type->{$indices};
        my $ser = $e_serial->{$indices};
        if (length($ser)<5 && $info->vendor() =~ /cisco/i && $cl eq 'chassis'){
        	$ser=$info->chassis_id();
        	if (length($ser)<3) {
        		$ser=$info->serial();
        	}
        }
		my $indx = $e_index->{$indices};
		my $vend = $e_vendor->{$indices};
        $sth4->execute($deviceid,riscUtility::ascii($cl),riscUtility::ascii($des),riscUtility::ascii($fw),riscUtility::ascii($hw),riscUtility::ascii($map),riscUtility::ascii($mo),riscUtility::ascii($na),riscUtility::ascii($pa),riscUtility::ascii($ser),riscUtility::ascii($sw),riscUtility::ascii($ty),riscUtility::ascii($indices),riscUtility::ascii($vend));
        }
$sth4->finish();
}; if ($@) {print "Problem with Entity: $@\n";}

}
sub GatherNetworkDeviceInfo {
eval {
#Gather System Information
my $sth5 = $mysql->prepare_cached("INSERT INTO networkdeviceinfo (deviceid,serialnumber,vendor,swversion,featureset,family,ntpserver,ntpclock,processorram) VALUES (?,?,?,?,?,?,?,?,?)");
my $vendor = $info->vendor();
if ($vendor =~ /Cisco/i){
	my $software = $info->ci_images();
	my $serial = $info->chassis_type();
	my $softwareversion = $software->{5};
	my $featureset = $software->{4};
	my $family = $software->{3};
	my $ntpserver = $info->ntp_syspeer();
	my $ntpclock = $info->ntp_sysclock();
	my $processorram = $info->chassis_procRam();
	$processorram = 0 if not defined $processorram;
	$sth5->execute($deviceid,$serial,$vendor,$softwareversion,$featureset,$family,$ntpserver,$ntpclock,$processorram);
	}elsif ($vendor =~ /hp/i) {
	my $software = $info->os_version();
	my $serial = $info->serial1();
	my $family = $info->model();
	my $softwareversion = $info->os_bin();
	my $featureset = 'unknown';
	my $processorram = 0;
	$sth5->execute($deviceid,$serial,$vendor,$softwareversion,$featureset,$family,$ntpserver,$ntpclock,$processorram);
	} else {
	my $software = $info->os_ver() || undef;
	my $serial = $info->serial();
	my $family = $info->model();
	my $softwareversion = $info->os_bin() || undef;
	if (defined $software && defined $softwareversion) {
		$softwareversion = $software." ".$softwareversion;
	} elsif (defined $software && not defined $softwareversion) {
		$softwareversion = $software;
	}
	my $featureset = 'unknown';
	my $processorram = 0;
	$sth5->execute($deviceid,$serial,$vendor,$softwareversion,$featureset,$family,$ntpserver,$ntpclock,$processorram);
	}
$sth5->finish();
}; if ($@) {print "Problem with NetworkDeviceInfo Gather: $@\n";};
}
sub GatherCDPInfo {
eval {
#Gather CDP Information
 my $sth6 = $mysql->prepare_cached("INSERT INTO cdp (deviceid,deviceip,localport,duplex,neighborip,neighborhostname,neighborport,neighborplatform) VALUES (?,?,?,?,?,?,?,?)");
 my $c_if       = $info->c_if();
 my $c_ip       = $info->c_ip();
 my $c_port     = $info->c_port();
 my $c_plat     = $info->c_platform();
 my $c_nodeid   = $info->c_id();
 my $i_duplex 	= $info->i_duplex();
 foreach my $iid (keys %$name){
    my $duplex = $i_duplex->{$iid};
    # Print out physical port name, not snmp iid
    my $port  = $name->{$iid};
    #I know that the name/description values are switched here, but that is due to the poor naming in the MIB.
    $port="DESCR: ".$port." NAME: ".$description->{$iid};
    # The CDP Table has table entries different than the interface tables.
    # So we use c_if to get the map from cdp table to interface table.
    my %c_map = reverse %$c_if;
    $c_key = $c_map{$iid};
    my $neighbor_ip   = $c_ip->{$c_key};
    my $neighbor_port = $c_port->{$c_key};
    my $neighbor_platform = $c_plat->{$c_key};
    my $neighbor_id = $c_nodeid->{$c_key};
    #print "$neighbor_ip $neighbor_port $neighbor_platform $neighbor_id\n";
    $sth6->execute($deviceid,$winmachine, $port , $duplex, riscUtility::ascii($neighbor_ip) , riscUtility::ascii($neighbor_id) , riscUtility::ascii($neighbor_port) , riscUtility::ascii($neighbor_platform)) if defined $neighbor_ip;
 }
$sth6->finish();
}; if ($@) {print "Problem with CDP Gather: $@\n";};
}
sub GatherIPTables {
eval {
#Gather IP Address Information
 $sth7 = $mysql->prepare_cached("INSERT INTO iptables (deviceid,ip,netmask,intindex) VALUES (?,?,?,?)");
 my $ipindex    = $info->ip_index();
 my $iptable    = $info->ip_table();
 my $ipnetmask  = $info->ip_netmask();
 foreach $x (keys %$ipnetmask){
 #print "$x\n";
 my $ipintindex = $ipindex->{$x};
 my $ipnetmaskvalue = $ipnetmask->{$x};
 #print "$ipnetmaskvalue\n";
 $sth7->execute($deviceid, $x, $ipnetmaskvalue,$ipintindex);
}
$sth7->finish();
}; if ($@) {print "Problem with IP Tables:$@\n";}
}
sub GatherQoSInfo {
eval {
#QoS PM mapping - all qos tableinfo listed below
my $sth8 = $mysql->prepare_cached("INSERT INTO qosobjects (deviceid,objectid,objectname,objectdesc,objectspec,objecttype,configindex,parentid) VALUES (?,?,?,?,?,?,?,?)");
my $sth9 = $mysql->prepare_cached("INSERT INTO qosservicepolicies (deviceid,intindex,policymap,policydirection,interfacetype) VALUES (?,?,?,?,?)");
my $sth10 = $mysql->prepare_cached("INSERT INTO qosqueueconfig (deviceid,configindex,bandwidth,bandunits,flowenabled,prienabled,aggqueuesize,indqueuesize,dynqueuesize,priburstsize,queuelimitunits,aggqueuelimit,aggqueuetime) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $sth11 = $mysql->prepare_cached("INSERT INTO qosshapeconfig (deviceid,configindex,rate,bur_size,ext_bur_size,adaptenabled,adaptrate,limittype,ratetype,perratevalue,bursttime,extbursttime,rate64) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

 my $i_index = $info->qos_i_index();
 my $i_type = $info->qos_i_type();
 my $pol_dir = $info->qos_pol_direction();
 my $obj_type = $info->qos_obj_type();
 my $obj_paren = $info->qos_obj_parent();
 my $obj_index = $info->qos_obj_index();
 my $cm_name = $info->qos_cm_name();
 my $cm_desc = $info->qos_cm_desc();
 my $cm_info = $info->qos_cm_info();
 my $qos_pre = $info->qos_octet_pre();
 my $qos_post = $info->qos_octet_post();
 my $qos_con_index = $info->qos_config_index();
 my $qos_pol_name = $info->qos_policy_name();
 my $qos_pol_desc = $info->qos_policy_desc();
 my $qos_pol_index = $info->qos_policy_index();
 my $match_stat = $info->qos_match_stmt();
 my $q_bandwidth = $info->qos_ofg_q_bandwidth();
 my $q_bandwidth_unit = $info->qos_cfg_q_bandwidthunit();
 my $q_flow_en = $info->qos_cfg_q_flow_enabled();
 my $q_pri_en = $info->qos_cfg_q_pri_enabled();
 my $q_agg_q_size = $info->qos_cfg_q_agg_q_size();
 my $q_ind_q_size = $info->qos_cfg_q_ind_q_size();
 my $q_dyn_q_num = $info->qos_cfg_q_dyn_q_num();
 my $q_pri_bur_size = $info->qos_cfg_q_pri_bur_size();
 my $q_que_lim_units = $info->qos_cfg_q_que_lim_units();
 my $q_agg_que_lim = $info->qos_cfg_q_agg_que_lim();
 my $q_agg_que_time = $info->qos_cfg_q_agg_que_time();
 my $s_cfg_rate = $info->qos_ts_cfg_rate();
 my $s_cfg_bur_size = $info->qos_ts_cfg_bur_size();
 my $s_cfg_ext_bur_size = $info->qos_ts_cfg_ext_bur_size();
 my $s_cfg_adap_enable = $info->qos_ts_cfg_adap_enable();
 my $s_cfg_adap_rate = $info->qos_ts_cfg_adap_rate();
 my $s_cfg_lim_type = $info->qos_ts_cfg_lim_type();
 my $s_cfg_rate_type = $info->qos_ts_cfg_rate_type();
 my $s_cfg_per_rate_val = $info->qos_ts_cfg_per_rate_val();
 my $s_cfg_bur_time = $info->qos_ts_cfg_bur_time();
 my $s_cfg_ext_bur_time = $info->qos_ts_cfg_ext_bur_time();
 #my $s_cfg_rate_64 = $info->qos_ts_cfg_rate_64();

#Gather qos Objects
  my $policymapname;
  my $policymapdesc;
  my $classmapname;

  foreach my $iid (keys %$qos_con_index){
    $object = "";
    $objectdesc = "";
    $objectspec = "";
    $dot = index ($iid, ".");
    $length = length($iid);
    $objid = substr($iid,$dot+1,$length);
    $parentid = $obj_paren->{$iid};
    $objecttype = $obj_type->{$iid};
    $objectvalue = $qos_con_index->{$iid};
    $configindex = $objectvalue;
    foreach my $iid2 (keys %$qos_pol_name){
       if ($objectvalue eq $iid2){
          $object = $qos_pol_name->{$iid2};
          $objectdesc = $qos_pol_desc->{$iid2};
       }
    }
    foreach my $iid3 (keys %$cm_name){
       if ($objectvalue eq $iid3){
          $object = $cm_name->{$iid3};
          $objectdesc = $cm_desc->{$iid3};
          $objectspec = $cm_info->{$iid3};
       }
    }
    foreach my $iid4 (keys %$match_stat){
       if ($objectvalue eq $iid4){
          $objectspec = $match_stat->{$iid4};
       }
    }
    $sth8->execute($deviceid, $objid, $object, $objectdesc, $objectspec, $objecttype,  $configindex, $parentid);
  }
$sth8->finish();


#Gather qos Service policy info
foreach my $iid (keys %$i_index){
  my $interfaceindex = $i_index->{$iid};
  my $interfacedirection = $pol_dir->{$iid};
  my $interfacetype = $i_type->{$iid};
  my $configIndex = $qos_con_index->{"$iid.$iid"};
  my $interfacepolicymap = $qos_pol_name->{$configIndex};
  $sth9->execute($deviceid, $interfaceindex, $interfacepolicymap, $interfacedirection, $interfacetype);
 }
$sth9->finish();

#Gather qos queueing info
foreach my $iid (keys %$q_bandwidth){
   $configindex = $iid;
   $value_q_bandwidth = "";
   $value_q_bandwidth_unit = "";
   $value_q_flow_en = "";;
   $value_q_pri_en = "";
   $value_q_agg_q_size = "";
   $value_q_ind_q_size = "";
   $value_q_dyn_q_num = "";
   $value_q_pri_bur_size = "";
   $value_q_que_lim_units = "";
   $value_q_agg_que_lim = "";
   $value_q_agg_que_time = "";
   $value_q_bandwidth = $q_bandwidth->{$iid};
   $value_q_bandwidth_unit = $q_bandwidth_unit->{$iid};
   $value_q_flow_en = $q_flow_en->{$iid};
   $value_q_pri_en = $q_pri_en->{$iid};
   $value_q_agg_q_size = $q_agg_q_size->{$iid};
   $value_q_ind_q_size = $q_ind_q_size->{$iid};
   $value_q_dyn_q_num = $q_dyn_q_num->{$iid};
   $value_q_pri_bur_size = $q_pri_bur_size->{$iid};
   $value_q_que_lim_units = $q_que_lim_units->{$iid};
   $value_q_agg_que_lim = $q_agg_que_lim->{$iid};
   $value_q_agg_que_time = $q_agg_que_time->{$iid};
   $sth10->execute($deviceid,$configindex, $value_q_bandwidth, $value_q_bandwidth_unit, $value_q_flow_en, $value_q_pri_en, $value_q_agg_q_size, $value_q_ind_q_size, $value_q_dyn_q_num, $value_q_pri_bur_size, $value_q_que_limit_units, $value_q_agg_que_lim, $value_q_agg_que_time);
}
$sth10->finish();

#gather qos shaping info
foreach my $iid (keys %$s_cfg_rate){
   $ConfigIndex = $iid;

   $value_s_cfg_rate = "";
   $value_s_cfg_bur_size = "";
   $value_s_cfg_ext_bur_size = "";
   $value_s_cfg_adap_enable = "";
   $value_s_cfg_adap_rate = "";
   $value_s_cfg_lim_type = "";
   $value_s_cfg_rate_type = "";
   $value_s_cfg_per_rate_val = "";
   $value_s_cfg_bur_time = "";
   $value_s_cfg_ext_bur_time = "";
   #$value_s_cfg_rate_64 = "";
   $value_s_cfg_rate = $s_cfg_rate->{$iid};
   $value_s_cfg_bur_size = $s_cfg_bur_size->{$iid};
   $value_s_cfg_ext_bur_size = $s_cfg_ext_bur_size->{$iid};
   $value_s_cfg_adap_enable = $s_cfg_adap_enable->{$iid};
   $value_s_cfg_adap_rate = $s_cfg_adap_rate->{$iid};
   $value_s_cfg_lim_type = $s_cfg_lim_type->{$iid};
   $value_s_cfg_rate_type = $s_cfg_rate_type->{$iid};
   $value_s_cfg_per_rate_val = $s_cfg_per_rate_val->{$iid};
   $value_s_cfg_bur_time = $s_cfg_bur_time->{$iid};
   $value_s_cfg_ext_bur_time = $s_cfg_ext_bur_time->{$iid};
   #$value_s_cfg_rate_64 = $s_cfg_rate_64->{$iid};
   $sth11->execute($deviceid,$ConfigIndex,$value_s_cfg_rate, $value_s_cfg_bur_size, $value_s_cfg_ext_bur_size, $value_s_cfg_adap_enable, $value_s_cfg_adap_rate,$value_s_cfg_lim_type, $value_s_cfg_rate_type, $value_s_cfg_per_rate_val, $value_s_cfg_bur_time, $value_s_cfg_ext_bur_time, $value_s_cfg_rate_64);
}
$sth11->finish();
}; if ($@) {print "Problem with QoS Gather $@\n";};
}
sub GatherNTPInfo {
eval {
#Gather NTP Information
#my $ntpassocid = $info->ntp_peers_associd();
my $sth12 = $mysql->prepare_cached("INSERT INTO ntpinfo (deviceid,associd,peeraddress,peerport,peermode,stratum,refid) VALUES (?,?,?,?,?,?,?)");
my $ntppeeraddress	= $info->ntp_peers_peeraddress();
my $ntppeerport = $info->ntp_peers_peerport();
my $ntppeermode = $info->ntp_peers_peermode();
my $ntppeerstratum = $info->ntp_peers_stratum();
my $ntppeerrefid = $info->ntp_peers_refid();
foreach my $associd (keys %$ntppeeraddress){
	$value_assoc_id = $ntpassocid->{$associd};
	$value_peer_addr = $ntppeeraddress->{$associd};
	$value_peer_port = $ntppeerport->{$associd};
	$value_peer_mode = $ntppeermode->{$associd};
	$value_peer_stratum = $ntppeerstratum->{$associd};
	$value_peer_refid = $ntppeerrefid->{$associd};
	$sth12->execute($deviceid,$value_assoc_id,$value_peer_addr,$value_peer_port,$value_peer_mode,$value_peer_stratum,$value_peer_refid);
}
$sth12->finish();
}; if ($@) {print "Problem with NTP Gather $@\n";};
}
sub GatherARPInfo {
eval {
#Gather Global ARP / Forwarding Information
my $sth95 = $mysql->prepare_cached("INSERT INTO iptoint (deviceid,ifindex,remoteip) VALUES (?,?,?)");
my $sth96 = $mysql->prepare_cached("INSERT INTO iptomac (deviceid,mac,remoteip) VALUES (?,?,?)");
my $ip2int = $info->at_index();
my $ip2mac = $info->at_paddr();
	foreach my $iid (keys %$ip2int) {
		my $intindex2=IntindexWithIP($iid,1);
		my $ip=IntindexWithIP($iid,2);
		#print "$ip on VLAN:$vlan maps to $ip2int->{$iid}\n";
		$sth95->execute($deviceid,$ip2int->{$iid},$ip);
		}
	foreach my $pid (keys %$ip2mac) {
		my $intindex2=IntindexWithIP($pid,1);
		my $ip=IntindexWithIP($pid,2);
		#print "$ip on VLAN:$vlan maps to $ip2mac->{$pid}\n";
		$sth96->execute($deviceid,$ip2mac->{$pid},$ip);
		}
$sth95->finish();
$sth96->finish();
}; if ($@) {print "Problem with global IP to MAC and Interface pull: $@\n";}
}
sub GatherVLANandSTPInfo {
eval {
#Get VLAN Information - Uses main SNMP::Info handle and then also gets L2 Forwarding Information
	my $sth94 = $mysql->prepare_cached("INSERT INTO l2forward (deviceid,mac,vlan,intindex) VALUES (?,?,?,?)");
	my $sth13 = $mysql->prepare("Insert into vlandevice (deviceid,vlanid,vlandescription,vlanstate) values (?,?,?,?)");
	my $vlanName = $info->v_name();
	my $vlanState = $info->v_state();
	my $vlanType = $info->v_type();
	my $devicestring=$info->snmp_comm();
	if (defined $vlanName) {
	foreach my $tvid (keys %$vlanName){
     	if ($tvid=~/\./){
     		$vid = substr($tvid,2);
     	} else {
     		$vid = $tvid;
     	}
     	if ($vlanType->{$tvid} =~ /ethernet/i) {
    		$sth13->execute($deviceid,$vid,$vlanName->{$tvid},$vlanState->{$tvid});
     		$sth13->finish();
    		my $bridgeid = $info->b_mac();
    		#now, loop through each vlan and get stp info for PVST+
    		my $infoSTP = new SNMP::Info(
              	 AutoSpecify     => 1,
              	 #Debug          => 1,
              	 #DebugSNMP      => 1,
             	 DestHost        => $winmachine,
             	  Community       => "$devicestring\@$vid",
             	  Version         => 1
            	  ); #or die "Can't make STP Connection\n";
              	 #my $stperr = $infoSTP->error();
              	 #die "Problem connecting for STP Pull $stperr\n" if defined $stperr;
             	  if (defined $infoSTP) {
             	  	my $sth14 = $mysql->prepare("insert into stpdevice (deviceid,vlanid,stproot,stprootcost,bridgeid,priority,rootportindex,timesincetc,totaltc) values (?,?,?,?,?,?,?,?,?)");
             	  	my $rootBridge = substr($infoSTP->stp_root(),-17);
             	 	 my $bridgePri = $infoSTP->stp_priority();
             	 	 my $STProotPort = $infoSTP->stp_root_port();
             		  my $rootCost = $infoSTP->stp_root_cost();
              	 	 my $timetc = $infoSTP->stp_time();
              	  my $totaltc = $infoSTP->stp_ttc();
              	  my $interfacemap = $infoSTP->i_stp_id();
             	  my $rootPort = $interfacemap->{$STProotPort};
               	  $rootPort=9999999 unless defined $rootPort ;
               	  #print "$devicevalues[0],$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc\n";
               	  $sth14->execute($deviceid,$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc);
              	  $sth14->finish();
               	  my $sth15=$mysql->prepare("insert into stpinterface (deviceid,vlanid,intindex,forwardingstate,trans,pathcost,rootcost) values (?,?,?,?,?,?,?)");
                  my $pfs = $infoSTP->stp_p_state();
              	  my $ptt = $infoSTP->stp_p_trans();
                  my $ppc = $infoSTP->stp_p_cost();
                  my $prc = $infoSTP->stp_p_rootcost();
                  foreach my $stppid (keys %$pfs){
                             my $stp_p_index = $interfacemap->{$stppid};
                             my $stp_p_fs = $pfs->{$stppid};
                             my $stp_p_trans = $ptt->{$stppid};
                             my $stp_p_pc = $ppc->{$stppid};
                             my $stp_p_rc = $prc->{$stppid};
                             #print "$devicevalues[0],$vid,$stppid,$stp_p_index\n";
                             $sth15->execute($deviceid,$vid,$stp_p_index,$stp_p_fs,$stp_p_trans,$stp_p_pc,$stp_p_rc);
                              }
                my $fw_mac = $infoSTP->fw_mac();
				my $fw_port = $infoSTP->fw_port();
				my $bp_index = $infoSTP->bp_index();
				foreach my $fw_index (keys %$fw_mac) {
        					my $mac2 = $fw_mac->{$fw_index};
        					my $bp_id = $fw_port->{$fw_index};
        					my $iid = $bp_index->{$bp_id};
        					$sth94->execute($deviceid,$mac2,$vid,$iid);
        					}
             	$sth15->finish();
                $sth94->finish();
             	}
             	}
             	else {
             	 my $bridgeid = $info->b_mac();
		  		 my $sth14 = $mysql->prepare("insert into stpdevice (deviceid,vlanid,stproot,stprootcost,bridgeid,priority,rootportindex,timesincetc,totaltc) values (?,?,?,?,?,?,?,?,?)");
             	  my $rootBridge = substr($info->stp_root(),-17);
             	  my $bridgePri = $info->stp_priority();
             	  my $STProotPort = $info->stp_root_port();
             	  my $rootCost = $info->stp_root_cost();
              	  my $timetc = $info->stp_time();
              	  my $totaltc = $info->stp_ttc();
              	  my $interfacemap = $info->i_stp_id();
             	  my $rootPort = $interfacemap->{$STProotPort};
             	  $sth13->execute($deviceid,$vid,$vlanName->{$tvid},$vlanState->{$tvid});
               	  $rootPort=9999999 unless defined $rootPort;
               	  #print "$devicevalues[0],$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc\n";
               	  $sth14->execute($deviceid,$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc);
              	  $sth14->finish();
               	  my $sth15=$mysql->prepare("insert into stpinterface (deviceid,vlanid,intindex,forwardingstate,trans,pathcost,rootcost) values (?,?,?,?,?,?,?)");
                  my $pfs = $info->stp_p_state();
              	  my $ptt = $info->stp_p_trans();
                  my $ppc = $info->stp_p_cost();
                  my $prc = $info->stp_p_rootcost();
                  foreach my $stppid (keys %$pfs){
                             my $stp_p_index = $interfacemap->{$stppid};
                             my $stp_p_fs = $pfs->{$stppid};
                             my $stp_p_trans = $ptt->{$stppid};
                             my $stp_p_pc = $ppc->{$stppid};
                             my $stp_p_rc = $prc->{$stppid};
                             #print "$devicevalues[0],$vid,$stppid,$stp_p_index\n";
                             $sth15->execute($deviceid,$vid,$stp_p_index,$stp_p_fs,$stp_p_trans,$stp_p_pc,$stp_p_rc);
                              }
                my $fw_mac = $info->fw_mac();
				my $fw_port = $info->fw_port();
				my $bp_index = $info->bp_index();
				foreach my $fw_index (keys %$fw_mac) {
							my $mac2 = $fw_mac->{$fw_index};
        					my $bp_id = $fw_port->{$fw_index};
        					my $iid = $bp_index->{$bp_id};
        					$sth94->execute($deviceid,$mac2,$vid,$iid);
        					}
             	$sth15->finish();
                $sth94->finish();
                }
             	}
             	}
             	 else {
             	 my $bridgeid = $info->b_mac();
		  		 my $sth14 = $mysql->prepare("insert into stpdevice (deviceid,vlanid,stproot,stprootcost,bridgeid,priority,rootportindex,timesincetc,totaltc) values (?,?,?,?,?,?,?,?,?)");
             	  my $rootBridge = substr($info->stp_root(),-17);
             	  my $bridgePri = $info->stp_priority();
             	  my $STProotPort = $info->stp_root_port();
             	  my $rootCost = $info->stp_root_cost();
              	  my $timetc = $info->stp_time();
              	  my $totaltc = $info->stp_ttc();
              	  my $interfacemap = $info->i_stp_id();
             	  my $rootPort = $interfacemap->{$STProotPort};
               	  $rootPort=9999999 unless defined $rootPort ;
               	  #print "$deviceid,$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc\n";
               	  $sth14->execute($deviceid,$vid,$rootBridge,$rootCost,$bridgeid,$bridgePri,$rootPort,$timetc,$totaltc);
              	  $sth14->finish();
               	  $sth15=$mysql->prepare("insert into stpinterface (deviceid,vlanid,intindex,forwardingstate,trans,pathcost,rootcost) values (?,?,?,?,?,?,?)");
                  my $pfs = $info->stp_p_state();
              	  my $ptt = $info->stp_p_trans();
                  my $ppc = $info->stp_p_cost();
                  my $prc = $info->stp_p_rootcost();
                  foreach my $stppid (keys %$pfs){
                             my $stp_p_index = $interfacemap->{$stppid};
                             my $stp_p_fs = $pfs->{$stppid};
                             my $stp_p_trans = $ptt->{$stppid};
                             my $stp_p_pc = $ppc->{$stppid};
                             my $stp_p_rc = $prc->{$stppid};
                             #print "$deviceid,$vid,$stppid,$stp_p_index\n";
                             $sth15->execute($deviceid,$vid,$stp_p_index,$stp_p_fs,$stp_p_trans,$stp_p_pc,$stp_p_rc);
                              }
                my $fw_mac = $info->fw_mac();
				my $fw_port = $info->fw_port();
				my $bp_index = $info->bp_index();
				foreach my $fw_index (keys %$fw_mac) {
        					my $mac2 = $fw_mac->{$fw_index};
        					my $bp_id = $fw_port->{$fw_index};
        					my $iid = $bp_index->{$bp_id};
        					$sth94->execute($deviceid,$mac2,$vid,$iid);
        					}
             	$sth15->finish();
                $sth94->finish();
                }
}; if ($@) {print "Problem with Spanning Tree Gather $@\n"};
}
sub GatherFlashInfo {
eval {
#Pull the Flash Device Information for the Device - if it is Cisco
my $sth113 = $mysql->prepare_cached("INSERT INTO flashdevice (deviceid,flashindex,devicecard,devicephyentindex,devicenameextended,devicesize,devicepartitions,devicename,devicedescr,devicecontroller) values (?,?,?,?,?,?,?,?,?,?)");
my $sth14 = $mysql->prepare_cached("INSERT INTO flashfile (deviceid,fileindex,filesize,filechecksum,filestatus,filename,filetype,filedate) VALUES (?,?,?,?,?,?,?,?)");

my $flash_dev_index = $info->flash_deviceindex();
my $flash_dev_card = $info->flash_devicecard();
my $flash_dev_phyentindex = $info->flash_devicephyentindex();
my $flash_dev_nameextended = $info->flash_devicenameextended();
my $flash_dev_devicesize = $info->flash_devicesize();
my $flash_dev_devicepartitions = $info->flash_devicepartitions();
my $flash_dev_devicename = $info->flash_devicename();
my $flash_dev_devicedescr = $info->flash_devicedescr();
my $flash_dev_devicecontroller = $info->flash_devicecontroller();
foreach my $fdindex (keys %$flash_dev_devicename) {
	my $fd_card = $flash_dev_card->{$fdindex};
	my $fd_phy = $flash_dev_phyentindex->{$fdindex};
	my $fd_nameext = $flash_dev_nameextended->{$fdindex};
	my $fd_size = $flash_dev_devicesize->{$fdindex};
	my $fd_partitions = $flash_dev_devicepartitions->{$fdindex};
	my $fd_name = $flash_dev_devicename->{$fdindex};
	my $fd_descr = $flash_dev_devicedescr->{$fdindex};
	my $fd_controller = $flash_dev_devicecontroller->{$fdindex};
	$sth113->execute($deviceid,$fdindex,$fd_card,$fd_phy,$fd_nameext,$fd_size,$fd_partitions,$fd_name,$fd_descr,$fd_controller);
	}
$sth113->finish();
#Gather Flash File Information - if it is Cisco
my $flash_file_index = $info->flash_fileindex();
my $flash_file_size = $info->flash_filesize();
my $flash_file_checksum = $info->flash_filechecksum();
my $flash_file_status = $info->flash_filestatus();
my $flash_file_name = $info->flash_filename();
my $flash_file_type = $info->flash_filetype();
my $flash_file_date = $info->flash_filedate();
foreach my $ffindex (keys %$flash_file_name) {
	my $ff_size = $flash_file_size->{$ffindex};
	my $ff_checksum = $flash_file_checksum->{$ffindex};
	my $ff_status = $flash_file_status->{$ffindex};
	my $ff_name = $flash_file_name->{$ffindex};
	my $ff_type = $flash_file_type->{$ffindex};
	my $ff_date = $flash_file_date->{$ffindex};
	$sth14->execute($deviceid,$ffindex,$ff_size,$ff_checksum,$ff_status,$ff_name,$ff_type,$ff_date);	
	}
$sth14->finish();
}; if ($@){print "Problem with Flash Gather $@\n";};
}
sub GatherStackInfo {
#Gather Cisco Stack information for Cisco Devices - JL 12-08-2009
eval {
my $sth213 = $mysql->prepare_cached("INSERT INTO ciscostack (deviceid,moduletype,modulemodel,moduleserialnumber,modulestatus,modulename,modulenumports,moduleportstatus,modulehwversion,modulefwversion,moduleswversion,moduleindex,modulesubtype,modulesubtype2,moduleentphysindex,moduleslotnum,snmpindex) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $m_type = $info->m_type();
my $m_model = $info->m_model();
my $m_serial = $info->m_serial();
my $m_status = $info->m_status();
my $m_name = $info->m_name();
my $m_ports = $info->m_ports();
my $m_ports_status = $info->m_ports_status();
my $m_hwver = $info->m_hwver();
my $m_fwver = $info->m_fwver();
my $m_swver = $info->m_swver();
my $m_ip = $info->m_ip();
my $m_sub1 = $info->m_sub1();
my $m_sub2 = $info->m_sub2();
my $m_mindex = $info->m_index();
my $m_entphysindex = $info->m_ent_phys_index();
my $m_slot = $info->m_slot_num();
foreach my $csmindex (keys %$m_type) {
	my $mm_type = $m_type->{$csmindex};
	my $mm_model = $m_model->{$csmindex};
	my $mm_serial = $m_serial->{$csmindex};
	my $mm_status = $m_status->{$csmindex};
	my $mm_name = $m_name->{$csmindex};
	my $mm_ports = $m_ports->{$csmindex};
	my $mm_ports_status = $m_ports_status->{$csmindex};
	my $mm_hwver = $m_hwver->{$csmindex};
	my $mm_fwver = $m_fwver->{$csmindex};
	my $mm_swver = $m_swver->{$csmindex};
	my $mm_ip = $m_ip->{$csmindex};
	my $mm_sub1 = $m_sub1->{$csmindex};
	my $mm_sub2 = $m_sub2->{$csmindex};
	my $mm_mindex = $m_mindex->{$csmindex};
	my $mm_entphysindex = $m_entphysindex->{$csmindex};
	my $mm_slot = $m_slot->{$csmindex};
	my $mm_index = $csmindex;
	$sth213->execute($deviceid,$mm_type,$mm_model,$mm_serial,$mm_status,$mm_name,$mm_ports,$mm_ports_status,$mm_hwver,$mm_fwver,$mm_swver,$mm_mindex,$mm_sub1,$mm_sub2,$mm_entphysindex,$mm_slot,$mm_index);
	}
}; if ($@) {print "Problem with Cisco Stack MIB pull $@\n";}
}
sub GatherChassisInfo {
##Pull Cisco OLD-CHASSIS-MIB Information
eval {
my $sth214 = $mysql->prepare_cached("INSERT INTO ciscooldchassis (deviceid,cardindex,cardslots,cardtype,carddescr,cardserial,cardhwversion,cardswversion,cardcontainedbyindex,cardoperstatus,cardslotnum,snmpindex) values (?,?,?,?,?,?,?,?,?,?,?,?)");
my $c_chass_cardindex = $info->chassis_cardIndex();
my $c_chass_cardslots = $info->chassis_cardSlots();
my $c_chass_cardtype = $info->chassis_cardType();
my $c_chass_carddescr = $info->chassis_cardDescr();
my $c_chass_cardserial = $info->chassis_cardSerial();
my $c_chass_cardhwver = $info->chassis_cardHwVersion();
my $c_chass_cardswver = $info->chassis_cardSwVersion();
my $c_chass_cardcontainedindex = $info->chassis_cardContainedByIndex();
my $c_chass_operstatus = $info->chassis_cardOperStatus();
my $c_chass_cardslot = $info->chassis_cardSlotNum();
foreach my $chassindex (keys %$c_chass_cardindex) {	
	my $cc_chass_cardindex = $c_chass_cardindex->{$chassindex};
	my $cc_chass_cardtype = $c_chass_cardtype->{$chassindex};
	my $cc_chass_cardslots = $c_chass_cardslots->{$chassindex};
	my $cc_chass_carddescr = $c_chass_carddescr->{$chassindex};
	my $cc_chass_cardserial = $c_chass_cardserial->{$chassindex};
	my $cc_chass_cardhwver = $c_chass_cardhwver->{$chassindex};
	my $cc_chass_cardswver = $c_chass_cardswver->{$chassindex};
	my $cc_chass_cardcontainedindex = $c_chass_cardcontainedindex->{$chassindex};
	my $cc_chass_operstatus = $c_chass_operstatus->{$chassindex};
	my $cc_chass_cardslot = $c_chass_cardslot->{$chassindex};
	my $cc_index = $chassindex;
	$sth214->execute($deviceid,$cc_chass_cardindex,$cc_chass_cardslots,$cc_chass_cardtype,$cc_chass_carddescr,$cc_chass_cardserial,$cc_chass_cardhwver,$cc_chass_cardswver,$cc_chass_cardcontainedindex,$cc_chass_operstatus,$cc_chass_cardslot,$cc_index);
	}
}; if ($@) { print "Problem with OLD-CISCO-CHASSIS-MIB: $@\n";}
}
sub GatherCDSInfo {
##Gather additional info for Cisco Discovery Services
eval {
my $sth215 = $mysql->prepare_cached("INSERT INTO ciscocds (deviceid,ocm_chasstype,ocm_chasspartner,ocm_sysuptimelastchange,ocm_chassversion,ocm_chassid,ocm_romversion,ocm_romsysversion,ocm_nvramsize,ocm_nvramused,ocm_configregister,cs_chasstype,cs_chassmodel) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
my $cds_ocm_type = $info->chassis_type();
my $cds_ocm_partner = $info->chassis_partner();
my $cds_ocm_uptime = $info->chassis_sysuplastchange();
my $cds_ocm_version = $info->chassis_version();
my $cds_ocm_id = $info->chassis_id();
my $cds_ocm_romver = $info->chassis_romversion();
my $cds_ocm_romsysver = $info->chassis_romsysversion();
my $cds_ocm_nvram = $info->chassis_nvramsize();
my $cds_ocm_nvramused = $info->chassis_nvramused();
my $cds_ocm_confreg = $info->chassis_confreg();
my $cds_csm_type = $info->systype1();
my $cds_csm_model = $info->model1();
$sth215->execute($deviceid,$cds_ocm_type,$cds_ocm_partner,$cds_ocm_uptime,$cds_ocm_version,$cds_ocm_id,$cds_ocm_romver,$cds_ocm_romsysver,$cds_ocm_nvram,$cds_ocm_nvramused,$cds_ocm_confreg,$cds_csm_type,$cds_csm_model);
}; if ($@) { print "problem with CDS Specific Gathering: $@\n";}
}
sub GatherNetflowInfo{
#Gather Netflow Configuration Information
eval {
$sth20 = $mysql->prepare_cached("Insert into netflowconfig (deviceid,intindex,direction,riscdeployed) VALUES (?,?,?,?)");
#Get Netflow enabled interfaces
my $Netflow_En = $info->cnf_CI_Netflow_Enable();
#drop in each netflow interface into the database
foreach my $instance (keys %$Netflow_En) {
        #print "Instance: $instance\n";
        my $netflowenable = $Netflow_En->{$instance};
 		#print "Enabled: $netflowenable\n";
        #Field RISCdeployed of 0 is not risc deployed. 1 is deployed though netflowDeploy.pl
        $sth20->execute($deviceid,$instance,$netflowenable,'0');
        }
$sth20->finish();
}; if ($@) {print "Problem with Netflow enable status pull $@\n";};
}
sub GatherIPSLAInfo {
#Gather IP SLA Configuration Information - If Available
eval {
my $sth212 = $mysql->prepare_cached("INSERT INTO rttsupport (deviceid,operationtype,supported) values (?,?,?)");
my $operationssupport = $info->rtt_supportedoperations();
foreach my $suppopp (keys %$operationssupport) {
	$sth212->execute($deviceid,$suppopp,$operationssupport->{$suppopp});
	}
$sth21 = $mysql->prepare_cached("INSERT INTO rttconfig (rttindex,opertype,opertargetaddr,opertargetport,operrequestsize,operresponsesize,opersourceaddr,opersourceport,opertos,operpktinterval,opernumpkts,opercodec,opercodecinterval,opercodecpayload,opercodecnumpkts,operlife,operfrequency,riscdeployed) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
$opertype = $info->rtt_opertype();
$opertargetaddr = $info->rtt_opertargetaddr();
$opertargetport = $info->rtt_opertargetport();
$operrequestsize = $info->rtt_operrequestsize();
$operresponsesize = $info->rtt_operresponsesize();
$opersourceaddr = $info->rtt_opersourceaddr();
$opersourceport = $info->rtt_opersourceport();
$opertos = $info->rtt_opertos();
$operpktinterval = $info->rtt_pktinterval();
$opernumpkts = $info->rtt_numpkts();
$opercodec = $info->rtt_codec();
$opercodecinterval = $info->rtt_codecinterval();
$opercodecpayload = $info->rtt_codecpayload();
$opercodecnumpkts = $info->rtt_codecnumpkts();
$operlife = $info->rtt_operlife();
$operfrequency = $info->rtt_operfrequency();
foreach my $opid (keys %$opertargetaddr) {
	my $index = $opid;
	my $type2 = $opertype->{$opid};
	my $targetaddr = unpack('H*', $opertargetaddr->{$opid});
	my $targetport = $opertargetport->{$opid};
	my $requestsize = $operrequestsize->{$opid};
	my $responsesize = $operresponsesize->{$opid};
	my $sourceaddr = unpack('H*',$opersourceaddr->{$opid});
	my $sourceport = $opersourceport->{$opid};
	my $tos = $opertos->{$opid};
	my $pktinterval = $operpktinterval->{$opid};
	my $numpkts = $opernumpkts->{$opid};
	my $codec = $opercodec->{$opid};
	my $codecinterval = $opercodecinterval->{$opid};
	my $codecpayload = $opercodecpayload->{$opid};
	my $codecnumpkts = $opercodecnumpkts->{$opid};
	my $life = $operlife->{$opid};
	my $frequency = $operfrequency->{$opid};
	my $targetip = join '.', unpack "C*", pack "H*", $targetaddr;
	my $sourceip = join '.', unpack "C*", pack "H*", $sourceaddr;
	if (defined $codecinterval){$codecinterval=$codecinterval;} else {$codecinterval=$operpktinterval;}
	#$codecinterval = $operpktinterval if undefined $codecinterval;
	if (defined $codecnumpkts){$codecnumpkts=$codecnumpkts;} else {$codecnumpkts=$opernumpkts;}
	#$codecnumpkts = $opernumpkts if undefined $codecnumpkts;
	if (defined $codecpayload) {$codecpayload=$codecpayload;} else {$codecpayload=$requestsize;}
	#$codecpayload = $requestsize if undefined $codecpayload;
	print "$index,$type,$targetip,$targetport,$requestsize,$responsesize,$sourceip,$sourceport,$tos,$pktinterval,$numpkts,$codec,$codecinterval,$codecpayload,$codecnumpkts,$life,$frequency\n";
	$sth21->execute($index,$type2,$targetip,$targetport,$requestsize,$responsesize,$sourceip,$sourceport,$tos,$pktinterval,$numpkts,$codec,$codecinterval,$codecpayload,$codecnumpkts,$life,$frequency,0);
}
$sth21->finish();
}; if ($@){print "problem collecting IP SLA inventory information: $@\n";};
}
sub GatherQosPerfInfo{
#Now, go through the port qos and get the configs and the first list of stats, that way when you run the performance
#you will know which deviceids to go after.
eval {
die "SNMP Community or Version probably wrong connecting to device. $err\n" if defined $err;
my $sth220 = $mysql->prepare_cached("INSERT INTO cportqosrlconfig (deviceid,intindex,direction,enable,rate,burstsize) values (?,?,?,?,?,?)");
my $sth221 = $mysql->prepare_cached("INSERT INTO cportqostsconfig (deviceid,intindex,enable,rate,burstsize) values (?,?,?,?,?)");
my $sth222 = $mysql->prepare_cached("INSERT INTO cportqosstat (deviceid,intindex,direction,qosindex,prepolicypkts,postpolicypkts,prepolicyoctets,postpolicyoctets,droppkts,dropoctets,classifiedpkts,classifiedoctets,nochangepkts,nochangeoctets,scantime) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
#cportqos RL Config
my $cport_rl_direction = $info->portqos_RLConfigDirection();
my $cport_rl_enable = $info->portqos_RLConfigEnable();
my $cport_rl_rate = $info->portqos_RLConfigRate();
my $cport_rl_burstsize = $info->portqos_RLConfigBurstSize();
foreach my $cport_rl (keys %$cport_rl_direction) {
	$sth220->execute($deviceid,$cport_rl,$$cport_rl_direction->{$cport_rl},$cport_rl_enable->{$cport_rl},$cport_rl_rate->{$cport_rl},$cport_rl_burstsize->{$cport_rl});
	}
#cportqos TS Config
my $cport_ts_enable = $info->portqos_TSConfigEnable();
my $cport_ts_rate = $info->portqos_TSConfigRate();
my $cport_ts_burstsize = $info->portqos_TSConfigBurstSize();
foreach my $cport_ts (keys %$cport_ts_enable) {
	$sth221->execute($deviceid,$cport_ts,$cport_ts_enable->{$cport_ts},$cport_ts_rate->{$cport_ts},$cport_ts_burstsize->{$cport_ts});
	}
#cportqos Stats pull - just an initial one
my $cport_scantime = time();
my $cport_stat_prepkts = $info->portqos_qosPrePolicyPkts();
my $cport_stat_postpkts = $info->portqos_qosPostPolicyPkts();
my $cport_stat_preoctets = $info->portqos_qosPrePolicyOctets();
my $cport_stat_postoctets = $info->portqos_qosPostPolicyOctets();
my $cport_stat_droppkts = $info->portqos_qosDropPkts();
my $cport_stat_dropoctets = $info->portqos_qosDropOctets();
my $cport_stat_classpkts = $info->portqos_qosClassifiedPkts();
my $cport_stat_classoctets = $info->portqos_qosClassifiedOctets();
my $cport_stat_nochangepkts = $info->portqos_qosNoChangePkts();
my $cport_stat_nochangeoctets = $info->portqos_qosNoChangeOctets();
foreach my $cport_stat (keys %$cport_stat_droppkts) {
    my $s1=stringpos3($cport_stat,1);
    my $s2=stringpos3($cport_stat,2);
    my $s3=stringpos3($cport_stat,3);
	$sth222->execute($deviceid,$s1,$s2,$s3,$cport_stat_prepkts->{$cport_stat},$cport_stat_postpkts->{$cport_stat},$cport_stat_preoctets->{$cport_stat},$cport_stat_postoctets->{$cport_stat},$cport_stat_droppkts->{$cport_stat},$cport_stat_dropoctets->{$cport_stat},$cport_stat_classpkts->{$cport_stat},$cport_stat_classoctets->{$cport_stat},$cport_stat_nochangepkts->{$cport_stat},$cport_stat_nochangeoctets->{$cport_stat},$cport_scantime);
	}
}; if ($@){print "problem with Cisco Port or Switch QOS: $@\n";}
}
sub GatherSwitchQoS {
eval {
$sth200 = $mysql->prepare_cached("INSERT INTO csqcostodscp (deviceid,cos,dscp) values (?,?,?)");
$sth201 = $mysql->prepare_cached("INSERT INTO csqipprectodscp (deviceid,ipprec,dscp) values (?,?,?)");
$sth202 = $mysql->prepare_cached("INSERT INTO csqexptodscp (deviceid,exp,dscp) values (?,?,?)");
$sth203 = $mysql->prepare_cached("INSERT INTO csqdscpmapping (deviceid,dscp,cos,exp,normalburstdscp,maxburstdscp) values (?,?,?,?,?,?)");
$sth204 = $mysql->prepare_cached("INSERT INTO csqifcostoqueue (deviceid,intindex,direction,cos,queuenumber,queuethresholdnumber) values (?,?,?,?,?,?)");
$sth205 = $mysql->prepare_cached("INSERT INTO csqifdscptoqueue (deviceid,intindex,direction,dscp,queuenumber,queuethresholdnumber) values (?,?,?,?,?,?)");
$sth206 = $mysql->prepare_cached("INSERT INTO csqifdropconfig (deviceid,intindex,direction,queueindex,thresholdindex,algorithm,dropthreshold,minwredthreshold,maxwredthreshold) values (?,?,?,?,?,?,?,?,?)");
$sth207 = $mysql->prepare_cached("INSERT INTO csqifqueueconfig (deviceid,intindex,direction,queuenumber,queuewrrweight,queuesizeweight,queuestatsgranularity) values (?,?,?,?,?,?,?)");
$sth208 = $mysql->prepare_cached("INSERT INTO csqifmodeconfig (deviceid,intindex,vlanbasedqosmodeenable) values (?,?,?)");
$sth209 = $mysql->prepare_cached("INSERT INTO csqifconsistencycheck (deviceid,intindex,consistencycheckenable) values (?,?,?)");
$sth210 = $mysql->prepare_cached("INSERT INTO csqglobal (deviceid,dscprewriteenable,policeredirectedtrafficenable,portqueueingmodeenable,markingstatisticsenable) values (?,?,?,?,?)");
$sth211 = $mysql->prepare_cached("INSERT INTO csqifconfig (deviceid,intindex,defaultcos,truststate) values (?,?,?,?)");
#Global switch qos information
my $swqos_dscpReWriteEnable = $info->switchqos_dscpReWriteEnable();
my $swqos_policeRedirectedTrafficEnable = $info->switchqos_PoliceRedirectedTrafficEnable();
my $swqos_portQueueingModeEnable = $info->switchqos_PortQueueingModeEnable();
my $swqos_markingStatisticsEnable = $info->switchqos_MarkingStatisticsEnable();
if (defined $swqos_dscpReWriteEnable) {
	$sth210->execute($deviceid,$swqos_dscpReWriteEnable,$swqos_policeRedirectedTrafficEnable,$swqos_portQueueingModeEnable,$swqos_markingStatisticsEnable);
}
#QOS Mappings
my $swqos_c2d_d = $info->switchqos_mapCos2DSCP_DSCP();
foreach my $swx_c2d (keys %$swqos_c2d_d) {
	$sth200->execute($deviceid,$swx_c2d,$swqos_c2d_d->{$swx_c2d});
	}
my $swqos_i2d_d = $info->switchqos_mapIpPrec2DSCP_DSCP();
foreach my $swx_i2d (keys %$swqos_i2d_d) {
	$sth201->execute($deviceid,$swx_i2d,$swqos_i2d_d->{$swx_i2d});
	}
my $swqos_e2d_d = $info->switchqos_mapExp2DSCP_DSCP();
foreach my $swx_e2d (keys %$swqos_e2d_d) {
	$sth202->execute($deviceid,$swx_e2d,$swqos_e2d_d->{$swx_e2d});
	}
my $swqos_dscpmap_cos = $info->switchqos_DSCPMappingCos();
my $swqos_dscpmap_exp = $info->switchqos_DSCPMappingExp();
my $swqos_dscpmap_normalburstdscp = $info->switchqos_DSCPMappingNormalBurstDSCP();
my $swqos_dscpmap_maxburstdscp = $info->switchqos_DSCPMappingMaxBurstDSCP();
foreach my $swx_dscpm (keys %$swqos_dscpmap_cos) {
	$sth203->execute($deviceid,$swx_dscpm,$swqos_dscpmap_cos->{$swx_dscpm},$swqos_dscpmap_exp->{$swx_dscpm},$swqos_dscpmap_normalburstdscp->{$swx_dscpm},$swqos_dscpmap_maxburstdscp->{$swx_dscpm});
	}
my $swqos_ifcos2q_qnumber = $info->switchqos_IfCOS2Queue_QueueNumber();
my $swqos_ifcos2q_thresholdnumber = $info->switchqos_IfCOS2Queue_ThresholdNumber();
foreach my $swx_ifcos2q (keys %$swqos_ifcos2q_qnumber) {
	my $s1 = stringpos3($swx_ifcos2q,1);
	my $s2 = stringpos3($swx_ifcos2q,2);
	my $s3 = stringpos3($swx_ifcos2q,3);
	$sth204->execute($deviceid,$s1,$s2,$s3,$swqos_ifcos2q_qnumber->{$swx_ifcos2q},$swqos_ifcos2q_thresholdnumber->{$swx_ifcos2q});
	}
my $swqos_ifd2q_qnumber = $info->switchqos_IfDSCP2Queue_QueueNumber();
my $swqos_ifd2q_thresholdnumber = $info->switchqos_IfDSCP2Queue_ThresholdNumber();
foreach my $swx_ifd2q (keys %$swqos_ifd2q_qnumber) {
	my $s1 = stringpos3($swx_ifd2q,1);
	my $s2 = stringpos3($swx_ifd2q,2);
	my $s3 = stringpos3($swx_ifd2q,3);
	$sth205->execute($deviceid,$s1,$s2,$s3,$swqos_ifd2q_qnumber->{$swx_ifd2q},$swqos_ifd2q_thresholdnumber->{$swx_ifd2q});
	}
my $swqos_int_defaultcos = $info->switchqos_IfDefaultCos();
my $swqos_int_truststate = $info->switchqos_IfTrustState();
foreach my $swx_int (keys %$swqos_int_defaultcos) {
	$sth211->execute($deviceid,$swx_int,$swqos_int_defaultcos->{$swx_int},$swqos_int_truststate->{$swx_int});
	}
my $swqos_drop_algorithm = $info->switchqos_IfDropConfigDropAlgorithm();
my $swqos_drop_dthreshold = $info->switchqos_IfDropConfigDropThreshold();
my $swqos_drop_minwredthreshold = $info->switchqos_IfDropConfigMinWredThreshold();
my $swqos_drop_maxwredthreshold = $info->switchqos_IfDropConfigMaxWredThreshold();
foreach my $swx_drop (keys %$swqos_drop_algorithm) {
	my $s1 = stringpos4($swx_drop,1);
	my $s2 = stringpos4($swx_drop,2);
	my $s3 = stringpos4($swx_drop,3);
	my $s4 = stringpos4($swx_drop,4);
	$sth206->execute($deviceid,$s1,$s2,$s3,$s4,$swqos_drop_algorithm->{$swx_drop},$swqos_drop_dthreshold->{$swx_drop},$swqos_drop_minwredthreshold->{$swx_drop},$swqos_drop_maxwredthreshold->{$swx_drop});
	}
my $swqos_q_wrrweight = $info->switchqos_IfQueueWrrWeight();
my $swqos_q_sizeweight = $info->switchqos_IfQueueSizeWeight();
my $swqos_q_statsgran = $info->switchqos_IFQueueStatsGranularity();
foreach my $swx_q (keys %$swqos_q_dwrrweight) {
	my $s1 = stringpos3($swx_q,1);
	my $s2 = stringpos3($swx_q,2);
	my $s3 = stringpos3($swx_q,3);
	$sth207->execute($deviceid,$s1,$s2,$s3,$swqos_q_wrrweight->{$swx_q},$swqos_q_sizeweight->{$swx_q},$swqos_q_statsgran->{$swx_q});
	}
my $swqos_mode_vlanbased = $info->switchqos_IfVlanBasedQosModeEnable();
foreach my $swx_mode (keys %$swqos_mode_vlanbased) {
	$sth208->execute($deviceid,$swx_mode,$swqos_mode_vlanbased->{$swx_mode});
	}
my $swqos_consist = $info->switchqos_IfConsistencyCheckEnable();
foreach my $swx_consist (keys %$swqos_consist) {
	$sth209->execute($deviceid,$swx_consist,$swqos_consist->{$swx_consist});
	}
}; if ($@) {print "Problem with CISCO-SWITCH-QOS INventory: $@\n";}
}
sub GetMDSInfo {
eval {
#Get Devices-match 'mds'
$query100 = "SELECT deviceid, ipaddress,snmpstring FROM riscdevice where (sysdescription regexp 'mds') or (sysdescription regexp 'NX-OS')";
$sth100 = $mysql->prepare($query100);
$sth100->execute();
$sth60 = $mysql->prepare_cached("INSERT INTO fcsNetwork (deviceid,Net_Index,Switch_WWN) VALUES (?,?,?)");
$sth61 = $mysql->prepare_cached("INSERT INTO fcsInterface (deviceid,SwitchPort_WWN,port_ifindex,port_Inet_Type,port_Inet_addr) VALUES (?,?,?,?,?)");
$sth62 = $mysql->prepare_cached("INSERT INTO fcsDeviceAlias (deviceid,DeviceAlias,DeviceType,ID,RowStatus) VALUES (?,?,?,?,?)");
$sth63 = $mysql->prepare_cached("INSERT INTO fcshbaInfo (deviceid,InfoID,NodeName,Mfg,SerialNum,Model,HWVer,DriverVer,ObtROMVer,FWVer,OSInfo,MaxCTPayload) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
$sth64 = $mysql->prepare_cached("INSERT INTO fcshbaPort (deviceid,PortID,SupportedFC4Type,SupportedSpeed,MaxFrameSize,OSDevName,HostName) VALUES (?,?,?,?,?,?,?)");
$sth65 = $mysql->prepare_cached("INSERT INTO fcsFDMIIF (deviceid,WWN,AdminMode,OperMode,AdminSpeed,BeaconMode,PortChIfIndex,OperStatDescr,AdminTrunkMode,OperTrunkMode,AllowedVsanList2k,AllowedVsanList4k,ActiveVsanList2k,ActiveVsanList4k,BbCreditModel,HoldTime,TransmitterType,ConnectorType,SerialNum,Revision,Vendor,SFPSerialIDData,PartNumber,AdminRxBbCredit,AdminRxBbCreditModelSL,AdminRxBbCreditModelFX,OperRxBbCredit,RxDataFieldSize,ActiveVsanUpList2k,ActiveVsanUpList4k,PortRateMode,AdminRxPerfBuffer,OperRxPerfBuffer,BbScn,PortInitStatus,AdminRxBbCreditExtended,TunnelIfIndex,ServiceState,AdminBbScnMode) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
$sth66 = $mysql->prepare_cached("INSERT INTO fcsTrunkIf (deviceid,OperStatus,OperStatusCause,OperStatusCauseDesc) VALUES (?,?,?,?)");
$sth67 = $mysql->prepare_cached("INSERT INTO fcsElpEntry (deviceid,NbrNodeName,NbrPortName,RxZBbCredit,CosSuppAgreed,Class2Seqdel,Class2RxDataFieldSize,Class3Seqdel,Class3RxDataFieldSize,ClassFXII,ClassFRxDataFieldSize,ClassFConcurrentSeq,ClassFEndToEndCredit,ClassFOpenSeq) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
$sth68 = $mysql->prepare_cached("INSERT INTO fcsRNIDInfo (deviceid,status,TypeNum,ModeNum,Manufacture,PlantofMfg,SerialNum,UnitType,PortID) VALUES (?,?,?,?,?,?,?,?,?)");
$sth69 = $mysql->prepare_cached("INSERT INTO fcsIfGig (deviceid,PortChanIfIndex,AutoNegotiate,BeaconMode) VALUES (?,?,?,?)");
#FCS Network
 my $netindex = $info->clp_Network_Index();
 my $switch_wwn = $info->clp_Network_SwitchWWN();
foreach my $iid (keys %$netindex){
   $val_netindex = "";
   $val_switch_wwn = "";
   $val_netindex = $netindex->{$iid};
   $val_switch_wwn = $switch_wwn->{$iid};
   $sth60->execute($deviceid,$val_netindex,$val_switch_wwn);
}
$sth60->finish();



#FCS Network Interface Table
 my $netportswitchwwn = $info->clp_Network_Port_SwitchWWN();
 my $netportintindex = $info->clp_Network_Port_IfIndex();
 my $netportaddrtype = $info->clp_Network_Port_InetAddrType();
 my $networkinetaddr = $info->clp_Network_Port_InetQAddr();
foreach my $iid (keys %$netportswitchwwn){
   $val_netportswitchwwn = "";
   $val_netportintindex = "";
   $val_netportaddrtype = "";
   $val_networkinetaddr = "";
   $val_netportswitchwwn = $netportswitchwwn->{$iid};
   $val_netportintindex = $netportintindex->{$iid};
   $val_netportaddrtype = $netportaddrtype->{$iid};
   $val_networkinetaddr = $networkinetaddr->{$iid};
   $sth61->execute($deviceid,$val_netportswitchwwn,$val_netportintindex,$val_netportaddrtype,$val_networkinetaddr);
}
$sth61->finish();



#FCS Network device alias
 my $devicealias = $info->cfda_Config_DeviceAlias();
 my $devicetype = $info->cfda_Config_DeviceType();
 my $confdeviceid = $info->cfda_Config_DeviceID();
 my $rowstatus = $info->cfda_Config_RowStatus();
foreach my $iid (keys %$devicealias){
   $val_devicealias = "";
   $val_devicetype = "";
   $val_confdeviceid = "";
   $val_rowstatus = "";
   $val_devicealias = $devicealias->{$iid};
   $val_devicetype = $devicetype->{$iid};
   $val_confdeviceid = $confdeviceid->{$iid};
   $val_rowstatus = $rowstatus->{$iid};
   $sth62->execute($deviceid,$val_devicealias,$val_devicetype,$val_confdeviceid,$val_rowstatus);
}
$sth62->finish();


#FCS HBA Info
 my $hba_infoid = $info->cfdmi_HbaInfo_InfoId();
 my $hba_nodename = $info->cfdmi_HbaInfo_NodeName();
 my $hba_mfg = $info->cfdmi_HbaInfo_Mfg();
 my $hba_sn = $info->cfdmi_HbaInfo_Sn();
 my $hba_model = $info->cfdmi_HbaInfo_Model();
 my $hba_modeldesc = $info->cfdmi_HbaInfo_ModelDescr();
 my $hba_hwver = $info->cfdmi_HbaInfo_HwVer();
 my $hba_driverver = $info->cfdmi_HbaInfo_DriverVer();
 my $hba_romver = $info->cfdmi_HbaInfo_ObtROMVer();
 my $hba_fwver = $info->cfdmi_HbaInfo_FwVer();
 my $hba_os = $info->cfdmi_HbaInfo_OSInfo();
 my $hba_maxpayload = $info->cfdmi_HbaInfo_MaxCTPayload();
foreach my $iid (keys %$hba_infoid){
   $val_hba_infoid = "";
   $val_hba_nodename = "";
   $val_hba_mfg = "";
   $val_hba_sn = "";
   $val_hba_model = "";
   $val_hba_modeldesc = "";
   $val_hba_hwver = "";
   $val_hba_driverver = "";
   $val_hba_romver = "";
   $val_hba_fwver = "";
   $val_hba_os = "";
   $val_hba_maxpayload = "";
   $val_hba_infoid = $hba_infoid->{$iid};
   $val_hba_nodename = $hba_nodename->{$iid};
   $val_hba_mfg = $hba_mfg->{$iid};
   $val_hba_sn = $hba_sn->{$iid};
   $val_hba_model = $hba_model->{$iid};
   $val_hba_modeldesc = $hba_modeldesc->{$iid};
   $val_hba_hwver = $hba_hwver->{$iid};
   $val_hba_driverver = $hba_driverver->{$iid};
   $val_hba_romver = $hba_romver->{$iid};
   $val_hba_fwver = $hba_fwver->{$iid};
   $val_hba_os = $hba_os->{$iid};
   $val_hba_maxpayload = $hba_maxpayload->{$iid};
   $sth63->execute($deviceid,$val_hba_infoid,$val_hba_nodename,$val_hba_mfg,$val_hba_sn,$val_hba_model,$val_hba_modeldesc,$val_hba_hwver,$val_hba_driverver,$val_hba_romver,$val_hba_fwver,$val_hba_os,$val_hba_maxpayload);
}
$sth63->finish();


#FCS HBA Port Table
 my $hba_portid = $info->cfdmi_HbaPort_Id();
 my $hba_supportedfc4type = $info->cfdmi_HbaPort_SupportedFC4Type();
 my $hba_supportspeed = $info->cfdmi_HbaPort_SupportedSpeed();
 my $hba_curspeed = $info->cfdmi_HbaPort_CurrentSpeed();
 my $hba_maxframesize = $info->cfdmi_HbaPort_MaxFrameSize();
 my $hba_osdevname = $info->cfdmi_HbaPort_OsDevName();
 my $hba_hostname = $info->cfdmi_HbaPort_HostName();
foreach my $iid (keys %$hba_portid){
   $val_hba_portid = "";
   $val_hba_supportedfc4type = "";
   $val_hba_supportspeed = "";
   $val_hba_curspeed = "";
   $val_hba_maxframesize = "";
   $val_hba_osdevname = "";
   $val_hba_hostname = "";
   $val_hba_portid = $hba_portid->{$iid};
   $val_hba_supportedfc4type = $hba_supportedfc4type->{$iid};
   $val_hba_supportspeed = $hba_supportspeed->{$iid};
   $val_hba_curspeed = $hba_curspeed->{$iid};
   $val_hba_maxframesize = $hba_maxframesize->{$iid};
   $val_hba_osdevname = $hba_osdevname->{$iid};
   $val_hba_hostname = $hba_hostname->{$iid};

   $sth64->execute($deviceid,$val_hba_portid,$val_hba_supportedfc4type,$val_hba_supportspeed,$val_hba_curspeed,$val_hba_maxframesize,$val_hba_osdevname,$val_hba_hostname);
}
$sth64->finish();


#FCS Interface info
 my $If_Wwn = $info->fcIf_Wwn();
 my $If_AdminMode = $info->fcIf_AdminMode();
 my $If_OperMode = $info->fcIf_OperMode();
 my $If_AdminSpeed = $info->fcIf_AdminSpeed();
 my $If_BeaconMode = $info->fcIf_BeaconMode();
 my $If_PortChannelIfIndex = $info->fcIf_PortChannelIfIndex();
 my $If_OperStatusCauseDescr = $info->fcIf_OperStatusCauseDescr();
 my $If_AdminTrunkMode = $info->fcIf_AdminTrunkMode();
 my $If_OperTrunkMode = $info->fcIf_OperTrunkMode();
 my $If_AllowedVsanList2k = $info->fcIf_AllowedVsanList2k();
 my $If_AllowedVsanList4k = $info->fcIf_AllowedVsanList4k();
 my $If_ActiveVsanList2k = $info->fcIf_ActiveVsanList2k();
 my $If_ActiveVsanList4k = $info->fcIf_ActiveVsanList4k();
 my $If_BbCreditModel = $info->fcIf_BbCreditModel();
 my $If_HoldTime = $info->fcIf_HoldTime();
 my $If_TransmitterType = $info->fcIf_TransmitterType();
 my $If_ConnectorType = $info->fcIf_ConnectorType();
 my $If_SerialNo = $info->fcIf_SerialNo();
 my $If_Revision = $info->fcIf_Revision();
 my $If_Vendor = $info->fcIf_Vendor();
 my $If_SFPSerialIDData = $info->fcIf_SFPSerialIDData();
 my $If_PartNumber = $info->fcIf_PartNumber();
 my $If_AdminRxBbCredit = $info->fcIf_AdminRxBbCredit();
 my $If_AdminRxBbCreditModelSL = $info->fcIf_AdminRxBbCreditModelSL();
 my $If_AdminRxBbCreditModelFx = $info->fcIf_AdminRxBbCreditModelFx();
 my $If_OperRxBbCredit = $info->fcIf_OperRxBbCredit();
 my $If_RxDataFieldSize = $info->fcIf_RxDataFieldSize();
 my $If_ActiveVsanUpList2k = $info->fcIf_ActiveVsanUpList2k();
 my $If_ActiveVsanUpList4k = $info->fcIf_ActiveVsanUpList4k();
 my $If_PortRateMode = $info->fcIf_PortRateMode();
 my $If_AdminRxPerfBuffer = $info->fcIf_AdminRxPerfBuffer();
 my $If_OperRxPerfBuffer = $info->fcIf_OperRxPerfBuffer();
 my $If_BbScn = $info->fcIf_BbScn();
 my $If_PortInitStatus = $info->fcIf_PortInitStatus();
 my $If_AdminRxBbCreditExtended = $info->fcIf_AdminRxBbCreditExtended();
 my $If_TunnelIfIndex = $info->fcIf_TunnelIfIndex();
 my $If_ServiceState = $info->fcIf_ServiceState();
 my $If_AdminBbScnMode = $info->fcIf_AdminBbScnMode();
foreach my $iid (keys %$If_Wwn){
   $val_If_Wwn = "";
   $val_If_AdminMode = "";
   $val_If_OperMode = "";
   $val_If_AdminSpeed = "";
   $val_If_BeaconMode = "";
   $val_If_PortChannelIfIndex = "";
   $val_If_OperStatusCauseDescr = "";
   $val_If_AdminTrunkMode = "";
   $val_If_OperTrunkMode = "";
   $val_If_AllowedVsanList2k = "";
   $val_If_AllowedVsanList4k = "";
   $val_If_ActiveVsanList2k = "";
   $val_If_ActiveVsanList4k = "";
   $val_If_BbCreditModel = "";
   $val_If_HoldTime = "";
   $val_If_TransmitterType = "";
   $val_If_ConnectorType = "";
   $val_If_SerialNo = "";
   $val_If_Revision = "";
   $val_If_Vendor = "";
   $val_If_SFPSerialIDData = "";
   $val_If_PartNumber = "";
   $val_If_AdminRxBbCredit = "";
   $val_If_AdminRxBbCreditModelSL = "";
   $val_If_AdminRxBbCreditModelFx = "";
   $val_If_OperRxBbCredit = "";
   $val_If_RxDataFieldSize = "";
   $val_If_ActiveVsanUpList2k = "";
   $val_If_ActiveVsanUpList4k = "";
   $val_If_PortRateMode = "";
   $val_If_AdminRxPerfBuffer = "";
   $val_If_OperRxPerfBuffer = "";
   $val_If_BbScn = "";
   $val_If_PortInitStatus = "";
   $val_If_AdminRxBbCreditExtended = "";
   $val_If_TunnelIfIndex = "";
   $val_If_ServiceState = "";
   $val_If_AdminBbScnMode = "";
   $val_If_Wwn = $If_Wwn->{$iid};
   $val_If_AdminMode = $If_AdminMode->{$iid};
   $val_If_OperMode = $If_OperMode->{$iid};
   $val_If_AdminSpeed = $If_AdminSpeed->{$iid};
   $val_If_BeaconMode = $If_BeaconMode->{$iid};
   $val_If_PortChannelIfIndex = $If_PortChannelIfIndex->{$iid};
   $val_If_OperStatusCauseDescr = $If_OperStatusCauseDescr->{$iid};
   $val_If_AdminTrunkMode = $If_AdminTrunkMode->{$iid};
   $val_If_OperTrunkMode = $If_OperTrunkMode->{$iid};
   $val_If_AllowedVsanList2k = $If_AllowedVsanList2k->{$iid};
   $val_If_AllowedVsanList4k = $If_AllowedVsanList4k->{$iid};
   $val_If_ActiveVsanList2k = $If_ActiveVsanList2k->{$iid};
   $val_If_ActiveVsanList4k = $If_ActiveVsanList4k->{$iid};
   $val_If_BbCreditModel = $If_BbCreditModel->{$iid};
   $val_If_HoldTime = $If_HoldTime->{$iid};
   $val_If_TransmitterType = $If_TransmitterType->{$iid};
   $val_If_ConnectorType = $If_ConnectorType->{$iid};
   $val_If_SerialNo = $If_SerialNo->{$iid};
   $val_If_Revision = $If_Revision->{$iid};
   $val_If_Vendor = $If_Vendor->{$iid};
   $val_If_SFPSerialIDData = $If_SFPSerialIDData->{$iid};
   $val_If_PartNumber = $If_PartNumber->{$iid};
   $val_If_AdminRxBbCredit = $If_AdminRxBbCredit->{$iid};
   $val_If_AdminRxBbCreditModelSL = $If_AdminRxBbCreditModelSL->{$iid};
   $val_If_AdminRxBbCreditModelFx = $If_AdminRxBbCreditModelFx->{$iid};
   $val_If_OperRxBbCredit = $If_OperRxBbCredit->{$iid};
   $val_If_RxDataFieldSize = $If_RxDataFieldSize->{$iid};
   $val_If_ActiveVsanUpList2k = $If_ActiveVsanUpList2k->{$iid};
   $val_If_ActiveVsanUpList4k = $If_ActiveVsanUpList4k->{$iid};
   $val_If_PortRateMode = $If_PortRateMode->{$iid};
   $val_If_AdminRxPerfBuffer = $If_AdminRxPerfBuffer->{$iid};
   $val_If_OperRxPerfBuffer = $If_OperRxPerfBuffer->{$iid};
   $val_If_BbScn = $If_BbScn->{$iid};
   $val_If_PortInitStatus = $If_PortInitStatus->{$iid};
   $val_If_AdminRxBbCreditExtended = $If_AdminRxBbCreditExtended->{$iid};
   $val_If_TunnelIfIndex = $If_TunnelIfIndex->{$iid};
   $val_If_ServiceState = $If_ServiceState->{$iid};
   $val_If_AdminBbScnMode = $If_AdminBbScnMode->{$iid};
   $sth65->execute($deviceid,$val_If_Wwn,$val_If_AdminMode,$val_If_OperMode,$val_If_AdminSpeed,$val_If_BeaconMode,$val_If_PortChannelIfIndex,$val_If_OperStatusCauseDescr,$val_If_AdminTrunkMode,$val_If_OperTrunkMode,$val_If_AllowedVsanList2k,$val_If_AllowedVsanList4k,$val_If_ActiveVsanList2k,$val_If_ActiveVsanList4k,$val_If_BbCreditModel,$val_If_HoldTime,$val_If_TransmitterType,$val_If_ConnectorType,$val_If_SerialNo,$val_If_Revision,$val_If_Vendor,$val_If_SFPSerialIDData,$val_If_PartNumber,$val_If_AdminRxBbCredit,$val_If_AdminRxBbCreditModelSL,$val_If_AdminRxBbCreditModelFx,$val_If_OperRxBbCredit,$val_If_RxDataFieldSize,$val_If_ActiveVsanUpList2k,$val_If_ActiveVsanUpList4k,$val_If_PortRateMode,$val_If_AdminRxPerfBuffer,$val_If_OperRxPerfBuffer,$val_If_BbScn,$val_If_PortInitStatus,$val_If_AdminRxBbCreditExtended,$val_If_TunnelIfIndex,$val_If_ServiceState,$val_If_AdminBbScnMode);
}
$sth65->finish();


#FCS Trunk Interface table
 my $ifoperstatus = $info->fc_Trunk_IfOperStatus();
 my $ifoperstatuscause = $info->fc_Trunk_IfOperStatusCause();
 my $ifoperstatuscausedesc = $info->fc_Trunk_IfOperStatusCauseDescr();
foreach my $iid (keys %$ifoperstatus){
   $val_ifoperstatus = "";
   $val_ifoperstatuscause = "";
   $val_ifoperstatuscausedesc = "";
   $val_ifoperstatus = $ifoperstatus->{$iid};
   $val_ifoperstatuscause = $ifoperstatuscause->{$iid};
   $val_ifoperstatuscausedesc = $ifoperstatuscausedesc->{$iid};
   $sth66->execute($deviceid,$val_ifoperstatus,$val_ifoperstatuscause,$val_ifoperstatuscausedesc);
}
$sth66->finish();


#FCS neighbor info
 my $nbrnodename = $info->fcIf_Elp_NbrNodeName();
 my $nbrportname = $info->fcIf_Elp_NbrPortName();
 my $rxBbcredit = $info->fcIf_Elp_RxBbCredit();
 my $cossuppagreed = $info->fcIf_Elp_CosSuppAgreed();
 my $class2SeqDelivAgreed = $info->fcIf_Elp_Class2SeqDelivAgreed();
 my $class2RxDataFieldSize = $info->fcIf_Elp_Class2RxDataFieldSize();
 my $class3seqDelivAgreed = $info->fcIf_Elp_Class3SeqDelivAgreed();
 my $class3RxDataFieldSize = $info->fcIf_Elp_Class3RxDataFieldSize();
 my $ClassFXii = $info->fcIf_Elp_ClassFXII();
 my $classFRxDatafieldSize = $info->fcIf_Elp_ClassFRxDataFieldSize();
 my $classFConcurrentSeq = $info->fcIf_Elp_ClassFConcurrentSeq();
 my $ClassFEndtoEndCredit = $info->fcIf_Elp_ClassFEndToEndCredit();
 my $classFOpenSeq = $info->fcIf_Elp_ClassFOpenSeq();
foreach my $iid (keys %$nbrnodename){
   $val_nbrnodename = "";
   $val_nbrportname = "";
   $val_rxBbcredit = "";
   $val_cossuppagreed = "";
   $val_class2SeqDelivAgreed = "";
   $val_class2RxDataFieldSize = "";
   $val_class3seqDelivAgreed = "";
   $val_class3RxDataFieldSize = "";
   $val_ClassFXii = "";
   $val_classFRxDatafieldSize = "";
   $val_classFConcurrentSeq = "";
   $val_ClassFEndtoEndCredit = "";
   $val_classFOpenSeq = "";
   $val_nbrnodename = $nbrnodename->{$iid};
   $val_nbrportname = $nbrportname->{$iid};
   $val_rxBbcredit = $rxBbcredit->{$iid};
   $val_cossuppagreed = $cossuppagreed->{$iid};
   $val_class2SeqDelivAgreed = $class2SeqDelivAgreed->{$iid};
   $val_class2RxDataFieldSize = $class2RxDataFieldSize->{$iid};
   $val_class3seqDelivAgreed = $class3seqDelivAgreed->{$iid};
   $val_class3RxDataFieldSize = $class3RxDataFieldSize->{$iid};
   $val_ClassFXii = $ClassFXii->{$iid};
   $val_classFRxDatafieldSize = $classFRxDatafieldSize->{$iid};
   $val_classFConcurrentSeq = $classFConcurrentSeq->{$iid};
   $val_ClassFEndtoEndCredit = $ClassFEndtoEndCredit->{$iid};
   $val_classFOpenSeq = $classFOpenSeq->{$iid};
   $sth67->execute($deviceid,$val_nbrnodename,$val_nbrportname,$val_rxBbcredit,$val_cossuppagreed,$val_class2SeqDelivAgreed,$val_class2RxDataFieldSize,$val_class3seqDelivAgreed,$val_class3RxDataFieldSize,$val_ClassFXii,$val_classFRxDatafieldSize,$val_classFConcurrentSeq,$val_ClassFEndtoEndCredit,$val_classFOpenSeq);
}
$sth67->finish();


#FCS RNID Info table
 my $RNIDInfoStatus = $info->fcIf_RNIDInfo_Status();
 my $InfoTypeNum = $info->fcIf_RNIDInfo_TypeNumber();
 my $InfoModeNum = $info->fcIf_RNIDInfo_ModeNumber();
 my $InfoManufacture = $info->fcIf_RNIDInfo_Manufacture();
 my $PlantOfMfg = $info->fcIf_RNIDInfo_PlantOfMfg();
 my $SerialNum = $info->fcIf_RNIDInfo_SerialNumber();
 my $UnitType = $info->fcIf_RNIDInfo_UnitType();
 my $PortID = $info->fcIf_RNIDInfo_PortId();
foreach my $iid (keys %$RNIDInfoStatus){
   $val_RNIDInfoStatus = "";
   $val_InfoTypeNum = "";
   $val_InfoModeNum = "";
   $val_InfoManufacture = "";
   $val_PlantOfMfg = "";
   $val_SerialNum = "";
   $val_UnitType = "";
   $val_PortID = "";
   $val_RNIDInfoStatus = $RNIDInfoStatus->{$iid};
   $val_InfoTypeNum = $InfoTypeNum->{$iid};
   $val_InfoModeNum = $InfoModeNum->{$iid};
   $val_InfoManufacture = $InfoManufacture->{$iid};
   $val_PlantOfMfg = $PlantOfMfg->{$iid};
   $val_SerialNum = $SerialNum->{$iid};
   $val_UnitType = $UnitType->{$iid};
   $val_PortID = $PortID->{$iid};
   $sth68->execute($deviceid,$val_RNIDInfoStatus,$val_InfoTypeNum,$val_InfoModeNum,$val_InfoManufacture,$val_PlantOfMfg,$val_SerialNum,$val_UnitType,$val_PortID);
}
$sth68->finish();


#FCS Gig Table
 my $portchanIfIndex = $info->fcIf_GigE_PortChannelIfIndex();
 my $autoneg = $info->fcIf_GigE_AutoNegotiate();
 my $beaconmode = $info->fcIf_GigE_BeaconMode();
foreach my $iid (keys %$portchanIfIndex){
   $val_portchanIfIndex = "";
   $val_autoneg = "";
   $val_beaconmode = "";
   $val_portchanIfIndex = $portchanIfIndex->{$iid};
   $val_autoneg = $autoneg->{$iid};
   $val_beaconmode = $beaconmode->{$iid};
   $sth69->execute($deviceid,$val_portchanIfIndex,$val_autoneg,$val_beaconmode);
}
$sth69->finish();
}; if ($@){print "problem with FCS inventory"};
}	


