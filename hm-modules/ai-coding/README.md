# ai-coding Home Manager Module

A Home Manager module that provides a unified abstraction layer for AI coding
tools. It centralises shared configuration (agents, skills, commands,
permissions, MCP servers, model aliases, sandbox settings) and compiles it into
the native format of each supported backend.

## Supported Backends

| Backend | Binary | Config location |
|---------|--------|----------------|
| [OpenCode](https://opencode.ai) | `opencode` / `opencode-sandboxed` | `~/.config/opencode/` |
| [Claude Code](https://claude.ai/code) | `claude` / `claude-sandboxed` | `~/.claude/` |

## Module Layout

```
hm-modules/ai-coding/
├── default.nix        # Top-level options & shared assertions
├── types.nix          # Reusable NixOS option types
└── backends/
    ├── opencode.nix   # OpenCode backend implementation
    └── claude.nix     # Claude Code backend implementation
```

## Quick Start

Import the module from your Home Manager configuration and enable whichever
backends you need:

```nix
{
  imports = [ <path-to>/hm-modules/ai-coding ];

  modules.ai-coding = {
    enable = true;

    backends.opencode.enable = true;
    backends.claude.enable = true;

    modelAliases = {
      sonnet.opencode = "anthropic/claude-sonnet-4-20250514";
    };
  };
}
```

## Top-Level Options

All options live under `modules.ai-coding.*`.

### `enable`

`bool` — default `false`

Enable the AI coding abstraction layer. Must be `true` for any backend or
sub-option to take effect.

---

### `rules`

`null | path` — default `null`

Path to a Markdown file used as global system-prompt / instructions.

- OpenCode: deployed as `~/.config/opencode/AGENTS.md` (via
  `programs.opencode.rules`).
- Claude: copied to `~/.claude/CLAUDE.md`.

```nix
modules.ai-coding.rules = ./AGENTS.md;
```

---

### `agents`

`attrsOf agent` — default `{}`

Named agent definitions. Each key becomes the agent filename (`<name>.md`).

- OpenCode: written to `~/.config/opencode/agent/<name>.md` as Markdown with
  YAML frontmatter.
- Claude: written to `~/.claude/agents/<name>.md` with its own frontmatter
  format.

See [Agent Type](#agent) for the full set of sub-options.

```nix
modules.ai-coding.agents = {
  reviewer = {
    description = "Performs code reviews.";
    instructions = ./agents/reviewer.md;
    model = "sonnet";  # resolved via modelAliases
    permissions.bash."*" = "deny";
    tools = { bash = true; edit = false; };
  };
};
```

---

### `skills`

#### `skills.local`

`listOf path` — default `[]`

Paths to local skill directories. Each directory must contain a `SKILL.md` file.
Skills are deployed to `~/.config/opencode/skills/` (OpenCode) and
`~/.claude/skills/` (Claude).

#### `skills.sources`

`listOf skillSource` — default `[]`

External skill sources, typically from flake inputs. See
[SkillSource Type](#skillsource) for sub-options.

```nix
modules.ai-coding.skills = {
  local = [ ./skills/my-skill ];
  sources = [
    {
      name = "superpowers";
      src = flake.inputs.superpowers;
      exclude = [ "using-git-worktrees" ];
    }
  ];
};
```

---

### `commands`

`listOf path` — default `[]`

Markdown command files.

- OpenCode: deployed to `~/.config/opencode/command/`.
- Claude: each command is converted to a skill directory under
  `~/.claude/skills/<name>/SKILL.md`.

---

### `permissions`

`permissionSet` — default `{}`

Shared permission rules applied to all backends. A map of tool names to
permission rules.

Each value is either:
- A blanket action string: `"allow"`, `"ask"`, or `"deny"`.
- An attribute set of glob patterns to actions.

Tool names recognised by the DSL:

| DSL name | OpenCode tool | Claude tool(s) |
|----------|--------------|----------------|
| `bash` | `bash` | `Bash` |
| `edit` | `edit` | `Edit`, `Write` |
| `read` | `read` | `Read` |
| `webfetch` | `webfetch` | `WebFetch` |
| `glob` | `glob` | `Glob` |
| `grep` | `grep` | `Grep` |
| `list` | `list` | `List` |
| `task` | `task` | `Task` |
| `skill` | `skill` | `Skill` |
| `external_directory` | `external_directory` | `Read`, `Edit` |

OpenCode-specific tools (`doom_loop`, `question`, `lsp`, `codesearch`,
`websearch`) are silently skipped by the Claude backend.

```nix
modules.ai-coding.permissions = {
  webfetch = "deny";
  bash = {
    "*" = "ask";
    "git status*" = "allow";
    "git diff*"   = "allow";
  };
};
```

---

### `mcpServers`

`attrsOf mcpServer` — default `{}`

MCP server definitions shared across all backends. See
[McpServer Type](#mcpserver) for sub-options.

```nix
modules.ai-coding.mcpServers = {
  my-server = {
    type    = "stdio";
    command = "/path/to/mcp-server";
    args    = [ "--flag" ];
    env     = { API_KEY = "$MY_API_KEY"; };
  };
};
```

---

### `modelAliases`

`attrsOf modelAlias` — default `{}`

Human-readable model alias → per-backend model ID mapping.  Agent `model`
fields reference these aliases.  See [ModelAlias Type](#modelalias).

```nix
modules.ai-coding.modelAliases = {
  sonnet = {
    opencode = "anthropic/claude-sonnet-4-20250514";
    # claude defaults to the alias key ("sonnet")
  };
};
```

---

### `sandbox.*`

Shared sandbox settings inherited by all backend sandboxes.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sandbox.allowedPackages` | `listOf package` | `[coreutils which git ripgrep fd gnused gnugrep findutils jq nodejs]` | Base package set available inside every sandbox. |
| `sandbox.extraAllowedPackages` | `listOf package` | `[]` | Additional packages appended to `allowedPackages`. |
| `sandbox.extraStateDirs` | `listOf str` | `[]` | Additional writable directories merged with per-backend dirs. |
| `sandbox.extraStateFiles` | `listOf str` | `[]` | Additional writable files merged with per-backend files. |
| `sandbox.extraEnv` | `attrsOf str` | `{ GITHUB_TOKEN = "$GITHUB_TOKEN"; }` | Environment variables. Use shell references (e.g. `"$TOKEN"`) for secrets. |
| `sandbox.restrictNetwork` | `bool` | `false` | Restrict network to `allowedDomains` when `true`. |
| `sandbox.allowedDomains` | `attrsOf (str \| listOf str)` | `{}` | Domains reachable when `restrictNetwork = true`. Map domain → `"*"` or `["GET"]`. Suffix-matched. |

> **Note:** Setting `restrictNetwork = true` without defining any
> `allowedDomains` triggers an assertion error.

---

## Backend Options

### OpenCode (`backends.opencode.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable the OpenCode backend. |
| `extraPermissions` | `permissionSet` | `{}` | Permissions merged on top of shared `permissions` (backend-specific values win). |
| `extraSettings` | `attrsOf anything` | `{}` | Freeform fields merged into `opencode.json` (e.g. `provider`, `tui`, `keybinds`, `instructions`). |
| `extraMcpServers` | `attrsOf mcpServer` | `{}` | OpenCode-only MCP servers. |
| `disabledMcpServers` | `listOf str` | `[]` | Names of shared MCP servers to exclude from OpenCode config. |
| `plugins` | `listOf path` | `[]` | JS plugin file paths deployed to `~/.config/opencode/plugins/`. |
| `prompts` | `listOf path` | `[]` | Prompt text files deployed to `~/.config/opencode/prompts/`. |

#### OpenCode Sandbox (`backends.opencode.sandbox.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Build and install `opencode-sandboxed`. |
| `extraAllowedPackages` | `listOf package` | `[]` | Packages added to the OpenCode sandbox. |
| `extraStateDirs` | `listOf str` | `[]` | Extra writable dirs (default includes `~/.config/opencode`, `~/.local/share/opencode`). |
| `extraStateFiles` | `listOf str` | `[]` | Extra writable files. |
| `extraEnv` | `attrsOf str` | `{}` | Extra env vars (merged with shared; backend-specific wins). |
| `restrictNetwork` | `bool` | `false` | ORed with shared `restrictNetwork`. |
| `allowedDomains` | `attrsOf (str \| listOf str)` | `{}` | Merged with shared `allowedDomains`. |

**Files written by OpenCode backend:**

| Path | Content |
|------|---------|
| `~/.config/opencode/opencode.json` | Compiled JSON config (permissions, MCP servers, extra settings) |
| `~/.config/opencode/agent/<name>.md` | Compiled agent files with YAML frontmatter |
| `~/.config/opencode/command/<file>` | Command markdown files |
| `~/.config/opencode/plugins/<name>.<ext>` | Plugin files (symlinked) |
| `~/.config/opencode/prompts/<name>` | Prompt text files |
| `~/.config/opencode/skills/<name>/` | Skill directories (rsync'd) |

---

### Claude Code (`backends.claude.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable the Claude Code backend. |
| `extraPermissions` | `permissionSet` | `{}` | Permissions merged on top of shared `permissions`. |
| `extraSettings` | `attrsOf anything` | `{}` | Freeform fields merged into `~/.claude/settings.json`. |
| `extraMcpServers` | `attrsOf mcpServer` | `{}` | Claude-only MCP servers. |
| `disabledMcpServers` | `listOf str` | `[]` | Names of shared MCP servers to exclude from Claude config. |

#### Claude Sandbox (`backends.claude.sandbox.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Build and install `claude-sandboxed`. |
| `extraAllowedPackages` | `listOf package` | `[]` | Packages added to the Claude sandbox. |
| `extraStateDirs` | `listOf str` | `[]` | Extra writable dirs (default includes `~/.claude`). |
| `extraStateFiles` | `listOf str` | `[]` | Extra writable files (default includes `~/.claude.json`, `~/.claude.json.lock`). |
| `extraEnv` | `attrsOf str` | `{}` | Extra env vars (`CLAUDE_CODE_OAUTH_TOKEN` included by default). |
| `restrictNetwork` | `bool` | `false` | ORed with shared `restrictNetwork`. |
| `allowedDomains` | `attrsOf (str \| listOf str)` | `{}` | Merged with shared `allowedDomains`. |

**Files written by Claude backend:**

| Path | Content |
|------|---------|
| `~/.claude/settings.json` | Compiled JSON settings (permissions, extra settings) |
| `~/.claude.json` | MCP server definitions (merged preserving existing keys) |
| `~/.claude/CLAUDE.md` | Global rules/instructions (when `rules` is set) |
| `~/.claude/agents/<name>.md` | Compiled agent files |
| `~/.claude/skills/<name>/` | Skill directories (rsync'd) |
| `~/.claude/skills/<cmd>/SKILL.md` | Commands converted to Claude skills |

---

## Type Definitions

### `agent`

Sub-module used in `agents`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `description` | `str` | — | Short description shown in the UI / used to trigger the agent. |
| `instructions` | `path` | — | Path to a Markdown file with agent instructions. |
| `model` | `null \| str` | `null` | Model alias (resolved via `modelAliases`). |
| `color` | `null \| str` | `null` | Agent colour in the UI. |
| `permissions` | `permissionSet` | `{}` | Per-agent permission rules. |
| `tools` | `null \| attrsOf bool` | `null` | Tool availability map. `null` = all tools. `{ "*" = false; bash = true; }` = only bash. |
| `opencode` | `attrsOf anything` | `{}` | Extra fields merged into the OpenCode agent frontmatter. |
| `claude` | `attrsOf anything` | `{}` | Extra fields merged into the Claude agent frontmatter. |

---

### `mcpServer`

Sub-module used in `mcpServers` and `backends.*.extraMcpServers`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | `"stdio" \| "http" \| "sse" \| "ws"` | — | Transport type. |
| `command` | `null \| str` | `null` | Executable path (stdio servers). |
| `args` | `listOf str` | `[]` | Arguments for `command`. |
| `url` | `null \| str` | `null` | URL for remote servers. |
| `env` | `attrsOf str` | `{}` | Environment variables. Mapped to `environment` in OpenCode. |
| `headers` | `attrsOf str` | `{}` | HTTP headers (remote servers). |
| `enabled` | `bool` | `true` | OpenCode respects this field; disabled servers are omitted from Claude. |
| `oauth` | `attrsOf anything` | `{}` | OAuth config (OpenCode-only; ignored by Claude). |

---

### `skillSource`

Sub-module used in `skills.sources`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | `str` | — | Name for this source (used in dedup logging). |
| `src` | `path` | — | Flake input path containing skills. |
| `path` | `str` | `"skills"` | Subdirectory within `src` containing skill directories. |
| `exclude` | `listOf str` | `[]` | Skill names to skip. |
| `include` | `null \| listOf str` | `null` | If set, only include these skill names; `null` = all. |

---

### `modelAlias`

Sub-module used in `modelAliases`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `opencode` | `str` | — | Full `provider/model-id` for OpenCode (e.g. `"anthropic/claude-sonnet-4-20250514"`). |
| `claude` | `str` | alias key | Model identifier for Claude. Defaults to the alias name. |

---

## Permission Reference

Permissions use a two-level DSL:

```
permissionSet = { <tool> = permissionRule; ... }
permissionRule = "allow" | "ask" | "deny"
               | { <pattern> = "allow" | "ask" | "deny"; ... }
```

**Blanket rule** — applies to all uses of that tool:

```nix
permissions.webfetch = "deny";
```

**Pattern map** — applies per-command/path pattern:

```nix
permissions.bash = {
  "*"            = "ask";   # default for everything
  "git status*"  = "allow";
  "rm -rf *"     = "deny";
};
```

The `"*"` pattern sets the default for unmatched commands (OpenCode) or is
omitted from Claude's flat allow/deny/ask lists (Claude's default is `ask`).

---

## Sandbox Notes

The sandbox feature requires the `agent-sandbox` flake input and uses it to
produce a wrapped binary (e.g. `opencode-sandboxed` / `claude-sandboxed`) that:

- Has access only to the listed packages.
- Can read/write only the listed state directories and files.
- Optionally has restricted network access.

Use shell variable references (e.g. `"$MY_SECRET"`) in `extraEnv` to keep
secrets out of the Nix store.
