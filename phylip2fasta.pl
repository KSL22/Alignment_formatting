#!/usr/bin/perl

use warnings;
use strict;

die "usage: $0 file.phylip\n" unless $ARGV[0];

open A, shift;

# read in file
while( <A> ){
  /^$/                and next;
  /^#/                and next;
  /^\s*(\d+)\s+(\d+)/ and next;

  my @line = split /\s+/;

  print ">", $line[0], "\n";
  print $line[1], "\n";
  
}
close A;

exit;

