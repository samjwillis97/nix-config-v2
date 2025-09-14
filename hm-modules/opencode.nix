{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "enable opencode";

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Configuration settings for opencode.";
    };

    plugins = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "List of opencode plugins to use. Should be file paths of javascript files";
    };

    agents = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "List of opencode agents to use. Should be file paths of markdown files";
    };

    commands = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Custom commands to add to opencode config. Should be file paths of markdown files";
    };
  };

  config = (
    mkIf cfg.enable (mkMerge [
      {
        home.file.".config/opencode/opencode.json".text = builtins.toJSON (
          cfg.settings
          // {
            "$schema" = "https://opencode.ai/config.json";
          }
        );

        home.activation.opencode-plugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.config/opencode/plugin
          rm -f $HOME/.config/opencode/plugin/*
          ${concatMapStringsSep "\n" (plugin: ''
            cp ${plugin} $HOME/.config/opencode/plugin/
          '') cfg.plugins}
        '';

        home.activation.opencode-commands = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.config/opencode/command
          rm -f $HOME/.config/opencode/command/*
          ${concatMapStringsSep "\n" (command: ''
            cp ${command} $HOME/.config/opencode/command/
          '') cfg.commands}
        '';

        home.activation.opencode-agents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.config/opencode/agent
          rm -f $HOME/.config/opencode/agent/*
          ${concatMapStringsSep "\n" (agent: ''
            agent_src=${agent}
            agent_bn=$(basename "$agent_src")
            agent_name=''${agent_bn#*-}
            cp "$agent_src" "$HOME/.config/opencode/agent/$agent_name"
          '') cfg.agents}
        '';
      }
    ])
  );
}
