{
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  opencode-notifier-deps,
}:

let
  version = "0.1.35";
  rev = "64fa8e28e69077f6d6c4eeeef6d060431ea27bc8";
in
stdenvNoCC.mkDerivation {
  pname = "opencode-notifier";
  inherit version;

  src = fetchFromGitHub {
    owner = "mohak34";
    repo = "opencode-notifier";
    inherit rev;
    hash = "sha256-q/fsa0e4fZlZUfv3gI9Cn9l5saGG58js0JB7DmglA58=";
  };

  nativeBuildInputs = [ bun ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$PWD/.home"
    mkdir -p "$HOME"

    rm -rf node_modules
    cp -R "${opencode-notifier-deps}/node_modules" ./node_modules
    chmod -R u+w ./node_modules

    bun build src/index.ts --outdir dist --target node --offline

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/index.js "$out/opencode-notifier.js"

    runHook postInstall
  '';
}
