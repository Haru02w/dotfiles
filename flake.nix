{
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      suportedSystems = lib.systems.flakeExposed;
      forEachSystem = f:
        lib.genAttrs suportedSystems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs suportedSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
    in {
      inherit lib;
      # system-level modules
      nixosModules = import ./modules/nixos;
      # user-level modules
      homeManagerModules = import ./modules/home-manager;
      # 'nix flake new -t self#<template>'
      templates = import ./templates;
      # override inputs
      overlays = import ./overlays { inherit inputs outputs; };
      # 'nix build', 'nix shell', etc
      packages = forEachSystem (pkgs: import ./pkgs { inherit inputs pkgs; });
      # 'nix develop'
      devShells =
        forEachSystem (pkgs: { default = pkgs.callPackage ./shell.nix { }; });
      # 'nix fmt'
      formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);

      # 'nixos-rebuild --flake .#<hostname>'
      nixosConfigurations = {
        # personal laptop
        zephyrus = lib.nixosSystem {
          modules = [ ./nixos/zephyrus ];
          specialArgs = { inherit inputs outputs; };
        };
        # work desktop
        tweety = lib.nixosSystem {
          modules = [ ./nixos/tweety ];
          specialArgs = { inherit inputs outputs; };
        };
        testvm = lib.nixosSystem {
          modules = [ ./nixos/testvm ];
          specialArgs = { inherit inputs outputs; };
        };
      };

      # 'home-manager --flake .#<username>@<hostname>'
      homeConfigurations = {
        "haru02w@zephyrus" = lib.homeManagerConfiguration {
          modules = [ ./home/haru02w/zephyrus.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "haru02w@tweety" = lib.homeManagerConfiguration {
          modules = [ ./home/haru02w/tweety.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "haru02w@testvm" = lib.homeManagerConfiguration {
          modules = [ ./home/haru02w/testvm.nix ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixos module
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # nixos module
    impermanence.url = "github:nix-community/impermanence";

    # nixos module
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos and home-manager module
    nix-colors.url = "github:misterio77/nix-colors";

    # nixos and home-manager module
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    # nixos module
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # overlay
    nur.url = "github:nix-community/NUR";

    # package
    nixnvc = {
      url = "github:haru02w/nixnvc";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    #nh = {
    #  url = "github:viperml/nh";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    # home-manager module
    hyprland = {
      url = "github:hyprwm/hyprland/v0.38.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # package
    split-monitor-workspaces = {
      url =
        "github:zjeffer/split-monitor-workspaces/759e4b605d873dd6f47967c54d5d78d12939986c";
      inputs.hyprland.follows = "hyprland";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org" # hyprland
      "https://nix-community.cachix.org" # nix-community (nur)
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" # Hyprland
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" # nix-community (nur)
    ];
  };
}
