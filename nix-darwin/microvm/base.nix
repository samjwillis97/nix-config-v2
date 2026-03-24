{ flake, hostName, workspace, opencodeStatePath, mac, extraPackages ? [ ], extraZshInit ? "", enableFirewall ? true, vcpu ? 8, mem ? 4096 }:
{ pkgs, ... }:
{
  imports = [ flake.inputs.home-manager.nixosModules.home-manager ];

  networking.hostName = hostName;
  system.stateVersion = "24.05";

  programs.zsh.enable = true;

  users.groups.sam.gid = 1000;
  users.users.sam = {
    isNormalUser = true;
    uid = 1000;
    group = "sam";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.sam = {
    imports = [ ./home.nix ];
    workMicrovm.extraZshInit = extraZshInit;
  };

  services.getty.autologinUser = "sam";

  networking.firewall.enable = enableFirewall;

  environment.systemPackages = with pkgs; [
    git curl wget ripgrep fd jq file which tree gnumake gcc pkg-config neovim
    pkgsCross.gnu64.hello
  ] ++ extraPackages;

  microvm = {
    hypervisor = "vfkit";
    vmHostPackages = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    vfkit.rosetta = {
      enable = true;
      install = true;
    };

    writableStoreOverlay = "/nix/.rw-store";
    volumes = [
      {
        mountPoint = "/nix/.rw-store";
        image = "nix-store-overlay.img";
        size = 4096;
      }
      {
        mountPoint = "/var";
        image = "var.img";
        size = 8192;
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      {
        proto = "virtiofs";
        tag = "workspace";
        source = workspace;
        mountPoint = "/workspace";
      }
      {
        proto = "virtiofs";
        tag = "opencode-state";
        source = opencodeStatePath;
        mountPoint = "/home/sam/opencode-microvm";
      }
    ];

    interfaces = [
      {
        type = "user";
        id = "usernet";
        inherit mac;
      }
    ];

    vcpu = vcpu;
    mem = mem;
    socket = "control.socket";
  };
}
