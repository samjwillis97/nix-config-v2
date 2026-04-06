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

    sandbox = {
      allowedPackages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          coreutils
          which
          git
          ripgrep
          fd
          gnused
          gnugrep
          findutils
          jq
          nodejs
        ];
        description = "Base set of packages available inside all sandboxes. Shared across backends.";
      };

      extraAllowedPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional packages available inside all sandboxes, appended to allowedPackages.";
      };

      extraStateDirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional writable directories shared across all sandboxes. Merged with per-backend extraStateDirs.";
      };

      extraStateFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional writable files shared across all sandboxes. Merged with per-backend extraStateFiles.";
      };

      extraEnv = mkOption {
        type = types.attrsOf types.str;
        default = {
          GITHUB_TOKEN = "$GITHUB_TOKEN";
        };
        description = ''
          Environment variables shared across all sandboxes.
          Use shell variable references (e.g. "$TOKEN") for secrets so they expand
          at runtime and stay out of the /nix/store.
          Includes GITHUB_TOKEN by default for git remote access.
        '';
      };

      restrictNetwork = mkOption {
        type = types.bool;
        default = false;
        description = "When true, network is limited to allowedDomains for all sandboxes.";
      };

      allowedDomains = mkOption {
        type = types.attrsOf (types.either types.str (types.listOf types.str));
        default = { };
        description = ''
          Domains the sandbox can reach when restrictNetwork = true.
          Map domain to "*" (all methods) or a list of HTTP methods (e.g. ["GET" "HEAD"]).
          Domains are suffix-matched, so "anthropic.com" captures *.anthropic.com.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.sandbox.restrictNetwork || cfg.sandbox.allowedDomains != { };
        message = "modules.ai-coding.sandbox: restrictNetwork is true but no allowedDomains are defined. All network traffic will be blocked.";
      }
    ];
  };
}
