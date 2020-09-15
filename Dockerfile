FROM ubuntu:latest

# This fixes stupid tzdata package: https://dev.to/setevoy/docker-configure-tzdata-and-timezone-during-build-20bk
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /usr/src/zcash

# Most of this from https://zcash.readthedocs.io/en/latest/rtd_pages/user_guide.html

# Install dependencies - https://zcash.readthedocs.io/en/latest/rtd_pages/Debian-Ubuntu-build.html
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
      python3 \
      python3-zmq \
      unzip \
      wget \
      zlib1g-dev \
      && rm -rf /var/lib/apt/lists/*

##### Checkout & Build ####
# Fetch the software and parameter files - https://github.com/zcash/zcash/wiki/1.0-User-Guide#fetch-the-software-and-parameter-files
RUN git clone https://github.com/zcash/zcash.git zcash-src
WORKDIR zcash-src

ARG ZCASH_TAG=v4.0.0

# NOTE: if you want to cause it to re-fetch, just append a comment to the below command:

RUN git fetch origin ${ZCASH_TAG}
RUN git checkout FETCH_HEAD

## CLEAN ##
RUN git clean -f -x -d .

##### Fetch zkSNARK Params #####
# If the zcash params already exist (as copied from volume above, the below does nothing)
# TODO: Consider using a cache VOLUME for this when Docker 18.09 is available (see https://stackoverflow.com/a/52762779/51061)
RUN ./zcutil/fetch-params.sh

##### Build #####
RUN ./zcutil/clean.sh
RUN ./zcutil/build.sh -j$(nproc)

## Testing ##
# TAKES FOREVER!
# RUN ./qa/zcash/full_test_suite.py


##### Runtime Configuration #####
# First we have to create the mountpoint (any files created in here before the VOLUME mount will be copied into the volume)
RUN [ -d /zcash-datadir ] || mkdir -v /zcash-datadir

ARG ZCASH_CONF=/zcash-datadir/zcash.conf

# SEE https://zcash.readthedocs.io/en/latest/rtd_pages/zcash_conf_guide.html#zcash-conf-guide
RUN echo "addnode=mainnet.z.cash" >${ZCASH_CONF}

RUN echo "rpcuser=activescott" >>${ZCASH_CONF}
# CHANGE THIS PASSWORD
RUN echo "rpcpassword=123456" >>${ZCASH_CONF}
# By default, only RPC connections from localhost are allowed.
# Specify as many rpcallowip= settings as you like to allow connections from other hosts:
#  (172.17.0.0 is a default address range for containers in docker)
RUN echo "rpcallowip=172.17.0.1/255.255.255.0" >>${ZCASH_CONF}

# JUST to force a rebuild of subsequent container layers
RUN echo "# rebuild" >>${ZCASH_CONF}

RUN cat ${ZCASH_CONF}

##### PORTS #####
# https://zcash.readthedocs.io/en/latest/rtd_pages/troubleshooting_guide.html#system-requirements
EXPOSE 8232
EXPOSE 8233

# Mount /zcash-datadir to share blockchain across containers (and put conf there)
VOLUME /zcash-datadir

# Running Zcash - https://github.com/zcash/zcash/wiki/1.0-User-Guide#running-zcash
# NOTE: path provided to -conf seems to always  be releative to datadir
CMD ./src/zcashd -datadir=/zcash-datadir -conf=zcash.conf
