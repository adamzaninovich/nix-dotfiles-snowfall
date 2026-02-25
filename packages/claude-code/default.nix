{ pkgs, lib, stdenv, ... }:

let
  version = "2.1.56";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "1f87p5cy6047m28inva41lc4pz4vy5xxwpqyaxjp4f32ipxc8z5r";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/claude-code
    cp -r . $out/lib/claude-code/
    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/claude \
      --add-flags "$out/lib/claude-code/cli.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI coding assistant CLI";
    homepage = "https://claude.ai/code";
    license = licenses.unfree;
    mainProgram = "claude";
  };
}
