FROM nixos/nix:2.14.0

RUN nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
RUN nix-channel --update

# Install baseline packages
RUN nix-env -iA \
    nixpkgs.curl \
    nixpkgs.git \
    nixpkgs.wget \

RUN nix-shell '<home-manager>' -A install

# Run as
USER root
