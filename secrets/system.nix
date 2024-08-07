{
  age = {
    secrets = {
      "wireguard_private-key" = {
        file = ./wireguard_private-key.age;
        mode = "444";
        owner = "root";
        group = "systemd-network";
      };
      "p2p-vpn-key" = {
        file = ./p2p-vpn-key.age;
        mode = "444";
        owner = "root";
        group = "systemd-network";
      };
    };
    identityPaths = [ "/var/agenix/wireguard-primary" ];
  };
}
