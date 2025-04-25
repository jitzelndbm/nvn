{ buildNpmPackage }:
buildNpmPackage {
  name = "nvn-graph";
  src = ../graph;
  npmBuildScript = "build";
  npmDepsHash = "sha256-puAkctXeEOZzjyFTcrBD1ptm+TWbpIo+It7flloO0Qg=";
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp -r build/* $out/lib
    cp -r src/index.html $out/lib
    runHook postInstall
  '';
}
