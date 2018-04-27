#!/bin/sh
docker build \
    --build-arg name="Jared Johnson" \
    --build-arg email="jjohnson@efolder.net" \
    --build-arg version="efs1204+0" \
    --build-arg distribution="rb-precise-alpha" \
    -t \
    build-precise \
    .

docker run --rm -it -v "${PWD}/output:/out" build-precise
