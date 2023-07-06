FROM ubuntu:jammy

RUN useradd ampcontrol \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
	mkdir -p /etc/sudoers.d && \
    echo "ampcontrol ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd && \
	groupadd docker && \
	usermod -aG docker ampcontrol 

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
    curl vim

# Install Nix
RUN addgroup --system nixbld \
  && adduser ampcontrol nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown ampcontrol /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf

CMD /bin/bash -l
USER ampcontrol 
ENV USER ampcontrol
WORKDIR /home/ampcontrol

RUN touch .bash_profile && touch .bashrc \
 && curl https://nixos.org/releases/nix/nix-2.9.2/install | sh

RUN . /home/ampcontrol/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA cachix -f https://cachix.org/api/v1/install \
  && cachix use cachix

  # Install direnv
RUN . /home/ampcontrol/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA nixpkgs.direnv \
  && direnv hook bash >> /home/ampcontrol/.bashrc

# Install devenv
RUN . /home/ampcontrol/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA cachix -f https://cachix.org/api/v1/install \
  && cachix use devenv

# Start SSH service
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]

# Run as
USER ampcontrol
