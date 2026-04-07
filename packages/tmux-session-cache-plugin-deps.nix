{
  stdenvNoCC,
  bun,
}:

stdenvNoCC.mkDerivation {
  pname = "tmux-session-cache-plugin-deps";
  version = "0.1.0";

  src = ../home-manager/ai-coding/plugins/tmux-session-cache;

  nativeBuildInputs = [ bun ];

  dontConfigure = true;
  dontFixup = true;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "sha256-H5q/v78lnWVTciVdBcigE+lrye7PFsyL/x64yL12SH8=";

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
    cp package.json "$out/"
    if [ -f bun.lock ]; then cp bun.lock "$out/"; fi

    runHook postInstall
  '';
}
