package utils1;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( invert_aoa print_hash print_aoa
highest_number get_list zip_lists p_tag);

sub invert_aoa{
use strict;
use warnings;
use 5.010;

my $a = shift;
my @AoA = @$a;
my $k = $#AoA;
#say "k is $k"; 
my @BoB;
    for my $i ( 0 .. $#AoA ) {
        my $aref = $AoA[$i];
        my $x = $#{$aref};
        #say "x is $x";
        for my $j ( 0 .. $#{$aref} ) {
            $BoB[$j][$i]= $AoA[$i][$j];
        }
    }
my $b = \@BoB;
return $b;
}
sub print_aoa{
use strict;
use warnings;
use 5.010;

my $a = shift;
my @AoA = @$a;
    for my $i ( 0 .. $#AoA ) {
        my $aref = $AoA[$i];
        for my $j ( 0 .. $#{$aref} ) {
            print "elt $i $j is $AoA[$i][$j]\n";
        }
    }
return $a;
}

sub highest_number{
use strict;
use File::Basename;
use Cwd;

my ($aref, $filetype, $word) = @_;
my $number;
my @matching;
my $ext = ".".$filetype;
push (@matching, 0); #min returned value
for my $file (@{$aref}) {
#print "file is $file\n";
if ($file =~ /^$word(\d*)$ext$/){
   #print "matching is $file\n";
   push (@matching, $1);
   }
}
@matching = sort @matching;
my $winner  = pop @matching;
return $winner  
}

sub print_hash{
   my $hash_ref = shift;
   print "subroutine says this is your hash: \n";
   my %hash = %$hash_ref;
   while ( (my $key,my $value) = each %hash )
   {
      print "key: $key, value: $hash{$key}\n";
   }
}

sub get_list{
use strict;
use warnings;
use 5.010;
use File::Slurp;

my $file = shift;
my @lines = read_file($file);
chomp(@lines); 
s/^\s+|\s+$//g for @lines;
@lines = grep length, @lines;
return @lines;
}

sub zip_lists  {
use strict;
use warnings;
use 5.010;
use List::MoreUtils qw( zip );

my ($file1, $file2) = @_;
my @file1lines = get_list($file1);
my @file2lines = get_list($file2);
say "keys are @file1lines";
say "values are @file2lines";
my %hash = zip @file1lines, @file2lines;
return \%hash;
}

sub p_tag  {
use strict;
use warnings;

my $text = shift;
my $before = '<p>';
my $after = '</p>';
my $return = $before.$text.$after;
return \$return;
}

1;

