{
  age = {
    secrets = {
      "infra-access-key-id" = {
        file = ./infra-access-key-id.age;
      };
      "infra-secret-access-key" = {
        file = ./infra-secret-access-key.age;
      };
    };
    identityPaths = [ 
      "/var/agenix/aws-infra-primary-key"
    ];
  };
}
