{ pkgs, lib, ... }:

pkgs.claude-code.overrideAttrs (oldAttrs: {
  pname = "claude-code";
  version = "2.0.27";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.0.27.tgz";
    sha256 = "0dxi1n4bacaz81cmj35pnlj1vdp558cb03mf8pqn2c28jhms4cnv";
  };
})
