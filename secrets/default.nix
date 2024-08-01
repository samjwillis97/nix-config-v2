{
  age = {
    secrets = {
      "tailscale_pre-auth" = {
        file = ./tailscale_pre-auth.age;
      };
      "gh_pat" = {
        file = ./gh_pat.age;
      };
      "xtream_password" = {
        file = ./xtream_password.age;
      };
      "microvm-tailscale" = {
        file = ./microvm/tailscale.age;
      };
      "microvm-ssh-host-key-rsa" = {
        file = ./microvm/ssh-host-key-rsa.age;
      };
      "microvm-ssh-host-key-ecdsa" = {
        file = ./microvm/ssh-host-key-ecdsa.age;
      };
      "microvm-ssh-host-key-ed25519" = {
        file = ./microvm/ssh-host-key-ed25519.age;
      };
      "infra-access-key-id" = {
        file = ./aws/infra-access-key-id.age;
      };
      "infra-secret-access-key" = {
        file = ./aws/infra-secret-access-key.age;
      };
      "paperless-s3-bucket-name" = {
        file = ./paperless/s3-bucket-name.age;
      };
      "paperless-s3-backup-bucket-name" = {
        file = ./paperless/s3-backup-bucket-name.age;
      };
      "paperless-s3-bucket-region" = {
        file = ./paperless/s3-bucket-region.age;
      };
    };
    identityPaths = [
      "/var/agenix/id-ed25519-agenix-primary"
      "/var/agenix/github-primary"
      "/var/agenix/iptv-primary"
      "/var/agenix/microvm-primary"
      "/var/agenix/aws-infra-primary-key"
      "/var/agenix/paperless-primary-key"
    ];
  };
}
