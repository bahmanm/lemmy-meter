FROM perl:5.38

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN cpan Mojo::Lite Net::Prometheus Mojo::UserAgent Data::Dump
RUN cpan Schedule::Cron::Events Text::CSV
RUN cpan Moose JSON JSON::Validator File::Slurper
RUN cpan Data::UUID Log::Log4perl
