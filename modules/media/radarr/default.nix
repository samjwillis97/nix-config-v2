{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.radarr;
  radarrCfg = config.services.radarr;

  inherit (import ../../../lib/curl.nix { inherit pkgs; }) mkCurlCommand;
in
{
  options.modules.media.radarr = {
    enable = mkEnableOption "Enables Radarr";

    config = {
      port = mkOption {
        default = 7878;
        type = types.port;
      };
      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };
    };
  };

  # Be careful with permissions issues for data folder
  #   This will hurt down the road a bit when actually trying to use

  # Configuration:
  #   Here is one way using the API: https://github.com/kira-bruneau/nixos-config/blob/5de7ec5e225075f4237722e38c5ec9fa2ed63e6a/environments/media-server.nix#L565
  config = mkIf cfg.enable {
    services.radarr.enable = true;

    system.activationScripts.makeRadarrConfig =
      let
        configFile = pkgs.writeTextFile {
          name = "radarr-config.xml";
          text = ''
            <Config>
              <BindAddress>*</BindAddress>
              <Port>${toString cfg.config.port}</Port>
              <ApiKey>${cfg.config.apiKey}</ApiKey>
              <AuthenticationMethod>External</AuthenticationMethod>
              <LogLevel>info</LogLevel>
              <AnalyticsEnabled>False</AnalyticsEnabled>
              <LogDbEnabled>False</LogDbEnabled>
              <InstanceName>Radarr</InstanceName>
              <!-- <SslPort>9898</SslPort> -->
              <!-- <EnableSsl>False</EnableSsl> -->
              <!-- <LaunchBrowser>True</LaunchBrowser> -->
              <!-- <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired> -->
              <!-- <Branch>master</Branch> -->
              <!-- <SslCertPath></SslCertPath> -->
              <!-- <SslCertPassword></SslCertPassword> -->
              <!-- <UrlBase></UrlBase> -->
            </Config>'';
        };
        user = radarrCfg.user;
        group = radarrCfg.group;
        outputFile = "${radarrCfg.dataDir}/config.xml";
      in
      lib.stringAfter [ "var" ] ''
        ${pkgs.coreutils}/bin/cp ${configFile} ${outputFile}
        ${pkgs.coreutils}/bin/chown ${user}:${group} ${outputFile}
        ${pkgs.coreutils}/bin/chmod 444 ${outputFile}
      '';

    systemd.services.radarr-config = {
      description = "Config script to run once radarr has started";
      wants = [ "radarr.service" ];
      after = [ "radarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          getStatus = mkCurlCommand {
            headers = {
              "X-Api-Key" = cfg.config.apiKey;
              "Content-Type" = "application/json";
            };
            url = "localhost:${toString cfg.config.port}/api/v3/system/status";
          };
          setNaming = mkCurlCommand {
            headers = {
              "X-Api-Key" = cfg.config.apiKey;
              "Content-Type" = "application/json";
            };
            method = "PUT";
            url = "localhost:${toString cfg.config.port}/api/v3/config/naming/1";
            dataFile = pkgs.writers.writeJSON "radarr-naming.json" {
              renameMovies = true;
              replaceIllegalCharacters = true;
              standardMovieFormat = "{Movie Title} ({Release Year}) {Quality Title} {MediaInfo VideoCodec}";
              movieFolderFormat = "{Movie Title} ({Release Year})";
            };
          };
        in
        ''
          echo "Starting config"
          echo "Checking status"
          ${getStatus}
          echo "Setting naming conventions"
          ${setNaming}
          echo "Ending config"
        '';
    };
  };
}
