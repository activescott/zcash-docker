#!/bin/bash

die () {
	echo >&2 "$@"
	exit 1
}

CONTAINER=zc
IMAGE=zcash:v2-with-data

status () {
  printf "\n**********\n$@\n"
}

docker run -it -d \
--name $CONTAINER \
--mount source=zcash-datadir,target=/zcash-datadir \
$IMAGE /bin/bash

#docker exec zc cp -Rvu /root/.zcash/. /zcash-datadir/
docker exec zc ls -a /zcash-datadir/
