{ config, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    ../../modules/ops/deploy.nix
    ../../secrets/mediaserver
    ../../secrets/aws
  ];

  modules = {
    ops.deploy = {
      createDeployUser = true;
    };

    system.users.media = true;

    database.postgres = {
      enable = true;
      backup = {
        enable = true;
        s3Bucket = "mediaserver-pgsql-backup-b96bddb";
        awsAccessKeyIdFile = config.age.secrets.infra-access-key-id.path;
        awsSecretAccessKeyFile = config.age.secrets.infra-secret-access-key.path;
      };
    };

    virtualisation.docker = {
      enable = true;
      useHostNetwork = true;
    };

    media = {
      sonarr = {
        enable = true;
        openFirewall = true;
        libraryDirectory = "/shows";
        database.postgres.enable = true;
        downloaders = {
          decypharr = true;
        };
        indexers = {
          elfhosted = true;
        };
      };

      radarr = {
        enable = true;
        openFirewall = true;
        libraryDirectory = "/movies";
        database.postgres.enable = true;
        downloaders = {
          decypharr = true;
        };
        indexers = {
          elfhosted = true;
          savvy = true;
        };
      };

      recyclarr = {
        enable = true;
        sonarr = {
          enable = true;
        };
        radarr = {
          enable = true;
        };
      };

      decypharr = {
        enable = true;
        openFirewall = true;
        realdebrid.tokenFile = config.age.secrets.real-debrid-token.path;
      };

      autoscan = {
        enable = true;
        openFirewall = true;
        plex = {
          enable = true;
          tokenFile = config.age.secrets.plex-token.path;
        };
      };

      plex.enable = true;

      overseerr = {
        enable = true;
        openFirewall = true;
      };
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = lib.mkForce "25.05"; # Did you read the comment?
}
