{
  age = {
    secrets = {
      "infra-access-key-id" = {
        file = ./infra-access-key-id.age;
      };
      "infra-secret-access-key" = {
        file = ./infra-secret-access-key.age;
      };
      "borg-bucket-name" = {
        file = ./borg-bucket-name.age;
      };
      "borg-bucket-region" = {
        file = ./borg-bucket-region.age;
      };
    };
    identityPaths = [ "/var/agenix/aws-infra-primary-key" ];
  };
}
