FROM ubuntu:jammy

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get update --yes
RUN apt-get install --yes \
  curl \
	git \
	sudo \
	vim \
	wget 
RUN rm -rf /var/lib/apt/lists/*

ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}
