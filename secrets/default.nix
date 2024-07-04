{
  age = {
    secrets = {
      "tailscale_pre-auth" = {
        file = ./tailscale_pre-auth.age;
      };
      "gh_pat" = {
        file = ./gh_pat.age;
      };
      "xtream_password" = {
        file = ./xtream_password.age;
      };
      "wireguard_private-key" = {
        file = ./wireguard_private-key.age;
      };
      "tailscale-microvm" = {
        file = ./tailscale-microvm.age;
      };
    };
    identityPaths = [
      "/var/agenix/id-ed25519-agenix-primary"
      "/var/agenix/github-primary"
      "/var/agenix/iptv-primary"
      "/var/agenix/wireguard-primary"
      "/var/agenix/microvm-primary"
    ];
  };
}
