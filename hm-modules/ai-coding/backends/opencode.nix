# hm-modules/ai-coding/backends/opencode.nix
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption mkIf mkMerge types concatMapStringsSep
    filterAttrs mapAttrs mapAttrsToList optionalAttrs recursiveUpdate optional;

  aiTypes = import ../types.nix { inherit lib; };
  cfg = config.modules.ai-coding;
  ocCfg = cfg.backends.opencode;
  sandboxCfg = ocCfg.sandbox;

  # Import agent-sandbox
  agentSandbox = import flake.inputs.agent-sandbox { inherit pkgs; };

  # Resolve model alias for OpenCode
  resolveModel = alias:
    if alias == null then null
    else if cfg.modelAliases ? ${alias} then cfg.modelAliases.${alias}.opencode
    else alias;

  # Map DSL transport type to OpenCode transport type
  mapTransportType = type:
    if type == "stdio" then "local"
    else "remote";

  # Compile a single MCP server to OpenCode format
  compileMcpServer = name: server: {
    type = mapTransportType server.type;
  } // (if server.command != null then {
    command = [ server.command ] ++ server.args;
  } else { })
  // (if server.url != null then { inherit (server) url; } else { })
  // (if server.env != { } then { environment = server.env; } else { })
  // (if server.headers != { } then { inherit (server) headers; } else { })
  // { inherit (server) enabled; }
  // (if server.oauth != { } then { inherit (server) oauth; } else { });

  # Merge shared + extra MCP servers, then remove disabled ones
  allMcpServers = let
    shared = cfg.mcpServers;
    extra = ocCfg.extraMcpServers;
    merged = recursiveUpdate shared extra;
  in filterAttrs (name: _: !(builtins.elem name ocCfg.disabledMcpServers)) merged;

  compiledMcpServers = mapAttrs compileMcpServer allMcpServers;

  # Merge shared + extra permissions
  mergedPermissions = recursiveUpdate cfg.permissions ocCfg.extraPermissions;

  # Compile permissions — the DSL format IS the OpenCode format (near 1:1)
  compiledPermissions = mergedPermissions;

  # Compile opencode.json settings
  opencodeJson = {
    "$schema" = "https://opencode.ai/config.json";
  }
  // (if compiledPermissions != { } then { permission = compiledPermissions; } else { })
  // (if compiledMcpServers != { } then { mcp = compiledMcpServers; } else { })
  // ocCfg.extraSettings;

  # Compile a single agent to OpenCode markdown with YAML frontmatter
  compileAgent = name: agent: let
    resolvedModel = resolveModel agent.model;

    # Build frontmatter attrset
    frontmatter = { inherit (agent) description; }
      // (if resolvedModel != null then { model = resolvedModel; } else { })
      // (if agent.color != null then { inherit (agent) color; } else { })
      // (if agent.tools != null then { inherit (agent) tools; } else { })
      // (if agent.permissions != { } then { permission = agent.permissions; } else { })
      // agent.opencode;

    # Convert attrset to YAML frontmatter string
    # Using builtins.toJSON for values, then reformatting
    # NOTE: This produces JSON-in-YAML which is valid YAML
    yamlLines = mapAttrsToList (k: v: "${k}: ${builtins.toJSON v}") frontmatter;
    yamlFrontmatter = builtins.concatStringsSep "\n" yamlLines;

    instructionContent = builtins.readFile agent.instructions;
  in ''
---
${yamlFrontmatter}
---
${instructionContent}'';

  # Generate agent files as a derivation
  agentFiles = mapAttrs (name: agent:
    pkgs.writeTextFile {
      name = "${name}.md";
      text = compileAgent name agent;
    }
  ) cfg.agents;

  # Helper to strip nix store hashes from filenames
  stripNixHashScript = ''
    strip_nix_hash() {
      if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
    }
  '';

  # Skill resolution (same logic as existing opencode config)
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

  # Sandbox derivation: wraps the opencode binary
  opencodeSandboxed = agentSandbox.mkSandbox {
    pkg = pkgs.opencode;
    binName = "opencode";
    outName = "opencode-sandboxed";
    allowedPackages = cfg.sandbox.allowedPackages
      ++ cfg.sandbox.extraAllowedPackages
      ++ sandboxCfg.extraAllowedPackages;
    stateDirs = [
      "$HOME/.config/opencode"
      "$HOME/.local/share/opencode"
    ] ++ cfg.sandbox.extraStateDirs ++ sandboxCfg.extraStateDirs;
    stateFiles = cfg.sandbox.extraStateFiles ++ sandboxCfg.extraStateFiles;
    extraEnv = cfg.sandbox.extraEnv // sandboxCfg.extraEnv;
    restrictNetwork = cfg.sandbox.restrictNetwork || sandboxCfg.restrictNetwork;
    allowedDomains = cfg.sandbox.allowedDomains // sandboxCfg.allowedDomains;
  };

