{ self, nixpkgs, ... }:
let
  microvm = self.inputs.microvm;
  microvmBase = import ./base.nix;
in
{
  nixosConfigurations.work-mbp-agentvm = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      microvm.nixosModules.microvm
      (microvmBase {
        # Keep explicit values to preserve current guest behavior.
        flake = self;
        hostName = "work-mbp-agentvm";
        workspace = "/Users/samuel.willis/microvm/agentvm";
        sshHostKeysPath = "/Users/samuel.willis/microvm/agentvm/ssh-host-keys";
        opencodeStatePath = "/Users/samuel.willis/opencode-microvm";
        mac = "02:00:00:00:10:01";
        enableSsh = true;
        enableFirewall = false;
        vcpu = 8;
        mem = 4096;
      })
    ];
  };

  packages.aarch64-darwin.work-mbp-agentvm =
    self.nixosConfigurations.work-mbp-agentvm.config.microvm.declaredRunner;
}
