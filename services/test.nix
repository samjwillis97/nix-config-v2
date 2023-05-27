{ pkgs, ... }: {
  virtualisation.oci-containers.containers = {
    hello-world = {
      image = "nginxdemos/hello";
      user = "root";
      extraOptions = [ "--network=host" ];
      ports = [ "80:80" ];
    };
  };
}
