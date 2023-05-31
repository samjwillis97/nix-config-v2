
FROM ubuntu:jammy

RUN useradd sam \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
	mkdir -p /etc/sudoers.d && \
    echo "sam ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd && \
	groupadd docker && \
	usermod -aG docker sam

# Install packages from apt repositories
ARG DEBIAN_FRONTEND="noninteractive"

# Update ubuntu
RUN apt-get update && apt-get upgrade --yes

# Install Docker
RUN apt-get install --yes \
	  debconf ca-certificates curl gnupg lsb-release software-properties-common && \
    mkdir -m 0755 -p /etc/apt/keyrings && \
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  	apt-get update && apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
	# Delete package cache to avoid consuming space in layer
	apt-get clean

RUN apt-get install --yes \
	apt-transport-https \
	apt-utils \
	bash \
	bind9-dnsutils \
	build-essential \
	ca-certificates \
	cmake \
	curl \
	fd-find \
	file \
	git \
	gnupg \
	language-pack-en \
	less \
	lsb-release \
	man \
	meld \
	openssh-server \
	openssl \
	pkg-config \
	python3 \
	python3-pip \
	rsync \
	strace \
	sudo \
	wget \
	zip \
	unzip

# Install Nix
RUN addgroup --system nixbld \
  && adduser sam nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown sam /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf

CMD /bin/bash -l
USER sam 
ENV USER sam
WORKDIR /home/sam

RUN touch .bash_profile \
 && curl https://nixos.org/releases/nix/nix-2.9.2/install | sh

RUN . /home/sam/.nix-profile/etc/profile.d/nix.sh \
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
RUN . /home/sam/.nix-profile/etc/profile.d/nix.sh \
    nix-channel --update

RUN . /home/sam/.nix-profile/etc/profile.d/nix.sh \
    nix-shell '<home-manager>' -A install

RUN echo '. /home/sam/.nix-profile/etc/profile.d/hm-session-vars.sh' >> /home/sam/.bashrc

# Start SSH service
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]

# Run as
USER sam
