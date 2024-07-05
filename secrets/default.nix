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
      "microvm-tailscale" = {
        file = ./microvm/tailscale.age;
      };
      "microvm-ssh-host-key-rsa" = {
        file = ./microvm/ssh-host-key-rsa.age;
      };
      "microvm-ssh-host-key-ecdsa" = {
        file = ./microvm/ssh-host-key-ecdsa.age;
      };
      "microvm-ssh-host-key-ed25519" = {
        file = ./microvm/ssh-host-key-ed25519.age;
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
