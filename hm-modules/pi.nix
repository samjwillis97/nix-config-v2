# hm-modules/pi.nix
#
# Standalone home-manager module for the pi coding agent.
# Manages settings, skills, extensions, and an optional sandbox wrapper.
#
# Pi's configuration model is different enough from OpenCode/Claude
# (extensions, packages, TypeScript plugins, settings.json merging)
# that it lives outside the ai-coding abstraction layer.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkMerge
    types
    concatMapStringsSep
    ;

  cfg = config.modules.pi;
  sandboxCfg = cfg.sandbox;

  # Import agent-sandbox
  agentSandbox = import flake.inputs.agent-sandbox { inherit pkgs; };

  # Helper to strip nix store hashes from filenames
  stripNixHashScript = ''
    strip_nix_hash() {
      if [[ "$1" =~ ^[a-z0-9]{32}- ]]; then echo "''${1#*-}"; else echo "$1"; fi
    }
  '';

  # Skill resolution
  getDirNames =
    dir: lib.attrNames (lib.filterAttrs (_: value: value == "directory") (builtins.readDir dir));

  localSkillNames = builtins.concatMap (path: getDirNames path) cfg.skills.local;

  resolveSkillSource =
    {
      name,
      src,
      path ? "skills",
      exclude ? [ ],
      include ? null,
    }:
    let
      skillsDir = "${src}/${path}";
      allNames = getDirNames skillsDir;
      selectedNames =
        if include != null then lib.filter (n: builtins.elem n allNames) include else allNames;
      filteredNames = lib.filter (
        n: !(builtins.elem n exclude) && !(builtins.elem n localSkillNames)
      ) selectedNames;
    in
    map (n: "${skillsDir}/${n}") filteredNames;

  allSkillPaths = cfg.skills.local ++ builtins.concatMap resolveSkillSource cfg.skills.sources;

  # Build the settings.json content
  piSettings =
    lib.filterAttrs (_: v: v != null) {
      defaultProvider = cfg.defaultProvider;
      defaultModel = cfg.defaultModel;
    }
    // cfg.extraSettings;

  # Sandbox derivation
  piSandboxed = agentSandbox.mkSandbox {
    pkg = pkgs.llm-agents.pi;
    binName = "pi";
    outName = "pi-sandboxed";
    allowedPackages = sandboxCfg.allowedPackages ++ sandboxCfg.extraAllowedPackages;
    # Pi needs write access to its own config dirs so it can
    # install/update extensions and skills at runtime
    stateDirs = [
      "$HOME/.pi"
      "$HOME/.agents"
    ]
    ++ sandboxCfg.extraStateDirs;
    stateFiles = sandboxCfg.extraStateFiles;
    readOnlyDirs = sandboxCfg.readOnlyDirs;
    extraEnv = sandboxCfg.extraEnv;
    restrictNetwork = sandboxCfg.restrictNetwork;
    allowedDomains = sandboxCfg.allowedDomains;
  };

