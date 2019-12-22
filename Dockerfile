FROM consol/ubuntu-xfce-vnc
## Custom Dockerfile FROM consol/centos-xfce-vnc
	
# set version label
ARG CODE_RELEASE=2.1692-vsc1.39.2

# environment settings
ENV HOME="/headless"

# Switch to root user to install additional software
USER 0

## Install a gedit
RUN \
 apt-get update && \
 apt-get install -y \
	git \
	nano \
	net-tools \
	python3 \
	python3-pip \
	python-virtualenv \
	python-setuptools \
        zip \
        unzip \
        jq \
        wget \
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
	pip \
	setuptools \
	virtualenv

# setup ngrok tool (requires unzip)
RUN curl -o /tmp/ngrok.zip -L "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip" && \
    unzip /tmp/ngrok.zip -d /usr/bin/ && \
    rm -rf \
        /tmp/*

# setup az tool
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
		
RUN echo "/dockerstartup/vnc_startup.sh $@" >> /dockerstartup/entrypoint.sh
RUN chmod a+x /dockerstartup/entrypoint.sh
	
## switch back to default user
USER 1000

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "/dockerstartup/entrypoint.sh /usr/bin/code-server --port 8443 --auth none --disable-telemetry --disable-updates --user-data-dir ${HOME}/data --extensions-dir ${HOME}/extensions ${HOME}/workspace"]

