{ pkgs, ... }:
{
    home.packages = with pkgs; [
        rustc
        rustfmt
        rust-analyzer
        cargo
    ];
}
