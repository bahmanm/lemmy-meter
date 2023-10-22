#!/usr/bin/env perl

use strict ;
use warnings ;
use diagnostics ;
use utf8 ;
use feature ':5.38' ;
use experimental qw(try) ;

use Data::Dump qw(dump) ;

local $ENV{TZ} = 'UTC' ;

####################################################################################################

{

  package LmDP ;

  use Log::Log4perl ;

  use constant {
    TRUE               => 1,
    FALSE              => 0,
    DEFAULT_GSHEET_URL =>
'https://docs.google.com/spreadsheets/d/1KS3pMzrkW4888LbtqoGR5xylLCfYfkeHrSyMHIIvAfg/export?exportFormat=csv',
    DEFAULT_GSHEET_HEADER_ROWS      => 12,
    TIMESTAMP_FORMAT                => '%Y-%m-%d %H:%M:%S',
    DEFAULT_SCRAPE_TARGETS_LOCATION => './scrape-targets.txt',
    DEFAULT_SCHEMA_LOCATION         => './scheduled-downtime-schema.json',
    DEFAULT_LOG_LEVEL               => 'WARN'
  } ;

  my $log4perl_conf = q(
    log4perl.rootLogger=DEBUG,Screen
    log4perl.appender.Screen = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.layout = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = [%r] %F %L %c - %m%n
  ) ;

  our $json_schema_path    = ( $ENV{LMDP_JSON_SCHEMA}    or DEFAULT_SCHEMA_LOCATION ) ;
  our $scrape_targets_path = ( $ENV{LMDP_SCRAPE_TARGETS} or DEFAULT_SCRAPE_TARGETS_LOCATION ) ;
  our $log_level           = ( $ENV{LMDP_LOG_LEVEL}      or DEFAULT_LOG_LEVEL ) ;
  our $gsheet_url          = ( $ENV{LMDP_GSHEET_URL}     or DEFAULT_GSHEET_URL ) ;
  our $ghseet_header_rows  = ( $ENV{LMDP_GSHEET_HEADER_ROWS} or DEFAULT_GSHEET_HEADER_ROWS ) ;

  our $json_validator = JSON::Validator->new->schema ( $json_schema_path ) ;
  our ( @now, $now_ts ) = ( undef, undef ) ;

  Log::Log4perl::init ( \$log4perl_conf ) ;
  our $logger = Log::Log4perl->get_logger ( 'LmDP' ) ;
  $logger->level ( Log::Log4perl::Level::to_priority ( $log_level ) ) ;
}

####################################################################################################

{

  package LmDP::Metrics ;

  use Net::Prometheus ;

  our $prom                  = Net::Prometheus->new ;
  our $counter_http_requests = $prom->new_counter (
    name => 'lmdp_http_requests',
    help => 'Number of HTTP requests received'
  ) ;
  our $counter_scrape = $prom->new_counter (
    name   => 'lmdp_scrape_count',
    help   => 'Number of times targets (Lemmy instance and GSheet) were scraped.',
    labels => [ "result", "target" ]
  ) ;
  our $counter_json_validation = $prom->new_counter (
    name   => 'lmdp_json_validation_count',
    help   => 'Number of times scraped JSON data was validated.',
    labels => [ "result", "target" ]
  ) ;
}

####################################################################################################

{

  ####################
  # Represents the next downtime for a particular Lemmy instance.
  ####################
  package LmDP::NextOccurence ;
  use Moose ;
  require JSON ;

  has 'start_ts'       => ( is => 'rw', isa => 'Str' ) ;
  has 'end_ts'         => ( is => 'rw', isa => 'Str' ) ;
  has 'lemmy_instance' => ( is => 'rw', isa => 'Str' ) ;

  sub is_active ( $self, $ts ) {
    if ( $ts ge $self->start_ts () && $ts le $self->end_ts () ) {
      return LmDP::TRUE ;
    }
    else {
      return LmDP::FALSE ;
    }
  }
}

####################################################################################################

