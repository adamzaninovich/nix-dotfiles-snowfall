# Wrapper package that re-signs the zen-browser app bundle for macOS
#
# WORKAROUND: The upstream zen-browser-flake adds files to the signed app bundle
# (zen-beta symlink, policies.json) which breaks macOS Gatekeeper verification.
# This package copies the app and re-signs it with an ad-hoc signature.
#
# TODO: Remove this once upstream fixes the issue
# See: https://github.com/0xc000022070/zen-browser-flake
{
  lib,
  stdenv,
  inputs,
  system,
  ...
}:
let
  upstream = inputs.zen-browser.packages.${system}.default;
in
stdenv.mkDerivation {
  pname = "zen-browser-temp-signing-fix";
  version = upstream.version or "unknown";

  # No source - we're wrapping an existing package
  dontUnpack = true;

  # Only needed on Darwin
  meta.platforms = [ "aarch64-darwin" "x86_64-darwin" ];

  buildPhase = ''
    runHook preBuild

    # Copy the entire upstream package, dereferencing symlinks
    # codesign requires the main executable to be a regular file, not a symlink
    cp -rL ${upstream} $out
    chmod -R u+w $out

    # Find and re-sign all .app bundles
    find $out -name "*.app" -type d | while read -r app; do
      echo "Re-signing: $app"
      /usr/bin/codesign --sign - --force --deep "$app"
    done

    runHook postBuild
  '';

  # Skip all the standard phases we don't need
  dontConfigure = true;
  dontInstall = true;
  dontFixup = true;
}
