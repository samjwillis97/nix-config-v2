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

# Install Nix
RUN addgroup --system nixbld \
  && adduser ${USER} nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown ${USER} /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf
CMD /bin/bash -l

USER ${USER}
ENV USER ${USER}
WORKDIR /home/${USER}

RUN touch .bash_profile && touch .bashrc \
 && curl https://nixos.org/releases/nix/nix-2.9.2/install | sh

RUN . /home/${USER}/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA cachix -f https://cachix.org/api/v1/install \
  && cachix use cachix

  # Install direnv
RUN . /home/${USER}/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA nixpkgs.direnv \
  && direnv hook bash >> /home/${USER}/.bashrc

# Install devenv
RUN . /home/${USER}/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA cachix -f https://cachix.org/api/v1/install \
  && cachix use devenv

# Run as
USER ${USER}