{

  ####################
  # Represents a single schedule scraped.
  ####################
  package LmDP::Schedule ;

  use Moose ;

  has 'when'     => ( is => 'rw', isa => 'Str' ) ;
  has 'cron'     => ( is => 'rw', isa => 'Str' ) ;
  has 'duration' => ( is => 'rw', isa => 'Int' ) ;
  has 'instance' => ( is => 'rw', isa => 'Str' ) ;

  sub is_valid ( $self ) {
    return LmDP::FALSE if !$self->instance () ;
    return LmDP::FALSE if !$self->duration () ;
    return LmDP::FALSE if !( $self->when () || $self->cron () ) ;
    return LmDP::TRUE ;
  }

  sub is_recurring ( $self ) {
    if ( $self->when () ) {
      return LmDP::FALSE ;
    }
    else {
      return LmDP::TRUE ;
    }
  }

}

####################################################################################################

{

  ####################
  # Represents the CSV data via the GSheet.
  ####################
  package LmDP::Csv ;

  use Moose ;
  require Text::CSV ;

  has 'text' => ( is => 'rw', isa => 'Str' ) ;
  has 'rows' => ( is => 'rw', isa => 'ArrayRef[LmDP::Schedule]', default => sub { [] } ) ;

  sub of_text ( $text ) {
    if ( !$text ) {
      $LmDP::logger->error ( "Attempting to load from an empty text." ) ;
      return undef ;
    }
    my $result = LmDP::Csv->new () ;

    my @raw_lines      = split ( /\r?\n/, $text ) ;
    my $text_no_header = join ( "\n", @raw_lines[ $LmDP::ghseet_header_rows .. $#raw_lines ] ) ;
    $result->text ( $text_no_header ) ;

    my $csv = Text::CSV->new ( { diag_verbose => 1 } ) ;
    $csv->column_names ( qw(instance when cron duration matrix_user email) ) ;
    open ( my $sfh, '<', \$text_no_header ) ;
    my $lines = $csv->getline_hr_all ( $sfh ) ;
    close ( $sfh ) ;

    foreach my $line ( @$lines ) {
      my $row = LmDP::Schedule->new (
        {
          instance => $line->{instance},
          when     => $line->{when},
          cron     => $line->{cron},
          duration => $line->{duration}
        }
      ) ;
      push ( @{ $result->rows }, $row ) if $row->is_valid () ;
    }
    $LmDP::logger->debug ( "Loaded $#{ $result->rows } rows from CSV." ) ;
    return $result ;
  }
}

####################################################################################################

{
  ####################
  # Maps an LmDP::Schedule ot LmDP::NextOccurence
  ####################
  package LmDP::ScheduleMapper ;

  require Schedule::Cron::Events ;
  use Time::Piece ;
  use Time::Seconds ;

  sub to_NextOccurence ( $schedule ) {
    if ( $schedule->is_recurring () ) {
      return _map_recurring ( $schedule ) ;
    }
    else {
      return _map_non_recurring ( $schedule ) ;
    }
  }

  sub _map_non_recurring ( $schedule ) {
    my $result = LmDP::NextOccurence->new ( { lemmy_instance => $schedule->instance () } ) ;

    my $start_ts = $schedule->when () ;
    $start_ts =~ s/([\d-]+)T([\d:]+)/$1 $2:00/ ;
    $result->start_ts ( $start_ts ) ;

    my $end_ts = localtime->strptime ( $start_ts, LmDP::TIMESTAMP_FORMAT ) ;
    $end_ts += ONE_MINUTE * $schedule->duration () ;
    $result->end_ts ( $end_ts->strftime ( LmDP::TIMESTAMP_FORMAT ) ) ;

    return ( $result ) ;
  }

  sub _map_recurring ( $schedule ) {
    my $cron   = new Schedule::Cron::Events ( $schedule->cron (), @LmDP::now ) ;
    my @result = () ;

    my ( $start_ts1, $end_ts1 ) =
      _ts_duration_to_start_end_ts ( $schedule->duration (), $cron->nextEvent () ) ;
    my $result1 = LmDP::NextOccurence->new (
      {
        lemmy_instance => $schedule->instance (),
        start_ts       => $start_ts1,
        end_ts         => $end_ts1
      }
    ) ;
    push ( @result, $result1 ) ;

    $cron->resetCounter () ;

    my ( $start_ts2, $end_ts2 ) =
      _ts_duration_to_start_end_ts ( $schedule->duration (), $cron->previousEvent () ) ;
    my $result2 = LmDP::NextOccurence->new (
      {
        lemmy_instance => $schedule->instance (),
        start_ts       => $start_ts2,
        end_ts         => $end_ts2
      }
    ) ;
    push ( @result, $result2 ) ;

    return @result ;
  }

  sub _ts_duration_to_start_end_ts ( $duration, $sec, $min, $hr, $day, $month, $year ) {
    my @result       = () ;
    my $start_ts_str = sprintf ( '%04d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1,
      $day, $hr, $min, $sec ) ;
    push ( @result, $start_ts_str ) ;
    my $ts = localtime->strptime ( $start_ts_str, LmDP::TIMESTAMP_FORMAT ) ;
    $ts += ONE_MINUTE * $duration ;
    push ( @result, $ts->strftime ( LmDP::TIMESTAMP_FORMAT ) ) ;
    return @result ;
  }
}

####################################################################################################

{

  ####################
  # Deals w/ downtime schedules scraped off instances.
  #
  # The JSON document is validated against the schema available at
  # lemmy-meter.info/.schemas/scheduled-downtime.json"
  ####################
  package LmDP::Json ;

  use JSON qw(decode_json) ;
  use JSON::Validator ;
  use Data::Dump qw(dump) ;

  use Moose ;

  has 'text'      => ( is => 'rw', isa => 'Str' ) ;
  has 'schedules' => ( is => 'rw', isa => 'ArrayRef[LmDP::Schedule]' ) ;

  sub of_text ( $text, $target ) {
    if ( !$text ) {
      $LmDP::logger->error ( "Attempting to load from an empty text." ) ;
      return undef ;
    }
    my $result = LmDP::Json->new ( { text => $text, schedules => [] } ) ;
    my $json   = decode_json ( $text ) ;
    my @errors = $LmDP::json_validator->validate ( $json ) ;
    if ( @errors ) {
      warn ( @errors ) ;
      $LmDP::Metrics::counter_json_validation->inc ( { target => $target, result => "error" } ) ;
    }
    else {
      $LmDP::Metrics::counter_json_validation->inc (
        { target => $target, result => "success" } ) ;
      my @schedules = _records_from ( $json, $target ) ;
      $result->schedules ( \@schedules ) ;
    }
    $LmDP::logger->debug ( "Loaded $#{ $result->schedules } records from JSON." ) ;
    return $result ;
  }

  sub _records_from ( $json, $target ) {
    my @result = () ;
    foreach my $record ( @{ $json->{schedule}->{once} } ) {
      push (
        @result,
        LmDP::Schedule->new (
          { when => $record->{when}, duration => $record->{duration}, instance => $target }
        )
      ) ;
    }
    foreach my $record ( @{ $json->{schedule}->{recurring} } ) {
      push (
        @result,
        LmDP::Schedule->new (
          { cron => $record->{cron}, duration => $record->{duration}, instance => $target }
        )
      ) ;
    }
    return @result ;
  }
}

####################################################################################################

{

  ####################
  # Scrape the downtime schedules off both the GSheet and Lemmy instances defined in
  # `$scrape_targets_path'.
  ####################
  package LmDP::Scrape ;

  use Mojo::UserAgent ;
  use File::Slurper qw(read_lines) ;
  use Data::Dump    qw(dump) ;
  use Mojo::Promise ;

  our @scrape_targets = do {
    my @lines = read_lines ( $LmDP::scrape_targets_path ) ;
    grep ( !/^\s*$/, @lines ) ;
  } ;

  sub scrape {
    my @occurences = () ;
    push ( @occurences, _gsheet () ) ;
    push ( @occurences, _json_all () ) ;

    my %instances = () ;
    my @result    = () ;
    foreach my $occ ( @occurences ) {
      if ( !$instances{ $occ->lemmy_instance } ) {
        $instances{ $occ->lemmy_instance } = LmDP::TRUE ;
        push ( @result, $occ ) ;
      }
    }

    return @result ;
  }

  sub _gsheet {
    my $text = _scrape ( $LmDP::gsheet_url, "gsheet" ) ;
    my $csv  = LmDP::Csv::of_text ( $text ) ;
    if ( !$csv ) {
      return () ;
    }
    else {
      return _active_occurences ( $csv->rows ) ;
    }
  }

  sub _json_all {
    my @occurences = () ;
    $LmDP::logger->info ( "Attempting to scrape off " . ( $#scrape_targets + 1 ) . " targets." ) ;
    foreach my $target ( @scrape_targets ) {
      push ( @occurences, _json ( $target ) ) ;
    }
    return @occurences ;
  }

  sub _json ( $lemmy_instance ) {
    my $text = _scrape ( "$lemmy_instance/scheduled-downtime.json", $lemmy_instance ) ;
    my $json = LmDP::Json::of_text ( $text, $lemmy_instance ) ;
    if ( !$json ) {
      return () ;
    }
    else {
      return _active_occurences ( $json->schedules ) ;
    }
  }

  sub _active_occurences ( $schedules ) {
    my @occurences = () ;
    foreach my $schedule ( @$schedules ) {
      if ( $schedule->is_valid ) {
        my @occs = LmDP::ScheduleMapper::to_NextOccurence ( $schedule ) ;
        foreach my $occ ( @occs ) {
          if ( $occ->is_active ( $LmDP::now_ts ) ) {
            $LmDP::logger->debug ( "Identified active downtime. LmDP::Schedule is "
                . Data::Dumper->Dumper ( $schedule )
                . " and LmDP::NextOccurence is "
                . Data::Dumper->Dumper ( $occ ) ) ;
            push ( @occurences, $occ ) ;
          }
        }
      }
    }
    return @occurences ;
  }

  sub _scrape ( $url, $target ) {
    $LmDP::logger->debug ( "Attempting to scrape off $url w/ target being $target." ) ;
    try {
      my $ua   = Mojo::UserAgent->new->max_redirects ( 3 ) ;
      my $resp = $ua->get ( $url )->result ;
      if ( $resp && $resp->is_success ) {
        $LmDP::logger->debug                ( "Successful HTTP request to $url" ) ;
        $LmDP::Metrics::counter_scrape->inc ( { target => $target, result => "success" } ) ;
        return $resp->body ;
      }
      else {
        $LmDP::logger->debug                ( "Failed HTTP request to $url" ) ;
        $LmDP::Metrics::counter_scrape->inc ( { target => $target, result => "error" } ) ;
        undef ;
      }
    }
    catch ( $err ) {
      $LmDP::logger->error                ( "Failed to scrape off $url: $err" ) ;
      $LmDP::Metrics::counter_scrape->inc ( { target => $target, result => "error" } ) ;
      return undef ;
    }
  }
}

####################################################################################################

{

  ####################
  # The web server.
  ####################
  package LmDP::Web ;

  use Mojolicious::Lite ;
  use POSIX qw(strftime) ;
  use Data::UUID ;

  get '/metrics' => sub ( $c ) {
    $c->render ( text => $LmDP::Metrics::prom->render ) ;
  } ;

  get '/scheduled-downtime-in-progress.json' => sub ( $c ) {
    $LmDP::Metrics::counter_http_requests->inc ;
    @LmDP::now    = localtime () ;
    $LmDP::now_ts = strftime ( '%Y-%m-%d %H:%M', @LmDP::now ) . ':00' ;
    my @instances =
      map { { lemmy_instance => $_->lemmy_instance } } LmDP::Scrape::scrape ;
    $LmDP::logger->info (
      "There are " . ( $#instances + 1 ) . " instances undergoing scheduled downtime." ) ;
    my $resp = { scheduled_downtime => \@instances } ;
    $c->render ( json => $resp ) ;
  } ;

  our $ug   = Data::UUID->new ;
  our $uuid = $ug->create ;

  app->secrets ( [ $ug->to_string ( $uuid ) ] ) ;
}

####################################################################################################

Mojo::IOLoop->start unless Mojo::IOLoop->is_running ;
LmDP::Web::app->start ;
