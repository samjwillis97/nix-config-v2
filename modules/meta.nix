{ lib, ... }:

with lib;
{
  options.meta = {
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
    /* configPath = mkOption { */
    /*   description = "Location of this config"; */
    /*   type = types.path; */
    /*   default = "/etc/nixos"; */
    /* }; */
  };
}
