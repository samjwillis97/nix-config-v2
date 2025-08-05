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
          enabled = false;
        };
        github = {
          type = "local";
          command = [
            "${github-mcp-wrapped}/bin/github-mcp-wrapped"
            "stdio"
          ];
          enabled = true;
        };
      };
    };
  };
}
