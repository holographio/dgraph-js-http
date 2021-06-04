#!/bin/bash

sleepTime=5
if [[ "$TRAVIS" == true ]]; then
    sleepTime=30
fi

zero_pid=
alpha_pid=

function quit {
    echo "Shutting down Dgraph alpha and zero."
    curl -s localhost:8080/admin/shutdown #TODO In the future this endpoint won't work anymore, in favor of GraphQL. We should prepare it.

    kill -9 $zero_pid || true
    kill -9 $alpha_pid || true

    echo "Waiting for dgraph to shutdown."
    wait $zero_pid || true
    wait $alpha_pid || true

    echo "Clean shutdown done."
    return $1
}

function start {
    echo -e "Starting Dgraph alpha."
    head -c 1024 /dev/random > data/acl-secret.txt
    dgraph alpha -p data/p -w data/w --lru_mb 4096 --acl_secret_file data/acl-secret.txt > data/alpha.log 2>&1 &
    alpha_pid=$!
    # Wait for membership sync to happen.
    sleep $sleepTime
    return 0
}

function startZero {
    echo -e "Starting Dgraph zero.\n"
    dgraph zero -w data/wz > data/zero.log 2>&1 &
    zero_pid=$!
    # To ensure Dgraph doesn't start before Dgraph zero.
    # It takes time for zero to start on travis mac.
    sleep $sleepTime
}

function init {
    echo -e "Initializing.\n"
    mkdir data
}
