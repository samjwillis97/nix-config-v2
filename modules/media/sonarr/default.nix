{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.modules.media.sonarr;
  postgresCfg = config.modules.database.postgres;
  mediaUserEnabled = config.modules.system.users.media;

  user = if mediaUserEnabled then "media" else "sonarr";
  group = if mediaUserEnabled then "media" else "sonarr";

  terraform-executable = pkgs.terraform;

  sonarrTerranixConfig = flake.inputs.terranix.lib.terranixConfiguration {
    system = pkgs.stdenv.system;
    inherit pkgs;

    modules = [ 
      ./terraform.nix
      {
        sonarr = {
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
  options.modules.media.sonarr = {
    enable = mkEnableOption "Enables Sonarr";

    openFirewall = mkEnableOption "Open firewall for Sonarr";

    port = mkOption {
      default = 8989;
      type = types.port;
    };
    apiKey = mkOption {
      default = "00000000000000000000000000000000";
      type = types.string;
    };

    libraryDirectory = mkOption {
      default = "/var/lib/sonarr-library";
      type = types.string;
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

    downloaders = {
      decypharr = mkEnableOption "Enable Decypharr downloader integration";
    };

    indexers = {
      zilean = mkEnableOption "Enable Zilean indexer integration";
      elfhosted = mkEnableOption "Enable elfhosted zilean indexers integration";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.setupSonarrDirs = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.libraryDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.libraryDirectory}
    '';

    systemd.services.sonarr-terraform = {
      description = "Sonarr Terraform Apply";
      after = [ "sonarr.service" ];
      wants = [ "sonarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.curl}/bin/curl --retry-connrefused --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 45 http://localhost:${toString cfg.port}/ping

        export PATH=${pkgs.getent}/bin:$PATH
        STATE_DIR="/var/lib/sonarr-terraform"

        if [ ! -d "$STATE_DIR" ]; then
          mkdir -p "$STATE_DIR"
          cp ${sonarrTerranixConfig} "$STATE_DIR/config.tf.json"
          ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" init -no-color
        else
          cp ${sonarrTerranixConfig} "$STATE_DIR/config.tf.json"
        fi

        ${terraform-executable}/bin/terraform -chdir="$STATE_DIR" apply -auto-approve -no-color

      '';
    };

    modules.database.postgres = mkIf cfg.database.postgres.enable {
      databases = ["sonarr" "sonarr-logs"];
    };

    services.sonarr = {
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
          maindb = "sonarr";
          logdb = "sonarr-logs";
        };
      };
    };
  };
}
