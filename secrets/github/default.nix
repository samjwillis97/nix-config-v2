{
  age = {
    secrets = {
      "gh_pat" = {
        file = ./gh_pat.age;
      };
      "ssh-key" = {
        file = ./ssh-key.age;
      };
      "ssh-key.pub" = {
        file = ./ssh-key-public.age;
      };
    };
    identityPaths = [ "/var/agenix/github-primary" ];
  };
}
