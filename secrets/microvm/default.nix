{
  age = {
    secrets = {
      "microvm-tailscale" = {
        file = ./tailscale.age;
      };
      "microvm-ssh-host-key-rsa" = {
        file = ./ssh-host-key-rsa.age;
      };
      "microvm-ssh-host-key-ecdsa" = {
        file = ./ssh-host-key-ecdsa.age;
      };
      "microvm-ssh-host-key-ed25519" = {
        file = ./ssh-host-key-ed25519.age;
      };
      "binary-cache-private-key" = {
        file = ./binary-cache-private-key.age;
      };
      "minio-secret-key" = {
        file = ./minio-secret-key.age;
      };
    };
    identityPaths = [ "/var/agenix/microvm-primary" ];
  };
}
