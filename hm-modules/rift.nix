{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.rift;

  tomlFormat = pkgs.formats.toml { };

  riftPkg = pkgs.rustPlatform.buildRustPackage rec {
    pname = "rift";
    version = "v0.0.4.1-beta";

    src = pkgs.fetchFromGitHub {
      owner = "acsandmann";
      repo = pname;
      rev = version;
      sha256 = "3iAM+TX0W6tBp4uSWtEptb9VrOOhBk9S5HXo6ItA974=";
    };

    cargoHash = "sha256-KsbbeuVEkvZgRLbP9ZMBYnRVNMOuxtJpXb3Us9ewiGY=";

    meta = {
      description = "Rift is a tiling window manager for macOS that focuses on performance and usability. ";
      homepage = "https://github.com/acsandmann/rift";
      maintainers = [ ];
    };
  };
in
{

  options.modules.rift = {
    enable = mkEnableOption "an i3-like window manager for macOS";

    package = mkOption {
      type = types.package;
      default = riftPkg;
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "rift/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "config" cfg.settings;
      };
    };
  };
}
