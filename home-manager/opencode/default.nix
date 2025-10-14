{
  config,
  pkgs,
  lib,
  ...
}:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';

  getFilesInDir = (
    dir: ext:
    lib.mapAttrsToList (name: value: dir + ("/" + name)) (
      lib.filterAttrs (key: value: value == "regular" && lib.hasSuffix ext key) (builtins.readDir dir)
    )
  );

  node = pkgs.nodejs_24;

  plugins =
    getFilesInDir ./plugins ".js"
    ++ (if (pkgs.stdenv.isDarwin) then getFilesInDir ./plugins/darwin ".js" else [ ]);
in
{
  imports = [
    ../../hm-modules/opencode.nix
  ];

  # For some reason with these MCP's you need node globally :(
  home.packages = with pkgs; [
    node
    terminal-notifier
    ai-sandbox
  ];

  modules.opencode = {
    enable = true;
    plugins = plugins;
    commands = getFilesInDir ./commands ".md";
    agents = getFilesInDir ./agents ".md";
    settings = {
      share = "disabled";
      instructions = [
        ".instructions.md"
        "CONTRIBUTING.md"
        ".cursor/rules/*.md"
        ".github/*.md"
      ];
      keybinds = {
        messages_half_page_up = "ctrl+u";
        messages_half_page_down = "ctrl+d";
      };
      permission = {
        bash = {
          "*" = "ask";
          "git status" = "allow";
          "git diff" = "allow";
          "git add" = "allow";
          "git commit" = "allow";
          "git checkout" = "allow";
          "git stash" = "allow";
          "ls" = "allow";
          "pwd" = "allow";
          "mkdir" = "allow";
          "npm" = "allow";
          "npm run" = "allow";
          "bun run" = "allow";
          "pnpm run" = "allow";
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
          enabled = false; # Need admin approval to enable
        };
        sentry = {
          type = "local";
          command = [
            "${node}/bin/npx"
            "-y"
            "mcp-remote"
            "https://mcp.sentry.dev/sse"
          ];
          enabled = false; # Bit annoying
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
            exePath = "${pkgs.playwright.browsers}/chromium-${chromium-rev}/chrome-mac/Chromium.app/Contents/MacOS/Chromium";
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
            enabled = true;
          };
        httpcraft = {
          type = "local";
          command = [
            "${pkgs.httpcraft-mcp}/bin/httpcraft-mcp"
          ];
          enabled = true;
        };
      };
    };
  };
}
