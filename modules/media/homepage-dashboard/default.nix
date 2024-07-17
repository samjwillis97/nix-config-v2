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
  options.modules.media.homepage-dashboard = {
    enable = mkEnableOption "Enables homepage-dashboard";

    port = mkOption {
      default = 8082;
      type = types.port;
    };

    settingOverrides = mkOption {
      type = types.attrs;
      default = { };
    };

    widgets = mkOption {
      type = types.listOf (types.enum [ "time" ]);
      default = [ "time" ];
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

    prowlarr = {
      enable = mkEnableOption "Enable prowlarr service and widgets";

      enableWidget = mkOption {
        type = types.bool;
        default = true;
      };

      group = mkOption {
        type = types.string;
        default = "Downloaders";
      };

      description = mkOption {
        type = types.string;
        default = "Torrent and Usenet indexer";
      };

      icon = mkOption {
        type = types.string;
        default = "prowlarr.png";
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

    deluge = {
      enable = mkEnableOption "Enable deluge service and widgets";

      enableWidget = mkOption {
        type = types.bool;
        default = true;
      };

      group = mkOption {
        type = types.string;
        default = "Downloaders";
      };

      description = mkOption {
        type = types.string;
        default = "Torrent client";
      };

      icon = mkOption {
        type = types.string;
        default = "deluge.png";
      };

      url = mkOption {
        type = types.string;
        default = "http://localhost:8112";
      };

      password = mkOption {
        type = types.string;
        default = "deluge";
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

      settings = {
        language = "en-AU";
        headerStyle = "boxed";
        title = "Dash";
        layout = {
          Media = {
            style = "row";
            columns = 3;
          };
          Downloaders = {
            style = "row";
            columns = 3;
          };
        };
      } // cfg.settingOverrides;

      widgets =
        let
          widgetOptions = {
            "time" = {
              datetime = {
                text_size = "xl";
                format = {
                  dateStyle = "short";
                  timeStyle = "short";
                  hour12 = true;
                };
              };
            };
          };
        in
        builtins.map (v: widgetOptions.${v}) cfg.widgets;

      # so could iterate over the services array with each of the enabled configs
      # if the group exists append, if it doesn't create new

      services =
        let
          serviceMaps = {
            "radarr" = {
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
            };
            "prowlarr" = {
              "Prowlarr" = {
                icon = cfg.prowlarr.icon;
                href = cfg.prowlarr.url;
                siteMonitor = cfg.prowlarr.url;
                description = cfg.prowlarr.description;
                widget = mkIf cfg.prowlarr.enableWidget {
                  type = "prowlarr";
                  url = cfg.prowlarr.url;
                  key = cfg.prowlarr.apiKey;
                };
              };
            };
            "deluge" = {
              "Deluge" = {
                icon = cfg.deluge.icon;
                href = cfg.deluge.url;
                siteMonitor = cfg.deluge.url;
                description = cfg.deluge.description;
                widget = mkIf cfg.deluge.enableWidget {
                  type = "deluge";
                  url = cfg.deluge.url;
                  password = cfg.deluge.password;
                };
              };
            };
          };
        in
        builtins.foldl'
          (
            acc: appKey:
            # if the service is defined above
            if (builtins.hasAttr appKey serviceMaps) then
              # if the services group exists in the accumuluator
              if (builtins.any (v: builtins.hasAttr cfg.${appKey}.group v) acc) then
                # Add onto that group
                builtins.concatLists [
                  (lib.take (lib.lists.findFirstIndex (v: builtins.hasAttr cfg.${appKey}.group v) 0 acc) acc) # this should take elements before the index
                  [
                    {
                      ${cfg.${appKey}.group} =
                        (lib.lists.findFirst (v: builtins.hasAttr cfg.${appKey}.group v) 0 acc).${cfg.${appKey}.group}
                        ++ [ serviceMaps.${appKey} ];
                    }
                  ]
                  (lib.drop ((lib.lists.findFirstIndex (v: builtins.hasAttr cfg.${appKey}.group v) 0 acc) + 1) acc) # this should be the elements after the index
                ]
              else
                # insert into the accumulator
                acc ++ [ { ${cfg.${appKey}.group} = [ serviceMaps.${appKey} ]; } ]
            else
              acc
          )
          [ ]
          (
            [ ]
            ++ (if cfg.radarr.enable then [ "radarr" ] else [ ])
            ++ (if cfg.deluge.enable then [ "deluge" ] else [ ])
            ++ (if cfg.prowlarr.enable then [ "prowlarr" ] else [ ])
          );

      bookmarks = [ ];
    };
  };
}
