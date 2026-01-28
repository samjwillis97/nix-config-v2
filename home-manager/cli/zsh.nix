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
    export PATH="$PATH:${homeDirectory}/.npm-packages/bin"

    # alias nvim="nix run github:samjwillis97/neovim-flake --"

    bindkey -s ^f "${pkgs.f}/bin/f -l\n\n"

    export CDPATH="$CDPATH:../:../../"

    export FZF_DEFAULT_OPTS=" \
        --color=bg+:${base02},bg:${base00},spinner:${base06},hl:${base08} \
        --color=fg:${base05},header:${base08},info:${base0E},pointer:${base06} \
        --color=marker:${base06},fg+:${base05},prompt:${base0E},hl+:${base08}"

    # See: https://discourse.nixos.org/t/brew-not-on-path-on-m1-mac/26770/4
    # Cache brew shellenv to avoid repeated subprocess calls
    ${
      if (super.meta.isDarwin) then
        ''
          if [[ ! -f ~/.cache/brew_shellenv.zsh ]] || [[ /opt/homebrew/bin/brew -nt ~/.cache/brew_shellenv.zsh ]]; then
            mkdir -p ~/.cache
            /opt/homebrew/bin/brew shellenv > ~/.cache/brew_shellenv.zsh
          fi
          source ~/.cache/brew_shellenv.zsh
        ''
      else
        ""
    }

    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi

    # Seems to be a problem once I removed oh-mh-zsh, delete key would enter a ~
    bindkey "^[[3~" delete-char

    # better history completion
    autoload -U up-line-or-beginning-search
    autoload -U down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey "^[[A" up-line-or-beginning-search
    bindkey "^[[B" down-line-or-beginning-search

    source ${p10kTheme}
  '';

  completionInit = ''
    # Optimized compinit with caching
    autoload -Uz compinit
    setopt EXTENDEDGLOB

    # Only regenerate compdump once per day
    local zcompdump="${homeDirectory}/.zcompdump"
    if [[ -n $zcompdump(#qNmh+24) ]]; then
      compinit -u -d "$zcompdump"  # -u skips security check
    else
      compinit -C -d "$zcompdump"  # -C skips both check and regeneration
    fi

    unsetopt EXTENDEDGLOB
  '';
in
# Disabling shc whilst doing some development
# . <(${pkgs.shc-cli}/bin/shc-cli --completion)
{
  home.packages = with pkgs; [
    bat
    rsync
    gnutar
    f
  ];

  programs.zsh = {
    initContent = initExtra;

    enable = true;

    zprof.enable = false;

    # Syntax highlighting enabled - the brew caching and p10k instant prompt
    # provide most of the speedup
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    completionInit = completionInit;

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
      enable = false;
      plugins = [
        "git"
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
        warn_timeout = "30s"; # Reduce timeout overhead
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
