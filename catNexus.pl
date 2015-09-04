#!/usr/bin/perl


use strict;
use warnings;
use Getopt::Long;

our $OUTGROUP;
our $FILE_EXTENSION = "nex";
our $HELP;

parseArgs();


my %alignLengths;
my %matrixCoords;
my %matrices;     # key = matrix ID (e.g., gene name); value = array, each element a sequence (with name) from the matrix
my @taxa;         # 2D array; num elements = num matrices; each element (gene), 0 = gene name and 1 = array of taxa
my @matrix_names; # name (filename minus extension) of each matrix, to preserve matrix order
my %charsets;     # holds charsets read in from original nexus files
my %gene_starts;  # start coordinate foreach gene in the new, concatenated matrix
my @taxon_order;  # array of taxa, ordered according to the first file read from the directory
my $matrix;       # holds the concatenated matrix
my $format_line;
my $numtax;
my $matrix_counter = 0;

chomp( my $directory = `pwd` );

opendir( DIR, $directory ) || die "Cannot open $directory, assface: $!\n";
my @nexFiles = readdir( DIR );
closedir DIR;

foreach my $file ( @nexFiles ){
  $file =~ /(.+)\.$FILE_EXTENSION$/ or next;

  $matrix_counter++;
  my $filename = $1;
  push @matrix_names, $filename;
  
  #parse Nexus file
  open( FILE, $file ) || die "Can't open $file: $!\n";
  while( <FILE> ){
    my $nchar;

    #---------------READ CHARSETS
    #new charset, all coords on one line b/c line ends with semicolon
    if( /(charset\s+(\S+)\s*=\s*(.+));/i ){
      my $charset_name = $2;
      my $chars = $3;
      $chars =~ s/- /-/g;
      $chars =~ s/ -/-/g;

      # print $chars . "\n";

      #splits up 1) multiple ranges on same line or 2) single range with spaces around dash
      my @chars = split( /\s+/, $chars );
      foreach my $range ( @chars ){
	if( $range =~ /-/ ){  # character range, not a single position
	  $range =~ s/\s//g;  # get rid of whitespace
	  $range =~ s/;//;    # get rid of any semicolons, leaving just the coord
	  push( @{$charsets{$filename}{$charset_name}}, $range );

        # else no dash, so it's a single site, not a range
	}else{ 	              
	  $range =~ s/\s//g;  # get rid of whitespace
	  $range =~ s/;//;    # get rid of any semicolons, leaving just the coord
	  push( @{$charsets{$filename}{$charset_name}}, $range );
	}
      }

    #---------------READ NCHAR
    }elsif( /NCHAR=(\d+)/i ){
      $nchar = $1;
      $alignLengths{$filename} = $nchar;

    #---------------READ DATATYPE
    }elsif( /DATATYPE/i ){
      $format_line or $format_line = $_;
      $format_line =~ s/^\s+//;
      $format_line =~ s/;\n//;

    #---------------READ MATRIX
    }elsif( /MATRIX/i ){
      while ( my $matrix_line = <FILE> ){
      	$matrix_line =~ /;/  and last; # exit loop at end of matrix
      	$matrix_line =~ /^$/ and next; # skip blank lines
	$matrix_line =~ s/^\s+//;      # remove leading whitespace
	my ($id, $seq ) = split( /\s+/, $matrix_line );     # split sequence and sequence ID
	$matrix_counter == 1 and push( @taxon_order, $id ); # for the first matrix, create an ordered list of taxa
	$matrices{$filename}{$id} = $matrix_line;           # store the entire sequence line (ID and sequence)
	$taxa[$matrix_counter][0] = $filename;
	push @{$taxa[$matrix_counter][1]}, $id;
      }
    }
  }
  close FILE;
}

#---------------DONE READING MATRICES


#---------------MAKE SURE MATRICES ALL HAVE IDENTICAL SETS OF TAXA
check_taxa( \@taxa );


#---------------ASSEMBLE MATRICES
my $running_total; # cumulative number of characters in matrix
my $charset;

# for( my $i = 0; $i < @taxon_order; $i++ ){ # looping over array of taxa for the first matrix read from the directory (1-based numbering in @taxa)
#   print $i+1, "\t", $taxon_order[$i], "\n"
# }
# exit;

