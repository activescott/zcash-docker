FROM ubuntu:latest

WORKDIR /usr/src/zcash

# Most of this from https://github.com/zcash/zcash/wiki/1.0-User-Guide

# Install dependencies - https://github.com/zcash/zcash/wiki/1.0-User-Guide#install-dependencies
RUN apt-get update && apt-get install -y \
      autoconf \
      automake \
      bsdmainutils \
      build-essential \
      curl \
      g++-multilib \
      git \
      libc6-dev \
      libtool \
      m4 \
      ncurses-dev \
      pkg-config \
      python \
      python-zmq \
      unzip \
      wget \
      zlib1g-dev \
      && rm -rf /var/lib/apt/lists/*

# Fetch the software and parameter files - https://github.com/zcash/zcash/wiki/1.0-User-Guide#fetch-the-software-and-parameter-files
RUN git clone https://github.com/zcash/zcash.git zcash-src

WORKDIR zcash-src
RUN git checkout v1.1.0
RUN ./zcutil/fetch-params.sh

# Build - https://github.com/zcash/zcash/wiki/1.0-User-Guide#build
RUN ./zcutil/build.sh -j$(nproc)

# Testing - https://github.com/zcash/zcash/wiki/1.0-User-Guide#testing
## TAKES FOREVER!
## RUN ./qa/zcash/full_test_suite.py


# Configuring for Mainnet - https://github.com/zcash/zcash/wiki/1.0-User-Guide#configuring-for-mainnet
RUN mkdir -p ~/.zcash
RUN echo "addnode=mainnet.z.cash" >~/.zcash/zcash.conf

# RPC Config:
# 8232 is the rpc port
EXPOSE 8232

RUN echo "rpcuser=activescott" >>~/.zcash/zcash.conf
# CHANGE THIS PASSWORD
RUN echo "rpcpassword=123456" >>~/.zcash/zcash.conf
# By default, only RPC connections from localhost are allowed.
# Specify as many rpcallowip= settings as you like to allow connections from other hosts:
#  (172.17.0.0 is a default address range for containers in docker)
RUN echo "rpcallowip=172.17.0.1/255.255.255.0" >>~/.zcash/zcash.conf

# See https://en.bitcoin.it/wiki/Running_Bitcoin#Sample_Bitcoin.conf for more configuration:

# Running Zcash - https://github.com/zcash/zcash/wiki/1.0-User-Guide#running-zcash
CMD ./src/zcashd
