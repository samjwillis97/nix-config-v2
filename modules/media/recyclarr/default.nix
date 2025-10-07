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

  configFile = pkgs.writers.writeYAML "settings.yaml" {
    git_path = "${pkgs.git}/bin/git";
    repositories = {
      trash_guides = {
        clone_url = cfg.repositoryConfig.trash_guides.cloneUrl;
      };
      config_templates = {
        lone_url = cfg.repositoryConfig.config_templates.cloneUrl;
      };
    };
    log_janitor = {
      max_files = 1;
    };
  };

  # trashGuideRepo = builtins.fetchGit {
  #   url = cfg.repositoryConfig.trash_guides.cloneUrl;
  #   rev = cfg.repositoryConfig.trash_guides.sha;
  # };
in
{
  imports = [
    ../radarr
    ../sonarr
  ];

  options.modules.media.recyclarr = {
    enable = mkEnableOption "Enables Recyclarr";

    repositoryConfig = {
      trash_guides = {
        cloneUrl = mkOption {
          default = "https://github.com/samjwillis97/Guides.git";
          type = types.string;
        };
      };

      config_templates = {
        cloneUrl = mkOption {
          default = "https://github.com/samjwillis97/config-templates.git";
          type = types.string;
        };
      };
    };

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

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            include = [
              # Comment out any of the following includes to disable them
              { template = "sonarr-quality-definition-series"; }
              { template = "sonarr-v4-quality-profile-web-1080p-alternative"; }
              { template = "sonarr-v4-custom-formats-web-1080p"; }
            ];

            custom_formats = [ 
              {
                # Allows x265 HD Releases with HDR/DV
                trash_ids = [
                  "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "WEB-1080p";
                    score = 0;
                  }
                ];
              }
            ];
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
                quality_profiles = [ { name = "HD Bluray + WEB"; } ];
              }
            ];
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts."recyclarr-working-dir" = ''
      mkdir -p /root/.config/recyclarr
      ${pkgs.coreutils}/bin/cp ${configFile} /root/.config/recyclarr/settings.yml
    '';

    systemd.services.recyclarr-sync = let 
      requiredServices = [] 
        ++ (if cfg.radarr.enable then [ "radarr.service" ] else []) 
        ++ (if cfg.sonarr.enable then [ "sonarr.service" ] else []);
    in
    {
      description = "configuring sonarr/radarr with recyclarr";
      wants = requiredServices;
      after = requiredServices;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script =
        let
          radarrStatusCheck = mkRadarrRequest { uri = "/ping"; };

          radarrConfig = pkgs.writers.writeYAML "radarr-recyclarr-config.yaml" {
            radarr = cfg.radarr.config;
          };

          sonarrStatusCheck = mkSonarrRequest { uri = "/ping"; };

          sonarrConfig = pkgs.writers.writeYAML "sonarr-recyclarr-config.yaml" {
            sonarr = cfg.sonarr.config;
          };
        in
        ''
          ${optionalString cfg.radarr.enable ''
            echo "Check if radarr is up"
            ${radarrStatusCheck}
            echo "Radarr is now running"
            ${pkgs.recyclarr}/bin/recyclarr sync radarr -c ${radarrConfig}
          ''}

          ${optionalString cfg.sonarr.enable ''
            echo "Check if sonarr is up"
            ${sonarrStatusCheck}
            echo "Sonarr is now running"
            ${pkgs.recyclarr}/bin/recyclarr sync sonarr -c ${sonarrConfig}
          ''}
        '';
    };
  };
}
