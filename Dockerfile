FROM ubuntu:16.04

MAINTAINER Sarlos Cainz

RUN sed -i.bak -e "s%archive.ubuntu.com%jp.archive.ubuntu.com%g" /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        id3v2 \
        lame \
        libxml2-utils \
        rtmpdump \
        swftools \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:en
ENV LC_ALL ja_JP.UTF-8

VOLUME ["/data"]
WORKDIR /tmp

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
