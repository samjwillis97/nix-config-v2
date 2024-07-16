{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.homepage-dashboard;
in
{
  options.modules.media.homepage-dashboard= {
    enable = mkEnableOption "Enables homepage-dashboard";

    port = mkOption {
      default = 8082;
      type = types.port;
    };

    settingOverrides = mkOption {
      type = types.attrs;
      default = {};
    };

    radarr = {
      enable = mkEnableOption "Enable radarr service and widgets";

      enableWidget = mkOption {
        type = types.bool;
        default = true;
      };

      group = mkOption {
        type = types.string;
        default = "Media";
      };

      description = mkOption {
        type = types.string;
        default = "Movie management";
      };

      icon = mkOption {
        type = types.string;
        default = "radarr.png";
      };

      url = mkOption {
        type = types.string;
        default = "http://localhost:7878";
      };

      apiKey = mkOption {
        type = types.string;
        default = "00000000000000000000000000000000";
      };
    };
  };

  # Be careful with permissions issues for data folder
  #   This will hurt down the road a bit when actually trying to use

  # Configuration:
  #   Here is one way using the API: https://github.com/kira-bruneau/nixos-config/blob/5de7ec5e225075f4237722e38c5ec9fa2ed63e6a/environments/media-server.nix#L565
  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;

      widgets = [];

      services = [] ++ (if  cfg.radarr.enable then [
        {
          "${cfg.radarr.group}" = [
          {
            "Radarr" = {
              icon = cfg.radarr.icon;
              href = cfg.radarr.url;
              siteMonitor = cfg.radarr.url;
              description = cfg.radarr.description;
              widget = mkIf cfg.radarr.enableWidget {
                type = "radarr";
                url = cfg.radarr.url;
                key = cfg.radarr.apiKey;
              };
            };
          }
          ];
        }
      ] else []);

      settings = {
        language = "en-AU";
        headerStyle = "boxed";
        title = "Dash";
        layout = {
          Media = {
            style = "row";
            columns = 3;
          };
        };
      } // cfg.settingOverrides;

      bookmarks = [];
    };
  };
}
