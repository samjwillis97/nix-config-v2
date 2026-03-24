{
  pkgs,
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

    agentsmd = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Markdown file to be used as agents in opencode config.";
    };

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

    prompts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Custom prompts to be used from opencode config. Should be file paths of text files";
    };

    skills = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Custom skills to be used from opencode config. Each skill should be a directory containing a SKILL.md file";
    };
  };

  config = (
    mkIf cfg.enable (mkMerge [
      {
        programs.opencode.enable = true;
      }
      (mkIf (builtins.isNull (cfg.agentsmd) == false) {
        programs.opencode.rules = cfg.agentsmd;
      })
      {
        home.file.".config/opencode/opencode.json".text = builtins.toJSON (
          cfg.settings
          // {
            "$schema" = "https://opencode.ai/config.json";
          }
        );

        home.activation.opencode-plugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          rm -rf $HOME/.config/opencode/plugin
          mkdir -p $HOME/.config/opencode/plugins
          rm -f $HOME/.config/opencode/plugins/*
          ${concatMapStringsSep "\n" (plugin: ''
            cp ${plugin} $HOME/.config/opencode/plugins/
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
          strip_nix_hash() {
            if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
          }
          mkdir -p $HOME/.config/opencode/agent
          rm -f $HOME/.config/opencode/agent/*
          ${concatMapStringsSep "\n" (agent: ''
            agent_name=$(strip_nix_hash "$(basename "${agent}")")
            cp "${agent}" "$HOME/.config/opencode/agent/$agent_name"
          '') cfg.agents}
        '';

        home.activation.opencode-prompts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          strip_nix_hash() {
            if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
          }
          mkdir -p $HOME/.config/opencode/prompts
          rm -f $HOME/.config/opencode/prompts/*
          ${concatMapStringsSep "\n" (prompt: ''
            prompt_name=$(strip_nix_hash "$(basename "${prompt}")")
            cp "${prompt}" "$HOME/.config/opencode/prompts/$prompt_name"
          '') cfg.prompts}
        '';

        home.activation.opencode-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          strip_nix_hash() {
            if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
          }
          mkdir -p $HOME/.config/opencode/skills
          chmod -R u+w $HOME/.config/opencode/skills 2>/dev/null || true
          rm -rf $HOME/.config/opencode/skills/*
          ${concatMapStringsSep "\n" (skill: ''
            skill_name=$(strip_nix_hash "$(basename "${skill}")")
            ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw "${skill}/" "$HOME/.config/opencode/skills/$skill_name/"
          '') cfg.skills}
        '';
      }
    ])
  );
}
