# ai-coding

A home-manager module that provides a unified abstraction layer for AI coding tools (OpenCode and Claude Code), with shared configuration for agents, skills, commands, MCP servers, permissions, and sandboxing.

---

## Enable

Import the module and set `modules.ai-coding.enable = true`, then enable at least one backend:

```nix
imports = [ <path-to-repo>/hm-modules/ai-coding ];

modules.ai-coding = {
  enable = true;
  backends.opencode.enable = true;
  backends.claude.enable = true;
};
```

---

## Options

### Top-level

| Option | Type | Description |
|--------|------|-------------|
| `enable` | bool | Enable the AI coding abstraction layer |
| `rules` | path or null | Path to a markdown file deployed as `AGENTS.md` (OpenCode) and `CLAUDE.md` (Claude) |
| `agents` | attrs | Agent definitions (see [Agents](#agents)) |
| `skills.local` | list of paths | Local skill directories, each containing a `SKILL.md` |
| `skills.sources` | list | External skill sources from flake inputs (see [Skills](#skills)) |
| `commands` | list of paths | Command markdown files deployed as commands (OpenCode) and skills (Claude) |
| `permissions` | attrs | Shared permission rules applied to all backends (see [Permissions](#permissions)) |
| `mcpServers` | attrs | MCP server definitions shared across backends (see [MCP servers](#mcp-servers)) |
| `modelAliases` | attrs | Logical model aliases resolved per-backend (see [Model aliases](#model-aliases)) |

### Sandbox

Shared sandbox settings applied to both backends when sandboxing is enabled:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sandbox.allowedPackages` | list | `[coreutils git ripgrep …]` | Base packages available inside all sandboxes |
| `sandbox.extraAllowedPackages` | list | `[]` | Additional packages appended to `allowedPackages` |
| `sandbox.extraStateDirs` | list | `[]` | Additional writable directories |
| `sandbox.extraStateFiles` | list | `[]` | Additional writable files |
| `sandbox.extraEnv` | attrs | `{ GITHUB_TOKEN = "$GITHUB_TOKEN"; }` | Environment variables (use `"$VAR"` for secrets) |
| `sandbox.restrictNetwork` | bool | `false` | Restrict outbound network to `allowedDomains` |
| `sandbox.allowedDomains` | attrs | `{}` | Domains allowed when `restrictNetwork = true` |

---

## Backends

### OpenCode

```nix
modules.ai-coding.backends.opencode = {
  enable = true;
  sandbox.enable = true;       # installs opencode-sandboxed

  extraSettings = {            # merged into opencode.json
    share = "disabled";
    instructions = [ ".instructions.md" "CONTRIBUTING.md" ];
    tui.scroll_acceleration.enabled = true;
  };

  plugins = [ ./plugins/my-plugin.js ];
  prompts = [ ./prompts/my-prompt.txt ];
};
```

Additional backend-specific options:

| Option | Type | Description |
|--------|------|-------------|
| `extraPermissions` | attrs | Permissions merged with (and overriding) shared permissions |
| `extraSettings` | attrs | Freeform settings merged into `opencode.json` |
| `extraMcpServers` | attrs | MCP servers for OpenCode only |
| `disabledMcpServers` | list | Shared MCP server names to exclude |
| `plugins` | list of paths | JS plugin file paths |
| `prompts` | list of paths | Prompt text file paths |
| `sandbox.extraAllowedPackages` | list | Extra packages for the OpenCode sandbox |
| `sandbox.extraStateDirs` | list | Extra writable directories for the OpenCode sandbox |

### Claude Code

```nix
modules.ai-coding.backends.claude = {
  enable = true;
  sandbox.enable = true;       # installs claude-sandboxed

  extraSettings = { };         # merged into ~/.claude/settings.json
};
```

Additional backend-specific options mirror those of OpenCode (`extraPermissions`, `extraSettings`, `extraMcpServers`, `disabledMcpServers`, `sandbox.*`).

---

## Agents

Agents are submodule definitions compiled to markdown files with YAML frontmatter and deployed to each backend's agent directory.

```nix
modules.ai-coding.agents = {
  reviewer = {
    description = "Reviews code diffs and pull requests.";
    instructions = ./agents/reviewer.md;
    model = "sonnet";          # resolved via modelAliases
    color = "#ff6b6b";
    permissions = {
      bash = { "*" = "deny"; "git diff *" = "allow"; };
    };
    tools = {
      bash = true;
      write = false;
      edit = false;
    };
    opencode = { mode = "all"; };
    claude = { };
  };
};
```

Agent fields:

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Short description shown in the UI |
| `instructions` | path | Markdown file with agent instructions |
| `model` | string or null | Model alias (resolved via `modelAliases`) |
| `color` | string or null | Agent colour in the UI |
| `permissions` | attrs | Per-tool permission rules (same format as shared permissions) |
| `tools` | attrs or null | Tool availability map; `null` = all tools; `{ "*" = false; bash = true; }` = only bash |
| `opencode` | attrs | Extra fields merged into OpenCode agent frontmatter |
| `claude` | attrs | Extra fields merged into Claude agent frontmatter |

---

## Skills

Skills are directories containing a `SKILL.md` that describe a reusable capability.

```nix
modules.ai-coding.skills = {
  local = [ ./skills/my-skill ];   # each dir must have SKILL.md

  sources = [
    {
      name = "superpowers";
      src = flake.inputs.superpowers;    # flake input path
      path = "skills";                   # subdirectory within src (default: "skills")
      exclude = [ "using-git-worktrees" ];
      # include = [ "only-this-skill" ]; # whitelist; null = all
    }
  ];
};
```

Local skill names take precedence — external skills with matching names are silently skipped.

---

## Commands

Command markdown files are deployed as named commands in OpenCode and converted to skills in Claude (placed in `~/.claude/skills/<name>/SKILL.md`).

```nix
modules.ai-coding.commands = [ ./commands/review.md ./commands/deploy.md ];
```

---

## Permissions

Permissions use a two-level DSL that maps directly to OpenCode's format and is compiled to Claude's allow/deny list format.

```nix
modules.ai-coding.permissions = {
  # Blanket rule for a tool
  webfetch = "deny";

  # Pattern map for a tool
  bash = {
    "*"           = "ask";
    "git status*" = "allow";
    "git diff*"   = "allow";
    "rm -rf*"     = "deny";
  };

  external_directory = {
    "~/code/**"  = "allow";
    "~/.ssh/**"  = "deny";
  };
};
```

Valid actions: `"allow"`, `"ask"`, `"deny"`.

---

## MCP servers

```nix
modules.ai-coding.mcpServers = {
  my-server = {
    type    = "stdio";          # "stdio" | "http" | "sse" | "ws"
    command = "/path/to/bin";
    args    = [ "--flag" ];
    env     = { API_KEY = "$MY_API_KEY"; };
    enabled = true;
  };

  remote-server = {
    type    = "http";
    url     = "https://example.com/mcp";
    headers = { Authorization = "Bearer $TOKEN"; };
  };
};
```

MCP server fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | enum | — | `stdio`, `http`, `sse`, or `ws` |
| `command` | string or null | `null` | Executable for stdio servers |
| `args` | list | `[]` | Arguments passed to `command` |
| `url` | string or null | `null` | URL for remote servers |
| `env` | attrs | `{}` | Environment variables (use `"$VAR"` for secrets) |
| `headers` | attrs | `{}` | HTTP headers for remote servers |
| `enabled` | bool | `true` | OpenCode respects this; disabled servers are omitted from Claude |
| `oauth` | attrs | `{}` | OAuth config (OpenCode only) |

---

## Model aliases

Define logical names resolved to the correct provider/model ID per backend:

```nix
modules.ai-coding.modelAliases = {
  sonnet = {
    opencode = "anthropic/claude-sonnet-4-20250514";
    claude   = "claude-sonnet-4-5";   # optional; defaults to alias key
  };
  haiku = {
    opencode = "anthropic/claude-haiku-4-20250514";
  };
};
```

Use the alias name in `agents.<name>.model` and it is resolved to the correct ID for each backend at build time.

---

## Sandboxing

Enabling `backends.opencode.sandbox.enable` or `backends.claude.sandbox.enable` installs a sandboxed wrapper binary (`opencode-sandboxed` / `claude-sandboxed`) that restricts filesystem and network access using [agent-sandbox](https://github.com/samjwillis97/agent-sandbox).

```nix
modules.ai-coding = {
  sandbox = {
    extraAllowedPackages = with pkgs; [ gh jq ];
    extraStateDirs  = [ "$HOME/.cache" "$HOME/.npm" ];
    extraStateFiles = [ "$HOME/.netrc" ];
    extraEnv        = { MY_TOKEN = "$MY_TOKEN"; };

    restrictNetwork  = true;
    allowedDomains   = {
      "api.github.com"   = "*";
      "registry.npmjs.org" = [ "GET" "HEAD" ];
    };
  };

  backends.opencode.sandbox.enable = true;
  backends.claude.sandbox.enable   = true;
};
```

Shared sandbox settings are merged with per-backend overrides; per-backend values win on conflicts.
