{ pkgs, ... }: {
  home.packages = with pkgs; [ act ];

  # TODO: Get mongodb-memory-server working by exporting the path
  # environment.variables.MONGOMS_SYSTEM_BINARY= "${pkgs.mongodb-5_0}/bin/mongod";
}
