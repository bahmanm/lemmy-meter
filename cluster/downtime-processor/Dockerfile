FROM perl:5.39.8

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm Carton \
    && mkdir -p /opt/downtime-processor/ /opt/downtime-processor-lib/

COPY cpanfile /opt/downtime-processor-lib

RUN cd /opt/downtime-processor-lib \
    && carton install
