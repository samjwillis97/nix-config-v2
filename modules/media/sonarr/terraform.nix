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

      sonarr_indexer = {
        "zilean" = mkIf cfg.zilean.enable {
          enable_automatic_search = true;
          name = "Zilean";
          implementation = "Torznab";
          protocol = "torrent";
          config_contract = "TorznabSettings";
          base_url = cfg.zilean.baseUrl + "/torznab";
          api_path = "/api";
        };
      };

      sonarr_root_folder = {
        main = {
          path = cfg.rootFolderPath;
        };
      };
    };
  };
}
