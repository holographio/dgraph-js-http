#!/bin/bash

set -e
set -x

image="dgraph/dgraph:v20.11.3"
dir="$(cd "$(dirname "$0")" && pwd -P)"
data="${dir}/../data"

function dgraph {
	docker run -d --rm --network host -v "${data}/acl-secret.txt":/tmp/acl-secret.txt "${image}" dgraph "$@"
}

mkdir -p "${data}"

head -c 1024 /dev/random > "${data}/acl-secret.txt"

echo -e "Starting Dgraph zero.\n"
zero_id=`dgraph zero`
sleep 5

echo -e "Starting Dgraph alpha."
alpha_id=`dgraph alpha --lru_mb 4096 --acl_secret_file /tmp/acl-secret.txt`
sleep 15

npm run build
npm test

docker stop $zero_id
docker stop $alpha_id
rm -rf "${data}"
