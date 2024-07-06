{ ... }:
{
  networking.hostName = "steve";

  microvm.mem = 4096;

  services.minecraft-server = {
    enable = true;
    eula = true;
  };
}
