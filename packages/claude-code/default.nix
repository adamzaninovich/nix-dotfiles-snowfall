{ pkgs, lib, ... }:

pkgs.claude-code.overrideAttrs (oldAttrs: {
  pname = "claude-code";
  version = "2.1.6";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.6.tgz";
    sha256 = "0zpw4cb6gvdsc1405y8hsrxbwdm4lq324pmrvmqabgn232jlpib7";
  };
})
