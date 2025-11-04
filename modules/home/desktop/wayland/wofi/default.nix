{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.wayland.wofi;
  colors = config.bravo.desktop.theme.rosepine.colors;

  # Common CSS base with Rose Pine colors
  commonStyle = ''
    @define-color mauve ${colors.hex.love};
    @define-color red ${colors.hex.love};
    @define-color lavender ${colors.hex.text};
    @define-color text ${colors.hex.text};
    @define-color background ${colors.hex.base};

    @keyframes fadeIn {
        0% {
        }
        100% {
        }
    }

    * {
        all: unset;
        font-family: 'CodeNewRoman Nerd Font Mono', monospace;
        font-size: 18px;
        outline: none;
        border: none;
        text-shadow: none;
        background-color: transparent;
    }

    window {
        all: unset;
        padding: 20px;
        border-radius: 0px;
        background-color: alpha(@background, .5);
    }

    #inner-box {
        margin: 2px;
        padding: 5px;
        border: none;
    }

    #outer-box {
        border: none;
    }

    #scroll {
        margin: 0px;
        padding: 30px;
        border: none;
    }

    #input {
        all: unset;
        margin-left: 20px;
        margin-right: 20px;
        margin-top: 20px;
        padding: 20px;
        border: none;
        outline: none;
        color: @text;
        box-shadow: 1px 1px 5px rgba(0, 0, 0, .5);
        border-radius: 10;
        background-color: alpha(@background, .2);
    }

    #input image {
        border: none;
        color: @red;
        padding-right: 10px;
    }

    #input * {
        border: none;
        outline: none;
    }

    #input:focus {
        outline: none;
        border: none;
        border-radius: 10;
    }

    #text {
        margin: 5px;
        border: none;
        color: @text;
        outline: none;
    }

    #entry {
        border: none;
        margin: 5px;
        padding: 10px;
    }

    #entry arrow {
        border: none;
        color: @lavender;
    }

    #entry:selected {
        box-shadow: 1px 1px 5px rgba(255, 255, 255, .03);
        border: none;
        border-radius: 20px;
        background-color: transparent;
    }

    #entry:selected #text {
        color: @mauve;
    }

    #entry:drop(active) {
        background-color: @lavender !important;
    }
  '';

in
{
  options.bravo.desktop.wayland.wofi = {
    enable = mkEnableOption "Wofi application launcher";
  };

  config = mkIf cfg.enable {
    # Enable Rose Pine theme
    bravo.desktop.theme.rosepine.enable = true;

    # Main launcher config
    xdg.configFile."wofi/config".text = ''
      [config]
      allow_images=true
      width=500
      show=drun
      prompt=Search
      height=400
      term=ghostty
      hide_scroll=true
      print_command=true
      insensitive=true
      columns=1
      no_actions=true
    '';

    # Main launcher style
    xdg.configFile."wofi/style.css".text = commonStyle;

    # Wallpaper picker config
    xdg.configFile."wofi/wallpaper".text = ''
      [config]
      allow_images=true
      show=drun
      width=800
      height=600
      always_parse_args=true
      show_all=true
      term=ghostty
      hide_scroll=true
      print_command=true
      insensitive=true
      columns=4
      image_size=150
    '';

    # Wallpaper picker style
    xdg.configFile."wofi/style-wallpaper.css".text = commonStyle;

    # Waybar theme selector config
    xdg.configFile."wofi/waybar".text = ''
      [config]
      allow_images=true
      show=drun
      width=1200
      height=600
      always_parse_args=true
      show_all=true
      term=ghostty
      hide_scroll=true
      print_command=true
      insensitive=true
      columns=1
      image_size=1050
    '';

    # Waybar theme selector style
    xdg.configFile."wofi/style-waybar.css".text = commonStyle;

    # Install wofi package
    home.packages = with pkgs; [
      wofi
    ];
  };
}
