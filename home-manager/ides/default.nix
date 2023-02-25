{ pkgs, ... }:
{
    home.packages = with pkgs; [
        jetbrains.webstorm
        jetbrains.rider
        jetbrains.pycharm-professional
        jetbrains.goland
        jetbrains.gateway
        vscodium
    ];

    # TODO: .idea config
}
