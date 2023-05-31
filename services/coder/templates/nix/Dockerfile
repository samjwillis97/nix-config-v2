FROM nixos/nix:2.14.0

RUN nix-channel --update

# Install baseline packages
RUN nix-env -iA \
    nixpkgs.curl \
    nixpkgs.git \
    nixpkgs.wget \

# Run as
USER root
