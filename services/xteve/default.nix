{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ xteve ];

  systemd.services.xteve-start = {
    description = "Startup xTeve";

    serviceConfig.Type = "oneshot";

    script = ''
      echo "Starting xTeve"
      ${pkgs.xteve}/bin/xteve
    '';
  };
}
