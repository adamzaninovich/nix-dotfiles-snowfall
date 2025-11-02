# Snowfall lib file format: accepts inputs, snowfall-inputs, lib
# Returns an attribute set that gets merged into lib
{ inputs, snowfall-inputs, lib }:

{
  # Rose Pine color palettes
  # Accessible as: lib.rose_pine.moon, lib.rose_pine.main, etc.
  rose_pine = {

  # Rose Pine Moon variant (darker)
  moon = {
    base = "232136";
    surface = "2a273f";
    overlay = "393552";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ea9a97";
    pine = "3e8fb0";
    foam = "9ccfd8";
    iris = "c4a7e7";
    highlightLow = "2a283e";
    highlightMed = "44415a";
    highlightHigh = "56526e";
  };

  # Rose Pine Main variant (original)
  # Source: https://github.com/rose-pine/neovim/blob/main/lua/rose-pine/palette.lua
  main = {
    base = "191724";
    surface = "1f1d2e";
    overlay = "26233a";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ebbcba";      # More peachy/beige than moon's rose
    pine = "31748f";
    foam = "9ccfd8";
    iris = "c4a7e7";
    leaf = "95b1ac";      # Bonus color from official palette
    highlightLow = "21202e";
    highlightMed = "403d52";
    highlightHigh = "524f67";
  };

  # Core palette colors (defaults to moon)
  palette = {
    base = "232136";
    surface = "2a273f";
    overlay = "393552";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ea9a97";
    pine = "3e8fb0";
    foam = "9ccfd8";
    iris = "c4a7e7";
    highlightLow = "2a283e";
    highlightMed = "44415a";
    highlightHigh = "56526e";
  };

  # Terminal colors (0-15)
  # Basic colors (0-7) use moon variant, bright colors (8-15) use main variant
  terminal = {
    color0 = "393552";   # moon overlay
    color1 = "eb6f92";   # moon love
    color2 = "3e8fb0";   # moon pine
    color3 = "f6c177";   # moon gold
    color4 = "9ccfd8";   # moon foam
    color5 = "c4a7e7";   # moon iris
    color6 = "ea9a97";   # moon rose (more pink)
    color7 = "e0def4";   # moon text
    color8 = "26233a";   # main overlay (bright black)
    color9 = "eb6f92";   # main love (bright red)
    color10 = "31748f";  # main pine (bright green - darker than moon)
    color11 = "f6c177";  # main gold (bright yellow)
    color12 = "9ccfd8";  # main foam (bright blue)
    color13 = "c4a7e7";  # main iris (bright magenta)
    color14 = "ebbcba";  # main rose (bright cyan - more peachy than moon)
    color15 = "e0def4";  # main text (bright white)
  };

  # Helper functions for different color formats
  toHyprland = color: "0xff${color}";
  toHex = color: "#${color}";
  toRGB = color:
    let
      r = lib.toInt ("0x" + builtins.substring 0 2 color);
      g = lib.toInt ("0x" + builtins.substring 2 2 color);
      b = lib.toInt ("0x" + builtins.substring 4 2 color);
    in "rgb(${toString r}, ${toString g}, ${toString b})";
  toRGBA = alpha: color:
    let
      r = lib.toInt ("0x" + builtins.substring 0 2 color);
      g = lib.toInt ("0x" + builtins.substring 2 2 color);
      b = lib.toInt ("0x" + builtins.substring 4 2 color);
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
  };
}
