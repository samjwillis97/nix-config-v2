{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.xteve;
in {
  options.services.xteve = {
    enable = mkEnableOption "Enables xTeve service";

    port = mkOption rec {
      description = mdDoc "xTeve port";
      default = 34400;
      example = default;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {
    # SEE: https://github.com/pierre-emmanuelJ/iptv-proxy
    systemd.services.xteve-start = {
      description = "Startup xTeve";

      serviceConfig.Type = "exec";

      wantedBy = [ "multi-user.target" ];

      script = ''
        echo "Starting xTeve"
        ${pkgs.xteve}/bin/xteve -port="${toString cfg.port}"
      '';
    };
  };
}
