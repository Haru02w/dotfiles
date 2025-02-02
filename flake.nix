{
  description = "My dotfiles";
  outputs = inputs: let
    lib = import ./lib {inherit inputs;};
  in {
    inherit lib;
    nixosModules = {
      modules = _: {
        imports = lib.nixFilesInPathR ./modules/nixos;
      };
    };
    homeModules = {
      modules = _: {
        imports = lib.nixFilesInPathR ./modules/home-manager;
      };
    };
    nixvimModule = import ./modules/nixvim;

    # 'nixos-rebuild --flake .#<hostname>'
    nixosConfigurations = lib.mkNixosConfig (host: let
      settings = import ./hosts/${host} {};
    in {
      pkgs = lib.pkgsFor."${settings.arch}";
      modules =
        lib.nixFilesInPathR ./hosts/${host}/nixos
        ++ (builtins.attrValues inputs.self.outputs.nixosModules);
      specialArgs = {
        inherit lib;
        inherit inputs;
        inherit settings;
      };
    });

    # 'home-manager --flake .#<username>@<hostname>'
    homeConfigurations = lib.mkHomeConfig (host: user: let
      settings =
        import ./hosts/${host} {};
    in {
      pkgs = lib.pkgsFor."${settings.arch}";
      modules =
        lib.nixFilesInPathR ./hosts/${host}/home-manager/${user}
        ++ [
          inputs.stylix.homeManagerModules.stylix
        ];
      extraSpecialArgs = {
        inherit lib;
        inherit inputs;
        inherit settings;
      };
    });

    # 'nix build', 'nix shell', etc
    packages = lib.forEachSystemPkgs (pkgs: import ./pkgs {inherit inputs pkgs;});
    overlays = import ./overlays {inherit inputs;};
    # 'nix develop'
    devShells = lib.forEachSystemPkgs (pkgs: import ./shell.nix {inherit inputs pkgs;});
    # 'nix fmt'
    formatter = lib.forEachSystemPkgs (pkgs: pkgs.alejandra);
    # 'nix flake new -t self#<template>'
    templates = lib.mkTemplates;
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" # nix-community (nur)
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nur.url = "github:nix-community/nur";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    buffer_manager-nvim = {
      url = "github:j-morano/buffer_manager.nvim";
      flake = false;
    };
  };
}
