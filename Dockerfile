FROM    ubuntu:20.04

WORKDIR    /

ARG MICROSOCKS_VERSION=1.0.3
ARG TINYPROXY_VERSION=1.11.1

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
        unzip \
        wget \
        ca-certificates \
        build-essential \
        gcc \
        iputils-ping && \
    wget https://github.com/rofl0r/microsocks/archive/v${MICROSOCKS_VERSION}.zip -O microsocks.zip --progress=bar:force:noscroll && \
    unzip -q microsocks.zip && \
    rm microsocks.zip && \
    mv /microsocks-${MICROSOCKS_VERSION} /microsocks && \
    cd /microsocks && \
    make && \
    make install && \
    cd / && \
    wget https://github.com/tinyproxy/tinyproxy/archive/${TINYPROXY_VERSION}.zip -O tinyproxy.zip --progress=bar:force:noscroll && \
    unzip -q tinyproxy.zip && \
    rm tinyproxy.zip && \
    mv /tinyproxy-${TINYPROXY_VERSION} /tinyproxy && \
    cd /tinyproxy && \
    ./configure && \
    make && \
    make install && \
    apt-get -y install --no-install-recommends \
        openconnect && \
# cleaning
   apt-get -y remove \
        unzip \
        git \
        make \
        wget \
        build-essential \
        ca-certificates \
        gcc && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /microsocks /var/lib/apt/lists/* && \
# tinyproxy configuration file
    echo $'Port 8888\nMaxClients 100\nStartServers 10\nTimeout 600\n#BasicAuth user password\n' >> /etc/tinyproxy.conf && \
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
