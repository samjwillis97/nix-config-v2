{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types mkIf;
  aiTypes = import ./types.nix { inherit lib; };
  cfg = config.modules.ai-coding;
in
{
  imports = [
    ./backends/opencode.nix
    ./backends/claude.nix
  ];

  options.modules.ai-coding = {
    enable = mkEnableOption "AI coding tools abstraction layer";

    rules = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to system prompt / instructions markdown file. Deployed as AGENTS.md (OpenCode) and CLAUDE.md (Claude).";
    };

    agents = mkOption {
      type = types.attrsOf aiTypes.agent;
      default = { };
      description = "Agent definitions. Keys become agent filenames.";
    };

    skills = {
      local = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Local skill directories (each must contain a SKILL.md).";
      };

      sources = mkOption {
        type = types.listOf aiTypes.skillSource;
        default = [ ];
        description = "External skill sources from flake inputs.";
      };
    };

    commands = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Command markdown files. Deployed as commands (OpenCode) and skills (Claude).";
    };

    permissions = mkOption {
      type = aiTypes.permissionSet;
      default = { };
      description = "Shared permission rules. Per-tool map of patterns to allow/ask/deny.";
    };

    mcpServers = mkOption {
      type = types.attrsOf aiTypes.mcpServer;
      default = { };
      description = "MCP server definitions shared across backends.";
    };

    modelAliases = mkOption {
      type = types.attrsOf aiTypes.modelAlias;
      default = { };
      description = "Model alias -> per-tool model ID mapping.";
    };
  };
}
