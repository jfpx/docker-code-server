FROM lsiobase/ubuntu:bionic

# set version label
ARG CODE_RELEASE=2.1688-vsc1.39.2
LABEL build_version="version: v1 date: 2019-12-17 -Lily"
LABEL maintainer="aptalca"

# environment settings
ENV HOME="/config"

RUN \
 apt-get update && \
 apt-get install -y \
	git \
	nano \
	net-tools \
	python \
	python-pip \
	python3 \
	python3-pip \
	python-virtualenv \
	python-setuptools \
	sudo && \
 echo "**** install code-server ****" && \
 if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/code.tar.gz -L \
	"https://github.com/cdr/code-server/releases/download/${CODE_RELEASE}/code-server${CODE_RELEASE}-linux-x86_64.tar.gz" && \
 tar xzf /tmp/code.tar.gz -C \
	/usr/bin/ --strip-components=1 \
  --wildcards code-server*/code-server && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*
	
RUN pip3 install -U \
	pip \
	setuptools \
	virtualenv
	
RUN virtualenv -p python3.6 /config/workspace/py3

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
