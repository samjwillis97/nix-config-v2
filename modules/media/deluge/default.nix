{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.deluge;
  mediaUserEnabled = config.modules.system.users.media;
in
{
  options.modules.media.deluge = {
    enable = mkEnableOption "Enables Deluge service";

    port = mkOption {
      default = 8112;
      type = types.port;
    };

    listenPorts = mkOption {
      default = [
        6881
        6891
      ];
      type = types.listOf types.port;
    };

    downloadPath = mkOption {
      type = types.string;
      default = "/data/downloads/torrents";
    };

    privateTrackers = mkEnableOption "For use with private trackers";

    networkInterface = mkOption {
      default = null;
      type = types.nullOr types.str;
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;

      user = if mediaUserEnabled then "media" else "deluge";
      group = if mediaUserEnabled then "media" else "deluge";

      web = {
        enable = true;
        port = cfg.port;
      };

      authFile = pkgs.writeTextFile {
        name = "deluge-auth-file";
        text = ''
          localclient::10
          deluge:deluge:10
        '';
      };

      declarative = true;
      # https://trash-guides.info/Downloaders/Deluge/Basic-Setup/
      config = {
        outgoing_interface = cfg.networkInterface;

        pre_allocate_storage = true;

        download_location = cfg.downloadPath;

        max_connections_global = -1;
        max_upload_slots_global = -1;
        max_download_speed = -1; # KiB/s
        max_upload_speed = -1; # KiB/s
        max_half_open_connections = 125;
        max_connections_per_second = 125;

        max_connections_per_torrent = -1;
        max_upload_slots_per_torrent = -1;
        max_upload_speed_per_torrent = -1;
        max_download_speed_per_torrent = -1;

        max_active_limit = -1;
        max_active_downloading = 5;
        max_active_seeding = -1;

        # Let Starr apps manage seeding ratios - advanced

        # TODO: Incoming port - https://protonvpn.com/support/port-forwarding/
        listen_ports = cfg.listenPorts;
        random_port = false;

        upnp = false;
        natpmp = false;

        # Only set true for public trackers, false otherwise
        dht = !cfg.privateTrackers;
        lsd = !cfg.privateTrackers;
        utpex = !cfg.privateTrackers;

        enabled_plugins = [
          "WebUi"
          "Label"
        ];
      };
    };
  };
}
