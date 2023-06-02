{ super, lib, pkgs, ... }:
let inherit (super.meta) username;
in {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "video" "docker" ];
    shell = pkgs.zsh;
    password = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe5uIFvexscAC/HCsBwctMuoABqQ6CN7Wq8dYXSJqjAz8pFoW/kvyl5WtRa372LokUYflsyXvhWQJJWyJVwsC4JvkN44QyWLLVBlp21GCqyvILyk960hGYgiyauf96sV7w5Aq+NRibsPjK6n2PLmxt9U4Dcfg4LgX6sXKc5+rljoToXjf1DKeFcjIfIwwJXWFt2njCromt8WYQQxg0w+YL6b5Hqi5LZcYjQu+AF0AMptoTyh9J1KQQg+XZjdbM8z+vf0VRFJlBrrQHyNxgqeWhMwxipTVq1yr+henaba8Tag/iacP070RDX2qTvUqmtS0Cftt7FaW6zVK+27FHigKJPNjz/ExiWnmGCNA+t5MBz5EGfHdZRf0Vv4x82+eHkhGnigs0rBFcHDqGVSmHKld4WKzyeIyTecmXr9XcODoxR+xEhMqzw8fy3D9ZaZTalzDPDRlzONpD4J0oI8ly4N0nUn+gJzM02i6RsbrzM90CsVdCpFR2RsUZTIjc4ATKF+c= sam@AMP-8060"
    ];
  };

  programs.zsh.enable = true;
}
