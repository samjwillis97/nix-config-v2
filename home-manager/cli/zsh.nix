{ config, pkgs, lib, flake, ... }:
{
    # TODO: 
    #   - Tmux Sessionizer
    #   - Direnv hook
    #   - Bash aliases

    home.packages = with pkgs; [
        bat
    ];

    programs.zsh = {
        enable = true;

        enableSyntaxHighlighting = true;
        enableCompletion = true;

        history = {
            extended = true;
            save = 20000;
            size = 20000;
            share = true;
        };

        shellAliases = {
            cat = "bat";
        };

        oh-my-zsh = {
            enable = true;
            plugins = [
                "sudo"
                "git"
                "docker"
                "docker-compose"
                "cp"
            ];
            theme = "ys";
        };

    };
}
