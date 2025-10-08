{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  inherit (import ../../../lib/curl.nix { inherit pkgs; }) mkCurlCommand;

  cfg = config.modules.media.recyclarr;

  mkRadarrRequest =
    args:
    let
      curlArgs = removeAttrs (
        args
        // {
          headers = {
            "X-Api-Key" = cfg.radarr.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "${cfg.radarr.url}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);

  mkSonarrRequest =
    args:
    let
      curlArgs = removeAttrs (
        args
        // {
          headers = {
            "X-Api-Key" = cfg.sonarr.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "${cfg.sonarr.url}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);

  configFile = pkgs.writers.writeYAML "settings.yaml" {
    git_path = "${pkgs.git}/bin/git";
    repositories = {
      trash_guides = {
        clone_url = cfg.repositoryConfig.trash_guides.cloneUrl;
      };
      config_templates = {
        clone_url = cfg.repositoryConfig.config_templates.cloneUrl;
      };
    };
    log_janitor = {
      max_files = 1;
    };
  };
in
{
  imports = [
    ../radarr
    ../sonarr
  ];

  options.modules.media.recyclarr = {
    enable = mkEnableOption "Enables Recyclarr";

    repositoryConfig = {
      trash_guides = {
        cloneUrl = mkOption {
          default = "https://github.com/samjwillis97/Guides.git";
          type = types.string;
        };
      };

      config_templates = {
        cloneUrl = mkOption {
          default = "https://github.com/samjwillis97/config-templates.git";
          type = types.string;
        };
      };
    };

    sonarr = {
      enable = mkEnableOption "Enables for Sonarr";

      url = mkOption {
        default = "http://localhost:8989";
        type = types.string;
      };

      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };

      config = mkOption {
        type = types.attrs;
        default = {
          web-1080p-v4 = {
            base_url = cfg.sonarr.url;
            api_key = cfg.sonarr.apiKey;

            media_naming = {
              series = "default";
              season = "default";
              episodes = {
                rename = true;
                standard = "default";
                daily = "default";
                anime = "default";
              };
            };

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            quality_definition = {
              type = "series";
            };

            quality_profiles = [
              {
                name = "WEB-1080/2160p";
                reset_unmatched_scores = {
                  enabled = true;
                };
                upgrade = {
                  allowed = true;
                  until_quality = "WEB 2160p";
                  until_score = 10000;
                };
                min_format_score = 0;
                quality_sort = "top";
                qualities = [
                  {
                    name = "WEB 2160p";
                    qualities = [
                      "WEBDL-2160p"
                      "WEBRip-2160p"
                    ];
                  }
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "WEBDL-1080p"
                      "WEBRip-1080p"
                    ];
                  }
                  { name = "Bluray-2160p Remux"; }
                  { name = "Bluray-2160p"; }
                  { name = "Bluray-1080p"; }
                  { name = "HDTV-1080p"; }
                  {
                    name = "WEB 720p";
                    qualities = [
                      "WEBDL-720p"
                      "WEBRip-720p"
                    ];
                  }
                  { name = "Bluray-720p"; }
                  { name = "HDTV-720p"; }
                ];
              }
            ];

            custom_formats = [
              {
                trash_ids = [
                  # Unified HDR
                  "505d871304820ba7106b693be6fe4a9e" # HDR

                  # Unwanted
                  "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                  "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                  "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                  "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                  "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1

                  # Misc
                  "ec8fa7296b64e8cd390a1600981f3923" # Repack/Proper
                  "eb3d5cc0a2be0db205fb823640db6a3c" # Repack v2
                  "44e7c4de10ae50265753082e5dc76047" # Repack v3

                  # Streaming Services
                  "d660701077794679fd59e8bdf4ce3a29" # AMZN
                  "f67c9ca88f463a48346062e8ad07713f" # ATVP
                  "77a7b25585c18af08f60b1547bb9b4fb" # CC
                  "36b72f59f4ea20aad9316f475f2d9fbb" # DCU
                  "dc5f2bb0e0262155b5fedd0f6c5d2b55" # DSCP
                  "89358767a60cc28783cdc3d0be9388a4" # DSNP
                  "7a235133c87f7da4c8cccceca7e3c7a6" # HBO
                  "a880d6abc21e7c16884f3ae393f84179" # HMAX
                  "f6cce30f1733d5c8194222a7507909bb" # Hulu
                  "0ac24a2a68a9700bcb7eeca8e5cd644c" # iT
                  "81d1fbf600e2540cee87f3a23f9d3c1c" # MAX
                  "d34870697c9db575f17700212167be23" # NF
                  "1656adc6d7bb2c8cca6acfb6592db421" # PCOK
                  "c67a75ae4a1715f2bb4d492755ba4195" # PMTP
                  "ae58039e1319178e6be73caab5c42166" # SHO
                  "1efe8da11bfd74fbbcd4d8117ddb9213" # STAN
                  "9623c5c9cac8e939c1b9aedd32f640bf" # SYFY
                  "218e93e5702f44a68ad9e3c6ba87d2f0" # HD Streaming Boost

                  # HQ Source Groups
                  "e6258996055b9fbab7e9cb2f75819294" # WEB Tier 01
                  "58790d4e2fdcd9733aa7ae68ba2bb503" # WEB Tier 02
                  "d84935abd3f8556dcd51d4f27e22d0a6" # WEB Tier 03
                  "d0c516558625b04b363fa6c5c2c7cfd4" # WEB Scene
                ];
                assign_scores_to = [
                  { name = "WEB-1080/2160p"; }
                ];
              }
              # Allows x265 HD Releases with HDR/DV
              {
                trash_ids = [
                  "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "WEB-1080/2160p";
                    score = 0;
                  }
                ];
              }
              {
                trash_ids = [
                  "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                ];
                assign_scores_to = [
                  { name = "WEB-1080/2160p"; }
                ];
              }
              # Dolby Vision
              {
                trash_ids = [
                  "0c4b99df9206d2cfac3c05ab897dd62a" # HDR10+ Boost
                  "7c3a61a9c6cb04f52f1544be6d44a026" # DV Boost
                ];
                assign_scores_to = [
                  { name = "WEB-1080/2160p"; }
                ];
              }
            ];
          };
        };
      };
    };

    radarr = {
      enable = mkEnableOption "Enables for Radarr";

      url = mkOption {
        default = "http://localhost:7878";
        type = types.string;
      };

      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };

      config = mkOption {
        type = types.attrs;
        default = {
          hd-bluray-web = {
            base_url = cfg.radarr.url;
            api_key = cfg.radarr.apiKey;

            media_naming = {
              folder = "plex-tmdb";
              movie = {
                rename = true;
                standard = "plex-tmdb";
              };
            };

            delete_old_custom_formats = true;
            replace_existing_custom_formats = true;

            quality_definition = {
              type = "movie";
            };

            quality_profiles = [
              {
                name = "U/HD Bluray + WEB";
                reset_unmatched_scores = {
                  enabled = true;
                };
                upgrade = {
                  allowed = true;
                  until_quality = "Bluray-2160p";
                  until_score = 10000;
                };
                min_format_score = 0;
                quality_sort = "top";
                qualities = [
                  { name = "Bluray-2160p"; }
                  {
                    name = "WEB 2160p";
                    qualities = [
                      "WEBDL-2160p"
                      "WEBRip-2160p"
                    ];
                  }
                  { name = "Bluray-1080p"; }
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "WEBDL-1080p"
                      "WEBRip-1080p"
                    ];
                  }
                  { name = "Bluray-720p"; }
                ];
              }
            ];

            custom_formats = [
              {
                trash_ids = [
                  # HQ Release Groups
                  "4d74ac4c4db0b64bff6ce0cffef99bf0" # UHD Bluray Tier 01
                  "a58f517a70193f8e578056642178419d" # UHD Bluray Tier 02
                  "e71939fae578037e7aed3ee219bbe7c1" # UHD Bluray Tier 03
                  "ed27ebfef2f323e964fb1f61391bcb35" # HD Bluray Tier 01
                  "c20c8647f2746a1f4c4262b0fbbeeeae" # HD Bluray Tier 02
                  "5608c71bcebba0a5e666223bae8c9227" # HD Bluray Tier 03
                  "c20f169ef63c5f40c2def54abaf4438e" # WEB Tier 01
                  "403816d65392c79236dcb6dd591aeda4" # WEB Tier 02
                  "af94e0fe497124d1f9ce732069ec8c3b" # WEB Tier 03

                  # Misc
                  "e7718d7a3ce595f289bfee26adc178f5" # Repack/Proper
                  "ae43b294509409a6a13919dedd4764c4" # Repack2
                  "5caaaa1c08c1742aa4342d8c4cc463f2" # Repack3

                  # Unwanted
                  "ed38b889b31be83fda192888e2286d83" # BR-DISK
                  "e6886871085226c3da1830830146846c" # Generated Dynamic HDR
                  "90a6f9a284dff5103f6346090e6280c8" # LQ
                  "e204b80c87be9497a8a6eaff48f72905" # LQ (Release Title)
                  "b8cd450cbfa689c0259a01d9e29ba3d6" # 3D
                  "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
                  "0a3f082873eb454bde444150b70253cc" # Extras
                  "712d74cd88bceb883ee32f773656b1f5" # Sing-Along Versions
                  "cae4ca30163749b891686f95532519bd" # AV1

                  # Streaming Services
                  "cc5e51a9e85a6296ceefe097a77f12f4" # BCORE
                  "16622a6911d1ab5d5b8b713d5b0036d4" # CRiT
                  "2a6039655313bf5dab1e43523b62c374" # MA
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
              {
                trash_ids = [
                  # Streaming Services
                  "b3b3a6ac74ecbd56bcdbefa4799fb9df" # AMZN
                  "40e9380490e748672c2522eaaeb692f7" # ATVP
                  "84272245b2988854bfb76a16e60baea5" # DSNP
                  "509e5f41146e278f9eab1ddaceb34515" # HBO
                  "5763d1b0ce84aff3b21038eea8e9b8ad" # HMAX
                  "526d445d4c16214309f0fd2b3be18a89" # Hulu
                  "e0ec9672be6cac914ffad34a6b077209" # iT
                  "6a061313d22e51e0f25b7cd4dc065233" # MAX
                  "170b1d363bd8516fbf3a3eb05d4faff6" # NF
                  "c9fd353f8f5f1baf56dc601c4cb29920" # PCOK
                  "e36a0ba1bc902b26ee40818a1d59b8bd" # PMTP
                  "c2863d2a50c9acad1fb50e53ece60817" # STAN
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
              # Advanced Audio Formats
              {
                trash_ids = [
                  "496f355514737f7d83bf7aa4d24f8169" # TrueHD Atmos
                  "2f22d89048b01681dde8afe203bf2e95" # DTS X
                  "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                  "1af239278386be2919e1bcee0bde047e" # DD+ ATMOS
                  "3cafb66171b47f226146a0770576870f" # TrueHD
                  "dcf3ec6938fa32445f590a4da84256cd" # DTS-HD MA
                  "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                  "e7c2fcae07cbada050a0af3357491d7b" # PCM
                  "8e109e50e0a0b83a5098b056e13bf6db" # DTS-HD HRA
                  "185f1dd7264c4562b9022d963ac37424" # DD+
                  "f9f847ac70a0af62ea4a08280b859636" # DTS-ES
                  "1c1a4c5e823891c75bc50380a6866f73" # DTS
                  "240770601cc226190c367ef59aba7463" # AAC
                  "c2998bd0d90ed5621d8df281e839436e" # DD
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
              {
                trash_ids = [
                  "e0c07d59beb37348e975a930d5e50319" # Criterion Collection
                  "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
              # Allowing x265 HD releases with HDR/DV
              {
                trash_ids = [
                  "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "U/HD Bluray + WEB";
                    score = 0;
                  }
                ];
              }
              {
                trash_ids = [
                  "839bea857ed2c0a8e084f3cbdbd65ecb" # x265 (no HDR/DV)
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
              # Dolby Vision
              {
                trash_ids = [
                  "b337d6812e06c200ec9a2d3cfa9d20a7" # DV Boost
                  "caa37d0df9c348912df1fb1d88f9273a" # HDR10+ Boost
                ];
                assign_scores_to = [
                  { name = "U/HD Bluray + WEB"; }
                ];
              }
            ];
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts."recyclarr-working-dir" = ''
      mkdir -p /root/.config/recyclarr
      ${pkgs.coreutils}/bin/cp ${configFile} /root/.config/recyclarr/settings.yml
    '';

    systemd.services.recyclarr-sync =
      let
        requiredServices =
          [ ]
          ++ (if cfg.radarr.enable then [ "radarr.service" ] else [ ])
          ++ (if cfg.sonarr.enable then [ "sonarr.service" ] else [ ]);
      in
      {
        description = "configuring sonarr/radarr with recyclarr";
        wants = requiredServices;
        after = requiredServices;
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script =
          let
            radarrStatusCheck = mkRadarrRequest { uri = "/ping"; };

            radarrConfig = pkgs.writers.writeYAML "radarr-recyclarr-config.yaml" {
              radarr = cfg.radarr.config;
            };

            sonarrStatusCheck = mkSonarrRequest { uri = "/ping"; };

            sonarrConfig = pkgs.writers.writeYAML "sonarr-recyclarr-config.yaml" {
              sonarr = cfg.sonarr.config;
            };
          in
          ''
            ${optionalString cfg.radarr.enable ''
              echo "Check if radarr is up"
              ${radarrStatusCheck}
              echo "Radarr is now running"
              ${pkgs.recyclarr}/bin/recyclarr sync radarr -c ${radarrConfig}
            ''}

            ${optionalString cfg.sonarr.enable ''
              echo "Check if sonarr is up"
              ${sonarrStatusCheck}
              echo "Sonarr is now running"
              ${pkgs.recyclarr}/bin/recyclarr sync sonarr -c ${sonarrConfig}
            ''}
          '';
      };
  };
}
