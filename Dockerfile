FROM ubuntu:16.04

MAINTAINER Sarlos Cainz

RUN sed -i.bak -e "s%archive.ubuntu.com%jp.archive.ubuntu.com%g" /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        id3v2 \
        jq \
        lame \
        libxml2-utils \
        rtmpdump \
        swftools \
        wget \
        language-pack-ja \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN /bin/rm /etc/localtime \
 && /bin/ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

VOLUME ["/data", "/config.json"]
WORKDIR /tmp

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
