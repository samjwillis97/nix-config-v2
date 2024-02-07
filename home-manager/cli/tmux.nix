{ config, pkgs, lib, flake, ... }:
# TODO: Auto Reconnect
{
  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    package = pkgs.tmux;

    aggressiveResize = true;
    baseIndex = 1;
    historyLimit = 10000;
    newSession = false;

    prefix = "C-b";
    terminal = "screen-256color";

    extraConfig = with config.theme.colors; ''

      # Better splitting
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      set-window-option -g mode-keys vi
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

      # Better sessions
      bind-key -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"
      bind-key -r i run-shell "tmux neww tmux-cht.sh"

      # Enabled 256 Color
      set -g default-terminal "tmux-256color"
      set-option -ga terminal-overrides ',xterm-256color:Tc'

      # Enable scrolling
      set -g mouse on

      # Fix switching delay
      set -sg escape-time 0

      # easy reload
      bind-key r source-file ~/.tmux.conf \; display-message "~/.tmux.conf reloaded"


      thm_bg="${base00}"
      thm_fg="${base05}"
      thm_cyan="${base0C}"
      thm_black="${base00}"
      thm_gray="${base02}"
      thm_magenta="${base0E}"
      thm_pink="${base0F}"
      thm_red="${base08}"
      thm_green="${base0B}"
      thm_yellow="${base0A}"
      thm_blue="${base0D}"
      thm_orange="${base09}"
      thm_black4="${base04}"

      # ----------------------------=== Theme ===--------------------------
      # status
      set-option -gq status "on"
      set-option -gq status-bg "''${thm_bg}"
      set-option -gq status-justify "left"
      set-option -gq status-left-length "100"
      set-option -gq status-right-length "100"

      # messages
      set-option -gq message-style "fg=''${thm_cyan},bg=''${thm_gray},align=centre"
      set-option -gq message-command-style "fg=''${thm_cyan},bg=''${thm_gray},align=centre"

      # panes
      set-option -gq pane-border-style "fg=''${thm_gray}"
      set-option -gq pane-active-border-style "fg=''${thm_blue}"

      # windows
      set-window-option -gq window-status-activity-style "fg=''${thm_fg},bg=''${thm_bg},none"
      set-window-option -gq window-status-separator ""
      set-window-option -gq window-status-style "fg=''${thm_fg},bg=''${thm_bg},none"

      # --------=== Statusline

      set-option -gq status-left ""
      set-option -gq status-right "#[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics] #[fg=$thm_fg,bg=$thm_gray] #W #{?client_prefix,#[fg=$thm_red],#[fg=$thm_green]}#[bg=$thm_gray]#{?client_prefix,#[bg=$thm_red],#[bg=$thm_green]}#[fg=$thm_bg] #[fg=$thm_fg,bg=$thm_gray] #S "

      # current_dir
      set-window-option -gq window-status-format "#[fg=$thm_bg,bg=$thm_blue] #I #[fg=$thm_fg,bg=$thm_gray] #{b:pane_current_path} "
      set-window-option -gq window-status-current-format "#[fg=$thm_bg,bg=$thm_orange] #I #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} "

      # --------=== Modes
      set-window-option -gq clock-mode-colour "''${thm_blue}"
      set-window-option -gq mode-style "fg=''${thm_pink} bg=''${thm_black4} bold"

      # Pane number display
      set-option -g display-panes-active-colour colour33
      set-option -g display-panes-colour colour166

    '';
  };
}
