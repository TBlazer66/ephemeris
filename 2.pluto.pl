#! /usr/bin/perl
use warnings;
use strict;
use 5.010;
use WWW::Mechanize::GZip;
use HTML::TableExtract qw(tree);
use open ':std', OUT => ':utf8';
use Prompt::Timeout;
use constant TIMEOUT  => 3;
use constant MAXTRIES => 30;

## redesign for solar eclipse of aug 21, 2017

my $site = 'http://www.fourmilab.ch/yoursky/cities.html';
my $mech = 'WWW::Mechanize::GZip'->new;
$mech->get($site);
$mech->follow_link( text => 'Portland OR' );
my $before_bound = 2457987.04167;    #before conjunction
my $after_bound  = 2457988.0;        #after conjunction
$mech->set_fields(qw'date 2');
my $moon_seconds = 5;
my $sun_seconds  = 3;
my $upper        = $after_bound;
my $lower        = $before_bound;
my $equal;
my $equal_sec;
my $now_string = localtime;
my $filename   = '2.pluto.txt';
open( my $jh, '>>', $filename ) or die "Could not open file '$filename' $!";
say $jh "Script executed at $now_string";
say $jh "       attempt  upper  lower  guess";
my $attempts = 1;

while ( ( $sun_seconds != $moon_seconds ) ) {

    my $default = ( ( $attempts >= MAXTRIES ) ) ? 'N' : 'Y';
    my $answer = prompt( "Make query number $attempts?", $default, TIMEOUT );
    exit if $answer =~ /^N/i;

    my $guess = closetohalf( $upper, $lower );
    say "to server is $attempts $upper $lower $guess ";
    say $jh "to server is $attempts $upper $lower $guess ";
    $mech->set_fields( jd => $guess );
    $mech->click_button( value => "Update" );
    my $te = 'HTML::TableExtract'->new;
    $te->parse( $mech->content );
    my $table      = ( $te->tables )[3];
    my $table_tree = $table->tree;
    my $moon       = $table_tree->cell( 5, 1 )->as_text;
    say "right ascension of moon $moon";
    say $jh "right ascension of moon $moon";
    my $sun = $table_tree->cell( 2, 1 )->as_text;
    say "right ascension of sun $sun";
    say $jh "right ascension of sun $sun";
    $moon_seconds = string_to_second($moon);
    say "moon seconds is $moon_seconds";
    say $jh "moon seconds is $moon_seconds";
    $sun_seconds = string_to_second($sun);
    say "sun seconds is $sun_seconds";
    say $jh "sun seconds is $sun_seconds";

    if ( $sun_seconds < $moon_seconds ) {
        $upper = $guess;
    }
    elsif ( $moon_seconds < $sun_seconds ) {
        $lower = $guess;
    }
    else {
        $equal = $guess;
        say "equal, while condition fails at julian day $equal";
        say $jh "equal, while condition fails at julian day $equal";
        $equal_sec = $moon_seconds;
    }
    $te->delete;
    $attempts++;
}

say $jh "equal seconds is $equal_sec";

# re-design 4-29-17 for solar eclipse

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

sub closetohalf {
    my ( $up, $low ) = @_;
    $low + ( $up - $low ) * ( 0.4 + rand 0.2 );
}

