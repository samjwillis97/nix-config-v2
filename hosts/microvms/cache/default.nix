{
  pkgs,
  config,
  lib,
  ...
}:
let
  binaryStoreCacheDir = "/cache";
  port = 8080;
in
{
  imports = [
    ../../../modules/media/homepage-dashboard
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
  ];

  networking.hostName = "cache";
  networking.firewall.enable = lib.mkForce false;

  modules.monitoring = {
    promtail = {
      enable = true;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = true;
  };

  microvm.shares = [
    {
      source = "/mnt/nas/nix-store";
      mountPoint = binaryStoreCacheDir;
      tag = "media";
      proto = "virtiofs";
      securityModel = "none";
    }
  ];

  environment.systemPackages = with pkgs; [ attic-server ];

  services.atticd = {
    enable = true;

    # Replace with absolute path to your credentials file
    credentialsFile = config.age.secrets."atticd-credentials".path;

    settings = {
      listen = "[::]:${toString port}";

      storage = {
        type = "local";
        path = binaryStoreCacheDir;
      };

      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "30 days";
      };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = false;

    clientMaxBodySize = "0";

    virtualHosts."${config.networking.hostName}" = {
      forceSSL = false;
      enableACME = false;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
