# hm-modules/ai-coding/backends/claude.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption mkIf mkMerge types concatMapStringsSep
    filterAttrs mapAttrs mapAttrsToList optionalAttrs recursiveUpdate
    concatLists optional optionals;

  aiTypes = import ../types.nix { inherit lib; };
  cfg = config.modules.ai-coding;
  claudeCfg = cfg.backends.claude;

  # Tool name mapping: DSL name -> Claude name(s)
  # Returns a list because some DSL tools map to multiple Claude tools
  toolNameMap = {
    bash = [ "Bash" ];
    edit = [ "Edit" "Write" ];
    read = [ "Read" ];
    webfetch = [ "WebFetch" ];
    glob = [ "Glob" ];
    grep = [ "Grep" ];
    list = [ "List" ];
    task = [ "Task" ];
    skill = [ "Skill" ];
    external_directory = [ "Read" "Edit" ];
  };

  # Tools that are OpenCode-specific and should be silently skipped
  opencodeOnlyTools = [ "doom_loop" "question" "lsp" "codesearch" "websearch" ];

  # Map a DSL tool name to Claude tool name(s)
  mapToolNames = toolName:
    if builtins.hasAttr toolName toolNameMap then toolNameMap.${toolName}
    else if builtins.elem toolName opencodeOnlyTools then [ ]
    else [ toolName ]; # Pass through unknown tools as-is

  # Compile permissions to Claude's flat list format
  # Returns { allow = [...]; deny = [...]; ask = [...]; }
  compilePermissions = permissions: let
    # Process a single tool's rules
    processToolRules = toolName: rule:
      if builtins.isString rule then
        # Blanket rule: e.g. webfetch = "deny"
        let claudeNames = mapToolNames toolName;
        in if rule == "deny" then { allow = []; deny = claudeNames; ask = []; }
        else if rule == "allow" then { allow = claudeNames; deny = []; ask = []; }
        else { allow = []; deny = []; ask = []; } # "ask" is Claude default, skip
      else
        # Pattern map: e.g. bash = { "*" = "ask"; "git status*" = "allow"; }
        let
          claudeNames = mapToolNames toolName;
          patternRules = filterAttrs (pat: _: pat != "*") rule;
          mkEntries = action:
            concatLists (map (claudeName:
              map (pat: "${claudeName}(${pat})")
                (builtins.attrNames (filterAttrs (_: a: a == action) patternRules))
            ) claudeNames);
        in {
          allow = mkEntries "allow";
          deny = mkEntries "deny";
          ask = mkEntries "ask";
        };

    # Process all tools
    allResults = mapAttrsToList processToolRules permissions;

    # Merge all results
    mergeResults = builtins.foldl' (acc: r: {
      allow = acc.allow ++ r.allow;
      deny = acc.deny ++ r.deny;
      ask = acc.ask ++ r.ask;
    }) { allow = []; deny = []; ask = []; } allResults;

  in mergeResults;

  # Merge shared + extra permissions
  mergedPermissions = recursiveUpdate cfg.permissions claudeCfg.extraPermissions;
  compiledPermissions = compilePermissions mergedPermissions;

   # Compile MCP servers for Claude
   # All servers are included regardless of enabled/disabled state
   allMcpServers = let
     shared = cfg.mcpServers;
     extra = claudeCfg.extraMcpServers;
     merged = recursiveUpdate shared extra;
   in filterAttrs (name: _:
     !(builtins.elem name claudeCfg.disabledMcpServers)
   ) merged;

  compileMcpServer = name: server: {
    inherit (server) type;
  } // (if server.command != null then { inherit (server) command args; } else { })
  // (if server.url != null then { inherit (server) url; } else { })
  // (if server.env != { } then { inherit (server) env; } else { })
   // (if server.headers != { } then { inherit (server) headers; } else { });
   # oauth is NOT passed to Claude (not supported)
   # enabled is NOT passed (disabled servers already filtered out)

  compiledMcpServers = mapAttrs compileMcpServer allMcpServers;

  # JSON blob for MCP servers to merge into ~/.claude.json
  mcpServersJson = builtins.toJSON { mcpServers = compiledMcpServers; };

  # Build settings.json (permissions, env, model config — NOT MCP servers)
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
  }
  // (if compiledPermissions.allow != [] || compiledPermissions.deny != [] || compiledPermissions.ask != [] then {
    permissions = {
      allow = compiledPermissions.allow;
      deny = compiledPermissions.deny;
      ask = compiledPermissions.ask;
    };
  } else { })
  // claudeCfg.extraSettings;

  # Compile agent to Claude markdown with frontmatter
  compileAgent = name: agent: let
    # Build tools list from tools attrset
    toolsList = if agent.tools == null then null
      else let
        enabledTools = builtins.attrNames (filterAttrs (k: v: v && k != "*") agent.tools);
        # Map DSL tool names to Claude names
        claudeToolNames = concatLists (map (t:
          if builtins.hasAttr t toolNameMap then toolNameMap.${t}
          else [ t ]
        ) enabledTools);
      in claudeToolNames;

    disallowedTools = if agent.tools == null then null
      else let
        disabledTools = builtins.attrNames (filterAttrs (k: v: !v && k != "*") agent.tools);
        claudeToolNames = concatLists (map (t:
          if builtins.hasAttr t toolNameMap then toolNameMap.${t}
          else [ t ]
        ) disabledTools);
      in claudeToolNames;

    frontmatter = { inherit name; inherit (agent) description; }
      // (if agent.model != null then { model = agent.model; } else { })
      // (if agent.color != null then { inherit (agent) color; } else { })
      // (if toolsList != null && toolsList != [] then {
        tools = builtins.concatStringsSep ", " toolsList;
      } else { })
      // (if disallowedTools != null && disallowedTools != [] then {
        disallowedTools = builtins.concatStringsSep ", " disallowedTools;
      } else { })
      // agent.claude;

    yamlLines = mapAttrsToList (k: v:
      if builtins.isList v then
        "${k}:\n${builtins.concatStringsSep "\n" (map (item: "  - ${builtins.toJSON item}") v)}"
      else "${k}: ${if builtins.isString v then v else builtins.toJSON v}"
    ) frontmatter;
    yamlFrontmatter = builtins.concatStringsSep "\n" yamlLines;

    instructionContent = builtins.readFile agent.instructions;
  in ''
