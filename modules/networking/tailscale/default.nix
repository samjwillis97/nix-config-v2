# thank you: https://tailscale.com/blog/nixos-minecraft/
# and: https://github.com/ghuntley/ghuntley/blob/cb78de98fbaf1ea97d5c8465e155516f3e72132d/ops/nixos-modules/tailscale.nix
{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.networking.tailscale;
in
{
  options.modules.networking.tailscale = {
    enable = mkEnableOption "Enables tailscale";

    allowExitNode = mkEnableOption "Allows using node as exit node";

    advertiseRoutes = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = ''["10.0.0.0/24"]'';
      description = "List of routes to advertise";
    };

    authKeyFile = mkOption {
      type =
        with types;
        oneOf [
          path
          str
        ];
      description = "File containing authKey";
      example = "/var/lib/myKey";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    networking.firewall = {
      # enable the firewall
      enable = true;

      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" ];

      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];

      checkReversePath = "loose";
    };

    boot.kernel.sysctl = mkIf cfg.allowExitNode {
      "net.ipv6.conf.all.forwarding" = "1"; # for tailscale exit node
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        echo "Waiting for tailscaled to settle"
        sleep 2

        if [ ! -f ${cfg.authKeyFile} ]; then
            echo "Unable to get authkey ${cfg.authKeyFile}"
            exit 0
        fi

        echo "Checking tailscale status"
        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          echo "Tailscale already running"
          exit 0
        fi

        key=`cat ${cfg.authKeyFile}`

        # otherwise authenticate with tailscale
        echo "Connect to tailscale"
        ${tailscale}/bin/tailscale up --auth-key $key
      '';
    };
  };
}
