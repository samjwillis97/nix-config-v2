{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.modules.media.prowlarr;
in
{
  options.modules.media.prowlarr = {
    enable = mkEnableOption "Enables Prowlarr service";

    config = {
      port = mkOption {
        default = 9696;
        type = types.port;
      };
      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };
    };
  };

  config = mkIf cfg.enable {
    services.prowlarr.enable = true;

    system.activationScripts.makeProwlarrConfig =
      let
        configFile = pkgs.writeTextFile {
          name = "prowlarr-config.xml";
          text = ''
            <Config>
              <BindAddress>*</BindAddress>
              <Port>${toString cfg.config.port}</Port>
              <ApiKey>${cfg.config.apiKey}</ApiKey>
              <AuthenticationMethod>External</AuthenticationMethod>
              <LogLevel>info</LogLevel>
              <AnalyticsEnabled>False</AnalyticsEnabled>
              <LogDbEnabled>False</LogDbEnabled>
              <InstanceName>Prowlarr</InstanceName>
            </Config>'';
        };
        owner = "prowlarr";
        group = "prowlarr";
        outputFile = "/var/lib/prowlarr/config.xml";
      in
      lib.stringAfter [ "var" ] ''
        ${pkgs.coreutils}/bin/cp ${configFile} ${outputFile}
        ${pkgs.coreutils}/bin/chown ${owner}:${group} ${outputFile}
        ${pkgs.coreutils}/bin/chmod 644 ${outputFile}
      '';
  };
}
