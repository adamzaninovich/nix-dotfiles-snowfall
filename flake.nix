{
  description = "Adam Zaninovich's Dotfiles";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/nixos-wsl/release-25.05";

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # todo: add sops
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # add when setting up darwin
    # mac-app-util.url = "github:hraban/mac-app-util";

    # figure out how to make these into packages?
    comic-code = {
      url = "git+ssh://git@github.com/adamzaninovich/Comic-Code.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    doom-fonts = {
      url = "git+ssh://git@github.com/adamzaninovich/fonts.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up-to-date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:

    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "bravo";

        meta = {
          name = "snowfall-config-nix-flake";
          title = "Adam's Snowfall Nix Config";
        };
      };

      channels-config = {
        allowUnfree = true;
        # needed?
        permittedInsecurePackages = [ "python-2.7.18.8" ];
      };

      # how to do this with snowfall?
      # extraSpecialArgsFor = system: {
      #   inherit inputs mac-app-util comic-code doom-fonts;
      #   pkgs-unstable = unstableFor system;
      # };

      # how to do this with all mac users?
      # homes.users."adam@Rocinante".modules = with inputs; [
      #   mac-app-util.homeManagerModules.default
      # ];

      # todo: add sops
      # homes.modules = with inputs; [
      #   sops-nix.homeManagerModules.sops
      # ];

      # todo: add sops
      # systems.modules.nixos = with inputs; [
      #   sops-nix.nixosModules.sops
      # ];
    };
}
