{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ops.deploy;
in
{
  options.modules.ops.deploy = {
    enable = mkEnableOption "Enable installing deploy-rs tooling";
  };

  config = {
    environment.systemPackages = with pkgs; [ deploy-rs ];
  };
}
