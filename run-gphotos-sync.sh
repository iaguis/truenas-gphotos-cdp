#!/bin/bash

# TODO add ID here
HEALTHCHECK_ID=""

docker run \
    --net=host \
    --pid=host \
    --security-opt apparmor=unconfined \
    --security-opt seccomp=unconfined \
    -e HEALTHCHECK_ID=$HEALTHCHECK_ID \
    -v /mnt/locke-nas/iago-home/gphotos-cdp:/tmp/gphotos-cdp \
    -v /mnt/locke-nas/google-photos:/home/nonroot/Downloads/gphotos-cdp \
    -v /mnt/locke-nas/iago-home/gphotos-sync/gphotos-sync.sh:/usr/bin/gphotos-sync.sh \
    ghcr.io/iaguis/gphotos-cdp:v6 \
    /usr/bin/gphotos-sync.sh
