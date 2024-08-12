{
  age = {
    secrets = {
      "tailscale_pre-auth" = {
        file = ./tailscale_pre-auth.age;
      };
      "home-wifi-SSID" = {
        file = ./home-wifi-ssid.age;
      };
      "home-wifi-PSK" = {
        file = ./home-wifi-psk.age;
      };
    };
    identityPaths = [ "/var/agenix/id-ed25519-agenix-primary" ];
  };
}
