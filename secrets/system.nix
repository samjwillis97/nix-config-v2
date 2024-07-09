{
  age = {
    secrets = {
      "wireguard_private-key" = {
        file = ./wireguard_private-key.age;
        mode = "444";
        owner = "root";
        group = "systemd-network";
      };
    };
    identityPaths = [
      "/var/agenix/wireguard-primary"
    ];
  };
}
