#!/usr/bin/env sh

docker run --detach \
--name zc \
-P \
--mount source=zcash-datadir,target=/zcash-datadir \
--publish 8000:8232 \
zcash:latest