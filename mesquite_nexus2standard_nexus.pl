#!/usr/bin/perl

use strict;
use warnings;


my $usage = "$0 alignment.nex\n";
print $usage and exit unless $ARGV[0];

my $INFILE = $ARGV[0];
my( $ntax, $nchar, %out, @lengths );

# Begin printing Nexus header
print "#NEXUS\n\n";
print "BEGIN DATA;\n";
print "\tDimensions ";

# Begin parsing Mesquite-formatted Nexus file
open( FILE, $INFILE ) || die "Can't open $INFILE: $!\n";
while( <FILE> ){
  /Title/i and next;
  if( /ntax=(\d+)/i ){
    print "ntax=$1 ";
  }elsif( /nchar=(\d+)/i ){
    print "nchar=$1\;\n";
  }elsif( /FORMAT/ ){
    print $_, "\n";
  }elsif( /MATRIX/ ){
    $_ =~ s/^\s+//;
    print $_, "\n";
    while( <FILE> ){
      print;
    }
  }
}
close FILE;

exit;
