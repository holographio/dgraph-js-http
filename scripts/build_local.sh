#!/bin/bash

dir="$(cd "$(dirname "$0")" && pwd -P)"

export DATA="${dir}/../data"
export PATH="${dir}:${PATH}"
export DOCKER_VOLUME=dgraph-js-http-build_local

rm -r "${DATA}"
"${dir}/build.sh"

docker volume rm "${DOCKER_VOLUME}"
