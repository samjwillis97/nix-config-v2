# AI coding

Home Manager module for managing AI coding tool configuration declaratively.

---

## Enable

Import the module and set `modules.ai-coding.enable = true` in your Home Manager configuration.

```nix
imports = [ ./path/to/hm-modules/ai-coding ];

modules.ai-coding = {
  enable = true;
  backends.opencode.enable = true;
  backends.claude.enable = true;
};
```

---

## Configure backends

Each backend (OpenCode, Claude Code) is opt-in via its own `enable` flag. Backend-specific settings can be set under `backends.opencode` or `backends.claude`.

```nix
modules.ai-coding.backends.opencode = {
  enable = true;
  extraSettings = { tui.vim = true; };
};

modules.ai-coding.backends.claude = {
  enable = true;
  extraSettings = { preferredNotifChannel = "terminal"; };
};
```

---

## Add agents

Agents are defined as attribute sets with a description and a path to a markdown instructions file. They are compiled to per-backend markdown files with YAML frontmatter on activation.

```nix
modules.ai-coding.agents = {
  my-agent = {
    description = "Does something useful.";
    instructions = ./agents/my-agent.md;
    tools = { "*" = false; bash = true; read = true; };
    permissions = { webfetch = "deny"; };
  };
};
```

---

## Set permissions

`permissions` is a shared per-tool map of patterns to `allow`, `ask`, or `deny`. Both string (blanket) and attrset (pattern-based) values are accepted.

```nix
modules.ai-coding.permissions = {
  webfetch = "deny";
  bash = {
    "*" = "ask";
    "git*" = "allow";
  };
};
```

Backend-specific overrides go in `backends.opencode.extraPermissions` or `backends.claude.extraPermissions`.

---

## Add MCP servers

MCP servers defined under `mcpServers` are shared across both backends. Use `type = "stdio"` for local processes and `type = "http"` (or `sse`/`ws`) for remote endpoints.

```nix
modules.ai-coding.mcpServers.my-server = {
  type = "stdio";
  command = "${pkgs.my-mcp-server}/bin/my-mcp-server";
  args = [ "--flag" ];
  env = { MY_TOKEN = "$MY_TOKEN"; };
};
```

Backend-specific servers go in `backends.opencode.extraMcpServers` or `backends.claude.extraMcpServers`. Use `disabledMcpServers` on a backend to exclude shared servers.

---

## Manage skills

Local skill directories (each must contain a `SKILL.md`) are listed under `skills.local`. External skills from flake inputs go in `skills.sources`.

```nix
modules.ai-coding.skills = {
  local = [ ./skills/my-skill ];
  sources = [
    {
      name = "superpowers";
      src = flake.inputs.superpowers;
      exclude = [ "some-skill" ];
    }
  ];
};
```

---

## Add commands

Command markdown files are deployed as OpenCode commands and as Claude skills. Pass a list of paths to `.md` files.

```nix
modules.ai-coding.commands = [ ./commands/my-command.md ];
```

---

## Use model aliases

Define aliases that map a short name to backend-specific model identifiers. Reference the alias name in agent definitions via `model`.

```nix
modules.ai-coding.modelAliases.sonnet = {
  opencode = "anthropic/claude-sonnet-4-20250514";
  claude = "claude-sonnet-4-20250514";
};
```

---

## Enable sandboxing

Each backend can be run as a sandboxed binary that restricts filesystem and network access. Enable it and add any extra packages or state paths your workflow requires.

```nix
modules.ai-coding.backends.opencode.sandbox.enable = true;

modules.ai-coding.sandbox = {
  extraAllowedPackages = with pkgs; [ gh jq ];
  extraStateDirs = [ "$HOME/.config/my-tool" ];
  extraEnv = { MY_SECRET = "$MY_SECRET"; };
  restrictNetwork = true;
  allowedDomains = { "api.anthropic.com" = "*"; };
};
```

The sandboxed binaries are installed alongside the originals as `opencode-sandboxed` and `claude-sandboxed`.
