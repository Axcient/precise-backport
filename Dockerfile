FROM ubuntu:precise

# Set locale to fix character encoding
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 16126D3A3E5C1192

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and utilities
RUN apt-get update && apt-get install -y \
  apt-src \
  devscripts \
  debian-keyring \
  debhelper \
  software-properties-common \
  aptitude \
  sudo \
  wget \
  less \
  vim \
  quilt

WORKDIR /build

# Avoid warnings and occasional bugs with building packages as root
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN useradd --user-group builder
RUN adduser builder sudo
RUN mkdir -p /home/builder
RUN chown -R builder:builder \
  /home/builder \
  /build
USER builder
RUN mkdir -p ~/.apt-src

# Set name and email that will appear in changelog entries
ARG name="Backport Builder"
ARG email="nowhere@example.com"
ARG version="backport"
ARG distribution="precise"
ENV NAME=${name}
ENV EMAIL=${email}
ENV VERSION=${version}
ENV DISTRIBUTION=${distribution}
ENV QUILT_PATCHES=debian/patches

COPY build_backport.sh /scripts/

# Will build stuff here

VOLUME /out

# Copy build packages to volume
CMD cp -a /build/* /out/
