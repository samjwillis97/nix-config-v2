{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';

  # DeckTape wrapper for macOS using Docker
  decktape-wrapped = pkgs.writeShellScriptBin "decktape" ''
    docker run --rm -t --net=host -v "$(pwd):/slides" astefanutti/decktape "$@"
  '';

  getFilesInDir = (
    dir: ext:
    lib.mapAttrsToList (name: value: dir + ("/" + name)) (
      lib.filterAttrs (key: value: value == "regular" && lib.hasSuffix ext key) (builtins.readDir dir)
    )
  );

  getDirsInDir = (
    dir:
    lib.mapAttrsToList (name: value: dir + ("/" + name)) (
      lib.filterAttrs (key: value: value == "directory") (builtins.readDir dir)
    )
  );

  getDirNames = (
    dir: lib.attrNames (lib.filterAttrs (key: value: value == "directory") (builtins.readDir dir))
  );

  # Get local skill directory names for dedup (local takes priority)
  localSkillNames = getDirNames ./skills;

  # External skill sources - each entry pulls skills from a flake input
  # src:     the flake input (fetched with flake = false)
  # path:    subdirectory containing skill dirs (default: "skills")
  # exclude: skill names to skip (default: [])
  # include: if set, ONLY include these skill names (default: null = all)
  skillSources = [
    {
      src = flake.inputs.superpowers;
      # path = "skills";
      exclude = [ "using-git-worktrees" ];
      # include = [ "test-driven-development" "systematic-debugging" ];
    }
  ];

  # Resolve a single skill source into a list of skill directory paths
  resolveSkillSource =
    {
      src,
      path ? "skills",
      exclude ? [ ],
      include ? null,
    }:
    let
      skillsDir = "${src}/${path}";
      allNames = getDirNames skillsDir;
      selectedNames =
        if include != null then lib.filter (name: lib.elem name allNames) include else allNames;
      filteredNames = lib.filter (
        name: !(lib.elem name exclude) && !(lib.elem name localSkillNames)
      ) selectedNames;
    in
    map (name: "${skillsDir}/${name}") filteredNames;

  # Combine all external skill sources
  externalSkills = lib.concatMap resolveSkillSource skillSources;

  node = pkgs.nodejs_24;

  plugins =
    getFilesInDir ./plugins ".js"
    ++ (if (pkgs.stdenv.isDarwin) then getFilesInDir ./plugins/darwin ".js" else [ ]);

  workEnabled = config.modules.darwin.work;
in
{
  imports = [
    ../../hm-modules/opencode.nix
  ];

  # For some reason with these MCP's you need node globally :(
  home.packages = with pkgs; [
    node
    # hugo
    # go # Required for Hugo modules
    # decktape-wrapped
  ];

  modules.opencode = {
    enable = true;
    plugins = plugins;
    commands = getFilesInDir ./commands ".md";
    agents = getFilesInDir ./agents ".md";
    prompts = getFilesInDir ./prompts ".txt";
    skills = getDirsInDir ./skills ++ externalSkills;
    # agentsmd = ./AGENTS.md;
    settings = {
      share = "disabled";
      provider = lib.mkIf workEnabled {
        amazon-bedrock = {
          options = {
            region = "ap-southeast-2";
            profile = "default";
          };
          models = {
            "anthropic-claude-sonnet-4.5" = {
              id = "{file:~/.config/opencode/bedrock/inference-profile.txt}";
            };
          };
        };
      };
      instructions = [
        ".instructions.md"
        "CONTRIBUTING.md"
        ".cursor/rules/*.md"
        ".github/*.md"
      ];
      tui = {
        scroll_acceleration = {
          enabled = true;
        };
      };
      keybinds = {
        messages_half_page_up = "ctrl+u";
        messages_half_page_down = "ctrl+d";
      };
      permission = {
        external_directory = {
          "~/code/**" = "allow";
        };
        bash = {
          "*" = "ask";
          "git status*" = "allow";
          "git diff*" = "allow";
          "git add*" = "allow";
          "git commit*" = "allow";
          "git checkout*" = "allow";
          "git stash*" = "allow";
          "git log*" = "allow";
          "git show*" = "allow";
          "git remote*" = "allow";
          "git rev-parse*" = "allow";
          "git branch*" = "allow";
          "ls*" = "allow";
          "pwd*" = "allow";
          "mkdir*" = "allow";
          "npm*" = "allow";
          "bun*" = "allow";
          "pnpm*" = "allow";
          "echo*" = "allow";
          "cat*" = "allow";
          "grep*" = "allow";
          "find*" = "allow";
          "fd*" = "allow";
          "rg*" = "allow";
          "wc*" = "allow";
          "jq*" = "allow";
          "sort*" = "allow";
          "head*" = "allow";
          "tail*" = "allow";
          "nix*" = "allow";
          "xargs*" = "allow";
          "true*" = "allow";
          "readlink*" = "allow";
        };
      };
      agent = {
        code-researcher = {
          mode = "subagent";
          prompt = "{file:./prompts/code-researcher.txt}";
          description = "Always use this agent when asked to research a codebase.";
          permission = {
            edit = "deny";
            bash = {
              "*" = "ask";
              "ls*" = "allow";
              "pwd*" = "allow";
              "grep*" = "allow";
              "find*" = "allow";
              "cd*" = "allow";
              "head*" = "allow";
              "tail*" = "allow";
              "wc*" = "allow";
              "rg*" = "allow";
              "sort*" = "allow";
              "true*" = "allow";
              "echo*" = "allow";
              "jq*" = "allow";
              "cat*" = "allow";
            };
            webfetch = "deny";
          };
          tools = {
            "*" = false;
            bash = true;
            read = true;
            grep = true;
            glob = true;
            list = true;
          };
        };
      };
      mcp = {
        atlassian = {
          type = "local";
          command = [
            "${node}/bin/npx"
            "-y"
            "mcp-remote"
            "https://mcp.atlassian.com/v1/sse"
          ];
          enabled = false;
        };
        buildkite = {
          type = "remote";
          url = "https://mcp.buildkite.com/mcp/readonly";
          enabled = false;
          headers = {
            X-Buildkite-Toolsets = "user,pipelines,builds";
          };
        };
        sentry = {
          type = "remote";
          url = "https://mcp.sentry.dev/mcp";
          enabled = false; # Bit annoying,
          oauth = { };
        };
        github = {
          type = "local";
          command = [
            "${github-mcp-wrapped}/bin/github-mcp-wrapped"
            "stdio"
          ];
          enabled = false;
        };
        playwright =
          let
            browsers =
              (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;
            chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;
            exePath = "${pkgs.playwright.browsers}/chromium-${chromium-rev}/chrome-mac-arm64/Google\ Chrome\ for\ Testing.app/Contents/MacOS/Google\ Chrome\ for\ Testing";
          in
          {
            type = "local";
            command = [
              (pkgs.lib.getExe pkgs.playwright-mcp)
              "--executable-path=${exePath}"
              "--user-data-dir=$USER_DATA_DIR"
            ];
            environment = {
              PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright.browsers}";
              PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
              PLAYWRIGHT_NODEJS_PATH = "${node}/bin/node";
              USER_DATA_DIR = "$TMPDIR/chrome-mcp";
            };
            enabled = false;
          };
        httpcraft = {
          type = "local";
          command = [
            "${pkgs.httpcraft-mcp}/bin/httpcraft-mcp"
          ];
          enabled = false;
        };
      };
    };
  };
}
