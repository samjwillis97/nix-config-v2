FROM ubuntu

RUN apt-get update && apt-get update --yes
RUN apt-get install --yes sudo

ARG USER=coder
RUN useradd --groups sudo --create-home --shell /bin/bash ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}

# ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get install --yes \
  curl \
	git \
	vim \
  xz-utils \
	wget && \
	# Delete package cache to avoid consuming space in layer
	apt-get clean
RUN rm -rf /var/lib/apt/lists/*

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

RUN echo "experimental-features = nix-command flakes" >> /home/${USER}/.config/nix/nix.conf

RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
  -t ys \
  -p git \
  -p ssh-agent \
  -p https://github.com/zsh-users/zsh-autosuggestions \
  -p https://github.com/zsh-users/zsh-completions

RUN mkdir -p /home/${USER}/.ssh && touch /home/${USER}/.ssh/known_hosts && ssh-keygen -R bitbucket.org && curl https://bitbucket.org/site/ssh >> /home/${USER}/.ssh/known_hosts
RUN echo "eval \"\$(direnv hook zsh)\"" >> /home/${USER}/.zshrc

# Run as
USER ${USER}
ENTRYPOINT [ "/usr/bin/zsh" ]

