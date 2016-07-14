#! /usr/bin/perl
use warnings;
use strict;
use 5.010;
use WWW::Mechanize::GZip;
use HTML::TableExtract qw(tree);
use open ':std', OUT => ':utf8';
use Prompt::Timeout;
use constant TIMEOUT  => 3;
use constant MAXTRIES => 16;

=head1 SYNOPSIS

You can't know where you are until you know when you are relative to it. It really can't get simpler than Einstein's 4-vectors for any real world problem. The assumption is that you have to figure out where you are by looking at the sky, yet somehow you have an ftp connection so that ephemeral data are available.

This program calculates the midpoint and duration of a conjunction, primitively. The duration output is completely wrong in the real world sense, but, along with mu, represented by the lexical "middle" value, provide a good first-order statistic on when a conjunction happens. 

The method is a numerical contraction.

Care is taken that the number of queries to our good friends at fourmilab is not a burden to their computational means.

=head1 VERSION

Version 0.01

=cut 

my $site = 'http://www.fourmilab.ch/yoursky/cities.html';
my $mech = 'WWW::Mechanize::GZip'->new;
$mech->get($site);
$mech->follow_link( text => 'Portland OR' );
my $lub = 2457204.63659;    #least upper bound
my $glb = 2457207.63659;    #greatest lower bound
my @right;
my @left;
my @julian;
$mech->set_fields(qw'date 2');
my $vstr  = 5;
my $jstr  = 3;
my $upper = $lub;
my $lower = $glb;
my $equal;
my $equal_sec;
my $now_string = localtime;
my $filename   = 'planet3.txt';
open( my $jh, '>>', $filename ) or die "Could not open file '$filename' $!";
say $jh "Script executed at $now_string";
say $jh join "\t", "venus", "jupiter", "julian date";
my $attempts = 1;

while ( ( $jstr != $vstr ) ) {

  my $default = ( ( $attempts >= MAXTRIES ) ) ? 'N' : 'Y';
  my $answer = prompt( "Make query number $attempts?", $default, TIMEOUT );
  exit if $answer =~ /^N/i;
  my $guess = median( $upper, $lower );
  say "guess is $guess";
  push @julian, $guess;
  $mech->set_fields( jd => $guess );
  $mech->click_button( value => "Update" );
  my $te = 'HTML::TableExtract'->new;
  $te->parse( $mech->content );
  my $table      = ( $te->tables )[3];
  my $table_tree = $table->tree;
  my $venus      = $table_tree->cell( 4, 1 )->as_text;
  my $jupiter    = $table_tree->cell( 7, 1 )->as_text;
  $vstr = string_to_second($venus);
  say "vstr is $vstr";
  push @right, $vstr;
  $jstr = string_to_second($jupiter);
  say "jstr is $jstr";
  push @left, $jstr;
  say $jh join "\t", $vstr, $jstr, $guess;

  if ( $jstr > $vstr ) {
    $upper = $guess;
  }
  elsif ( $vstr > $jstr ) {
    $lower = $guess;
  }
  else {
    $equal = $guess;
    say "equal, while condition should fail $equal";
    $equal_sec = $vstr;
  }
  $te->delete;
  $attempts++;
}
my $equal_ra = second_to_string($equal_sec);
say "equal_ra is $equal_ra";
say $jh "equal seconds is $equal_sec and equal ra is $equal_ra";
say "right is @right";
say "left is @left";
say "julian is @julian";

## Determine last best guess that was unequal
my $ind1 = get_index( \@right );
say "ind is $ind1";
say "v is $right[$ind1] and jul is $julian[$ind1]";
if ( $ind1 >= 0 ) {
  $upper = $julian[$ind1];
}
else {
  $upper = $lub;
}
say "upper is $upper";
$lower = $julian[-1];
say "lower is $lower";

