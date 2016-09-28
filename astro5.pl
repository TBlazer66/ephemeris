#!/usr/bin/perl
use warnings;
use strict;
use 5.010;

use Astro::Utils;
use DateTime;
use DateTime::Event::Sunrise;
use DateTime::Format::Strptime;
use DateTime::Format::Human::Duration;

my $LONG = -122.5;                  # E = +, W = -
my $LAT  = 45;                      # N = +, S = -
my $ZONE = 'America/Los_Angeles';

for my $sun_height ( 0, -0.833, -6, -12, -18 ) {

   my $sun = DateTime::Event::Sunrise->new(
      precise   => 1,
      longitude => $LONG,
      latitude  => $LAT,
      altitude  => $sun_height
   );
   say "sun height is $sun_height";
   my $strp = DateTime::Format::Strptime->new(
      pattern   => '%Y-%m-%d %H:%M:%S',
      time_zone => 'UTC',
      on_error  => 'croak'
   );
   my $durfmt = DateTime::Format::Human::Duration->new();

   print "At "
     . abs($LAT)
     . ( $LAT > 0 ? "N" : "S" ) . " "
     . abs($LONG)
     . ( $LONG > 0 ? "E" : "W" ) . ":\n";
   my $now_year = DateTime->now->year;
   for my $year ($now_year) {
      print " In $year:\n";
      my @seas = (
         [
            'Spring', 'March equinox', calculate_equinox( 'mar', 'utc', $year )
         ],
         [
            'Summer',
            'June solstice',
            calculate_solstice( 'jun', 'utc', $year )
         ],
         [
            'Fall',
            'September equinox',
            calculate_equinox( 'sep', 'utc', $year )
         ],
         [
            'Winter',
            'December solstice',
            calculate_solstice( 'dec', 'utc', $year )
         ],
      );
      for my $seas (@seas) {
         my ( $sname, $when, $start ) = @$seas;
         $start = $strp->parse_datetime($start);
         $start->set_time_zone($ZONE);
         my $rise = $sun->sunrise_datetime($start);
         my $set  = $sun->sunset_datetime($start);
         my $dur  = $durfmt->format_duration_between( $rise, $set );
         print "  $sname begins on the $when at ",
           $start->strftime('%Y-%m-%d %H:%M:%S %Z'), ".\n";
         print "   Sunrise is at ", $rise->strftime('%H:%M:%S %Z'),
           ", sunset is at ", $set->strftime('%H:%M:%S %Z'), ",\n";
         print "   and the day is $dur long.\n";
      }
   }

}

