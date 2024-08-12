let
  primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKOxqC9TmYNgf2GHDd8guuj0C1MRXWMU3kaWDzHUl4AM";
  secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkXaJnC6aITP4MxHIhxTo2iFXmpDiogXnfxJsb368yb";

  github-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqBgLxog6NG/d2LQ/XQr1NfCxbvTxsAgDLGKV0pNjcf sam@williscloud.org";
  github-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfkEyrxhe8xzftrPSHH+1Zkkz7i+0MOoHvPNHzd/J6C sam@williscloud.org";

  iptv-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOALWUCVS0LGysQaZKrMHq22QNQAAVeb3+1cRKtg9jcE sam@williscloud.org";
  iptv-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGF2/UWwHwsUVS5n1sTEL0Wo9Jp8i+cdB1Ixz7AsPkrB sam@williscloud.org";

  wireguard-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWEpbQNNB5K2FE0QMxU0PPrSTuUr4EnhmJf/+R5qAnh sam@personal-desktop";
  wireguard-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsi1d39cIzleqaxpG7lC+v4wj2qtu0tWSf7DVofJ+yy sam@personal-desktop";

  microvm-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkfdBeKrK1A6ccSOVMsS3e/f5flYOdm7JB0MqgMsIXz sam@personal-desktop";
  microvm-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiV93l9WxEzGa8tYjAj8TWZ2q4Cz+IuGBR/kvRRYZNl sam@personal-desktop";

  aws-infra-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZS7bX4db9yIzSxfmtqnCrYtJfzrJP7POp8X/aYXxp1 sam@personal-desktop";
  aws-infra-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDe1oDK5JLLWudsoaAxGmhRuhtOkfwfNMSNZAoF2bpO sam@personal-desktop";

  paperless-primary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOFi2Que2/gAc8QmcpAPzpkxX7hq9YoN8qHWlKXNBDl sam@personal-desktop";
  paperless-secondary-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMR5c5eojnEtEALkqVElixavek+0JhC8tBaEdSfHCGgJ sam@personal-desktop";

  keys = [
    primary-key
    secondary-key
  ];
  github-keys = [
    github-primary-key
    github-secondary-key
  ];
  iptv-keys = [
    iptv-primary-key
    iptv-secondary-key
  ];
  wireguard-keys = [
    wireguard-primary-key
    wireguard-secondary-key
  ];
  microvm-keys = [
    microvm-primary-key
    microvm-secondary-key
  ];
  aws-infra-keys = [
    aws-infra-primary-key
    aws-infra-secondary-key
  ];
  paperless-keys = [
    paperless-primary-key
    paperless-secondary-key
  ];
in
{
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

  "default/tailscale_pre-auth.age".publicKeys = keys;

  "github/gh_pat.age".publicKeys = github-keys;

  "iptv/xtream_password.age".publicKeys = iptv-keys;

  "wireguard/wireguard_private-key.age".publicKeys = wireguard-keys;
  "wireguard/p2p-vpn-key.age".publicKeys = wireguard-keys;

  "microvm/tailscale.age".publicKeys = microvm-keys;
  "microvm/ssh-host-key-ed25519.age".publicKeys = microvm-keys;
  "microvm/ssh-host-key-rsa.age".publicKeys = microvm-keys;
  "microvm/ssh-host-key-ecdsa.age".publicKeys = microvm-keys;

  "aws/infra-access-key-id.age".publicKeys = aws-infra-keys;
  "aws/infra-secret-access-key.age".publicKeys = aws-infra-keys;

  "paperless/s3-bucket-name.age".publicKeys = paperless-keys;
  "paperless/s3-backup-bucket-name.age".publicKeys = paperless-keys;
  "paperless/s3-bucket-region.age".publicKeys = paperless-keys;
}
