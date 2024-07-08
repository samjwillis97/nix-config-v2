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
in
{
  imports = [
    ../radarr
  ];

  options.modules.media.recyclarr = {
    enable = mkEnableOption "Enables Recyclarr";

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
          radarr = {
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
                { template =  "radarr-quality-definition-movie"; }
                { template =  "radarr-quality-profile-hd-bluray-web"; }
                { template =  "radarr-custom-formats-hd-bluray-web"; }
              ];

              custom_formats = [
                {
                  trash_ids = [ "9f6cbff8cfe4ebbc1bde14c7b7bec0de" ]; # IMAX Enhanced
                  quality_profiles = [
                    {
                      name = "HD Bluray + WEB";
                      # score = 0; # Uncomment this line to disable prioritised IMAX Enhanced releases
                    }
                  ];
                }
                {
                  quality_profiles = [ { name = "HD Bluray + WEB"; } ];
                }
              ];
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.recyclarr ];

    systemd.services.recyclarr-radrr = mkIf (cfg.radarr.enable && radarrEnabled) {
      description = "configuring radarr with recyclarr";
      wants = [ "radarr.service" ];
      after = [ "radarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = let 
        radarrStatusCheck = mkRadarrRequest {
          uri = "/ping";
        };

        radarrConfig = pkgs.writers.writeYAML "radarr-recyclarr-config.yaml" cfg.radarr.config;
      in
      ''
      echo "Check if radarr is up"
      ${radarrStatusCheck}
      echo "Radarr is now running"
      ${pkgs.recyclarr}/bin/recyclarr sync radarr -c ${radarrConfig}
      '';
    };
  };
}
