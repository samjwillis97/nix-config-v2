{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.zilean;
  standardUserEnabled = config.modules.system.users.standardUser.enable;
  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
  user = if standardUserEnabled then config.modules.system.users.standardUser.username else "docker";

  databaseUsername = config.modules.database.postgres.user;
  databasePassword = config.modules.database.postgres.password;
  databaseName = "zilean";
in
{
  options.modules.media.zilean = {
    enable = mkEnableOption "Enables Zilean";

    dataDirectory = mkOption {
      type = types.str;
      default = "/opt/zilean";
      description = "Directory for Zilean data";
    };
  };
  
  config = mkIf cfg.enable {
    modules.database.postgres = {
      enable = true;
      databases = [
        databaseName
      ];
    };

    system.activationScripts.setupZileanDirs = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:docker ${cfg.dataDirectory}
    '';

    virtualisation.oci-containers.containers = {
      zilean = {
        pull = "missing";
        image = "ipromknight/zilean:latest";
        autoStart = true;
        ports = [
          "8181:8181"
        ];
        environment = {
          Zilean__Database__ConnectionString = "Host=127.0.0.1;Database=${databaseName};Username=${databaseUsername};Password=${databasePassword};Include Error Detail=true;Timeout=30;CommandTimeout=3600;";
        };
        volumes = [
          "${cfg.dataDirectory}:/app/data"
        ];
        extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
      };
    };
  };
}
