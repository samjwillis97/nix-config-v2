{
  age = {
    secrets = {
      "gh_pat" = {
        file = ./gh_pat.age;
      };
    };
    identityPaths = [ "/var/agenix/github-primary" ];
  };
}
