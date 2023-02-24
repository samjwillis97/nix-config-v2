{ config, pkgs, lib, flake, ... }:
{
    # TODO: 
    #   - Tmux Sessionizer

    home.packages = with pkgs; [
        bat
        rsync
        gnutar
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
            l = "ls -l";
            ll = "ls -alFh";
            lt = "ls --human-readable --size -1 -S --classify";
            cat = "bat";
            cp = "rsync -ah --info=progress2";
            count-file-watchers = ''
                find /proc/*/fd -user "$USER" -lname anon_inode:inotify -printf "%hinfo/%f\n" 2>/dev/null | xargs cat | grep -c "^inotify"
            '';
            untar = "tar -zxvf";
        };

        initExtra = with config.theme.colors; ''
            export FZF_DEFAULT_OPTS=" \
                --color=bg+:${base02},bg:${base00},spinner:${base06},hl:${base08} \
                --color=fg:${base05},header:${base08},info:${base0E},pointer:${base06} \
                --color=marker:${base06},fg+:${base05},prompt:${base0E},hl+:${base08}"
        '';

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

    programs = {
        dircolors.enable = true;
        direnv = {
            enable = true;
            nix-direnv.enable = true;
        };
        fzf = {
            enable = true;
        };
    };
}
