{ config, pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    colorSchemes = {
      base16 = with config.theme.colors; {
        ansi = [
          base00
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base05
        ];
        brights = [
          base03
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base05
        ];
        background = base00;
        cursor_bg = base06;
        cursor_border = base06;
        cursor_fg = base00;
        foreground = base05;
        selection_bg = base06;
        selection_fg = base00;
      };
    };
    enableZshIntegration = true;
    # `text_background_opacity` effects the background colors of neovim
    extraConfig = ''
      wezterm.on('increase-opacity', function(window, pane)
        local overrides = window:get_config_overrides() or {}
        local config = window:effective_config() or {}
        overrides.window_background_opacity = config.window_background_opacity + 0.025
        window:set_config_overrides(overrides)
      end)

      wezterm.on('decrease-opacity', function(window, pane)
        local overrides = window:get_config_overrides() or {}
        local config = window:effective_config() or {}
        overrides.window_background_opacity = config.window_background_opacity - 0.025
        window:set_config_overrides(overrides)
      end)

      return {
        keys = {
          {
            key = ']',
            mods = 'CTRL',
            action = wezterm.action.EmitEvent 'increase-opacity',
          },
          {
            key = '[',
            mods = 'CTRL',
            action = wezterm.action.EmitEvent 'decrease-opacity',
          },
        },
        font = wezterm.font("FiraCode Nerd Font Mono"),
        hide_tab_bar_if_only_one_tab = true,
        color_scheme = "base16",
        text_background_opacity = 1,
        window_background_opacity = 0.85,
        macos_window_background_blur = 15,
        window_decorations = "RESIZE",
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
        front_end = "WebGpu"
      }
    '';
  };
}
