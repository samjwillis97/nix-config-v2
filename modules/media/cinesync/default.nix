{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.cinesync;
  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
  boolToString = x: if x then "true" else "false";
in
{
  options.modules.media.cinesync = {
    enable = mkEnableOption "Enables CineSync";

    openFirewall = mkEnableOption "Expose through firewall";

    tmdbApiKeyFile = mkOption {
      type = types.str;
      default = "";
      description = "TMDB API key for metadata retrieval";
    };

    dependsOn = mkOption {
      type = types.listOf types.string;
      default = [ ];
      description = "List of containers that required";
    };

    enableAllAutomation = mkOption {
      type = types.bool;
      default = true;
      description = "Enable all? automation";
    };

    directories = {
      source = mkOption {
        type = types.str;
        default = "/data/source";
        description = "Directory for source files";
      };

      destination = mkOption {
        type = types.str;
        default = "/mnt/destination";
        description = "Destination directory for organized library";
      };
    };

    webInterface = {
      uiPort = mkOption {
        type = types.port;
        default = 5173;
        description = "Port for CineSync web interface";
      };

      apiPort = mkOption {
        type = types.port;
        default = 8082;
        description = "Port for CineSync API";
      };

      authEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable authentication for the CineSync web interface";
      };

      username = mkOption {
        type = types.str;
        default = "admin";
        description = "Username for CineSync web interface authentication";
      };

      password = mkOption {
        type = types.str;
        default = "change-this-password";
        description = "Password for CineSync web interface authentication";
      };
    };

    mediaOrganisation = {
      layoutOptions = {
        cinesyncLayout= mkOption {
          type = types.bool;
          default = cfg.mediaOrganisation.contentSeparation.animeSeparation || cfg.mediaOrganisation.contentSeparation."4KSeparation" || cfg.mediaOrganisation.layoutOptions.showResolutionStructure || cfg.mediaOrganisation.layoutOptions.movieResolutionStructure;
          description = "Use simplified Movies/Shows layout";
        };

        showResolutionStructure = mkOption {
          type = types.bool;
          default = false;
          description = "Use resolution structure for shows";
        };

        movieResolutionStructure = mkOption {
          type = types.bool;
          default = false;
          description = "Use resolution structure for movies";
        };
      };

      contentSeparation = {
        animeSeparation = mkOption {
          type = types.bool;
          default = true;
          description = "Separate anime content into dedicated folders";
        };

        "4KSeparation" = mkOption {
          type = types.bool;
          default = true;
          description = "Separate 4K content into dedicated folders";
        };
      };

      fileProcessing = {
        enableRenaming = mkOption {
          type = types.bool;
          default = true;
          description = "Enable file renaming based on metadata";
        };

        renameTags = mkOption {
          type = types.listOf types.str;
          default = [
            "VideoCodec"
            "DynamicRange"
            "AudioCodec"
            "AudioChannels"
            "Resolution"
          ];
          description = "List of tags to include for renaming files";
        };

        allowedExtensions = mkOption {
          type = types.listOf types.str;
          default = [
            ".mp4"
            ".mkv"
            ".srt"
            ".avi"
            ".mov"
            ".divx"
          ];
          description = "List of allowed file extensions for processing";
        };
      };
    };

    integrations = {
      remoteStorage = {
        enableMountVerification = mkOption {
          type = types.bool;
          default = false;
          description = "Enable rclone mount verification";
        };

        mountVerificationInterval = mkOption {
          type = types.int;
          default = 30;
          description = "Interval in seconds for rclone mount verification";
        };
      };

      plex = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Plex integration for media organization";
        };

        url = mkOption {
          type = types.str;
          default = "http://127.0.0.1:32400";
          description = "URL for the Plex server";
        };

        tokenFile = mkOption {
          type = types.str;
          default = "";
          description = "Plex server authentication token";
        };
      };
    };

    metadata = {
      database = {
        directory = mkOption {
          type = types.str;
          default = "/opt/cinesync/db";
          description = "Directory for CineSync metadata database";
        };
      };

      sources = {
        enableTmdbFolderId = mkOption {
          type = types.bool;
          default = true;
          description = "Enable TMDB ID in folder structure";
        };
        enableImdbFolderId = mkOption {
          type = types.bool;
          default = true;
          description = "Enable IMDB ID in folder structure";
        };
        enableTvdbFolderId = mkOption {
          type = types.bool;
          default = false;
          description = "Enable TVDB ID in folder structure";
        };
      };
    };
  };

  config = mkIf cfg.enable (
    let
      tmdbApiKeyTemplate = "@tmdb-api-key@";
      plexTokenTemplate = "@plex-token@";

      finalConfigDir = "/var/lib/cinesync";
      finalConfigFile = "${finalConfigDir}/.env";

      envFile = pkgs.writeText "cinesync-env" ''
        # REQUIRED
        SOURCE_DIR=${cfg.directories.source}
        DESTINATION_DIR=${cfg.directories.destination}
        TMDB_API_KEY=${tmdbApiKeyTemplate}

        CINESYNC_IP="0.0.0.0"
        AUTO_PROCESSING_ENABLED=${boolToString cfg.enableAllAutomation}

        # Web Interface
        CINESYNC_UI_PORT=${toString cfg.webInterface.uiPort}
        CINESYNC_API_PORT=${toString cfg.webInterface.apiPort}
        CINESYNC_AUTH_ENABLED=${boolToString cfg.webInterface.authEnabled}
        CINESYNC_USERNAME=${cfg.webInterface.username}
        CINESYNC_PASSWORD=${cfg.webInterface.password}

        # Media Organisation
        ## Layout Options
        CINESYNC_LAYOUT=${boolToString cfg.mediaOrganisation.layoutOptions.cinesyncLayout}
        SHOW_RESOLUTION_STRUCTURE=${boolToString cfg.mediaOrganisation.layoutOptions.showResolutionStructure}
        MOVIE_RESOLUTION_STRUCTURE=${boolToString cfg.mediaOrganisation.layoutOptions.movieResolutionStructure}

        ## Content Seperation
        ANIME_SEPARATION=${boolToString cfg.mediaOrganisation.contentSeparation.animeSeparation}
        4K_SEPARATION=${boolToString cfg.mediaOrganisation.contentSeparation."4KSeparation"}

        ## File Processing
        ALLOWED_EXTENSIONS=${builtins.concatStringsSep "," cfg.mediaOrganisation.fileProcessing.allowedExtensions}
        RENAME_ENABLED=${boolToString cfg.mediaOrganisation.fileProcessing.enableRenaming}
        RENAME_TAGS=${builtins.concatStringsSep "," cfg.mediaOrganisation.fileProcessing.renameTags}

        # Integrations
        ## Remote Storage
        RCLONE_MOUNT=${boolToString cfg.integrations.remoteStorage.enableMountVerification}
        MOUNT_CHECK_INTERVAL=${toString cfg.integrations.remoteStorage.mountVerificationInterval}

        ## Plex
        ENABLE_PLEX_UPDATE=${boolToString cfg.integrations.plex.enable}
        PLEX_URL=${cfg.integrations.plex.url}
        PLEX_TOKEN=${plexTokenTemplate}

        # Metadata
        ## Sources
        TMDB_FOLDER_ID=${boolToString cfg.metadata.sources.enableTmdbFolderId}
        IMDB_FOLDER_ID=${boolToString cfg.metadata.sources.enableImdbFolderId}
        TVDB_FOLDER_ID=${boolToString cfg.metadata.sources.enableTvdbFolderId}
      '';
    in
    {
      system.activationScripts."cinesync-runtime-config-builder" = ''
        mkdir -p ${finalConfigDir}
        tmdbApiKey=$(cat "${cfg.tmdbApiKeyFile}")
        plexToken=$(cat "${cfg.integrations.plex.tokenFile}")

        envFile="${envFile}"

        ${pkgs.gnused}/bin/sed "s#${tmdbApiKeyTemplate}#$tmdbApiKey#" "$envFile" | ${pkgs.gnused}/bin/sed "s#${plexTokenTemplate}#$plexToken#" > ${finalConfigFile}
      '';

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        cfg.webInterface.uiPort
        cfg.webInterface.apiPort
      ];

      virtualisation.oci-containers.containers = {
        cinesync = {
          pull = "missing";
          image = "sureshfizzy/cinesync:v3";
          autoStart = true;
          volumes = [
            "${finalConfigFile}:/app/.env"
            "${cfg.metadata.database.directory}:/app/db"
            "${cfg.directories.source}:${cfg.directories.source}"
            "${cfg.directories.destination}:${cfg.directories.destination}"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          ports = [
            "${toString cfg.webInterface.uiPort}:${toString cfg.webInterface.uiPort}"
            "${toString cfg.webInterface.apiPort}:${toString cfg.webInterface.apiPort}"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          dependsOn = cfg.dependsOn;
        };
      };
    }
  );
}
