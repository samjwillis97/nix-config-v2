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
  workEnabled = config.modules.darwin.work;
  # workEnabled = false;

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
        name = "httpcraft";
        src = flake.inputs.httpcraft;
        path = "skills";
        include = [
          "authoring-httpcraft-configs"
          "using-httpcraft-cli"
        ];
      }
      {
        name = "mattpocock/productivity";
        src = flake.inputs.mattpocock-skills;
        path = "skills/productivity";
        include = [
          "grill-me"
          "grilling"
          "handoff"
          "writing-great-skills"
        ];
      }
      {
        name = "mattpocock/misc";
        src = flake.inputs.mattpocock-skills;
        path = "skills/misc";
        include = [
          "setup-pre-commit"
        ];
      }
      {
        name = "mattpocock/engineering";
        src = flake.inputs.mattpocock-skills;
        path = "skills/engineering";
        include = [
          "code-review"
          "codebase-design"
          "domain-modeling"
          "grill-with-docs"
          "implement"
          "prototype"
          "improve-codebase-architecture"
          "tdd"
          "to-spec"
          "to-tickets"
          "resolving-merge-conflicts"
          "setup-matt-pocock-skills"
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
    setupVersion = 1;
    symbolPreset = "nerd";
    theme = {
      dark = "titanium";
      light = "light";
    };
    statusLine = {
      separator = "slash";
    };
    tui = {
      tight = true;
    };
    personality = "pragmatic";
    debug.enabled = true;
    advisor = {
      enabled = if workEnabled then true else false;
      syncBacklog = 3;
    };
    startup = {
      quiet = true;
      setupWizard = false;
      checkUpdate = false;
      changeLogMode = "hidden";
    };
    features = {
      unexpectedStopDetection = true;
    };
    lsp = {
      enabled = true;
      lazy = true;
      shared = false;
      formatOnWrite = false;
      diagnosticsOnWrite = true;
      diagnosticsOnEdit = true;
      diagnosticsDeduplicate = true;
    };
    github = {
      enabled = true;
      cache.enabled = true;
    };
    browser = {
      enabled = if workEnabled then false else true;
    };
    dev = {
      autoqa = false;
    };
    task = {
      eager = "preferred";
      enableEffort = true;
      enableLsp = true;
      maxRecursionDepth = 3;
    };
    skills.enabled = true;
    modelRoles =
      if workEnabled then
        {
          default = "github-copilot/gpt-5.6-luna:xhigh";
          advisor = "github-copilot/gpt-5.6-luna:max";
          task = "github-copilot/gpt-5.6-luna:high";
          smol = "github-copilot/gpt-5.6-luna:low";
          slow = "github-copilot/gpt-5.6-terra:high";
          plan = "github-copilot/gpt-5.6-sol:high";
          tiny = "github-copilot/gemini-3.5-flash";
          commit = "github-copilot/claude-haiku-4.5";
        }
      else
        {
          default = "openai-codex/gpt-5.6-luna:xhigh";
          advisor = "openai-codex/gpt-5.6-luna:max";
          task = "openai-codex/gpt-5.6-luna:high";
          smol = "openai-codex/gpt-5.6-luna:low";
          slow = "openai-codex/gpt-5.6-terra:high";
          plan = "openai-codex/gpt-5.6-terra:high";
          tiny = "openai-codex/gpt-5.4-nano";
          commit = "openai-codex/gpt-5.4-nano";
        };
  };

  lspPackages = with pkgs; [
    nixd
    nil
    typescript-language-server
  ];

  allowedGetDomains = [
    "githubusercontent.com"
    "npmjs.org"
    "nodejs.org"
    "developer.mozilla.org"
    "omp.sh"
    "html.duckduckgo.com"
    "typescriptlang.org"
    "tanstack.com"
    "shadcn.com"
    "supabase.com"
    "nextjs.org"
    "react.dev"
    "docs.aws.amazon.com"
  ];

  sandboxGetDomainsMapped = builtins.listToAttrs (
    map (domain: {
      name = domain;
      value = [
        "GET"
        "HEAD"
      ];
    }) allowedGetDomains
  );

  # Sandbox derivation
  ompSandboxed = agentSandbox.mkSandbox {
    pkg = pkgs.llm-agents.omp;
    binName = "omp";
    outName = "omp";
    allowedPackages =
      with pkgs;
      [
        curl
        wget
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
        bun
        rsync
        gh
        httpcraft
        lavish-axi
      ]
      ++ lspPackages;
    rwDirs = [
      "$HOME/.omp"
      "$HOME/.npm"
      "$HOME/.cache"
      "$HOME/.config/gh"
      "$HOME/.config/git"
      "$HOME/.config/httpcraft"
      "$HOME/.ssh"
      "/nix/var/nix/daemon-socket"
    ];
    roFiles = [
      "$TMPDIR/agenix/ssh-key"
      "$TMPDIR/agenix/ssh-key.pub"
    ];
    roDirs = [
      "$HOME/code"
    ];
    env = {
      GITHUB_TOKEN = "$GITHUB_TOKEN";
      GH_TOKEN = "$(${pkgs.gh}/bin/gh auth token)";
      # Keep the OAuth callback on the host loopback interface, rather than
      # routing it through the sandbox's outbound filtering proxy.
      NO_PROXY = "localhost,127.0.0.1,::1";
      no_proxy = "localhost,127.0.0.1,::1";
    };
    allowNix = true;
    allowUnixSocketConnect = true;
    allowNetworkBind = true;
    allowedLocalPorts = null;
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
    }
    // sandboxGetDomainsMapped;
  };
in
{
  options.modules.omp = {
    enable = mkEnableOption "Oh-My-Pi coding agent";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [
        pkgs.lavish-axi
      ]
      ++ (
        if workEnabled then
          [
            ompSandboxed
          ]
        else
          with pkgs;
          [
            gh
            llm-agents.omp
          ]
      );
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
