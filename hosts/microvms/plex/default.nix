{ ... }:
{
  imports = [
    ../../../modules/media/plex
    ../../../modules/system/users
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "plex";

  modules.system.users.media = true;

  modules.monitoring.exporters.system.enable = true;

  modules.media = {
    plex = {
      enable = true;
    };
  };

  microvm.shares = [
    {
      source = "/var/lib/media-server-test";
      mountPoint = "/data";
      tag = "media";
      proto = "virtiofs";
      securityModel = "none";
    }
  ];
}
