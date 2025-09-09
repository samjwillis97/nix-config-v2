{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.sonarr;
in
{
  options.sonarr = {
    port = mkOption {
      default = 8989;
      type = types.port;
      description = "The port Sonarr will listen on.";
    };

    username = mkOption {
      default = "sam";
      type = types.string;
      description = "The username for Prowlarr authentication.";
    };

    password = mkOption {
      default = "nixos";
      type = types.string;
      description = "The password for Prowlarr authentication.";
    };

    apiKey = mkOption {
      default = "";
      type = types.string;
      description = "The API key for Sonarr";
    };

    logLevel = mkOption {
      default = "info";
      type = types.enum [ "info" "debug" "trace" ];
      description = "The log level for Prowlarr.";
    };

    rootFolderPath = mkOption {
      type = types.str;
      default = "/tmp";
      description = "The root folder path for Sonarr to store media.";
    };

    zilean = {
      enable = mkEnableOption "Enable Zilean integration";

      baseUrl = mkOption {
        default = "http://localhost:8181";
        type = types.string;
      };
    };

    elfhosted = {
      enable = mkEnableOption "Enable elfhosted Zilean indexers integration";
    };

    decypharr = {
      enable = mkEnableOption "Enable Decypharr integration";

      hostname = mkOption {
        default = "localhost";
        type = types.string;
      };

      port = mkOption {
        default = 8282;
        type = types.port;
      };
    };
  };

  config = {
    # This section defines the providers Terraform needs to download.
    terraform.required_providers.sonarr = {
      source = "devopsarr/sonarr";
      version = "3.4.0";
    };

    # This section configures the provider itself.
    # It will get the API key from an environment variable at runtime.
    provider.sonarr = {
      url = "http://localhost:${toString cfg.port}";
      api_key = cfg.apiKey;
    };

    resource = {
      sonarr_host = {
        "main" = {
          instance_name = "Sonarr";
          application_url = "";
          url_base = "";
          bind_address = "*";
          port = cfg.port;
          proxy = {
            enabled = false;
          };
          ssl = {
            enabled = false;
            certificate_validation = "disabled";
          };
          logging = {
            log_level = cfg.logLevel;
            log_size_limit = 1;
          };
          authentication = {
            method = "forms";
            username = cfg.username;
            password = cfg.password;
            required = "disabledForLocalAddresses";
          };
          backup = {
            folder = "/backup";
            interval = 5;
            retention = 10;
          };
          update = {
            mechanism = "external";
            branch = "develop";
          };
        };
      };

      sonarr_media_management = {
        "main" = {
          # Folders
          create_empty_folders        = false;
          delete_empty_folders        = false;

          # Importing
          episode_title_required      = "never";
          skip_free_space_check       = true;
          minimum_free_space          = 100;
          hardlinks_copy              = true;
          import_extra_files          = false;
          extra_file_extensions       = "srt,info";

          # File Management
          unmonitor_previous_episodes = false;
          download_propers_repacks    = "preferAndUpgrade";
          enable_media_info           = true;
          rescan_after_refresh        = "always";
          file_date                   = "none";
          recycle_bin_path            = "";
          recycle_bin_days            = 7;

          # Permissions
          set_permissions             = false;
          chmod_folder                = "755";
          chown_group                 = "media";
        };
      };

      sonarr_indexer = {
        "zilean" = mkIf cfg.zilean.enable {
          enable_automatic_search = true;
          enable_interactive_search = true;
          enable_rss = true;
          name = "Zilean (terraform)";
          priority = 20;
          implementation = "Torznab";
          protocol = "torrent";
          config_contract = "TorznabSettings";
          base_url = cfg.zilean.baseUrl + "/torznab";
          api_path = "/api";
        };
        "elfhosted" = mkIf cfg.elfhosted.enable {
          enable_automatic_search = true;
          enable_interactive_search = true;
          enable_rss = true;
          name = "Elfhosted (terraform)";
          priority = 25;
          implementation = "Torznab";
          protocol = "torrent";
          config_contract = "TorznabSettings";
          base_url = "https://zilean.elfhosted.com/torznab";
          api_path = "/api";
        };
      };

      sonarr_download_client_qbittorrent.main = mkIf cfg.decypharr.enable {
        enable = true;
        priority = 1;
        name = "Decypharr";
        host = cfg.decypharr.hostname;
        url_base = "";
        username = "http://${cfg.decypharr.hostname}:${toString cfg.decypharr.port}";
        password = cfg.apiKey;
        port = cfg.decypharr.port;
        use_ssl = false;
        sequential_order = false;
      };

      sonarr_notification_webhook.main = {
        on_download = true;
        on_upgrade = true;
        name = "Autoscan";
        url = "http://localhost:3030/triggers/sonarr";
        method   = 1;
      };

      sonarr_root_folder = {
        main = {
          path = cfg.rootFolderPath;
        };
      };
    };
  };
}
