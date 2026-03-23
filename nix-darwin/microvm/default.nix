{ ... }:
{
  # VM definition lives in flake nixosConfigurations for darwin compatibility.
  environment.variables = {
    OPENCODE_MICROVM_WORKSPACE_ROOT = "/Users/samuel.willis/microvm";
    OPENCODE_MICROVM_STATE_DIR = "/Users/samuel.willis/opencode-microvm";
  };
}
