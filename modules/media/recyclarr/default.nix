{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  inherit (import ../../../lib/curl.nix { inherit pkgs; }) mkCurlCommand;

  cfg = config.modules.media.recyclarr;
  radarrEnabled = config.modules.media.radarr.enable;
  sonarrEnabled = config.modules.media.sonarr.enable;

  mkRadarrRequest =
    args:
    let
      curlArgs = removeAttrs (
        args
        // {
          headers = {
            "X-Api-Key" = cfg.radarr.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "${cfg.radarr.url}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);

  mkSonarrRequest =
    args:
    let
      curlArgs = removeAttrs (
        args
        // {
          headers = {
            "X-Api-Key" = cfg.sonarr.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "${cfg.sonarr.url}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);
in
{
  imports = [
    ../radarr
    ../sonarr
  ];

  options.modules.media.recyclarr = {
    enable = mkEnableOption "Enables Recyclarr";

    sonarr = {
      enable = mkEnableOption "Enables for Sonarr";

      url = mkOption {
        default = "http://localhost:8989";
        type = types.string;
      };

      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };

      config = mkOption {
        type = types.attrs;
        default = {
          web-1080p-v4 = {
            base_url = cfg.sonarr.url;
            api_key = cfg.sonarr.apiKey;

            media_naming = {
              series = "default";
              season = "default";
              episodes = {
                rename = true;
                standard = "default";
                daily = "default";
                anime = "default";
              };
            };

            include = [
              # Comment out any of the following includes to disable them
              { template = "sonarr-quality-definition-series"; }
              { template = "sonarr-v4-quality-profile-web-1080p"; }
              { template = "sonarr-v4-custom-formats-web-1080p"; }
            ];

            custom_formats = [ { quality_profiles = [ { name = "WEB-1080p"; } ]; } ];
          };
        };
      };
    };

    radarr = {
      enable = mkEnableOption "Enables for Radarr";

      url = mkOption {
        default = "http://localhost:7878";
        type = types.string;
      };

      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };

      config = mkOption {
        type = types.attrs;
        default = {
          hd-bluray-web = {
            base_url = cfg.radarr.url;
            api_key = cfg.radarr.apiKey;

            media_naming = {
              folder = "plex-tmdb";
              movie = {
                rename = true;
                standard = "plex-tmdb";
              };
            };

            include = [
              # Comment out any of the following includes to disable them
              { template = "radarr-quality-definition-movie"; }
              { template = "radarr-quality-profile-hd-bluray-web"; }
              { template = "radarr-custom-formats-hd-bluray-web"; }
            ];

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            custom_formats = [
              {
                trash_ids = [ "9f6cbff8cfe4ebbc1bde14c7b7bec0de" ]; # IMAX Enhanced
                quality_profiles = [
                  {
                    name = "HD Bluray + WEB";
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.recyclarr ];

    systemd.services.recyclarr-radarr-sync = mkIf (cfg.radarr.enable && radarrEnabled) {
      description = "configuring radarr with recyclarr";
      wants = [ "radarr.service" ];
      after = [ "radarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          radarrStatusCheck = mkRadarrRequest { uri = "/ping"; };

          radarrConfig = pkgs.writers.writeYAML "radarr-recyclarr-config.yaml" {
            radarr = cfg.radarr.config;
          };
        in
        ''
          echo "Check if radarr is up"
          ${radarrStatusCheck}
          echo "Radarr is now running"
          ${pkgs.recyclarr}/bin/recyclarr sync radarr -c ${radarrConfig}
        '';
    };

    systemd.services.recyclarr-sonarr-sync = mkIf (cfg.sonarr.enable && sonarrEnabled) {
      description = "configuring sonarr with recyclarr";
      wants = [ "sonarr.service" ];
      after = [ "sonarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          sonarrStatusCheck = mkSonarrRequest { uri = "/ping"; };

          sonarrConfig = pkgs.writers.writeYAML "sonarr-recyclarr-config.yaml" {
            sonarr = cfg.sonarr.config;
          };
        in
        ''
          echo "Check if sonarr is up"
          ${sonarrStatusCheck}
          echo "Radarr is now running"
          ${pkgs.recyclarr}/bin/recyclarr sync sonarr -c ${sonarrConfig}
        '';
    };
  };
}
