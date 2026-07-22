{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeWrapper,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lavish-axi";
  version = "0.1.42";

  src = fetchFromGitHub {
    owner = "kunchenguid";
    repo = "lavish-axi";
    tag = "lavish-axi-v${finalAttrs.version}";
    hash = "sha256-IcApX4Qpx7oy5x5uaeOlIFC/6pr/kjjcjjPjmCXk2DI=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpmConfigHook
    pnpm_10
    makeWrapper
  ];

  pnpmInstallFlags = [
    "--child-concurrency=1"
    "--network-concurrency=1"
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      pnpmInstallFlags
      ;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-Hs3sqZx9VzwJw2/0Lgghvfqi7uo8nPaEYfuKSqCu8bA=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    packageOut="$out/lib/node_modules/lavish-axi"
    mkdir -p "$packageOut/skills" "$packageOut/lavish-editor-marketing/renders"

    cp -rL dist "$packageOut/"
    cp -rL skills/lavish "$packageOut/skills/"
    cp -L lavish-editor-marketing/renders/lavish-editor-marketing.gif \
      "$packageOut/lavish-editor-marketing/renders/"
    cp -L LICENSE THIRD-PARTY-NOTICES.md README.md package.json "$packageOut/"

    pnpm prune --prod --ignore-scripts
    cp -r node_modules "$packageOut/"

    makeWrapper "${lib.getExe nodejs_22}" "$out/bin/lavish-axi" \
      --add-flags "$packageOut/dist/cli.mjs"

    runHook postInstall
  '';

  meta = {
    description = "HTML editor for reviewing and annotating agent-generated artifacts";
    homepage = "https://github.com/kunchenguid/lavish-axi";
    license = lib.licenses.mit;
    mainProgram = "lavish-axi";
    platforms = lib.platforms.unix;
  };
})
