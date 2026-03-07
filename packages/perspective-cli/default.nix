{ lib, pkgs, stdenv, ... }:

let
  version = "0.15.0";
  # Release archives include a short commit hash in the filename
  releaseTag = "${version}-1-g0187008";
in
stdenv.mkDerivation {
  pname = "perspective-cli";
  inherit version;

  src = pkgs.fetchzip {
    url = "https://github.com/Techopolis/PerspectiveCLI/releases/download/${version}/perspective-cli-${releaseTag}-macos-arm64.tar.gz";
    sha256 = "1filq0x810zr3cs7qfbs7jyipdjyy9qrwn5aqch983vyc2zvl569";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp perspective $out/bin/perspective
    chmod +x $out/bin/perspective

    # mlx.metallib must live alongside the binary — the binary looks for it
    # in the same directory (mirroring what install.sh does in /usr/local/bin)
    cp mlx.metallib $out/bin/mlx.metallib

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI for Apple's on-device AI via FoundationModels and MLX (requires macOS 26+ with Apple Intelligence)";
    homepage = "https://github.com/Techopolis/PerspectiveCLI";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "perspective";
  };
}
