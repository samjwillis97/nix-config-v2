{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "rpiv-ask-user-question";
  version = "1.4.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-1.4.0.tgz";
    hash = "sha512-bzKcjYbqrXlEmqFZS7b+A2W2fZMadyIxoFjvURh+xYo5rkgpfWtZhYf1+d/cCchcYmnEIZ0S2YvaCE9LRQybNA==";
  };

  dontBuild = true;

  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    cp -r package $out
  '';
}
