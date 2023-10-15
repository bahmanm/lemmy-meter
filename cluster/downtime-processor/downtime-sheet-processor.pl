#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use feature ':5.38';

use Net::Prometheus;
use POSIX      qw(strftime);
use Data::Dump qw(dump);

use Mojo::UserAgent;
use Mojolicious::Lite;

####################################################################################################

use constant {
    TRUE                    => 1,
    FALSE                   => 0,
    PLANNED_DOWNTIME_GSHEET =>
'https://docs.google.com/spreadsheets/d/1KS3pMzrkW4888LbtqoGR5xylLCfYfkeHrSyMHIIvAfg/export?exportFormat=csv'
};

####################################################################################################

our $prometheus                 = Net::Prometheus->new;
our $prom_http_requests_counter = $prometheus->new_counter(
    name => 'planned_downtime_http_requests',
    help => 'Number of HTTP requests received'
);
our $prom_gsheet_download_error_counter = $prometheus->new_counter(
    name => 'planned_downtime_gsheet_download_errors',
    help => 'Number of errors downloading Google sheet.'
);

####################################################################################################

get '/planned-downtime-in-progress.json' => sub ($c) {
    $prom_http_requests_counter->inc;
    my $csv = download_gsheet();
    if ($csv) {
        my $instances = filter_active_instances($csv);
        $c->render(
            json => { planned_downtime => $instances, status => 'success' } );
    }
    else {
        $c->render( json => { 'planned_downtime' => [], status => 'failed' } );
    }
};

####################################################################################################

get '/metrics' => sub ($c) {
    $c->render( text => $prometheus->render );
};

####################################################################################################

sub filter_active_instances ($csv) {
    my $now_ts = time();
    my $now    = strftime( '%Y-%m-%dT%H:%M', gmtime($now_ts) );
    my @result = ();
    my @lines  = split( /\r?\n/, $csv );
    foreach my $line ( @lines[ 4 .. $#lines ] ) {
        my @fields = split( /,/, $line );
        if ( $now ge $fields[1] && $now le $fields[2] ) {
            push( @result, { lemmy_instance => $fields[0] } );
        }
    }
    return \@result;
}

####################################################################################################

sub download_gsheet() {
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(2);
    my $resp = $ua->get(PLANNED_DOWNTIME_GSHEET)->result;
    if ( $resp->is_success ) {
        return $resp->body;
    }
    else {
        $prom_gsheet_download_error_counter->inc;
        return '';
    }
}

app->start;
