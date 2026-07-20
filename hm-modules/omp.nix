{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    concatMapStringsSep
    ;

  cfg = config.modules.omp;
  # sandboxCfg = cfg.sandbox;

  # Import agent-sandbox
  agentSandbox = import flake.inputs.agent-sandbox { inherit pkgs; };
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };

  dapAdapters = {
    node = {
      command = "${pkgs.vscode-js-debug}/bin/js-debug";
      args = [ "--stdio" ];
      languages = [
        "javascript"
        "typescript"
      ];
      fileTypes = [
        ".cjs"
        ".cts"
        ".js"
        ".jsx"
        ".mjs"
        ".mts"
        ".ts"
        ".tsx"
      ];
      rootMarkers = [
        "package.json"
        "tsconfig.json"
      ];
      launchDefaults = {
        type = "pwa-node";
        request = "launch";
      };
    };
  };

  skills = {
    sources = [
      {
        name = "mattpocock/skills";
        src = flake.inputs.mattpocock-skills;
        path = "skills/engineering";
        include = [
          "codebase-design"
          "domain-modeling"
          "grill-with-docs"
          "implement"
          "improve-codebase-architecture"
          "to-spec"
          "to-tickets"
          "wayfinder"
        ];
      }
    ];
  };

  getDirNames =
    dir: lib.attrNames (lib.filterAttrs (_: value: value == "directory") (builtins.readDir dir));

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
      filteredNames = lib.filter (n: !(builtins.elem n exclude)) selectedNames;
    in
    map (n: "${skillsDir}/${n}") filteredNames;

  allSkillPaths = builtins.concatMap resolveSkillSource skills.sources;

  settings = {
    symbolPreset = "nerd";
    theme = {
      dark = "titanium";
      light = "light";
    };
    setupVersion = 1;
    debug.enabled = true;
    advisor.enabled = false;
    skills.enabled = true;
    modelRoles = {
      default = "github-copilot/gpt-5.6-terra:medium";
      advisor = "github-copilot/gpt-5.6-terra:medium";
      task = "github-copilot/gpt-5.6-luna:high";
      smol = "github-copilot/gpt-5.6-luna:low";
      slow = "github-copilot/gpt-5.6-terra:high";
      plan = "github-copilot/gpt-5.6-terra:high";
      tiny = "github-copilot/gemini-3.5-flash";
      commit = "github-copilot/claude-haiku-4.5";
    };
  };

  lspPackages = with pkgs; [
    nixd
    nil
    typescript-language-server
  ];

  # Sandbox derivation
  ompSandboxed = agentSandbox.mkSandbox {
    pkg = pkgs.llm-agents.omp;
    binName = "omp";
    outName = "omp";
    allowedPackages =
      with pkgs;
      [
        file
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
        vscode-js-debug
        python3
        openssh
        difftastic
        gnused
        nix
        man
        llm-agents.omp
      ]
      ++ lspPackages;
    stateDirs = [
      "$HOME/.omp"
    ];
    stateFiles = [
    ];
    readOnlyDirs = [ ];
    extraEnv = {
      GITHUB_TOKEN = "$GITHUB_TOKEN";
    };
    restrictNetwork = true;
    allowedDomains = {
      # Copilot required domains (MITM-filtered)
      "githubcopilot.com" = "*";

      # GitHub API/web: tunnelled (raw TCP passthrough) so `gh` trusts the
      # real GitHub cert. gh is a Go binary and on macOS ignores the proxy's
      # CA bundle (SSL_CERT_FILE), so it cannot use the MITM path.
      "github.com" = "tunnel";
      "api.github.com" = "tunnel";

      "openai.com" = "tunnel";
      "chatgpt.com" = "tunnel";

      "ui.shadcn.com" = [
        "GET"
        "HEAD"
      ];

      # Domain required for user content
      "githubusercontent.com" = [
        "GET"
        "HEAD"
      ];
      "npmjs.org" = [
        "GET"
        "HEAD"
      ];
      "nodejs.org" = [
        "GET"
        "HEAD"
      ];
      "developer.mozilla.org" = [
        "GET"
        "HEAD"
      ];
      "omp.sh" = [
        "GET"
        "HEAD"
      ];
      "html.duckduckgo.com" = [
        "GET"
        "HEAD"
      ];
      "typescriptlang.org" = [
        "GET"
        "HEAD"
      ];
    };
  };
in
{
  options.modules.omp = {
    enable = mkEnableOption "Oh-My-Pi coding agent";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ ompSandboxed ];
      home.file = {
        ".omp/agent/config.yml".source = yamlFormat.generate "omp-config.yml" settings;
        ".omp/agent/dap.json".source = jsonFormat.generate "omp-dap.json" {
          adapters = dapAdapters;
        };
      };
    }

    (mkIf (allSkillPaths != [ ]) {
      home.activation.omp-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        skills_dir="$HOME/.omp/agent/skills"
        mkdir -p "$skills_dir"
        chmod -R u+w "$skills_dir" 2>/dev/null || true

        managed_file="$HOME/.omp/agent/.nix-managed-skills"
        touch "$managed_file"

        while IFS= read -r old_skill; do
          if [ -n "$old_skill" ] && [ -d "$skills_dir/$old_skill" ]; then
            rm -rf "$skills_dir/$old_skill"
          fi
        done < "$managed_file"

        > "$managed_file.new"
        ${concatMapStringsSep "\n" (skill: ''
          skill_name="$(basename "${skill}")"
          echo "$skill_name" >> "$managed_file.new"
          ${pkgs.rsync}/bin/rsync -rL --chmod=u+rw --delete "${skill}/" "$skills_dir/$skill_name/"
        '') allSkillPaths}
        mv "$managed_file.new" "$managed_file"
      '';
    })
  ]);
}
