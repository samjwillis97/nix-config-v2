{ ... }:
{
  imports = [
    ../../hm-modules/opencode.nix
  ];

  modules.opencode = {
    enable = true;
    settings = {
      mcp = {
        atlassian = {
          type = "remote";
          url = "https://mcp.atlassian.com/v1/sse";
          enabled = true;
        };
      };
    };
  };
}
