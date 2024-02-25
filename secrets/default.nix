{
  age = {
    secrets = {
      "tailscale_pre-auth" = { file = ./tailscale_pre-auth.age; };
      "gh_pat" = { file = ./gh_pat.age; };
    };
    identityPaths =
      [ "/var/agenix/id-ed25519-agenix-primary" "/var/agenix/github-primary" ];
  };
}