in
{
  options.modules.pi = {
    enable = mkEnableOption "Pi coding agent";

    defaultProvider = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default provider (e.g. 'anthropic', 'openai', 'github-copilot').";
    };

    defaultModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default model (e.g. 'claude-sonnet-4-20250514').";
    };

    extraSettings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Freeform settings merged into ~/.pi/agent/settings.json.
        These are merged on top of existing settings, preserving
        runtime state (auth, sessions, lastChangelogVersion, etc.).
      '';
    };

    skills = {
      local = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Local skill directories (each must contain a SKILL.md).";
      };

      sources = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name for this skill source.";
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
                description = "Skill names to skip.";
              };
              include = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = null;
                description = "If set, ONLY include these skills. null = all.";
              };
            };
          }
        );
        default = [ ];
        description = "External skill sources from flake inputs.";
      };
    };

    agents = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Agent definition files (.md) to deploy to ~/.pi/agent/agents/.";
    };

    extensions = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Extension file paths (TypeScript) to deploy to ~/.pi/agent/extensions/.";
    };

    extensionDirs = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Directory name under ~/.pi/agent/extensions/.";
          };
          src = mkOption {
            type = types.path;
            description = "Source directory to copy.";
          };
        };
      });
      default = [ ];
      description = "Extension directories (for multi-file extensions like subagent/).";
    };

    prompts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Prompt template files (.md) to deploy to ~/.pi/agent/prompts/.";
    };

    rules = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to instructions markdown file. Deployed as ~/.pi/agent/AGENTS.md.";
    };

    sandbox = {
      enable = mkEnableOption "Sandboxed Pi agent binary (pi-sandboxed)";

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
        description = "Base set of packages available inside the sandbox.";
      };

      extraAllowedPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional packages appended to allowedPackages.";
      };

      extraStateDirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional writable directories.
          ~/.pi and ~/.agents are always included so pi can modify and extend itself.
        '';
      };

      extraStateFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional writable files.";
      };

      readOnlyDirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Read-only directories visible inside the sandbox.";
      };

      extraEnv = mkOption {
        type = types.attrsOf types.str;
        default = {
          GITHUB_TOKEN = "$GITHUB_TOKEN";
        };
        description = ''
          Environment variables for the sandbox.
          Use shell variable references (e.g. "$TOKEN") for secrets.
          Includes GITHUB_TOKEN by default.
        '';
      };

      restrictNetwork = mkOption {
        type = types.bool;
        default = false;
        description = "When true, network is limited to allowedDomains.";
      };

      allowedDomains = mkOption {
        type = types.attrsOf (types.either types.str (types.listOf types.str));
        default = { };
        description = ''
          Domains the sandbox can reach when restrictNetwork = true.
          Map domain to "*" (all methods) or a list of HTTP methods.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Install pi-agent
      home.packages = [ pkgs.llm-agents.pi ];

      # Merge settings into ~/.pi/agent/settings.json
      # Preserves existing runtime state (auth, sessions, etc.)
      home.activation.pi-settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PI_DIR="$HOME/.pi/agent"
        mkdir -p "$PI_DIR"
        SETTINGS_JSON='${builtins.toJSON piSettings}'
        SETTINGS_FILE="$PI_DIR/settings.json"
        if [ -f "$SETTINGS_FILE" ]; then
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$SETTINGS_JSON") > "$SETTINGS_FILE.tmp" \
            && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        else
          echo "$SETTINGS_JSON" > "$SETTINGS_FILE"
        fi
      '';
    }

    # Skills — deploy to ~/.agents/skills/ (shared agent skills standard)
    (mkIf (allSkillPaths != [ ]) {
      home.activation.pi-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.agents/skills
        chmod -R u+w $HOME/.agents/skills 2>/dev/null || true

        # Track Nix-managed skills so we don't delete user-installed ones
        MANAGED_FILE="$HOME/.agents/.nix-managed-pi-skills"
        touch "$MANAGED_FILE"

        # Remove previously managed skills
        while IFS= read -r old_skill; do
          if [ -n "$old_skill" ] && [ -d "$HOME/.agents/skills/$old_skill" ]; then
            rm -rf "$HOME/.agents/skills/$old_skill"
          fi
        done < "$MANAGED_FILE"

        # Deploy and record
        > "$MANAGED_FILE"
        ${concatMapStringsSep "\n" (skill: ''
          skill_name=$(strip_nix_hash "$(basename "${skill}")")
          echo "$skill_name" >> "$MANAGED_FILE"
          ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw --delete "${skill}/" "$HOME/.agents/skills/$skill_name/"
        '') allSkillPaths}
      '';
    })

    # Agents
    (mkIf (cfg.agents != [ ]) {
      home.activation.pi-agents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.pi/agent/agents

        # Track Nix-managed agents so we don't delete user-created ones
        MANAGED_FILE="$HOME/.pi/agent/.nix-managed-agents"
        touch "$MANAGED_FILE"

        # Remove previously managed agents
        while IFS= read -r old_agent; do
          if [ -n "$old_agent" ] && [ -f "$HOME/.pi/agent/agents/$old_agent" ]; then
            rm -f "$HOME/.pi/agent/agents/$old_agent"
          fi
        done < "$MANAGED_FILE"

        > "$MANAGED_FILE"
        ${concatMapStringsSep "\n" (agent: ''
          agent_base="$(basename "${agent}")"
          agent_name="$(strip_nix_hash "$agent_base")"
          echo "$agent_name" >> "$MANAGED_FILE"
          cp "${agent}" "$HOME/.pi/agent/agents/$agent_name"
        '') cfg.agents}
      '';
    })

    # Prompts
    (mkIf (cfg.prompts != [ ]) {
      home.activation.pi-prompts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.pi/agent/prompts

        MANAGED_FILE="$HOME/.pi/agent/.nix-managed-prompts"
        touch "$MANAGED_FILE"

        # Remove previously managed prompts
        while IFS= read -r old_prompt; do
          if [ -n "$old_prompt" ] && [ -f "$HOME/.pi/agent/prompts/$old_prompt" ]; then
            rm -f "$HOME/.pi/agent/prompts/$old_prompt"
          fi
        done < "$MANAGED_FILE"

        > "$MANAGED_FILE"
        ${concatMapStringsSep "\n" (prompt: ''
          prompt_base="$(basename "${prompt}")"
          prompt_name="$(strip_nix_hash "$prompt_base")"
          echo "$prompt_name" >> "$MANAGED_FILE"
          cp "${prompt}" "$HOME/.pi/agent/prompts/$prompt_name"
        '') cfg.prompts}
      '';
    })

    # Extensions
    (mkIf (cfg.extensions != [ ] || cfg.extensionDirs != [ ]) {
      home.activation.pi-extensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${stripNixHashScript}
        mkdir -p $HOME/.pi/agent/extensions

        # Track Nix-managed extensions so we don't delete user-created ones
        MANAGED_FILE="$HOME/.pi/agent/.nix-managed-extensions"
        touch "$MANAGED_FILE"

        # Remove previously managed extensions (files and directories)
        while IFS= read -r old_ext; do
          if [ -n "$old_ext" ]; then
            if [[ "$old_ext" == */ ]]; then
              rm -rf "$HOME/.pi/agent/extensions/$old_ext"
            else
              rm -f "$HOME/.pi/agent/extensions/$old_ext"
              rm -rf "$HOME/.pi/agent/extensions/$(echo "$old_ext" | sed 's/\.[^.]*$//')"
            fi
          fi
        done < "$MANAGED_FILE"

        > "$MANAGED_FILE"
        ${concatMapStringsSep "\n" (ext: ''
          ext_path="${ext}"
          ext_base="$(basename "$ext_path")"
          ext_name="$(strip_nix_hash "$ext_base")"
          echo "$ext_name" >> "$MANAGED_FILE"
          cp "${ext}" "$HOME/.pi/agent/extensions/$ext_name"
        '') cfg.extensions}
        ${concatMapStringsSep "\n" (dir: ''
          echo "${dir.name}/" >> "$MANAGED_FILE"
          rm -rf "$HOME/.pi/agent/extensions/${dir.name}"
          ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw "${dir.src}/" "$HOME/.pi/agent/extensions/${dir.name}/"
        '') cfg.extensionDirs}
      '';
    })

    # Rules
    (mkIf (cfg.rules != null) {
      home.activation.pi-rules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.pi/agent
        cp "${cfg.rules}" "$HOME/.pi/agent/AGENTS.md"
      '';
    })

    # Sandbox
    (mkIf sandboxCfg.enable {
      home.packages = [ piSandboxed ];
    })
  ]);
}
