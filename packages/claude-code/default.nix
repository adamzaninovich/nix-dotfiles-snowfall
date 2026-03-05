{ pkgs, lib, stdenv, ... }:

let
  version = "2.1.69";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "1b8hz5822nxs4m7r1w6z8152z2j4f8321lj09z6blx21ycf05d25";
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
      --add-flags "$out/lib/claude-code/cli.js" \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1
    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI coding assistant CLI";
    homepage = "https://claude.ai/code";
    license = licenses.unfree;
    mainProgram = "claude";
  };
}
