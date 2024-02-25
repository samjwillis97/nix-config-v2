{ 
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    config = {
      server_port = 8123;
    };
  };
}
