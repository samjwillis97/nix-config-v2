{
  flake,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.radarr;
  postgresCfg = config.modules.database.postgres;
  mediaUserEnabled = config.modules.system.users.media;

  user = if mediaUserEnabled then "media" else "radarr";
  group = if mediaUserEnabled then "media" else "radarr";

  terraform-executable = pkgs.terraform;

  radarrTerranixConfig = flake.inputs.terranix.lib.terranixConfiguration {
    system = pkgs.stdenv.system;
    inherit pkgs;

    modules = [ 
      ./terraform.nix
      {
        radarr = {
          port = cfg.port;
          apiKey = cfg.apiKey;

          rootFolderPath = cfg.libraryDirectory;

          zilean.enable = cfg.indexers.zilean;
          elfhosted.enable = cfg.indexers.elfhosted;

          decypharr.enable = cfg.downloaders.decypharr;
        };
      }
    ];
  };
in
{
  options.modules.media.radarr = {
    enable = mkEnableOption "Enables Radarr";

    prometheus = {
      enable = mkEnableOption "Enable prometheus exporter";

      port = mkOption {
        default = 9708;
        type = types.port;
      };
    };

    openFirewall = mkEnableOption "Open firewall for Radarr";

    port = mkOption {
      default = 7878;
      type = types.port;
    };

    apiKey = mkOption {
      default = "00000000000000000000000000000000";
      type = types.string;
    };

    libraryDirectory = mkOption {
      default = "/var/lib/radarr-library";
      type = types.string;
    };


    database = {
      postgres = {
        enable = mkEnableOption "Use PostgreSQL for Radarr";

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

    downloaders = {
      decypharr = mkEnableOption "Enable Decypharr downloader integration";
    };

    indexers = {
      zilean = mkEnableOption "Enable Zilean indexer integration";
      elfhosted = mkEnableOption "Enable elfhosted zilean indexers integration";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.setupRadarrDirs = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.libraryDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.libraryDirectory}
    '';

    systemd.services.radarr-terraform = {
      description = "Radarr Terraform Apply";
      after = [ "radarr.service" ];
      wants = [ "radarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.curl}/bin/curl --retry-connrefused --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 45 http://localhost:${toString cfg.port}/ping

        export PATH=${pkgs.getent}/bin:$PATH
        STATE_DIR="/var/lib/radarr-terraform"

        if [ ! -d "$STATE_DIR" ]; then
          mkdir -p "$STATE_DIR"
          cp ${radarrTerranixConfig} "$STATE_DIR/config.tf.json"
          ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" init -no-color
        else
          cp ${radarrTerranixConfig} "$STATE_DIR/config.tf.json"
        fi

        ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" apply -auto-approve -no-color

      '';
    };

    modules.database.postgres = mkIf cfg.database.postgres.enable {
      databases = ["radarr" "radarr-logs"];
    };

    systemd.services.radarr.wants = mkIf cfg.database.postgres.enable [
      "postgresql.service"
    ];
    systemd.services.radarr.after = mkIf cfg.database.postgres.enable [
      "postgresql.service"
    ];

    services.radarr = {
      enable = true;
      openFirewall = cfg.openFirewall;
      user = user;
      group = group;
      settings = {
        server = {
         port = cfg.port;
        };
        auth = {
          apikey = cfg.apiKey;
        };
        postgres = mkIf cfg.database.postgres.enable {
          host = "127.0.0.1";
          port = 5432;
          user = postgresCfg.user;
          password = postgresCfg.password;
          maindb = "radarr";
          logdb = "radarr-logs";
        };
      };
    };

    services.prometheus = {
      exporters =
        {

        }
        // (mkIf cfg.prometheus.enable {
          exportarr-radarr = {
            enable = true;
            url = "http://127.0.0.1:${toString cfg.config.port}";
            port = cfg.prometheus.port;
            user = user;
            group = group;
            apiKeyFile = pkgs.writeTextFile {
              name = "radarr-key";
              text = cfg.config.apiKey;
            };
          };
        });
    };
  };
}
