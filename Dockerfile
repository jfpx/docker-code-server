FROM consol/ubuntu-xfce-vnc
## Custom Dockerfile FROM consol/centos-xfce-vnc
	
# set version label
ARG CODE_RELEASE=2.1692-vsc1.39.2

# environment settings
ENV HOME="/headless"

# Switch to root user to install additional software
USER 0

 
## install other tools
RUN \
 apt-get update && \
 apt-get install -y \
        xarchiver \
	git \
	kate \
	nano \
	net-tools \
	python3 \
	python3-pip \
	python-virtualenv \
	python-setuptools \
	curl \
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
 echo "adding ubuntu to sudoers" && \
 adduser --disabled-password --gecos '' --uid 1000 default && \
 adduser default sudo && \
 echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*
	
RUN pip3 install -U \
	requests \
	pip \
	setuptools \
	virtualenv

# setup ngrok tool (requires unzip)
RUN apt-get update && \
 apt-get install -y \
        unzip && \
 curl -o /tmp/ngrok.zip -L "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip" && \
    unzip /tmp/ngrok.zip -d /usr/bin/ && \
    rm -rf \
        /tmp/*

# setup az tool
RUN apt-get update && \
  apt-get install -y \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg && \
 curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null && \
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
            tee /etc/apt/sources.list.d/azure-cli.list && \
                apt-get update && \
                apt-get install -y azure-cli

## Install python3.7 with 3.5 side by side
RUN \
 apt update && \
 apt install -y software-properties-common && \
 add-apt-repository -y ppa:deadsnakes/ppa && \
 apt update && \
 apt install -y python3.7  
 #&& \
 #update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 && \
 #update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 2 && \
 #echo 2 | update-alternatives --config python3
RUN \
 python3.7 -m pip install -U pip
 
# setup vscode extension unzip tool
RUN apt-get update && \
 add-apt-repository universe && \
 #apt install -y fonts-firacode && \
 apt-get install -y \
	bsdtar \
	jq \
	unzip
	
# install VSCode extensions
RUN mkdir -p /${HOME}/extensions && \
    curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/2019.11.50794/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/ms-python.python-2019.11.50794 && \
    curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/shardulm94/vsextensions/trailing-spaces/0.3.1/vspackage | \
                bsdtar -xvf - extension && mv extension /${HOME}/extensions/shardulm94.trailing-spaces-0.3.1

# add toolset
COPY /dockerstartup /dockerstartup
RUN chmod a+x /dockerstartup/entrypoint.sh
RUN chmod a+x /dockerstartup/ngrokserver

## switch back to default user
USER 1000

# add .vscode settings files
COPY /.vscode/settings.json ${HOME}/workspace/.vscode/settings.json

ENTRYPOINT ["/bin/bash"]
CMD ["/dockerstartup/entrypoint.sh"]

