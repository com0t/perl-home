#!/usr/bin/perl
#
## remap-redeviceid.pl

## arguments: <orig-assessmentid> <new-assessmentid>
#
## when we remap an appliance to a new assessment, the assessmentid obviously changes
## since the assessmentid is a component of deviceids, and the assessmentid is passed to the disco scripts,
##  deviceids generated on scans after the remap will be slightly different
## this has implications when vmware builds its windowsosids, and in the riscdevice/credentials deviceid-/mac-based
##  unique constraints (credentials uniqueid, riscdevice mac when mac is the deviceid)
## in order to keep everything trued up, when we remap we need to rebuild all of the deviceids to swap the old
##  assessmentid with the new assessmentid

use strict;
use RISC::riscUtility;
use RISC::remapping;
use Data::Dumper;

my $debugging = 0;
$debugging = $ENV{'DEBUG'} if ( defined( $ENV{'DEBUG'} ) );

my $assessmentid = shift;
my $db           = getCustDBH($assessmentid);

dbg('begin');

eval {
    ## build a hash of vmware deviceids
    ## these are used below to skip processing
    dbg('building skip hash');
    dbg('adding vmwareids to skip hash');
    my $skipids;
    my $vmwareidQ =
      $db->prepare("select distinct deviceid from riscvmwarematrix");
    $vmwareidQ->execute();
    while ( my $vmid = $vmwareidQ->fetchrow_hashref() ) {
        $skipids->{ $vmid->{'deviceid'} }++;
    }

    ## dboids also need to be skipped, as they have a potential to begin with something
    ## that looks like the assessmentid
    dbg('adding DB dboids to skip hash');
    my $dboids = $db->prepare('select distinct dboid from db_inventory');
    $dboids->execute();
    while ( my $dboid = $dboids->fetchrow_hashref() ) {
        $skipids->{ $dboid->{'dboid'} }++;
    }

    ## build a hash of all tables that have a deviceid column
    ## we skip riscvmwarematrix (deviceid is the small deviceid)
    ## we skip riscdevice (requires special processing to handle deviceids as macaddrs)
    dbg('building table list');
    my $tables = $db->selectall_hashref(
        "select table_name
						from information_schema.columns
						where column_name = 'deviceid'
							and table_name not in ('riscdevice','riscvmwarematrix')
							and table_schema = 'RISC_Discovery'
						", 'table_name'
    );

    ## loop through the table list
    ## for each, get a list of deviceids, skip vmwareids, replace the assessmentid portion, and update
    dbg('looping table list');
    foreach my $tbl ( sort keys %{$tables} ) {
        dbg("====> $tbl");
        my $update =
          $db->prepare("update $tbl set deviceid = ? where deviceid = ?");
        my $deviceids =
          $db->selectall_hashref( "select distinct deviceid from $tbl",
            'deviceid' );
        foreach my $devid ( keys %{$deviceids} ) {
            next if ( $skipids->{$devid} );
            my $pre  = $devid;
            my $post = remapping::xform_deviceid( $pre, $assessmentid );
            eval { $update->execute( $post, $pre ) unless $pre == $post;  };
            if ($@) {
                print STDERR "EXCEPTION: $tbl: $@";
            }
        }
    }

    ## credentials has already been modified for deviceid
    ## we need to rebuild the uniqueid (deviceid-protocol)
    dbg('rebuilding credentials uniqueids');
    eval {
        $db->do(
            "update credentials set uniqueid = concat(deviceid,'-',technology)"
        );
    };
    if ($@) {
        print STDERR "EXCEPTION: credentials.uniqueid: $@";
    }

    ## critical_interfaces has a connecteddeviceid field that needs updating
    dbg('rebuilding critical_interfaces connecteddeviceids');
    my $critintupdate = $db->prepare(
'update critical_interfaces set connecteddeviceid = ? where (deviceid = ? and connecteddeviceid = ?)'
    );
    my $critint = $db->prepare(
'select deviceid,connecteddeviceid from critical_interfaces where connecteddeviceid is not null'
    );
    $critint->execute();
    while ( my $ci = $critint->fetchrow_hashref() ) {
        my $pre  = $ci->{'connecteddeviceid'};
        my $post = remapping::xform_deviceid( $pre, $assessmentid );
        eval { $critintupdate->execute( $post, $ci->{'deviceid'}, $pre ) unless $pre == $post; };
        if ($@) {
            print STDERR "EXCEPTION: critical_interfaces: $@";
        }
    }

    ## riscdevice entries may have the assessmentid as the macaddr
    ## the macaddr field is the primary enforcer of uniqueness, so we have to update these to match the deviceid, but only where the mac is the deviceid
    ## there are cases where deviceids may be duplicated in riscdevice, with different macaddrs (inaccessible is now accessible), where downstream queries group to avoid them
    ## therefore, we have to be sure to only update one record at a time, using the macaddr in the where clause
    dbg('processing riscdevice');
    my $riscdevice = $db->prepare('select deviceid,macaddr from riscdevice');
    $riscdevice->execute();
    my $rdupdate = $db->prepare(
'update riscdevice set deviceid = ?, macaddr = ? where (deviceid = ? and macaddr = ?)'
    );
    while ( my $rd = $riscdevice->fetchrow_hashref() ) {
        next if ( $skipids->{ $rd->{'deviceid'} } );
        my $pre  = $rd->{'deviceid'};
        my $post = remapping::xform_deviceid( $pre, $assessmentid );
        eval {
            if ( $rd->{'deviceid'} eq $rd->{'macaddr'} ) {
                $rdupdate->execute( $post, $post, $rd->{'deviceid'},
                    $rd->{'deviceid'} ) unless $pre == $post;
            }
            else {
                $rdupdate->execute(
                    $post,             $rd->{'macaddr'},
                    $rd->{'deviceid'}, $rd->{'macaddr'}
                ) unless $pre == $post;
            }
        };
        if ($@) {
            print STDERR "EXCEPTION: riscdevice: $@";
        }
    }

    ## db_inventory has the hostdevice, which may be a deviceid
    ## if it is not a deviceid, it will be equal to the dboid
    dbg('db_inventory');
    my $dbhostupdate = $db->prepare(
'update db_inventory set hostdevice = ? where (dboid = ? and hostdevice = ?)'
    );
    my $dbinvQ = $db->prepare('select dboid,hostdevice from db_inventory');
    $dbinvQ->execute();
    while ( my $hd = $dbinvQ->fetchrow_hashref() ) {
        next
          if ( ( $hd->{'dboid'} eq $hd->{'hostdevice'} )
            or ( $skipids->{ $hd->{'hostdevice'} } ) );
        my $pre  = $hd->{'hostdevice'};
        my $post = remapping::xform_deviceid( $pre, $assessmentid );
        eval {
            $dbhostupdate->execute( $post, $hd->{'dboid'},
                $hd->{'hostdevice'} ) unless $pre == $post;
        };
        if ($@) {
            print STDERR "EXCEPTION: db_inventory: $@";
        }
    }
};
if ($@) {
    dbg("exception: $@");
    exit(1);
}

dbg('complete');
exit(0);

sub dbg {
    my ($msg) = @_;
    print STDERR "$0: $msg\n" if ($debugging);
}
