FROM ubuntu:18.04
WORKDIR /home

# Install some necessary packages
RUN apt-get update -y --fix-missing
RUN apt-get upgrade -y
RUN apt-get install -y bc build-essential cpio file git gnupg2 \
    libncurses5-dev libc6-dev rsync tftp-hpa tree unzip wget