foreach my $matrix_name ( @matrix_names ){ # iterate over genes/matrices

  #--------------- 1 - ASSEMBLE CHARSETS
  if( defined $running_total ){
    my $line .= "\tcharset $matrix_name\t= ";
    $gene_starts{$matrix_name} = $running_total+1;
    $line .= $running_total+1;  # start coord of this gene in the concatenated matrix
    $line .= "\-";
    $line .= $running_total+$alignLengths{$matrix_name};  # end coord of this gene in the concatenated matrix
    $line .= ";\n";
    $charset .= $line;
    $running_total += $alignLengths{$matrix_name};
  }else{
    $charset .= "\tcharset $matrix_name\t= 1\-$alignLengths{$matrix_name};\n";
    $running_total = $alignLengths{$matrix_name};
    $gene_starts{$matrix_name} = 1;
  }
 

  #--------------- 2 - CALCULATE NUMBER OF TAXA IN MATRIX
  my $ntax = keys $matrices{$matrix_name};
  $numtax = $ntax; # doing this just to put some number in the format line for 'NTAX'

  #--------------- 3 - PRINT DATA MATRIX
  $matrix .= "\n\n[  $matrix_name, nchar=$alignLengths{$matrix_name}, ntax=$ntax  ]\n\n"; # print label for matrix

  # print data for this gene/matrix

  for( my $i = 0; $i < @taxon_order; $i++ ){ # looping over array of taxa for the first matrix read from the directory (1-based numbering in @taxa)
    $matrix .= $matrices{$matrix_name}{$taxon_order[$i]};
  }
}

# print NEXUS and DATA header
print "#NEXUS\n\n";
print "BEGIN DATA;\n";
print "\tDIMENSIONS NTAX=$numtax NCHAR=$running_total;\n";
print "\t$format_line INTERLEAVE;\n\n";
print "MATRIX";

# print matrix
print $matrix;

# print footers, PAUP block, charsets
print ";\nEND;\n\n";
print "BEGIN PAUP;\n\n";
print "\tSET increase=auto autoclose=yes notifybeep=no tcompress=yes torder=right showtaxnum=yes taxlabels=full warnreset=no warntree=no warnroot=no maxtrees=50000 outroot=mono;\n";
if( $OUTGROUP){
  print "\tOUTGROUP $OUTGROUP;\n\n";
}else{
  print "\n";
}

print $charset . "\n";

# print charsets that were in the original matrices
my $exclude_sets;
my $other_sets;
my $stop_sets;
my $edited_sets;

foreach my $gene( sort {lc($a) cmp lc($b)} keys %charsets ){             #foreach gene
  foreach my $set( sort {lc($a) cmp lc($b)} keys %{$charsets{$gene}} ){  #foreach charset per gene
    my $num = scalar @{$charsets{$gene}{$set}};  #number of coords in this array
    if( $set =~ /exclude/i ){
      $exclude_sets .= "                          ";
      for( my $i = 0; $i < $num; $i++ ){
	if( $charsets{$gene}{$set}->[$i] =~ /-/ ){
	  my @tmp = split( /-/, $charsets{$gene}{$set}->[$i] );
	  my $start = $gene_starts{$gene} + $tmp[0] - 1;
	  my $end   = $gene_starts{$gene} + $tmp[1] - 1;
	  $exclude_sets .= $start . "-" . $end . " ";
	}else{
	  $exclude_sets .= ($gene_starts{$gene} + $charsets{$gene}{$set}->[$i] - 1) . " ";
	}
      }
      $exclude_sets .= "[ $gene ]\n";
    }elsif( $set =~ /stop_codons/i ){
      $stop_sets .= "                              ";
      for( my $i = 0; $i < $num; $i++ ){
	if( $charsets{$gene}{$set}->[$i] =~ /-/ ){
	  my @tmp = split( /-/, $charsets{$gene}{$set}->[$i] );
	  my $start = $gene_starts{$gene} + $tmp[0] - 1;
	  my $end   = $gene_starts{$gene} + $tmp[1] - 1;
	  $stop_sets .= $start . "-" . $end . " ";
	}else{
	  $stop_sets .= ($gene_starts{$gene} + $charsets{$gene}{$set}->[$i] - 1) . " ";
	}
      }
      $stop_sets .= "[ $gene ]\n";
    }elsif( $set =~ /edited_codons/i ){
      $edited_sets .= "                                ";
      for( my $i = 0; $i < $num; $i++ ){
	if( $charsets{$gene}{$set}->[$i] =~ /-/ ){
	  my @tmp = split( /-/, $charsets{$gene}{$set}->[$i] );
	  my $start = $gene_starts{$gene} + $tmp[0] - 1;
	  my $end   = $gene_starts{$gene} + $tmp[1] - 1;
	  $edited_sets .= $start . "-" . $end . " ";
	}else{
	  $edited_sets .= ($gene_starts{$gene} + $charsets{$gene}{$set}->[$i] - 1) . " ";
	}
	$edited_sets .= "[ $gene ]\n";
      }
    }else{
      $other_sets .= "\tcharset $set\t= ";
      my $num = scalar @{$charsets{$gene}{$set}};
      for( my $i = 0; $i < $num; $i++ ){
	my @tmp = split( /-/, $charsets{$gene}{$set}->[$i] );
	my $start = $gene_starts{$gene} + $tmp[0] - 1;
	my $end   = $gene_starts{$gene} + $tmp[1] - 1;
	$other_sets .= $start . "-" . $end . " ";
      }
      chop $other_sets;
      $other_sets .= ";\t[ $gene ]\n";
    }
  }
}

