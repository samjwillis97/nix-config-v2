{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "enable opencode";

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Configuration settings for opencode.";
    };
  };

  config = (
    mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs; [
          opencode
        ];

        home.file.".config/opencode/opencode.json".text = builtins.toJSON (
          cfg.settings
          // {
            "$schema" = "https://opencode.ai/config.json";
          }
        );
      }
    ])
  );
}
