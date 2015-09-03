#!/usr/bin/perl

use strict;
use warnings;


my $usage = "$0 alignment.nex name1 name2 . . . \n";
print $usage and exit unless $ARGV[0];

my $nex   = shift @ARGV;
my @names = @ARGV;
my( $ntax, $nchar, %sequences, @ids, $i, $id );
my $max_name_length = 0;

#parse Nexus file
open( NEX, $nex ) || die "Can't open $nex: $!\n";
while( <NEX> ){
  if( /Dimensions\s+ntax=(\d+)\s+nchar=(\d+)/i ){
    $ntax = $1 and $nchar = $2;
  }elsif( /MATRIX/ ){
    while( <NEX> ){
      /;/ and last;
      if( /(.*)\s+(\S{$nchar})/ ){
	# print;
	my $id  = $1;
	my $seq = $2;
	
	$id =~ s/\s//g;
	push @ids, $id;
	length $id > $max_name_length and $max_name_length = length $id;
	$sequences{$id} = $seq;

      }
    }
  }
}
close NEX;


for( $i = 0; $i < @names; $i++ ){
  $sequences{$names[$i]} = "\-" x $nchar;
}

$ntax += scalar @names;



print
"#NEXUS

BEGIN DATA;
  DIMENSIONS NTAX=$ntax NCHAR=$nchar;
  FORMAT DATATYPE=DNA MISSING=\? GAP=- ;

MATRIX

";

push @ids, @names;

#format names, so they have the proper number of spaces after each one
for( $i = 0; $i < @ids; $i++ ){
  my $numSpaces = $max_name_length - (length $ids[$i]) + 3;
  my $spaces = ' ' x $numSpaces;
  print $ids[$i], $spaces, $sequences{$ids[$i]}, "\n";
}

print ";\n\n";
print "END;\n";

# print everything after the matrix
open( NEX, $nex ) || die "Can't open $nex: $!\n";
while( <NEX> ){
  if( /end;/i ){
    while( <NEX> ){
      print;
    }
  }
}
close NEX;

exit;
