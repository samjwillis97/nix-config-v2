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

    createDeployUser = mkEnableOption "Create a deployer user, used to login with deploy-rs";
  };

  config = {
    environment.systemPackages = mkIf cfg.enable (with pkgs; [ deploy-rs ]);

    users.users.deployer = mkIf cfg.createDeployUser {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "very-complex-password";
      packages = with pkgs; [
        deploy-rs
      ];
      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
          # Github Action Key
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK+XxL2uM1FT0dR3T5cOJxJd+9luPMctdZd+O2LlJsRk sam@Sams-MacBook-Air.local"
        ];
      };
    };

    security.sudo.extraRules = mkIf cfg.createDeployUser [
      {
        users = [ "deployer" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
          }
        ];
      }
    ];
  };
  # // (
}
