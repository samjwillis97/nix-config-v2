{ lib, ... }:

with lib;
{
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
        default = [];
    };
    networkAdapterName = mkOption {
        description = "Name of network adapter";
        type = types.str;
        default = "en01";
    };
    /* configPath = mkOption { */
    /*   description = "Location of this config"; */
    /*   type = types.path; */
    /*   default = "/etc/nixos"; */
    /* }; */
  };
}
