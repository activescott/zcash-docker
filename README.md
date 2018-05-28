# Overview
A docker container to build a ZCash node from source and run it in a container.

# Build it:

    docker build -t zcash .

# Run it from image:

    docker run --detach --name zc --publish 8000:8232 zcash:latest

# Gracefully Stop the Container

    docker exec zc ./src/zcash-cli stop


# Start it from an existing stopped container:

    docker start zc

# Use It
With the container running (in another tab if running interactively):

## See what ZCash is doing:

or for a streaming view of debug.log:

    docker container exec zc tail -f /root/.zcash/debug.log

to view the config:

    docker exec zc cat /root/.zcash/zcash.conf


## Run ZCash RPC commands:

    docker exec zc ./src/zcash-cli help

    docker exec zc ./src/zcash-cli getinfo

    docker exec zc ./src/zcash-cli getnetworksolps

    docker exec zc ./src/zcash-cli getblockcount


## Save Container with State into Image

    ZBC=$(docker exec zc ./src/zcash-cli getblockcount); docker container commit --message "zcash blockcount $ZBC" zc zcash:blockcount_$ZBC

You can later run a container from that image like this:

    docker run --detach --name zc zcash:blockcount_20848

To run it with publishing port 8232 of container to port 8000 on host:
 
    docker run --detach --name zc --publish 8232:8232 zcash:blockcount_20848


# Exposed Ports
## To see what ports the container is exposing already:

    docker container ls

## To expose ports
You can only expose ports in docker when creating a new container. So best to do it when running it above. However, if you've already started a container and want to expose ports on it, save the container to an image (see _Save Container with State into Image_ above) and then run a new container from that saved image with the `--publish` parameter like so:

    docker run --detach --name zc --expose 8232 --publish 8000:8232 zcash:blockcount_322963

The above maps the container's port 8232 to port 8000 on the host. 


# TODO
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
