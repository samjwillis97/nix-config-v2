{
  super,
  config,
  pkgs,
  lib,
  flake,
  ...
}:
let
  homeDirectory =
    if super.meta.isDarwin then "/Users/${super.meta.username}" else "/home/${super.meta.username}";

  p10kTheme = ./zsh/p10k.zsh;

  initExtra = with config.theme.colors; ''
    setopt INC_APPEND_HISTORY   # Write to history file immediate, not on exit
    setopt HIST_SAVE_NO_DUPS    # DO no write a duplicate event
    setopt HIST_VERIFY          # Do not execute immediately
    setopt HIST_NO_STORE        # Do not store the history command
    setopt HIST_REDUCE_BLANKS   # Remove leading and trailing blanks

    export PATH="$PATH:${homeDirectory}/.dotnet/tools"
    export PATH="$PATH:${homeDirectory}/go/bin"
    export PATH="$PATH:${homeDirectory}/.local/bin"

    # alias nvim="nix run github:samjwillis97/neovim-flake --"

    bindkey -s ^f "${pkgs.f-tmux}/bin/f-fzf-tmux-wrapper\n\n"

    export CDPATH="$CDPATH:../:../../"

    export FZF_DEFAULT_OPTS=" \
        --color=bg+:${base02},bg:${base00},spinner:${base06},hl:${base08} \
        --color=fg:${base05},header:${base08},info:${base0E},pointer:${base06} \
        --color=marker:${base06},fg+:${base05},prompt:${base0E},hl+:${base08}"

    # See: https://discourse.nixos.org/t/brew-not-on-path-on-m1-mac/26770/4
    ${if (super.meta.isDarwin) then  "eval \"$(/opt/homebrew/bin/brew shellenv)\"" else ""}

    source ${p10kTheme}
  '';
in
{
  home.packages = with pkgs; [
    bat
    rsync
    gnutar
    f-tmux
  ];

  programs.zsh = {
    inherit initExtra;

    enable = true;

    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      extended = true;
      save = 1000000;
      size = 1000000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      git-silent-add = "git-silent-add() {git add --intent-to-add $1 && git update-index --skip-worktree --assume-unchanged $1 };git-silent-add";
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

    # See: https://github.com/NixOS/nixpkgs/issues/154696#issuecomment-1238433989
    plugins = [
      {
        # A prompt will appear the first time to configure it properly
        # make sure to select MesloLGS NF as the font in Konsole
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        "sudo"
        "git"
        "docker-compose"
        "cp"
      ];
      theme = "robbyrussell";
    };
  };

  programs = {
    dircolors.enable = true;
    direnv = {
      # TODO: Change cache location
      # TODO: Set the variable for this https://github.com/direnv/direnv/pull/1234
      enable = true;
      nix-direnv.enable = true;
      config = {
        hide_env_diff = true;
      };
      # stdlib = ''
      #   DIRENV_LOG_FORMAT=""
      # '';
    };
    fzf = {
      enable = true;
    };
  };
}
