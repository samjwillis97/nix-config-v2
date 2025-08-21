{
  age = {
    secrets = {
      "real-debrid-token" = {
        file = ./real-debrid-token.age;
      };
      "tmdb-api-key" = {
        file = ./tmdb-api-key.age;
      };
      "plex-token" = {
        file = ./plex-token.age;
      };
      "overseerr-api-key" = {
        file = ./overseerr-api-key.age;
      };
      "trakt-api-key" = {
        file = ./trakt-api-key.age;
      };
      "dmm-access-token" = {
        file = ./dmm-access-token.age;
      };
      "dmm-refresh-token" = {
        file = ./dmm-refresh-token.age;
      };
      "dmm-client-id" = {
        file = ./dmm-client-id.age;
      };
      "dmm-client-secret" = {
        file = ./dmm-client-secret.age;
      };
    };
    identityPaths = [ "/var/agenix/mediaserver-primary-key" ];
  };
}
