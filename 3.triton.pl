use warnings;
use strict;
use 5.010;
use WWW::Mechanize::GZip;
use HTML::TableExtract;
use Prompt::Timeout;
use open ':std', OUT => ':utf8';
use constant TIMEOUT  => 3;
use constant MAXTRIES => 30;

## redesign for solar eclipse of aug 21, 2017
# declarations, initializations to precede main control
my ( $moon_seconds, $sun_seconds, $equal_sec, $equal );

# set time boundaries
my ( $before_bound, $after_bound ) = ( 2457987.04167, 2457988.0 );

# hard code 2 objects to look at (rows)
my $e1 = 5;    #moon
my $e2 = 2;    #sun

# hard code column
my $column     = 1;                 #right ascension
my $filename   = '3.triton.txt';    #output file
my $now_string = localtime;
open( my $jh, '>>', $filename ) or die "Could not open file '$filename' $!";
say $jh "Script executed at $now_string";
my $attempts = 1;
my ( $lower, $upper ) = ( $before_bound, $after_bound );
my $site = 'http://www.fourmilab.ch/yoursky/cities.html';
my $mech = 'WWW::Mechanize::GZip'->new;
$mech->get($site);
$mech->follow_link( text => 'Portland OR' );
$mech->set_fields(qw'date 2');      #julian date specified

# determine equality by contracting stochastically

while ( ( ( $attempts == 1 ) || ( $sun_seconds != $moon_seconds ) ) ) {

    my $default = ( ( $attempts >= MAXTRIES ) ) ? 'N' : 'Y';
    my $answer = prompt( "Make query number $attempts?", $default, TIMEOUT );
    exit if $answer =~ /^N/i;

    my $guess = closetohalf( $upper, $lower );
    $mech->set_fields( jd => $guess );
    $mech->click_button( value => "Update" );
    my $te = 'HTML::TableExtract'->new;
    $te->parse( $mech->content );
    my $table = ( $te->tables )[3];    #ephemeris table

    # looking to get the whole row

    my $row_ref1 = $table->row($e1);
    my @row1     = @$row_ref1;
    my $row_ref2 = $table->row($e2);
    my @row2     = @$row_ref2;
    my $moon     = $row1[$column];
    my $sun      = $row2[$column];

    $moon_seconds = string_to_second($moon);
    $sun_seconds  = string_to_second($sun);

    if ( $sun_seconds < $moon_seconds ) {
        $upper = $guess;
    }
    elsif ( $moon_seconds < $sun_seconds ) {
        $lower = $guess;
    }
    else {
        $equal = $guess;
        say $jh "equal, while condition fails at julian second $equal";
        $equal_sec = $moon_seconds;
    }
    say $jh "$attempts @row1";
    say $jh "$attempts @row2";
    $attempts++;
}

say $jh "equal seconds is $equal";
my $from_c = pass_to_c($equal);
say "from c is $from_c";

sub string_to_second {
    my $string = shift;
    my $return;

    if ( my $success = $string =~ /^(\d*)h\s+(\d*)m\s+(\d*)s$/ ) {
        $return = 3600 * $1 + 60 * $2 + $3;
    }
    else {
    }
    return $return;
}

sub pass_to_c {
    my $string = shift;
    my $string_from_c;
    $string_from_c = system "./orange $string";
    return $string_from_c;
}

sub closetohalf {
    my ( $up, $low ) = @_;
    $low + ( $up - $low ) * ( 0.4 + rand 0.2 );
}

