{ pkgs, ... }:
{
    home.packages = with pkgs; [
        rustc
        git
        rustfmt
        rust-analyzer
    ];
}