if( $exclude_sets ){
  print "\tcharset exclude =\n";
  print $exclude_sets . "\t;\n\n";
}
if( $stop_sets ){
  print "\tcharset stop_codons =\n";
  print $stop_sets . "\t;\n\n";
}
if( $edited_sets ){
  print "\tcharset edited_codons =\n";
  print $edited_sets . "\t;\n\n" if defined $edited_sets;
}

print $other_sets if defined $other_sets;
if( $edited_sets && $stop_sets ){
  print "\tEXCLUDE stop_codons edited_codons;\n";
}elsif( $edited_sets ){
  print "\tEXCLUDE edited_codons;\n";
}elsif( $stop_sets ){
  print "\tEXCLUDE stop_codons;\n";
}

print "\nEND;\n";

exit;



############################################SUBROUTINES#############################################
sub check_taxa{
  my $taxaRef = shift;
  my( $i, $j, $k );
  #FORMAT AND PRINT OUTPUT; $i = 1 because I used 1-based numbering for tracking number of matrices
  for( $i = 1; $i < @$taxaRef; $i++ ){
    for( $j = $i+1; $j < @$taxaRef; $j++ ){
      
      #make sure matrices have the same number of taxa
      if( @{$taxaRef->[$i][1]} != @{$taxaRef->[$j][1]} ){
	print "Different numbers of taxa in matrices $taxaRef->[$i][0] and $taxaRef->[$j][0] - ";
	print "fix and try again.\n";
	exit;
      }
      
      @{$taxaRef->[$i][1]} = sort {$a cmp $b} @{$taxaRef->[$i][1]};
      @{$taxaRef->[$j][1]} = sort {$a cmp $b} @{$taxaRef->[$j][1]};
      
      for( $k = 0; $k < @{$taxaRef->[$i][1]}; $k++ ){
	if( $taxaRef->[$i][1][$k] ne $taxaRef->[$j][1][$k] ){
	  print "Different names and/or numbers of taxa in the following:\n";
	  print $i, " ", $taxaRef->[$i][0], " ", $taxaRef->[$i][1][$k], "\n";
	  print $i, " ", $taxaRef->[$j][0], " ", $taxaRef->[$j][1][$k], "\n";
	  exit;
	}
      }  
    }
  }
}
####################################################################################################
sub parseArgs{

  my $usage = "\nUsage: $0 [options]

Note: taxa need identical names between matrices but do not need to be in the same order; will carry over existing charsets, but charsets to be excluded should be in a charset called 'exclude' in the original files - these will be compiled into a single 'exclude' charset in the concatenated matrix; non-interleaved input matrices only

    options
          --file_extension - nexus file extension for files to be concatenated (default: nex)
          --outgroup - outgroup taxon/taxa for PAUP block; put multiple outgroups in quotes, e.g. 'o1 o2 o3'
          --help - print usage
\n\n";

	my $result = GetOptions
	(
		'file_extension=s' => \$FILE_EXTENSION,
		'outgroup=s'       => \$OUTGROUP,
                'help!'            => \$HELP
	);

	print $usage and exit if defined $HELP;
}
####################################################################################################

