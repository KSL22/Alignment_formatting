#!/usr/bin/perl

# this appends the non gap character length of each sequence to the sequence name

use warnings;
use strict;

die "usage: $0 file.fasta\n" unless $ARGV[0];

open A, shift;

my( $i, $id, @ids, %seq, @seqNames );
my $max_name_length = 0;
my $name_alignment_gap = 4;
my $num = 0;

# read in file
while (<A>){
  chomp;
  if( /^>(.*)/ ){
    $num++;
    $id = $1;
    push @ids, $id;
    length $id > $max_name_length and $max_name_length = length $id;
  }else{
    $seq{$id} .= $_;
  }
}

#format names, so they have the proper number of spaces after each one
for( $i = 0; $i < @ids; $i++ ){
  my $numSpaces = $max_name_length - (length $ids[$i]) + $name_alignment_gap;
  my $spaces = ' ' x $numSpaces;
  $seqNames[$i] = $ids[$i];
  $seqNames[$i] .= $spaces;
}

my( $seq, $len, $matrix );
$len = length $seq{$ids[0]};

print "$num $len\n";

for( $i = 0; $i < @ids; $i++ ){
  print $seqNames[$i];
  print $seq{$ids[$i]};
  $i <= $#ids and print "\n";
}

exit;
