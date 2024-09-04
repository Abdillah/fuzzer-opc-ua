#!/bin/sh

set -e

name=$(basename $(realpath $(dirname $0)))
echo $name
docker build -f server.dockerfile -t $name-server .
docker build -f fuzzer.dockerfile -t $name-fuzzer .
docker build -t $name .

imgname=$name
docker run --rm -v ./results:/home/ubuntu/experiments $imgname
