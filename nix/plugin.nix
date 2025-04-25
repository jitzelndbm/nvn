{ stdenv, graph }:
stdenv.mkDerivation rec {
  name = "nvn";

  src = ../lua/nvn;

  buildInputs = [ graph ];

  installPhase = ''
    mkdir -p $out/{lib,lua/${name}}
    cp -r *.lua $out/lua/${name}
    cp -r ${graph}/lib/graph.min.js $out/lib
    cp -r ${graph}/lib/index.html $out/lib/graph.html
  '';
}
