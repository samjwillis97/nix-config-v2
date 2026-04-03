# hm-modules/ai-coding/types.nix
{ lib }:
let
  inherit (lib) mkOption types;
in
{
  # Permission action: allow, ask, or deny
  permissionAction = types.enum [ "allow" "ask" "deny" ];

  # Permission rule: either a blanket action or a map of patterns -> actions
  permissionRule = types.either
    (types.enum [ "allow" "ask" "deny" ])
    (types.attrsOf (types.enum [ "allow" "ask" "deny" ]));

  # Permission set: map of tool names -> permission rules
  permissionSet = types.attrsOf (types.either
    (types.enum [ "allow" "ask" "deny" ])
    (types.attrsOf (types.enum [ "allow" "ask" "deny" ])));

  # MCP server definition
  mcpServer = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "stdio" "http" "sse" "ws" ];
        description = "Transport type. stdio = local process, http/sse/ws = remote.";
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Executable path for stdio servers.";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments for the command.";
      };
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL for http/sse/ws servers.";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables. Mapped to 'environment' for OpenCode.";
      };
      headers = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "HTTP headers for remote servers.";
      };
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether this server is enabled. OpenCode respects this field; Claude omits disabled servers.";
      };
      oauth = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "OAuth configuration (OpenCode-only, skipped by Claude backend).";
      };
    };
  };

  # Agent definition
  agent = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        description = "Short description of what this agent does.";
      };
      instructions = mkOption {
        type = types.path;
        description = "Path to markdown file containing agent instructions.";
      };
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model alias (e.g. 'sonnet'). Resolved per-backend via modelAliases.";
      };
      color = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent color in the UI.";
      };
      permissions = mkOption {
        # Inline the permissionSet type to avoid circular reference
        type = types.attrsOf (types.either
          (types.enum [ "allow" "ask" "deny" ])
          (types.attrsOf (types.enum [ "allow" "ask" "deny" ])));
        default = { };
        description = "Per-tool permission rules for this agent.";
      };
      tools = mkOption {
        type = types.nullOr (types.attrsOf types.bool);
        default = null;
        description = "Tool availability map. null = all tools available. { \"*\" = false; bash = true; } = only bash.";
      };
      opencode = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Extra fields merged into OpenCode agent frontmatter.";
      };
      claude = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Extra fields merged into Claude agent frontmatter.";
      };
    };
  };

  # Skill source (external flake input)
  skillSource = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name for this skill source (used for dedup logging).";
      };
      src = mkOption {
        type = types.path;
        description = "Flake input path containing skills.";
      };
      path = mkOption {
        type = types.str;
        default = "skills";
        description = "Subdirectory within src containing skill directories.";
      };
      exclude = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Skill names to skip from this source.";
      };
      include = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "If set, ONLY include these skill names. null = all.";
      };
    };
  };

  # Model alias mapping
  modelAlias = types.submodule ({ name, ... }: {
    options = {
      opencode = mkOption {
        type = types.str;
        description = "Full provider/model-id for OpenCode (e.g. 'anthropic/claude-sonnet-4-20250514').";
      };
      claude = mkOption {
        type = types.str;
        default = name;
        description = "Model identifier for Claude. Defaults to the alias key name.";
      };
    };
  });
}
