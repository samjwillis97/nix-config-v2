{ pkgs, ... }:
{
  home.packages = with pkgs; [ 
    deploy-rs

    # Nix tools under testing
    nox
    nix-output-monitor
    nvd
    nh
  ];
}
