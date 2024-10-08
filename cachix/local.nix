{
  nix.settings = {
    substituters = [ "http://cache/hello" ];
    trusted-public-keys = [
      "hello:FQLbUnzWwgsM443PxYlHY9MpAwrjvDWFplcoFPPrn+c= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
