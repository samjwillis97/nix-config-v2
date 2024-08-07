{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ssh;
in
{
  options.modules.ops.deploy = {
    addDeployerPrivateKey = mkEnableOption "Add private SSH key for deployment":
  };

  config = { };
}
