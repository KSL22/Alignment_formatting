#!/usr/bin/perl

use warnings;
use strict;

die "usage: $0 file.phylip\n" unless $ARGV[0];

open A, shift;

my( $i, $ntax, $nchar, @ids, %sequences, @seqNames );
my $max_name_length = 0;

# read in file
while( <A> ){
  /^$/ and next;
  /^#/ and next;
  
  if( /^\s*(\d+)\s+(\d+)/ ){
    $ntax  = $1;
    $nchar = $2;
  }else{
    my @line = split /\s+/;
    # print $line[0], "\n";
    # print $line[1], "\n";
    push @ids, $line[0];
    length $line[0] > $max_name_length and $max_name_length = length $line[0];
    $sequences{$line[0]} = $line[1];
  }
  
}

#print Nexus header
print
"#NEXUS

BEGIN DATA;
  DIMENSIONS NTAX=$ntax NCHAR=$nchar;
  FORMAT DATATYPE=DNA MISSING=\? GAP=-;

MATRIX

";

#format names, so they have the proper number of spaces after each one
for( $i = 0; $i < @ids; $i++ ){
  my $numSpaces  = $max_name_length - (length $ids[$i]) + 3;
  my $spaces     = ' ' x $numSpaces;
  print $ids[$i], $spaces, $sequences{$ids[$i]}, "\n";
}

print ";\n\nEND;\n";

exit;

