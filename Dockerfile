FROM lsiobase/ubuntu:bionic

# set version label
ARG CODE_RELEASE
ARG BUILD_DATE
ARG VERSION
LABEL build_version="release:- ${CODE_RELEASE} version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# environment settings
ENV HOME="/config"

# setup code sever
RUN \
 apt-get update && \
 apt-get install -y \
        git \
        nano \
        net-tools \
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

# setup python
RUN \
 apt-get update && \
 apt-get install -y \
        unzip \
        python3 \
        python3-pip \
        python-virtualenv \
        python-setuptools && \
 pip3 install -U \
        pip \
        setuptools \
        virtualenv

# setup ngrok tool
RUN curl -o /tmp/ngrok.zip -L "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip" && \
    unzip /tmp/ngrok.zip -d /usr/bin/ && \
    rm -rf \
        /tmp/*

# setup az tool
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg
    
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null && \
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
            tee /etc/apt/sources.list.d/azure-cli.list && \
                apt-get update && \
                apt-get install -y azure-cli

# setup docker cli
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
        apt-get update && \
        apt-get install -y docker-ce-cli

# install VSCode extensions
RUN mkdir -p /${HOME}/extensions && \
    apt-get update && apt-get install -y bsdtar curl && \
        curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/2019.11.50794/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/ms-python.python-2019.11.50794 && \
        curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/shardulm94/vsextensions/trailing-spaces/0.3.1/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/shardulm94.trailing-spaces-0.3.1 && \
        curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/njpwerner/vsextensions/autodocstring/0.4.0/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/njpwerner.autodocstring-0.4.0 && \
        curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-azuretools/vsextensions/vscode-docker/0.9.0/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/ms-azuretools.vscode-docker-0.9.0

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
