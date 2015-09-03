#!/usr/bin/perl

use strict;
use warnings;

my $usage = "$0 input.nex\n";
$ARGV[0] or die $usage;


#parse file
open( FILE, $ARGV[0] ) || die "Can't open $ARGV[0]: $!\n";
while( my $file_line = <FILE> ){
  if( $file_line =~ /charset/i ){
    parse_charset( $file_line );
    while( my $char_line = <FILE> ){
      $char_line =~ /;/ and last;
      parse_charset( $char_line );
    }
  }
}

close FILE;

exit;

############################################SUBROUTINES#############################################
sub parse_charset{

  my $line = shift;
  
  $line =~ s/- /-/g;
  $line =~ s/ -/-/g;
  
  my @chars = split( /\s+/, $line );
  
  print $line;
  foreach my $range ( @chars ){
    $range =~ /[a-zA-Z]/ and next; # skip if letters
    $range =~ /[\[\]]/   and next; # skip if brackets
    $range =~ /^$/       and next; # skip if blank line
    $range =~ /=/        and next; # skip if equal sign
    
    # character range, not a single position
    if( $range =~ /-/ ){
      $range =~ s/\s//g; #get rid of whitespace
      $range =~ s/;//g;  #get rid of any semicolons, leaving just the coord
      print $range, "\n";
      
      # else no dash, so it's a single site, not a range
    }else{
      $range =~ s/\s+//g;  #get rid of whitespace
      $range =~ s/;//;     #get rid of any semicolons, leaving just the coord
      print "$range\-$range\n";
    }
  }

  
}
####################################################################################################
