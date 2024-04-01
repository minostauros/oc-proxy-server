FROM    ubuntu:20.04

WORKDIR    /

ARG MICROSOCKS_VERSION=1.0.3
ARG TINYPROXY_VERSION=1.11.1
ARG OPENCONNECT_VERSION=9.12

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV TZ=Asia/Seoul
ENV HTTPS_PROXY_PORT=8888
ENV SOCKS5_PROXY_PORT=8889

RUN apt-get -y update -qq --fix-missing && \
    apt-get -y install --no-install-recommends \
        git \
        make \
        automake \
        unzip \
        wget \
        ca-certificates \
        build-essential \
        gcc \
        iputils-ping \
# install packages for openconnect
        pkg-config \
        autoconf \
        libxml2 \
        openssl \
        libtool \
        gettext \
        zlib1g-dev \
        libxml2-dev \
        libssl-dev \
        libp11-dev \
        libproxy-dev \
        libstoken-dev \
        libpcsclite-dev \
        libgnutls28-dev \
        curl \
        libcurl4-openssl-dev \
        libc6-dev-i386 \
        libevent-dev \
        liblwip-dev \
        python3 \
        python3-dev \
        python3-pip \
        default-jre \
        && \
# microsocks
    wget https://github.com/rofl0r/microsocks/archive/v${MICROSOCKS_VERSION}.zip -O microsocks.zip --progress=bar:force:noscroll && \
    unzip -q microsocks.zip && \
    rm microsocks.zip && \
    mv /microsocks-${MICROSOCKS_VERSION} /microsocks && \
    cd /microsocks && \
    make && \
    make install && \
    cd / && \
    rm -rf /microsocks && \
# tinyproxy
    wget https://github.com/tinyproxy/tinyproxy/archive/${TINYPROXY_VERSION}.zip -O tinyproxy.zip --progress=bar:force:noscroll && \
    unzip -q tinyproxy.zip && \
    rm tinyproxy.zip && \
    mv /tinyproxy-${TINYPROXY_VERSION} /tinyproxy && \
    cd /tinyproxy && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf /tinyproxy && \
# openconnect
    mkdir -p /openconnect && \
    cd /openconnect && \
    wget https://gitlab.com/openconnect/openconnect/-/archive/v${OPENCONNECT_VERSION}/openconnect-v${OPENCONNECT_VERSION}.zip -O openconnect.zip --progress=bar:force:noscroll && \
    unzip -q openconnect.zip && \
    rm openconnect.zip && \
    ls -lah && \
    mv openconnect-v${OPENCONNECT_VERSION}/* /openconnect/ && \
    mkdir -p /etc/vpnc && \
    wget https://gitlab.com/openconnect/vpnc-scripts/-/raw/master/vpnc-script -O /etc/vpnc/vpnc-script --progress=bar:force:noscroll && \
    chmod +x /etc/vpnc/vpnc-script && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    cd / && \
# python packages for openconnect tncc
    pip install mechanize netifaces urlgrabber asn1crypto && \
# set default python
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
# cleaning
   apt-get -y remove \
        unzip \
        git \
        make \
        automake \
        wget \
        gcc \
        pkg-config \
        autoconf \
        && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# tinyproxy configuration file
    echo $'Port 8888\nMaxClients 100\nTimeout 600\n#BasicAuth user password\n' >> /etc/tinyproxy.conf && \
# startup.sh
    echo $'#!/bin/sh\n\n\
set -ex\n\n# Set proxy port\n\
sed \"s/^Port .*$/Port $HTTPS_PROXY_PORT/\" -i /etc/tinyproxy.conf\n\
if [ ! -z $TINYPROXY_USER ]\n\
then\n\
   if [ ! -z $TINYPROXY_PASSWORD ]\n\
   then\n\
      sed \"s/^#BasicAuth user password/BasicAuth $TINYPROXY_USER $TINYPROXY_PASSWORD/\" -i /etc/tinyproxy.conf \n\
   fi\n\
fi\n\n# Start proxy\n\
tinyproxy -c /etc/tinyproxy.conf\n\n# Start socks5 proxy\n\
/usr/local/bin/microsocks -i 0.0.0.0 -p $SOCKS5_PROXY_PORT\n' >> /root/startup.sh && \
    chmod +x /root/startup.sh

CMD  ["/root/startup.sh"]
WORKDIR /workspace
