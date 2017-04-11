#!/bin/sh
name=cdegroot/kafka:$(git rev-parse --short HEAD)
docker build -t $name .
docker push $name
echo Published $name
