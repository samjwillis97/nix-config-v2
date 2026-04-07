{
  stdenvNoCC,
  bun,
  tmux-session-cache-plugin-deps,
}:

stdenvNoCC.mkDerivation {
  pname = "tmux-session-cache-plugin";
  version = "0.1.0";

  src = ../home-manager/ai-coding/plugins/tmux-session-cache;

  nativeBuildInputs = [ bun ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$PWD/.home"
    mkdir -p "$HOME"

    rm -rf node_modules
    cp -R "${tmux-session-cache-plugin-deps}/node_modules" ./node_modules
    chmod -R u+w ./node_modules

    bun build src/index.ts --outdir dist --target node --offline

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/index.js "$out/dist/index.js"

    runHook postInstall
  '';
}
