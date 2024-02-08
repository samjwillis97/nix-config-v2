{ super, config, lib, pkgs, ... }:
let inherit (super.meta) username shell;
in {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    # shell = pkgs.zsh;
    extraGroups =
      [ "wheel" "networkmanager" "video" "docker" "libvirtd" "qemu-libvirtd" ];
    password = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
    ];
    shell = if shell == "zsh" then pkgs.zsh else pkgs.bash; 
  };

  programs.zsh.enable = if shell == "zsh" then true else false;

}
