{ super, config, pkgs, lib, flake, ... }:
let
  homeDirectory = if super.meta.isDarwin then
    "/Users/${super.meta.username}"
  else
    "/home/${super.meta.username}";

  initExtra = with config.theme.colors; ''
    export PATH="$PATH:${homeDirectory}/.dotnet/tools"
    export PATH="$PATH:${homeDirectory}/go/bin"
    export PATH="$PATH:${homeDirectory}/.local/bin"

    # alias nvim="nix run github:samjwillis97/neovim-flake --"

    bindkey -s ^f "tmux-sessionizer\n"

    export CDPATH="$CDPATH:../:../../"

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

    syntaxHighlighting.enable = true;
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
      cat = "${pkgs.bat}/bin/bat";
      cp = "${pkgs.rsync}/bin/rsync -ah --progress";
      count-file-watchers = ''
        find /proc/*/fd -user "$USER" -lname anon_inode:inotify -printf "%hinfo/%f\n" 2>/dev/null | xargs cat | grep -c "^inotify"
      '';
      untar = "tar -zxvf";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "sudo" "git" "docker-compose" "cp" ];
      theme = "ys";
    };
  };

  programs = {
    dircolors.enable = true;
    direnv = {
      # TODO: Change cache location
      # TODO: Set the variable for this https://github.com/direnv/direnv/pull/1234
      enable = true;
      # silent = true;
      nix-direnv.enable = true;
    };
    fzf = { enable = true; };
  };
}
