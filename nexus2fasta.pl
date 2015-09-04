#!/usr/bin/perl

use strict;
use warnings;


my $usage = "$0 alignment.nex\n";
print $usage and exit unless $ARGV[0];

my $file = $ARGV[0];
nexus2fasta( $file );

####################################################################################################
sub nexus2fasta{
  my $INFILE = shift;
  my( $ntax, $nchar, %out, @lengths );
  
  #parse Nexus file
  open( FILE, $INFILE ) || die "Can't open $INFILE: $!\n";
  while( <FILE> ){
    if( /Dimensions\s+ntax=(\d+)\s+nchar=(\d+)/i ){
      $ntax = $1 and $nchar = $2;
      next;
    }elsif( /MATRIX/i ){
      while( <FILE> ){
	last if /;/;
	if( /(.*)\s+(\S{$nchar})/ ){
	  my $taxon = $1;
	  my $seq = $2;
	  $taxon =~ s/\s//g;
	  print ">$taxon\n$seq\n";
	}else{
	  next;
	}
      }
    }elsif(/BEGIN PAUP/ || /BEGIN CODONS/){
      last;
    }
  }
  close FILE;
  
}
####################################################################################################
