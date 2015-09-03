#!/usr/bin/perl

use strict;
use warnings;

my $usage = "$0 input.nex\n";
$ARGV[0] or die $usage;


#parse file
open( FILE, $ARGV[0] ) || die "Can't open $ARGV[0]: $!\n";
while( my $line = <FILE> ){
  
  $line =~ s/- /-/g;
  $line =~ s/ -/-/g;
    
  my @chars = split( /\s+/, $line );

  foreach my $char ( @chars ){
    $char =~ /[a-zA-Z]/ and next;  # skip if letters
    $char =~ /[\[\]]/ and next;    # skip if brackets
    $char =~ /^$/ and next;        # skip if blank line
    $char =~ /=/ and next;        # skip if equal sign

    # character range, not a single position
    if( $char =~ /-/ ){
      $char =~ s/\s//g; #get rid of whitespace
      $char =~ s/;//g;  #get rid of any semicolons, leaving just the coord
      print $char, "\n";

    # else no dash, so it's a single site, not a range
    }else{
      $char =~ s/\s+//g;  #get rid of whitespace
      $char =~ s/;//;     #get rid of any semicolons, leaving just the coord
      print "$char\-$char\n";

    }
  }
  
}


close FILE;


exit;

