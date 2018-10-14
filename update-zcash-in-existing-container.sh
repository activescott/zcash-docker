#!/bin/bash

#########
# This is probably not useful in most cases now that the Dockerfile is using Docker Volumes for the blockchain storage.
# Leaving here only really for reference
#########
die () {
	echo >&2 "$@"
	exit 1
}

CONTAINERDEF=zc
IMAGEDEF=zcash:deprecatedv1.1.0
BRANCHDEF=v2.0.0

read -p "Whats the name of the container? ($CONTAINERDEF) " CONTAINER
[[ -n $CONTAINER ]] || CONTAINER=$CONTAINERDEF

read -p "Whats the name of the image to start a container from (ignored if container is already running)? ($IMAGEDEF) " IMAGE
[[ -n $IMAGE ]] || IMAGE=$IMAGEDEF

read -p "Whats the name of the Zcash git branch to update to? ($BRANCHDEF) " BRANCH
[[ -n $BRANCH ]] || BRANCH=$BRANCHDEF

status () {
  printf "\n**********\n$@\n"
}

# See if container is already running:
docker exec $CONTAINER true 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo Container \"$CONTAINER\" not running. Starting container...
  docker run -it -d --name $CONTAINER $IMAGE /bin/bash
  run_code=$?
  printf "docker run returned exit code \"$run_code\"."
  [[ $run_code -eq 0 ]] || die "Failed to start container"
else
  echo Container \"$CONTAINER\" running.
fi

status "Git fetching origin...\n"
docker container exec --workdir /usr/src/zcash/zcash-src zc git fetch origin
[ $? ] || die git fetch failed

status "Git checking out branch $BRANCH..."
docker container exec --workdir /usr/src/zcash/zcash-src zc git checkout --force $BRANCH
[ $? ] || die git checkout failed

status "Git clean..."
docker container exec --workdir /usr/src/zcash/zcash-src zc git clean -f -x -d .

status "Git status..."
docker container exec --workdir /usr/src/zcash/zcash-src zc git status

status "Fetching params (pre-build step)..."
docker container exec --workdir /usr/src/zcash/zcash-src $CONTAINER ./zcutil/fetch-params.sh
[ $? ] || die fetch params failed

status "Running make clean..."
docker container exec --workdir /usr/src/zcash/zcash-src $CONTAINER make clean
[ $? ] || die make clean failed

status "Building..."
docker container exec --workdir /usr/src/zcash/zcash-src $CONTAINER ./zcutil/build.sh -j4
[ $? ] || die build failed