---
${yamlFrontmatter}
---
${instructionContent}'';

  agentFiles = mapAttrs (name: agent:
    pkgs.writeTextFile {
      name = "${name}.md";
      text = compileAgent name agent;
    }
  ) cfg.agents;

  # Skill resolution (same as OpenCode backend)
  getDirNames = dir:
    lib.attrNames (filterAttrs (_: value: value == "directory") (builtins.readDir dir));

  localSkillNames = builtins.concatMap (path: getDirNames path) cfg.skills.local;

  resolveSkillSource = { name, src, path ? "skills", exclude ? [ ], include ? null }:
    let
      skillsDir = "${src}/${path}";
      allNames = getDirNames skillsDir;
      selectedNames =
        if include != null then lib.filter (n: builtins.elem n allNames) include
        else allNames;
      filteredNames = lib.filter (n:
        !(builtins.elem n exclude) && !(builtins.elem n localSkillNames)
      ) selectedNames;
    in map (n: "${skillsDir}/${n}") filteredNames;

  allSkillPaths = cfg.skills.local
    ++ builtins.concatMap resolveSkillSource cfg.skills.sources;

  stripNixHashScript = ''
    strip_nix_hash() {
      if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
    }
  '';

in
{
  options.modules.ai-coding.backends.claude = {
    enable = mkEnableOption "Claude Code backend";

    extraPermissions = mkOption {
      type = aiTypes.permissionSet;
      default = { };
      description = "Additional permissions merged with shared (overrides shared for same tool/pattern).";
    };

    extraSettings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Freeform settings merged into Claude's settings.json.";
    };

    extraMcpServers = mkOption {
      type = types.attrsOf aiTypes.mcpServer;
      default = { };
      description = "Additional MCP servers for Claude only.";
    };

    disabledMcpServers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "MCP server names to exclude from Claude config.";
    };
  };

  config = mkIf (cfg.enable && claudeCfg.enable) (mkMerge [
    {
      # Install Claude Code package
      home.packages = [ pkgs.claude-code ];

      # settings.json
      home.file.".claude/settings.json".text = builtins.toJSON claudeSettings;

      # MCP servers — merged into ~/.claude.json (user scope) preserving existing content
      home.activation.ai-coding-claude-mcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CLAUDE_JSON="$HOME/.claude.json"
        MCP_JSON='${mcpServersJson}'
        if [ -f "$CLAUDE_JSON" ]; then
          # Merge: replace only the mcpServers key, preserve everything else
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_JSON" <(echo "$MCP_JSON") > "$CLAUDE_JSON.tmp" \
            && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
        else
          echo "$MCP_JSON" > "$CLAUDE_JSON"
        fi
      '';

      # CLAUDE.md (rules)
      home.activation.ai-coding-claude-rules = mkIf (cfg.rules != null)
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          cp "${cfg.rules}" "$HOME/.claude/CLAUDE.md"
        '');

      # Agent files
      home.activation.ai-coding-claude-agents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.claude/agents
        rm -f $HOME/.claude/agents/*
        ${concatMapStringsSep "\n" (nameAgentPair: let
          name = builtins.elemAt nameAgentPair 0;
          file = builtins.elemAt nameAgentPair 1;
        in ''
          cp "${file}" "$HOME/.claude/agents/${name}.md"
        '') (mapAttrsToList (name: file: [ name file ]) agentFiles)}
      '';

      # Skills (shared + external, via rsync)
      home.activation.ai-coding-claude-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.claude/skills
        chmod -R u+w $HOME/.claude/skills 2>/dev/null || true
        rm -rf $HOME/.claude/skills/*
        ${concatMapStringsSep "\n" (skill: ''
          skill_name=$(strip_nix_hash "$(basename "${skill}")")
          ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw "${skill}/" "$HOME/.claude/skills/$skill_name/"
        '') allSkillPaths}
      '';

      # Commands -> Claude skills conversion
      home.activation.ai-coding-claude-commands = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        ${concatMapStringsSep "\n" (command: ''
          cmd_basename=$(strip_nix_hash "$(basename "${command}" .md)")
          skill_dir="$HOME/.claude/skills/$cmd_basename"
          mkdir -p "$skill_dir"
          cp "${command}" "$skill_dir/SKILL.md"
        '') cfg.commands}
      '';
    }
  ]);
}
