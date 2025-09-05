{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.prowlarr;
in
{
  options.prowlarr = {
    port = mkOption {
      default = 9696;
      type = types.port;
      description = "The port Prowlarr will listen on.";
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

    logLevel = mkOption {
      default = "info";
      type = types.enum [ "info" "debug" "trace" ];
      description = "The log level for Prowlarr.";
    };

    apiKey = mkOption {
      default = "";
      type = types.string;
      description = "The API key for Prowlarr";
    };

    zilean = {
      enable = mkEnableOption "Enable Zilean integration";

      baseUrl = mkOption {
        default = "http://localhost:8181";
        type = types.string;
      };
    };

    sonarr = {
      enable = mkEnableOption "Enable Sonarr integration";

      baseUrl = mkOption {
        default = "http://localhost:8989";
        type = types.string;
      };

      apiKey = mkOption {
        default = "";
        type = types.string;
      };

      prowlarrUrl = mkOption {
        default = "http://localhost:${toString cfg.port}";
        type = types.string;
      };
    };
  };

  config = {
    # This section defines the providers Terraform needs to download.
    terraform.required_providers.prowlarr = {
      source = "devopsarr/prowlarr";
      version = "3.0.2";
    };

    # This section configures the provider itself.
    # It will get the API key from an environment variable at runtime.
    provider.prowlarr = {
      url = "http://localhost:${toString cfg.port}";
      api_key = cfg.apiKey;
    };

    resource = {
      prowlarr_host = {
        "main" = {
          instance_name = "Prowlarr";
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

      prowlarr_indexer = {
        "zilean" = mkIf cfg.zilean.enable {
          enable = true;
          app_profile_id = 1;
          name = "Zilean";
          implementation = "Torznab";
          config_contract = "TorznabSettings";
          protocol = "torrent";
          priority = 25;
          fields = [
            {
              name = "baseUrl";
              text_value = cfg.zilean.baseUrl + "/torznab";
            }
            {
              name = "apiPath";
              text_value = "/api";
            }
          ];
        };
      };

      prowlarr_application_sonarr = {
        "main" = mkIf cfg.sonarr.enable {
          name = "Sonarr";
          sync_level = "fullSync";
          base_url = cfg.sonarr.baseUrl;
          prowlarr_url = cfg.sonarr.prowlarrUrl;
          api_key = cfg.sonarr.apiKey;
        };
      };
    };
  };
}
