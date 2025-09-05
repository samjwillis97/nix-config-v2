{
  flake,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.prowlarr;
  postgresCfg = config.modules.database.postgres;
  sonarrCfg = config.modules.media.sonarr;

  terraform-executable = pkgs.terraform;

  prowlarrTerranixConfig = flake.inputs.terranix.lib.terranixConfiguration {
    system = pkgs.stdenv.system;
    inherit pkgs;

    modules = [ 
      ./terraform.nix
      {
        prowlarr = {
          port = cfg.port;
          apiKey = cfg.apiKey;
          username = cfg.auth.username;
          password = cfg.auth.password;
          logLevel = cfg.logLevel;

          zilean = {
            enable = cfg.integrations.zilean.enable;
            baseUrl = cfg.integrations.zilean.baseUrl;
          };

          sonarr = {
            enable = cfg.integrations.sonarr.enable;
            baseUrl = cfg.integrations.sonarr.baseUrl;
            apiKey = cfg.integrations.sonarr.apiKey;
          };
        };
      }
    ];
  };
in
{
  options.modules.media.prowlarr = {
    enable = mkEnableOption "Enables Prowlarr";

    openFirewall = mkEnableOption "Open firewall for Prowlarr";

    port = mkOption {
      default = 9696;
      type = types.port;
    };

    apiKey = mkOption {
      default = "00000000000000000000000000000000";
      type = types.string;
    };

    logLevel = mkOption {
      default = "info";
      type = types.enum [
        "info"
        "debug"
        "trace"
      ];
    };

    auth = {
      username = mkOption {
        default = "sam";
        type = types.string;
      };

      password = mkOption {
        default = "nixos";
        type = types.string;
      };
    };

    database = {
      postgres = {
        enable = mkEnableOption "Use PostgreSQL for Prowlarr";

        user = mkOption {
          default = postgresCfg.user;
          type = types.string;
        };

        password = mkOption {
          default = postgresCfg.password;
          type = types.string;
        };
      };
    };

    integrations = {
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
          default = "http://localhost:${toString sonarrCfg.port}";
          type = types.string;
        };

        apiKey = mkOption {
          default = sonarrCfg.apiKey;
          type = types.string;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.prowlarr-terraform = {
      description = "Prowlarr Terraform Apply";
      after = [ "prowlarr.service" ];
      wants = [ "prowlarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.curl}/bin/curl --retry-connrefused --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 45 http://localhost:${toString cfg.port}/ping
        ${optionalString cfg.integrations.sonarr.enable ''
          ${pkgs.curl}/bin/curl --retry-connrefused --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 45 http://localhost:${toString cfg.integrations.sonarr.baseUrl}/ping
        ''}

        STATE_DIR="/var/lib/prowlarr-terraform"

        if [ ! -d "$STATE_DIR" ]; then
          mkdir -p "$STATE_DIR"
          cp ${prowlarrTerranixConfig} "$STATE_DIR/config.tf.json"
          ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" init -no-color
        else
          cp ${prowlarrTerranixConfig} "$STATE_DIR/config.tf.json"
        fi

        ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" apply -auto-approve -no-color
      '';
      # TODO: Force a double application sync of prowlarr
    };

    modules.database.postgres = mkIf cfg.database.postgres.enable {
      databases = ["prowlarr" "prowlarr-logs"];
    };

    services.prowlarr = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = {
        auth = {
          apikey = cfg.apiKey;
        };
        log.analyticsEnabled = false;
        server = {
          bindaddress = "*";
          port = cfg.port;
        };
        postgres = mkIf cfg.database.postgres.enable {
          host = "127.0.0.1";
          port = 5432;
          user = postgresCfg.user;
          password = postgresCfg.password;
          maindb = "prowlarr";
          logdb = "prowlarr-logs";
        };
      };
    };
  };
}
