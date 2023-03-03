{ pkgs, ... }:
{
    home.packages = with pkgs; [
        nodejs
        nodePackages.npm
        nodePackages.typescript
        nodePackages.prettier
        nodePackages.pnpm
    ];
}
