{
  config,
  pkgs,
  ...
}:
let
  # Not secret
  githubPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0JQTnmK59i/vGOzMb4MR3KphYThSxEOorbribPp/Y1 sam@williscloud.org";

  allowedSignersFile = pkgs.writeText "git-allowed-signers" ''
    ${config.programs.git.userEmail} namespaces="git" ${githubPublicKey}
  '';
in
{
  imports = [ ../../secrets/github ];

  programs.ssh = {
    enable = true;
    compression = true;
    forwardAgent = true;

    matchBlocks."github.com" = {
      identityFile = config.age.secrets."ssh-key".path;
      identitiesOnly = true;
    };
  };

  # Assuming git is enabled
  programs.git = {
    signing = {
      key = config.age.secrets."ssh-key".path;
      signByDefault = true;
    };

    extraConfig = {
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${allowedSignersFile}";
    };
  };

  home.packages = with pkgs; [ mosh ];
}
