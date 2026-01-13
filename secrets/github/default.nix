{
  age = {
    secrets = {
      "gh_pat" = {
        file = ./gh_pat.age;
      };
      "ssh-key" = {
        file = ./ssh-key.age;
        path = "/home/sam/.ssh/ssh-key";
      };
      "ssh-key.pub" = {
        file = ./ssh-key-public.age;
        path = "/home/sam/.ssh/ssh-key.pub";
      };
    };
    identityPaths = [ "/var/agenix/github-primary" ];
  };
}
