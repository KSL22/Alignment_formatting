#!/usr/bin/perl

use strict;
use warnings;


my $usage = "$0 alignment.nex sequence.fasta\n";
print $usage and exit unless $ARGV[0];

my $nex   = shift @ARGV;
my $fasta = shift @ARGV;
my( $ntax, $nchar, %sequences, @ids, @fas, $i, $id );
my $max_name_length = 0;

#parse Nexus file
open( NEX, $nex ) || die "Can't open $nex: $!\n";
while( <NEX> ){
  if( /Dimensions\s+ntax=(\d+)\s+nchar=(\d+)/i ){
    $ntax = $1 and $nchar = $2;
    next;
  }elsif( /MATRIX/i ){
    while( <NEX> ){
      last if /;/;
      if( /(.*)\s+(\S{$nchar})/ ){
	my $id  = $1;
	my $seq = $2;
	
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

close NEX;
 

#parse FASTA file

open( A, $fasta ) || die "Can't open $fasta: $!\n";
while( <A> ){
  chomp;
  if( /^>(.*)/ ){
    $ntax++;
    $id = $1;
    push @ids, $id;
    push @fas, $id;
    length $id > $max_name_length and $max_name_length = length $id;
  }else{
    $sequences{$id} .= $_;
  }
}
close A;


for( $i = 0; $i < @fas; $i++ ){
  if( length( $sequences{$fas[$i]} ) < $nchar ){
    my $n_terminal_dashes = $nchar - (length $sequences{$fas[$i]});
    my $d = "\-" x $n_terminal_dashes;
    $sequences{$fas[$i]} .= $d;
  }
}


print
"#NEXUS

BEGIN DATA;
  DIMENSIONS NTAX=$ntax NCHAR=$nchar;
  FORMAT DATATYPE=DNA MISSING=\? GAP=- ;

MATRIX

";

#format names, so they have the proper number of spaces after each one
for( $i = 0; $i < @ids; $i++ ){
  my $numSpaces = $max_name_length - (length $ids[$i]) + 3;
  my $spaces = ' ' x $numSpaces;
  print $ids[$i], $spaces, $sequences{$ids[$i]}, "\n";
}


print ";\n";
print "END;\n";

my $first  = $nchar - 2;
my $second = $nchar - 1;

print
"BEGIN CODONS;
	CODONPOSSET * CodonPositions = 
		1: 1\-$first\\3, 
		2: 2\-$second\\3, 
		3: 3\-$nchar\\3 $nchar;
	CODESET  * UNTITLED = Universal: all ;
END;
";

print
"BEGIN MacClade;
	Version 4.0  86;
	LastModified -929730803;
	FileSettings editor  '0' '0' '1' '1';
	Singles 100;
	Editor 00011001111111100100010010 '4' '12' Geneva '9' '100' '1' all;
	EditorPosition  '46' '6' '643' '1323';
	TreeWindowPosition  '46' '6' '831' '1390';
	ListWindow Characters closed Geneva '9' '50' '10' '129' '406' 000;
	ListWindow Taxa closed Geneva '9' '50' '10' '129' '354' 1000000;
	ListWindow Trees closed Geneva '9' '50' '10' '129' '379' ;
	ListWindow TypeSets closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow WtSets closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow ExSets closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow CharSets closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow TaxSets closed Geneva '9' '50' '10' '129' '177' ;
	ListWindow CharPartitions closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow CharPartNames closed Geneva '9' '50' '10' '276' '490' ;
	ListWindow WtSets closed Geneva '9' '50' '10' '276' '490' ;
	ChartWindowPosition  '52' '30' '818' '1380';
	StateNamesSymbols closed Geneva '9' '10' '50' '30' '148' '220';
	WindowOrder  Data;
	OtherSymbols &/ 00 ?-;
	Correlation  '0' '0' '1000' '0' '0' 10011010;
	Salmo 00000001;
	EditorFile  '2';
	ExportHTML _ MOSS  '100' 110000;
	PrettyPrint 10;
	EditorToolsPosition  '531' '46' '115' '165';
	TreeWindowProgram 10;
	TreeWindow 0000;
	Continuous  '0' '3' 1;
	Calculations 0000001;
	SummaryMode  '0' '0' 0;
	Charts  Geneva '9' (normal) 0010;
	NexusOptions  '0' '0' '50' 001011001;
	TipLabel  '1';
	TreeFont  Geneva '9' (normal);
	TreeShape  1.0 1.0 0100;
	TraceLabels 0101;
	ChartColors  '0' '0' '65535' '9' '0' 1;
	ChartBiggestSpot 1;
	ChartPercent 10;
	ChartBarWidth  '10' 1;
	ChartVerticalAxis 10101;
	ChartMinMax  '0';
	TraceAllChangesDisplay  '1' 1;
	BarsOnBranchesDisplay  '0' '0' '60000' '10000' '10000' '10000' '10000' '60000' '65000' '65000' '65000' '6' '1' 0000101;
	ContinuousBranchLabels 0;
	AllStatesBranchLabels 1;
	IndexNotation  '2' 1;
	PrintTree  10.00 '2' '2' '2' '2' '2' '2' '2' '2' '2' '2' '2' Geneva '9' (normal) Geneva '10' (normal) Geneva '9' (normal) Geneva '9' (normal) Geneva '9' (bold ) Geneva '9' (normal) Geneva '9' (normal) '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '1' '1' '1' '1' '1' '5527' '-39' '4' '-40' '0' '1' '2' '1' '8' '0' '0' '0' '2' 1000111000000000000100000111000;
	MatchChar 00 .;
	EntryInterpretation 01;
	ColorOptions 00;
	TreeTools  '0' '5' '4' '0' '10' '4' '0' 00100111111101110;
	EditorTools  '0' '0' '0' '1000' '0' '0' '6' '3' '0' 100000101110001;
	PairAlign  '2' '2' '3' '2' '1' '1' '2' '1' '3' 1010;
	BothTools  '1';
END;
";

exit;
