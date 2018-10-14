# Overview
A docker container to build a ZCash node from source and run it in a container.

## Zcash Data Storage ##
The "Zcash data" (i.e. blockchain data, wallet) are very large and not suitable for storing in the container’s writable layer. The Zcash data is large and to download/regenerate it each time you regenerate a container would be terrible. Also you may want to have multiple Zcash containers over time and you wouldn't want the local copy of the blockchain destroyed along with it. So the Zcash data is tored in [Docker volumes](https://docs.docker.com/storage/volumes/). The Zcash blockchain data (i.e. the value for zcashd's `-datadir` arg) is stored in a Docker volume named `zcash-datadir`.

So if you kill the container and associated iamges and rebuild it, it will only pull and rebuild the source, it won't need to download and reindex the blockchain or zkSNARK parameters.

#SECURITY NOTES #
A couple key things to keep in mind with regards to security:

* The Zcash node's wallet is stored in the `zcash-datadir` volume above. So if you have any value stored in that wallet any other container that mounts it will have access to the wallet.
* See the `zcash.conf` file in the Dockerfile has other security elements in it that you need to be cautious about (e.g. `rpcuser` and `rpcpassword`).

# Build it: #

    docker build -t zcash .

# Run it from image: #

```
docker run --detach \
--name zc \
-P \
--mount source=zcash-datadir,target=/zcash-datadir \
zcash:latest
```

# Gracefully Stop the Container #

    docker exec zc ./src/zcash-cli --datadir=/zcash-datadir stop

# Start it from an existing stopped container: #

    docker start zc

# Use It #
With the container running (in another tab if running interactively):

## See what ZCash is doing: ##

or for a streaming view of debug.log:

    docker container exec zc tail -f /zcash-datadir/debug.log

to view the config:

    docker container exec zc cat /zcash-datadir/zcash.conf

## Run ZCash RPC commands: ##
_With the container running..._

    docdocker exec zc ./src/zcash-cli --datadir=/zcash-datadir help

    docdocker exec zc ./src/zcash-cli --datadir=/zcash-datadir getinfo

    docdocker exec zc ./src/zcash-cli --datadir=/zcash-datadir getnetworksolps

    docdocker exec zc ./src/zcash-cli --datadir=/zcash-datadir getblockcount


## Save Container with State into Image ##

    ZHEAD=$(docker container exec --workdir /usr/src/zcash/zcash-src zc cat ./.git/FETCH_HEAD); docker container commit --message "zcash FETCH_HEAD $ZHEAD" zc zcash:container-backup

To run the saved image with mapping port 8000 on the host to port 8232 on the container (port 8232 is exposed in the Dockerfile, but this maps it to a specific host port):
 
    docker run --detach --name zc --publish 8000:8232 zcash:latest

## Update Zcash to the latest version from source ##
With the blockchain stored in the Docker Volume as described above you won't loose the blockchain when rebuilding the container. So to update to a new version in the source, just rebuild the image from the Dockerfile and update the `ZCASH_TAG` Docker ARG like. For example, to rebuild the container using the source tag `v2.0.1-rc1`, run the following:

    docker build --build-arg ZCASH_TAG=v2.0.1-rc1 -t zcash:v2.0.1-rc1 .

# Exposed Ports
## To see what ports the container is exposing already:

    docker container ls


# TODO #
- Dockerfile-base - Base image with only necessary dependencies to build zcash
    - Dockerfile-dev - should build from source and stop
        - should COPY zcash source from a ./zcash-src directory
            - user expected to clone on host
        - setup script to build source (after local edits on host)
        - setup script to force-rebuild source
        - setup script to run tests
    - Dockerfile-run-testnet Create an image FROM the baseimage to run on testnet
        - should git clone within container
            - Should expect an ARG for the tag/commit to checkout from
    - Dockerfile-run-mainnet Create an image FROM the baseimage to run on mainnet
