{
  super,
  flake,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (super.meta) username;
in
{
  imports = [ flake.inputs.home-manager.darwinModules.home-manager ];

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.${username} = {
    home = "/Users/${username}";
    # FIXME: why I can't use `pkgs.zsh` here?
    shell = "/run/current-system/sw/bin/zsh";
  };

  home-manager = {
    useUserPackages = true;
    users.${username} = import ../users/${username};
    extraSpecialArgs = {
      inherit flake system super;
    };
  };

  # I dont like this being here, need to come up with better modules
  system.activationScripts.postActivation.text = ''
    appsDir="/Applications/Nix Apps"
    if [ -d "$appsDir" ]; then
      rm -rf "$appsDir/1Password.app"
    fi

    app="/Applications/1Password.app"
    if [ -L "$app" ] || [ -f "$app"  ]; then
      rm "$app"
    fi
    install -o root -g wheel -m0555 -d "$app"

    rsyncFlags=(
      --archive
      --checksum
      --chmod=-w
      --copy-unsafe-links
      --delete
      --no-group
      --no-owner
    )
    ${lib.getBin pkgs.rsync}/bin/rsync "''${rsyncFlags[@]}" \
      ${pkgs._1password-gui}/Applications/1Password.app/ /Applications/1Password.app
  '';
}
