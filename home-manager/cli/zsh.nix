{ super, config, pkgs, lib, flake, ... }:
let
  homeDirectory = if super.meta.isDarwin then
    "/Users/${super.meta.username}"
  else
    "/home/${super.meta.username}";

  initExtra = with config.theme.colors; ''
    export PATH="$PATH:${homeDirectory}/.dotnet/tools"
    export PATH="$PATH:${homeDirectory}/go/bin"
    export MONGOMS_SYSTEM_BINARY=/etc/profiles/per-user/${super.meta.username}/bin/mongod
    export OMNISHARP_DIR=${pkgs.omnisharp-roslyn}/lib/omnisharp-roslyn/
    # alias nvim="nix run github:samjwillis97/neovim-flake --"

    bindkey -s ^f "tmux-sessionizer\n"

    # for ZSH
    # for BASH use $(which git) instead of whence
    function do_git {
      cmd=$1

      if [ -n "$cmd" ]; then
          shift
          extra=""

          if [ "$cmd" '==' "blame" ]; then
            cmd="blamer"
          fi

          to_run="`whence -p git`"
          if [ -n "$cmd" ]; then
              to_run="$to_run $cmd"
          fi
          if [ -n "$extra" ]; then
              to_run="$to_run $extra"
          fi

          eval "$to_run $@" else "`whence -p git`"
      fi
    }

    export FZF_DEFAULT_OPTS=" \
        --color=bg+:${base02},bg:${base00},spinner:${base06},hl:${base08} \
        --color=fg:${base05},header:${base08},info:${base0E},pointer:${base06} \
        --color=marker:${base06},fg+:${base05},prompt:${base0E},hl+:${base08}"
  '';
in {
  home.packages = with pkgs; [ bat rsync gnutar ];

  programs.zsh = {
    inherit initExtra;

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
      git = "do_git";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "sudo" "git" "docker" "docker-compose" "cp" ];
      theme = "ys";
    };
  };

  programs = {
    dircolors.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fzf = { enable = true; };
  };
}
