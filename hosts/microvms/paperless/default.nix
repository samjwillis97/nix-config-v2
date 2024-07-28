{ config, ... }:
{
  imports = [
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
    ../../../modules/storage/s3
  ];

  networking.hostName = "paperless";

  modules = {
    monitoring = {
      promtail = {
        enable = true;
        lokiUrl = "http://insights:3100";
      };

      exporters.system.enable = true;
    };

    storage.s3 = {
      enable = true;
    };
  };
}
