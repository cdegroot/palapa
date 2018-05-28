# Base Ubuntu image

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y
RUN apt-get build-dep -y erlang
RUN apt-get install -y git
RUN apt-get install -y curl