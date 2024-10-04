{
  age = {
    secrets = {
      "paperless-s3-bucket-name" = {
        file = ./s3-bucket-name.age;
      };
      "paperless-s3-backup-bucket-name" = {
        file = ./s3-backup-bucket-name.age;
      };
      "paperless-s3-bucket-region" = {
        file = ./s3-bucket-region.age;
      };
    };
    identityPaths = [ "/var/agenix/microvm-primary" ];
  };
}
