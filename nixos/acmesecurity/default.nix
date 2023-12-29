{ config, pkgs, inputs, outputs, ...}:
let
  admin = "haru02w";
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = (builtins.attrValues outputs.nixosModules) ++ [
    ./hardware-configuration.nix
    ../features/quietboot.nix
    ../features/common/global.nix
    ../features/common/hyprland-desktop.nix
  ];

  networking.hostName = "acmesecurity";

  # TODO: Bootloader

  # Users
  users.users = {
    "${admin}"= {
      isNormalUser = true;
      extraGroups = ifGroupsExist [ 
        "wheel" # Enable ‘sudo’ for the user.
        "networkmanager"
        "video"
        "audio"
        "libvirtd"
        "network"
        "git"
      ];
      shell = pkgs.zsh;
      packages = with pkgs; [];
    };
    # more
  };
  home-manager.users.${admin} = import ../../home/${admin}/${config.networking.hostName}.nix;
}
