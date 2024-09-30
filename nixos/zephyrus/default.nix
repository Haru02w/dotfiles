{ inputs, pkgs, ... }: {
  imports = [
    # settings
    ../common/global
    ../common/settings/locale_n_timezone.nix
    ../common/settings/sops.nix
    ../common/settings/impermanence.nix
    ../common/users/haru02w.nix

    #programs
    ../common/programs/hyprland.nix
    ../common/programs/pipewire.nix
    ../common/programs/tuigreet.nix
    ../common/programs/udisks2.nix
    ../common/programs/docker.nix

    # host specific
    ./hardware-configuration.nix
    ./disko.nix
    ./laptop.nix
    ./nvidia.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga401
    (import ./disko.nix { device = "/dev/nvme0n1"; })
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  services.tailscale.enable = true;
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama-cuda;
    acceleration = "cuda";
  };

  #ignore lid close
  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
  '';

  networking.hostName = "zephyrus";
}
