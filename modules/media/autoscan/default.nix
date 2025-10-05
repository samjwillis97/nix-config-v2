{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.autoscan;

  mediaUserEnabled = config.modules.system.users.media;
  user = if mediaUserEnabled then "media" else "docker";
  group = if mediaUserEnabled then "media" else "docker";

  plexTokenTemplate = "@plex-token@";

  finalConfigFile = "${cfg.dataDirectory}/config.yaml";
  configFile = pkgs.writers.writeYAML "config.yaml" {
    minimum-age = "0m";
    scan-delay = "5s";
    scan-stats = "1h";
    anchors = [
      "${cfg.debridMountLocation}/version.txt"
    ];
    port = cfg.port;
    triggers = {
      sonarr = [
        {
          name = "sonarr";
          priority = 1;
        }
      ];
      radarr = [
        {
          name = "radarr";
          priority = 1;
        }
      ];
    };
    targets = {
      plex = [] ++ (if cfg.plex.enable then [{
        url = cfg.plex.url;
        token = plexTokenTemplate;
      }] else []);
    };
  };

  autoscan = pkgs.buildGoModule (finalAttrs: {
    name = "autoscan";
    version = "1.4.0";

    vendorHash = "sha256-/Lc5AabPQsIknIwnGAXwqgrZKJo2QOPDD7FcgkfBJ8Q=";

    src = pkgs.fetchFromGitHub {
      owner = "Cloudbox";
      repo = "autoscan";
      rev = "v${finalAttrs.version}";
      sha256 = "sha256-cW/mOjXzVwCf/FBtAh4kCz9jJOzUnOuOsUTGfJ9XyLk=";
    };
  });
in
{
  options.modules.media.autoscan= {
    enable = mkEnableOption "Enables autoscan";

    openFirewall = mkEnableOption "Open firewall for autoscan";

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/autoscan";
      description = "Path to autoscan data directory";
    };

    port = mkOption {
      default = 3030;
      type = types.port;
      description = "Port for autoscan";
    };

    debridMountLocation = mkOption {
      type = types.str;
      default = "/mnt/decypharr/realdebrid";
      description = "Path where Real-Debrid fs is mounted";
    };

    plex = {
      enable = mkEnableOption "Enable Plex integration";

      url = mkOption {
        type = types.str;
        default = "http://localhost:32400";
        description = "URL to Plex server";
      };

      tokenFile = mkOption {
        type = types.str;
        default = "";
        description = "Path to Plex auth token file";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    system.activationScripts.setupAutoscan = lib.stringAfter [ "var" ] ''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/cp ${configFile} ${finalConfigFile}

      ${optionalString cfg.plex.enable ''
        secret=$(cat "${cfg.plex.tokenFile}")
        ${pkgs.gnused}/bin/sed -i "s#${plexTokenTemplate}#$secret#" "${finalConfigFile}"
      ''}
    '';

    environment.systemPackages = [ autoscan ];

    systemd.services.autoscan = {
      description = "autoscan";
      after = [ "docker-decypharr.service" "plex.service" ];
      wants = [ "docker-decypharr.service" "plex.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "exec";
      };
      environment = {
        HOME = "/root";
      };
      restartIfChanged = true;
      script = ''
        ${autoscan}/bin/autoscan \
         --config="${finalConfigFile}" \
         --database="${cfg.dataDirectory}/autoscan.db" \
         --log="${cfg.dataDirectory}/activity.log"
      '';
    };
  };
}
