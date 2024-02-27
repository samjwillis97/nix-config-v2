{
  username = "test-user";
  uid = 1000;
  shell = "zsh";
  extraGroups =
    [ "wheel" "networkmanager" "video" "docker" "libvirtd" "qemu-libvirtd" ];
  isNormalUser = true;
  isHomeManaged = true;
  homeModules = [ ../home-manager/theme ];
}
