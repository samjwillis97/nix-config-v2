let
  personal-desktop-user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org";
  personal-laptop-user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com";
  personal-desktop =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOd7v84VAa7MqFt3mNenC+hON42PxLEJtBp7FwOm4trj";
  personal-laptop =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYJXNCehyPdJMX0bzsJAyt0Rpi4x+E9KhpiFT5kKNuo";
  testing-vm =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOPqvzlWz+Ti82THdblcmUXZUBQ/Ke0gnvRwlHMouE8";
  keys = [
    personal-desktop-user
    personal-laptop-user
    personal-desktop
    personal-laptop
    testing-vm
  ];
in {
  # See: https://github.com/ryantm/agenix/issues/17#issuecomment-797174338
  # Workflow for a new machine according to Ryan:
  # 
  # setup a git repo with your nix configuration
  # setup the machine to deploy to with NixOS
  # Use ssh-keyscan to get public ssh key of the machine you set up
  # Add that key to your git repo's secrets.nix file
  # Encrypt or rekey your secrets to use the new SSH key
  # Add the age module to your machine's nix configuration
  # Redeploy nix configuration.

  "tailscale_pre-auth.age".publicKeys = keys;
}
