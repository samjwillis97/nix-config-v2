{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.sam.extraGroups = [ "docker" ];
}
