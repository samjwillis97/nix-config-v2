{
  # See: https://github.com/NixOS/nix/issues/7273
  auto-optimise-store = false;
  trusted-users = [
    "root"
    "@wheel"
  ];
  experimental-features = [
    "nix-command"
    "flakes"
  ];
}
