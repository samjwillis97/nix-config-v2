{ lib, ... }:
with lib; {
  options.user = {
    shell = mkOption {
      description = "Default shell";
      type = types.enum [ "bash" "zsh" ];
      default = "bash";
    };
  };
}
