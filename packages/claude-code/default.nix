{ pkgs, lib, ... }:

pkgs.claude-code.overrideAttrs (oldAttrs: {
  pname = "claude-code";
  version = "2.1.32";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.32.tgz";
    sha256 = "1v811dwpqj3yfyghdw9zwiw7l8xdgq3zb8bnx3w7jnkihnqqzh58";
  };
})
