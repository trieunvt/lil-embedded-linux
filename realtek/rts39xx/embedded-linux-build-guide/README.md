# Realtek RTS39XX Embedded Linux Build Guide

## Brief Introduction

This guide tutors how to build the embedded Linux operating system based on Buildroot for Realtek RTS39XX series IPCam processors.

## Development Environment

### System Requirements

Build a Realtek docker image:

```sh
$ docker build -f realtek.dockerfile -t realtek-image:1.0.0 .
```

Create and work with a Realtek docker container:

```sh
$ docker run -it --privileged --net=host -v $PWD/source:/home --name realtek-container realtek-image:1.0.0 /bin/bash
$ docker start -ai realtek-container
```

### [Installation](../../../private/realtek_rts39xx_embedded_linux_build_guide.md)
