#!/usr/bin/perl

use strict;
use warnings;

my $usage = "$0 input.nex\n";
$ARGV[0] or die $usage;


#parse file
open( FILE, $ARGV[0] ) || die "Can't open $ARGV[0]: $!\n";
while( my $file_line = <FILE> ){
  
  if( $file_line =~ /charset/i ){
    while( my $char_line = <FILE> ){
      # print $char_line;
      $char_line =~ s/- /-/g;
      $char_line =~ s/ -/-/g;
    
      my @chars = split( /\s+/, $char_line );

      foreach my $range ( @chars ){
	$range =~ /[a-zA-Z]/ and next; # skip if letters
	$range =~ /[\[\]]/ and next;   # skip if brackets
	$range =~ /^$/ and next;       # skip if blank line
	$range =~ /=/ and next;        # skip if equal sign
	
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
      $char_line =~ /;/ and last;
    }
  }
}


close FILE;


exit;

