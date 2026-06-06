{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "rpiv-ask-user-question";
  version = "1.18.2";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-1.4.0.tgz";
    hash = "sha256-QvD5Po6iCOCUgU1VIjsPBfbF5L47PyxhkCyenQc21Yo=";
  };

  dontBuild = true;

  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    cp -r package $out
  '';
}
