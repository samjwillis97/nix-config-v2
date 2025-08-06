{ config, pkgs, ... }:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';

  node = pkgs.nodejs;
in
{
  imports = [
    ../../hm-modules/opencode.nix
  ];

  # For some reason with these MCP's you need node globally :(
  home.packages = [
    node
  ];

  modules.opencode = {
    enable = true;
    settings = {
      share = "disabled";
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
          "bun" = "allow";
          "pnpm" = "allow";
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
          enabled = true;
        };
        github = {
          type = "local";
          command = [
            "${github-mcp-wrapped}/bin/github-mcp-wrapped"
            "stdio"
          ];
          enabled = true;
        };
        playwright = {
          type = "local";
          command = [
            (pkgs.lib.getExe pkgs.playwright-mcp)
          ];
          enabled = true;
        };
        context7 = {
          type = "local";
          command = [
            "${node}/bin/npx"
            "-y"
            "@upstash/context7-mcp"
          ];
          enabled = true;
        };
      };
    };
  };
}
