#!/usr/bin/perl

use strict;
use warnings;


my $usage = "$0 alignment.nex\n";
print $usage and exit unless $ARGV[0];

nexus2phylip( shift @ARGV );

####################################################################################################
sub nexus2phylip{
  my $INFILE = shift;
  my( $ntax, $nchar, %sequences, @ids, $i );
  my $max_name_length = 0;

  #parse Nexus file

  my $stringLen; 

  open( FILE, $INFILE ) || die "Can't open $INFILE: $!\n";
  while( <FILE> ){
    /ntax=(\d+)/i  and $ntax  = $1;
    /nchar=(\d+)/i and $nchar = $1;
    
    if( /^\s*MATRIX/i ){
      while( <FILE> ){
	/^\s*\[/ and next; # skip commented lines
	/;/      and last; # end at semicolon (end of the matrix)

	if( /^.*\s+(\S+)/ ){
	  $_ =~ s/^\s+//; #get rid of leading whitespace
	  my @tmp = split /\s+/, $_;
	  my $id  = $tmp[0];
	  my $seq = $tmp[1];
	  
	  # for( my $i = 0; $i < @tmp; $i++ ){
	  #   print "$i = $tmp[$i]\n";
	  # }
	  
	  $id =~ s/\s//g;
	  push @ids, $id;
	  length $id > $max_name_length and $max_name_length = length $id;

	  $sequences{$id} = $seq;
	}else{
	  next;
	}
      }
    }elsif(/BEGIN PAUP/ || /BEGIN CODONS/){
      last;
    }
  }

  close FILE;

  print "$ntax $nchar\n";
    
  #format names, so they have the proper number of spaces after each one
  for( $i = 0; $i < @ids; $i++ ){
    my $numSpaces = $max_name_length - (length $ids[$i]) + 3;
    my $spaces = ' ' x $numSpaces;
    print $ids[$i], $spaces, $sequences{$ids[$i]}, "\n";
  }

}
####################################################################################################
