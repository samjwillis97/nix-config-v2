{
  stdenvNoCC,
  fetchFromGitHub,
  bun,
}:

let
  version = "0.1.35";
  rev = "64fa8e28e69077f6d6c4eeeef6d060431ea27bc8";
  src = fetchFromGitHub {
    owner = "mohak34";
    repo = "opencode-notifier";
    inherit rev;
    hash = "sha256-q/fsa0e4fZlZUfv3gI9Cn9l5saGG58js0JB7DmglA58=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "opencode-notifier-deps";
  inherit version src;

  nativeBuildInputs = [ bun ];

  dontConfigure = true;
  dontFixup = true;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "sha256-BeVAFFqC98f55tlbzN1vtbT/roKPchztou5nlYY01ak=";

  buildPhase = ''
    runHook preBuild

    export HOME="$PWD/.home"
    mkdir -p "$HOME"

    bun install --frozen-lockfile

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R node_modules "$out/node_modules"
    cp package.json bun.lock "$out/"

    runHook postInstall
  '';
}
