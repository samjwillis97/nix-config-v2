{
  age = {
    secrets = {
      "tailscale_pre-auth" = {
        file = ./tailscale_pre-auth.age;
      };
    };
    identityPaths = [ "/var/agenix/id-ed25519-agenix-primary" ];
  };
}
