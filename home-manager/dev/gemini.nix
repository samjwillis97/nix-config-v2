{ pkgs, config, ... }:
let
  mySecureGemini = pkgs.writeShellApplication {
    name = "gemini";
    runtimeInputs = [ pkgs.gemini-cli ];
    text = ''
      GEMINI_API_KEY=$(cat "${config.age.secrets.gemini-api-key.path}")
      export GEMINI_API_KEY
      ${pkgs.gemini-cli}/bin/gemini "$@"
    '';

  };
in
{
  imports = [
    ../../secrets/default
  ];

  home.packages = [
    mySecureGemini
  ];
}

