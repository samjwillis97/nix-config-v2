{ self, nixpkgs }:
{
  nixosConfigurations.work-mbp-agentvm = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ ];
    specialArgs = { flake = self; };
  };

  packages.aarch64-darwin.work-mbp-agentvm =
    self.nixosConfigurations.work-mbp-agentvm.config.microvm.declaredRunner;
}
