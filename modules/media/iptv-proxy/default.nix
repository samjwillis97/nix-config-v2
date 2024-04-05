{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.media.iptv-proxy;

  iptv-proxy = pkgs.buildGoModule rec {
    name = "iptv-proxy";
    version = "3.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "pierre-emmanuelJ";
      repo = "iptv-proxy";
      rev = "v${version}";
      hash = "sha256-mkJ1iIOXnX2Pc6Z686jdwtcqSWc4woIsT9x9G+EQIGE=";
    };

    vendorHash = null;
  };
in
{
  options.modules.media.iptv-proxy = {
    enable = mkEnableOption "Enables IPTV proxy";

    port = mkOption rec {
      description = mdDoc "IPTV port";
      default = 8080;
      example = default;
      type = types.port;
    };

    xtream = {
      enable = mkEnableOption "Use XTream";

      hostname = mkOption {
        description = mdDoc "XTream hostname";
        example = "http://localhost:3030";
        type = types.str;
      };

      # Should make some sort of check to see that one of these is defined
      username = mkOption {
        default = null;
        description = mdDoc "XTream username";
        example = "username";
        type = types.nullOr types.str;
      };

      usernameFile = mkOption {
        default = null;
        description = mdDoc "XTream username file";
        type =
          with types;
          nullOr (oneOf [
            path
            str
          ]);
        example = "/var/mySecret/usernameFile";
      };

      password = mkOption {
        default = null;
        description = mdDoc "XTream password";
        example = "password";
        type = types.nullOr types.str;
      };

      passwordFile = mkOption {
        default = null;
        description = mdDoc "XTream password file";
        type =
          with types;
          nullOr (oneOf [
            path
            str
          ]);
        example = "/var/mySecret/passwordFile";
      };
    };

    username = mkOption rec {
      description = mdDoc "Username for proxy output";
      type = types.str;
      default = "username";
      example = default;
    };

    password = mkOption rec {
      description = mdDoc "Password for proxy output";
      type = types.str;
      default = "password";
      example = default;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.iptv-proxy = {
      description = "Startup IPTV Proxy";

      serviceConfig.Type = "exec";

      wantedBy = [ "multi-user.target" ];

      script = ''
        echo "Starting IPTV Proxy"

        echo "Setting Environment Variables"

        PORT=${toString cfg.port}
        export PORT

        USER=${cfg.username}
        export USER

        PASSWORD=${cfg.password}
        export PASSWORD

        ${optionalString cfg.xtream.enable ''
          XTREAM_API_GET=1
          export XTREAM_API_GET

          XTREAM_BASE_URL=${cfg.xtream.hostname}
          export XTREAM_BASE_URL

          ${
            if isNull cfg.xtream.usernameFile then
              ''
                XTREAM_USER=${cfg.xtream.username}
                export XTREAM_USER
              ''
            else
              ''
                XTREAM_USER=$(cat ${toString cfg.xtream.usernameFile})
                export XTREAM_USER
              ''
          }

          ${
            if isNull cfg.xtream.passwordFile then
              ''
                XTREAM_PASSWORD=${cfg.xtream.password}
                export XTREAM_PASSWORD
              ''
            else
              ''
                XTREAM_PASSWORD=$(cat ${toString cfg.xtream.passwordFile})
                export XTREAM_PASSWORD
              ''
          }

          # M3U_URL=${cfg.xtream.hostname}/get.php?username\=$XTREAM_USERNAME\&password\=$XTREAM_PASSWORD\&type\=m3u_plus\&output\=m3u8
          # export M3U_URL
        ''}

        ${iptv-proxy}/bin/iptv-proxy
      '';
    };
  };
}