## find upper bound of convergence range
$attempts = 1;
while ( ( abs( $upper - $lower ) > .000005 ) ) {

  my $default = ( ( $attempts >= MAXTRIES ) ) ? 'N' : 'Y';
  my $answer = prompt( "Make query number $attempts?", $default, TIMEOUT );
  exit if $answer =~ /^N/i;
  my $guess = median( $upper, $lower );
  say "guess is $guess";
  $mech->set_fields( jd => $guess );
  $mech->click_button( value => "Update" );
  my $te = 'HTML::TableExtract'->new;
  $te->parse( $mech->content );
  my $table      = ( $te->tables )[3];
  my $table_tree = $table->tree;
  my $venus      = $table_tree->cell( 4, 1 )->as_text;
  my $jupiter    = $table_tree->cell( 7, 1 )->as_text;
  $vstr = string_to_second($venus);
  say "vstr is $vstr";
  $jstr = string_to_second($jupiter);
  say "jstr is $jstr";
  say $jh join "\t", $vstr, $jstr, $guess;
  if ( $vstr > $jstr ) {
    $upper = $guess;
  }
  elsif ( $vstr == $jstr ) {
    $lower = $guess;
  }
  else {
    die "retrograde motion or bad data";
  }
  $te->delete;
  $attempts++;
}
say "after upper contraction, upper is $upper";
say "after upper contraction, lower is $lower";
my $end_time = $lower;
say $jh join "\t", $upper, $end_time;

## Determine last best guess that was unequal
$ind1 = low_index( \@left );
say "ind is $ind1";
say "v is $left[$ind1] and jul is $julian[$ind1]";
if ( $ind1 >= 0 ) {
  $upper = $julian[$ind1];
}
else {
  $upper = $glb;
}
say "left is @left";
say "julian is @julian";
say "upper is $upper";
$lower = $julian[-1];
say "lower is $lower";
## find beginning  bound of convergence range
$attempts = 1;
while ( ( abs( $upper - $lower ) > .000005 ) ) {

  my $default = ( ( $attempts >= MAXTRIES ) ) ? 'N' : 'Y';
  my $answer = prompt( "Make query number $attempts?", $default, TIMEOUT );
  exit if $answer =~ /^N/i;
  my $guess = median( $upper, $lower );
  say "guess is $guess";
  $mech->set_fields( jd => $guess );
  $mech->click_button( value => "Update" );
  my $te = 'HTML::TableExtract'->new;
  $te->parse( $mech->content );
  my $table      = ( $te->tables )[3];
  my $table_tree = $table->tree;
  my $venus      = $table_tree->cell( 4, 1 )->as_text;
  my $jupiter    = $table_tree->cell( 7, 1 )->as_text;
  $vstr = string_to_second($venus);
  say "vstr is $vstr";
  $jstr = string_to_second($jupiter);
  say "jstr is $jstr";
  say $jh join "\t", $vstr, $jstr, $guess;
  if ( $vstr < $jstr ) {
    $upper = $guess;
  }
  elsif ( $vstr == $jstr ) {
    $lower = $guess;
  }
  else {
    die "retrograde motion or bad data";
  }
  $te->delete;
  $attempts++;
}
say "after begin contraction, upper is $upper";
say "after begin contraction, lower is $lower";
my $begin_time = $upper;
say $jh join "\t", $lower, $begin_time;
my $middle = median($begin_time, $end_time);
say "middle is $middle";
my $duration = $end_time-$begin_time;
say "duration is $duration";
say $jh "middle: $middle\t duration: $duration";

sub median {
  my ( $up, $low ) = @_;
  my $return = ( $up + $low ) / 2.0;
  return $return;
}

sub string_to_second {
  my $string = shift;
  my $return = 9000;
  if ( my $success = $string =~ /^(\d*)h\s+(\d*)m\s+(\d*)s$/ ) {
    $return = 3600 * $1 + 60 * $2 + $3;
  }
  else {
    say "string was misformed";
  }
  return $return;
}

sub second_to_string {
  my $seconds   = shift;
  my $hours     = int( $seconds / 3600 );
  my $remainder = $seconds % 3600;
  my $minutes   = int( $remainder / 60 );
  my $sec       = $remainder % 60;
  my $return    = join '', $hours, 'h ', $minutes, 'm ', $sec, 's';
  return $return;
}

sub get_index {
  my ($ref_right) = shift;
  my @right       = @$ref_right;
  my $return      = -1;
  my $eq          = $right[-1];
  say "right is @right";
  say "eq is $eq";
  for my $i ( 0 .. $#right ) {
    if ( $right[$i] <= $eq ) {
      next;
    }
    else {
      $return = $i;
      say "i is $i";
    }
  }
  say "right is @right";
  return $return;
}

sub low_index {
  my ($ref_right) = shift;
  my @right       = @$ref_right;
  my $return      = -1;
  my $eq          = $right[-1];
  say "right is @right";
  say "eq is $eq";
  for my $i ( 0 .. $#right ) {
    if ( $right[$i] >= $eq ) {
      next;
    }
    else {
      $return = $i;
      say "i is $i";
    }
  }
  say "right is @right";
  return $return;
}


