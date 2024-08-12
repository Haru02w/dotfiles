{ inputs, lib, config, ... }:
with lib;
let cfg = config.modules.nix;
in {
  options.modules.nix.enable = mkOption {
    description = "Enable nix config";
    default = true;
    type = types.bool;
  };

  config = mkIf cfg.enable {
    nixpkgs = {
      config.allowUnfree = mkDefault true;
      config.allowUnfreePredicate = mkDefault (_: true);
    };

    nix = {
      optimise.automatic = mkDefault true;

      settings = {
        trusted-users = mkDefault [ "root" "@wheel" ];
        auto-optimise-store = mkDefault true;
        experimental-features = mkDefault [ "nix-command" "flakes" "repl-flake" ];
        system-features = mkDefault [ "kvm" "big-parallel" "nixos-test" ];
      };

      gc = {
        automatic = mkDefault true;
        randomizedDelaySec = mkDefault "24h";
        options = mkDefault "--delete-older-than 3d";
      };

      # Add each flake input as a registry
      # To make nix3 commands consistent with the flake
      registry = mkDefault (lib.mapAttrs (_: value: { flake = value; }) inputs);

      # Add nixpkgs input to NIX_PATH
      # This lets nix2 commands still use <nixpkgs>
      nixPath = mkDefault [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
    };
  };
}