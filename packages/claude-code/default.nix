{ pkgs, lib, ... }:

pkgs.claude-code.overrideAttrs (oldAttrs: {
  pname = "claude-code";
  version = "2.0.54";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.0.54.tgz";
    sha256 = "17jvraz7ba0nybxfrg9s488fd16zw21s69ahhlldz2idwxf60k07";
  };
})