in
{
  options.modules.ai-coding.backends.opencode = {
    enable = mkEnableOption "OpenCode backend";

    extraPermissions = mkOption {
      type = aiTypes.permissionSet;
      default = { };
      description = "Additional permissions merged with shared (overrides shared for same tool/pattern).";
    };

    extraSettings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Freeform settings merged into opencode.json (provider, tui, keybinds, instructions, etc.).";
    };

    extraMcpServers = mkOption {
      type = types.attrsOf aiTypes.mcpServer;
      default = { };
      description = "Additional MCP servers for OpenCode only.";
    };

    disabledMcpServers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "MCP server names to exclude from OpenCode config.";
    };

    plugins = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "JS plugin file paths (OpenCode-only).";
    };

    prompts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Prompt text file paths (OpenCode-only).";
    };

    sandbox = {
      enable = mkEnableOption "Sandboxed OpenCode binary (opencode-sandboxed)";

      extraAllowedPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional packages available inside the OpenCode sandbox, appended to the shared allowedPackages.";
      };

      extraStateDirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional directories the sandboxed agent can read/write.
          ~/.config/opencode and ~/.local/share/opencode are included by default.
        '';
      };

      extraStateFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional files the sandboxed agent can read/write.";
      };

      extraEnv = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Additional environment variables for the OpenCode sandbox.
          Use shell variable references (e.g. "$TOKEN") for secrets.
          Merged with shared sandbox.extraEnv (backend-specific values win).
        '';
      };

      restrictNetwork = mkOption {
        type = types.bool;
        default = false;
        description = "Restrict network to allowedDomains for the OpenCode sandbox. ORed with shared sandbox.restrictNetwork.";
      };

      allowedDomains = mkOption {
        type = types.attrsOf (types.either types.str (types.listOf types.str));
        default = { };
        description = "Additional allowed domains for the OpenCode sandbox. Merged with shared sandbox.allowedDomains.";
      };
    };
  };

  config = mkIf (cfg.enable && ocCfg.enable) (mkMerge [
    {
      programs.opencode.enable = true;
    }

    (mkIf (cfg.rules != null) {
      programs.opencode.rules = cfg.rules;
    })

    {
      # opencode.json
      home.file.".config/opencode/opencode.json".text = builtins.toJSON opencodeJson;

      # Agent files
      home.activation.ai-coding-opencode-agents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.config/opencode/agent
        rm -f $HOME/.config/opencode/agent/*
        ${concatMapStringsSep "\n" (nameAgentPair: let
          name = builtins.elemAt nameAgentPair 0;
          file = builtins.elemAt nameAgentPair 1;
        in ''
          cp "${file}" "$HOME/.config/opencode/agent/${name}.md"
        '') (mapAttrsToList (name: file: [ name file ]) agentFiles)}
      '';

      # Command files
      home.activation.ai-coding-opencode-commands = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.config/opencode/command
        rm -f $HOME/.config/opencode/command/*
        ${concatMapStringsSep "\n" (command: ''
          cp ${command} $HOME/.config/opencode/command/
        '') cfg.commands}
      '';

      # Plugins
      home.activation.ai-coding-opencode-plugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        rm -rf $HOME/.config/opencode/plugin
        mkdir -p $HOME/.config/opencode/plugins
        rm -f $HOME/.config/opencode/plugins/*
        ${concatMapStringsSep "\n" (plugin: ''
          plugin_path="${plugin}"
          plugin_base="$(basename "$plugin_path")"
          ext="''${plugin_path##*.}"
          if [ "$plugin_base" = "index.$ext" ]; then
            # Generic filename — derive unique name from nix store package name
            store_entry="$(basename "$(dirname "$(dirname "$plugin_path")")")"
            plugin_name="$(strip_nix_hash "$store_entry")"
          else
            # Already a unique filename — strip hash and extension
            plugin_name="$(strip_nix_hash "''${plugin_base%.*}")"
          fi
          ln -sf "$plugin_path" "$HOME/.config/opencode/plugins/''${plugin_name}.''${ext}"
        '') ocCfg.plugins}
      '';

      # Prompts
      home.activation.ai-coding-opencode-prompts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.config/opencode/prompts
        rm -f $HOME/.config/opencode/prompts/*
        ${concatMapStringsSep "\n" (prompt: ''
          prompt_name=$(strip_nix_hash "$(basename "${prompt}")")
          cp "${prompt}" "$HOME/.config/opencode/prompts/$prompt_name"
        '') ocCfg.prompts}
      '';

      # Skills (shared + external, via rsync)
      home.activation.ai-coding-opencode-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.config/opencode/skills
        chmod -R u+w $HOME/.config/opencode/skills 2>/dev/null || true
        rm -rf $HOME/.config/opencode/skills/*
        ${concatMapStringsSep "\n" (skill: ''
          skill_name=$(strip_nix_hash "$(basename "${skill}")")
          ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw "${skill}/" "$HOME/.config/opencode/skills/$skill_name/"
        '') allSkillPaths}
      '';
    }

    # Sandbox: install sandboxed binary alongside the original
    (mkIf sandboxCfg.enable {
      home.packages = [ opencodeSandboxed ];
    })
  ]);
}
