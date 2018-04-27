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

# Build unattended-upgrade package with fix for cpu-pinning bug
RUN sudo apt-get update \
  && apt-src install unattended-upgrades
ARG new_uu_version="0.82.1ubuntu1"
ARG old_uu_version="0.76ubuntu1.3"
ARG uu_dir="unattended-upgrades-${old_uu_version}"

RUN debchange \
  --changelog ${uu_dir}/debian/changelog \
  --newversion ${new_uu_version}~0${VERSION} \
  --distribution ${DISTRIBUTION} \
  --force-distribution \
  "Backport cpu pinning bugfix from ${new_uu_version}."

# Apply cpu-pinning-bug fix
# See https://bugs.launchpad.net/ubuntu/+source/unattended-upgrades/+bug/1265729
COPY ${uu_patch} /patches/
ARG uu_patch="unattended-upgrade.patch"
ARG uu_to_patch="unattended-upgrade"
RUN patch ${uu_dir}/${uu_to_patch} /patches/${uu_patch}

RUN cd ${uu_dir} \
  && debuild -i -uc -us
RUN rm -rf ${uu_dir}
RUN ls /build/
RUN rm -rf *${old_uu_version}*


VOLUME /out

# Copy build packages to volume
CMD cp -a /build/* /out/
