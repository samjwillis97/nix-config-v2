{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.radarr;
in
{
  options.radarr = {
    port = mkOption {
      default = 7878;
      type = types.port;
      description = "The port Radarr will listen on.";
    };

    username = mkOption {
      default = "sam";
      type = types.str;
      description = "The username for Radarr authentication.";
    };

    password = mkOption {
      default = "nixos";
      type = types.str;
      description = "The password for Radarr authentication.";
    };

    apiKey = mkOption {
      default = "";
      type = types.str;
      description = "The API key for Radarr";
    };

    logLevel = mkOption {
      default = "info";
      type = types.enum [
        "info"
        "debug"
        "trace"
      ];
      description = "The log level for Radarr";
    };

    rootFolderPath = mkOption {
      type = types.str;
      default = "/tmp";
      description = "The root folder path for Radarr to store media.";
    };

    zilean = {
      enable = mkEnableOption "Enable Zilean integration";

      baseUrl = mkOption {
        default = "http://localhost:8181";
        type = types.str;
      };
    };

    elfhosted = {
      enable = mkEnableOption "Enable elfhosted Zilean indexers integration";
    };

    decypharr = {
      enable = mkEnableOption "Enable Decypharr integration";

      hostname = mkOption {
        default = "localhost";
        type = types.str;
      };

      port = mkOption {
        default = 8282;
        type = types.port;
      };
    };
  };

  config = {
    # This section defines the providers Terraform needs to download.
    terraform.required_providers.radarr = {
      source = "devopsarr/radarr";
      version = "2.3.3";
    };

    # This section configures the provider itself.
    # It will get the API key from an environment variable at runtime.
    provider.radarr = {
      url = "http://localhost:${toString cfg.port}";
      api_key = cfg.apiKey;
    };

    resource = {
      radarr_host = {
        "main" = {
          instance_name = "Radarr";
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

      radarr_media_management = {
        "main" = {
          # Folders
          create_empty_movie_folders = false;
          delete_empty_folders = false;

          # Importing
          skip_free_space_check_when_importing = true;
          minimum_free_space_when_importing = 100;
          copy_using_hardlinks = true;
          import_extra_files = false;
          extra_file_extensions = "srt,info";

          # File Management
          auto_rename_folders = true;
          auto_unmonitor_previously_downloaded_movies = false;
          download_propers_and_repacks = "preferAndUpgrade";
          enable_media_info = true;
          rescan_after_refresh = "always";
          file_date = "none";
          paths_default_static = false;
          recycle_bin = "";
          recycle_bin_cleanup_days = 7;

          # Permissions
          set_permissions_linux = false;
          chmod_folder = "755";
          chown_group = "media";
        };
      };

      radarr_indexer = {
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

      radarr_download_client_qbittorrent.main = mkIf cfg.decypharr.enable {
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

      radarr_notification_webhook.main = {
        on_download = true;
        on_upgrade = true;
        on_movie_delete = false;
        name = "Autoscan";
        url = "http://localhost:3030/triggers/radarr";
        method = 1;
      };

      radarr_root_folder = {
        main = {
          path = cfg.rootFolderPath;
        };
      };
    };
  };
}
