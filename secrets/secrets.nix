let
  primary-key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOxqC9TmYNgf2GHDd8guuj0C1MRXWMU3kaWDzHUl4AM";
  secondary-key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkXaJnC6aITP4MxHIhxTo2iFXmpDiogXnfxJsb368yb";
  github-primary-key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqBgLxog6NG/d2LQ/XQr1NfCxbvTxsAgDLGKV0pNjcf sam@williscloud.org";
  github-secondary-key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfkEyrxhe8xzftrPSHH+1Zkkz7i+0MOoHvPNHzd/J6C sam@williscloud.org";
  keys = [ primary-key secondary-key ];
  github-keys = [ github-primary-key github-secondary-key ];
in {
  # See: https://github.com/ryantm/agenix/issues/17#issuecomment-797174338
  # Workflow for a new machine according to Ryan:
  # 
  # setup a git repo with your nix configuration
  # setup the machine to deploy to with NixOS
  # Use ssh-keyscan to get public ssh key of the machine you set up
  # Add that key to your git repo's secrets.nix file
  # Encrypt or rekey your secrets to use the new SSH key
  # Add the age module to your machine's nix configuration
  # Redeploy nix configuration.

  "tailscale_pre-auth.age".publicKeys = keys;
  "gh_pat.age".publicKeys = github-keys;
}
