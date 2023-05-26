let
  personal-desktop-user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org";
  personal-laptop-user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com";
  personal-desktop =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOd7v84VAa7MqFt3mNenC+hON42PxLEJtBp7FwOm4trj";
  personal-laptop =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYJXNCehyPdJMX0bzsJAyt0Rpi4x+E9KhpiFT5kKNuo";
  keys = [
    personal-desktop-user
    personal-laptop-user
    personal-desktop
    personal-laptop
  ];
in { "tailscale_pre-auth.age".publicKeys = keys; }
