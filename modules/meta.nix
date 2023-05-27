{ lib, ... }:

with lib; {
  options.meta = {
    hostname = mkOption {
      description = "PC Hostname";
      type = types.str;
      default = "nixos";
    };
    username = mkOption {
      description = "Main username";
      type = types.str;
      default = "sam";
    };
    extraHomeModules = mkOption {
      description = "list of extra modules to be loaded on the main user";
      type = types.listOf types.path;
      default = [ ];
    };
    networkAdapterName = mkOption {
      description = "Name of network adapter";
      type = types.str;
      default = "en01";
    };
    isDarwin = mkOption {
      description = "Whether system is darwin";
      type = types.bool;
      default = false;
    };
    useHomeManager = mkOption {
      description = "Whether to use home-manager";
      type = types.bool;
      default = true;
    };
    # configPath = mkOption {
    # description = "Location of this config";
    # type = types.path;
    # default = "/etc/nixos";
    # };
  };
}
