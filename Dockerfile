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
 echo "adding default to sudoers" && \
 echo "default ALL=(ALL:ALL) ALL" >> /etc/sudoers && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*
	
RUN pip3 install -U \
	pip \
	setuptools \
	virtualenv

RUN mkdir -p ${HOME}/{extensions,data,workspace,.ssh}
RUN echo "/usr/bin/code-server --port 8443 --disable-telemetry --disable-updates --user-data-dir ${HOME}/data --extensions-dir ${HOME}/extensions ${HOME}/workspace" >> /dockerstartup/entrypoint.sh
RUN echo "/dockerstartup/vnc_startup.sh --wait" >> /dockerstartup/entrypoint.sh
RUN chown default /dockerstartup/entrypoint.sh
RUN chmod a+x /dockerstartup/entrypoint.sh
	
## switch back to default user
USER 1000

# ports and volumes
EXPOSE 80 8443 5901 6901 8501

ENTRYPOINT ["/dockerstartup/entrypoint.sh"]

