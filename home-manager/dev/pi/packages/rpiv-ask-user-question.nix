{ pkgs }:

let
  # Runtime dependency: imported (non-type) by config.ts.
  # v1.20.0 of rpiv-ask-user-question started depending on this; v1.4.0 did not.
  rpivConfig = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@juicesharp/rpiv-config/-/rpiv-config-1.20.0.tgz";
    hash = "sha256-Xd/v2Id/pDLwnTMKKWri4orvVnxOSQ9uxcBRtudcTWI=";
  };

  # Peer dependency of rpiv-config, value-imported by tool/types.ts.
  # Must be resolvable at extension load time.
  typebox = pkgs.fetchurl {
    url = "https://registry.npmjs.org/typebox/-/typebox-1.3.0.tgz";
    hash = "sha256-IoCXlUts+JmXXPGF0P8UX5+7mYxnCFIZsIDOdLgIyd4=";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "rpiv-ask-user-question";
  version = "1.20.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-1.20.0.tgz";
    hash = "sha256-wV7JSV7Rw8i6WsfjRXKCCGIU1gUtCqi1ZfrB9+kYekY=";
  };

  dontBuild = true;

  unpackPhase = ''
    tar xzf $src
  '';

  # Pi loads this package directly from its read-only nix store path, so it has
  # no shared node_modules to fall back on. Bundle the package's runtime deps
  # under node_modules/ so Node's standard upward resolution succeeds.
  installPhase = ''
    cp -r package $out
    chmod -R u+w $out

    mkdir -p $out/node_modules/@juicesharp/rpiv-config
    tar xzf ${rpivConfig} -C $out/node_modules/@juicesharp/rpiv-config --strip-components=1

    mkdir -p $out/node_modules/typebox
    tar xzf ${typebox} -C $out/node_modules/typebox --strip-components=1
  '';
}
