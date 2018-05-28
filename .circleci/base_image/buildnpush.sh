#!/bin/sh
name=cdegroot/palapa-ci:$(git rev-parse --short HEAD)
docker build -t $name .
docker push $name
echo Published $name
