{ pkgs, lib, ... }:

pkgs.claude-code.overrideAttrs (oldAttrs: {
  pname = "claude-code";
  version = "2.1.34";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.34.tgz";
    sha256 = "0l47b1sfz7jsp1hqw28ri972cr82f0rw31hrqgrmsrjy72qj96pn";
  };
})
