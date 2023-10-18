#!/usr/bin/env perl
use strict ;
use warnings ;
use diagnostics ;
use utf8 ;
use feature ':5.38' ;

use Net::Prometheus ;
use POSIX      qw(strftime) ;
use Data::Dump qw(dump) ;
use Text::CSV  qw(csv) ;
use Schedule::Cron::Events ;

use Time::Piece ;
use Time::Seconds ;

use Mojo::UserAgent ;
use Mojolicious::Lite ;
plugin 'AutoReload' => {} ;

####################################################################################################

use constant {
  TRUE                    => 1,
  FALSE                   => 0,
  PLANNED_DOWNTIME_GSHEET =>
'https://docs.google.com/spreadsheets/d/1KS3pMzrkW4888LbtqoGR5xylLCfYfkeHrSyMHIIvAfg/export?exportFormat=csv',
  GSHEET_HEADER_ROWS => 12,
  TIMESTAMP_FORMAT   => '%Y-%m-%d %H:%M:%S'
} ;

####################################################################################################

local $ENV{TZ} = 'UTC' ;
our @now    = localtime () ;
our $now_ts = strftime ( '%Y-%m-%d %H:%M', @now ) . ':00' ;

####################################################################################################

our $prometheus                 = Net::Prometheus->new ;
our $prom_http_requests_counter = $prometheus->new_counter (
  name => 'planned_downtime_http_requests',
  help => 'Number of HTTP requests received'
) ;
our $prom_gsheet_download_error_counter = $prometheus->new_counter (
  name => 'planned_downtime_gsheet_download_errors',
  help => 'Number of errors downloading Google sheet.'
) ;

####################################################################################################

get '/metrics' => sub ( $c ) {
  $c->render ( text => $prometheus->render ) ;
} ;

####################################################################################################

get '/planned-downtime-in-progress.json' => sub ( $c ) {
  $prom_http_requests_counter->inc ;
  my $csv = download_gsheet () ;
  if ( $csv ) {
    my $instances = get_active_instances ( $csv ) ;
    $c->render ( json => { planned_downtime => $instances, status => 'success' } ) ;
  }
  else {
    $c->render ( json => { 'planned_downtime' => [], status => 'failed' } ) ;
  }
} ;

####################################################################################################

sub get_active_instances ( $csv ) {
  my $csv_rows         = load_csv ( $csv ) ;
  my $records          = process_rows ( $csv_rows ) ;
  my $active_records   = get_active_records ( $records, $now_ts ) ;
  my @active_instances = map { { lemmy_instance => $_->{instance} } } @$active_records ;
  return \@active_instances ;
}

####################################################################################################

sub load_csv ( $csv_text ) {
  my @raw_lines          = split ( /\r?\n/, $csv_text ) ;
  my $csv_text_no_header = join ( "\n", @raw_lines[ GSHEET_HEADER_ROWS .. $#raw_lines ] ) ;

  my $csv = Text::CSV->new ( { diag_verbose => 1 } ) ;
  $csv->column_names ( qw(instance single_ts recurring_cron duration matrix_user email) ) ;

  open ( my $sfh, '<', \$csv_text_no_header ) ;
  my $rows = $csv->getline_hr_all ( $sfh ) ;
  close ( $sfh ) ;
  return $rows ;
}

####################################################################################################

sub process_rows ( $csv_rows ) {
  my $result = [] ;
  foreach my $row ( @$csv_rows ) {
    if ( is_valid_row ( $row ) ) {
      my $records = process_row ( $row ) ;
      push ( @$result, @$records ) ;
    }
  }
  return $result ;
}

####################################################################################################

sub is_valid_row ( $row ) {
  return FALSE if !$row->{instance} ;
  return FALSE if !$row->{duration} ;
  return FALSE if !( $row->{single_ts} || $row->{recurring_cron} ) ;
  return TRUE ;
}

####################################################################################################

sub process_row ( $row ) {
  if ( $row->{single_ts} ) {
    return process_single_ts ( $row ) ;
  }
  else {
    return process_cron_schedule ( $row ) ;
  }
}

####################################################################################################

sub process_single_ts ( $row ) {
  my $result = { instance => $row->{instance} } ;
  $result->{start_ts} = $row->{single_ts} ;
  $result->{start_ts} =~ s/([\d-]+)T([\d:]+)/$1 $2:00/ ;

  my $end = localtime->strptime ( $result->{start_ts}, TIMESTAMP_FORMAT ) ;
  $end += ONE_MINUTE * $row->{duration} ;
  $result->{end_ts} = $end->strftime ( TIMESTAMP_FORMAT ) ;

  return [$result] ;
}

####################################################################################################

sub process_cron_schedule ( $row ) {
  my $cron   = new Schedule::Cron::Events ( $row->{recurring_cron}, @now ) ;
  my $result = [] ;

  my $result1 = { instance => $row->{instance} } ;
  my ( $sec, $min, $hr, $day, $month, $year ) = $cron->nextEvent ;
  my $cron_ts =
    sprintf ( '%04d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1, $day, $hr, $min, $sec ) ;
  $result1->{start_ts} = $cron_ts ;
  my $ts = localtime->strptime ( $result1->{start_ts}, TIMESTAMP_FORMAT ) ;
  $ts += ONE_MINUTE * $row->{duration} ;
  $result1->{end_ts} = $ts->strftime ( TIMESTAMP_FORMAT ) ;
  push ( @$result, $result1 ) ;

  $cron->resetCounter () ;

  my $result2 = { instance => $row->{instance} } ;
  ( $sec, $min, $hr, $day, $month, $year ) = $cron->previousEvent () ;
  $cron_ts =
    sprintf ( '%04d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1, $day, $hr, $min, $sec ) ;
  $result2->{start_ts} = $cron_ts ;
  $ts = localtime->strptime ( $result2->{start_ts}, TIMESTAMP_FORMAT ) ;
  $ts += ONE_MINUTE * $row->{duration} ;
  $result2->{end_ts} = $ts->strftime ( TIMESTAMP_FORMAT ) ;
  push ( @$result, $result2 ) ;

  return $result ;
}

####################################################################################################

sub get_active_records ( $records, $now_ts ) {
  my $result = [] ;
  foreach my $record ( @$records ) {
    if ( $now_ts ge $record->{start_ts} && $now_ts le $record->{end_ts} ) {
      push ( @$result, $record ) ;
    }
  }
  return $result ;
}

####################################################################################################

sub download_gsheet() {
  my $ua = Mojo::UserAgent->new ;
  $ua->max_redirects ( 2 ) ;
  my $resp = $ua->get ( PLANNED_DOWNTIME_GSHEET )->result ;
  if ( $resp->is_success ) {
    return $resp->body ;
  }
  else {
    $prom_gsheet_download_error_counter->inc ;
    return '' ;
  }
}

####################################################################################################

app->start ;
