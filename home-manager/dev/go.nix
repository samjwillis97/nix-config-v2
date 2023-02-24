{ pkgs, ... }:
{
    home.packages = with pkgs; [
        go
        go-outline
        go-tools
        gopls
        golangci-lint
    ];
}
