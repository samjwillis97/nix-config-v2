{
  age = {
    secrets = {
      "jira-url" = {
        file = ./jira-url.age;
      };
      "jira-username" = {
        file = ./jira-username.age;
      };
      "jira-token" = {
        file = ./jira-token.age;
      };
    };
    identityPaths = [ "/var/agenix/work-primary" ];
  };
}
